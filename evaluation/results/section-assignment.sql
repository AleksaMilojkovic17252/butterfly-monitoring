-- T103: nearest-section (T048, D-084) against the [start_m, end_m) interval of linear referencing.
-- Run with psql (or the django shell, one statement at a time). Read-only apart from the temp view.

-- One row per live transect record with a visit. `lim` is the protocol's
-- max_distance_from_transect_m.
CREATE TEMP VIEW sa AS
SELECT o.id, o.survey_visit_id, v.transect_id, t.code AS transect_code, o.transect_section_id AS stored,
       bo.distance_along_m AS d, bo.offset_m, pp.max_distance_from_transect_m AS lim,
       -- nearest: the same query as transects.services.nearest_section_id
       (SELECT s.id FROM public.transect_section s
        WHERE s.transect_id = v.transect_id AND s.deleted_at IS NULL
          AND ST_DWithin(s.geometry::geography, o.geometry::geography, pp.max_distance_from_transect_m)
        ORDER BY s.geometry::geography <-> o.geometry::geography, s.sequence_number
        LIMIT 1) AS nearest,
       -- interval: the live section with start_m <= d < end_m (the last one also takes d = end_m),
       -- only when the offset check passes
       CASE WHEN bo.offset_m <= pp.max_distance_from_transect_m THEN
         (SELECT gs.id FROM geo.transect_sections gs
          WHERE gs.transect_id = v.transect_id
            AND bo.distance_along_m >= gs.start_m
            AND (bo.distance_along_m < gs.end_m
                 OR (bo.distance_along_m = gs.end_m
                     AND gs.end_m = (SELECT max(g2.end_m) FROM geo.transect_sections g2
                                     WHERE g2.transect_id = gs.transect_id)))
          ORDER BY gs.sequence_number LIMIT 1)
       END AS interval_sec,
       -- distance to the nearest section boundary, metres along the transect
       (SELECT min(least(abs(bo.distance_along_m - gs.start_m), abs(bo.distance_along_m - gs.end_m)))
        FROM geo.transect_sections gs WHERE gs.transect_id = v.transect_id) AS boundary_m
FROM public.butterfly_observation o
JOIN public.survey_visit v ON v.id = o.survey_visit_id
JOIN public.transect t ON t.id = v.transect_id
JOIN public.project_protocol pp ON pp.project_id = o.project_id
JOIN geo.butterfly_observations bo ON bo.id = o.id
WHERE o.deleted_at IS NULL AND o.source = 'transect' AND bo.distance_along_m IS NOT NULL;

-- Q1 totals
SELECT count(*) AS records,
       count(*) FILTER (WHERE nearest IS NOT NULL AND nearest = interval_sec) AS agree,
       count(*) FILTER (WHERE nearest IS NOT NULL AND interval_sec IS NOT NULL
                          AND nearest <> interval_sec) AS disagree,
       count(*) FILTER (WHERE nearest IS NOT NULL AND interval_sec IS NULL) AS nearest_only,
       count(*) FILTER (WHERE nearest IS NULL AND interval_sec IS NOT NULL) AS interval_only,
       count(*) FILTER (WHERE nearest IS NULL AND interval_sec IS NULL) AS neither,
       count(*) FILTER (WHERE offset_m > lim) AS beyond_limit
FROM sa;

