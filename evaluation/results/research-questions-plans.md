# Plans of the research-question spatial joins (T101, for T102)

`EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF)` on the dev database, 2026-11-07, on the planted project (`T101 planted effects`: 571 observations, 26 habitat features, 34 plant records, 4 tran...

Reproduce: `EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF) SELECT * FROM <view> WHERE project_id = '<uuid>'` as the database owner.

## Q1 · incidental record to habitat polygon (`report_habitat_richness`)

`habitat_feature` GiST `habitat_feature_geometry_4ee5e74f_id`, inner side of the lateral join (`geometry && o.geometry`, then the exact `ST_Intersects`). Natural plan: yes. The outer side...

Planner's choice:

```
Nested Loop Left Join (actual rows=7 loops=1)
  Join Filter: (((effort_1.habitat_code)::text = (agg.habitat_code)::text) AND (effort_1.year = agg.year))
  Rows Removed by Join Filter: 42
  CTE vv
    ->  Nested Loop (actual rows=164 loops=1)
          ->  Nested Loop (actual rows=164 loops=1)
                ->  Nested Loop (actual rows=164 loops=1)
                      ->  Hash Join (actual rows=324 loops=1)
                            Hash Cond: (v.project_id = p.project_id)
                            ->  Seq Scan on survey_visit v (actual rows=324 loops=1)
                                  Filter: (deleted_at IS NULL)
                                  Rows Removed by Filter: 382
                            ->  Hash (actual rows=13 loops=1)
                                  Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                  ->  Seq Scan on project_protocol p (actual rows=13 loops=1)
                      ->  Subquery Scan on weather (actual rows=1 loops=324)
                            Filter: (cardinality(array_remove(ARRAY[CASE WHEN ((v.status)::text = 'cancelled'::text) THEN 'cancelled'::text WHEN ((v.status)::text <> ALL ('{completed,sync...
                            Rows Removed by Filter: 0
                            ->  Aggregate (actual rows=1 loops=324)
                                  ->  Values Scan on "*VALUES*" (actual rows=2 loops=324)
                                        Filter: ((column1 IS NOT NULL) AND (column2 IS NOT NULL) AND (column3 IS NOT NULL))
                                        Rows Removed by Filter: 0
                ->  Index Scan using survey_visit_pkey on survey_visit sv (actual rows=1 loops=164)
                      Index Cond: (id = v.id)
                      Filter: (deleted_at IS NULL)
          ->  Index Scan using project_protocol_project_id_key on project_protocol pp (actual rows=1 loops=164)
                Index Cond: (project_id = sv.project_id)
  CTE pairs
    ->  Hash Left Join (actual rows=1071 loops=1)
          Hash Cond: (s.habitat_type_id = ht.id)
          ->  Nested Loop (actual rows=1071 loops=1)
                ->  Nested Loop (actual rows=164 loops=1)
                      ->  CTE Scan on vv (actual rows=164 loops=1)
                      ->  Index Scan using transect_pkey on transect t (actual rows=1 loops=164)
                            Index Cond: (id = vv.transect_id)
                ->  Index Scan using transect_section_transect_id_eaa5c16f on transect_section s (actual rows=7 loops=164)
                      Index Cond: (transect_id = t.id)
                      Filter: (deleted_at IS NULL)
          ->  Hash (actual rows=7 loops=1)
                Buckets: 1024  Batches: 1  Memory Usage: 9kB
                ->  Seq Scan on habitat_type ht (actual rows=7 loops=1)
  CTE effort
    ->  GroupAggregate (actual rows=36 loops=1)
          Group Key: pairs.project_id, pairs.habitat_type_id, pairs.habitat_code, pairs.year
          ->  Sort (actual rows=1071 loops=1)
                Sort Key: pairs.project_id, pairs.habitat_type_id, pairs.habitat_code, pairs.year, pairs.visit_id
                Sort Method: quicksort  Memory: 144kB
                ->  CTE Scan on pairs (actual rows=1071 loops=1)
  CTE sect
    ->  HashAggregate (actual rows=36 loops=1)
          Group Key: pairs_1.project_id, pairs_1.habitat_type_id, pairs_1.habitat_code, pairs_1.year
          Batches: 1  Memory Usage: 24kB
          ->  HashAggregate (actual rows=156 loops=1)
                Group Key: pairs_1.project_id, pairs_1.habitat_type_id, pairs_1.habitat_code, pairs_1.year, pairs_1.section_id, pairs_1.km
                Batches: 1  Memory Usage: 72kB
                ->  CTE Scan on pairs pairs_1 (actual rows=1071 loops=1)
  CTE agg
    ->  GroupAggregate (actual rows=45 loops=1)
          Group Key: "*SELECT* 1_1".project_id, "*SELECT* 1_1".habitat_type_id, "*SELECT* 1_1".habitat_code, "*SELECT* 1_1".year
          ->  Sort (actual rows=2846 loops=1)
                Sort Key: "*SELECT* 1_1".project_id, "*SELECT* 1_1".habitat_type_id, "*SELECT* 1_1".habitat_code, "*SELECT* 1_1".year, "*SELECT* 1_1".taxon_id
                Sort Method: quicksort  Memory: 364kB
                ->  Append (actual rows=2846 loops=1)
                      ->  Subquery Scan on "*SELECT* 1_1" (actual rows=2436 loops=1)
                            ->  Hash Left Join (actual rows=2436 loops=1)
                                  Hash Cond: (ts.habitat_type_id = ht_1.id)
                                  ->  Nested Loop Left Join (actual rows=2436 loops=1)
                                        ->  Nested Loop (actual rows=2436 loops=1)
                                              ->  CTE Scan on vv vv_1 (actual rows=164 loops=1)
                                              ->  Bitmap Heap Scan on butterfly_observation o (actual rows=15 loops=164)
                                                    Recheck Cond: (survey_visit_id = vv_1.id)
                                                    Filter: ((deleted_at IS NULL) AND ((source)::text = 'transect'::text))
                                                    Heap Blocks: exact=268
                                                    ->  Bitmap Index Scan on butterfly_observation_survey_visit_id_2790ba7f (actual rows=15 loops=164)
                                                          Index Cond: (survey_visit_id = vv_1.id)
                                        ->  Index Scan using transect_section_pkey on transect_section ts (actual rows=1 loops=2436)
                                              Index Cond: (id = o.transect_section_id)
                                  ->  Hash (actual rows=7 loops=1)
                                        Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                        ->  Seq Scan on habitat_type ht_1 (actual rows=7 loops=1)
                      ->  Subquery Scan on "*SELECT* 2_1" (actual rows=410 loops=1)
                            ->  Nested Loop Left Join (actual rows=410 loops=1)
                                  ->  Hash Join (actual rows=410 loops=1)
                                        Hash Cond: (o_1.project_id = pp_1.project_id)
                                        ->  Hash Left Join (actual rows=410 loops=1)
                                              Hash Cond: (o_1.survey_visit_id = sv_1.id)
                                              Filter: ((o_1.survey_visit_id IS NULL) OR ((sv_1.deleted_at IS NULL) AND ((sv_1.status)::text <> 'cancelled'::text)))
                                              ->  Seq Scan on butterfly_observation o_1 (actual rows=410 loops=1)
                                                    Filter: ((deleted_at IS NULL) AND ((source)::text <> 'transect'::text))
                                                    Rows Removed by Filter: 3777
                                              ->  Hash (actual rows=706 loops=1)
                                                    Buckets: 1024  Batches: 1  Memory Usage: 50kB
                                                    ->  Seq Scan on survey_visit sv_1 (actual rows=706 loops=1)
                                        ->  Hash (actual rows=13 loops=1)
                                              Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                              ->  Seq Scan on project_protocol pp_1 (actual rows=13 loops=1)
                                  ->  Hash Right Join (actual rows=0 loops=410)
                                        Hash Cond: (ht_2.id = hf.habitat_type_id)
                                        ->  Seq Scan on habitat_type ht_2 (actual rows=7 loops=5)
                                        ->  Hash (actual rows=0 loops=410)
                                              Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                              ->  Subquery Scan on hf (actual rows=0 loops=410)
                                                    ->  Limit (actual rows=0 loops=410)
                                                          ->  Sort (actual rows=0 loops=410)
                                                                Sort Key: f.observed_at DESC, f.id
                                                                Sort Method: quicksort  Memory: 25kB
                                                                ->  Index Scan using habitat_feature_geometry_4ee5e74f_id on habitat_feature f (actual rows=0 loops=410)
                                                                      Index Cond: (geometry && o_1.geometry)
                                                                      Filter: ((deleted_at IS NULL) AND (project_id = o_1.project_id) AND (st_geometrytype(geometry) = ANY ('{ST_Polygon,ST...
                                                                      Rows Removed by Filter: 0
  ->  Nested Loop Left Join (actual rows=7 loops=1)
        Join Filter: (((effort_1.habitat_code)::text = (sect.habitat_code)::text) AND (effort_1.year = sect.year))
        Rows Removed by Join Filter: 36
        ->  Nested Loop Left Join (actual rows=7 loops=1)
              Join Filter: (((effort_1.habitat_code)::text = (effort.habitat_code)::text) AND (effort_1.year = effort.year))
              Rows Removed by Join Filter: 36
              ->  Unique (actual rows=7 loops=1)
                    ->  Sort (actual rows=19 loops=1)
                          Sort Key: effort_1.project_id, effort_1.habitat_type_id, effort_1.habitat_code, effort_1.year
                          Sort Method: quicksort  Memory: 26kB
                          ->  Append (actual rows=19 loops=1)
                                ->  CTE Scan on effort effort_1 (actual rows=6 loops=1)
                                      Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                      Rows Removed by Filter: 30
                                ->  CTE Scan on sect sect_1 (actual rows=6 loops=1)
                                      Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                      Rows Removed by Filter: 30
                                ->  CTE Scan on agg agg_1 (actual rows=7 loops=1)
                                      Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                      Rows Removed by Filter: 38
              ->  CTE Scan on effort (actual rows=6 loops=7)
                    Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                    Rows Removed by Filter: 30
        ->  CTE Scan on sect (actual rows=6 loops=7)
              Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
              Rows Removed by Filter: 30
  ->  CTE Scan on agg (actual rows=7 loops=7)
        Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
        Rows Removed by Filter: 38
Planning Time: 13.360 ms
Execution Time: 18.894 ms
```

With `enable_seqscan = off`:

```
Nested Loop Left Join (actual rows=7 loops=1)
  Join Filter: (((effort_1.habitat_code)::text = (agg.habitat_code)::text) AND (effort_1.year = agg.year))
  Rows Removed by Join Filter: 42
  CTE vv
    ->  Nested Loop (actual rows=164 loops=1)
          ->  Nested Loop (actual rows=164 loops=1)
                ->  Nested Loop (actual rows=164 loops=1)
                      ->  Nested Loop (actual rows=324 loops=1)
                            ->  Index Scan using survey_visit_project_id_cfcf17f2 on survey_visit v (actual rows=324 loops=1)
                                  Filter: (deleted_at IS NULL)
                                  Rows Removed by Filter: 382
                            ->  Memoize (actual rows=1 loops=324)
                                  Cache Key: v.project_id
                                  Cache Mode: logical
                                  Hits: 316  Misses: 8  Evictions: 0  Overflows: 0  Memory Usage: 2kB
                                  ->  Index Scan using project_protocol_project_id_key on project_protocol p (actual rows=1 loops=8)
                                        Index Cond: (project_id = v.project_id)
                      ->  Subquery Scan on weather (actual rows=1 loops=324)
                            Filter: (cardinality(array_remove(ARRAY[CASE WHEN ((v.status)::text = 'cancelled'::text) THEN 'cancelled'::text WHEN ((v.status)::text <> ALL ('{completed,sync...
                            Rows Removed by Filter: 0
                            ->  Aggregate (actual rows=1 loops=324)
                                  ->  Values Scan on "*VALUES*" (actual rows=2 loops=324)
                                        Filter: ((column1 IS NOT NULL) AND (column2 IS NOT NULL) AND (column3 IS NOT NULL))
                                        Rows Removed by Filter: 0
                ->  Index Scan using survey_visit_pkey on survey_visit sv (actual rows=1 loops=164)
                      Index Cond: (id = v.id)
                      Filter: (deleted_at IS NULL)
          ->  Index Scan using project_protocol_project_id_key on project_protocol pp (actual rows=1 loops=164)
                Index Cond: (project_id = sv.project_id)
  CTE pairs
    ->  Nested Loop Left Join (actual rows=1071 loops=1)
          ->  Nested Loop (actual rows=1071 loops=1)
                ->  Nested Loop (actual rows=164 loops=1)
                      ->  CTE Scan on vv (actual rows=164 loops=1)
                      ->  Index Scan using transect_pkey on transect t (actual rows=1 loops=164)
                            Index Cond: (id = vv.transect_id)
                ->  Index Scan using transect_section_transect_id_eaa5c16f on transect_section s (actual rows=7 loops=164)
                      Index Cond: (transect_id = t.id)
                      Filter: (deleted_at IS NULL)
          ->  Index Scan using habitat_type_pkey on habitat_type ht (actual rows=1 loops=1071)
                Index Cond: (id = s.habitat_type_id)
  CTE effort
    ->  GroupAggregate (actual rows=36 loops=1)
          Group Key: pairs.project_id, pairs.habitat_type_id, pairs.habitat_code, pairs.year
          ->  Sort (actual rows=1071 loops=1)
                Sort Key: pairs.project_id, pairs.habitat_type_id, pairs.habitat_code, pairs.year, pairs.visit_id
                Sort Method: quicksort  Memory: 144kB
                ->  CTE Scan on pairs (actual rows=1071 loops=1)
  CTE sect
    ->  HashAggregate (actual rows=36 loops=1)
          Group Key: pairs_1.project_id, pairs_1.habitat_type_id, pairs_1.habitat_code, pairs_1.year
          Batches: 1  Memory Usage: 24kB
          ->  HashAggregate (actual rows=156 loops=1)
                Group Key: pairs_1.project_id, pairs_1.habitat_type_id, pairs_1.habitat_code, pairs_1.year, pairs_1.section_id, pairs_1.km
                Batches: 1  Memory Usage: 72kB
                ->  CTE Scan on pairs pairs_1 (actual rows=1071 loops=1)
  CTE agg
    ->  GroupAggregate (actual rows=45 loops=1)
          Group Key: "*SELECT* 1_1".project_id, "*SELECT* 1_1".habitat_type_id, "*SELECT* 1_1".habitat_code, "*SELECT* 1_1".year
          ->  Sort (actual rows=2846 loops=1)
                Sort Key: "*SELECT* 1_1".project_id, "*SELECT* 1_1".habitat_type_id, "*SELECT* 1_1".habitat_code, "*SELECT* 1_1".year, "*SELECT* 1_1".taxon_id
                Sort Method: quicksort  Memory: 364kB
                ->  Append (actual rows=2846 loops=1)
                      ->  Subquery Scan on "*SELECT* 1_1" (actual rows=2436 loops=1)
                            ->  Nested Loop Left Join (actual rows=2436 loops=1)
                                  ->  Nested Loop Left Join (actual rows=2436 loops=1)
                                        ->  Nested Loop (actual rows=2436 loops=1)
                                              ->  CTE Scan on vv vv_1 (actual rows=164 loops=1)
                                              ->  Bitmap Heap Scan on butterfly_observation o (actual rows=15 loops=164)
                                                    Recheck Cond: (survey_visit_id = vv_1.id)
                                                    Filter: ((deleted_at IS NULL) AND ((source)::text = 'transect'::text))
                                                    Heap Blocks: exact=268
                                                    ->  Bitmap Index Scan on butterfly_observation_survey_visit_id_2790ba7f (actual rows=15 loops=164)
                                                          Index Cond: (survey_visit_id = vv_1.id)
                                        ->  Index Scan using transect_section_pkey on transect_section ts (actual rows=1 loops=2436)
                                              Index Cond: (id = o.transect_section_id)
                                  ->  Memoize (actual rows=1 loops=2436)
                                        Cache Key: ts.habitat_type_id
                                        Cache Mode: logical
                                        Hits: 2429  Misses: 7  Evictions: 0  Overflows: 0  Memory Usage: 1kB
                                        ->  Index Scan using habitat_type_pkey on habitat_type ht_1 (actual rows=1 loops=7)
                                              Index Cond: (id = ts.habitat_type_id)
                      ->  Subquery Scan on "*SELECT* 2_1" (actual rows=410 loops=1)
                            ->  Nested Loop Left Join (actual rows=410 loops=1)
                                  ->  Nested Loop Left Join (actual rows=410 loops=1)
                                        ->  Hash Left Join (actual rows=410 loops=1)
                                              Hash Cond: (o_1.survey_visit_id = sv_1.id)
                                              Filter: ((o_1.survey_visit_id IS NULL) OR ((sv_1.deleted_at IS NULL) AND ((sv_1.status)::text <> 'cancelled'::text)))
                                              ->  Nested Loop (actual rows=410 loops=1)
                                                    ->  Index Scan using project_protocol_project_id_key on project_protocol pp_1 (actual rows=13 loops=1)
                                                    ->  Bitmap Heap Scan on butterfly_observation o_1 (actual rows=32 loops=13)
                                                          Recheck Cond: (project_id = pp_1.project_id)
                                                          Filter: ((deleted_at IS NULL) AND ((source)::text <> 'transect'::text))
                                                          Rows Removed by Filter: 291
                                                          Heap Blocks: exact=227
                                                          ->  Bitmap Index Scan on butterfly_observation_project_id_665a935f (actual rows=322 loops=13)
                                                                Index Cond: (project_id = pp_1.project_id)
                                              ->  Hash (actual rows=706 loops=1)
                                                    Buckets: 1024  Batches: 1  Memory Usage: 50kB
                                                    ->  Index Scan using survey_visit_pkey on survey_visit sv_1 (actual rows=706 loops=1)
                                        ->  Limit (actual rows=0 loops=410)
                                              ->  Sort (actual rows=0 loops=410)
                                                    Sort Key: f.observed_at DESC, f.id
                                                    Sort Method: quicksort  Memory: 25kB
                                                    ->  Index Scan using habitat_feature_geometry_4ee5e74f_id on habitat_feature f (actual rows=0 loops=410)
                                                          Index Cond: (geometry && o_1.geometry)
                                                          Filter: ((deleted_at IS NULL) AND (project_id = o_1.project_id) AND (st_geometrytype(geometry) = ANY ('{ST_Polygon,ST_MultiPolygo...
                                                          Rows Removed by Filter: 0
                                  ->  Memoize (actual rows=0 loops=410)
                                        Cache Key: f.habitat_type_id
                                        Cache Mode: logical
                                        Hits: 408  Misses: 2  Evictions: 0  Overflows: 0  Memory Usage: 1kB
                                        ->  Index Scan using habitat_type_pkey on habitat_type ht_2 (actual rows=0 loops=2)
                                              Index Cond: (id = f.habitat_type_id)
  ->  Nested Loop Left Join (actual rows=7 loops=1)
        Join Filter: (((effort_1.habitat_code)::text = (sect.habitat_code)::text) AND (effort_1.year = sect.year))
        Rows Removed by Join Filter: 36
        ->  Nested Loop Left Join (actual rows=7 loops=1)
              Join Filter: (((effort_1.habitat_code)::text = (effort.habitat_code)::text) AND (effort_1.year = effort.year))
              Rows Removed by Join Filter: 36
              ->  Unique (actual rows=7 loops=1)
                    ->  Sort (actual rows=19 loops=1)
                          Sort Key: effort_1.project_id, effort_1.habitat_type_id, effort_1.habitat_code, effort_1.year
                          Sort Method: quicksort  Memory: 26kB
                          ->  Append (actual rows=19 loops=1)
                                ->  CTE Scan on effort effort_1 (actual rows=6 loops=1)
                                      Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                      Rows Removed by Filter: 30
                                ->  CTE Scan on sect sect_1 (actual rows=6 loops=1)
                                      Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                      Rows Removed by Filter: 30
                                ->  CTE Scan on agg agg_1 (actual rows=7 loops=1)
                                      Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                      Rows Removed by Filter: 38
              ->  CTE Scan on effort (actual rows=6 loops=7)
                    Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                    Rows Removed by Filter: 30
        ->  CTE Scan on sect (actual rows=6 loops=7)
              Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
              Rows Removed by Filter: 30
  ->  CTE Scan on agg (actual rows=7 loops=7)
        Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
        Rows Removed by Filter: 38
Planning Time: 8.469 ms
Execution Time: 19.298 ms
```

## Q3 · host-plant patches within 50 m of a section (`report_specialist_host_plants`)

`plant_resource_observation` GiST `plant_resource_observation_geometry_3dc366e0_id`; the condition is the `&&` with `ST_Expand(section, 60 m in degrees)` (50 m x 1.2 over `111320 * cos(la...

Planner's choice:

```
Nested Loop Left Join (actual rows=26 loops=1)
  Join Filter: ((sy_1.section_id = sy.section_id) AND (sy_1.year = sy.year))
  Rows Removed by Join Filter: 314
  CTE specialists
    ->  GroupAggregate (actual rows=19 loops=1)
          Group Key: thp_1.taxon_id
          Filter: (count(DISTINCT (split_part((pt.scientific_name)::text, ' '::text, 1))) = 1)
          Rows Removed by Filter: 10
          ->  Sort (actual rows=47 loops=1)
                Sort Key: thp_1.taxon_id, (split_part((pt.scientific_name)::text, ' '::text, 1))
                Sort Method: quicksort  Memory: 27kB
                ->  Hash Join (actual rows=47 loops=1)
                      Hash Cond: (thp_1.plant_taxon_id = pt.id)
                      ->  Seq Scan on taxon_host_plant thp_1 (actual rows=47 loops=1)
                      ->  Hash (actual rows=78 loops=1)
                            Buckets: 1024  Batches: 1  Memory Usage: 13kB
                            ->  Seq Scan on plant_taxon pt (actual rows=78 loops=1)
  CTE vv
    ->  Nested Loop (actual rows=164 loops=1)
          ->  Nested Loop (actual rows=164 loops=1)
                ->  Nested Loop (actual rows=164 loops=1)
                      ->  Hash Join (actual rows=324 loops=1)
                            Hash Cond: (v.project_id = p.project_id)
                            ->  Seq Scan on survey_visit v (actual rows=324 loops=1)
                                  Filter: (deleted_at IS NULL)
                                  Rows Removed by Filter: 382
                            ->  Hash (actual rows=13 loops=1)
                                  Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                  ->  Seq Scan on project_protocol p (actual rows=13 loops=1)
                      ->  Subquery Scan on weather (actual rows=1 loops=324)
                            Filter: (cardinality(array_remove(ARRAY[CASE WHEN ((v.status)::text = 'cancelled'::text) THEN 'cancelled'::text WHEN ((v.status)::text <> ALL ('{completed,sync...
                            Rows Removed by Filter: 0
                            ->  Aggregate (actual rows=1 loops=324)
                                  ->  Values Scan on "*VALUES*" (actual rows=2 loops=324)
                                        Filter: ((column1 IS NOT NULL) AND (column2 IS NOT NULL) AND (column3 IS NOT NULL))
                                        Rows Removed by Filter: 0
                ->  Index Scan using survey_visit_pkey on survey_visit sv (actual rows=1 loops=164)
                      Index Cond: (id = v.id)
                      Filter: (deleted_at IS NULL)
          ->  Index Scan using project_protocol_project_id_key on project_protocol pp_1 (actual rows=1 loops=164)
                Index Cond: (project_id = sv.project_id)
  CTE sec_year
    ->  GroupAggregate (actual rows=156 loops=1)
          Group Key: s_1.id, t.project_id, t.code, vv_1.year
          ->  Sort (actual rows=1071 loops=1)
                Sort Key: s_1.id, t.project_id, t.code, vv_1.year, vv_1.id
                Sort Method: quicksort  Memory: 230kB
                ->  Nested Loop (actual rows=1071 loops=1)
                      ->  Nested Loop (actual rows=164 loops=1)
                            ->  CTE Scan on vv vv_1 (actual rows=164 loops=1)
                            ->  Index Scan using transect_pkey on transect t (actual rows=1 loops=164)
                                  Index Cond: (id = vv_1.transect_id)
                      ->  Index Scan using transect_section_transect_id_eaa5c16f on transect_section s_1 (actual rows=7 loops=164)
                            Index Cond: (transect_id = t.id)
                            Filter: (deleted_at IS NULL)
  ->  Merge Left Join (actual rows=26 loops=1)
        Merge Cond: ((sy.section_id = o.transect_section_id) AND (sy.year = vv.year))
        ->  Sort (actual rows=26 loops=1)
              Sort Key: sy.section_id, sy.year
              Sort Method: quicksort  Memory: 27kB
              ->  CTE Scan on sec_year sy (actual rows=26 loops=1)
                    Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                    Rows Removed by Filter: 130
        ->  GroupAggregate (actual rows=103 loops=1)
              Group Key: o.transect_section_id, vv.year
              ->  Sort (actual rows=303 loops=1)
                    Sort Key: o.transect_section_id, vv.year, (COALESCE(o.validated_taxon_id, o.taxon_id))
                    Sort Method: quicksort  Memory: 46kB
                    ->  Hash Semi Join (actual rows=309 loops=1)
                          Hash Cond: (COALESCE(o.validated_taxon_id, o.taxon_id) = specialists.taxon_id)
                          ->  Nested Loop (actual rows=2385 loops=1)
                                ->  CTE Scan on vv (actual rows=164 loops=1)
                                ->  Bitmap Heap Scan on butterfly_observation o (actual rows=15 loops=164)
                                      Recheck Cond: (survey_visit_id = vv.id)
                                      Filter: ((deleted_at IS NULL) AND (transect_section_id IS NOT NULL) AND ((source)::text = 'transect'::text))
                                      Rows Removed by Filter: 0
                                      Heap Blocks: exact=268
                                      ->  Bitmap Index Scan on butterfly_observation_survey_visit_id_2790ba7f (actual rows=15 loops=164)
                                            Index Cond: (survey_visit_id = vv.id)
                          ->  Hash (actual rows=19 loops=1)
                                Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                ->  CTE Scan on specialists (actual rows=19 loops=1)
  ->  GroupAggregate (actual rows=13 loops=26)
        Group Key: sy_1.section_id, sy_1.year
        ->  Incremental Sort (actual rows=23 loops=26)
              Sort Key: sy_1.section_id, sy_1.year
              Presorted Key: sy_1.section_id
              Full-sort Groups: 26  Sort Method: quicksort  Average Memory: 27kB  Peak Memory: 27kB
              ->  Nested Loop Left Join (actual rows=32 loops=26)
                    Filter: ((pr.survey_visit_id IS NULL) OR ((pv.deleted_at IS NULL) AND ((pv.status)::text <> 'cancelled'::text)))
                    ->  Nested Loop (actual rows=32 loops=26)
                          Join Filter: (pr.plant_taxon_id = thp.plant_taxon_id)
                          Rows Removed by Join Filter: 640
                          ->  Nested Loop (actual rows=61 loops=26)
                                Join Filter: ((pp.project_id = sy_1.project_id) AND ((EXTRACT(year FROM (pr.observed_at AT TIME ZONE pp.time_zone)))::integer = sy_1.year))
                                ->  Nested Loop (actual rows=61 loops=26)
                                      ->  CTE Scan on sec_year sy_1 (actual rows=156 loops=26)
                                      ->  Index Scan using plant_resource_observation_geometry_3dc366e0_id on plant_resource_observation pr (actual rows=0 loops=4056)
                                            Index Cond: (geometry && st_expand(sy_1.geometry, ('60'::double precision / ('111320'::double precision * cos(radians(st_y(st_centroid(sy_1.geo...
                                            Filter: ((deleted_at IS NULL) AND ((resource_type)::text = 'larval_host'::text) AND (project_id = sy_1.project_id) AND st_dwithin((geometry)::g...
                                            Rows Removed by Filter: 7
                                ->  Index Scan using project_protocol_project_id_key on project_protocol pp (actual rows=1 loops=1586)
                                      Index Cond: (project_id = pr.project_id)
                          ->  Unique (actual rows=11 loops=1586)
                                ->  Sort (actual rows=19 loops=1586)
                                      Sort Key: thp.plant_taxon_id
                                      Sort Method: quicksort  Memory: 25kB
                                      ->  Hash Join (actual rows=22 loops=1)
                                            Hash Cond: (thp.taxon_id = s.taxon_id)
                                            ->  Seq Scan on taxon_host_plant thp (actual rows=47 loops=1)
                                            ->  Hash (actual rows=19 loops=1)
                                                  Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                                  ->  CTE Scan on specialists s (actual rows=19 loops=1)
                    ->  Index Scan using survey_visit_pkey on survey_visit pv (actual rows=1 loops=832)
                          Index Cond: (id = pr.survey_visit_id)
Planning Time: 9.175 ms
Execution Time: 47.720 ms
```

With `enable_seqscan = off`:

```
Nested Loop Left Join (actual rows=26 loops=1)
  Join Filter: ((sy_1.section_id = sy.section_id) AND (sy_1.year = sy.year))
  Rows Removed by Join Filter: 314
  CTE specialists
    ->  GroupAggregate (actual rows=19 loops=1)
          Group Key: thp_1.taxon_id
          Filter: (count(DISTINCT (split_part((pt.scientific_name)::text, ' '::text, 1))) = 1)
          Rows Removed by Filter: 10
          ->  Incremental Sort (actual rows=47 loops=1)
                Sort Key: thp_1.taxon_id, (split_part((pt.scientific_name)::text, ' '::text, 1))
                Presorted Key: thp_1.taxon_id
                Full-sort Groups: 2  Sort Method: quicksort  Average Memory: 26kB  Peak Memory: 26kB
                ->  Nested Loop (actual rows=47 loops=1)
                      ->  Index Scan using taxon_host_plant_taxon_id_d4edb746 on taxon_host_plant thp_1 (actual rows=47 loops=1)
                      ->  Memoize (actual rows=1 loops=47)
                            Cache Key: thp_1.plant_taxon_id
                            Cache Mode: logical
                            Hits: 15  Misses: 32  Evictions: 0  Overflows: 0  Memory Usage: 5kB
                            ->  Index Scan using plant_taxon_pkey on plant_taxon pt (actual rows=1 loops=32)
                                  Index Cond: (id = thp_1.plant_taxon_id)
  CTE vv
    ->  Nested Loop (actual rows=164 loops=1)
          ->  Nested Loop (actual rows=164 loops=1)
                ->  Nested Loop (actual rows=164 loops=1)
                      ->  Nested Loop (actual rows=324 loops=1)
                            ->  Index Scan using survey_visit_project_id_cfcf17f2 on survey_visit v (actual rows=324 loops=1)
                                  Filter: (deleted_at IS NULL)
                                  Rows Removed by Filter: 382
                            ->  Memoize (actual rows=1 loops=324)
                                  Cache Key: v.project_id
                                  Cache Mode: logical
                                  Hits: 316  Misses: 8  Evictions: 0  Overflows: 0  Memory Usage: 2kB
                                  ->  Index Scan using project_protocol_project_id_key on project_protocol p (actual rows=1 loops=8)
                                        Index Cond: (project_id = v.project_id)
                      ->  Subquery Scan on weather (actual rows=1 loops=324)
                            Filter: (cardinality(array_remove(ARRAY[CASE WHEN ((v.status)::text = 'cancelled'::text) THEN 'cancelled'::text WHEN ((v.status)::text <> ALL ('{completed,sync...
                            Rows Removed by Filter: 0
                            ->  Aggregate (actual rows=1 loops=324)
                                  ->  Values Scan on "*VALUES*" (actual rows=2 loops=324)
                                        Filter: ((column1 IS NOT NULL) AND (column2 IS NOT NULL) AND (column3 IS NOT NULL))
                                        Rows Removed by Filter: 0
                ->  Index Scan using survey_visit_pkey on survey_visit sv (actual rows=1 loops=164)
                      Index Cond: (id = v.id)
                      Filter: (deleted_at IS NULL)
          ->  Index Scan using project_protocol_project_id_key on project_protocol pp_1 (actual rows=1 loops=164)
                Index Cond: (project_id = sv.project_id)
  CTE sec_year
    ->  GroupAggregate (actual rows=156 loops=1)
          Group Key: s_1.id, t.project_id, t.code, vv_1.year
          ->  Sort (actual rows=1071 loops=1)
                Sort Key: s_1.id, t.project_id, t.code, vv_1.year, vv_1.id
                Sort Method: quicksort  Memory: 230kB
                ->  Nested Loop (actual rows=1071 loops=1)
                      ->  Nested Loop (actual rows=164 loops=1)
                            ->  CTE Scan on vv vv_1 (actual rows=164 loops=1)
                            ->  Index Scan using transect_pkey on transect t (actual rows=1 loops=164)
                                  Index Cond: (id = vv_1.transect_id)
                      ->  Index Scan using transect_section_transect_id_eaa5c16f on transect_section s_1 (actual rows=7 loops=164)
                            Index Cond: (transect_id = t.id)
                            Filter: (deleted_at IS NULL)
  ->  Merge Left Join (actual rows=26 loops=1)
        Merge Cond: ((sy.section_id = o.transect_section_id) AND (sy.year = vv.year))
        ->  Sort (actual rows=26 loops=1)
              Sort Key: sy.section_id, sy.year
              Sort Method: quicksort  Memory: 27kB
              ->  CTE Scan on sec_year sy (actual rows=26 loops=1)
                    Filter: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                    Rows Removed by Filter: 130
        ->  GroupAggregate (actual rows=103 loops=1)
              Group Key: o.transect_section_id, vv.year
              ->  Sort (actual rows=303 loops=1)
                    Sort Key: o.transect_section_id, vv.year, (COALESCE(o.validated_taxon_id, o.taxon_id))
                    Sort Method: quicksort  Memory: 46kB
                    ->  Hash Semi Join (actual rows=309 loops=1)
                          Hash Cond: (COALESCE(o.validated_taxon_id, o.taxon_id) = specialists.taxon_id)
                          ->  Nested Loop (actual rows=2385 loops=1)
                                ->  CTE Scan on vv (actual rows=164 loops=1)
                                ->  Bitmap Heap Scan on butterfly_observation o (actual rows=15 loops=164)
                                      Recheck Cond: (survey_visit_id = vv.id)
                                      Filter: ((deleted_at IS NULL) AND (transect_section_id IS NOT NULL) AND ((source)::text = 'transect'::text))
                                      Rows Removed by Filter: 0
                                      Heap Blocks: exact=268
                                      ->  Bitmap Index Scan on butterfly_observation_survey_visit_id_2790ba7f (actual rows=15 loops=164)
                                            Index Cond: (survey_visit_id = vv.id)
                          ->  Hash (actual rows=19 loops=1)
                                Buckets: 1024  Batches: 1  Memory Usage: 9kB
                                ->  CTE Scan on specialists (actual rows=19 loops=1)
  ->  GroupAggregate (actual rows=13 loops=26)
        Group Key: sy_1.section_id, sy_1.year
        ->  Incremental Sort (actual rows=23 loops=26)
              Sort Key: sy_1.section_id, sy_1.year
              Presorted Key: sy_1.section_id
              Full-sort Groups: 26  Sort Method: quicksort  Average Memory: 27kB  Peak Memory: 27kB
              ->  Nested Loop Left Join (actual rows=32 loops=26)
                    Filter: ((pr.survey_visit_id IS NULL) OR ((pv.deleted_at IS NULL) AND ((pv.status)::text <> 'cancelled'::text)))
                    ->  Nested Loop (actual rows=32 loops=26)
                          Join Filter: (pr.plant_taxon_id = thp.plant_taxon_id)
                          Rows Removed by Join Filter: 640
                          ->  Nested Loop (actual rows=61 loops=26)
                                Join Filter: ((pp.project_id = sy_1.project_id) AND ((EXTRACT(year FROM (pr.observed_at AT TIME ZONE pp.time_zone)))::integer = sy_1.year))
                                ->  Nested Loop (actual rows=61 loops=26)
                                      ->  CTE Scan on sec_year sy_1 (actual rows=156 loops=26)
                                      ->  Index Scan using plant_resource_observation_geometry_3dc366e0_id on plant_resource_observation pr (actual rows=0 loops=4056)
                                            Index Cond: (geometry && st_expand(sy_1.geometry, ('60'::double precision / ('111320'::double precision * cos(radians(st_y(st_centroid(sy_1.geo...
                                            Filter: ((deleted_at IS NULL) AND ((resource_type)::text = 'larval_host'::text) AND (project_id = sy_1.project_id) AND st_dwithin((geometry)::g...
                                            Rows Removed by Filter: 7
                                ->  Index Scan using project_protocol_project_id_key on project_protocol pp (actual rows=1 loops=1586)
                                      Index Cond: (project_id = pr.project_id)
                          ->  Unique (actual rows=11 loops=1586)
                                ->  Sort (actual rows=19 loops=1586)
                                      Sort Key: thp.plant_taxon_id
                                      Sort Method: quicksort  Memory: 25kB
                                      ->  Nested Loop (actual rows=22 loops=1)
                                            ->  CTE Scan on specialists s (actual rows=19 loops=1)
                                            ->  Bitmap Heap Scan on taxon_host_plant thp (actual rows=1 loops=19)
                                                  Recheck Cond: (taxon_id = s.taxon_id)
                                                  Heap Blocks: exact=19
                                                  ->  Bitmap Index Scan on taxon_host_plant_taxon_id_d4edb746 (actual rows=1 loops=19)
                                                        Index Cond: (taxon_id = s.taxon_id)
                    ->  Index Scan using survey_visit_pkey on survey_visit pv (actual rows=1 loops=832)
                          Index Cond: (id = pr.survey_visit_id)
Planning Time: 10.515 ms
Execution Time: 50.334 ms
```

## Q4 · reproductive record in polygon (`report_reproductive_microhabitat`)

`butterfly_observation` GiST `butterfly_observation_geometry_07d52f9a_id` is the inner side (`geometry && polygon`). The 26 polygons are read with a sequential scan as the outer relation,...

Planner's choice:

```
Nested Loop (actual rows=6 loops=1)
  Join Filter: (ht.id = hf.habitat_type_id)
  Rows Removed by Join Filter: 18
  ->  WindowAgg (actual rows=6 loops=1)
        ->  Nested Loop Left Join (actual rows=6 loops=1)
              ->  Nested Loop Left Join (actual rows=6 loops=1)
                    Join Filter: (hf_2.habitat_type_id = hf.habitat_type_id)
                    Rows Removed by Join Filter: 25
                    ->  GroupAggregate (actual rows=6 loops=1)
                          Group Key: hf.habitat_type_id
                          ->  Sort (actual rows=26 loops=1)
                                Sort Key: hf.habitat_type_id
                                Sort Method: quicksort  Memory: 29kB
                                ->  Nested Loop (actual rows=26 loops=1)
                                      ->  Seq Scan on habitat_feature hf (actual rows=26 loops=1)
                                            Filter: ((deleted_at IS NULL) AND (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid) AND (st_geometrytype(geometry) = ANY ('{ST_Polygo...
                                            Rows Removed by Filter: 137
                                      ->  GroupAggregate (actual rows=1 loops=26)
                                            ->  Seq Scan on habitat_feature hf_1 (actual rows=26 loops=26)
                                                  Filter: ((deleted_at IS NULL) AND (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid) AND (st_geometrytype(geometry) = ANY ('{ST_...
                                                  Rows Removed by Filter: 137
                    ->  GroupAggregate (actual rows=5 loops=6)
                          Group Key: hf_2.habitat_type_id
                          ->  Sort (actual rows=25 loops=6)
                                Sort Key: hf_2.habitat_type_id, o.id
                                Sort Method: quicksort  Memory: 26kB
                                ->  Nested Loop Left Join (actual rows=25 loops=1)
                                      Filter: ((o.survey_visit_id IS NULL) OR ((sv.deleted_at IS NULL) AND ((sv.status)::text <> 'cancelled'::text)))
                                      ->  Nested Loop (actual rows=25 loops=1)
                                            ->  Seq Scan on habitat_feature hf_2 (actual rows=26 loops=1)
                                                  Filter: ((deleted_at IS NULL) AND (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid) AND (st_geometrytype(geometry) = ANY ('{ST_...
                                                  Rows Removed by Filter: 137
                                            ->  Index Scan using butterfly_observation_geometry_07d52f9a_id on butterfly_observation o (actual rows=1 loops=26)
                                                  Index Cond: (geometry && hf_2.geometry)
                                                  Filter: ((deleted_at IS NULL) AND (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid) AND ((behaviour && '{courtship,mating,ovipo...
                                                  Rows Removed by Filter: 82
                                      ->  Index Scan using survey_visit_pkey on survey_visit sv (actual rows=1 loops=25)
                                            Index Cond: (id = o.survey_visit_id)
              ->  GroupAggregate (actual rows=1 loops=6)
                    ->  Sort (actual rows=25 loops=6)
                          Sort Key: o_1.id
                          Sort Method: quicksort  Memory: 26kB
                          ->  Nested Loop Left Join (actual rows=25 loops=1)
                                Filter: ((o_1.survey_visit_id IS NULL) OR ((sv_1.deleted_at IS NULL) AND ((sv_1.status)::text <> 'cancelled'::text)))
                                ->  Nested Loop (actual rows=25 loops=1)
                                      ->  Seq Scan on habitat_feature hf_3 (actual rows=26 loops=1)
                                            Filter: ((deleted_at IS NULL) AND (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid) AND (st_geometrytype(geometry) = ANY ('{ST_Polygo...
                                            Rows Removed by Filter: 137
                                      ->  Index Scan using butterfly_observation_geometry_07d52f9a_id on butterfly_observation o_1 (actual rows=1 loops=26)
                                            Index Cond: (geometry && hf_3.geometry)
                                            Filter: ((deleted_at IS NULL) AND (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid) AND ((behaviour && '{courtship,mating,oviposition...
                                            Rows Removed by Filter: 82
                                ->  Index Scan using survey_visit_pkey on survey_visit sv_1 (actual rows=1 loops=25)
                                      Index Cond: (id = o_1.survey_visit_id)
  ->  Seq Scan on habitat_type ht (actual rows=4 loops=6)
Planning Time: 12.427 ms
Execution Time: 11.040 ms
```

With `enable_seqscan = off`:

```
Nested Loop (actual rows=6 loops=1)
  ->  WindowAgg (actual rows=6 loops=1)
        ->  Nested Loop Left Join (actual rows=6 loops=1)
              ->  Nested Loop Left Join (actual rows=6 loops=1)
                    Join Filter: (hf_2.habitat_type_id = hf.habitat_type_id)
                    Rows Removed by Join Filter: 25
                    ->  GroupAggregate (actual rows=6 loops=1)
                          Group Key: hf.habitat_type_id
                          ->  Sort (actual rows=26 loops=1)
                                Sort Key: hf.habitat_type_id
                                Sort Method: quicksort  Memory: 29kB
                                ->  Nested Loop (actual rows=26 loops=1)
                                      ->  Bitmap Heap Scan on habitat_feature hf (actual rows=26 loops=1)
                                            Recheck Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                            Filter: ((deleted_at IS NULL) AND (st_geometrytype(geometry) = ANY ('{ST_Polygon,ST_MultiPolygon}'::text[])))
                                            Heap Blocks: exact=2
                                            ->  Bitmap Index Scan on habitat_feat_proj_idx (actual rows=26 loops=1)
                                                  Index Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                      ->  GroupAggregate (actual rows=1 loops=26)
                                            ->  Bitmap Heap Scan on habitat_feature hf_1 (actual rows=26 loops=26)
                                                  Recheck Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                                  Filter: ((deleted_at IS NULL) AND (st_geometrytype(geometry) = ANY ('{ST_Polygon,ST_MultiPolygon}'::text[])))
                                                  Heap Blocks: exact=52
                                                  ->  Bitmap Index Scan on habitat_feat_proj_idx (actual rows=26 loops=26)
                                                        Index Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                    ->  GroupAggregate (actual rows=5 loops=6)
                          Group Key: hf_2.habitat_type_id
                          ->  Sort (actual rows=25 loops=6)
                                Sort Key: hf_2.habitat_type_id, o.id
                                Sort Method: quicksort  Memory: 26kB
                                ->  Nested Loop Left Join (actual rows=25 loops=1)
                                      Filter: ((o.survey_visit_id IS NULL) OR ((sv.deleted_at IS NULL) AND ((sv.status)::text <> 'cancelled'::text)))
                                      ->  Nested Loop (actual rows=25 loops=1)
                                            ->  Bitmap Heap Scan on habitat_feature hf_2 (actual rows=26 loops=1)
                                                  Recheck Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                                  Filter: ((deleted_at IS NULL) AND (st_geometrytype(geometry) = ANY ('{ST_Polygon,ST_MultiPolygon}'::text[])))
                                                  Heap Blocks: exact=2
                                                  ->  Bitmap Index Scan on habitat_feat_proj_idx (actual rows=26 loops=1)
                                                        Index Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                            ->  Index Scan using butterfly_observation_geometry_07d52f9a_id on butterfly_observation o (actual rows=1 loops=26)
                                                  Index Cond: (geometry && hf_2.geometry)
                                                  Filter: ((deleted_at IS NULL) AND (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid) AND ((behaviour && '{courtship,mating,ovipo...
                                                  Rows Removed by Filter: 82
                                      ->  Index Scan using survey_visit_pkey on survey_visit sv (actual rows=1 loops=25)
                                            Index Cond: (id = o.survey_visit_id)
              ->  GroupAggregate (actual rows=1 loops=6)
                    ->  Sort (actual rows=25 loops=6)
                          Sort Key: o_1.id
                          Sort Method: quicksort  Memory: 26kB
                          ->  Nested Loop Left Join (actual rows=25 loops=1)
                                Filter: ((o_1.survey_visit_id IS NULL) OR ((sv_1.deleted_at IS NULL) AND ((sv_1.status)::text <> 'cancelled'::text)))
                                ->  Nested Loop (actual rows=25 loops=1)
                                      ->  Bitmap Heap Scan on habitat_feature hf_3 (actual rows=26 loops=1)
                                            Recheck Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                            Filter: ((deleted_at IS NULL) AND (st_geometrytype(geometry) = ANY ('{ST_Polygon,ST_MultiPolygon}'::text[])))
                                            Heap Blocks: exact=2
                                            ->  Bitmap Index Scan on habitat_feat_proj_idx (actual rows=26 loops=1)
                                                  Index Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                      ->  Index Scan using butterfly_observation_geometry_07d52f9a_id on butterfly_observation o_1 (actual rows=1 loops=26)
                                            Index Cond: (geometry && hf_3.geometry)
                                            Filter: ((deleted_at IS NULL) AND (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid) AND ((behaviour && '{courtship,mating,oviposition...
                                            Rows Removed by Filter: 82
                                ->  Index Scan using survey_visit_pkey on survey_visit sv_1 (actual rows=1 loops=25)
                                      Index Cond: (id = o_1.survey_visit_id)
  ->  Index Scan using habitat_type_pkey on habitat_type ht (actual rows=1 loops=6)
        Index Cond: (id = hf.habitat_type_id)
Planning Time: 10.437 ms
Execution Time: 7.479 ms
```

## Q6 · observations in a hexagon (`geo.observation_hexgrid`, one project)

`butterfly_observation` GiST `butterfly_observation_geometry_07d52f9a_id` (`geometry && ST_Transform(hex, 4326)`), 225 hexagon probes. Natural plan: yes.

Planner's choice:

```
Subquery Scan on observation_hexgrid (actual rows=40 loops=1)
  ->  GroupAggregate (actual rows=40 loops=1)
        Group Key: p.name, g.i, g.j, g.geom
        ->  Sort (actual rows=571 loops=1)
              Sort Key: p.name, g.i, g.j, g.geom, (COALESCE(o.validated_taxon_id, o.taxon_id))
              Sort Method: quicksort  Memory: 197kB
              ->  Nested Loop Left Join (actual rows=571 loops=1)
                    Filter: ((o.survey_visit_id IS NULL) OR ((sv.deleted_at IS NULL) AND ((sv.status)::text <> 'cancelled'::text)))
                    ->  Nested Loop (actual rows=571 loops=1)
                          ->  GroupAggregate (actual rows=1 loops=1)
                                Group Key: (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ((st_extent(o_2.geometry))::geometry)))) >= '0'::double precision) THEN 32600 ELSE 32700 END + (...
                                ->  Sort (actual rows=571 loops=1)
                                      Sort Key: (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ((st_extent(o_2.geometry))::geometry)))) >= '0'::double precision) THEN 32600 ELSE 32700 EN...
                                      Sort Method: quicksort  Memory: 533kB
                                      ->  Nested Loop (actual rows=571 loops=1)
                                            ->  Nested Loop (actual rows=1 loops=1)
                                                  ->  Seq Scan on project p (actual rows=1 loops=1)
                                                        Filter: ((deleted_at IS NULL) AND (id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid))
                                                        Rows Removed by Filter: 12
                                                  ->  GroupAggregate (actual rows=1 loops=1)
                                                        ->  Bitmap Heap Scan on butterfly_observation o_2 (actual rows=571 loops=1)
                                                              Recheck Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                                              Filter: (deleted_at IS NULL)
                                                              Heap Blocks: exact=25
                                                              ->  Bitmap Index Scan on butterfly_observation_project_id_665a935f (actual rows=571 loops=1)
                                                                    Index Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                            ->  Bitmap Heap Scan on butterfly_observation o_1 (actual rows=571 loops=1)
                                                  Recheck Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                                  Filter: (deleted_at IS NULL)
                                                  Heap Blocks: exact=25
                                                  ->  Bitmap Index Scan on butterfly_observation_project_id_665a935f (actual rows=571 loops=1)
                                                        Index Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                          ->  Nested Loop (actual rows=571 loops=1)
                                Join Filter: st_intersects(g.geom, st_transform(o.geometry, (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ((st_extent(o_2.geometry))::geometry)))) >= '0'...
                                Rows Removed by Join Filter: 211
                                ->  Function Scan on st_hexagongrid g (actual rows=225 loops=1)
                                ->  Index Scan using butterfly_observation_geometry_07d52f9a_id on butterfly_observation o (actual rows=3 loops=225)
                                      Index Cond: (geometry && st_transform(g.geom, 4326))
                                      Filter: ((deleted_at IS NULL) AND (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid))
                                      Rows Removed by Filter: 12
                    ->  Index Scan using survey_visit_pkey on survey_visit sv (actual rows=1 loops=571)
                          Index Cond: (id = o.survey_visit_id)
Planning Time: 9.009 ms
Execution Time: 10.725 ms
```

With `enable_seqscan = off`:

```
Subquery Scan on observation_hexgrid (actual rows=40 loops=1)
  ->  GroupAggregate (actual rows=40 loops=1)
        Group Key: p.name, g.i, g.j, g.geom
        ->  Sort (actual rows=571 loops=1)
              Sort Key: p.name, g.i, g.j, g.geom, (COALESCE(o.validated_taxon_id, o.taxon_id))
              Sort Method: quicksort  Memory: 197kB
              ->  Nested Loop Left Join (actual rows=571 loops=1)
                    Filter: ((o.survey_visit_id IS NULL) OR ((sv.deleted_at IS NULL) AND ((sv.status)::text <> 'cancelled'::text)))
                    ->  Nested Loop (actual rows=571 loops=1)
                          ->  GroupAggregate (actual rows=1 loops=1)
                                Group Key: (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ((st_extent(o_2.geometry))::geometry)))) >= '0'::double precision) THEN 32600 ELSE 32700 END + (...
                                ->  Sort (actual rows=571 loops=1)
                                      Sort Key: (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ((st_extent(o_2.geometry))::geometry)))) >= '0'::double precision) THEN 32600 ELSE 32700 EN...
                                      Sort Method: quicksort  Memory: 533kB
                                      ->  Nested Loop (actual rows=571 loops=1)
                                            ->  Nested Loop (actual rows=1 loops=1)
                                                  ->  Index Scan using project_pkey on project p (actual rows=1 loops=1)
                                                        Index Cond: (id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                                        Filter: (deleted_at IS NULL)
                                                  ->  GroupAggregate (actual rows=1 loops=1)
                                                        ->  Bitmap Heap Scan on butterfly_observation o_2 (actual rows=571 loops=1)
                                                              Recheck Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                                              Filter: (deleted_at IS NULL)
                                                              Heap Blocks: exact=25
                                                              ->  Bitmap Index Scan on butterfly_observation_project_id_665a935f (actual rows=571 loops=1)
                                                                    Index Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                            ->  Bitmap Heap Scan on butterfly_observation o_1 (actual rows=571 loops=1)
                                                  Recheck Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                                                  Filter: (deleted_at IS NULL)
                                                  Heap Blocks: exact=25
                                                  ->  Bitmap Index Scan on butterfly_observation_project_id_665a935f (actual rows=571 loops=1)
                                                        Index Cond: (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid)
                          ->  Nested Loop (actual rows=571 loops=1)
                                Join Filter: st_intersects(g.geom, st_transform(o.geometry, (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ((st_extent(o_2.geometry))::geometry)))) >= '0'...
                                Rows Removed by Join Filter: 211
                                ->  Function Scan on st_hexagongrid g (actual rows=225 loops=1)
                                ->  Index Scan using butterfly_observation_geometry_07d52f9a_id on butterfly_observation o (actual rows=3 loops=225)
                                      Index Cond: (geometry && st_transform(g.geom, 4326))
                                      Filter: ((deleted_at IS NULL) AND (project_id = 'bfeed6a1-1c89-46e2-b994-894bf3e35b4f'::uuid))
                                      Rows Removed by Filter: 12
                    ->  Index Scan using survey_visit_pkey on survey_visit sv (actual rows=1 loops=571)
                          Index Cond: (id = o.survey_visit_id)
Planning Time: 6.197 ms
Execution Time: 10.654 ms
```

## Q6 · the OGC bbox filter on the whole view

pygeoapi's filter `ST_Intersects(ST_MakeEnvelope(...), geometry)` is applied **on top of** the view: the view is built in full first (all projects, 1380 hexagons), then filtered, so the b...

Planner's choice:

```
Subquery Scan on observation_hexgrid (actual rows=214 loops=1)
  ->  GroupAggregate (actual rows=214 loops=1)
        Group Key: p.id, p.name, g.i, g.j, g.geom
        ->  Incremental Sort (actual rows=2524 loops=1)
              Sort Key: p.id, p.name, g.i, g.j, g.geom, (COALESCE(o.validated_taxon_id, o.taxon_id))
              Presorted Key: p.id
              Full-sort Groups: 6  Sort Method: quicksort  Average Memory: 44kB  Peak Memory: 44kB
              Pre-sorted Groups: 6  Sort Method: quicksort  Average Memory: 167kB  Peak Memory: 173kB
              ->  Nested Loop Left Join (actual rows=2524 loops=1)
                    Filter: ((o.survey_visit_id IS NULL) OR ((sv.deleted_at IS NULL) AND ((sv.status)::text <> 'cancelled'::text)))
                    Rows Removed by Filter: 17
                    ->  Nested Loop (actual rows=2541 loops=1)
                          Join Filter: ((o.project_id = p.id) AND st_intersects(g.geom, st_transform(o.geometry, (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ext.box))) >= '0'::double ...
                          Rows Removed by Join Filter: 17522
                          ->  Nested Loop (actual rows=1380 loops=1)
                                ->  GroupAggregate (actual rows=8 loops=1)
                                      Group Key: p.id, (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ext.box))) >= '0'::double precision) THEN 32600 ELSE 32700 END + ((floor(((st_x(st_c...
                                      ->  Incremental Sort (actual rows=3978 loops=1)
                                            Sort Key: p.id, (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ext.box))) >= '0'::double precision) THEN 32600 ELSE 32700 END + ((floor(((st_x...
                                            Presorted Key: p.id
                                            Full-sort Groups: 8  Sort Method: quicksort  Average Memory: 82kB  Peak Memory: 82kB
                                            Pre-sorted Groups: 7  Sort Method: quicksort  Average Memory: 826kB  Peak Memory: 1293kB
                                            ->  Nested Loop (actual rows=3978 loops=1)
                                                  ->  Merge Join (actual rows=8 loops=1)
                                                        Merge Cond: (p.id = ext.project_id)
                                                        ->  Sort (actual rows=10 loops=1)
                                                              Sort Key: p.id
                                                              Sort Method: quicksort  Memory: 34kB
                                                              ->  Seq Scan on project p (actual rows=10 loops=1)
                                                                    Filter: (deleted_at IS NULL)
                                                                    Rows Removed by Filter: 3
                                                        ->  Sort (actual rows=8 loops=1)
                                                              Sort Key: ext.project_id
                                                              Sort Method: quicksort  Memory: 26kB
                                                              ->  Subquery Scan on ext (actual rows=8 loops=1)
                                                                    ->  HashAggregate (actual rows=8 loops=1)
                                                                          Group Key: o_2.project_id
                                                                          Batches: 1  Memory Usage: 24kB
                                                                          ->  Seq Scan on butterfly_observation o_2 (actual rows=3978 loops=1)
                                                                                Filter: (deleted_at IS NULL)
                                                                                Rows Removed by Filter: 209
                                                  ->  Bitmap Heap Scan on butterfly_observation o_1 (actual rows=497 loops=8)
                                                        Recheck Cond: (project_id = ext.project_id)
                                                        Filter: (deleted_at IS NULL)
                                                        Rows Removed by Filter: 26
                                                        Heap Blocks: exact=227
                                                        ->  Bitmap Index Scan on butterfly_observation_project_id_665a935f (actual rows=523 loops=8)
                                                              Index Cond: (project_id = ext.project_id)
                                ->  Function Scan on st_hexagongrid g (actual rows=172 loops=8)
                                      Filter: st_intersects('0103000020E61000000100000005000000CDCCCCCCCCCC3340CDCCCCCCCC8C4640CDCCCCCCCCCC33409A999999999946406666666666E633409A9999999999...
                                      Rows Removed by Filter: 110
                          ->  Index Scan using butterfly_observation_geometry_07d52f9a_id on butterfly_observation o (actual rows=15 loops=1380)
                                Index Cond: (geometry && st_transform(g.geom, 4326))
                                Filter: (deleted_at IS NULL)
                                Rows Removed by Filter: 0
                    ->  Index Scan using survey_visit_pkey on survey_visit sv (actual rows=1 loops=2541)
                          Index Cond: (id = o.survey_visit_id)
Planning Time: 6.309 ms
Execution Time: 80.187 ms
```

With `enable_seqscan = off`:

```
Subquery Scan on observation_hexgrid (actual rows=214 loops=1)
  ->  GroupAggregate (actual rows=214 loops=1)
        Group Key: p.id, p.name, g.i, g.j, g.geom
        ->  Incremental Sort (actual rows=2524 loops=1)
              Sort Key: p.id, p.name, g.i, g.j, g.geom, (COALESCE(o.validated_taxon_id, o.taxon_id))
              Presorted Key: p.id
              Full-sort Groups: 6  Sort Method: quicksort  Average Memory: 44kB  Peak Memory: 44kB
              Pre-sorted Groups: 6  Sort Method: quicksort  Average Memory: 167kB  Peak Memory: 173kB
              ->  Nested Loop Left Join (actual rows=2524 loops=1)
                    Filter: ((o.survey_visit_id IS NULL) OR ((sv.deleted_at IS NULL) AND ((sv.status)::text <> 'cancelled'::text)))
                    Rows Removed by Filter: 17
                    ->  Nested Loop (actual rows=2541 loops=1)
                          Join Filter: ((o.project_id = p.id) AND st_intersects(g.geom, st_transform(o.geometry, (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ((st_extent(o_2.geometry))...
                          Rows Removed by Join Filter: 17522
                          ->  Nested Loop (actual rows=1380 loops=1)
                                ->  GroupAggregate (actual rows=8 loops=1)
                                      Group Key: p.id, (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ((st_extent(o_2.geometry))::geometry)))) >= '0'::double precision) THEN 32600 ELSE 3...
                                      ->  Incremental Sort (actual rows=3978 loops=1)
                                            Sort Key: p.id, (((CASE WHEN (st_y(st_centroid(COALESCE(p.area, ((st_extent(o_2.geometry))::geometry)))) >= '0'::double precision) THEN 32600 E...
                                            Presorted Key: p.id
                                            Full-sort Groups: 8  Sort Method: quicksort  Average Memory: 82kB  Peak Memory: 82kB
                                            Pre-sorted Groups: 7  Sort Method: quicksort  Average Memory: 826kB  Peak Memory: 1293kB
                                            ->  Nested Loop (actual rows=3978 loops=1)
                                                  ->  Merge Join (actual rows=8 loops=1)
                                                        Merge Cond: (p.id = o_2.project_id)
                                                        ->  Index Scan using project_pkey on project p (actual rows=10 loops=1)
                                                              Filter: (deleted_at IS NULL)
                                                              Rows Removed by Filter: 3
                                                        ->  GroupAggregate (actual rows=8 loops=1)
                                                              Group Key: o_2.project_id
                                                              ->  Index Scan using butterfly_observation_project_id_665a935f on butterfly_observation o_2 (actual rows=3978 loops=1)
                                                                    Filter: (deleted_at IS NULL)
                                                                    Rows Removed by Filter: 209
                                                  ->  Bitmap Heap Scan on butterfly_observation o_1 (actual rows=497 loops=8)
                                                        Recheck Cond: (project_id = o_2.project_id)
                                                        Filter: (deleted_at IS NULL)
                                                        Rows Removed by Filter: 26
                                                        Heap Blocks: exact=227
                                                        ->  Bitmap Index Scan on butterfly_observation_project_id_665a935f (actual rows=523 loops=8)
                                                              Index Cond: (project_id = o_2.project_id)
                                ->  Function Scan on st_hexagongrid g (actual rows=172 loops=8)
                                      Filter: st_intersects('0103000020E61000000100000005000000CDCCCCCCCCCC3340CDCCCCCCCC8C4640CDCCCCCCCCCC33409A999999999946406666666666E633409A9999999999...
                                      Rows Removed by Filter: 110
                          ->  Index Scan using butterfly_observation_geometry_07d52f9a_id on butterfly_observation o (actual rows=15 loops=1380)
                                Index Cond: (geometry && st_transform(g.geom, 4326))
                                Filter: (deleted_at IS NULL)
                                Rows Removed by Filter: 0
                    ->  Index Scan using survey_visit_pkey on survey_visit sv (actual rows=1 loops=2541)
                          Index Cond: (id = o.survey_visit_id)
Planning Time: 6.456 ms
Execution Time: 78.618 ms
```
