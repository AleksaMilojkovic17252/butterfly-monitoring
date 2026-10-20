from django.conf import settings
from django.contrib.postgres.fields import ArrayField
from django.db import models
from simple_history.models import HistoricalRecords

from apps.core.models import SyncableModel


class MutationStatus(models.TextChoices):
    APPLIED = "applied"
    MERGED = "merged"
    CONFLICT = "conflict"
    REJECTED = "rejected"


class SyncMutation(models.Model):
    """One received push mutation and its result. Makes push idempotent (T026)."""

    mutation_id = models.UUIDField(primary_key=True)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    device_id = models.CharField(max_length=64)
    entity_type = models.CharField(max_length=40)
    entity_id = models.UUIDField()
    operation = models.CharField(max_length=15)
    base_version = models.BigIntegerField(null=True)
    status = models.CharField(max_length=10, choices=MutationStatus.choices)
    result = models.JSONField(default=dict)
    received_at = models.DateTimeField(auto_now_add=True)
    client_created_at = models.DateTimeField(null=True)

    class Meta:
        db_table = "sync_mutation"
        indexes = [
            models.Index(fields=["entity_type", "entity_id"]),
            models.Index(fields=["user", "received_at"]),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(status__in=MutationStatus.values),
                name="sync_mutation_status_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(operation__in=["create", "update", "delete", "create_batch"]),
                name="sync_mutation_operation_valid",
            ),
        ]


class ConflictStatus(models.TextChoices):
    OPEN = "open"
    RESOLVED_SERVER = "resolved_server"  # keep server state, drop client change
    RESOLVED_CLIENT = "resolved_client"  # apply client payload


class SyncConflict(SyncableModel):
    """An update/delete the server could not merge (T027). An admin resolves it (T028)."""

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="sync_conflicts"
    )
    mutation = models.OneToOneField(SyncMutation, on_delete=models.PROTECT, related_name="conflict")
    project = models.ForeignKey("projects.Project", on_delete=models.PROTECT)
    entity_type = models.CharField(max_length=40)
    entity_id = models.UUIDField()
    operation = models.CharField(max_length=15)
    base_version = models.BigIntegerField()
    server_version_at_conflict = models.BigIntegerField()
    client_payload = models.JSONField()
    server_snapshot = models.JSONField()  # current server record at conflict time
    base_snapshot = models.JSONField(null=True)  # record at base_version, if found
    conflicting_fields = ArrayField(models.CharField(max_length=60), default=list)
    status = models.CharField(
        max_length=20, choices=ConflictStatus.choices, default=ConflictStatus.OPEN
    )
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
    )
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolution_note = models.TextField(blank=True)
    history = HistoricalRecords(table_name="historical_sync_conflict")

    class Meta:
        db_table = "sync_conflict"
        indexes = [
            models.Index(fields=["status", "entity_type"]),
            models.Index(fields=["entity_type", "entity_id"]),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(status__in=ConflictStatus.values),
                name="sync_conflict_status_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(status="open", resolved_at__isnull=True)
                | (~models.Q(status="open") & models.Q(resolved_at__isnull=False)),
                name="sync_conflict_resolution_consistent",
            ),
        ]
