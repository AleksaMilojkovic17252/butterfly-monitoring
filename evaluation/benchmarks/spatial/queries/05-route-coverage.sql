-- title: Route coverage (T100, surveys.coverage.route_coverage_pct)
-- tables: survey_track_point
-- source: backend/apps/surveys/coverage.py:30
-- The code's CTE per finished visit, here per visit through LATERAL. The geometries are computed
-- (transformed to UTM, interpolated), so no index on a stored column applies. The UTM zone is
-- worked out in SQL the way core.geo.utm_srid does it.
SELECT count(*) AS visits, round(avg(c.pct), 1) AS mean_pct
FROM survey_visit v
JOIN project_protocol pp ON pp.project_id = v.project_id
CROSS JOIN LATERAL (
    WITH t AS (
        SELECT ST_Transform(tr.geometry, u.srid) AS g
        FROM transect tr,
             LATERAL (SELECT (CASE WHEN ST_Y(ST_Centroid(tr.geometry)) >= 0 THEN 32600 ELSE 32700 END
                              + floor((ST_X(ST_Centroid(tr.geometry)) + 180) / 6)::int % 60 + 1) AS srid) u
        WHERE tr.id = v.transect_id
    ),
    r AS (
        SELECT count(*) AS n, ST_Transform(ST_Collect(tp.geometry), (SELECT ST_SRID(g) FROM t)) AS g
        FROM survey_track_point tp
        WHERE tp.survey_visit_id = v.id AND tp.deleted_at IS NULL
          AND (tp.accuracy_m IS NULL OR tp.accuracy_m <= pp.gps_accuracy_warning_m * 2)
    ),
    s AS (
        SELECT ST_LineInterpolatePoint(t.g, LEAST(1.0, k * 10.0 / NULLIF(ST_Length(t.g), 0))) AS p
        FROM t, generate_series(0, ceil(ST_Length(t.g) / 10)::int) AS k
    )
    SELECT round(100.0 * count(*) FILTER (WHERE ST_DWithin(s.p, r.g, pp.max_distance_from_transect_m::float8))
                 / count(*), 1) AS pct
    FROM s, r
    GROUP BY r.n
    HAVING r.n >= 2
) c
WHERE v.project_id = :'project' AND v.deleted_at IS NULL
  AND v.status IN ('completed', 'synced', 'reviewed');
