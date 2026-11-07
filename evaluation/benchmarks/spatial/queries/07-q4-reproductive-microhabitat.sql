-- title: Q4 reproductive microhabitat (T101, report_reproductive_microhabitat)
-- tables: butterfly_observation habitat_feature
-- source: backend/apps/reports/migrations/0003_research_questions.py
-- Geometry ST_Intersects between reproductive records and habitat polygons of the project.
SELECT * FROM report_reproductive_microhabitat WHERE project_id = :'project';
