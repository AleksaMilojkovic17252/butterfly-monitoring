"""Input rules for a plant record (T051): V02, V07 and V08 reject. There is no V03 or V04: a plant
record has no visit-status or time-window rule, the visit lock is its only visit rule.

The rules are in docs/requirements/validation-rules.md. Pure functions, no database access:
`resources.services` calls them from `save_plant_resource`, so REST, push and admin are covered.
"""

from apps.observations.rules import MAX_LATITUDE, MAX_LONGITUDE, MIN_LATITUDE, MIN_LONGITUDE
from apps.resources.models import AbundanceClass, Intensity, PhenologyStage, ResourceType

PLANT_GEOMETRY_TYPES = ("Point", "Polygon")


def validate_plant_resource(data):
    """The hard errors of a plant record as `{field: [rule ID]}`; an empty dict means valid.

    `data` holds the record's final values by field name; the geometry is a GEOS geometry.
    """
    errors = {}
    _v02_required(data, errors)
    _v07_choices(data, errors)
    _v08_geometry(data, errors)
    return errors


def _add(errors, field, rule_id):
    errors.setdefault(field, []).append(rule_id)


def _v02_required(data, errors):
    # V02
    for field in ("observed_at", "geometry"):
        if data.get(field) is None:
            _add(errors, field, "V02")


def _v07_choices(data, errors):
    # V07. The three optional choices also allow "" (not recorded).
    if data.get("resource_type") not in ResourceType.values:
        _add(errors, "resource_type", "V07")
    optional_choices = {
        "abundance_class": AbundanceClass.values,
        "phenology_stage": PhenologyStage.values,
        "flowering_intensity": Intensity.values,
    }
    for field, allowed in optional_choices.items():
        if data.get(field) not in [*allowed, ""]:
            _add(errors, field, "V07")


def _v08_geometry(data, errors):
    # V08. A missing geometry is V02's.
    geometry = data.get("geometry")
    if geometry is not None and not is_valid_plant_geometry(geometry):
        _add(errors, "geometry", "V08")


def is_valid_plant_geometry(geometry):
    """True for a non-empty, valid, two-dimensional point or polygon inside the longitude and
    latitude limits (V08's test)."""
    if (
        geometry is None
        or geometry.geom_type not in PLANT_GEOMETRY_TYPES
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
