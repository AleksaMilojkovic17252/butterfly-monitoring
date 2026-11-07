-- title: OGC bbox on geo.plant_resources (wide bbox)
-- tables: plant_resource_observation
-- source: pygeoapi 0.24 bbox filter (T067); bbox is the bench project area envelope
SELECT * FROM geo.plant_resources WHERE ST_Intersects(ST_MakeEnvelope(:wxmin, :wymin, :wxmax, :wymax, 4326), geometry);
