-- title: Walked distance (T036, surveys.services.walked_distance_m)
-- tables: survey_track_point
-- source: backend/apps/surveys/services.py:256
-- The code's statement per visit, here GROUP BY visit for all visits of the bench project. The
-- filter is a btree on survey_visit_id; there is no spatial filter, only ST_MakeLine and a length.
SELECT count(*) AS visits, round(sum(x.length_m)) AS total_m
FROM (
    SELECT v.id,
           ST_Length(ST_MakeLine(tp.geometry ORDER BY tp.recorded_at, tp.sequence_number)::geography) AS length_m
    FROM survey_visit v
    JOIN project_protocol pp ON pp.project_id = v.project_id
    JOIN survey_track_point tp ON tp.survey_visit_id = v.id
    WHERE v.project_id = :'project' AND v.deleted_at IS NULL
      AND tp.deleted_at IS NULL
      AND (tp.accuracy_m IS NULL OR tp.accuracy_m <= pp.gps_accuracy_warning_m * 2)
    GROUP BY v.id
    HAVING count(*) >= 2
) x;
