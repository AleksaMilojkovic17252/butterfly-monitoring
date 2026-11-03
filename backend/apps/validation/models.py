import uuid

from django.conf import settings
from django.db import models

from apps.observations.models import ButterflyObservation


class Decision(models.TextChoices):
    CONFIRMED = "confirmed"
    CHANGED_TAXON = "changed_taxon"
    UNCONFIRMED = "unconfirmed"
    UNDETERMINABLE = "undeterminable"
    RESET = "reset"


class ValidationEvent(models.Model):
    """One validation decision on a butterfly observation (T058, F33).

    Server-only and append-only: written by `validation.services.record_decision`, never edited
    or deleted, and not synced to the phone. It is not a `SyncableModel` and has no history table.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    observation = models.ForeignKey(
        "observations.ButterflyObservation",
        on_delete=models.PROTECT,
        related_name="validation_events",
        help_text="The butterfly observation the decision is about",
    )
    decision = models.CharField(
        max_length=20,
        choices=Decision.choices,
        help_text="What the validator decided: confirmed, changed_taxon, unconfirmed, "
        "undeterminable or reset",
    )
    previous_status = models.CharField(
        max_length=15, help_text="The observation's validation status before the decision"
    )
    new_status = models.CharField(
        max_length=15, help_text="The observation's validation status after the decision"
    )
    previous_taxon = models.ForeignKey(
        "catalogues.Taxon",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        help_text="The validator's taxon before the decision; missing if none was set",
    )
    new_taxon = models.ForeignKey(
        "catalogues.Taxon",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        help_text="The taxon the validator set; only for a changed_taxon decision",
    )
    comment = models.TextField(blank=True, help_text="The validator's comment on the decision")
    decided_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="+",
        help_text="The user who made the decision",
    )
    decided_at = models.DateTimeField(
        auto_now_add=True, help_text="When the decision was made (UTC, ISO 8601)"
    )

    class Meta:
        db_table = "validation_event"
        ordering = ["-decided_at"]
        indexes = [
            models.Index(fields=["observation", "decided_at"], name="validation_event_obs_time_idx")
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(decision__in=Decision.values),
                name="validation_decision_valid",
            ),
            models.CheckConstraint(
                condition=~models.Q(decision="changed_taxon") | models.Q(new_taxon__isnull=False),
                name="validation_changed_needs_taxon",
            ),
        ]

    def __str__(self):
        return f"{self.decision} ({self.previous_status} -> {self.new_status})"


class ValidationQueueItem(ButterflyObservation):
    """An observation as the validation queue shows it (T057). Admin only: never save one of
    these, a proxy save writes no history row. `validation.services` loads the real model."""

    class Meta:
        proxy = True
        verbose_name = "validation queue item"
        verbose_name_plural = "validation queue"
