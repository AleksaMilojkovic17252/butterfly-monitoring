from django.contrib.gis.db import models as gis_models
from django.core.exceptions import ValidationError
from django.db import models
from simple_history.models import HistoricalRecords

from apps.core.models import SyncableModel


class Transect(SyncableModel):
    """A fixed walking route of a project, split into numbered sections.

    Keep the geometry a plain 2D LineString: Phase 2 reuses it (T078, T091).
    """

    project = models.ForeignKey(
        "projects.Project",
        on_delete=models.PROTECT,
        related_name="transects",
        help_text="Project the transect belongs to",
    )
    code = models.CharField(max_length=20, help_text="Short transect code, unique in the project")
    name = models.CharField(max_length=200, help_text="Transect name")
    description = models.TextField(blank=True, help_text="Free-text description of the route")
    target_length_m = models.DecimalField(
        max_digits=8,
        decimal_places=1,
        null=True,
        blank=True,
        help_text="Planned length, metres",
    )
    habitat_summary = models.TextField(blank=True, help_text="Short summary of the habitats")
    active = models.BooleanField(default=True, help_text="Whether the transect is still walked")
    geometry = gis_models.LineStringField(srid=4326, help_text="Route of the transect, WGS 84")
    history = HistoricalRecords(table_name="historical_transect")

    class Meta:
        db_table = "transect"
        constraints = [
            models.UniqueConstraint(fields=["project", "code"], name="transect_code_unique")
        ]

    def __str__(self):
        return f"{self.code} {self.name}"


class TransectSection(SyncableModel):
    """One numbered stretch of a transect. Its line must lie along the transect (5 m)."""

    transect = models.ForeignKey(
        Transect,
        on_delete=models.PROTECT,
        related_name="sections",
        help_text="Transect the section belongs to",
    )
    section_code = models.CharField(
        max_length=20, help_text="Section code, unique within the transect"
    )
    sequence_number = models.PositiveSmallIntegerField(
        help_text="Order of the section along the transect, from 1"
    )
    habitat_type = models.ForeignKey(
        "catalogues.HabitatType",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        help_text="Habitat type of the section",
    )
    management_type = models.ForeignKey(
        "catalogues.ManagementType",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        help_text="Management of the section, e.g. mowing or grazing",
    )
    notes = models.TextField(blank=True, help_text="Free-text notes on the section")
    geometry = gis_models.LineStringField(srid=4326, help_text="Line of the section, WGS 84")
    history = HistoricalRecords(table_name="historical_transect_section")

    class Meta:
        db_table = "transect_section"
        ordering = ["transect", "sequence_number"]
        constraints = [
            # Live rows only, so a soft-deleted section does not block its code or number.
            models.UniqueConstraint(
                fields=["transect", "sequence_number"],
                condition=models.Q(deleted_at__isnull=True),
                name="section_seq_unique",
            ),
            models.UniqueConstraint(
                fields=["transect", "section_code"],
                condition=models.Q(deleted_at__isnull=True),
                name="section_code_unique",
            ),
            models.CheckConstraint(
                condition=models.Q(sequence_number__gte=1), name="section_seq_positive"
            ),
        ]

    def __str__(self):
        return f"{self.transect.code} / {self.section_code}"

    def clean(self):
        from apps.transects.services import SECTION_TOLERANCE_M, section_lies_along

        errors = {}
        # Same rule as section_seq_positive, raised on the field so forms show it there.
        if self.sequence_number == 0:
            errors["sequence_number"] = "Sections are numbered from 1."
        # Uses the transect instance in memory, so an edited but unsaved line is checked too.
        if (
            self.transect_id is not None
            and self.geometry is not None
            and not section_lies_along(self.geometry, self.transect.geometry)
        ):
            errors["geometry"] = (
                f"The section must lie within {SECTION_TOLERANCE_M:g} m of the transect line "
                f"of {self.transect.code}."
            )
        if errors:
            raise ValidationError(errors)


