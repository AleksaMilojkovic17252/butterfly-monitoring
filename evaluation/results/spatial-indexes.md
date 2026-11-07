# Spatial indexes on the simulated season (T102)

**The data is simulated, on one laptop, from one generator run.** The question: do the spatial queries of the app use their
GiST indexes, does the `::geography` cast block them, and would a fix pay off? Method and files:
[evaluation/benchmarks/spatial/](../benchmarks/spatial/README.md) (the runner is committed; T096 reuses it).

## Setup

- 2026-11-07, Intel Core i5-1235U (12 threads), 31 GB RAM, Docker Compose, PostgreSQL 17.5, PostGIS 3.5.2 (GEOS 3.9.0, PROJ 7.2.1),
  default configuration. Everything is in cache (`shared_read` is 0 except query 04 at scale 10: 523 blocks of `survey_track_point` in both A and B, so that median includes some disk reads).
- Two scratch databases, `butterfly_bench_s1` and `butterfly_bench_s10`, restored from a T010 backup of the dev database (`scripts/backup.sh`), then
  `VACUUM ANALYZE`. The dev database was not touched (row counts before and after are the same).
- In each, a copy of the demo project "Demo – Fruška Gora 2026" (4 transects, 26 sections), then
  `simulate_season --seed 42 --direct` with `--visits-per-transect 8` (**scale 1**, the default) or `80` (**scale 10**).
  Both databases also hold the restored dev data as background, the same in both.

| Rows | Scale 1: bench project | Scale 1: whole database | Scale 10: bench project | Scale 10: whole database |
|---|--:|--:|--:|--:|
| `butterfly_observation` | 441 | 4 628 | 4 038 | 8 225 |
| `survey_track_point` | 5 789 | 54 559 | 60 946 | 109 716 |
| `survey_visit` | 32 | 738 | 320 | 1 026 |
| `plant_resource_observation` | 14 | 246 | 14 | 246 |
| `habitat_feature` | 11 | 174 | 11 | 174 |
| `transect_section` | 26 | 277 | 26 | 277 |

Visits, observations and track points grow about 10×. **Plant records, habitat features and sections do not**: the generator makes the same
ones at every scale. So query 08 (nearest host plant) and the habitat joins stay tiny, which limits what they can show.

**Method.** Each query file (`queries/`) is set-based: it runs the code's statement once per row of the bench project. Configs:
**A** the GiST indexes of the query's tables dropped (`DROP INDEX` inside `BEGIN … ROLLBACK`; the btree indexes stay),
**B** as the app has it, **C1** B plus an index, **C2** B's indexes plus a rewritten query. 1 warm-up and 10 timed
`EXPLAIN (ANALYZE, TIMING OFF)` runs, **median** of `Execution Time` in ms; the plan node comes from one `EXPLAIN (ANALYZE, BUFFERS)`
per config. Raw output: `tmp/t102/out/` (not committed).

## Scale 1 (8 visits per transect), median ms

| Query | A: no GiST | B: as is | C1 | C2 | GiST in B plan |
|---|--:|--:|--:|--:|---|
| `01-section-assignment` | 9.46 | 9.49 | 11.90 | 16.99 | no |
| `02-far-from-transect` | 2.22 | 2.21 | – | – | no |
| `03-outside-project-area` | 0.18 | 0.23 | – | – | no |
| `04-walked-distance` | 12.37 | 12.44 | – | – | Seq Scan |
| `05-route-coverage` | 40.20 | 40.93 | – | – | no |
| `06-q3-specialist-host-plants` | 4.18 | 48.56 | – | 10.61 | GiST |
| `07-q4-reproductive-microhabitat` | 1.26 | 0.47 | – | – | GiST |
| `08-knn-host-plant` | 10.52 | 10.31 | 28.47 | – | Seq Scan |
| `10-ogc-bbox-transects-small` | 0.40 | 0.22 | – | – | GiST |
| `10-ogc-bbox-transects-wide` | 0.58 | 1.07 | – | – | no |
| `11-ogc-bbox-transect_sections-small` | 1.67 | 1.44 | – | – | GiST |
| `11-ogc-bbox-transect_sections-wide` | 7.81 | 7.92 | – | – | GiST |
| `12-ogc-bbox-butterfly_observations-small` | 12.54 | 11.62 | – | – | GiST |
| `12-ogc-bbox-butterfly_observations-wide` | 63.03 | 56.48 | – | – | GiST |
| `13-ogc-bbox-habitat_features-small` | 0.10 | 0.20 | – | – | GiST |
| `13-ogc-bbox-habitat_features-wide` | 0.31 | 0.18 | – | – | GiST |
| `14-ogc-bbox-plant_resources-small` | 0.12 | 0.10 | – | – | GiST |
| `14-ogc-bbox-plant_resources-wide` | 0.27 | 0.16 | – | – | GiST |
| `15-ogc-bbox-observation_hexgrid-small` | 880.19 | 664.74 | – | – | GiST |
| `15-ogc-bbox-observation_hexgrid-wide` | 1890.93 | 707.06 | – | – | GiST |

## Scale 10 (80 visits per transect), median ms

