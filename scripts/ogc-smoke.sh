#!/usr/bin/env bash
# Smoke test of the OGC API - Features collections (T068). Reads only: the POST and DELETE at the end
# must be refused, and the DELETE names an id that does not exist.
#
#   scripts/ogc-smoke.sh [base-url]        default http://localhost:8080/ogc
#
# Prints PASS or FAIL per check and exits 1 if any failed. Expects the demo seed data
# (docs/setup/seed-data.md) and at least one observation. The next links come from server.url in the
# pygeoapi config, so the paging walk only reaches the laptop's own address.
set -uo pipefail

base=${1:-http://localhost:8080/ogc}
transects=$base/collections/transects/items
sections=$base/collections/transect-sections/items
obs=$base/collections/butterfly-observations/items
failed=0

pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; failed=1; }

# expect <label> <jq test> <url> [curl args]: GET as JSON and run the jq test on the body.
expect() {
  local label=$1 test=$2 url=$3 body
  shift 3
  if ! body=$(curl -fsS -G "$url" --data-urlencode f=json "$@"); then
    fail "$label (request failed)"
    return
  fi
  if jq -e "$test" <<<"$body" >/dev/null; then
    pass "$label"
  else
    fail "$label: $(jq -c '{numberMatched, numberReturned}' <<<"$body")"
  fi
}

# refused <label> <curl args>: the request must answer 4xx.
refused() {
  local label=$1 code
  shift
  code=$(curl -s -o /dev/null -w '%{http_code}' "$@")
  case $code in
    4*) pass "$label ($code)" ;;
    *) fail "$label ($code)" ;;
  esac
}

curl -fsS -o /dev/null "$base?f=json" || { echo "$base is not reachable"; exit 1; }

total_transects=$(curl -fsS -G "$transects" -d f=json -d limit=1 | jq .numberMatched)
first=$(curl -fsS -G "$obs" -d f=json -d limit=1 | jq -c '.features[0]')
first_id=$(jq -r .id <<<"$first")
day=$(jq -r '.properties.observed_at[:10]' <<<"$first")

echo "== Collections"
expect "the three collections, no skeleton" \
  '[.collections[].id] | (contains(["transects", "transect-sections", "butterfly-observations"]) and index("skeleton-pings") == null)' \
  "$base/collections"
expect "observations have spatial and temporal extents" \
  '.extent.spatial.bbox[0] != null and .extent.temporal.interval[0][0] != null' \
  "$base/collections/butterfly-observations"
expect "OpenAPI lists the observations" \
  '.paths | keys | any(contains("butterfly-observations"))' "$base/openapi"

echo "== bbox"
expect "bbox around Fruška Gora: some transects, not all" \
  ".numberMatched > 0 and .numberMatched < $total_transects" \
  "$transects" --data-urlencode 'bbox=19.8,45.1,19.9,45.2'

echo "== datetime"
expect "the ticket's June window: 200, and only June rows" \
  '.features | all(.properties.observed_at | . >= "2026-06-01" and . < "2026-07-01")' \
  "$obs" --data-urlencode 'datetime=2026-06-01T00:00:00Z/2026-06-30T23:59:59Z'
expect "the day of a real observation matches it" \
  ".numberMatched > 0 and (.features | all(.properties.observed_at | startswith(\"$day\")))" \
  "$obs" --data-urlencode "datetime=${day}T00:00:00Z/${day}T23:59:59Z"
expect "a one-second window inside the extent, with no data, matches nothing" \
  '.numberMatched == 0' \
  "$obs" --data-urlencode 'datetime=2026-03-01T00:00:00Z/2026-03-01T00:00:01Z'
refused "a window outside the collection's temporal extent is refused (D-079)" \
  -G "$obs" --data-urlencode f=json --data-urlencode 'datetime=2000-01-01T00:00:00Z/2000-12-31T23:59:59Z'

echo "== Property filter"
expect "effective_family=Lycaenidae returns only that family" \
  '.features | all(.properties.effective_family == "Lycaenidae")' \
  "$obs" --data-urlencode 'effective_family=Lycaenidae'
expect "a family nobody has matches nothing" \
  '.numberMatched == 0' \
  "$obs" --data-urlencode 'effective_family=NoSuchFamily'

echo "== CQL2 filter"
expect "filter=count>1 returns only count above 1" \
  '.features | all(.properties.count > 1)' \
  "$obs" --data-urlencode 'filter=count>1'
expect "a filter nothing passes matches nothing" \
  '.numberMatched == 0' \
  "$obs" --data-urlencode 'filter=count<0'

echo "== Paging"
expect "the ticket's limit=100&offset=100: has a prev link" \
  '[.links[].rel] | index("prev") != null' \
  "$obs" -d limit=100 -d offset=100
expect "limit=10&offset=10 on sections: 10 rows, prev and next" \
  '.numberReturned == 10 and ([.links[].rel] | (index("prev") != null and index("next") != null))' \
  "$sections" -d limit=10 -d offset=10

url="$sections?f=json&limit=10&sortby=id"
ids=""
matched=0
while [ -n "$url" ]; do
  body=$(curl -fsS "$url") || { fail "walk the next links (request failed)"; break; }
  matched=$(jq .numberMatched <<<"$body")
  ids+=$(jq -r '.features[].id' <<<"$body")$'\n'
  url=$(jq -r '[.links[] | select(.rel == "next")][0].href // empty' <<<"$body")
done
walked=$(grep . <<<"$ids" | sort -u | wc -l)
if [ "$walked" -eq "$matched" ]; then
  pass "walking the next links reaches all $matched sections once"
else
  fail "walking the next links: $walked unique ids of $matched"
fi

echo "== Formats and single item"
expect "single item by uuid" ".id == \"$first_id\"" "$obs/$first_id"
for format in json html; do
  type=$(curl -fsS -o /dev/null -w '%{content_type}' "$obs?f=$format&limit=1")
  case $format/$type in
    json/*json* | html/*html*) pass "f=$format answers $type" ;;
    *) fail "f=$format answers $type" ;;
  esac
done

echo "== Read-only"
refused "POST a feature is refused" -X POST -H 'Content-Type: application/geo+json' -d '{}' "$obs"
refused "DELETE a feature is refused" -X DELETE "$obs/00000000-0000-0000-0000-000000000000"

[ "$failed" -eq 0 ] && echo "All checks passed." || { echo "Some checks failed."; exit 1; }
