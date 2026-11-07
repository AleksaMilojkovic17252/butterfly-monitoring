-- title: outside_project_area flag (T056, validation.flags)
-- tables: butterfly_observation
-- source: backend/apps/validation/flags.py:47
-- The code does this in GEOS (project.area.covers(point)) with no query. This is the SQL
-- equivalent, over the project's live observations: a join on project id, then one ST_Covers each.
SELECT count(*) AS observations,
       count(*) FILTER (WHERE NOT ST_Covers(p.area, o.geometry)) AS outside
FROM butterfly_observation o
JOIN project p ON p.id = o.project_id
WHERE o.project_id = :'project' AND o.deleted_at IS NULL;
