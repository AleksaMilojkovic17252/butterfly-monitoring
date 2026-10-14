# CLAUDE.md

Butterfly monitoring: an offline-first Android app plus a Django/PostGIS server for standardised
butterfly transect surveys (Pollard walks). Researchers record visits, GPS routes, butterflies,
plants and habitat in the field without a connection, then sync to the server. Admins validate,
resolve conflicts, lock visits and export. Data is published through OGC API – Features (pygeoapi).
Master's thesis, solo developer. **Phase 1** (thesis Part 1) is due February 2027; **Phase 2**
(SensorThings, EDR, Moving Features + MobilityDB) comes after.

More: [docs/PROJECT_OUTLINE.md](docs/PROJECT_OUTLINE.md) · [docs/CONVENTIONS.md](docs/CONVENTIONS.md) ·
[docs/TICKETS.md](docs/TICKETS.md) · [docs/DECISIONS.md](docs/DECISIONS.md) ·
full original spec: [docs/reference/development-plan.md](docs/reference/development-plan.md) (body mostly Serbian).

## Stack and architecture

- **Mobile** (`mobile/`): Flutter, Android only. Riverpod, go_router, dio, Drift (SQLite), flutter_map, geolocator (foreground service).
- **Backend** (`backend/`): Python 3.12, Django 5.2 LTS + GeoDjango, DRF, simplejwt, drf-spectacular, django-simple-history, django-storages (S3).
- **Data**: PostgreSQL 17 + PostGIS 3.5, image `mobilitydb/mobilitydb:17-3.5-1.3` (MobilityDB not enabled until Phase 2). Photos in MinIO, reached only through Django.
- **OGC**: pygeoapi 0.24.x, read-only, reads views in schema `geo` as role `pygeoapi_ro`.
- **Runtime**: everything runs in Docker Compose on the developer's laptop behind nginx `:8080`; the phone reaches it over Tailscale (HTTPS) or USB (`adb reverse tcp:8080 tcp:8080`). Diagram: CONVENTIONS.md A.3.
- **Writes** from the app go through `POST /api/v1/sync/push`; REST viewsets share the same service functions.

Key directories (created by T002; most do not exist yet):

| Path | What |
|---|---|
| `backend/` | Django project; apps `core accounts projects catalogues transects surveys observations resources sync validation exports environment reports` |
| `mobile/` | Flutter app: `lib/core/` (config, http, db, location), `lib/features/<feature>/{data,domain,ui}`, `drift_schemas/` |
| `pygeoapi/config/` | pygeoapi configuration |
| `infrastructure/` | `compose.yaml`, `compose.dev.yaml`, `nginx/`, `db-init/` |
| `scripts/` | backup/restore, `tickets_index.py` |
| `simulator/` | Phase 2 sensor simulator (empty until then) |
| `docs/` | requirements, architecture, setup, evaluation notes |

## Commands

The code does not exist yet; T002, T003, T006 and T008 create it. Commands below come from those tickets.
Lines marked **TODO** are unknown until that ticket lands: update this section in the same PR.

```bash
# Stack (T002)
docker compose -f infrastructure/compose.yaml up -d          # TODO(T002): confirm file path / project name
docker compose -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml up -d   # dev: source mounted, runserver, DEBUG
docker compose -f infrastructure/compose.yaml ps | logs -f django

# Backend (T003, T008). TODO(T003): run inside the django container or a host venv? Package manager (pip/uv/poetry)?
pytest                                                       # TODO(T003): exact invocation
ruff check .                                                 # TODO(T008): formatter? (ruff format not yet decided)
python manage.py makemigrations --check
python manage.py spectacular --validate --file /tmp/schema.yaml

# Mobile (T006, T008), run in mobile/
flutter pub get
dart run build_runner build --delete-conflicting-outputs    # Drift codegen (TODO(T006): confirm)
flutter analyze
flutter test
dart run drift_dev make-migrations                           # after any Drift schema change
dart run drift_dev schema verify                             # TODO(T008): exact migration-test command
flutter build apk --debug

# Tickets
python3 scripts/tickets_index.py                             # regenerate docs/TICKETS.md from GitHub Issues
```

