from django.contrib import admin
from django.utils.translation import gettext_lazy as _

from apps.core.admin import HistoryAdmin, MapAdmin, SyncableAdmin
from apps.observations.admin import PhotoInline
from apps.resources.models import PlantResourceObservation


@admin.register(PlantResourceObservation)
class PlantResourceObservationAdmin(HistoryAdmin, SyncableAdmin, MapAdmin):
    """Plant records are recorded on the phone and pushed through the API, so this page only
    shows them (T051), with their photos: the thumbnail opens the original. Like `PhotoAdmin`:
    no add, no change, no actions."""

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

    def get_fields(self, request, obj=None):
        return [field.name for field in PlantResourceObservation._meta.fields]

    def get_readonly_fields(self, request, obj=None):
        return [*self.get_fields(request, obj)]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def get_actions(self, request):
        return {}

    @admin.display(description=_("Plant"), ordering="plant_taxon__scientific_name")
    def plant(self, plant_resource):
        return plant_resource.plant_taxon or _("Unidentified plant")
