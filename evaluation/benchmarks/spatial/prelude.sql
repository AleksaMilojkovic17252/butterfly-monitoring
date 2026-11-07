-- Variables for the bbox queries, set once per session from the bench project (psql variable `project`).
-- wide: the envelope of the project area. small: 500 m around the start of the first transect.
SELECT ST_XMin(e) AS wxmin, ST_YMin(e) AS wymin, ST_XMax(e) AS wxmax, ST_YMax(e) AS wymax
FROM (SELECT ST_Envelope(area) AS e FROM project WHERE id = :'project') x \gset
SELECT ST_XMin(e) AS sxmin, ST_YMin(e) AS symin, ST_XMax(e) AS sxmax, ST_YMax(e) AS symax
FROM (SELECT ST_Envelope(ST_Buffer(ST_StartPoint(geometry)::geography, 500)::geometry) AS e
      FROM transect WHERE project_id = :'project' AND deleted_at IS NULL ORDER BY code LIMIT 1) x \gset