| Query | A: no GiST | B: as is | C1 | C2 | GiST in B plan |
|---|--:|--:|--:|--:|---|
| `01-section-assignment` | 108.01 | 105.67 | 104.37 | 159.94 | no |
| `02-far-from-transect` | 18.55 | 18.58 | – | – | no |
| `03-outside-project-area` | 2.17 | 2.54 | – | – | Seq Scan |
| `04-walked-distance` | 97.26 | 101.68 | – | – | Seq Scan |
| `05-route-coverage` | 570.07 | 524.89 | – | – | no |
| `06-q3-specialist-host-plants` | 7.32 | 54.68 | – | 14.09 | GiST |
| `07-q4-reproductive-microhabitat` | 9.09 | 0.75 | – | – | GiST |
| `08-knn-host-plant` | 94.98 | 93.82 | 227.34 | – | Seq Scan |
| `10-ogc-bbox-transects-small` | 0.38 | 0.15 | – | – | GiST |
| `10-ogc-bbox-transects-wide` | 0.57 | 0.59 | – | – | no |
| `11-ogc-bbox-transect_sections-small` | 1.54 | 1.43 | – | – | GiST |
| `11-ogc-bbox-transect_sections-wide` | 7.54 | 7.40 | – | – | GiST |
| `12-ogc-bbox-butterfly_observations-small` | 64.37 | 22.84 | – | – | GiST |
| `12-ogc-bbox-butterfly_observations-wide` | 162.56 | 116.91 | – | – | GiST |
| `13-ogc-bbox-habitat_features-small` | 0.13 | 0.10 | – | – | GiST |
| `13-ogc-bbox-habitat_features-wide` | 0.28 | 0.17 | – | – | GiST |
| `14-ogc-bbox-plant_resources-small` | 0.18 | 0.09 | – | – | GiST |
| `14-ogc-bbox-plant_resources-wide` | 0.27 | 0.29 | – | – | GiST |
| `15-ogc-bbox-observation_hexgrid-small` | 1002.19 | 650.27 | – | – | GiST |
| `15-ogc-bbox-observation_hexgrid-wide` | 3320.65 | 694.97 | – | – | GiST |

"GiST in B plan": whether a plan node in config B scans a GiST index of the query's tables. Files `NN-name.sql` are described in the
benchmark folder; `10`–`15` are the pygeoapi bbox filter on each `geo` view, `-wide` = the project area's envelope, `-small` = 500 m around the first transect's start.

## Reading, per query (scale 10 unless said)

- **01 section assignment (T048).** B does **not** use a spatial index, and neither does the code's `::geography` cast matter: the
  `transect_id = …` predicate selects the transect's 6–7 sections through the btree `section_seq_unique`, and the geography distance is only
  a filter on those. A, B and C1 are within 2 % (about 98 ms for 4 038 observations, 24 µs each). C1 (expression index on `geometry::geography`) is
  used by the planner and is no faster; C2 (`&&` prefilter on `geometry`) is **44 % slower** (141 ms), because it
  adds an index probe to a 7-row table. No fix.
- **02 far_from_transect, 05 route coverage, 04 walked distance.** No spatial filter on a stored geometry, so A = B (02: primary-key lookup of the
  transect; 04: sequential read of the track points; 05: btree on `survey_visit_id`, then computed geometries). Their time is the geometry work
  (distance on geography; `ST_MakeLine`; UTM transform and interpolation: 1.6 ms per visit for 05). Indexes cannot help.
- **03 outside_project_area.** A = B: the project id picks the rows, then `ST_Covers` against one polygon. 1.6 ms.
- **06 Q3 specialist host plants (view).** **B is 7–12× slower than A** (55 against 7.3 ms at scale 10; 49 against 4.2 ms at scale 1). The planner
  puts an index scan on the GiST index of `plant_resource_observation` under a nested loop (26 loops) with an estimated 1 row, while the table
  has 246 rows; the sequential scan of A is cheaper. **C2 is the view's own SQL without its `&&` prefilter** (the exact geography `ST_DWithin` stays; the rows
  are identical, checked by comparing both outputs at scale 10): **14 ms at scale 10 and 11 ms at scale 1, so 3.9× and 4.6× faster than B**, with the plan of A (sequential scan of the plant table).
  This is the one variant that clearly wins (at least 2× at scale 10 and not slower at scale 1). The prefilter was meant to help the metric test; on 246 plant rows it is what
  makes the planner choose the index. Absolute gain: 41 ms per read of the view. **Applied in T102** as `reports/0004_q3_drop_bbox_prefilter` (drops and recreates the view without the `&&` term). After it, on the scale-10 database: A 13.5, B **13.6**, C2 13.6 ms (`tmp/t102/out/s10-after/`); the output is identical before and after, and the migration reverses. The tables above are from before the migration, which is why B is slow there.
- **07 Q4 reproductive microhabitat (view).** B uses the GiST index of `butterfly_observation` for the `ST_Intersects` with the polygons and is
  **14× faster** than A (0.57 against 7.8 ms), the clearest case of GiST paying off. The habitat table (11 polygons) is scanned sequentially in both.
