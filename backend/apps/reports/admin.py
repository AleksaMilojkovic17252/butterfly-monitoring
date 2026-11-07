from django.conf import settings
from django.contrib import admin
from django.contrib.admin import RelatedOnlyFieldListFilter
from django.http import StreamingHttpResponse

from apps.exports.admin_actions import ExportActionsMixin
from apps.exports.writers import csv_chunks, geojson_chunks
from apps.projects.services import projects_for
from apps.reports.models import (
    BehaviourCounts,
    HabitatRichness,
    ObservationHexgrid,
    ReproductiveMicrohabitat,
    SpecialistHostPlants,
    SpeciesPhenology,
    TransectIndicators,
    TransectProfile,
)


class ReportAdmin(ExportActionsMixin, admin.ModelAdmin):
    """A read-only changelist over a report view (T061, D-099). Rows are limited to the projects
    the user may see. The export actions are the shared ones (T065, D-101), but a report view is
    not an export dataset: the rows come straight from the selected queryset, with the missing-value
    code in CSV and `"geometry": null` in GeoJSON."""

    list_display_links = None
    actions = ExportActionsMixin.export_actions

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def get_queryset(self, request):
        return super().get_queryset(request).filter(project__in=projects_for(request.user))

    def export_response(self, request, queryset, fmt):
        # The row_id is a key for Django, not a column of the report. Relations are written as
        # their id (`project_id`).
        names = [f.attname for f in self.model._meta.fields if f.name != "row_id"]
        table = self.model._meta.db_table
        if fmt == "csv":
            rows = queryset.values(*names)
            chunks = csv_chunks(names, rows, na=settings.EXPORT_MISSING_VALUE)
            content_type, extension = "text/csv; charset=utf-8", "csv"
        else:
            rows = ({**row, "id": row["row_id"]} for row in queryset.values("row_id", *names))
            chunks = geojson_chunks(names, rows)
            content_type, extension = "application/geo+json", "geojson"
        response = StreamingHttpResponse(chunks, content_type=content_type)
        response["Content-Disposition"] = f'attachment; filename="{table}.{extension}"'
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


@admin.register(TransectProfile)
class TransectProfileAdmin(ReportAdmin):
    list_display = [
        "project",
        "transect_code",
        "year",
        "bin_start_m",
        "bin_end_m",
        "observations",
        "individuals",
        "species",
    ]
    list_filter = [
        ("project", RelatedOnlyFieldListFilter),
        ("transect", RelatedOnlyFieldListFilter),
        "year",
    ]
    list_select_related = ["project"]
    ordering = ["project", "transect_code", "-year", "bin_start_m"]


@admin.register(HabitatRichness)
class HabitatRichnessAdmin(ReportAdmin):
    list_display = [
        "project",
        "habitat_code",
        "year",
        "sections",
        "section_km",
        "valid_visits",
        "effort_km",
        "species",
        "transect_species",
        "transect_individuals",
        "individuals_per_km",
        "incidental_records",
        "incidental_individuals",
        "individuals",
    ]
    list_filter = [("project", RelatedOnlyFieldListFilter), "year", "habitat_code"]
    list_select_related = ["project"]
    ordering = ["project", "-year", "habitat_code"]


@admin.register(SpecialistHostPlants)
class SpecialistHostPlantsAdmin(ReportAdmin):
    list_display = [
        "project",
        "transect_code",
        "section_code",
        "year",
        "valid_visits",
        "specialist_species_individuals",
        "specialist_species",
        "specialist_species_per_visit",
        "host_patches",
        "host_abundance_mid",
        "radius_m",
    ]
    list_filter = [
        ("project", RelatedOnlyFieldListFilter),
        "year",
        ("transect", RelatedOnlyFieldListFilter),
    ]
    list_select_related = ["project"]
    ordering = ["project", "transect_code", "section_code", "-year"]


@admin.register(ReproductiveMicrohabitat)
class ReproductiveMicrohabitatAdmin(ReportAdmin):
    list_display = [
        "project",
        "habitat_code",
        "polygons",
        "area_m2",
        "repro_records",
        "project_repro_records",
        "record_share",
        "area_share",
        "jacobs_d",
    ]
    list_filter = [("project", RelatedOnlyFieldListFilter)]
    list_select_related = ["project"]
    ordering = ["project", "-jacobs_d"]


@admin.register(ObservationHexgrid)
class ObservationHexgridAdmin(ReportAdmin):
    """Q6 has no map here: QGIS reads the same hexagons from pygeoapi (the export writes
    `"geometry": null`, like the other reports)."""

    list_display = [
        "project",
        "id",
        "hex_size_m",
        "observations",
        "individuals",
        "species",
        "nectaring_records",
        "reproductive_records",
    ]
    list_filter = [("project", RelatedOnlyFieldListFilter)]
    list_select_related = ["project"]
    ordering = ["project", "-observations"]
