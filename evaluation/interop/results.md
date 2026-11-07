# OGC interoperability results (T070)

**Date:** 2026-11-07 · 

| Item | Version / value |
|---|---|
| Server | pygeoapi 0.24.0 (`geopython/pygeoapi:0.24.0`), behind nginx `auth_request` (D-080) |
| CITE suite | `ogccite/ets-ogcapi-features10:1.8-teamengine-5.7` (ETS 1.8, TEAM Engine 5.7) |
| QGIS | 4.2.3 Belém do Pará, Qt 6.12.0, Python 3.14.9 (`01-about.png`) |
| GDAL | 3.13.3 |
| geopandas / pyogrio / requests | 1.2.0 / 0.13.0 (bundled GDAL 3.12.4) / 2.34.2 · Python 3.14 |
| R / httr2 / ggplot2 | 4.6.2 / 1.3.0 / 4.0.3 (`sf` not used) |
| Data | simulated season (T071, seed 42): transects 33, transect-sections 207, butterfly-observations 3982, plant-resources 112, habitat-features 83, observation-hexgrid 454 |

The ticket says 5 collections; the server publishes 6 (`observation-hexgrid` was added by T101) and all 6 are tested.

## Results

| Client | Operation | Result | Notes |
|---|---|---|---|
| QGIS | Connect with API Header token | pass | QGIS 4.2.3, GDAL 3.13.3, connection `butterfly-skeleton`, CRS OGC:CRS84 (`02-connection.png`) |
| QGIS | Load all 6 collections | pass | all six listed and added (`02-connection-layers.png`); the map zooms to Serbia, clusters near Novi Sad and in the south-east |
| QGIS | Field types match queryables | pass, one exception | `butterfly-observations` (`03-fields-observations.png`, `-b`): all match (`observed_at` Date & Time, `count` Integer 32 bit, the three `_m` fields Decimal, rest Text). `plant-resources` (`03-fields-polygon.png`): `observed_at` and `patch_area_m2` match, but the three boolean fields (`eggs_present`, `larvae_present`, `feeding_damage_present`) show as Text. The server sends JSON booleans, but they are null in 109 / 112 / 112 simulated records, and QGIS seems to infer types from the data (not tested with filled-in values) |
| QGIS | Geometry draws in the right place | pass (lines), overview only for points and polygons | `04-geometry.png`: transects (lines) at 1:7864 in Niš, at 21.93°E 43.33°N; the simulated lines are straight segments across the street grid, not along paths. Points and polygons are only shown at overview scale (`02-connection-layers.png`), clusters near Novi Sad and Niš; mixed-geometry layers (`plant-resources`, `habitat-features`) not inspected |
| QGIS | Temporal Controller on observations | pass | Layer Properties → Temporal: Single Field with Date/Time, `observed_at`, event duration 7 days (`05-temporal-setup.png`). Animated, step 1 week: frame 2026-11-08 to 11-15 shows about 3 point locations (`05-week-A.png`), frame 2026-11-01 to 11-08 about 6 (`05-week-B.png`). The animation range QGIS set was only 2026-10-11 to 2026-11-14, probably from the features loaded for the zoomed-in view (not tested); the two weeks are consecutive, not early versus peak season |
| Python | Read each of 6 collections, `read == numberMatched` | pass | 33, 207, 3982, 112, 83, 454 features, each equal to `numberMatched` (assert in the notebook); geometry types LineString, LineString, Point, Point+Polygon, LineString+Point+Polygon, Polygon |
| Python | Paging, observations > 1000 | pass | observations 3982 in 4 pages (`limit=1000`, `sortby=id`, `rel=next`); all others 1 page |
| Python | GDAL OAPIF read via `geopandas.read_file` | pass (reported) | needs `GDAL_HTTP_HEADER_FILE` (D-080). Reported by the developer after a run in VSCodium; the saved notebook holds no output for this cell |
| Python | Map of transects and observations | pass | `evaluation/interop/notebook-map.png`: two clusters in Serbia, near 45.15°N 19.8°E and 43.3°N 22.0°E |
| R | Read observations and paging | pass | httr2: 3982 rows read, `numberMatched` 3982, 4 pages (`limit=1000`, `sortby=id`, `next` links) |
| R | Phenology chart | pass | `phenology.png`: 6 facets, one per most numerous species, weeks 16–45 |
| CITE | OGC API – Features 1.0 core + CRS by reference, 6 collections | **896 passed, 0 failed, 36 skipped** (932) | second run; the first run had 9 failures, fixed with a time column (below) |

