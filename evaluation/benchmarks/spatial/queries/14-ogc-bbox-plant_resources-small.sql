-- title: OGC bbox on geo.plant_resources (small bbox)
-- tables: plant_resource_observation
-- source: pygeoapi 0.24 bbox filter (T067); bbox is 500 m around the start of the first transect of the bench project
SELECT * FROM geo.plant_resources WHERE ST_Intersects(ST_MakeEnvelope(:sxmin, :symin, :sxmax, :symax, 4326), geometry);
