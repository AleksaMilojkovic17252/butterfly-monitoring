#!/usr/bin/env bash
# Smoke test of the OGC API - Features collections (T068). Reads only: the POST and DELETE at the end
# must be refused, and the DELETE names an id that does not exist.
#
#   OGC_AUTH='Token <key>' scripts/ogc-smoke.sh [base-url]        default http://localhost:8080/ogc
#
# OGC_AUTH is the whole Authorization header value of an admin (T069): 'Token <key>' (docs/setup/ogc-access.md),
# 'Bearer <jwt>' or 'Basic <base64>'. Without it every request would get a 401.
#
# Prints PASS or FAIL per check and exits 1 if any failed. Expects the demo seed data
# (docs/setup/seed-data.md) and at least one observation. The next links come from server.url in the
# pygeoapi config, so the paging walk only reaches the laptop's own address.
set -uo pipefail

: "${OGC_AUTH:?set OGC_AUTH, for example OGC_AUTH='Token <key>'}"
# Every curl call below sends the credential.
curl() { command curl -H "Authorization: $OGC_AUTH" "$@"; }

base=${1:-http://localhost:8080/ogc}
transects=$base/collections/transects/items
sections=$base/collections/transect-sections/items
obs=$base/collections/butterfly-observations/items
plants=$base/collections/plant-resources/items
habitats=$base/collections/habitat-features/items
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

code=$(curl -s -o /dev/null -w '%{http_code}' "$base?f=json")
case $code in
  200) ;;
  401 | 403) echo "$base refused OGC_AUTH ($code): it must be an admin's token, JWT or Basic header"; exit 1 ;;
  *) echo "$base is not reachable ($code)"; exit 1 ;;
esac

total_transects=$(curl -fsS -G "$transects" -d f=json -d limit=1 | jq .numberMatched)
first=$(curl -fsS -G "$obs" -d f=json -d limit=1 | jq -c '.features[0]')
first_id=$(jq -r .id <<<"$first")
day=$(jq -r '.properties.observed_at[:10]' <<<"$first")

echo "== Collections"
expect "the five collections, no skeleton" \
  '[.collections[].id] | (contains(["transects", "transect-sections", "butterfly-observations", "plant-resources", "habitat-features"]) and index("skeleton-pings") == null)' \
  "$base/collections"
expect "observations have spatial and temporal extents" \
  '.extent.spatial.bbox[0] != null and .extent.temporal.interval[0][0] != null' \
  "$base/collections/butterfly-observations"
expect "plant records have spatial and temporal extents" \
  '.extent.spatial.bbox[0] != null and .extent.temporal.interval[0][0] != null' \
  "$base/collections/plant-resources"
expect "habitat features have spatial and temporal extents" \
  '.extent.spatial.bbox[0] != null and .extent.temporal.interval[0][0] != null' \
  "$base/collections/habitat-features"
expect "OpenAPI lists the observations" \
  '.paths | keys | any(contains("butterfly-observations"))' "$base/openapi"
expect "OpenAPI lists the plant records" \
  '.paths | keys | any(contains("plant-resources"))' "$base/openapi"
expect "OpenAPI lists the habitat features" \
  '.paths | keys | any(contains("habitat-features"))' "$base/openapi"

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

echo "== Plant records (these pass with no rows too)"
expect "geometry_type is POINT or POLYGON, nothing else" \
  '.features | all(.properties.geometry_type | . == "POINT" or . == "POLYGON")' \
  "$plants"
expect "resource_type=larval_host returns only that value" \
  '.features | all(.properties.resource_type == "larval_host")' \
  "$plants" --data-urlencode 'resource_type=larval_host'
expect "a resource_type nobody has matches nothing" \
  '.numberMatched == 0' \
  "$plants" --data-urlencode 'resource_type=NoSuchType'

echo "== Habitat features (these pass with no rows too)"
expect "geometry_type is POINT, LINESTRING or POLYGON, nothing else" \
  '.features | all(.properties.geometry_type | . == "POINT" or . == "LINESTRING" or . == "POLYGON")' \
  "$habitats"
habitat_code=$(curl -fsS -G "$habitats" -d f=json -d limit=1 | jq -r '.features[0].properties.habitat_type_code // empty')
if [ -n "$habitat_code" ]; then
  expect "habitat_type_code=$habitat_code returns only that value" \
    ".numberMatched > 0 and (.features | all(.properties.habitat_type_code == \"$habitat_code\"))" \
    "$habitats" --data-urlencode "habitat_type_code=$habitat_code"
else
  echo "SKIP  no habitat features yet: the real-code filter is not checked"
fi
expect "a habitat_type_code nobody has matches nothing" \
  '.numberMatched == 0' \
  "$habitats" --data-urlencode 'habitat_type_code=NoSuchType'

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