-- Q2 stored (may be the phone's guess) against nearest
SELECT count(*) FILTER (WHERE stored IS NOT DISTINCT FROM nearest) AS same,
       count(*) FILTER (WHERE stored IS DISTINCT FROM nearest) AS different,
       count(*) FILTER (WHERE stored IS NULL) AS stored_null,
       count(*) FILTER (WHERE stored IS NULL AND nearest IS NOT NULL) AS stored_null_nearest_set
FROM sa;

-- Q3 disagreements by distance to the nearest section boundary
SELECT count(*) AS disagreements,
       count(*) FILTER (WHERE boundary_m <= 1) AS le_1m,
       count(*) FILTER (WHERE boundary_m > 1 AND boundary_m <= 5) AS le_5m,
       count(*) FILTER (WHERE boundary_m > 5 AND boundary_m <= 10) AS le_10m,
       count(*) FILTER (WHERE boundary_m > 10) AS gt_10m,
       max(boundary_m) AS max_boundary_m
FROM sa WHERE nearest IS NOT NULL AND interval_sec IS NOT NULL AND nearest <> interval_sec;

-- Q4 per transect
SELECT transect_code, transect_id, count(*) AS records,
       count(*) FILTER (WHERE nearest IS NOT NULL AND nearest = interval_sec) AS agree,
       count(*) FILTER (WHERE nearest IS NOT NULL AND interval_sec IS NOT NULL
                          AND nearest <> interval_sec) AS disagree,
       count(*) FILTER (WHERE nearest IS NOT NULL AND interval_sec IS NULL) AS nearest_only,
       count(*) FILTER (WHERE nearest IS NULL AND interval_sec IS NOT NULL) AS interval_only
FROM sa GROUP BY transect_code, transect_id ORDER BY transect_code, transect_id;

-- Q5 transects whose sections do not tile the line: a gap or overlap larger than 0.5 m between
-- end_m and the next start_m, or a first start_m / last end_m more than 1 m from 0 / the length.
WITH len AS (
  SELECT t.id AS transect_id, t.code,
         round(ST_Length(ST_Transform(t.geometry,
           (CASE WHEN ST_Y(ST_Centroid(t.geometry)) >= 0 THEN 32600 ELSE 32700 END)
           + (floor((ST_X(ST_Centroid(t.geometry)) + 180) / 6)::int % 60) + 1))::numeric, 1) AS length_m
  FROM public.transect t JOIN public.project p ON p.id = t.project_id
  WHERE t.deleted_at IS NULL AND p.deleted_at IS NULL
), g AS (
  SELECT transect_id, sequence_number, start_m, end_m,
         lead(start_m) OVER w - end_m AS to_next,
         row_number() OVER w AS rn, count(*) OVER (PARTITION BY transect_id) AS n
  FROM geo.transect_sections WINDOW w AS (PARTITION BY transect_id ORDER BY sequence_number)
)
SELECT len.code, len.transect_id, len.length_m, count(g.*) AS sections,
       min(g.start_m) FILTER (WHERE g.rn = 1) AS first_start_m,
       max(g.end_m) FILTER (WHERE g.rn = g.n) AS last_end_m,
       max(g.to_next) AS max_gap_m, min(g.to_next) AS max_overlap_m
FROM len LEFT JOIN g ON g.transect_id = len.transect_id
GROUP BY len.code, len.transect_id, len.length_m
HAVING count(g.*) = 0
    OR max(g.to_next) > 0.5 OR min(g.to_next) < -0.5
    OR abs(min(g.start_m) FILTER (WHERE g.rn = 1)) > 1
    OR abs(max(g.end_m) FILTER (WHERE g.rn = g.n) - len.length_m) > 1
ORDER BY len.code;

-- Q6 loop-backs: transects with non-adjacent sections within twice the limit of each other (the
-- buffers of the limit overlap), so ST_LineLocatePoint can pick the wrong pass.
SELECT t.code, t.id AS transect_id, count(*) AS close_nonadjacent_pairs
FROM public.transect t
JOIN public.project p ON p.id = t.project_id AND p.deleted_at IS NULL
JOIN public.project_protocol pp ON pp.project_id = t.project_id
JOIN public.transect_section a ON a.transect_id = t.id AND a.deleted_at IS NULL
JOIN public.transect_section b ON b.transect_id = t.id AND b.deleted_at IS NULL
 AND b.sequence_number > a.sequence_number + 1
 AND ST_DWithin(a.geometry::geography, b.geometry::geography, 2 * pp.max_distance_from_transect_m)
WHERE t.deleted_at IS NULL
GROUP BY t.code, t.id ORDER BY t.code;
