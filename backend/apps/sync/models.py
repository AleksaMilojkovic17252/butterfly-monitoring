from django.conf import settings
from django.db import models


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
