-- title: OGC bbox on geo.butterfly_observations (small bbox)
-- tables: butterfly_observation
-- source: pygeoapi 0.24 bbox filter (T067); bbox is 500 m around the start of the first transect of the bench project
SELECT * FROM geo.butterfly_observations WHERE ST_Intersects(ST_MakeEnvelope(:sxmin, :symin, :sxmax, :symax, 4326), geometry);
