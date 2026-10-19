from datetime import time
from decimal import Decimal

from django.conf import settings
from django.contrib.gis.db import models as gis_models
from django.core.exceptions import ValidationError
from django.db import models
from simple_history.models import HistoricalRecords

from apps.core.models import SyncableModel


class Project(SyncableModel):
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="owned_projects"
    )
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    default_crs = models.PositiveIntegerField(default=4326)  # EPSG code
    active = models.BooleanField(default=True)
    area = gis_models.MultiPolygonField(srid=4326, null=True, blank=True)  # study area
    # Which butterfly list release this project uses. New projects get the current one (signal).
    taxon_list_version = models.ForeignKey(
        "catalogues.TaxonListVersion",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="projects",
    )
    history = HistoricalRecords(table_name="historical_project")

    class Meta:
        db_table = "project"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(end_date__isnull=True)
                | models.Q(end_date__gte=models.F("start_date")),
                name="project_dates_ok",
            ),
        ]

    def __str__(self):
        return self.name

    def clean(self):
        # Same rule as project_dates_ok, raised on the field so forms show it next to End date.
        if self.start_date and self.end_date and self.end_date < self.start_date:
            raise ValidationError({"end_date": "End date cannot be before the start date."})


class ProjectMembership(models.Model):
    """Not synced (bigint PK, no trigger). Pull scopes projects by membership instead."""

    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name="memberships")
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="memberships"
    )
    added_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT, null=True, blank=True, related_name="+"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    history = HistoricalRecords(table_name="historical_project_membership")

    class Meta:
        db_table = "project_membership"
        constraints = [
            models.UniqueConstraint(fields=["project", "user"], name="project_membership_unique")
        ]

    def __str__(self):
        return f"{self.user} in {self.project}"


class SurveyMethod(models.TextChoices):
    POLLARD_WALK = "pollard_walk", "Pollard walk"
    OTHER = "other", "Other"


class ProjectProtocol(SyncableModel):
    """Survey protocol of one project. Validation (T055) and flags (T056) read these values.

    Defaults are the proposals in docs/requirements/protocol.md.
    """

    project = models.OneToOneField(Project, on_delete=models.CASCADE, related_name="protocol")
    protocol_version = models.CharField(max_length=20, default="1.0")
    survey_method = models.CharField(
        max_length=20, choices=SurveyMethod.choices, default=SurveyMethod.POLLARD_WALK
    )
    season_start = models.DateField()
    season_end = models.DateField()
    day_start_time = models.TimeField(default=time(10, 0))
    day_end_time = models.TimeField(default=time(17, 0))
    min_temperature_c = models.DecimalField(max_digits=4, decimal_places=1, default=Decimal("13.0"))
    sunny_temperature_c = models.DecimalField(
        max_digits=4, decimal_places=1, default=Decimal("17.0")
    )
    max_cloud_cover_pct_if_cool = models.PositiveSmallIntegerField(default=40)
    max_wind_beaufort = models.PositiveSmallIntegerField(default=5)
    allow_precipitation = models.BooleanField(default=False)
    target_visits_per_season = models.PositiveSmallIntegerField(default=8)
    max_distance_from_transect_m = models.DecimalField(
        max_digits=6, decimal_places=1, default=Decimal("20.0")
    )
    observation_time_tolerance_min = models.PositiveSmallIntegerField(default=5)
    gps_interval_s = models.PositiveSmallIntegerField(default=5)
    gps_interval_battery_saver_s = models.PositiveSmallIntegerField(default=15)
    gps_accuracy_warning_m = models.DecimalField(
        max_digits=6, decimal_places=1, default=Decimal("25.0")
    )
    gps_gap_s = models.PositiveSmallIntegerField(default=60)
    high_count_threshold = models.PositiveIntegerField(default=50)
    min_coverage_pct = models.PositiveSmallIntegerField(default=80)
    history = HistoricalRecords(table_name="historical_project_protocol")

    class Meta:
        db_table = "project_protocol"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(season_end__gte=models.F("season_start")),
                name="protocol_season_ok",
            ),
            models.CheckConstraint(
                condition=models.Q(day_end_time__gt=models.F("day_start_time")),
                name="protocol_day_window_ok",
            ),
            models.CheckConstraint(
                condition=models.Q(max_wind_beaufort__lte=12), name="protocol_wind_ok"
            ),
            models.CheckConstraint(
                condition=models.Q(max_cloud_cover_pct_if_cool__lte=100)
                & models.Q(min_coverage_pct__lte=100),
                name="protocol_pct_ok",
            ),
            models.CheckConstraint(
                condition=models.Q(gps_interval_s__gte=1)
                & models.Q(gps_interval_battery_saver_s__gte=models.F("gps_interval_s")),
                name="protocol_gps_interval_ok",
            ),
        ]

    def __str__(self):
        return f"Protocol of {self.project}"

    def clean(self):
        # Same rules as the check constraints, raised on the fields so forms show them there.
        errors = {}
        if self.season_start and self.season_end and self.season_end < self.season_start:
            errors["season_end"] = "Season end cannot be before the season start."
        if self.day_start_time and self.day_end_time and self.day_end_time <= self.day_start_time:
            errors["day_end_time"] = "Day window must end after it starts."
        if (
            self.gps_interval_s is not None
            and self.gps_interval_battery_saver_s is not None
            and self.gps_interval_battery_saver_s < self.gps_interval_s
        ):
            errors["gps_interval_battery_saver_s"] = (
                "Battery-saver interval cannot be shorter than the normal interval."
            )
        if errors:
            raise ValidationError(errors)
