from django import forms
from django.contrib import admin
from django.contrib.gis.forms.widgets import OpenLayersWidget
from django.utils.html import format_html
from django.utils.translation import gettext_lazy as _

from apps.core.admin import HistoryAdmin, MapAdmin, SyncableAdmin
from apps.observations.admin import PhotoInline
from apps.resources.models import PlantResourceObservation


@admin.register(PlantResourceObservation)
class PlantResourceObservationAdmin(HistoryAdmin, SyncableAdmin, MapAdmin):
    """Plant records are recorded on the phone and pushed through the API, so this page only
    shows them (T051), with their photos: the thumbnail opens the original. Like `PhotoAdmin`:
    no add, no change, no actions. A read-only map shows the point or the polygon (the form's own
    map widget is for editing, and a page without change permission shows plain text instead)."""

    inlines = [PhotoInline]
    list_display = [
        "observed_at",
        "plant",
        "resource_type",
        "project",
        "survey_visit",
        "created_by",
        "patch_area_m2",
    ]
    list_filter = ["project", "resource_type"]
    search_fields = ["plant_taxon__scientific_name", "notes"]
    ordering = ["-observed_at"]
    list_select_related = ["plant_taxon", "project", "survey_visit__transect", "created_by"]

    @property
    def media(self):
        # OpenLayers as Django's GIS widgets load it, plus the script that draws the geometry.
        return (
            super().media
            + forms.Media(css=OpenLayersWidget.Media.css, js=OpenLayersWidget.Media.js[:1])
            + forms.Media(js=["core/readonly_map.js"])
        )

    def get_fields(self, request, obj=None):
        fields = [field.name for field in PlantResourceObservation._meta.fields]
        # The map goes right after the geometry text.
        fields.insert(fields.index("geometry") + 1, "location_map")
        return fields

    def get_readonly_fields(self, request, obj=None):
        return [*self.get_fields(request, obj)]

    @admin.display(description=_("Map"))
    def location_map(self, plant):
        """The point or polygon on a map. `format_html` escapes the GeoJSON in the attribute. The
        width is not a percentage: the admin puts read-only values in a flex box, where a
        percentage collapses to 0 and the map draws nothing."""
        if plant.geometry is None:
            return "-"
        return format_html(
            '<div class="readonly-geometry-map" data-geojson="{}" '
            'style="width: clamp(320px, calc(100vw - 640px), 720px); height: 380px;"></div>',
            plant.geometry.geojson,
        )

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def get_actions(self, request):
        return {}

    @admin.display(description=_("Plant"), ordering="plant_taxon__scientific_name")
    def plant(self, plant_resource):
        return plant_resource.plant_taxon or _("Unidentified plant")
