-- title: OGC bbox on geo.habitat_features (small bbox)
-- tables: habitat_feature
-- source: pygeoapi 0.24 bbox filter (T067); bbox is 500 m around the start of the first transect of the bench project
SELECT * FROM geo.habitat_features WHERE ST_Intersects(ST_MakeEnvelope(:sxmin, :symin, :sxmax, :symax, 4326), geometry);
