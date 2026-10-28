from django import forms
from django.contrib import admin, messages
from django.template.response import TemplateResponse
from django.utils.translation import gettext_lazy as _

from apps.core.admin import HistoryAdmin, MapAdmin, SyncableAdmin
from apps.core.widgets import EditableMapWidget
from apps.projects.models import Project, ProjectMembership, ProjectProtocol
from apps.projects.services import AreaFileError, multipolygon_from_file


class HelpTextMixin:
    """Show a short explanation under each field listed in `help_texts`.

    Done in the admin (not as model `help_text`) so wording changes need no migration.
    """

    help_texts: dict[str, str] = {}

    def formfield_for_dbfield(self, db_field, request, **kwargs):
        field = super().formfield_for_dbfield(db_field, request, **kwargs)
        if field is not None and db_field.name in self.help_texts:
            field.help_text = self.help_texts[db_field.name]
        return field


class ProjectProtocolInline(HelpTextMixin, admin.StackedInline):
    """One protocol per project. It is created with the project (signal), so there is no add."""

    model = ProjectProtocol
    can_delete = False
    max_num = 1
    extra = 0
    exclude = ["server_version", "deleted_at", "created_by", "updated_by"]
    help_texts = {
        "protocol_version": (
            "Label for this set of rules, e.g. 1.0. Raise it when you change thresholds mid-study."
        ),
        "survey_method": (
            "Pollard walk = fixed transect walked at a steady pace, counting butterflies in a 5 m "
            "box."
        ),
        "season_start": (
            "First day of the monitoring season. Visits before it get a warning, they are not "
            "rejected."
        ),
        "season_end": "Last day of the monitoring season. Visits after it get a warning.",
        "time_zone": (
            "Time zone of the study site (IANA name, e.g. Europe/Belgrade). The season dates and "
            "the daily window below are read in it."
        ),
        "day_start_time": "Earliest local time of day a visit should start.",
        "day_end_time": (
            "Latest local time of day a visit should start. Must be after the start time."
        ),
        "min_temperature_c": (
            "Minimum air temperature (°C) when cloud cover is at most the limit below."
        ),
        "sunny_temperature_c": "Temperature (°C) at or above which any cloud cover is acceptable.",
        "max_cloud_cover_pct_if_cool": (
            "Highest cloud cover (%) allowed when the temperature is below the sunny threshold."
        ),
        "max_wind_beaufort": (
            "Highest wind force (Beaufort scale, 0-12) allowed. Pollard walks use 5."
        ),
        "allow_precipitation": "Tick only if visits in rain are acceptable. Normally off.",
        "target_visits_per_season": (
            "How many visits each transect should get per season. Shown as progress in the app."
        ),
        "max_distance_from_transect_m": (
            "Observations farther than this (metres) from the transect line are flagged, not "
            "rejected."
        ),
        "observation_time_tolerance_min": (
            "Allowed gap (minutes) between an observation's time and the visit's start-end window."
        ),
        "gps_interval_s": (
            "Seconds between GPS fixes while walking. Smaller = smoother route, more battery."
        ),
        "gps_interval_battery_saver_s": (
            "Seconds between GPS fixes in battery-saving mode. Must be at least the normal "
            "interval."
        ),
        "gps_accuracy_warning_m": "Fixes less accurate than this (metres) are marked as poor.",
        "gps_gap_s": (
            "A pause in GPS fixes longer than this (seconds) is reported as a gap in the route."
        ),
        "high_count_threshold": (
            "A single record with more individuals than this is flagged for review."
        ),
        "min_coverage_pct": (
            "Share of the transect length (%) the GPS route must cover for a visit to count as "
            "valid."
        ),
    }


class AreaImportForm(forms.Form):
    file = forms.FileField(label=_("GeoJSON or KML file"))


class ProjectMembershipInline(admin.TabularInline):
    model = ProjectMembership
    extra = 1
    autocomplete_fields = ["user"]
    fields = ["user", "added_by", "created_at"]
    readonly_fields = ["added_by", "created_at"]


