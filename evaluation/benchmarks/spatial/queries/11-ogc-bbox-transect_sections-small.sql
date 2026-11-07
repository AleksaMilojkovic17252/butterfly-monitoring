-- title: OGC bbox on geo.transect_sections (small bbox)
-- tables: transect_section
-- source: pygeoapi 0.24 bbox filter (T067); bbox is 500 m around the start of the first transect of the bench project
SELECT * FROM geo.transect_sections WHERE ST_Intersects(ST_MakeEnvelope(:sxmin, :symin, :sxmax, :symax, 4326), geometry);