## Expected field types (from `/collections/<c>/queryables`)

| Collection | Types |
|---|---|
| butterfly-observations | `observed_at` date-time; `count` integer; `location_accuracy_m`, `distance_along_m`, `offset_m` number; every other field string (ids are UUID strings, not a UUID type) |
| transects | `created_at` date-time; `target_length_m`, `length_m` number; `active` boolean; `section_count` integer; the rest string |
| transect-sections | `created_at` date-time; `sequence_number` integer; `length_m`, `start_m`, `end_m` number; the rest string |
| plant-resources | `observed_at` date-time; `patch_area_m2` number; `eggs_present`, `larvae_present`, `feeding_damage_present` boolean; the rest string |
| habitat-features | `observed_at` date-time; `vegetation_height_cm`, `shrub_cover_pct`, `tree_cover_pct`, `bare_ground_pct` integer; the rest string |
| observation-hexgrid | `last_observed_at` date-time; `hex_size_m`, `observations`, `individuals`, `species`, `nectaring_records`, `reproductive_records` integer; ids string |

## QGIS checklist

Screenshots in `evaluation/interop/qgis/`:

1. `01-about.png`: QGIS 4.2.3, GDAL 3.13.3.
2. `02-connection.png`, `02-connection-layers.png`: connection and all 6 layers loaded.
3. `03-fields-observations.png`, `03-fields-observations-b.png`, `03-fields-polygon.png` (`plant-resources`): field types, one exception (booleans read as Text, see the row above).
4. `04-geometry.png`: transects in Niš. Points and polygons only at overview scale.
5. `05-temporal-setup.png`, `05-week-A.png`, `05-week-B.png`: Temporal Controller.

Not tried: the mixed-geometry layers (`plant-resources`, `habitat-features`) at feature level, and the hexgrid fields.

## OGC CITE

Run 2026-11-07 against `pygeoapi-cite` (second instance, no nginx or auth), `noofcollections=-1`. Files in `evaluation/interop/cite/`:
`report.html` (summary built from the XML), `testng-results.xml`, `earl.rdf`. Total 932 · passed 896 · failed 0 · skipped 36 (the saved files are from the second run).

### Failures

First run (before the change below): 887 passed, 9 failed, 36 skipped. All 9 were `timeParameterDefinition`: pygeoapi advertises `datetime` in OpenAPI
only for a collection with a `time_field`, and `transects`, `transect-sections` and `observation-hexgrid` had none (they answered 500 to `datetime=`, D-079 limit 1).

**Fixed in this ticket (D-113):** the three views gained a time column and the config sets `time_field`: `created_at` on transects and sections (the row's own
creation time) and `last_observed_at` on the hexagons (newest record counted in the cell; a hexagon is computed, so it has no creation time).
Second run: **896 passed, 0 failed, 36 skipped**. `datetime=` now filters all six collections (checked directly).

### Skips (36, unchanged by the fix)

- `validateFeaturesOperation_QueryParamUnknown`, 6: skipped by the suite, "Free-form parameters are supported for collection …". pygeoapi advertises vendor-specific
  parameters, so the "unknown parameter answers 400" test does not apply. This is also why `?nonsense=1` is ignored (D-079 limit 2).
- `validateFeaturesWithBoundingBoxResponse`, 30 (5 per collection): skipped with "No features were returned for collection." The suite derives six bounding boxes per collection
  (one of them passes for every collection) and skips the cases where its box returns no features. No test failed; the bbox operation test passes for all 6 collections.

### Known limits that CITE did not report

The suite did not flag limit 3 (no `ORDER BY` without `sortby`), limit 6 (400 for a datetime outside the static extent) or the static extent (D-079). It does not follow
`next` links further than 3 pages.
