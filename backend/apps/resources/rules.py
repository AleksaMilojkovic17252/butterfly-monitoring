"""Input rules for a plant record (T051) and a habitat feature (T053): V02, V07 and V08 reject.
There is no V03 or V04: neither has a visit-status or time-window rule, the visit lock is the
only visit rule.

The rules are in docs/requirements/validation-rules.md. Pure functions, no database access:
`resources.services` calls them from `save_plant_resource` and `save_habitat_feature`, so REST,
push and admin are covered.
"""

from apps.observations.rules import MAX_LATITUDE, MAX_LONGITUDE, MIN_LATITUDE, MIN_LONGITUDE
from apps.resources.models import (
    AbundanceClass,
    Disturbance,
    Intensity,
    MowingStatus,
    PhenologyStage,
    ResourceType,
)

PLANT_GEOMETRY_TYPES = ("Point", "Polygon")
HABITAT_GEOMETRY_TYPES = ("Point", "LineString", "Polygon")


def validate_plant_resource(data):
    """The hard errors of a plant record as `{field: [rule ID]}`; an empty dict means valid.

    `data` holds the record's final values by field name; the geometry is a GEOS geometry.
    """
    errors = {}
    _v02_required(data, errors)
    _v07_choices(data, errors)
    _v08_geometry(data, errors, PLANT_GEOMETRY_TYPES)
    return errors


def validate_habitat_feature(data):
    """The hard errors of a habitat feature as `{field: [rule ID]}`; an empty dict means valid.

    `data` holds the record's final values by field name; the geometry is a GEOS geometry.
    """
    errors = {}
    _v02_required(data, errors)
    _v07_optional_choices(
        data,
        errors,
        {
            "flower_abundance_class": Intensity.values,
            "grazing_intensity": Intensity.values,
            "mowing_status": MowingStatus.values,
            "disturbance_type": Disturbance.values,
        },
    )
    _v08_geometry(data, errors, HABITAT_GEOMETRY_TYPES)
    return errors


def _add(errors, field, rule_id):
    errors.setdefault(field, []).append(rule_id)


def _v02_required(data, errors):
    # V02
    for field in ("observed_at", "geometry"):
        if data.get(field) is None:
            _add(errors, field, "V02")


def _v07_choices(data, errors):
    # V07. `resource_type` is required, the other choices may also be blank (not recorded).
    if data.get("resource_type") not in ResourceType.values:
        _add(errors, "resource_type", "V07")
    _v07_optional_choices(
        data,
        errors,
        {
            "abundance_class": AbundanceClass.values,
            "phenology_stage": PhenologyStage.values,
            "flowering_intensity": Intensity.values,
        },
    )


def _v07_optional_choices(data, errors, allowed_by_field):
    # V07 for choices that also allow "" (not recorded).
    for field, allowed in allowed_by_field.items():
        if data.get(field) not in [*allowed, ""]:
            _add(errors, field, "V07")


def _v08_geometry(data, errors, allowed_types):
    # V08. A missing geometry is V02's.
    geometry = data.get("geometry")
    if geometry is not None and not is_valid_geometry(geometry, allowed_types):
        _add(errors, "geometry", "V08")


def is_valid_geometry(geometry, allowed_types):
    """V08's test: a non-empty, valid, two-dimensional geometry of an allowed type, all of it
    inside the longitude and latitude limits."""
    if (
        geometry is None
        or geometry.geom_type not in allowed_types
        or geometry.empty
        or not geometry.valid
        or geometry.hasz
    ):
        return False
    min_x, min_y, max_x, max_y = geometry.extent
    return (
        MIN_LONGITUDE <= min_x
        and max_x <= MAX_LONGITUDE
        and MIN_LATITUDE <= min_y
        and max_y <= MAX_LATITUDE
    )