## Code style and conventions

Full rules: [docs/CONVENTIONS.md](docs/CONVENTIONS.md). The ones most often missed:

- Every model sets `db_table` (singular snake_case). UUID primary keys, client-generated; the server never re-keys.
- Synced tables extend `core.models.SyncableModel` and get `AttachSyncTrigger(table)` in their migration. Soft delete only (`soft_delete()`); no hard deletes of synced rows.
- Enums are `TextChoices` + `CheckConstraint`, never native PostgreSQL `ENUM`.
- Geometry is `geometry(<Type>, 4326)` with a GiST index; metres via `::geography`.
- Audited models use `HistoricalRecords(table_name="historical_<table>")`; no `QuerySet.update()` on audited models.
- `geo` views are created in Django migrations with `CreateView`; renaming a column means dropping and recreating dependent views by hand.
- API under `/api/v1/`, JSON, error body `{"code", "detail", "fields"}`, JWT bearer auth. Business rules live in service functions, not views or serializers.
- Drift: same column names as the server (camelCase in Dart), UUID text PKs, GeoJSON text geometry plus `lat`/`lon` for points, local `serverVersion`/`syncStatus`/`deletedAt`. UI never writes synced tables directly; go through the repository class.
- Times: UTC `timestamptz` on the server, UTC on the phone, local time only in the UI.
- Python: ruff. Dart: `flutter analyze` clean. TODO: line length and formatter settings once T003/T006 add the config.

## How to work a ticket

Use `/next-ticket` (or `/next-ticket T0xx`), then `/finish-ticket`. By hand:

1. **Read** the issue (`gh issue view <n>`; `Tnnn` is issue #(nnn+17)), its dependencies, and the conventions it cites. Check every hard dependency is closed; if not, stop and say so.
2. **Branch** `t0xx-short-slug` from the default branch and add the `in-progress` label to the issue.
3. **Plan** in 5–10 lines: files to touch, migrations, tests, and how each acceptance criterion will be checked. Show it before writing code.
4. **Implement** the smallest change that meets every acceptance criterion. Tests first where practical.
5. **Check**: run the backend and/or mobile checks above for whatever you touched. All must pass.
6. **Commit** with `T0xx: <imperative summary>` and `Refs #<issue>`. Open a PR using the template, with `Closes #<issue>`.
7. **Record**: tick the issue's checkboxes, comment with what was done, anything deferred, and `Actual: x d` if known. Add an entry to `docs/DECISIONS.md` for any design choice a later session would need. Resolve any `VERIFY` items the ticket names and write the result down where it says.
8. Regenerate `docs/TICKETS.md`.

## Definition of done

- Every acceptance criterion is met and checked off, or explicitly deferred in an issue comment the user agreed to.
- Tests cover the new behaviour; backend and/or mobile checks pass locally; `makemigrations --check` is clean.
- Drift schema changes have a committed snapshot and migration; Django migrations are committed and reversible where the ticket says so.
- OpenAPI still validates; new endpoints appear in it.
- Docs the ticket asks for exist; this file's Commands section is updated if a command changed.
- No TODO left in code without an issue reference.

## Do not

- Do not add, upgrade or remove a dependency (pip, pub, Docker image tag) without asking. Pins come from CONVENTIONS.md A.4.
- Do not work on a ticket whose hard dependencies are open, or on Phase 2 tickets before Phase 1 is done (study tickets T076/T082/T086 excepted).
- Do not widen a ticket: work outside its acceptance criteria goes in a new issue or a question to the user.
- Do not use removed features (CONVENTIONS.md A.1), OGC write/transactions, presigned MinIO URLs, Celery/workers, iOS code, or a custom permission framework.
- Do not set `security_invoker` on `geo` views or grant `pygeoapi_ro` anything on `public`.
- Do not edit applied migrations; add a new one. Do not edit `docs/reference/` or generated files by hand.
- Do not read, print or commit `.env` or secrets. Do not run `docker compose down -v` (deletes data) or force-push.
- Do not push to the default branch or close issues by hand: the PR's `Closes #n` closes the issue on merge.
