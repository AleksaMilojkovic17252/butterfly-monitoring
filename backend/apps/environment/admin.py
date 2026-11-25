import uuid

from django import forms
from django.contrib import admin, messages
from django.core.exceptions import PermissionDenied
from django.db.models import Func, IntegerField, Q
from django.http import JsonResponse
from django.shortcuts import redirect
from django.template.response import TemplateResponse
from django.urls import path, reverse
from django.utils.translation import gettext_lazy as _

from apps.core.admin import HistoryAdmin, MapAdmin, SyncableAdmin
from apps.environment import frost, services
from apps.environment.forms import CopyStationForm
from apps.environment.models import SensorStationLink
from apps.projects.services import projects_for
from apps.resources.models import HabitatFeature
from apps.transects.models import Transect


class SensorStationAdminForm(forms.ModelForm):
    def clean(self):
        data = super().clean()
        # A saved station's project is read-only, so it is not in the form's data.
        project = data.get("project") or (
            self.instance.project if self.instance.project_id else None
        )
        if project is not None:
            errors = services.station_link_errors(
                project, data.get("habitat_feature"), data.get("transects") or []
            )
            for field, message in errors.items():
                self.add_error(field, message)
        return data

    def _get_validation_exclusions(self):
        # Django skips a constraint on a field the form does not show. The code must still be
        # unique in a saved station's (read-only) project.
        exclude = super()._get_validation_exclusions()
        exclude.discard("project")
        return exclude


