"""Input rules for a visit (T055): V05, V06 (server direction), V07 and V09 reject, W06 and W07
warn.

The rules are in docs/requirements/validation-rules.md; the app repeats them in
`mobile/lib/core/validation/visit_rules.dart`. Pure functions, no database access:
`surveys.services` builds the context and calls them from `save_visit`. The observation rules are
in `observations/rules.py`.
"""

from dataclasses import dataclass
from zoneinfo import ZoneInfo

from apps.projects.models import SurveyMethod
from apps.surveys.models import CancelReason, Precipitation, VisitStatus

# Statuses in which the visit's weather must be complete (V05).
WEATHER_REQUIRED_STATUSES = [
    VisitStatus.COMPLETED,
    VisitStatus.SYNCED,
    VisitStatus.REVIEWED,
    VisitStatus.LOCKED,
]

_WEATHER_FIELDS = [
    "temperature_start_c",
    "temperature_end_c",
    "wind_beaufort_start",
    "wind_beaufort_end",
    "cloud_cover_start_pct",
    "cloud_cover_end_pct",
]


@dataclass(frozen=True)
class VisitRuleContext:
    """What the rules need to know besides the visit's own values."""

    protocol: object  # the project's ProjectProtocol; an unsaved one is fine
    # Live `source = transect` observations of the visit. Only read for a visit confirmed as a
    # true zero (V06), so the service counts them only then.
    transect_observation_count: int


def validate_visit(data, context):
    """The hard errors of a visit as `{field: [rule ID]}`; an empty dict means valid.

    `data` holds the visit's final values by field name.
    """
    errors = {}
    _v05_weather(data, errors)
    _v06_visit(data, context, errors)
    _v07_choices(data, errors)
    _v09_cancel_reason(data, errors)
    return errors


def visit_warnings(data, context):
    """The warnings that apply to a visit, as rule IDs (W06, W07). They never reject."""
    warnings = []
    if _w06_weather(data, context.protocol):
        warnings.append("W06")
    if _w07_outside_window(data, context.protocol):
        warnings.append("W07")
    return warnings


def weather_suitable(protocol, temperature_c, wind_beaufort, cloud_cover_pct, precipitation):
    """Whether one set of weather values meets the protocol (protocol.md §3)."""
    if precipitation != Precipitation.NONE and not protocol.allow_precipitation:
        return False
    if wind_beaufort > protocol.max_wind_beaufort:
        return False
    if temperature_c >= protocol.sunny_temperature_c:
        return True
    return (
        temperature_c >= protocol.min_temperature_c
        and cloud_cover_pct <= protocol.max_cloud_cover_pct_if_cool
    )


def _add(errors, field, rule_id):
    errors.setdefault(field, []).append(rule_id)


def _v05_weather(data, errors):
    # V05
    if data.get("status") not in WEATHER_REQUIRED_STATUSES:
        return
    if (data.get("weather_missing_reason") or "").strip():
        return
    for field in _WEATHER_FIELDS:
        if data.get(field) is None:
            _add(errors, field, "V05")


def _v06_visit(data, context, errors):
    # V06, server direction: a visit confirmed as a true zero has no transect observations. The
    # other direction (completed with none needs the tick) is checked in the app only.
    if data.get("zero_observation_confirmed") and context.transect_observation_count > 0:
        _add(errors, "zero_observation_confirmed", "V06")


def _v07_choices(data, errors):
    # V07
    choices = {
        "status": VisitStatus.values,
        "survey_method": SurveyMethod.values,
        "precipitation": Precipitation.values,
        "cancel_reason": ["", *CancelReason.values],
    }
    for field, allowed in choices.items():
        if data.get(field) not in allowed:
            _add(errors, field, "V07")


def _v09_cancel_reason(data, errors):
    # V09 (T041): "not conducted" is for a visit that was never started, the other reasons for one
    # that was. It reads `started_at`, not the previous status: a visit created offline and
    # cancelled arrives as one create, draft straight to cancelled.
    if data.get("status") != VisitStatus.CANCELLED:
        return
    reason = data.get("cancel_reason")
    if reason not in CancelReason.values:
        return  # a missing or unknown reason is V07's
    never_started = data.get("started_at") is None
    if (reason == CancelReason.NOT_CONDUCTED) != never_started:
        _add(errors, "cancel_reason", "V09")


def _w06_weather(data, protocol):
    # W06: the start weather, and the end weather when it is recorded.
    precipitation = data.get("precipitation")
    for suffix in ("start", "end"):
        values = [
            data.get(f"temperature_{suffix}_c"),
            data.get(f"wind_beaufort_{suffix}"),
            data.get(f"cloud_cover_{suffix}_pct"),
        ]
        if None in values:
            continue
        if not weather_suitable(protocol, *values, precipitation):
            return True
    return False


def _w07_outside_window(data, protocol):
    # W07: outside the season (local date) or the daily window (local wall-clock minute), local
    # meaning the time zone of the project's protocol. The server itself runs in UTC.
    started_at = data.get("started_at")
    if started_at is None:
        return False
    local = started_at.astimezone(ZoneInfo(protocol.time_zone))
    if not protocol.season_start <= local.date() <= protocol.season_end:
        return True
    local_time = local.time().replace(second=0, microsecond=0)
    return not protocol.day_start_time <= local_time <= protocol.day_end_time
