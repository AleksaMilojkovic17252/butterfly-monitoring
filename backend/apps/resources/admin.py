from django.contrib import admin
from django.utils.translation import gettext_lazy as _

from apps.core.admin import HistoryAdmin, MapAdmin, ReadOnlyMapMixin, SyncableAdmin
from apps.observations.admin import PhotoInline
from apps.resources.models import HabitatFeature, PlantResourceObservation


class ReadOnlyGeometryAdmin(ReadOnlyMapMixin, HistoryAdmin, SyncableAdmin, MapAdmin):
    """Base for a record that is made on the phone and pushed through the API, so the admin only
    shows it (T051, T053): no add, no change, no actions. A read-only map shows its geometry (the
    form's own map widget is for editing, and a page without change permission shows plain text
    instead)."""

    def get_fields(self, request, obj=None):
        fields = [field.name for field in self.model._meta.fields]
        # The map goes right after the geometry text.
        fields.insert(fields.index("geometry") + 1, "location_map")
        return fields

    def get_readonly_fields(self, request, obj=None):
        return [*self.get_fields(request, obj)]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def get_actions(self, request):
        return {}


@admin.register(PlantResourceObservation)
class PlantResourceObservationAdmin(ReadOnlyGeometryAdmin):
    """Plant records (T051), with their photos: the thumbnail opens the original. Like
    `PhotoAdmin`."""

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

    @admin.display(description=_("Plant"), ordering="plant_taxon__scientific_name")
    def plant(self, plant_resource):
        return plant_resource.plant_taxon or _("Unidentified plant")


@admin.register(HabitatFeature)
class HabitatFeatureAdmin(ReadOnlyGeometryAdmin):
    """Habitat features (T053). They have no photos."""

    list_display = [
        "observed_at",
        "habitat_type",
        "management_type",
        "geometry_kind",
        "project",
        "survey_visit",
        "created_by",
    ]
    list_filter = ["project", "habitat_type"]
    search_fields = ["habitat_type__name_en", "notes"]
    ordering = ["-observed_at"]
    list_select_related = [
        "habitat_type",
        "management_type",
        "project",
        "survey_visit__transect",
        "created_by",
    ]

    @admin.display(description=_("Geometry"))
    def geometry_kind(self, feature):
        return feature.geometry.geom_type
