import json
import uuid

from django.contrib import admin
from django.core.exceptions import PermissionDenied
from django.http import JsonResponse
from django.shortcuts import get_object_or_404
from django.urls import path, reverse
from django.utils.translation import gettext_lazy as _

from apps.core.admin import HistoryAdmin, MapAdmin, SyncableAdmin
from apps.core.widgets import LineMapWidget
from apps.transects.models import Transect, TransectSection
from apps.transects.services import SECTION_TOLERANCE_M


def line_widget_kwargs(note):
    """MapAdmin's map settings plus a line of field-specific help in the "?" popup."""
    return {"attrs": {**MapAdmin.gis_widget_kwargs["attrs"], "help_note": note}}


# Plain forms for now; T022 adds the map editor, line import and section generation.
@admin.register(Transect)
class TransectAdmin(HistoryAdmin, SyncableAdmin, MapAdmin):
    list_display = ["code", "name", "project", "active"]
    list_select_related = ["project"]
    list_filter = ["project", "active"]
    search_fields = ["code", "name"]
    autocomplete_fields = ["project"]
    # Soft delete and restore are list actions, so the field is not edited on the form.
    exclude = ["deleted_at"]
    gis_widget = LineMapWidget
    gis_widget_kwargs = line_widget_kwargs(
        _("Draw the route in the direction it is walked; sections are numbered along it.")
    )

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(TransectSection)
class TransectSectionAdmin(HistoryAdmin, SyncableAdmin, MapAdmin):
    list_display = [
        "section_code",
        "transect",
        "sequence_number",
        "habitat_type",
        "active_transect",
    ]
    list_select_related = ["transect", "habitat_type"]
    list_filter = ["transect__project", "transect", "habitat_type"]
    search_fields = ["section_code", "transect__code", "transect__name"]
    autocomplete_fields = ["transect", "habitat_type", "management_type"]
    exclude = ["deleted_at"]
    gis_widget = LineMapWidget
    gis_widget_kwargs = line_widget_kwargs(
        _(
            "Pick the transect first: its line is shown dashed, and new points snap to it. "
            "The section must lie within %(m)g m of that line along its whole length."
        )
        % {"m": SECTION_TOLERANCE_M}
    )

    class Media:
        js = ("transects/section_map.js",)

    def get_urls(self):
        line = path(
            "transect-line/<uuid:pk>/",
            self.admin_site.admin_view(self.transect_line),
            name="transects_transectsection_transect_line",
        )
        return [line, *super().get_urls()]

    def transect_line(self, request, pk):
        """The transect's line as GeoJSON, for the reference line on the section map."""
        if not self.has_view_or_change_permission(request):
            raise PermissionDenied
        transect = get_object_or_404(Transect.objects.alive(), pk=pk)
        return JsonResponse(
            {"code": transect.code, "geometry": json.loads(transect.geometry.geojson)}
        )

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        field = super().formfield_for_foreignkey(db_field, request, **kwargs)
        if db_field.name == "transect":
            # section_map.js swaps the zero UUID for the chosen transect's id.
            field.widget.attrs["data-line-url"] = reverse(
                "admin:transects_transectsection_transect_line", args=[uuid.UUID(int=0)]
            )
        return field

    @admin.display(boolean=True, description="Transect active")
    def active_transect(self, section):
        return section.transect.active

    def get_map_center(self, request, obj):
        line = obj.transect.geometry
        return line.centroid.x, line.centroid.y

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)
