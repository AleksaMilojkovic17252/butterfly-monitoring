-- C: an expression index on the geography cast, which the code's own filter and KNN can use.
CREATE INDEX bench_c_section_geog ON transect_section USING gist ((geometry::geography));
