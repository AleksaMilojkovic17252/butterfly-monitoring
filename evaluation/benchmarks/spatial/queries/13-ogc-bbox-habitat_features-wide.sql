-- title: OGC bbox on geo.habitat_features (wide bbox)
-- tables: habitat_feature
-- source: pygeoapi 0.24 bbox filter (T067); bbox is the bench project area envelope
SELECT * FROM geo.habitat_features WHERE ST_Intersects(ST_MakeEnvelope(:wxmin, :wymin, :wxmax, :wymax, 4326), geometry);
