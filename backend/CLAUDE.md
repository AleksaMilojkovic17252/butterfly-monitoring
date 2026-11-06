# backend/CLAUDE.md

Django 5.2 + GeoDjango, DRF, PostGIS. Rules for the whole repo are in the root
[CLAUDE.md](../CLAUDE.md); database and API rules in full are in
[docs/CONVENTIONS.md](../docs/CONVENTIONS.md) A.5 and A.7.

## Commands

Everything runs inside the `django` container (D-022), from the repo root. Commands that write
files (`ruff format`, `makemigrations`) run as the developer so the files are not root-owned.

```bash
DC="docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml"
$DC exec -u $(id -u) -e HOME=/tmp django ruff format .
$DC exec django ruff check .
$DC exec -u $(id -u) -e HOME=/tmp django python manage.py makemigrations   # then review it
$DC exec django python manage.py makemigrations --check
$DC exec django python manage.py migrate
$DC exec django python manage.py check
$DC exec django python manage.py test apps.surveys apps.observations   # no database: visit states vs visit-states.json (T034, D-058) and the input rules (T055)
$DC exec django python manage.py collectstatic --noinput   # after adding static files: nginx serves the collected copy

# Seed data (T024; docs/setup/seed-data.md). Run as the developer: they write the GBIF cache.
$DC exec -u $(id -u) -e HOME=/tmp django python manage.py import_gbif_butterflies --country RS
$DC exec -u $(id -u) -e HOME=/tmp django python manage.py seed_plants
$DC exec -u $(id -u) -e HOME=/tmp django python manage.py seed_codelists
$DC exec -u $(id -u) -e HOME=/tmp django python manage.py seed_demo

# Sync (T026): drop stored push mutations older than the retry window
$DC exec django python manage.py prune_sync_mutations --older-than 180d

# Quality flags (T056, D-093) and route coverage (T100, D-095): work them out again for a project (<uuid>); after
# changing a protocol threshold, the project area or a transect line. Locked visits are skipped.
$DC exec django python manage.py recompute_flags --project <uuid>   # also redoes the route coverage of visits (T100)
```

Dependencies are pip + `requirements.txt`, installed in the image: after a change, rebuild with
`$DC up -d --build`. Ruff config (line length 100) is in `pyproject.toml`.

## Layout

- `config/` holds settings, urls, wsgi. Apps live in `apps/<name>/`; import them as `apps.<name>`,
  but the app label stays `<name>` (`accounts.User`, table names, migration dependencies).
- `apps/core/` has the shared pieces: `models.SyncableModel` (with `soft_delete()`),
  `migration_ops` (`CreateView`, `AttachSyncTrigger`, `HistoryVersionIndex`), `history.save_with_reason`, the error
  handler in `exceptions.py`, `geo_files.open_datasource` (reading uploaded GeoJSON/KML/GPX), the admin site, and the admin map widgets in `widgets.py`
  (`EditableMapWidget`, `LineMapWidget`; `setReference()` in `editable_map.js` draws a guide line, D-045). A read-only page shows a geometry with `readonly_map.js` (a `div.readonly-geometry-map` with `data-geojson`, T052); `ReadOnlyMapMixin` adds it
  as `location_map` to a model admin.
- Input rules V01-V09 / W01-W07 (T055, docs/requirements/validation-rules.md) are pure functions in
  `apps/observations/rules.py` and `apps/surveys/rules.py`; `save_observation` and `save_visit` call the hard rules (the warning
  functions are not called by the services),
  and a rejection is `{"<field>": ["V04"]}` (the message is the rule ID).
- Section assignment (T048, D-084): `transects.services.nearest_section_id` finds the section; `observations.services`
  calls it on create, and `SyncEntity.server_fills_null` makes a pushed null section mean "server fills it in".
