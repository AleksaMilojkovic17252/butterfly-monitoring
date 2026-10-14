# CLAUDE.md

Butterfly monitoring: an offline-first Android app plus a Django/PostGIS server for standardised
butterfly transect surveys (Pollard walks). Researchers record visits, GPS routes, butterflies,
plants and habitat in the field without a connection, then sync to the server. Admins validate,
resolve conflicts, lock visits and export. Data is published through OGC API – Features (pygeoapi).
Master's thesis, solo developer. **Phase 1** (thesis Part 1) is due February 2027; **Phase 2**
(SensorThings, EDR, Moving Features + MobilityDB) comes after.

More: [docs/PROJECT_OUTLINE.md](docs/PROJECT_OUTLINE.md) · [docs/CONVENTIONS.md](docs/CONVENTIONS.md) ·
[docs/TICKETS.md](docs/TICKETS.md) (status) · [docs/TICKET_DETAILS.md](docs/TICKET_DETAILS.md) (full ticket text) · [docs/DECISIONS.md](docs/DECISIONS.md) ·
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
| `scripts/` | backup/restore (T010) |
| `simulator/` | Phase 2 sensor simulator (empty until then) |
| `docs/` | requirements, architecture, setup, evaluation notes |

## Commands

The code does not exist yet; T002, T003 and T006 create it. Commands below come from those tickets.
Lines marked **TODO** are settled by that ticket: update this section in the same commit.
No automated tests and no CI for now (DECISIONS.md D-021). Checks are lint, format and a manual run.

```bash
# Stack (T002). Backend commands run inside the django container (D-022).
DC="docker compose -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml"   # TODO(T002): confirm paths
$DC up -d                                          # dev: source mounted, runserver, DEBUG
$DC ps
$DC logs -f django

# Backend (T003): pip + backend/requirements.txt, installed in the image
$DC exec django ruff format .
$DC exec django ruff check .
$DC exec django python manage.py makemigrations    # then review the generated migration
$DC exec django python manage.py makemigrations --check
$DC exec django python manage.py migrate
$DC exec django python manage.py check

# Mobile (T006), run in mobile/
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift codegen
dart format .
flutter analyze
dart run drift_dev make-migrations                 # after any Drift schema change
flutter run                                        # on the phone over USB
flutter build apk --debug
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
- Python: `ruff format` + `ruff check`, line length 100, configured in `backend/pyproject.toml` (T003). Dart: `dart format` defaults, `flutter_lints`, `flutter analyze` clean (T006).
- Android package id: `rs.amilojkovic.butterfly`.

## How to work a ticket

Use `/next-ticket` (or `/next-ticket T0xx`), then `/finish-ticket`. By hand:

1. **Read** the ticket's section in [docs/TICKET_DETAILS.md](docs/TICKET_DETAILS.md) (search `### T0xx ·`), its row in [docs/TICKETS.md](docs/TICKETS.md), and the conventions it cites. Every ticket in "Depends on" must be `done` or `dropped`; if not, stop and say so.
2. **Branch** `t0xx-short-slug` from `main`, and set the ticket's status to `in progress` in TICKETS.md.
3. **Plan** in 5–10 lines: files to touch, migrations, and how each acceptance criterion will be shown working. Show it before writing code.
4. **Implement** the smallest change that meets the acceptance criteria. **Skip criteria that only ask for automated tests or CI** (D-021); say which ones you skipped.
5. **Check**: format and lint what you touched, `makemigrations --check`, and bring the stack or app up to confirm the feature works by hand. Give the user the steps to see it.
6. **Commit** on the branch as `T0xx: <imperative summary>`. The final commit message includes `Closes #<issue>` (issue = nnn + 17), so GitHub closes the issue when it reaches `main`.
7. **Record**: set the status to `done` in TICKETS.md, add a `docs/DECISIONS.md` entry for any design choice a later session would need, and write down `VERIFY` results where the ticket says.
8. **Merge** into `main` with the user's OK (`git merge --ff-only` or a merge commit); pushing is the user's call.

## Definition of done

- Every acceptance criterion is met, skipped as a test/CI item, or deferred with the user's agreement (noted in TICKETS.md under the ticket).
- Code is formatted and lint-clean; `makemigrations --check` is clean; `flutter analyze` is clean.
- The feature has been run once by hand (stack up, app on the phone or emulator) and the user has the steps to demo it.
- Drift schema changes have a committed snapshot and migration; Django migrations are committed.
- Docs the ticket asks for exist; this file's Commands section is updated if a command changed.
- TICKETS.md status is `done`. No TODO left in code without a ticket ID.

## Do not

- Do not add tests, test frameworks or CI unless the user asks (D-021).
- Do not add, upgrade or remove a dependency (pip, pub, Docker image tag) without asking. Pins come from CONVENTIONS.md A.4.
- Do not work on a ticket whose dependencies are not `done`/`dropped`, or on Phase 2 before Phase 1 is done (study tickets T076/T082/T086 excepted).
- Do not widen a ticket: anything outside its acceptance criteria is a question to the user.
- Do not use removed features (CONVENTIONS.md A.1), OGC write/transactions, presigned MinIO URLs, Celery/workers, iOS code, or a custom permission framework.
- Do not set `security_invoker` on `geo` views or grant `pygeoapi_ro` anything on `public`.
- Do not edit applied migrations; add a new one. Do not edit `docs/reference/` or `docs/TICKET_DETAILS.md`.
- Do not read, print or commit `.env` or secrets. Do not run `docker compose down -v` (deletes data), force-push or push without asking.
