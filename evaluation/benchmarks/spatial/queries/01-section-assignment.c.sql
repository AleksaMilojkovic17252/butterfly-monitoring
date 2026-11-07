-- title: Section assignment, C2: geometry prefilter with an exact geography recheck
-- tables: transect_section
-- source: rewrite of backend/apps/transects/services.py:238
-- The GiST index on geometry (config B's index) does the pre-selection: a bounding-box filter
-- on the point widened by the limit in degrees (0.01 deg is over 1 km in latitude, and a metre
-- of longitude is longer in degrees than a metre of latitude at this latitude, so the box is
-- generous), then the exact metric (geography) decides, exactly as in the code. KNN order stays on
-- geography among the few rows left.
SELECT count(*) AS observations, count(s.id) AS assigned
FROM butterfly_observation o
JOIN survey_visit v ON v.id = o.survey_visit_id
JOIN project_protocol pp ON pp.project_id = o.project_id
LEFT JOIN LATERAL (
    SELECT id FROM transect_section
    WHERE transect_id = v.transect_id AND deleted_at IS NULL
      AND geometry && ST_Expand(o.geometry, 0.01)
      AND ST_DWithin(geometry::geography, o.geometry::geography, pp.max_distance_from_transect_m)
    ORDER BY geometry::geography <-> o.geometry::geography, sequence_number
    LIMIT 1
) s ON true
WHERE o.project_id = :'project' AND o.source = 'transect' AND o.deleted_at IS NULL;
