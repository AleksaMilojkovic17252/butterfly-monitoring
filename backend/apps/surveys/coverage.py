"""Route coverage of a visit (T100, D-095): the share of the transect that the GPS track reached.

The same definition as the phone's `mobile/lib/features/visits/domain/route_coverage.dart`
(T040): samples along the transect at 0, 10, 20 ... m plus the end point, in the transect's UTM
zone (D-046). A sample is covered when a usable route point is within the protocol's
`max_distance_from_transect_m`. A usable point is a live one with an accuracy no worse than twice
`gps_accuracy_warning_m` (the rule of `walked_distance_m`, D-060). Fewer than two usable points
give no value.

This is a leaf module: it imports models and `apps.core.geo` only, never a `services` module,
because `surveys.services` calls it.
"""

import json
from decimal import Decimal

from django.db import connection

from apps.core.geo import utm_srid
from apps.surveys.models import VisitStatus

# The walk is over and the server has the visit. `reviewed` is included although
# `surveys.services.FINISHED_STATUSES` leaves it out: late batches already refresh its `gps_gap`,
# and a recompute must fill existing reviewed rows. `locked` keeps its value.
COVERAGE_STATUSES = [VisitStatus.COMPLETED, VisitStatus.SYNCED, VisitStatus.REVIEWED]

# Shared by the percentage and the uncovered part. `NULLIF` keeps a zero-length transect from
# dividing by zero: `LEAST` then ignores the NULL, giving one sample at fraction 1.0 (the phone's
# one sample). `r.n` is the number of usable points.
_CTE = """
WITH t AS (SELECT ST_Transform(geometry, %(utm)s::int) AS g FROM transect WHERE id = %(transect)s),
r AS (SELECT count(*) AS n, ST_Transform(ST_Collect(geometry), %(utm)s::int) AS g
      FROM survey_track_point
      WHERE survey_visit_id = %(visit)s AND deleted_at IS NULL
        AND (accuracy_m IS NULL OR accuracy_m <= %(max_acc)s)),
s AS (SELECT ST_LineInterpolatePoint(t.g, LEAST(1.0, k * 10.0 / NULLIF(ST_Length(t.g), 0))) AS p
      FROM t, generate_series(0, ceil(ST_Length(t.g) / 10)::int) AS k)
"""


def _params(visit):
    protocol = visit.project.protocol
    return {
        "utm": utm_srid(visit.transect.geometry),
        "transect": visit.transect_id,
        "visit": visit.pk,
        "max_acc": protocol.gps_accuracy_warning_m * 2,
        "max_m": float(protocol.max_distance_from_transect_m),
    }


def route_coverage_pct(visit):
    """Percent of the transect covered, as a Decimal with one decimal, or None with fewer than
    two usable points."""
    with connection.cursor() as db:
        db.execute(
            _CTE
            + """
            SELECT r.n,
                   round(100.0 * count(*) FILTER (WHERE ST_DWithin(s.p, r.g, %(max_m)s::float8))
                         / count(*), 1)
            FROM s, r GROUP BY r.n
            """,
            _params(visit),
        )
        row = db.fetchone()
    if row is None or row[0] < 2 or row[1] is None:
        return None
    return Decimal(row[1]).quantize(Decimal("0.1"))


def refresh_route_coverage(visit):
    """Set `route_coverage_pct` on the (unsaved) visit and return whether it changed.

    A locked visit keeps its value. `completed`, `synced` and `reviewed` compute it; any other
    status has none.
    """
    if visit.status == VisitStatus.LOCKED:
        return False
    if visit.status in COVERAGE_STATUSES:
        new_value = route_coverage_pct(visit)
    else:
        new_value = None
    changed = new_value != visit.route_coverage_pct
    visit.route_coverage_pct = new_value
    return changed


def uncovered_geojson(visit):
    """The parts of the transect farther than the limit from every usable route point, as a
    GeoJSON dict in WGS 84 (a LineString or a MultiLineString), or None with fewer than two usable
    points or when nothing is left uncovered."""
    with connection.cursor() as db:
        db.execute(
            _CTE
            + """
            SELECT r.n,
                   CASE WHEN ST_IsEmpty(x.d) THEN NULL
                        ELSE ST_AsGeoJSON(ST_Transform(x.d, 4326)) END
            FROM t, r,
                 LATERAL (SELECT ST_Difference(t.g, ST_Buffer(r.g, %(max_m)s::float8)) AS d) x
            """,
            _params(visit),
        )
        row = db.fetchone()
    if row is None or row[0] < 2 or row[1] is None:
        return None
    return json.loads(row[1])
