"""Plant record (T051) and habitat feature (T053) rules and scopes. Push, the REST endpoints and
the admin call these, not the models.

A change is built on the instance first (`build_new_plant_resource`,
`apply_plant_resource_changes`, and the habitat pair) and then saved by `save_plant_resource` or
`save_habitat_feature`, as for observations. A record of a locked visit refuses every change
(`state.ensure_unlocked`, T042). The save functions check the input rules of `resources.rules`
(`save_plant_resource` also fills in `patch_area_m2`), so REST and push both get them.

`observations.services` imports this module (a link to a plant record is checked against
`plant_resources_for`); this module never imports it back.
"""

from decimal import ROUND_HALF_UP, Decimal

from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import connection
from rest_framework import exceptions, serializers

from apps.accounts.services import is_admin
from apps.core.history import save_with_reason
from apps.projects.services import ensure_project_open, is_member, projects_for
from apps.resources import rules
from apps.resources.models import HabitatFeature, PlantResourceObservation
from apps.resources.serializers import (
    HabitatFeatureSyncSerializer,
    PlantResourceSyncSerializer,
)
from apps.surveys.models import SurveyVisit
from apps.surveys.services import visits_for
from apps.surveys.state import ensure_unlocked
from apps.sync.handlers import current_client_time, current_push_reason, soft_delete_pushed

REST_REASON = "REST API"  # history_change_reason of changes made through the REST endpoints

# What numeric(10,1) holds: 999,999,999.9 m², a square of about 32 km a side.
MAX_PATCH_AREA_M2 = Decimal("999999999.9")
_TENTH = Decimal("0.1")


def plant_resources_for(user):
    """Live plant records the user may see: an admin all of them in live projects, a researcher
    only the ones they created, in projects they are still a member of."""
    plants = PlantResourceObservation.objects.alive().filter(project__in=projects_for(user))
    if is_admin(user):
        return plants
    return plants.filter(created_by=user)


def pull_plant_resources(user, project):
    """The caller's own plant records in the project, deleted rows included (D-049)."""
    return PlantResourceObservation.objects.filter(project=project, created_by=user)


def build_new_plant_resource(user, plant_id, data):
    """An unsaved plant record from a create payload."""
    serializer = PlantResourceSyncSerializer(data=data)
    serializer.is_valid(raise_exception=True)
    plant = PlantResourceObservation(id=plant_id, created_by=user, **serializer.validated_data)
    _check_context(user, plant)
    ensure_project_open(plant.project, current_client_time())  # T099, D-104
    return plant


def apply_plant_resource_changes(user, plant, data):
    """Apply an update payload to `plant` (unsaved). Only the keys in `data` change."""
    changes = _validated_changes(user, plant, PlantResourceSyncSerializer, data, "plant record")
    old_geometry, old_area = plant.geometry, plant.patch_area_m2
    for field_name, value in changes.items():
        setattr(plant, field_name, value)
    if "plant_taxon" in changes:
        _check_plant_taxon(plant)
    # A changed shape makes a stored area wrong, unless this payload sends a new one. A payload
    # that echoes the stored area (a full row, as the phone pulled it) does not send a new one.
    # The save computes it again for a polygon. A moved point keeps an area the client set.
    new_area_sent = "patch_area_m2" in changes and changes["patch_area_m2"] != old_area
    if (
        "geometry" in changes
        and not new_area_sent
        and not old_geometry.equals_exact(plant.geometry)
        and "Polygon" in (old_geometry.geom_type, plant.geometry.geom_type)
    ):
        plant.patch_area_m2 = None
    return plant


def save_plant_resource(plant, user, history_reason):
    """Check the input rules, work out the area of a polygon left without one, check the table's
    constraints, then save with a history reason.

    The rules come first, so a bad polygon never reaches PostGIS: longitude 500 is
    `{"geometry": ["V08"]}`, not an SQL error.
    """
    errors = rules.validate_plant_resource(_rule_data(plant))
    if errors:
        raise exceptions.ValidationError(errors)
    if plant.patch_area_m2 is None and plant.geometry.geom_type == "Polygon":
        plant.patch_area_m2 = _polygon_area_m2(plant.geometry)
    return _store(plant, user, history_reason)


# REST (views.py). No delete: the ticket lists POST and PATCH only; push can delete.


def create_plant_resource(user, plant_id, data):
    return save_plant_resource(build_new_plant_resource(user, plant_id, data), user, REST_REASON)


def update_plant_resource(user, plant, data):
    ensure_project_open(plant.project, None)  # REST has no push time (T099, D-104)
    apply_plant_resource_changes(user, plant, data)
    return save_plant_resource(plant, user, REST_REASON)