- **08 KNN nearest larval host.** The 4-row `larval_host` set of the project is read sequentially in A and B (86 ms for 4 038 observations). C1 (an expression index on
  `geography`) makes the planner use `<->` through the index and is **2.5× slower** (212 ms): the index scan of 246 rows is dearer than sorting a few. The plant
  table does not grow with the scale, so this says only that nothing is gained at this size.
- **10–15 OGC bbox on the `geo` views.**
  - `geo.transects`: the small bbox uses the GiST index (0.13 against 0.38 ms), the wide bbox does **not**: the planner picks the `project_id` btree instead
    (0.55 ms either way; the T067 note holds at scale). Same for A.
  - `geo.transect_sections` (26 live rows in the project, 277 in the table), `geo.habitat_features`, `geo.plant_resources`: sub-millisecond to 7 ms. GiST is used in B for
    the small boxes; the differences are a fraction of a millisecond (for the sections' small box B is even slower than A: 2.5 against 1.4 ms).
  - `geo.butterfly_observations`: GiST is used in B. Small bbox: **2.9× faster** than A (20 against 58 ms); wide bbox (about 3 000 of the bench project's 4 038 observations inside, plus background rows; the view is not filtered by project): 1.35× (110 against 148 ms). The remaining
    time is the view's joins.
  - `geo.observation_hexgrid`: the slowest query in the set, **0.6 s in B at both box sizes**, and 5× slower in A for the wide box (3.0 s). The cost is the hexagon
    aggregation, not the index. The view recomputes the grid on every request; the wide bbox takes 0.6 s on 4 038 records.

At scale 1 every query is within the same orders and the same ranking (the table above); the only ratios that grow with the data are 12-small (1.1× → 2.9×), 15-wide
(2.9× → 5.1×) and 07 (2.6× → 14×), as the sequential alternative grows with the rows while the index probe does not.

## Index sizes

GiST indexes at scale 10 (`index-sizes.csv`), largest first:

| Index | Table | Size | |
|---|---|--:|---|
| `survey_track_point_geometry_…_id` | `survey_track_point` | 4 504 kB | live |
| `historical_butterfly_observation_geometry_…_id` | `historical_butterfly_observation` | 368 kB | **historical** |
| `butterfly_observation_geometry_…_id` | `butterfly_observation` | 344 kB | live |
| `historical_transect_geometry_…_id` | `historical_transect` | 216 kB | **historical** |
| `transect_geometry_…_id` | `transect` | 136 kB | live |
| `historical_plant_resource_observation_geometry_…_id` | `historical_plant_resource_observation` | 32 kB | **historical** |
| `historical_habitat_feature_geometry_…_id`, `historical_transect_section_geometry_…_id` | | 24 kB each | **historical** |
| the other 7 (`transect_section`, `habitat_feature`, `plant_resource_observation`, `project.area`, `transect_proposal`, `historical_project`, `historical_transect_proposal`) | | 8 kB each | mixed |
| C1: `bench_c_section_geog` (section), `bench_c_plant_geog` (plant) | | 32 kB, 24 kB | benchmark only |

The 7 GiST indexes on `historical_*` tables total **680 kB**, against 5 024 kB for all live GiST indexes (4 504 kB of them on the track points, the
only table that has no history).

**Decision on the historical GiST indexes (recommendation, not done in T102).** Nothing queries history spatially (the history reads of T027
go by `(id, server_version)`), so these indexes serve no query. Their cost is 680 kB here (12 % of all GiST indexes) and one more index insert per history row (write time not measured).
Both are small, but the benefit is exactly zero: **recommend dropping them**. A model-level change is needed (the history models copy the geometry fields of the audited model, which carry the GiST index), so this is a
follow-up for the developer to make a ticket: for example `HistoricalRecords` with the geometry fields' index turned off and a migration with `DROP INDEX`. Not worth doing before it is a
visible problem; keeping them is harmless.

## Limits

- One laptop, one generator run (seed 42), the same four transects at both scales. Scale 10 is ten times the visits, observations and track points,
  not ten times the transects, plants or habitat polygons: a join that depends on those (08, 07's habitat side) is not stressed.
- The largest table is 110 k rows (track points) and 8 k observations, all cached. At this size a sequential scan beating or matching an index is a valid result, and
  it is what most queries show. How the picture changes beyond about 10⁵ observations is not measured.
- The queries are the code's statements run set-based, not the application's request path: the cost of Django, the network and pygeoapi is not in the numbers.
- Medians of 10 runs after one warm-up; the min and max in `results.csv` are within a few percent except where stated.
- **Set-based, not per row.** 01, 02 and 08 run the code's statement as a `LATERAL` or join over the project's rows. The app runs it once per observation with the point as a constant
  (`ST_GeomFromEWKT`) and the limit as a parameter, which can change the plan. The per-row cost seen here (about 24 µs for section assignment) is an average over a set, not a measurement of one call.
- **Role.** The bbox queries on `geo` views ran as `django_app` over the whole database (the bench project's data plus the restored dev data), not as `pygeoapi_ro`; the bbox is the bench project's area, but the
  view rows returned include any project inside it.
