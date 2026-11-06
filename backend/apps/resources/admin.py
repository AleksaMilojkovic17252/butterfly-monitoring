import json

from django import forms
from django.contrib import admin, messages
from django.contrib.gis.gdal import GDALException
from django.contrib.gis.geos import GEOSException, GEOSGeometry
from django.db import transaction
from django.utils import timezone
from django.utils.translation import gettext_lazy as _
from rest_framework.exceptions import APIException, ValidationError

from apps.core.admin import (
    _RULE_ID,
    HistoryAdmin,
    MapAdmin,
    ReadOnlyMapMixin,
    SyncableAdmin,
    add_validation_errors,
)
from apps.exports.admin_actions import ExportActionsMixin
from apps.observations.admin import PhotoAddInline, PhotoInline, PhotoInlinesMixin
from apps.resources import services
from apps.resources.models import HabitatFeature, PlantResourceObservation
from apps.surveys.state import VisitLocked


class ReadOnlyGeometryAdmin(
    ExportActionsMixin, ReadOnlyMapMixin, HistoryAdmin, SyncableAdmin, MapAdmin
):
    """Base for a record that is made on the phone and pushed through the API, so the admin only
    shows it (T051, T053): no add, no change, only the export actions (T065). A read-only map
    shows its geometry (the form's own map widget is for editing, and a page without change
    permission shows plain text instead)."""

    actions = ExportActionsMixin.export_actions

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
        actions = super().get_actions(request)
        return {name: a for name, a in actions.items() if name in self.export_actions}


# Any GeoJSON geometry type is read; V08 then refuses what a plant record cannot be (a line).
GEOJSON_GEOMETRY_TYPES = (
    "Point",
    "LineString",
    "Polygon",
    "MultiPoint",
    "MultiLineString",
    "MultiPolygon",
)


def explain_plant_rule(field, rule_id):
    """The form field to mark and the sentence for a plant record rule that refused a save."""
    if field == "geometry_geojson":  # the box that stands in for the map
        return field, explain_plant_rule("geometry", rule_id)[1]
    label = str(PlantResourceObservation._meta.get_field(field).verbose_name).capitalize()
    texts = {
        "V02": _("{label} is required.").format(label=label),
        "V08": _(
            "The shape must be a valid point or polygon (not a line), not self-intersecting, "
            "with longitude -180..180 and latitude -90..90."
        ),
    }
    default = _("'{label}' is not one of the allowed choices.").format(label=label)
    return field, texts.get(rule_id, default)


def _refusal_text(error):
    """What an action says when it refused a record: a rule ID becomes its sentence."""
    if not isinstance(error.detail, dict):
        return str(error.detail)
    sentences = []
    for field, messages_ in error.detail.items():
        if isinstance(messages_, str):  # DRF keeps a lone string as it is
            messages_ = [messages_]
        for message in messages_:
            if _RULE_ID.match(str(message)):
                message = explain_plant_rule(field, str(message))[1]
            sentences.append(str(message))
    return " ".join(sentences)


