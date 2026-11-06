from zoneinfo import available_timezones

from django import forms
from django.contrib import admin, messages
from django.core.exceptions import PermissionDenied
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import transaction
from django.db.models.fields.files import FieldFile
from django.http import FileResponse, HttpResponseBadRequest
from django.shortcuts import get_object_or_404
from django.template.response import TemplateResponse
from django.urls import path
from django.utils.translation import gettext_lazy as _
from rest_framework.exceptions import ValidationError

from apps.core.admin import HistoryAdmin, MapAdmin, SyncableAdmin
from apps.core.widgets import EditableMapWidget, SearchableSelect
from apps.exports import geopackage, service
from apps.projects.models import Project, ProjectMembership, ProjectProtocol
from apps.projects.services import (
    AreaFileError,
    close_project,
    inspect_basemap,
    multipolygon_from_file,
    projects_for,
    reopen_project,
)


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


def time_zone_choices():
    """Region/City names (Europe/Belgrade) plus UTC, for the protocol's time zone list.

    The old aliases (Cuba, GB, EST5EDT, Etc/GMT+5 ...) are left out: a researcher picks a place.
    """
    names = [
        name
        for name in available_timezones()
        if "/" in name and not name.startswith(("Etc/", "posix/", "right/"))
    ]
    return [(name, name) for name in sorted(names + ["UTC"])]


class ProjectProtocolForm(forms.ModelForm):
    """Keeps the stored time zone selectable when it is not in the shortened list.

    A zone saved earlier as free text (Etc/UTC, Cuba ...) is still valid for the model, so it is
    added at the top of the choices. Otherwise every edit of that protocol would be refused.
    """

    class Meta:
        model = ProjectProtocol
        fields = "__all__"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        stored = self.instance.time_zone if self.instance.pk else None
        field = self.fields.get("time_zone")
        if field is not None and stored and stored not in dict(field.choices):
            field.choices = [(stored, stored), *field.choices]


class ProjectProtocolInline(HelpTextMixin, admin.StackedInline):
    """One protocol per project. It is created with the project (signal), so there is no add."""

    model = ProjectProtocol
    form = ProjectProtocolForm
    can_delete = False
    max_num = 1
    extra = 0
    exclude = ["server_version", "deleted_at", "created_by", "updated_by"]

    def formfield_for_dbfield(self, db_field, request, **kwargs):
        if db_field.name == "time_zone":
            # A list with a search box instead of a text box, so a typo is not possible.
            return forms.ChoiceField(
                choices=time_zone_choices(),
                initial=db_field.default,
                label=_("Time zone"),
                widget=SearchableSelect(attrs={"class": "searchable-select"}),
                help_text=self.help_texts["time_zone"],
            )
        return super().formfield_for_dbfield(db_field, request, **kwargs)

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
            "Time zone of the study site. Type to search, e.g. Belgrade. The season dates and "
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


class ProjectForm(forms.ModelForm):
    """Checks a new basemap upload (T060). The size and hash are kept for `save_model`."""

    class Meta:
        model = Project
        fields = "__all__"

    def clean_basemap(self):
        basemap = self.cleaned_data["basemap"]
        self.basemap_info = None
        # An upload is a new file; False is the "Clear" box; anything else is the stored file.
        if basemap and not isinstance(basemap, FieldFile):
            self.basemap_info = inspect_basemap(basemap)
        return basemap


class ProjectReasonForm(forms.Form):
    """The reason the Close and Reopen actions ask for. It becomes the project's history reason."""

    reason = forms.CharField(
        label=_("Reason"),
        min_length=10,
        strip=True,
        widget=forms.Textarea(attrs={"rows": 3}),
        help_text=_("At least 10 characters. It is kept in the project's history."),
    )


class ClosedFilter(admin.SimpleListFilter):
    title = _("closed")
    parameter_name = "closed"

    def lookups(self, request, model_admin):
        return [("yes", _("Yes")), ("no", _("No"))]

    def queryset(self, request, queryset):
        if self.value() == "yes":
            return queryset.filter(closed_at__isnull=False)
        if self.value() == "no":
            return queryset.filter(closed_at__isnull=True)
        return queryset


class ProjectMembershipInline(admin.TabularInline):
    model = ProjectMembership
    extra = 1
    autocomplete_fields = ["user"]
    fields = ["user", "added_by", "created_at"]
    readonly_fields = ["added_by", "created_at"]


