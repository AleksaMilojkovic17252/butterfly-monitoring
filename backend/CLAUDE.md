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
```

Dependencies are pip + `requirements.txt`, installed in the image: after a change, rebuild with
`$DC up -d --build`. Ruff config (line length 100) is in `pyproject.toml`.

## Layout

- `config/` holds settings, urls, wsgi. Apps live in `apps/<name>/`; import them as `apps.<name>`,
  but the app label stays `<name>` (`accounts.User`, table names, migration dependencies).
- `apps/core/` has the shared pieces: `models.SyncableModel` (with `soft_delete()`),
  `migration_ops` (`CreateView`, `AttachSyncTrigger`, `HistoryVersionIndex`), `history.save_with_reason`, the error
  handler in `exceptions.py`, `geo_files.open_datasource` (reading uploaded GeoJSON/KML/GPX), the admin site, and the admin map widgets in `widgets.py`
  (`EditableMapWidget`, `LineMapWidget`; `setReference()` in `editable_map.js` draws a guide line, D-045).
- Input rules V01-V08 / W01-W07 (T055, docs/requirements/validation-rules.md) are pure functions in
  `apps/observations/rules.py` and `apps/surveys/rules.py`; `save_observation` and `save_visit` call the hard rules (the warning
  functions are not called by the services),
  and a rejection is `{"<field>": ["V04"]}` (the message is the rule ID).
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
  migration. The autodetector does not see them: renaming or dropping a column a view uses needs
  a hand-written migration that drops and recreates the view. Never set `security_invoker` and
  never grant `pygeoapi_ro` anything on `public` (D-004).
- Always read a generated migration before applying it. Never edit an applied migration.

## API

- Everything under `/api/v1/`, JSON, JWT bearer auth. OpenAPI at `/api/v1/schema/`.
- Errors use the body `{"code", "detail", "fields"}`.
- Times are UTC `timestamptz`.
