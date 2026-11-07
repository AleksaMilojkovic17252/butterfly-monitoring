-- title: far_from_transect flag (T056, validation.flags._is_far_from_transect)
-- tables: transect
-- source: backend/apps/validation/flags.py:57
-- The code looks the transect up by id (a primary-key lookup) and measures one distance, so no
-- spatial index can matter here. This file shows that; set-based over the project's transect
-- observations.
SELECT count(*) AS observations,
       count(*) FILTER (
         WHERE ST_Distance(t.geometry::geography, o.geometry::geography) > pp.max_distance_from_transect_m
       ) AS far
FROM butterfly_observation o
JOIN survey_visit v ON v.id = o.survey_visit_id
JOIN transect t ON t.id = v.transect_id
JOIN project_protocol pp ON pp.project_id = o.project_id
WHERE o.project_id = :'project' AND o.source = 'transect' AND o.deleted_at IS NULL;