class ProposalReason(models.TextChoices):
    PRIVATE_PROPERTY = "private_property", "Private property"
    UNSAFE = "unsafe", "Unsafe"
    IMPASSABLE = "impassable", "Impassable"
    BETTER_ROUTE = "better_route", "Better route"
    OTHER = "other", "Other"


class ProposalStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    ACCEPTED = "accepted", "Accepted"
    REJECTED = "rejected", "Rejected"


class TransectProposal(SyncableModel):
    """A route recorded on the phone because a transect turned out to be unwalkable, or a better
    route exists (T108). It is never a visit and never a transect on the phone: an admin turns it
    into an inactive `Transect` (`services.accept_proposal`) and cuts its sections.

    The proposer is `created_by`. `status`, the review fields, `created_transect` and `length_m`
    belong to the server: a push cannot set them. The geometry is a valid line of at least two
    points; the geometry CHECKs are added by RunSQL in the migration, as for plant records.
    """

    project = models.ForeignKey(
        "projects.Project",
        on_delete=models.PROTECT,
        related_name="transect_proposals",
        help_text="Project the route is proposed for",
    )
    name = models.CharField(max_length=200, help_text="Name the proposer gives the route")
    reason = models.CharField(
        max_length=20,
        choices=ProposalReason.choices,
        help_text="Why: private_property, unsafe, impassable, better_route or other",
    )
    replaces_transect = models.ForeignKey(
        Transect,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="replacement_proposals",
        help_text="Transect the route would replace; empty for a new route",
    )
    notes = models.TextField(blank=True, help_text="Free-text notes of the proposer")
    geometry = gis_models.LineStringField(
        srid=4326, help_text="The recorded route, a line of at least two points, WGS 84"
    )
    recorded_from = models.DateTimeField(help_text="Time of the first fix of the line (UTC)")
    recorded_to = models.DateTimeField(help_text="Time of the last fix of the line (UTC)")
    length_m = models.DecimalField(
        max_digits=8,
        decimal_places=1,
        null=True,
        blank=True,
        help_text="Geodesic length of the line in metres; worked out by the server",
    )
    status = models.CharField(
        max_length=10,
        choices=ProposalStatus.choices,
        default=ProposalStatus.PENDING,
        help_text="pending, accepted or rejected; set by the server",
    )
    review_note = models.TextField(blank=True, help_text="The admin's reason for a rejection")
    reviewed_by = models.ForeignKey(
        "accounts.User",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        help_text="Admin who accepted or rejected the proposal",
    )
    reviewed_at = models.DateTimeField(
        null=True, blank=True, help_text="When the proposal was reviewed (UTC)"
    )
    created_transect = models.ForeignKey(
        Transect,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
        help_text="Inactive transect made from the proposal when it was accepted",
    )
    history = HistoricalRecords(table_name="historical_transect_proposal")

    class Meta:
        db_table = "transect_proposal"
        indexes = [models.Index(fields=["project", "status"], name="proposal_proj_status_idx")]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(reason__in=ProposalReason.values), name="proposal_reason_valid"
            ),
            models.CheckConstraint(
                condition=models.Q(status__in=ProposalStatus.values), name="proposal_status_valid"
            ),
            models.CheckConstraint(
                condition=models.Q(recorded_to__gte=models.F("recorded_from")),
                name="proposal_times_ordered",
            ),
            models.CheckConstraint(
                condition=models.Q(status=ProposalStatus.PENDING)
                | (models.Q(reviewed_by__isnull=False) & models.Q(reviewed_at__isnull=False)),
                name="proposal_reviewed_fields",
            ),
            models.CheckConstraint(
                condition=~models.Q(status=ProposalStatus.ACCEPTED)
                | models.Q(created_transect__isnull=False),
                name="proposal_accepted_transect",
            ),
        ]
        # The geometry CHECKs (proposal_geom_valid, proposal_geom_points) call PostGIS functions,
        # so they are added by RunSQL in the migration (D-098).

    def __str__(self):
        return f"{self.name} ({self.status})"
