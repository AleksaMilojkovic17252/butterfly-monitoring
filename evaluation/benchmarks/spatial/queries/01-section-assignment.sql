-- title: Section assignment (T048, transects.services.nearest_section_id)
-- tables: transect_section
-- source: backend/apps/transects/services.py:238
-- The code runs this statement once per new observation. Here it runs once for every live transect
-- observation of the bench project (LATERAL), so one run takes long enough to time. The inner
-- statement is the code's text: the geography casts, ST_DWithin, KNN ORDER BY, LIMIT 1. The code
-- passes the point as ST_GeomFromEWKT(...); here it is o.geometry. The limit is the protocol's value.
SELECT count(*) AS observations, count(s.id) AS assigned
FROM butterfly_observation o
JOIN survey_visit v ON v.id = o.survey_visit_id
JOIN project_protocol pp ON pp.project_id = o.project_id
LEFT JOIN LATERAL (
    SELECT id FROM transect_section
    WHERE transect_id = v.transect_id AND deleted_at IS NULL
      AND ST_DWithin(geometry::geography, o.geometry::geography, pp.max_distance_from_transect_m)
    ORDER BY geometry::geography <-> o.geometry::geography, sequence_number
    LIMIT 1
) s ON true
WHERE o.project_id = :'project' AND o.source = 'transect' AND o.deleted_at IS NULL;
