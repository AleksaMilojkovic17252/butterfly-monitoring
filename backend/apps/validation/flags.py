"""Automatic quality flags (T056, D-093): which records need an admin's attention.

A flag never rejects data. `observation_flags` and `visit_flags` are pure reads of the database and
the protocol; `save_observation` and `save_visit` store their result on the instance just before
the save, and `validation.services.recompute_*` applies them to rows already stored.

This is a leaf module: it imports models only, never a `services` module, because
`surveys.services` and `observations.services` import it.
"""

from datetime import UTC, datetime

from django.db import connection
from django.utils.translation import gettext_lazy as _

from apps.observations.models import ObservationSource
from apps.surveys.models import VisitStatus

OUTSIDE_PROJECT_AREA = "outside_project_area"
FAR_FROM_TRANSECT = "far_from_transect"
HIGH_COUNT = "high_count"
GPS_GAP = "gps_gap"
LOW_COVERAGE = "low_coverage"

# code -> label, in the order they are stored; the observation filter reads this
OBSERVATION_FLAGS = {
    OUTSIDE_PROJECT_AREA: _("Outside project area"),
    FAR_FROM_TRANSECT: _("Far from transect"),
    HIGH_COUNT: _("High count"),
}

# The walk is over, so the pauses are final: a visit in progress may have a running pause the server
# has not been told about yet.
GAP_STATUSES = [
    VisitStatus.COMPLETED,
    VisitStatus.SYNCED,
    VisitStatus.REVIEWED,
    VisitStatus.CANCELLED,
]


def observation_flags(observation):
    """The flags of an observation (unsaved or stored), in the order of `OBSERVATION_FLAGS`."""
    project = observation.project
    protocol = project.protocol
    flags = []
    # `covers`, not `within`: a point exactly on the boundary is inside.
    if project.area is not None and not project.area.covers(observation.geometry):
        flags.append(OUTSIDE_PROJECT_AREA)
    if _is_far_from_transect(observation, protocol):
        flags.append(FAR_FROM_TRANSECT)
    if observation.count > protocol.high_count_threshold:
        flags.append(HIGH_COUNT)
    return flags


def _is_far_from_transect(observation, protocol):
    """A transect observation farther than the protocol's limit from its transect line. The same
    `::geography` metric as `nearest_section_id`; strictly greater, so a point exactly at the limit
    agrees with that function's `ST_DWithin`."""
    if observation.source != ObservationSource.TRANSECT or observation.survey_visit_id is None:
        return False
    with connection.cursor() as db:
        db.execute(
            "SELECT ST_Distance(geometry::geography, ST_GeomFromEWKT(%s)::geography) > %s"
            " FROM transect WHERE id = %s",
            [
                observation.geometry.ewkt,
                float(protocol.max_distance_from_transect_m),
                observation.survey_visit.transect_id,
            ],
        )
        row = db.fetchone()
    return bool(row and row[0])


def visit_flags(visit):
    """The flags of a visit. A locked visit keeps what it has; `gps_gap` is set once the walk is
    over. `low_coverage` (T100) reads the stored `route_coverage_pct`, so call
    `surveys.coverage.refresh_route_coverage` first. It is set when the rounded value is strictly
    below the protocol's `min_coverage_pct`; no value, no flag."""
    if visit.status == VisitStatus.LOCKED:
        return list(visit.quality_flags)
    if visit.status not in GAP_STATUSES:
        return []
    result = []
    if has_gps_gap(visit):
        result.append(GPS_GAP)
    coverage_pct = visit.route_coverage_pct
    if coverage_pct is not None and coverage_pct < visit.project.protocol.min_coverage_pct:
        result.append(LOW_COVERAGE)
    return result


def has_gps_gap(visit):
    """True when two consecutive track points are more than `gps_gap_s` apart outside the pauses.

    Works like `mobile/lib/features/visits/domain/gps_gaps.dart`: all live points count (no
    accuracy filter), the pauses are subtracted from each pair's time, and the rest is compared in
    whole seconds. A pause only shortens a gap, so SQL finds the pairs that are long enough before
    any pause is taken off and Python subtracts the pauses from those. The stretch after the last
    point stays a phone warning.
    """
    gps_gap_s = visit.project.protocol.gps_gap_s
    with connection.cursor() as db:
        db.execute(
            """
            SELECT prev_at, recorded_at FROM (
                SELECT recorded_at,
                       lag(recorded_at) OVER (ORDER BY recorded_at, sequence_number) AS prev_at
                FROM survey_track_point
                WHERE survey_visit_id = %s AND deleted_at IS NULL
            ) p
            WHERE recorded_at - prev_at > make_interval(secs => %s)
            """,
            [visit.pk, gps_gap_s],
        )
        pairs = db.fetchall()
    if not pairs:
        return False
    pauses = _pauses(visit)
    for start, end in pairs:
        outside = end - start
        for pause_start, pause_end in pauses:
            overlap_start = max(pause_start, start)
            overlap_end = min(pause_end, end)
            if overlap_end > overlap_start:
                outside -= overlap_end - overlap_start
        # Whole seconds, truncated, as the phone's `inSeconds`: 60.9 s is not a gap on either side.
        if int(outside.total_seconds()) > gps_gap_s:
            return True
    return False


def _pauses(visit):
    """The visit's pauses as `(start, end)` datetimes. They are stored as UTC ISO strings with a
    `Z`. An entry that cannot be read is left out."""
    pauses = []
    for pause in visit.pauses or []:
        try:
            pauses.append((_parse_utc(pause["started_at"]), _parse_utc(pause["ended_at"])))
        except (KeyError, TypeError, ValueError):
            continue
    return pauses


def _parse_utc(value):
    moment = datetime.fromisoformat(value)
    return moment if moment.tzinfo else moment.replace(tzinfo=UTC)