- `apps/resources/` (T051, D-086; T053, D-088) holds `PlantResourceObservation` (a point or patch polygon, with `patch_area_m2` computed by
  `save_plant_resource`) and `HabitatFeature` (a point, line or polygon, `save_habitat_feature`), their rules (V02, V07, V08), the REST
  endpoints and the admin. Plant records are editable there (T111, D-106): add, a map editor plus an exact-coordinates GeoJSON box, and
  `admin_save_plant_resource`, `admin_soft_delete_plant_resource` and `admin_restore_plant_resource` (locked-visit and link guards); habitat
  features stay read-only (`ReadOnlyGeometryAdmin`). `PLANT_LINK_ROLES` and `plant_notes_errors` live in `resources/rules.py`. Scopes (T112, D-107): `plant_resources_for` / `habitat_features_for` are the **read** scope (every live record of the user's projects, also for links); `own_plant_resources_for` / `own_habitat_features_for` are the **write** scope (REST PATCH, `build_new_photo`); `observations.services.viewable_photos_for` is the read scope for photo downloads, `photos_for` stays the upload scope. The pulls send every member's rows (every visit of the project in any status; others' plant photos once uploaded). Observations link to a plant record
  (`host_plant_record`, `nectar_plant_record`) and a `Photo` can belong to one (a habitat feature has no photos); `observations.services` imports
  `resources.services`, never the reverse. The observation admin has Add (`check_admin_add` / `admin_add_observation`, T113, D-108: the visit's researcher
  is the recorder and `created_by`), and photos are editable on both pages from the `PhotoInline` / `PhotoAddInline` pair through `admin_add_photo`, `admin_make_primary_photo` and
  `admin_soft_delete_photo`; bytes are checked by `admin_store_photo_file` → `store_content`, and a photo's owner is the parent's `created_by`.
- `apps/transects/` also holds `TransectProposal` (T108, D-098): a route the phone recorded, pushed like a plant record (the
  proposer is `created_by`; `status`, the review fields, `created_transect` and `length_m` are server-owned; `guard_proposal` refuses
  any change after a review with `proposal_reviewed`). Its rules are `transects/rules.py`, and `services.accept_proposal` /
  `reject_proposal` are the only review path: the admin actions "Create transect" (an inactive transect, the replaced one only
  deactivated) and "Reject" call them. `ReadOnlyMapMixin.location_map_reference()` can draw a second, dashed geometry
  (`data-reference-geojson` in `readonly_map.js`).
- `apps/environment/` holds `EnvironmentalSnapshot` (server-only, T063) and `refresh_manual_snapshots`, which
  `save_visit` calls for a finished visit (D-076).
- `apps/exports/` (T064, D-077) builds the admin-only exports: `datasets.py` defines the datasets and columns, `writers.py` the
  CSV/GeoJSON/JSON streams, `service.py` is the single implementation (`export`, `bundle`) that the API views and T065's admin
  actions call. A new exportable table is a `Dataset` there, with `help_text` on its model fields. `geopackage.py` (T066, D-103) runs
  `ogr2ogr` per layer from the `geo` views, and the non-spatial tables come from the dataset SQL.
- `apps/validation/` (T058, D-090; T057, D-091) holds `ValidationEvent`, an append-only record of each validation decision, and the proxy
  `ValidationQueueItem` (the admin queue). Only `services.record_decision` creates events, and `services.decide` is the one way to apply a
  decision (it calls `record_decision` before changing the observation). **Never save a `ValidationQueueItem`**: a proxy save writes no history row, so
  `decide` loads `ButterflyObservation`. The read-only `ValidationEventInline` (in `inlines.py`) on the observation admin and the
  `validation_history` export read the events.
- `apps/validation/flags.py` (T056, D-093) works out the automatic quality flags (`outside_project_area`, `far_from_transect`,
  `high_count` on observations, `gps_gap` and `low_coverage` on visits; the latter reads the stored `route_coverage_pct`). It is a **leaf module** (models only, never a `services` module), because
  `save_observation` and `save_visit` call it and set the flags just before the save. `validation.services.recompute_*` (the admin
  actions and `recompute_flags`) apply it to stored rows: saved as instances so history applies, never `QuerySet.update()`.
- `apps/surveys/coverage.py` (T100, D-095) works out `SurveyVisit.route_coverage_pct` in SQL (a leaf module: models and `core.geo` only).
  `save_visit` and `refresh_after_points` call `refresh_route_coverage`, which is server-owned (`_NOT_SYNCED`, `SERVER_OWNED_FIELDS`, the
  admin's `fixed_fields`). The view `public.survey_visit_validity` is the valid-visit rule of protocol §6 for T061 and T101; it is not in
  `geo`, and `pygeoapi_ro` must not get it. `apps/core/geo.py` holds `utm_srid`, which `transects.services` and `surveys.coverage` share.
- `apps/reports/` (T061, D-099) has four unmanaged models over the views `public.report_transect_indicators`, `report_species_phenology`,
  `report_behaviour_counts` (created in `0001_initial`, no `pygeoapi_ro` grant) and `report_transect_profile` (T103, D-105, `0002`; 50 m bins along the transect, built on
  `geo.butterfly_observations`: a change to that view must drop and recreate it too) and read-only admins limited to `projects_for(user)`, with an "Export selected as CSV" action.
  Years and ISO weeks are in the project's time zone. A column change in a source table (`survey_visit`, `butterfly_observation`, `project_protocol`, `transect`) needs a
  hand-written migration that drops and recreates the views.
- `apps/projects/services.py` (T099, D-104): `close_project` / `reopen_project` (the admin actions, with a reason) set `Project.closed_at`. `ensure_project_open(project, made_at)` raises `ProjectClosed`
  (`project_closed`, 409) for a change the phone made after the close: `sync.services._apply` calls it for every update, delete and resent create, the `build_new_*` functions for creates,
  `push_track_points` for track points, and the REST `update_*` services with `None`. `made_at` is the mutation's `client_created_at` (`sync.handlers.current_client_time`). Django admin saves do not call it.
- `apps/accounts/` has `OgcVerifyView` (`/api/v1/auth/verify`, T069, D-080): nginx `auth_request` calls it for `/ogc`, and
  `authentication.py` adds Basic auth with its own failed-login counter. Personal tokens (`rest_framework.authtoken`) are accepted there only.
- Business rules go in `apps/<name>/services.py`. Views, serializers, admin and sync push all
  call these service functions; they do not hold rules themselves. Visibility goes through
  `projects.services.projects_for(user)`.

## Models and migrations

- Every model sets `db_table` (singular snake_case) and a client-generated UUID primary key.
  The server never re-keys.
- Enums are `TextChoices` + `CheckConstraint`, never a native PostgreSQL `ENUM`.
- Geometry is `geometry(<Type>, 4326)` with a GiST index; metres via `::geography`.
- **Synced table:** extend `SyncableModel`, and put `AttachSyncTrigger("<table>")` in the migration
  right after its `CreateModel`. Soft delete only, no hard deletes of synced rows.
  An audited synced table also gets `HistoryVersionIndex("historical_<table>")` in its migration
  (T027 reads past states by `(id, server_version)`). `PushHandlers` with `create`, `update` or
  `delete` must set `project_of` (checked at import).
- **Audited model:** `HistoricalRecords(table_name="historical_<table>")`. No `QuerySet.update()`
  on audited models (it skips history); save instances, with `save_with_reason` when a reason is
  required.
- **`geo` views** for pygeoapi are created with `CreateView("geo.<name>", "<select>")` in a
  migration in the app that owns the view's main table. The autodetector does not see them:
  renaming or dropping a column a view uses, or changing its type, needs a hand-written migration
  that drops and recreates the view (PostgreSQL refuses otherwise). `start_m`, `end_m` (sections) and `distance_along_m`, `offset_m` (observations) are computed in the views (T103). Never set `security_invoker` and
  never grant `pygeoapi_ro` anything on `public` (D-004). pygeoapi reads a view's columns at start,
  so restart it after a migration that changes a view; it does not start if a configured view is
  missing, so migrate first.
- Always read a generated migration before applying it. Never edit an applied migration.

## API

- Everything under `/api/v1/`, JSON, JWT bearer auth. OpenAPI at `/api/v1/schema/`.
- Errors use the body `{"code", "detail", "fields"}`.
- Times are UTC `timestamptz`.
