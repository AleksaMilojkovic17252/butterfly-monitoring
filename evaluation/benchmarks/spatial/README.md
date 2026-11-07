# Spatial index benchmark (T102)

Measures whether the spatial queries of the app use their indexes, on the simulated season at two sizes.
Results and discussion: [evaluation/results/spatial-indexes.md](../../results/spatial-indexes.md). T096 (Phase 2)
reuses this method with new query files.

## What it measures

`run.sh` runs every file in `queries/` (named `NN-name.sql`; the header comment `-- tables:` lists the tables whose
GiST indexes config A drops) under these configurations. Each runs inside `BEGIN ... ROLLBACK`, so nothing is kept:

| Config | What |
|---|---|
| A | the GiST indexes of the query's tables dropped (the btree indexes stay) |
| B | as the app has it (GeoDjango's GiST on every geometry column) |
| C1 | B plus the index in `NN-name.c1-setup.sql` (for example an expression index on `geometry::geography`), original query |
| C2 | the rewritten query in `NN-name.c.sql` (for example a `&&` prefilter), B's indexes |

Per query and config: 1 warm-up run, then 10 timed runs of `EXPLAIN (ANALYZE, TIMING OFF)`; the median, minimum
and maximum of `Execution Time`; then one `EXPLAIN (ANALYZE, BUFFERS)` saved under `plans/`. Output in `<out-dir>`:
`results.csv` (query, config, median_ms, min_ms, max_ms, scan_nodes, shared_hit, shared_read),
`index-sizes.csv` (every GiST index, plus the C indexes), `plans/`, and `raw/` (the generated SQL and psql output).
The queries are set-based: each runs the code's statement once per row of the bench project, so a run takes
milliseconds. The bbox files use variables set by `prelude.sql` (the project area envelope, and 500 m around the first transect's start).

## Run it

It **never runs on the dev database `butterfly`**: `run.sh` refuses it. The `createdb` and `dropdb` commands below have no such guard: type the scratch name carefully.
Use a scratch database restored from a backup (T010). Fish syntax, from the repo root; the stack must be up.
`awk` must be GNU awk (the scan-node parsing uses `match()` with an array).

```fish
set DC docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml

# 1. A backup, once
scripts/backup.sh tmp/bench-backups
set B (ls -d tmp/bench-backups/butterfly-* | tail -1)

# 2. Per scale: scratch database s1 (8 visits per transect, the default) and s10 (80). No --clean, no --create:
#    the dev database is never named. Repeat the block with butterfly_bench_s10 and 80.
set DB butterfly_bench_s1
set VISITS 8
$DC exec -T db sh -c 'createdb -U "$POSTGRES_USER" -O django_app "$1"' sh $DB
cat $B/butterfly.dump | $DC exec -T db sh -c 'pg_restore -U "$POSTGRES_USER" -d "$1" --exit-on-error' sh $DB

# 3. Check that Django points at the scratch database. EVERY Django command below passes -e POSTGRES_DB=$DB.
$DC exec -e POSTGRES_DB=$DB django python manage.py shell -c "from django.db import connection; print(connection.settings_dict['NAME'])"

# 4. Copy the demo project (prints the new uuid), simulate the season, refresh statistics
$DC exec -T -e POSTGRES_DB=$DB -e COPY_NAME="T102 bench" django python manage.py shell < evaluation/benchmarks/spatial/clone_project.py
$DC exec -u (id -u) -e HOME=/tmp -e POSTGRES_DB=$DB django python manage.py simulate_season --project <uuid> --seed 42 --visits-per-transect $VISITS --direct
$DC exec -T db psql -U django_app -d $DB -c 'VACUUM ANALYZE'

# 5. Benchmark (about a minute at scale 1, two at scale 10)
evaluation/benchmarks/spatial/run.sh $DB <uuid> tmp/bench-out/s$VISITS

# 6. Clean up (check the name first: this drops a database)
$DC exec -T db sh -c 'dropdb -U "$POSTGRES_USER" "$1"' sh $DB
```

The runner needs the bench project to be in the database and uses its protocol and area. The simulator rewrites
`database/seeds/transects.gpx`; `git restore` it if it shows as changed.