class PlantResourceAdminForm(forms.ModelForm):
    """Runs the service's checks (`services.check_admin_plant_resource`) so a locked visit or a
    broken rule shows as a form error. The checks run in `_post_clean`: `clean()` comes before
    the form's values are put on the instance."""

    geometry_geojson = forms.CharField(
        label=_("Exact coordinates (GeoJSON)"),
        required=False,
        widget=forms.Textarea(attrs={"rows": 4}),
        help_text=_(
            "Longitude, latitude in WGS 84, e.g. "
            '{"type":"Point","coordinates":[20.45,44.81]}. When filled, it replaces the shape '
            "on the map."
        ),
    )
    admin_user = None  # set by PlantResourceObservationAdmin.get_form

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.adding = self.instance._state.adding
        # The GeoJSON box may supply the shape instead of the map; a missing shape is V02 below.
        if "geometry" in self.fields:
            self.fields["geometry"].required = False
        self._stored_geometry = None if self.adding else self.instance.geometry
        self._geojson_geometry = None
        self.effective_changed = set()

    def clean_geometry_geojson(self):
        text = self.cleaned_data["geometry_geojson"].strip()
        if not text:
            return ""
        message = _("Not valid GeoJSON: give a Point or Polygon object with longitude, latitude.")
        try:
            data = json.loads(text)
        except ValueError as error:
            raise forms.ValidationError(message) from error
        # Only a bare geometry object: no WKT or hex, no Feature, no other CRS.
        if not isinstance(data, dict) or data.get("type") not in GEOJSON_GEOMETRY_TYPES:
            raise forms.ValidationError(message)
        if "crs" in data:
            raise forms.ValidationError(_("Coordinates must be WGS 84; remove the 'crs' member."))
        try:
            self._geojson_geometry = GEOSGeometry(text, srid=4326)
        except (ValueError, GDALException, GEOSException) as error:
            raise forms.ValidationError(message) from error
        return text

    def _post_clean(self):
        super()._post_clean()
        if self._geojson_geometry is not None:
            self.instance.geometry = self._geojson_geometry
        elif not self.adding and "geometry" not in self.changed_data:
            # The widget's round trip through Web Mercator moves coordinates slightly and
            # has_changed hides it: keep the stored value exactly.
            self.instance.geometry = self._stored_geometry
        self.effective_changed = set(self.changed_data) - {"geometry_geojson"}
        if self._geojson_geometry is not None:
            self.effective_changed.add("geometry")
        if self.errors:
            return  # the instance may be incomplete; the field errors are shown first
        try:
            services.check_admin_plant_resource(
                self.admin_user,
                self.instance,
                self.effective_changed,
                adding=self.adding,
                old_geometry=self._stored_geometry,
            )
        except VisitLocked as error:
            self.add_error(None, str(error.detail))
        except ValidationError as error:
            if self._geojson_geometry is not None and isinstance(error.detail, dict):
                error.detail["geometry_geojson"] = error.detail.pop("geometry", [])
            add_validation_errors(self, error, explain_plant_rule)
        except APIException as error:
            self.add_error(None, str(error.detail))


