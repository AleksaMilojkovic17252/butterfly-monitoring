-- title: OGC bbox on geo.transects (wide bbox)
-- tables: transect
-- source: pygeoapi 0.24 bbox filter (T067); bbox is the bench project area envelope
SELECT * FROM geo.transects WHERE ST_Intersects(ST_MakeEnvelope(:wxmin, :wymin, :wxmax, :wymax, 4326), geometry);
