import uuid

from django.contrib.gis.db import models as gis_models
from django.db import models
from simple_history.models import HistoricalRecords

from apps.core.models import SyncableModel

# What a station's habitat polygon may be; a habitat feature can also be a point or a line.
HABITAT_POLYGON_TYPES = ("Polygon", "MultiPolygon")


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


class SensorStationLink(SyncableModel):
    """A simulated microclimate station (T078, D-117): where it stands, which habitat and
    transects it serves, and the ids of the SensorThings entities that stand for it in FROST.

    Admins define it; the phone gets it by pull, read-only and without the FROST ids.
    """

    project = models.ForeignKey(
        "projects.Project",
        on_delete=models.PROTECT,
        related_name="sensor_stations",
        help_text="Project the station belongs to",
    )
    code = models.CharField(max_length=20, help_text="Short code, unique in the project, e.g. S01")
    name = models.CharField(max_length=200, help_text="Name of the station")
    geometry = gis_models.PointField(srid=4326, help_text="Where the station stands, WGS 84")
    habitat_type = models.ForeignKey(
        "catalogues.HabitatType",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        help_text="Habitat type; filled from the habitat polygon when left empty",
    )
    habitat_feature = models.ForeignKey(
        "resources.HabitatFeature",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text=(
            "Habitat polygon the station measures; FROST uses it as the feature of interest, "
            "otherwise the station point"
        ),
    )
    transects = models.ManyToManyField(
        "transects.Transect",
        blank=True,
        related_name="sensor_stations",
        db_table="sensor_station_link_transect",
        help_text="Transects the station serves",
    )
    # FROST ids may be numeric or strings. Only "Register in FROST" writes these two.
    sensorthings_thing_id = models.CharField(
        "FROST Thing id",
        max_length=64,
        blank=True,
        default="",
        help_text="Id of the station's Thing in FROST; empty until it is registered",
    )
    sensorthings_datastream_ids = models.JSONField(
        "FROST Datastream ids",
        default=dict,
        blank=True,
        help_text="Datastream id for each measured property",
    )
    is_simulated = models.BooleanField(
        default=True, help_text="The values come from the simulator, not a real sensor"
    )
    active = models.BooleanField(default=True, help_text="The station is in use")
    metadata_json = models.JSONField(
        "metadata",
        default=dict,
        blank=True,
        help_text="Extra data, JSON; holds the FROST FeatureOfInterest id",
    )
    history = HistoricalRecords(table_name="historical_sensor_station_link")

    class Meta:
        db_table = "sensor_station_link"
        constraints = [
            models.UniqueConstraint(fields=["project", "code"], name="sensor_station_code_unique")
        ]

    def __str__(self):
        return f"{self.code} — {self.name}"

    @property
    def habitat_polygon(self):
        """The linked habitat feature while it is a live polygon, otherwise None. The phone can
        delete or redraw the feature after an admin has linked it."""
        habitat = self.habitat_feature
        if habitat is None or habitat.deleted_at is not None:
            return None
        return habitat if habitat.geometry.geom_type in HABITAT_POLYGON_TYPES else None
