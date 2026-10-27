from django.conf import settings
from django.contrib.gis.db import models as gis_models
from django.contrib.postgres.fields import ArrayField
from django.contrib.postgres.indexes import GinIndex
from django.db import models
from simple_history.models import HistoricalRecords

from apps.core.models import SyncableModel
from apps.projects.models import SurveyMethod


class VisitStatus(models.TextChoices):
    """The lifecycle of a visit. Allowed moves are in `surveys.state.TRANSITIONS`."""

    DRAFT = "draft", "Draft"
    IN_PROGRESS = "in_progress", "In progress"
    COMPLETED = "completed", "Completed"
    SYNCED = "synced", "Synced"
    REVIEWED = "reviewed", "Reviewed"
    LOCKED = "locked", "Locked"
    CANCELLED = "cancelled", "Cancelled"


class CancelReason(models.TextChoices):
    NOT_CONDUCTED = "not_conducted", "Not conducted"
    ABORTED_WEATHER = "aborted_weather", "Aborted: weather"
    ABORTED_OTHER = "aborted_other", "Aborted: other"
    INVALID_PROTOCOL = "invalid_protocol", "Invalid protocol"


class Precipitation(models.TextChoices):
    NONE = "none", "None"
    DRIZZLE = "drizzle", "Drizzle"
    LIGHT_RAIN = "light_rain", "Light rain"
    RAIN = "rain", "Rain"


class SurveyVisit(SyncableModel):
    """One standardised walk of a transect: who, when, conditions, effort and status (T034).

    "Missing data" is the absence of a visit row (outline 7.3): a visit that was planned but not
    walked is a `cancelled` row with `cancel_reason = not_conducted`.
    """

    project = models.ForeignKey("projects.Project", on_delete=models.PROTECT, related_name="visits")
    transect = models.ForeignKey(
        "transects.Transect", on_delete=models.PROTECT, related_name="visits"
    )
    observer = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="visits"
    )
    protocol_version = models.CharField(max_length=20)
    survey_method = models.CharField(
        max_length=20, choices=SurveyMethod.choices, default=SurveyMethod.POLLARD_WALK
    )
    started_at = models.DateTimeField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    duration_seconds = models.PositiveIntegerField(null=True, blank=True)  # excludes pauses
    paused_seconds = models.PositiveIntegerField(default=0)
    # The phone sends its own figure; the server replaces it with the one from the track points
    # when it has at least two usable points (T036, surveys.services.set_distance_if_finished).
    distance_walked_m = models.DecimalField(max_digits=8, decimal_places=1, null=True, blank=True)
    observer_count = models.PositiveSmallIntegerField(default=1)
    observer_names = models.CharField(max_length=300, blank=True)
    temperature_start_c = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
    temperature_end_c = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
    wind_beaufort_start = models.PositiveSmallIntegerField(null=True, blank=True)
    wind_beaufort_end = models.PositiveSmallIntegerField(null=True, blank=True)
    cloud_cover_start_pct = models.PositiveSmallIntegerField(null=True, blank=True)
    cloud_cover_end_pct = models.PositiveSmallIntegerField(null=True, blank=True)
    precipitation = models.CharField(
        max_length=12, choices=Precipitation.choices, default=Precipitation.NONE
    )
    weather_suitable = models.BooleanField(null=True)
    weather_missing_reason = models.CharField(max_length=200, blank=True)
    zero_observation_confirmed = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    status = models.CharField(max_length=12, choices=VisitStatus.choices, default=VisitStatus.DRAFT)
    cancel_reason = models.CharField(max_length=20, choices=CancelReason.choices, blank=True)
    battery_saver_used = models.BooleanField(default=False)
    device_id = models.CharField(max_length=64, blank=True)
    created_offline = models.BooleanField(default=True)
    # Set by surveys.state.transition() on lock (admin, T043). Server-owned.
    locked_at = models.DateTimeField(null=True, blank=True)
    locked_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="+",
    )
    lock_reason = models.TextField(blank=True)
    quality_flags = ArrayField(models.CharField(max_length=40), default=list, blank=True)  # T056
    history = HistoricalRecords(table_name="historical_survey_visit")

    class Meta:
        db_table = "survey_visit"
        indexes = [
            models.Index(fields=["project", "transect", "started_at"]),
            models.Index(fields=["observer", "started_at"]),
            models.Index(fields=["status"]),
            GinIndex(fields=["quality_flags"], name="survey_visit_flags_gin"),
        ]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(status__in=VisitStatus.values), name="visit_status_valid"
            ),
            models.CheckConstraint(
                condition=models.Q(precipitation__in=Precipitation.values),
                name="visit_precip_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(survey_method__in=SurveyMethod.values),
                name="visit_survey_method_valid",
            ),
            models.CheckConstraint(
                condition=(
                    models.Q(status=VisitStatus.CANCELLED)
                    & models.Q(cancel_reason__in=CancelReason.values)
                )
                | (~models.Q(status=VisitStatus.CANCELLED) & models.Q(cancel_reason="")),
                name="visit_cancel_reason_consistent",
            ),
            models.CheckConstraint(
                condition=models.Q(ended_at__isnull=True)
                | models.Q(started_at__isnull=True)
                | models.Q(ended_at__gte=models.F("started_at")),
                name="visit_times_ok",
            ),
            models.CheckConstraint(
                condition=models.Q(observer_count__gte=1), name="visit_observer_count_ok"
            ),
            models.CheckConstraint(
                condition=(
                    models.Q(wind_beaufort_start__isnull=True)
                    | models.Q(wind_beaufort_start__lte=12)
                )
                & (models.Q(wind_beaufort_end__isnull=True) | models.Q(wind_beaufort_end__lte=12)),
                name="visit_wind_ok",
            ),
            models.CheckConstraint(
                condition=(
                    models.Q(cloud_cover_start_pct__isnull=True)
                    | models.Q(cloud_cover_start_pct__lte=100)
                )
                & (
                    models.Q(cloud_cover_end_pct__isnull=True)
                    | models.Q(cloud_cover_end_pct__lte=100)
                ),
                name="visit_cloud_ok",
            ),
            models.CheckConstraint(
                condition=~models.Q(status=VisitStatus.LOCKED) | models.Q(locked_at__isnull=False),
                name="visit_locked_has_timestamp",
            ),
        ]

    def __str__(self):
        start = self.started_at.strftime("%Y-%m-%d %H:%M") if self.started_at else "not started"
        return f"{self.transect} · {start} · {self.status}"


