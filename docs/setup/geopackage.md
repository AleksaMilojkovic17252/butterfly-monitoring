# GeoPackage export (T066)

One `.gpkg` file with every spatial layer of a project, for QGIS users. CSV and GeoJSON (T064)
cover the same data; the GeoPackage is the convenient one when you want all layers at once.

## What is in the file

Spatial layers come from the `geo` views (T067), so their columns are the ones OGC API shows.
All are EPSG:4326 and the geometry column is called `geometry`.

| Layer | Geometry | Source |
|---|---|---|
| `transects` | LineString | `geo.transects` |
| `transect_sections` | LineString | `geo.transect_sections` |
| `butterfly_observations` | Point | `geo.butterfly_observations` |
| `plant_resources_points` | Point | `geo.plant_resources` |
| `plant_resources_polygons` | Polygon | `geo.plant_resources` |
| `habitat_features_points` | Point | `geo.habitat_features` |
| `habitat_features_lines` | LineString | `geo.habitat_features` |
| `habitat_features_polygons` | Polygon | `geo.habitat_features` |

"Split by type" means by geometry type: a GeoPackage layer holds one. Three tables have no
geometry; their columns, scoping and order are those of the CSV bundle (T064), with real types:
`survey_visits` (with `outcome`), `environmental_snapshots`, `validation_history`.

- `from` / `to` (UTC days, both included) filter `observed_at` of observations, plant records
  and habitat features, and the dated non-spatial tables as in the CSV bundle. Transects and
  sections ignore them.
- `na`, `excel` and `track_points` do not apply: the file has real NULLs, and there is no
  track-point layer.
- A layer with no rows is still created, with its columns.
- The file has no `metadata.json`.

## Get it

From the admin: open a project and click **Export project GeoPackage** (the whole project, API
defaults).

From the API (fish; an admin token, see `docs/setup/ogc-access.md` or log in):

```fish
set TOKEN (curl -s -X POST localhost:8080/api/v1/auth/login -H 'Content-Type: application/json' -d '{"email":"ADMIN_EMAIL","password":"PASSWORD"}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["access"])')
curl -s -H "Authorization: Bearer $TOKEN" -o project.gpkg "localhost:8080/api/v1/exports/bundle?project=PROJECT_UUID&format=gpkg"
```

## Open it in QGIS

Layer > Add Layer > Add Vector Layer, pick the file, and add all layers (or drag the file into
QGIS). The project CRS should read EPSG:4326, and the attribute tables should show real types
(dates as dates, flags as booleans, counts as integers).

Checked in QGIS (T066): all 11 layers load with their attributes and the CRS is EPSG:4326.