@admin.register(SensorStationLink)
class SensorStationLinkAdmin(HistoryAdmin, SyncableAdmin, MapAdmin):
    """Simulated sensor stations (T078). The admin defines them; "Register in FROST" creates
    their SensorThings entities and is the only thing that writes the FROST ids. A station stays
    in the project it was made in (the old project's phones would never hear that it left):
    "Copy to another project" makes a new one elsewhere."""

    form = SensorStationAdminForm
    list_display = [
        "code",
        "name",
        "project",
        "habitat_type",
        "active",
        "is_simulated",
        "registered",
    ]
    list_select_related = ["project", "habitat_type"]
    list_filter = ["project", "active"]
    search_fields = ["code", "name"]
    ordering = ["project__name", "code"]
    autocomplete_fields = ["project", "habitat_type"]
    filter_horizontal = ["transects"]
    fieldsets = [
        (None, {"fields": ["project", "code", "name", "active", "is_simulated", "geometry"]}),
        (
            _("Habitat and transects"),
            {
                "description": _(
                    "The habitat polygons and transects offered are those of the station's "
                    "project. A saved station stays in its project; use “Copy to another "
                    "project” on the station list to make one elsewhere."
                ),
                "fields": ["habitat_type", "habitat_feature", "transects"],
            },
        ),
        (
            _("FROST (SensorThings)"),
            {
                "description": _(
                    "Save the station, then run “Register in FROST” from the station list. Run "
                    "it again after a change here."
                ),
                "fields": ["sensorthings_thing_id", "datastream_ids", "foi_id"],
            },
        ),
        (
            _("Record"),
            {
                "classes": ["collapse"],
                "fields": [
                    "server_version",
                    "created_at",
                    "created_by",
                    "updated_at",
                    "updated_by",
                ],
            },
        ),
    ]
    readonly_fields = ["is_simulated", "sensorthings_thing_id", "datastream_ids", "foi_id"]
    actions = [
        *SyncableAdmin.actions,
        "register_in_frost",
        "check_frost_status",
        "copy_to_project",
    ]

    class Media:
        js = ("environment/station_project.js",)

    def get_queryset(self, request):
        return services.stations_for(request.user).select_related("project", "habitat_type")

    def get_readonly_fields(self, request, obj=None):
        fields = super().get_readonly_fields(request, obj)
        return [*fields, "project"] if obj is not None else fields

    def get_map_center(self, request, obj):
        # A saved station is where the admin wants to look, not the middle of the project area.
        return obj.geometry.x, obj.geometry.y

    # The habitat polygons and transects offered are those of the station's project. On the add
    # page station_project.js fetches the same lists when a project is chosen.

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == "habitat_feature":
            kwargs["queryset"] = self._habitat_polygons(request, self._form_project(request))
        field = super().formfield_for_foreignkey(db_field, request, **kwargs)
        if db_field.name == "project":
            # station_project.js swaps the zero UUID for the chosen project's id.
            field.widget.attrs["data-choices-url"] = reverse(
                "admin:environment_sensorstationlink_project_choices", args=[uuid.UUID(int=0)]
            )
        return field

    def formfield_for_manytomany(self, db_field, request, **kwargs):
        if db_field.name != "transects":
            return super().formfield_for_manytomany(db_field, request, **kwargs)
        kwargs["queryset"] = self._transects(request, self._form_project(request))
        field = super().formfield_for_manytomany(db_field, request, **kwargs)
        field.label_from_instance = lambda t: f"{t} (deleted)" if t.deleted_at else str(t)
        return field

    def get_urls(self):
        choices = path(
            "project-choices/<uuid:pk>/",
            self.admin_site.admin_view(self.project_choices),
            name="environment_sensorstationlink_project_choices",
        )
        return [choices, *super().get_urls()]

    def project_choices(self, request, pk):
        """The habitat polygons and transects of project `pk`, for station_project.js."""
        if not self.has_view_or_change_permission(request):
            raise PermissionDenied
        querysets = {
            "transects": self._transects(request, pk),
            "habitat_features": self._habitat_polygons(request, pk),
        }
        return JsonResponse(
            {
                name: [{"id": str(row.pk), "label": str(row)} for row in rows]
                for name, rows in querysets.items()
            }
        )

    def _form_project(self, request):
        """The id of the project the form is for: a saved station's, otherwise the one posted
        (or given as `?project=`) on the add page. None when no project is chosen."""
        station = self._page_station(request)
        if station is not None:
            return station.values_list("project", flat=True).first()
        source = request.POST if request.method == "POST" else request.GET
        try:
            return uuid.UUID(str(source.get("project")))
        except ValueError:
            return None

    def _page_station(self, request):
        """The station this page edits, as a queryset for subqueries; None on other pages."""
        object_id = request.resolver_match.kwargs.get("object_id")
        return SensorStationLink.objects.filter(pk=object_id) if object_id else None

    def _transects(self, request, project_id):
        """The project's live transects, and those the page's station is already linked to: a
        link to a deleted transect must not vanish just because the station is saved."""
        wanted = Q(deleted_at__isnull=True)
        station = self._page_station(request)
        if station is not None:
            wanted |= Q(pk__in=station.values("transects"))
        return Transect.objects.filter(
            wanted, project=project_id, project__in=projects_for(request.user)
        ).order_by("code")

    def _habitat_polygons(self, request, project_id):
        """The project's live habitat polygons, and the one the page's station already has,
        even if that was deleted since."""
        # A polygon is the only shape with dimension 2.
        wanted = Q(deleted_at__isnull=True, dimension=2)
        station = self._page_station(request)
        if station is not None:
            wanted |= Q(pk__in=station.values("habitat_feature"))
        return (
            HabitatFeature.objects.alias(
                dimension=Func("geometry", function="ST_Dimension", output_field=IntegerField())
            )
            .filter(wanted, project=project_id)
            .select_related("habitat_type")
            .order_by("habitat_type__name_en", "observed_at")
        )

    @admin.display(boolean=True, description=_("Registered"), ordering="sensorthings_thing_id")
    def registered(self, station):
        return bool(station.sensorthings_thing_id)

    @admin.display(description=_("FROST Datastream ids"))
    def datastream_ids(self, station):
        ids = station.sensorthings_datastream_ids
        lines = [
            f"{prop['name']} ({prop['unit']['symbol']}): {ids[key]}"
            for key, prop in frost.OBSERVED_PROPERTIES.items()
            if key in ids
        ]
        return "\n".join(lines) or "-"

    @admin.display(description=_("FROST FeatureOfInterest id"))
    def foi_id(self, station):
        return station.metadata_json.get(frost.FOI_KEY) or "-"

    def save_model(self, request, obj, form, change):
        if change:
            services.keep_stored_frost_ids(obj)
        else:
            obj.created_by = request.user
        obj.updated_by = request.user
        services.fill_habitat_type(obj)
        super().save_model(request, obj, form, change)

    def _live(self, request, queryset):
        """The selected stations that are not soft-deleted; the others are named."""
        stations = list(queryset.select_related("habitat_feature").order_by("code"))
        deleted = [str(s) for s in stations if s.deleted_at is not None]
        if deleted:
            self.message_user(
                request,
                _("Skipped deleted station(s): %(stations)s") % {"stations": ", ".join(deleted)},
                messages.WARNING,
            )
        return [s for s in stations if s.deleted_at is None]

    @admin.action(description=_("Register in FROST"), permissions=["change"])
    def register_in_frost(self, request, queryset):
        stations = self._live(request, queryset)
        for index, selected in enumerate(stations):
            try:
                station, recreated = services.register_station(selected.pk, request.user)
            except frost.FrostUnreachable as error:
                self._stop_unreachable(request, error, stations[index:])
                return
            except frost.FrostError as error:
                self.message_user(request, f"{selected}: {error}", messages.ERROR)
                continue
            if recreated:
                message = _(
                    "%(station)s: the stored Thing was missing from FROST or was not this "
                    "station's, so it was registered again as Thing %(id)s."
                )
            else:
                message = _("%(station)s: FROST is up to date (Thing %(id)s).")
            self.message_user(
                request,
                message % {"station": station, "id": station.sensorthings_thing_id},
                messages.SUCCESS,
            )
            if station.habitat_feature_id and station.habitat_polygon is None:
                self.message_user(
                    request,
                    _(
                        "%(station)s: the linked habitat feature is deleted or no longer a "
                        "polygon, so FROST got the station point as the feature of interest."
                    )
                    % {"station": station},
                    messages.WARNING,
                )

    @admin.action(description=_("Check FROST status"), permissions=["view"])
    def check_frost_status(self, request, queryset):
        stations = self._live(request, queryset)
        for index, station in enumerate(stations):
            try:
                problems = frost.check(station)
            except frost.FrostUnreachable as error:
                self._stop_unreachable(request, error, stations[index:])
                return
            if problems:
                self.message_user(request, f"{station}: {' '.join(problems)}", messages.WARNING)
            else:
                self.message_user(
                    request,
                    _("%(station)s: OK, the Thing, Datastreams and feature of interest exist.")
                    % {"station": station},
                    messages.SUCCESS,
                )

    def _stop_unreachable(self, request, error, stations_left):
        """One message for a FROST that does not answer; the stations left are not tried."""
        self.message_user(
            request,
            _("%(error)s Not done: %(stations)s")
            % {"error": error, "stations": ", ".join(s.code for s in stations_left)},
            messages.ERROR,
        )

    @admin.action(description=_("Copy to another project…"), permissions=["add"])
    def copy_to_project(self, request, queryset):
        if queryset.count() != 1:
            self.message_user(request, _("Select exactly one station."), messages.ERROR)
            return None
        station = queryset.select_related("project", "habitat_type").get()
        if station.deleted_at is not None:
            self.message_user(request, _("Restore the station first."), messages.ERROR)
            return None
        applying = "apply" in request.POST
        form = CopyStationForm(
            request.POST if applying else None, station=station, user=request.user
        )
        # The changelist posts the action; the confirm page posts back with "apply".
        if applying and form.is_valid():
            copy = services.copy_station(
                station, form.cleaned_data["project"], form.cleaned_data["code"], request.user
            )
            self.message_user(
                request,
                _(
                    "Copied to %(project)s. Choose the habitat polygon and transects, save, "
                    "then register it in FROST."
                )
                % {"project": copy.project},
                messages.SUCCESS,
            )
            return redirect("admin:environment_sensorstationlink_change", copy.pk)
        context = {
            **self.admin_site.each_context(request),
            "title": _("Copy station to another project"),
            "opts": self.model._meta,
            "station": station,
            "form": form,
            "action_checkbox_name": admin.helpers.ACTION_CHECKBOX_NAME,
        }
        return TemplateResponse(request, "admin/environment/sensorstationlink/copy.html", context)