@admin.register(PlantResourceObservation)
class PlantResourceObservationAdmin(
    PhotoInlinesMixin, ExportActionsMixin, ReadOnlyMapMixin, HistoryAdmin, SyncableAdmin, MapAdmin
):
    """Plant records (T051), with their photos: the thumbnail opens the original, and photos can
    be added, made primary and soft-deleted (T113, D-108; this supersedes D-106's read-only
    photos). An admin may
    add one and correct one of an unlocked visit (`services.admin_save_plant_resource`, T111,
    D-106). A record of a locked visit, or a soft-deleted one, opens read-only (T042)."""

    form = PlantResourceAdminForm
    export_dataset = "plant_resources"
    raw_id_fields = ["survey_visit", "plant_taxon"]
    actions = [*SyncableAdmin.actions, *ExportActionsMixin.export_actions]

    inlines = [PhotoInline, PhotoAddInline]
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

    add_fields = [
        "project",
        "created_by",
        "survey_visit",
        "observed_at",
        "resource_type",
        "plant_taxon",
        "notes",
        "geometry",
        "geometry_geojson",
        "abundance_class",
        "phenology_stage",
        "flowering_intensity",
        "eggs_present",
        "larvae_present",
        "feeding_damage_present",
    ]
    fixed_fields = [
        "id",
        "project",
        "survey_visit",
        "created_by",
        "patch_area_m2",
        "deleted_at",
        "stored_shape",
    ]

    @property
    def media(self):
        return super().media + forms.Media(css={"all": ["resources/plant_admin.css"]})

    def _model_fields(self):
        return [field.name for field in PlantResourceObservation._meta.fields]

    def _is_read_only_page(self, request, obj):
        return obj is not None and not self.has_change_permission(request, obj)

    def get_fields(self, request, obj=None):
        if obj is None:
            return list(self.add_fields)
        fields = self._model_fields()
        at = fields.index("geometry") + 1
        if self._is_read_only_page(request, obj):
            fields.insert(at, "location_map")
        else:
            fields[at:at] = ["stored_shape", "geometry_geojson"]
        return fields

    def get_readonly_fields(self, request, obj=None):
        if obj is None:
            base = super().get_readonly_fields(request, obj)
            return [name for name in base if name != "created_by"]
        if self._is_read_only_page(request, obj):
            return [*self.get_fields(request, obj)]
        base = super().get_readonly_fields(request, obj)
        return [*base, *[f for f in self.fixed_fields if f not in base]]

    def has_change_permission(self, request, obj=None):
        if obj is not None and (obj.deleted_at is not None or services.is_locked(obj)):
            return False
        return super().has_change_permission(request, obj)

    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        form.admin_user = request.user
        return form

    def get_changeform_initial_data(self, request):
        return {**super().get_changeform_initial_data(request), "observed_at": timezone.now()}

    def formfield_for_dbfield(self, db_field, request, **kwargs):
        field = super().formfield_for_dbfield(db_field, request, **kwargs)
        if db_field.name == "geometry" and field is not None:
            field.help_text = _(
                "To change between point and polygon, click Delete all Features, pick the "
                "type and draw. Lines are not allowed."
            )
        return field

    def save_model(self, request, obj, form, change):
        services.admin_save_plant_resource(
            obj,
            request.user,
            self.get_change_reason(request),
            form.effective_changed,
            adding=not change,
            old_geometry=form._stored_geometry,
        )

    @admin.display(description=_("Plant"), ordering="plant_taxon__scientific_name")
    def plant(self, plant_resource):
        return plant_resource.plant_taxon or _("Unidentified plant")

    @admin.display(description=_("Stored shape"))
    def stored_shape(self, plant_resource):
        kind = plant_resource.geometry.geom_type
        if plant_resource.patch_area_m2 is not None:
            return f"{kind}, {plant_resource.patch_area_m2} m²"
        return kind

    def _each_record(self, request, queryset, service, verb, deleted):
        """Run `service` on each selected record on its own, like Reassign sections: a refused
        one is named, not fatal to the rest."""
        done = 0
        refused = []
        ids = list(queryset.filter(deleted_at__isnull=not deleted).values_list("pk", flat=True))
        for plant_id in ids:
            try:
                with transaction.atomic():
                    plant = (
                        PlantResourceObservation.objects.select_for_update()
                        .filter(pk=plant_id, deleted_at__isnull=not deleted)
                        .first()
                    )
                    if plant is None:
                        continue
                    try:
                        service(plant, request.user)
                    except APIException as error:
                        refused.append(f"{plant} ({_refusal_text(error)})")
                        raise
                done += 1
            except APIException:
                continue
        self.message_user(request, _("%(verb)s %(count)d row(s).") % {"verb": verb, "count": done})
        if refused:
            self.message_user(
                request,
                _("Not changed: %(rows)s") % {"rows": "; ".join(refused)},
                messages.ERROR,
            )

    @admin.action(description=_("Soft delete selected"), permissions=["change"])
    def soft_delete_selected(self, request, queryset):
        self._each_record(
            request, queryset, services.admin_soft_delete_plant_resource, _("Soft deleted"), False
        )

    @admin.action(description=_("Restore selected (undo soft delete)"), permissions=["change"])
    def restore_selected(self, request, queryset):
        self._each_record(
            request, queryset, services.admin_restore_plant_resource, _("Restored"), True
        )


@admin.register(HabitatFeature)
class HabitatFeatureAdmin(ReadOnlyGeometryAdmin):
    """Habitat features (T053). They have no photos."""

    export_dataset = "habitat_features"

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
