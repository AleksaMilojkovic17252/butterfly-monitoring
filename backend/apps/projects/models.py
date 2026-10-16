from django.conf import settings
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
    # Added by later tickets: area (T016), taxon_list_version (T019).
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
