-- C: expression index so KNN on geography can use it.
CREATE INDEX bench_c_plant_geog ON plant_resource_observation USING gist ((geometry::geography));
