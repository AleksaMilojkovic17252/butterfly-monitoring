-- title: OGC bbox on geo.transect_sections (wide bbox)
-- tables: transect_section
-- source: pygeoapi 0.24 bbox filter (T067); bbox is the bench project area envelope
SELECT * FROM geo.transect_sections WHERE ST_Intersects(ST_MakeEnvelope(:wxmin, :wymin, :wxmax, :wymax, 4326), geometry);