# Push (sync registry). The framework has checked ownership and the base version.


def push_create(user, plant_id, data):
    plant = build_new_plant_resource(user, plant_id, data)
    return save_plant_resource(plant, user, current_push_reason())


def push_update(user, plant, data):
    apply_plant_resource_changes(user, plant, data)
    return save_plant_resource(plant, user, current_push_reason())


def push_delete(user, plant):
    _lock_visit(plant)
    soft_delete_pushed(plant, user)


def project_of(record):
    """The project of a plant record or a habitat feature (`PushHandlers.project_of`)."""
    return record.project


def guard_plant_resource(user, plant):
    """Push guard (`PushHandlers.guard`): runs before the merge, so a change to a plant record of
    a locked visit is rejected even when its base version is stale (T042)."""
    _guard_visit(plant)


def _guard_visit(record):
    if record.survey_visit_id is not None:
        ensure_unlocked(record.survey_visit)


# Habitat features (T053). The same scopes and flow as plant records, without an area.


def habitat_features_for(user):
    """Live habitat features the user may see: an admin all of them in live projects, a
    researcher only the ones they created, in projects they are still a member of."""
    features = HabitatFeature.objects.alive().filter(project__in=projects_for(user))
    if is_admin(user):
        return features
    return features.filter(created_by=user)


def pull_habitat_features(user, project):
    """The caller's own habitat features in the project, deleted rows included (D-049)."""
    return HabitatFeature.objects.filter(project=project, created_by=user)


def build_new_habitat_feature(user, feature_id, data):
    """An unsaved habitat feature from a create payload."""
    serializer = HabitatFeatureSyncSerializer(data=data)
    serializer.is_valid(raise_exception=True)
    feature = HabitatFeature(id=feature_id, created_by=user, **serializer.validated_data)
    _check_project(user, feature)
    _check_codelists(feature)
    _check_visit(user, feature)
    ensure_project_open(feature.project, current_client_time())  # T099, D-104
    return feature


def apply_habitat_feature_changes(user, feature, data):
    """Apply an update payload to `feature` (unsaved). Only the keys in `data` change."""
    changes = _validated_changes(
        user, feature, HabitatFeatureSyncSerializer, data, "habitat feature"
    )
    old_habitat_type_id = feature.habitat_type_id
    old_management_type_id = feature.management_type_id
    for field_name, value in changes.items():
        setattr(feature, field_name, value)
    _check_codelists(feature, old_habitat_type_id, old_management_type_id)
    return feature


def save_habitat_feature(feature, user, history_reason):
    """Check the input rules, then the table's constraints, then save with a history reason.

    The rules come first, so a bad geometry never reaches PostGIS: longitude 500 is
    `{"geometry": ["V08"]}`, not an SQL error.
    """
    errors = rules.validate_habitat_feature(_habitat_rule_data(feature))
    if errors:
        raise exceptions.ValidationError(errors)
    return _store(feature, user, history_reason)


def create_habitat_feature(user, feature_id, data):
    return save_habitat_feature(
        build_new_habitat_feature(user, feature_id, data), user, REST_REASON
    )


def update_habitat_feature(user, feature, data):
    ensure_project_open(feature.project, None)
    apply_habitat_feature_changes(user, feature, data)
    return save_habitat_feature(feature, user, REST_REASON)


def push_create_habitat(user, feature_id, data):
    feature = build_new_habitat_feature(user, feature_id, data)
    return save_habitat_feature(feature, user, current_push_reason())


def push_update_habitat(user, feature, data):
    apply_habitat_feature_changes(user, feature, data)
    return save_habitat_feature(feature, user, current_push_reason())


def push_delete_habitat(user, feature):
    _lock_visit(feature)
    soft_delete_pushed(feature, user)


def guard_habitat_feature(user, feature):
    """Push guard: a change to a habitat feature of a locked visit is rejected even when its base
    version is stale (T042)."""
    _guard_visit(feature)


def _polygon_area_m2(geometry):
    """The area of a polygon in square metres on the WGS 84 ellipsoid, to one decimal. A value
    the column cannot hold is a field error, not a database one."""
    with connection.cursor() as cursor:
        cursor.execute("SELECT ST_Area(ST_GeomFromEWKT(%s)::geography)", [geometry.ewkt])
        area = Decimal(repr(cursor.fetchone()[0])).quantize(_TENTH, rounding=ROUND_HALF_UP)
    if area > MAX_PATCH_AREA_M2:
        raise exceptions.ValidationError({"patch_area_m2": ["This polygon is too large."]})
    return area


