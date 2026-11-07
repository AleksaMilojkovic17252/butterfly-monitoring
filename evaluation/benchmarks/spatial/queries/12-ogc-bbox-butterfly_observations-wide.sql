-- title: OGC bbox on geo.butterfly_observations (wide bbox)
-- tables: butterfly_observation
-- source: pygeoapi 0.24 bbox filter (T067); bbox is the bench project area envelope
SELECT * FROM geo.butterfly_observations WHERE ST_Intersects(ST_MakeEnvelope(:wxmin, :wymin, :wxmax, :wymax, 4326), geometry);