class LocationProvider(models.TextChoices):
    GPS = "gps", "GPS"
    FUSED = "fused", "Fused"
    NETWORK = "network", "Network"
    SIMULATED = "simulated", "Simulated"


class SurveyTrackPoint(SyncableModel):
    """One GPS fix of a visit, as recorded on the phone (T036).

    Append-only and high volume, so no history (CONVENTIONS A.5.7). Points are never thinned or
    simplified: they are the raw input for the Phase 2 MobilityDB trajectories (T088).
    """

    survey_visit = models.ForeignKey(
        SurveyVisit, on_delete=models.CASCADE, related_name="track_points"
    )
    recorded_at = models.DateTimeField()
    geometry = gis_models.PointField(srid=4326)
    accuracy_m = models.DecimalField(max_digits=6, decimal_places=1, null=True, blank=True)
    altitude_m = models.DecimalField(max_digits=7, decimal_places=1, null=True, blank=True)
    speed_m_s = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    heading_deg = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    provider = models.CharField(
        max_length=10, choices=LocationProvider.choices, default=LocationProvider.GPS
    )
    sequence_number = models.PositiveIntegerField()

    class Meta:
        db_table = "survey_track_point"
        indexes = [models.Index(fields=["survey_visit", "recorded_at"])]
        constraints = [
            models.UniqueConstraint(
                fields=["survey_visit", "sequence_number"], name="track_point_seq_unique"
            ),
            models.CheckConstraint(
                condition=models.Q(provider__in=LocationProvider.values),
                name="track_point_provider_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(heading_deg__isnull=True)
                | (models.Q(heading_deg__gte=0) & models.Q(heading_deg__lt=360)),
                name="track_point_heading_ok",
            ),
        ]

    def __str__(self):
        return f"{self.survey_visit_id} #{self.sequence_number}"
