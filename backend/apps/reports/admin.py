from django.contrib import admin
from django.contrib.admin import RelatedOnlyFieldListFilter
from django.http import StreamingHttpResponse
from django.utils.translation import gettext_lazy as _

from apps.exports.writers import csv_chunks
from apps.projects.services import projects_for
from apps.reports.models import BehaviourCounts, SpeciesPhenology, TransectIndicators


class ReportAdmin(admin.ModelAdmin):
    """A read-only changelist over a report view (T061, D-099). Rows are limited to the projects
    the user may see. The CSV action is T061's own; T065 may switch it to the export service."""

    list_display_links = None
    actions = ["export_csv"]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def get_queryset(self, request):
        return super().get_queryset(request).filter(project__in=projects_for(request.user))

    @admin.action(description=_("Export selected as CSV"), permissions=["view"])
    def export_csv(self, request, queryset):
        # The row_id is a key for Django, not a column of the report. Relations are written as
        # their id (`project_id`).
        names = [f.attname for f in self.model._meta.fields if f.name != "row_id"]
        rows = queryset.values(*names)
        table = self.model._meta.db_table
        response = StreamingHttpResponse(
            csv_chunks(names, rows, na=""), content_type="text/csv; charset=utf-8"
        )
        response["Content-Disposition"] = f'attachment; filename="{table}.csv"'
        return response


@admin.register(TransectIndicators)
class TransectIndicatorsAdmin(ReportAdmin):
    list_display = [
        "project",
        "transect_code",
        "year",
        "visits_completed",
        "valid_visits",
        "true_zero_visits",
        "target_visits",
        "total_hours",
        "total_km",
        "species_count",
        "individuals",
        "observations",
        "confirmed_obs",
        "to_review_obs",
        "individuals_per_km",
        "individuals_per_hour",
    ]
    list_filter = [
        ("project", RelatedOnlyFieldListFilter),
        "year",
        ("transect", RelatedOnlyFieldListFilter),
    ]
    list_select_related = ["project"]
    ordering = ["-year", "project", "transect_code"]


@admin.register(SpeciesPhenology)
class SpeciesPhenologyAdmin(ReportAdmin):
    list_display = [
        "project",
        "taxon",
        "year",
        "iso_week",
        "individuals",
        "observations",
        "first_date",
        "last_date",
    ]
    list_filter = [("project", RelatedOnlyFieldListFilter), "year", "taxon__family"]
    list_select_related = ["project", "taxon"]
    ordering = ["-year", "-iso_week", "taxon__scientific_name"]


@admin.register(BehaviourCounts)
class BehaviourCountsAdmin(ReportAdmin):
    list_display = ["project", "year", "behaviour", "records"]
    list_filter = [("project", RelatedOnlyFieldListFilter), "year"]
    list_select_related = ["project"]
    ordering = ["-year", "project", "-records"]