@admin.register(Project)
class ProjectAdmin(HelpTextMixin, HistoryAdmin, SyncableAdmin, MapAdmin):
    list_display = ["name", "owner", "start_date", "end_date", "active"]
    list_filter = ["active"]
    search_fields = ["name"]
    autocomplete_fields = ["owner"]
    # Explicit order: the inherited sync fields would otherwise come first.
    fields = [
        "name",
        "description",
        "owner",
        "start_date",
        "end_date",
        "default_crs",
        "active",
        "area",
        "taxon_list_version",
        "server_version",
        "created_at",
        "created_by",
        "updated_at",
        "updated_by",
    ]
    inlines = [ProjectProtocolInline, ProjectMembershipInline]
    gis_widget = EditableMapWidget
    gis_widget_kwargs = {
        "attrs": {
            **MapAdmin.gis_widget_kwargs["attrs"],
            "help_note": _(
                "To load a GeoJSON or KML file, select the project on the project list and run "
                "the “Import study area from GeoJSON/KML” action."
            ),
        }
    }
    help_texts = {
        "name": "Short name shown in the app's project list.",
        "description": "Optional notes about the project: aim, site, partners.",
        "owner": "The account responsible for this project. Defaults to you.",
        "start_date": "First day of the project. Its year sets the default monitoring season.",
        "end_date": "Last day of the project. Leave empty while it is ongoing.",
        "default_crs": "EPSG code of the coordinate system used for exports. 4326 = GPS (WGS 84).",
        "active": "Untick to hide the project from new work without deleting it.",
        "taxon_list_version": (
            "Butterfly list release used for this project. New projects get the current one."
        ),
        "area": (
            "Study area outline. Draw it on the map, or use the 'Import study area' action on the "
            "project list. Optional; observations outside it are flagged."
        ),
    }
    actions = [*SyncableAdmin.actions, "import_area"]

    def get_inline_instances(self, request, obj=None):
        # The protocol row only exists after the project is saved (signal).
        return [
            inline
            for inline in super().get_inline_instances(request, obj)
            if obj is not None or not isinstance(inline, ProjectProtocolInline)
        ]

    def get_map_center(self, request, obj):
        if obj is None or obj.area is None or obj.area.empty:
            return None
        return obj.area.centroid.x, obj.area.centroid.y

    @admin.action(description=_("Import study area from GeoJSON/KML"), permissions=["change"])
    def import_area(self, request, queryset):
        if queryset.count() != 1:
            self.message_user(request, _("Select exactly one project."), messages.ERROR)
            return None
        project = queryset.get()
        form = AreaImportForm(request.POST or None, request.FILES or None)
        # The changelist posts the action; the confirm page posts back with "apply".
        if "apply" in request.POST and form.is_valid():
            try:
                project.area = multipolygon_from_file(form.cleaned_data["file"])
            except AreaFileError as exc:
                form.add_error("file", str(exc))
            else:
                project.updated_by = request.user
                project.save()
                self.message_user(request, _("Study area of %(p)s replaced.") % {"p": project})
                return None
        context = {
            **self.admin_site.each_context(request),
            "title": _("Import study area"),
            "opts": self.model._meta,
            "project": project,
            "form": form if "apply" in request.POST else AreaImportForm(),
            "action_checkbox_name": admin.helpers.ACTION_CHECKBOX_NAME,
        }
        return TemplateResponse(request, "admin/projects/import_area.html", context)

    def get_changeform_initial_data(self, request):
        return {"owner": request.user.pk}

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)

    def save_formset(self, request, form, formset, change):
        instances = formset.save(commit=False)
        for obj in formset.deleted_objects:
            obj.delete()
        for obj in instances:
            if isinstance(obj, ProjectMembership) and obj.added_by_id is None:
                obj.added_by = request.user
            if isinstance(obj, ProjectProtocol):
                obj.updated_by = request.user
            obj.save()
        formset.save_m2m()