def _rule_data(plant):
    """The record's values (unsaved, as they will be stored) that the input rules read."""
    return {
        name: getattr(plant, name)
        for name in (
            "observed_at",
            "geometry",
            "resource_type",
            "abundance_class",
            "phenology_stage",
            "flowering_intensity",
        )
    }


def _store(record, user, history_reason):
    """Check the table's constraints, then save with a history reason."""
    try:
        record.validate_constraints()
    except DjangoValidationError as error:
        raise exceptions.ValidationError(serializers.as_serializer_error(error)) from error
    save_with_reason(record, user, history_reason)
    # The trigger wrote a new server_version; the instance still holds the old one (D-029).
    record.refresh_from_db(fields=["server_version"])
    return record


def _validated_changes(user, record, serializer_class, data, label):
    """The checked changes of an update payload. Locks the record's visit first, then checks the
    caller's membership and the payload. `project` and `survey_visit` cannot change: a payload
    that repeats the stored value is dropped, any other value is a field error."""
    _lock_visit(record)
    if not is_admin(user) and not is_member(user, record.project_id):
        raise exceptions.PermissionDenied(f"You are not a member of this {label}'s project.")
    serializer = serializer_class(record, data=data, partial=True)
    serializer.is_valid(raise_exception=True)
    changes = dict(serializer.validated_data)
    for field_name in ("project", "survey_visit"):
        if field_name in changes:
            new_value = changes.pop(field_name)
            if getattr(new_value, "pk", None) != getattr(record, f"{field_name}_id"):
                raise exceptions.ValidationError({field_name: ["Cannot be changed."]})
    return changes


def _habitat_rule_data(feature):
    """The feature's values (unsaved, as they will be stored) that the input rules read."""
    return {
        name: getattr(feature, name)
        for name in (
            "observed_at",
            "geometry",
            "flower_abundance_class",
            "grazing_intensity",
            "mowing_status",
            "disturbance_type",
        )
    }


def _check_codelists(feature, old_habitat_type_id=None, old_management_type_id=None):
    """A habitat or management type that was soft-deleted cannot be newly chosen. A value that
    did not change is not checked, so a full row echoed by the phone is not refused because its
    type was deleted since (as for the links of D-086). An inactive type is allowed everywhere:
    deactivating only hides a value from pickers (T020). Pass the stored ids on an update; on a
    new record there are none, so both values are checked."""
    for name, old_id in (
        ("habitat_type", old_habitat_type_id),
        ("management_type", old_management_type_id),
    ):
        if getattr(feature, f"{name}_id") == old_id:
            continue
        value = getattr(feature, name)
        if value is not None and value.deleted_at is not None:
            label = name.replace("_", " ")
            raise exceptions.ValidationError({name: [f"This {label} was deleted."]})


def _lock_visit(record):
    """Lock the record's visit for the rest of the transaction and refuse a locked one.
    Done first, so a lock that lands while another request works on the visit is not missed."""
    if record.survey_visit_id is None:
        return
    visit = SurveyVisit.objects.select_for_update().get(pk=record.survey_visit_id)
    ensure_unlocked(visit)
    record.survey_visit = visit


def _check_plant_taxon(plant):
    # An inactive plant is still allowed, as for butterflies (D-043): an old list may name it.
    if plant.plant_taxon is not None and plant.plant_taxon.deleted_at is not None:
        raise exceptions.ValidationError({"plant_taxon": ["This plant was deleted."]})


def _check_context(user, plant):
    """The project, plant and visit of `plant` must fit together."""
    _check_project(user, plant)
    _check_plant_taxon(plant)
    _check_visit(user, plant)


def _check_project(user, record):
    """The record's project must be live and the caller a member of it (or an admin)."""
    project = record.project
    if project.deleted_at is not None:
        raise exceptions.ValidationError({"project": ["This project was deleted."]})
    if not is_admin(user) and not is_member(user, project.pk):
        raise exceptions.PermissionDenied("You are not a member of this project.")


def _check_visit(user, record):
    """The record's visit, if it has one, must be one the caller may see, in the record's
    project, and not locked. Locks the visit for the rest of the transaction."""
    if record.survey_visit_id is not None:
        visit = visits_for(user).select_for_update().filter(pk=record.survey_visit_id).first()
        if visit is None:
            raise exceptions.ValidationError({"survey_visit": ["This visit was not found."]})
        if visit.project_id != record.project_id:
            raise exceptions.ValidationError(
                {"survey_visit": ["This visit is not in the project."]}
            )
        ensure_unlocked(visit)