@admin.register(Project)
class ProjectAdmin(HelpTextMixin, HistoryAdmin, SyncableAdmin, MapAdmin):
    list_display = ["name", "owner", "start_date", "end_date", "active", "closed"]
    list_filter = ["active", ClosedFilter]
    search_fields = ["name"]
    autocomplete_fields = ["owner"]
    form = ProjectForm
    # Explicit order: the inherited sync fields would otherwise come first.
    fields = [
        "name",
        "description",
        "owner",
        "start_date",
        "end_date",
        "default_crs",
        "active",
        "closed_at",
        "closed_by",
        "area",
        "taxon_list_version",
        "basemap",
        "basemap_size",
        "basemap_sha256",
        "server_version",
        "created_at",
        "created_by",
        "updated_at",
        "updated_by",
    ]
    readonly_fields = ["closed_at", "closed_by", "basemap_size", "basemap_sha256"]
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
        "basemap": (
            "Offline map for the phones: an MBTiles file, 200 MB at most (see "
            "docs/setup/basemap.md). Phones download it with the project; its size shows on "
            "the Download button."
        ),
        "area": (
            "Study area outline. Draw it on the map, or use the 'Import study area' action on the "
            "project list. Optional; observations outside it are flagged."
        ),
    }
    actions = [*SyncableAdmin.actions, "import_area", "close_selected", "reopen_selected"]
    change_form_template = "admin/projects/project/change_form.html"

    def get_urls(self):
        return [
            path(
                "<uuid:pk>/export-bundle/",
                self.admin_site.admin_view(self.export_bundle_view),
                name="projects_project_export_bundle",
            ),
            *super().get_urls(),
        ]

    def export_bundle_view(self, request, pk):
        """The project's ZIP bundle, or with ?format=gpkg its GeoPackage (T065, T066), with the
        API defaults (D-101)."""
        project = get_object_or_404(projects_for(request.user), pk=pk)
        if not self.has_view_permission(request, project):
            raise PermissionDenied
        try:
            fmt = service.parse_bundle_format(request.GET)
        except ValidationError:  # a DRF error: a plain admin view must answer it itself
            return HttpResponseBadRequest("Use format=gpkg, or no format for the ZIP.")
        filters = service.parse_filters({"project": str(pk)})
        if fmt == "gpkg":
            return geopackage.response(request.user, filters)
        file, filename = service.bundle(request.user, filters)
        return FileResponse(file, as_attachment=True, filename=filename)

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

    @admin.display(boolean=True, description=_("Closed"), ordering="closed_at")
    def closed(self, obj):
        return obj.closed_at is not None

    @admin.action(description=_("Close project…"), permissions=["change"])
    def close_selected(self, request, queryset):
        return self._ask_for_reason(
            request,
            queryset,
            "close_selected",
            _("Close project"),
            _(
                "Closing stops all new and changed data in the selected projects: no new visits, "
                "observations, plants, habitats or route proposals, and no edits or deletes, "
                "visits in progress included. What a phone recorded before the close still "
                "syncs. Admin work here is not affected. Members and data are kept. Reopen "
                "undoes it, and its reason is kept in the history."
            ),
            close_project,
            _("Closed %(count)d project(s)."),
        )

    @admin.action(description=_("Reopen project…"), permissions=["change"])
    def reopen_selected(self, request, queryset):
        return self._ask_for_reason(
            request,
            queryset,
            "reopen_selected",
            _("Reopen project"),
            _("Reopening lets the selected projects take new visits again."),
            reopen_project,
            _("Reopened %(count)d project(s)."),
        )

    def _ask_for_reason(self, request, queryset, action, title, intro, change, done_message):
        """The page between the list and the change: the selected projects and a reason form.

        The list posts the action; this page posts back with "apply". Each project is locked and
        changed on its own, so one refused project does not stop the others.
        """
        ids = list(queryset.filter(pk__in=projects_for(request.user)).values_list("pk", flat=True))
        projects = list(Project.objects.filter(pk__in=ids).order_by("name"))
        if not projects:
            self.message_user(request, _("Select at least one project."), messages.ERROR)
            return None
        form = ProjectReasonForm(request.POST if "apply" in request.POST else None)
        if "apply" in request.POST and form.is_valid():
            done, refused = 0, []
            for pk in ids:
                try:
                    with transaction.atomic():
                        project = Project.objects.select_for_update().get(pk=pk)
                        change(project, request.user, form.cleaned_data["reason"])
                    done += 1
                except DjangoValidationError as error:
                    refused.append(" ".join(error.messages))
            if done or not refused:
                self.message_user(request, done_message % {"count": done})
            if refused:
                self.message_user(
                    request, _("Not changed: %(p)s") % {"p": "; ".join(refused)}, messages.ERROR
                )
            return None
        context = {
            **self.admin_site.each_context(request),
            "title": title,
            "intro": intro,
            "opts": self.model._meta,
            "projects": projects,
            "form": form,
            "action": action,
            "action_checkbox_name": admin.helpers.ACTION_CHECKBOX_NAME,
        }
        return TemplateResponse(request, "admin/projects/project/project_reason.html", context)

    def get_changeform_initial_data(self, request):
        return {"owner": request.user.pk}

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        # A new upload gets its size and hash (the hash is in the MinIO key); Clear empties them.
        # The old object stays in MinIO, like replaced photos (D-072).
        if form.basemap_info is not None:
            obj.basemap_size, obj.basemap_sha256 = form.basemap_info
        elif not obj.basemap:
            obj.basemap_size, obj.basemap_sha256 = None, ""
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
