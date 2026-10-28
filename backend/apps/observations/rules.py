"""Input rules for an observation (T055): V01-V04, V06-V08 reject, W01-W04 warn.

The rules are in docs/requirements/validation-rules.md; the app repeats them in
`mobile/lib/core/validation/observation_rules.dart`. Pure functions, no database access:
`observations.services` builds the context and calls them from `save_observation`.
"""

from dataclasses import dataclass
from datetime import datetime, timedelta
from decimal import Decimal

from apps.observations.models import Behaviour, Confidence, LifeStage, ObservationSource, Sex
from apps.surveys.models import VisitStatus

# Visit statuses a transect observation may be recorded on (V03). A locked visit refuses every
# change earlier (`visit_locked`); `synced` and `reviewed` are "completed" seen from the server.
OBSERVATION_VISIT_STATUSES = ["in_progress", "completed", "synced", "reviewed"]

MIN_LONGITUDE, MAX_LONGITUDE = -180, 180
MIN_LATITUDE, MAX_LATITUDE = -90, 90


@dataclass(frozen=True)
class ObservationRuleContext:
    """What the rules need to know besides the observation's own values."""

    visit_status: str | None  # None: the observation has no visit
    visit_started_at: datetime | None
    visit_ended_at: datetime | None
    visit_zero_confirmed: bool
    tolerance_min: int  # protocol.observation_time_tolerance_min
    accuracy_warning_m: Decimal | float  # protocol.gps_accuracy_warning_m
    taxon_photo_required: bool
    photo_count: int


def validate_observation(data, context):
    """The hard errors of an observation as `{field: [rule ID]}`; an empty dict means valid.

    `data` holds the observation's final values by field name; the geometry is a GEOS Point.
    """
    errors = {}
    _v01_count(data, errors)
    _v02_required(data, errors)
    _v03_visit_status(data, context, errors)
    _v04_observed_at(data, context, errors)
    _v06_observation(data, context, errors)
    _v07_choices(data, errors)
    _v08_geometry(data, errors)
    return errors


def observation_warnings(data, context):
    """The warnings that apply to an observation, as rule IDs (W01-W04). They never reject."""
    warnings = []
    if photo_missing(context.taxon_photo_required, context.photo_count):
        warnings.append("W01")
    if _w02_poor_accuracy(data, context):
        warnings.append("W02")
    if _w03_oviposition(data):
        warnings.append("W03")
    if _w04_larva(data):
        warnings.append("W04")
    return warnings


def photo_missing(photo_required, photo_count):
    """W01: the taxon needs a photo and the observation has none, so it waits for validation."""
    return photo_required and photo_count == 0


def _add(errors, field, rule_id):
    errors.setdefault(field, []).append(rule_id)


def _v01_count(data, errors):
    # V01
    count = data.get("count")
    if count is None or count < 1:
        _add(errors, "count", "V01")


def _v02_required(data, errors):
    # V02
    for field in ("observed_at", "geometry"):
        if data.get(field) is None:
            _add(errors, field, "V02")


def _v03_visit_status(data, context, errors):
    # V03
    if data.get("source") != ObservationSource.TRANSECT:
        return
    if context.visit_status in OBSERVATION_VISIT_STATUSES:
        return
    # T041: an aborted visit keeps its butterflies. A cancelled visit that was started accepts
    # them; this also covers a visit cancelled offline, whose create reaches the server first.
    if context.visit_status == VisitStatus.CANCELLED and context.visit_started_at is not None:
        return
    _add(errors, "survey_visit", "V03")


def _v04_observed_at(data, context, errors):
    # V04
    observed_at = data.get("observed_at")
    if observed_at is None or context.visit_status is None:
        return
    tolerance = timedelta(minutes=context.tolerance_min)
    started_at, ended_at = context.visit_started_at, context.visit_ended_at
    if started_at is not None and observed_at < started_at - tolerance:
        _add(errors, "observed_at", "V04")
    elif ended_at is not None and observed_at > ended_at + tolerance:
        _add(errors, "observed_at", "V04")


def _v06_observation(data, context, errors):
    # V06, server direction: no new transect observation on a visit confirmed as a true zero.
    if data.get("source") == ObservationSource.TRANSECT and context.visit_zero_confirmed:
        _add(errors, "survey_visit", "V06")


def _v07_choices(data, errors):
    # V07
    single_choices = {
        "sex": Sex.values,
        "life_stage": LifeStage.values,
        "source": ObservationSource.values,
        "identification_confidence": Confidence.values,
    }
    for field, allowed in single_choices.items():
        if data.get(field) not in allowed:
            _add(errors, field, "V07")
    if any(item not in Behaviour.values for item in data.get("behaviour") or []):
        _add(errors, "behaviour", "V07")


def _v08_geometry(data, errors):
    # V08. A missing geometry is V02's.
    geometry = data.get("geometry")
    if geometry is None:
        return
    valid = (
        geometry.geom_type == "Point"
        and not geometry.empty
        and geometry.valid
        and MIN_LONGITUDE <= geometry.x <= MAX_LONGITUDE
        and MIN_LATITUDE <= geometry.y <= MAX_LATITUDE
    )
    if not valid:
        _add(errors, "geometry", "V08")


def _w02_poor_accuracy(data, context):
    # W02
    accuracy = data.get("location_accuracy_m")
    return accuracy is not None and accuracy > context.accuracy_warning_m


def _w03_oviposition(data):
    # W03. TODO(T051): fire only when the observation has no host-plant link; there is no link yet.
    return Behaviour.OVIPOSITION in (data.get("behaviour") or [])


def _w04_larva(data):
    # W04. TODO(T051): fire only when the observation has no host-plant link; there is no link yet.
    return data.get("life_stage") == LifeStage.LARVA
