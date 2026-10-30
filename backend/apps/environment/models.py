import uuid

from django.db import models


class SourceType(models.TextChoices):
    MANUAL = "manual"
    SENSORTHINGS = "sensorthings"
    EDR = "edr"
    OTHER_API = "other_api"


class SnapshotMoment(models.TextChoices):
    START = "start"
    END = "end"
    VISIT_MEAN = "visit_mean"
    AT_OBSERVATION = "at_observation"


class EnvironmentalSnapshot(models.Model):
    """Environmental values stored with a visit or an observation (T063), so an analysis can be
    repeated even if a remote source changes. Phase 1 fills it from the visit's manual start and
    end weather; Phase 2 adds SensorThings (T081) and EDR (T084) rows with no schema change.
    Server-only derived data: not a `SyncableModel`, no trigger, no history.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    survey_visit = models.ForeignKey(
        "surveys.SurveyVisit",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="environmental_snapshots",
        help_text="Visit the values describe",
    )
    observation = models.ForeignKey(
        "observations.ButterflyObservation",
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="environmental_snapshots",
        help_text="Observation the values describe, for at-observation snapshots",
    )
    source_type = models.CharField(
        max_length=15,
        choices=SourceType.choices,
        help_text="Where the values came from: manual, sensorthings, edr or other_api",
    )
    moment = models.CharField(
        max_length=15,
        choices=SnapshotMoment.choices,
        help_text="Moment described: start, end, visit_mean or at_observation",
    )
    source_uri = models.TextField(blank=True, help_text="URI the values were read from, if remote")
    retrieved_at = models.DateTimeField(
        auto_now_add=True, help_text="When the server stored the snapshot (UTC, ISO 8601)"
    )
    phenomenon_time_start = models.DateTimeField(
        help_text="Time the values refer to, or the start of the interval (UTC, ISO 8601)"
    )
    # An interval when the values are aggregated.
    phenomenon_time_end = models.DateTimeField(
        null=True, blank=True, help_text="End of the interval when aggregated (UTC, ISO 8601)"
    )
    temperature_c = models.DecimalField(
        max_digits=4, decimal_places=1, null=True, blank=True, help_text="Air temperature, °C"
    )
    relative_humidity_pct = models.DecimalField(
        max_digits=4,
        decimal_places=1,
        null=True,
        blank=True,
        help_text="Relative humidity, %",
    )
    wind_speed_m_s = models.DecimalField(
        max_digits=5, decimal_places=2, null=True, blank=True, help_text="Wind speed, m/s"
    )
    wind_direction_deg = models.DecimalField(
        max_digits=5,
        decimal_places=1,
        null=True,
        blank=True,
        help_text="Wind direction, degrees clockwise from north",
    )
    cloud_cover_pct = models.DecimalField(
        max_digits=4, decimal_places=1, null=True, blank=True, help_text="Cloud cover, %"
    )
    precipitation_mm = models.DecimalField(
        max_digits=6, decimal_places=2, null=True, blank=True, help_text="Precipitation, mm"
    )
    solar_radiation_w_m2 = models.DecimalField(
        max_digits=6,
        decimal_places=1,
        null=True,
        blank=True,
        help_text="Solar radiation, W/m²",
    )
    # Phase 2 SensorThings and EDR values are simulated.
    is_simulated = models.BooleanField(
        default=False, help_text="The values come from the simulator, not a real sensor"
    )
    raw_payload_json = models.JSONField(
        default=dict, blank=True, help_text="Source response kept as received, JSON"
    )

    def __str__(self):
        return f"{self.source_type} {self.moment} · {self.phenomenon_time_start:%Y-%m-%d %H:%M}"

    class Meta:
        db_table = "environmental_snapshot"
        indexes = [models.Index(fields=["survey_visit", "source_type"])]
        constraints = [
            models.CheckConstraint(
                condition=models.Q(survey_visit__isnull=False)
                | models.Q(observation__isnull=False),
                name="env_snapshot_has_target",
            ),
            models.CheckConstraint(
                condition=models.Q(source_type__in=SourceType.values),
                name="env_snapshot_source_valid",
            ),
            models.CheckConstraint(
                condition=models.Q(moment__in=SnapshotMoment.values),
                name="env_snapshot_moment_valid",
            ),
            models.UniqueConstraint(
                fields=["survey_visit", "source_type", "moment"],
                condition=models.Q(observation__isnull=True),
                name="env_snapshot_unique_visit_moment",
            ),
        ]
