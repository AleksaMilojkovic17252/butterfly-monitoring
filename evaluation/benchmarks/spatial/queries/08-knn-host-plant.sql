-- title: Nearest larval host plant (KNN, no code does this yet)
-- tables: plant_resource_observation
-- source: ticket T102
-- Each live observation of the bench project gets the nearest live larval_host plant record of the
-- same project, KNN on geography. The plant table is small and does not grow with --visits-per-transect
-- (the generator makes the same plant records at every scale), so this is a limit of the benchmark.
SELECT count(*) AS observations, count(p.id) AS matched
FROM butterfly_observation o
LEFT JOIN LATERAL (
    SELECT pr.id FROM plant_resource_observation pr
    WHERE pr.project_id = o.project_id AND pr.deleted_at IS NULL AND pr.resource_type = 'larval_host'
    ORDER BY pr.geometry::geography <-> o.geometry::geography
    LIMIT 1
) p ON true
WHERE o.project_id = :'project' AND o.deleted_at IS NULL;
