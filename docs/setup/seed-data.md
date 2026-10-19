# Seed data

Four management commands fill a fresh database with a butterfly list, plants, codelists and a demo
project. They are for development, the sample data of the thesis and the simulator (T071). All of them
can be run again: a second run creates nothing new.

```fish
set DC docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml
$DC exec -u (id -u) -e HOME=/tmp django python manage.py import_gbif_butterflies --country RS
$DC exec -u (id -u) -e HOME=/tmp django python manage.py seed_plants
$DC exec -u (id -u) -e HOME=/tmp django python manage.py seed_codelists
$DC exec -u (id -u) -e HOME=/tmp django python manage.py seed_demo
```

Run them as yourself (`-u`), because they write the GBIF cache into your working tree.
`seed_demo` calls `seed_codelists` itself and uses the GBIF list when it exists, so the order above is
the one that gives the demo project a real species list.

| Command | Creates |
|---|---|
| `import_gbif_butterflies --country RS` | `TaxonListVersion "2026.1 (GBIF RS)"` and one `Taxon` per species with at least 3 records in the country (`--min-records`). Species with fewer records are printed for manual review. The release becomes current only when there is no current one. |
| `seed_plants` | `PlantTaxon` rows from `database/seeds/plants.csv` with their GBIF key and family. Names GBIF does not find are saved as `manual` and listed. |
| `seed_codelists` | 6 habitat types (with EUNIS codes) and 5 management types. Values that exist are not touched. |
| `seed_demo` | Users `admin@demo` and `researcher@demo`, project "Demo – Fruška Gora 2026" (protocol, study area, researcher as member) and transects FG1–FG4 of about 1 km with 5–8 sections each, from `database/seeds/transects.geojson`. |

`seed_demo` prints the password of users it creates (`--password`, default `demo-password`). It refuses
to run unless `DJANGO_DEBUG` is true. An account that already exists is never added to a group (the
command warns), and a soft-deleted transect is skipped with a warning. Run it again after
`import_gbif_butterflies` and it links the project to the GBIF list.

## Files

The files live in `database/seeds/`, mounted into the django container as `/seeds` (`SEEDS_DIR`).

- `plants.csv`: about 77 larval host and nectar plants. A name ending in ` spp.` is a genus. Serbian
  names are filled only where they are known; the rest is for a researcher to add in the admin.
- `transects.geojson`: four lines and, per section, the habitat and management type. The lines are
  **illustrations on Fruška Gora, not surveyed routes**.
- `cache/` (git-ignored): every GBIF response, one JSON file each, about 500 files and 3 MB. A cached
  call makes no request, so a second run works offline. A fresh clone has no cache, so its first
  run of `import_gbif_butterflies` and `seed_plants` needs internet (about 500 requests, roughly
  3 minutes). Delete a file (or the folder) to fetch it again. Live calls are limited to 3 per
  second and send a `User-Agent` that names the project.

## Limitations

- **The list comes from GBIF occurrence records. It contains misidentifications and vagrants, and
  misses species nobody has uploaded. It is a working list, not a vetted checklist.** Say so in the thesis.
- The GBIF backbone has no node for the superfamily *Papilionoidea*, so the importer uses its six
  families instead (D-047). The backbone is being replaced; the importer stores the key GBIF returns
  and `taxon_source_id`, so a later list can be matched by key.
- Backbone names with status `DOUBTFUL` are imported and marked in the taxon's identification notes.
