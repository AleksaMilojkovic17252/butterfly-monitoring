#!/usr/bin/env bash
# Spatial index benchmark runner (T102; T096 reuses the method). See README.md.
#
#   evaluation/benchmarks/spatial/run.sh <scratch-db> <project-uuid> <out-dir>
#
# For every query in queries/ it measures configs A (GiST indexes of the query's tables dropped inside
# BEGIN ... ROLLBACK), B (as is) and, where files exist, C1 (NN.c1-setup.sql, then the plain query) and
# C2 (NN.c.sql, a rewritten query). Per config: 1 warm-up run, 10 timed runs of EXPLAIN (ANALYZE,
# TIMING OFF), median; then one EXPLAIN (ANALYZE, BUFFERS) saved to <out-dir>/plans/.
# Never runs on the dev database `butterfly`; every change is rolled back.
set -euo pipefail

[ $# -eq 3 ] || { echo "Usage: run.sh <scratch-db> <project-uuid> <out-dir>" >&2; exit 1; }
db=$1; project=$2; out=$3
case "$db" in butterfly|postgres|template0|template1)
  echo "Refusing to benchmark database '$db'. Create a scratch database (README.md)." >&2; exit 1;; esac
[[ $project =~ ^[0-9a-f-]{36}$ ]] || { echo "Not a uuid: $project" >&2; exit 1; }

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$here/../../.." && pwd)
cd "$root"
RUNS=10

psql_db() {
  docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml \
    exec -T db psql -U django_app -d "$db" -X -q -v ON_ERROR_STOP=1 -v "project=$project" "$@"
}

# Safety: the scratch database must hold the bench project, and psql must be on the database we named.
[ "$(psql_db -Atc 'select current_database()')" = "$db" ] || { echo "Wrong database" >&2; exit 1; }
[ "$(psql_db -Atc "select count(*) from project where id = '$project'" </dev/null)" = 1 ] || {
  echo "Project $project is not in $db" >&2; exit 1; }

mkdir -p "$out/plans" "$out/raw"
csv="$out/results.csv"
echo "query,config,median_ms,min_ms,max_ms,scan_nodes,shared_hit,shared_read" > "$csv"
sizes="$out/index-sizes.csv"

psql_db --csv -c "
  SELECT c.relname AS index, i.indrelid::regclass AS table,
         pg_relation_size(c.oid) AS bytes,
         CASE WHEN i.indrelid::regclass::text LIKE 'historical\_%' THEN 'historical' ELSE 'live' END AS kind
  FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid JOIN pg_am a ON a.oid = c.relam
  WHERE a.amname = 'gist' ORDER BY bytes DESC" </dev/null > "$sizes"

drop_gist_sql() { # <tables...>
  local list; list=$(printf "'%s'," "$@"); list=${list%,}
  cat <<SQL
DO \$\$ DECLARE r record; BEGIN
  FOR r IN SELECT i.indexrelid::regclass AS idx FROM pg_index i
           JOIN pg_class c ON c.oid = i.indexrelid JOIN pg_am a ON a.oid = c.relam
           WHERE a.amname = 'gist' AND i.indrelid = ANY (ARRAY[$list]::regclass[])
  LOOP RAISE NOTICE 'dropped %', r.idx; EXECUTE 'DROP INDEX ' || r.idx; END LOOP;
END \$\$;
SQL
}

