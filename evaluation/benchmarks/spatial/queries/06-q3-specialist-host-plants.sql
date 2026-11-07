-- title: Q3 specialist host plants (T101, report_specialist_host_plants)
-- tables: butterfly_observation plant_resource_observation
-- source: backend/apps/reports/migrations/0003_research_questions.py
-- The view already has an && ST_Expand prefilter before its metric test.
SELECT * FROM report_specialist_host_plants WHERE project_id = :'project';