# run_config <query-name> <config> <query-file> <setup-file-or-empty> <drop:0|1> <tables...>
run_config() {
  local name=$1 config=$2 qfile=$3 setup=$4 dropidx=$5; shift 5
  local tables=("$@") script="$out/raw/$name-$config.sql" log="$out/raw/$name-$config.out" i
  {
    echo "BEGIN;"
    cat "$here/prelude.sql"
    [ "$dropidx" = 1 ] && drop_gist_sql "${tables[@]}"
    if [ -n "$setup" ]; then
      cat "$setup"
      for t in "${tables[@]}"; do echo "ANALYZE $t;"; done
    fi
    echo "\\echo @@RUN"
    for ((i = 0; i <= RUNS; i++)); do
      echo "EXPLAIN (ANALYZE, TIMING OFF, SUMMARY ON)"; cat "$qfile"; echo
    done
    echo "\\echo @@PLAN"
    echo "EXPLAIN (ANALYZE, BUFFERS)"; cat "$qfile"; echo
    echo "\\echo @@SIZES"
    echo "\\pset format unaligned"; echo "\\pset tuples_only on"
    echo "SELECT c.relname || ',' || i.indrelid::regclass || ',' || pg_relation_size(c.oid) FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid WHERE c.relname LIKE 'bench\\_c%';"
    echo "ROLLBACK;"
  } > "$script"
  if ! psql_db < "$script" > "$log" 2> "$log.err"; then
    echo "  $name $config FAILED: $(head -c 300 "$log.err")" >&2
    echo "$name,$config,FAILED,,,,," >> "$csv"; return
  fi
  local times median min max
  times=$(awk '/^@@RUN/{r=1} /^@@PLAN/{r=0} r && /Execution Time:/{print $3}' "$log" | tail -n "$RUNS" | sort -n)
  if [ "$(echo "$times" | grep -c .)" -ne "$RUNS" ]; then
    echo "  $name $config FAILED: expected $RUNS timings, got $(echo "$times" | grep -c .)" >&2
    echo "$name,$config,FAILED,,,,," >> "$csv"; return
  fi
  median=$(echo "$times" | awk '{a[NR]=$1} END{print (NR%2)?a[(NR+1)/2]:(a[NR/2]+a[NR/2+1])/2}')
  min=$(echo "$times" | head -1); max=$(echo "$times" | tail -1)
  awk '/^@@PLAN/{p=1;next} /^@@SIZES/{p=0} p' "$log" > "$out/plans/$name-$config.txt"
  # scan nodes of the query's tables: a node names the table, or an index of one of the tables
  local pat idx tl
  tl=$(printf "'%s'," "${tables[@]}"); tl=${tl%,}
  idx=$(psql_db -Atc "SELECT string_agg(c.relname, '|') FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid
                      WHERE i.indrelid = ANY (ARRAY[$tl]::regclass[])" </dev/null)
  pat=$(IFS='|'; echo "${tables[*]}|bench_c")
  [ -n "$idx" ] && pat="$pat|$idx"
  local nodes
  nodes=$(grep -E "$pat" "$out/plans/$name-$config.txt" | awk '
    match($0, /(Seq Scan|Index Only Scan|Index Scan|Bitmap Index Scan)( Backward)? (using ([^ ]+) )?on ([^ ]+)/, m) {
      split(m[0], w, " "); type = m[1]; nm = (m[4] != "") ? m[4] : m[5]; print type ":" nm }' | sort | uniq -c |
    awk '{c=$1; $1=""; sub(/^ /,""); printf "%s%s%s", (NR>1?";":""), $0, (c>1?"x" c:"")}')
  local hit read
  hit=$(grep -m1 -o 'shared hit=[0-9]*' "$out/plans/$name-$config.txt" | cut -d= -f2 || true)
  read=$(grep -m1 -o 'read=[0-9]*' "$out/plans/$name-$config.txt" | cut -d= -f2 || true)
  echo "$name,$config,$median,$min,$max,\"$nodes\",${hit:-0},${read:-0}" >> "$csv"
  awk '/^@@SIZES/{s=1;next} s && NF{print $0 ",bench_c:" n}' n="$name-$config" FS='\n' "$log" | \
    awk -F, '{print $1 "," $2 "," $3 "," $4}' >> "$sizes"
  echo "  $name $config: median $median ms"
}

for qfile in "$here"/queries/[0-9]*.sql; do
  base=$(basename "$qfile" .sql)
  case "$base" in *.c|*.c1-setup|*.c2-setup) continue;; esac
  tables=($(sed -n 's/^-- tables: *//p' "$qfile"))
  [ ${#tables[@]} -gt 0 ] || { echo "No '-- tables:' header in $qfile" >&2; exit 1; }
  echo "$base"
  run_config "$base" A "$qfile" "" 1 "${tables[@]}"
  run_config "$base" B "$qfile" "" 0 "${tables[@]}"
  [ -f "$here/queries/$base.c1-setup.sql" ] &&
    run_config "$base" C1 "$qfile" "$here/queries/$base.c1-setup.sql" 0 "${tables[@]}"
  [ -f "$here/queries/$base.c.sql" ] &&
    run_config "$base" C2 "$here/queries/$base.c.sql" "" 0 "${tables[@]}"
done
echo "Wrote $csv and $sizes"
