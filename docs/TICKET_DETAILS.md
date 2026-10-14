> Full ticket text, the same as the GitHub issues (ticket `Tnnn` = issue #(nnn + 17)). Status lives in
> [TICKETS.md](TICKETS.md). To read one ticket, search for its heading, e.g. `### T025 ·`. Do not edit;
> if a ticket changes, change it here and on GitHub together.

# Butterfly Monitoring: GitHub Issues (Step 2)

Master's thesis · solo developer · deadline February 2027
Repository: `butterfly-monitoring` (monorepo) · Feature list: **v4** (frozen 2026-10-12)

This file is ready to paste into GitHub Issues: each `### E..` block is an epic issue and each `### T...` block is one issue. Label and milestone names are listed below. Every ticket states the feature IDs it implements.

**How to read the size field:** estimates are in ideal working days for one developer. Tickets are sized 1–3 days, and larger work is split. See the *Capacity check* in Part D before you start: the full list is larger than the time available, and Part D says where to cut.

---

## Part A: Shared decisions and conventions

### A.1 Feature list v4 (what these tickets cover)

- **Phase 1 (thesis Part 1):** F1–F4, F6–F37 (except F5), F39–F41, F43–F46, F61 (P1 part), F62–F64, F66–F68, F71–F74, F77–F80, F87.
- **Phase 2 (thesis Part 2):** F47–F50, F52, F53, F55–F60, F61 (P2 part), F69, F70, F89.
- **Removed (no tickets):** F5, F38, F42, F51, F54, F65, F75, F76, F81, F82, F83, F84, F85, F86, F88.
- **v4 changes:** two roles (F2, F62); admins create projects and add members (F3); validation, conflicts, exports and pygeoapi are admin-only; lock/unlock lives in Django admin and the API enforces it (F13, F66); MobilityDB is the Phase 2 target (F57 Must; F70 becomes a research and design spike, with plain PostGIS as the fallback); F89 [PROPOSED] adds a Phase 2 study per standard; the laptop is the only server, reached over **Tailscale**.

### A.2 Roles (F2)

| Group | App | Django admin | Data scope |
|---|---|---|---|
| `researcher` | yes | **no** (`is_staff = False`) | projects where they are a member; in the app, only their own visits and observations |
| `admin` | yes (same as researcher) | yes, all models | all projects; only admins validate, resolve conflicts, lock/unlock, export, and use pygeoapi |

There is no custom permission framework. The `admin` group holds all model permissions through a data migration (T013). DRF permission classes check either project membership or admin-group membership.

### A.3 Runtime layout (all on your CachyOS laptop)

```
Phone (Flutter, Android) ──HTTPS──► Tailscale (tailscale serve, https://<laptop>.<tailnet>.ts.net)
                                         │
                                         ▼
                                   nginx :8080 ─┬─ /api/*, /admin/*  → django (gunicorn) :8000
                                                ├─ /static/*         → collected static files
                                                ├─ /ogc/*            → pygeoapi :5000 (auth_request → django /api/auth/verify/)
                                                └─ /sta/* (Phase 2)  → FROST :8080 (auth_request, admin-only)
django ──► PostgreSQL 17 + PostGIS 3.5 (+ MobilityDB 1.3 in Phase 2)   [image: mobilitydb/mobilitydb]
django ──► MinIO (S3 API) via django-storages; the phone never talks to MinIO directly
QGIS / R / Python on the laptop ──► http://localhost:8080/ogc/  (admin token or Basic auth)
```

- **Tailscale** is a free personal plan (6 users, unlimited devices; no traffic cap documented). It needs the Tailscale app on the phone and "HTTPS certificates" enabled once in the admin console. Command: `sudo tailscale serve --bg https / http://localhost:8080` (check the `--bg` flag in your installed version: VERIFY).
- **USB fallback for demos:** `adb reverse tcp:8080 tcp:8080`, then the app uses `http://localhost:8080`. The dev flavour allows cleartext only to `localhost`.
- **MinIO risk:** the MinIO community edition stopped publishing Docker images in October 2025, went into maintenance mode, and its repository was archived in April 2026. The tickets **pin the last official image** (exact tag: VERIFY). This is acceptable for a laptop that only your own Tailscale devices can reach. Because django-storages talks plain S3, swapping in another S3-compatible store (Garage, SeaweedFS, or a Chainguard MinIO build) is a settings change only. Note it in the thesis as a known limitation.

### A.4 Version pins (all VERIFY at T002/T003; pin exact versions in lock files)

| Component | Target | Note |
|---|---|---|
| Python | 3.12 | |
| Django | 5.2 LTS | LTS until April 2028; safer than 6.x for a thesis |
| djangorestframework | 3.16.x | VERIFY Django 5.2 support |
| djangorestframework-simplejwt | 5.5.x | uses the `token_blacklist` app for logout |
| drf-spectacular | 0.28.x | VERIFY |
| django-simple-history | 3.8+ | VERIFY Django 5.2 support |
| django-storages[s3] + boto3 | 1.14.x | |
| psycopg | 3.2.x | |
| pygeoapi | 0.24.x | 0.24.0 released mid-2026 |
| PostgreSQL / PostGIS / MobilityDB | 17 / 3.5 / 1.3 | image `mobilitydb/mobilitydb:17-3.5-1.3` (built on `postgis/postgis`) |
| FROST-Server (P2) | 2.x latest | VERIFY current tag (2.7.x/2.8.x seen) |
| Flutter | current stable | VERIFY |
| drift / drift_flutter | 2.x | |
| flutter_map | 7.x/8.x | VERIFY |
| geolocator | latest | Android foreground service via `foregroundNotificationConfig` (VERIFY API) |
| flutter_riverpod, go_router, dio, uuid, flutter_secure_storage, image_picker, flutter_image_compress, crypto | latest | |

### A.5 Database conventions (apply to every table ticket)

1. **One database `butterfly`.** Django owns schema `public`. Read-only views for pygeoapi live in schema `geo` and are created by Django migrations (`RunSQL`). Role `pygeoapi_ro` has `USAGE` on `geo` and `SELECT` on its views only. FROST (Phase 2) gets its own database, `frost`.
2. **Explicit table names.** Every model sets `db_table` to a singular snake_case name (`survey_visit`, not `surveys_surveyvisit`). Views and exports then read cleanly.
3. **UUID primary keys** for everything created on the phone. The client generates UUID v4, and the server never re-keys a record. Catalogue tables also use UUIDs so they can be referenced offline.
4. **Geometry:** `geometry(<Type>, 4326)` with a GiST index. Distances in metres use a `::geography` cast. Lines and polygons on the phone are stored as GeoJSON text.
5. **Enums:** Django `TextChoices` with a `CheckConstraint`, giving `varchar` + `CHECK (col IN (...))`, **not** native PostgreSQL `ENUM`. *Django limitation:* the ORM has no native enum type, and changing PostgreSQL enum values would need hand-written migrations. A CHECK constraint is regenerated by `makemigrations` when the choices change.
6. **Sync columns** on every table the phone writes or reads (the `SyncableModel` from T005):

| Column | Type | Meaning |
|---|---|---|
| `id` | uuid PK | client-generated |
| `server_version` | bigint not null | set by a DB trigger from the global sequence `sync_version_seq` on every insert/update; the pull cursor |
| `created_at` | timestamptz | when the record was created (on the phone, if created offline) |
| `updated_at` | timestamptz | last server-side save |
| `deleted_at` | timestamptz null | soft delete (tombstone), so deletions reach other devices on pull |
| `created_by_id`, `updated_by_id` | uuid FK → `app_user` | |

7. **Audit:** django-simple-history on all business tables except `survey_track_point` (high volume, append-only). History tables live in `public` next to their models.
8. **Times:** stored as `timestamptz` (UTC) on the server. The app stores UTC and displays local time. Exports include the offset (ISO 8601).

### A.6 Drift (SQLite) conventions

- **Same column names as the server, in camelCase in Dart.** Drift maps them to snake_case SQL by default, so SQLite column names match the server.
- **Primary key** is `TextColumn id` holding the UUID string. Set `primaryKey => {id}`.
- **Geometry** is a `TextColumn` holding a GeoJSON geometry (`geometry_geojson`). Points also get `lat`/`lon` `RealColumn`s for fast map and bbox filtering without parsing JSON.
- **Dates:** `DateTimeColumn`. Set `store_date_time_values_as_text: true` in `build.yaml`, so values are ISO-8601 strings that are readable in exports and debugging.
- **Local-only sync columns** on every synced table:
  - `serverVersion` (`IntColumn`, nullable until first push)
  - `syncStatus` (`textEnum<SyncStatus>`: `synced`, `pending`, `conflict`, `rejected`)
  - `deletedAt` (nullable)
- **Arrays** (e.g. `behaviour`) are stored as JSON text.
- **Read-only reference tables** (catalogues, transects) are only ever written by pull. The app never enqueues changes for them.

### A.7 API conventions

- **Paths:** base path `/api/v1/`. JSON only. OpenAPI via drf-spectacular at `/api/v1/schema/`, with Swagger UI at `/api/v1/docs/`.
- **Auth:** `Authorization: Bearer <JWT access>`. Access tokens last 15 min and refresh tokens 30 days, with rotation and blacklist on.
- **Errors:** a consistent body, `{"code": "...", "detail": "...", "fields": {...}}`.
- **Sync is the main write path.** The app writes through `POST /api/v1/sync/push`. The outline's REST endpoints (`POST /survey-visits`, etc.) exist as normal DRF viewsets for testing and docs, but share the same service-layer functions, so the rules live in one place.

### A.8 Labels and milestones

**Milestones:** `Phase 1 – Thesis Part 1`, `Phase 2 – Thesis Part 2`.

**Labels:**
- type: `epic`, `backend`, `mobile`, `admin`, `database`, `sync`, `ogc`, `infra`, `research`, `evaluation`, `docs`, `security`
- priority: `must`, `should`, `could`
- `p2-compat`: the ticket contains a note on keeping the Phase 1 design compatible with Phase 2

---
# Part B: Phase 1 tickets (milestone `Phase 1 – Thesis Part 1`)

## E01 · Foundations and infrastructure

### E01 · Epic: Foundations and infrastructure
**Labels:** `epic`, `infra` · **Milestone:** Phase 1 · **Implements:** F44, F45, F46, F77, F78
Repository, Docker stack, database layout, sync base model, app skeleton, a working end-to-end slice, CI, connectivity and backups. Nothing else should start until T007 (walking skeleton) is green.
Children: T001 · T002 · T003 · T004 · T005 · T006 · T007 · T008 · T009 · T010

---

### T001 · Requirements baseline: protocol, mandatory fields, codelists, ER diagram
**ID:** T001 · **Implements:** F77 · **Labels:** `docs`, `must` · **Milestone:** Phase 1 · **Epic:** E01 · **Depends on:** — · **Estimate:** 2 d

**Description**
Write down the decisions every later ticket depends on, in `docs/requirements/`. Proposed defaults are below; change anything your biologist disagrees with.

**Acceptance criteria**
- [ ] `docs/requirements/protocol.md` covers:
  - Pollard walk with a recording box of 2.5 m each side, 5 m ahead and 5 m up
  - season window and daily time window
  - weather thresholds: ≥ 13 °C with ≤ 40 % cloud, or ≥ 17 °C any cloud; wind ≤ 5 Bft; no rain
  - one record per taxon per sighting event, with a `count` field; group records allowed and `sex = mixed` allowed
  - maximum distance from the transect for flagging: 20 m
  - valid visit = completed, weather within thresholds or justified, with ≥ 80 % route coverage
- [ ] `docs/requirements/fields.md` lists every field per entity with mandatory/optional status, matching the models in this file.
- [ ] `docs/requirements/codelists.md` lists every enum value used in the CHECK constraints (sex, life stage, behaviour, confidence, source, resource type, abundance class, phenology stage, flowering intensity, grazing, mowing, disturbance, precipitation, visit status, cancel reason).
- [ ] `docs/requirements/er-diagram.md` contains a Mermaid `erDiagram` of all Phase 1 tables.
- [ ] `docs/requirements/decisions.md` answers all 15 questions from the outline's §27 in one line each.
- [ ] A paper "simulated field day" (outline §29) has been walked through once, and the slow or unclear steps are listed at the end of `protocol.md`.

**Technical explanation**
Pure documentation. Use the outline §7–§8 and §27 as the source. The defaults above follow common Pollard-walk practice; confirm them with your biologist.

**Limitations / out of scope / risks**
- Species-range rules (outline §13.1 "species outside known area") are out: there is no distribution data.
- Changing a codelist later means a migration (CHECK constraint) plus an app release, so settle them here.

---

### T002 · Monorepo layout and Docker Compose stack
**ID:** T002 · **Implements:** F44 · **Labels:** `infra`, `must` · **Milestone:** Phase 1 · **Epic:** E01 · **Depends on:** — · **Estimate:** 2 d

**Description**
Create the `butterfly-monitoring` monorepo and a Compose stack that starts every Phase 1 service on the laptop with one command.

**Acceptance criteria**
- [ ] Repository layout (adapted from outline §24): `mobile/`, `backend/`, `pygeoapi/config/`, `infrastructure/` (`compose.yaml`, `compose.dev.yaml`, `nginx/`, `db-init/`), `scripts/`, `docs/`, `simulator/` (empty until Phase 2), `.env.example`, `README.md`.
- [ ] `docker compose up -d` starts these services, each with a health check:
  - `db`: `mobilitydb/mobilitydb:17-3.5-1.3`
  - `minio`: last official image, pinned (VERIFY tag)
  - `django`: built from `backend/`
  - `pygeoapi`: `geopython/pygeoapi:0.24.x`
  - `nginx`
- [ ] Only nginx (`8080`), MinIO console (`9001`, localhost only) and Postgres (`5432`, localhost only, for QGIS/psql) are published to the host.
- [ ] Data lives in named volumes (`pgdata`, `miniodata`) and survives `docker compose down`.
- [ ] `.env.example` lists every variable, and no secret is committed. `.env` is in `.gitignore`.
- [ ] `README.md` "Run locally" section works from a clean clone on CachyOS (Docker from the Arch repos, `docker compose` plugin).

**Technical explanation**
- `db-init/01-init.sql` creates the roles: `django_app` (owner) and `pygeoapi_ro` (login, no privileges yet). It also creates `CREATE EXTENSION postgis;` in database `butterfly`. MobilityDB is **not** enabled in Phase 1.
- The `django` image is based on `python:3.12-slim` plus `gdal-bin libgdal-dev libproj-dev binutils`, which GeoDjango needs. It runs gunicorn.
- `compose.dev.yaml` mounts source code, runs `runserver`, and enables `DEBUG`.
- Reverse proxy choice is **nginx**, not Traefik. `auth_request` is a built-in module and the routing is static (four paths), so Traefik's service discovery adds nothing here.

**Limitations / out of scope / risks**
- **MinIO**: see A.3. The image is pinned, and the swap path is S3-compatible storage behind django-storages.
- **p2-compat:** the DB image already contains MobilityDB, so Phase 2 does not swap the database image.

---

### T003 · Django project bootstrap
**ID:** T003 · **Implements:** F44, F46 · **Labels:** `backend`, `must` · **Milestone:** Phase 1 · **Epic:** E01 · **Depends on:** T002 · **Estimate:** 1.5 d

**Description**
Create the Django project with all apps registered, settings from environment variables, DRF, drf-spectacular, django-storages and GeoDjango working.

**Acceptance criteria**
- [ ] Apps exist (empty where not yet used): `core`, `accounts`, `projects`, `catalogues`, `transects`, `surveys`, `observations`, `resources`, `sync`, `validation`, `exports`, `environment`, `reports`.
- [ ] `DATABASES` uses `django.contrib.gis.db.backends.postgis`, and `AUTH_USER_MODEL = "accounts.User"` is set **before the first migration** (see T011).
- [ ] `STORAGES["default"]` is the django-storages S3 backend pointing at MinIO (`AWS_S3_ENDPOINT_URL=http://minio:9000`, bucket `photos`, `AWS_S3_ADDRESSING_STYLE="path"`). A test uploads and deletes a file.
- [ ] `/api/v1/schema/` returns OpenAPI 3, and `/api/v1/docs/` serves Swagger UI.
- [ ] `GET /api/v1/health/` returns `{"status":"ok","db":true,"storage":true}`.
- [ ] pytest + pytest-django run against a test database. `python manage.py makemigrations --check` passes.

**Technical explanation**
- Settings: a single `settings.py` reading `os.environ`, with no settings-split framework.
- `REST_FRAMEWORK`:
  - default authentication `JWTAuthentication`
  - default permission `IsAuthenticated`
  - `DEFAULT_SCHEMA_CLASS = drf_spectacular.openapi.AutoSchema`
  - exception handler producing the A.7 error body
- `TIME_ZONE = "Europe/Belgrade"`, `USE_TZ = True`.

**Limitations / out of scope / risks**
- No Celery or worker (outline §23 "optional worker"). Long jobs (exports, thumbnails) run synchronously at thesis data volumes.

---

### T004 · Database schema strategy: `geo` schema and read-only role
**ID:** T004 · **Implements:** F45 · **Labels:** `database`, `must`, `p2-compat` · **Milestone:** Phase 1 · **Epic:** E01 · **Depends on:** T003 · **Estimate:** 1 d

**Description**
Create the `geo` schema, the read-only grants and a helper for adding views, all through Django migrations, so a fresh `migrate` reproduces the full layout.

**Acceptance criteria**
- [ ] Migration `core/0001_schemas` creates the `geo` schema owned by `django_app` and grants `USAGE ON SCHEMA geo TO pygeoapi_ro`.
- [ ] `ALTER DEFAULT PRIVILEGES FOR ROLE django_app IN SCHEMA geo GRANT SELECT ON TABLES TO pygeoapi_ro;` makes every future view readable automatically.
- [ ] `pygeoapi_ro` has **no** privileges on `public` tables. A test connects as `pygeoapi_ro` and gets `permission denied` on `SELECT * FROM public.app_user`.
- [ ] `core/migration_ops.py` provides `CreateView(name, sql)`, a `RunSQL` wrapper with reverse `DROP VIEW`, used by T067.
- [ ] `docs/architecture/database.md` explains the layout (A.5 item 1) and why the outline's `app`/`audit`/`sensorthings`/`mobility` schemas are not used in Phase 1.

**Technical explanation**
Views run with their owner's privileges by default. So `pygeoapi_ro` can read `geo` views built on `public` tables without any grant on those tables. **Do not** set `security_invoker = true` on these views.

**Limitations / out of scope / risks**
- **Django limitation:** the migration autodetector does not see views. Renaming a model column requires a hand-written migration that drops and recreates the dependent views. A test in T067 selects from every view to catch this.
- **p2-compat:** in Phase 2 the `mobility` schema is created only if the T087 spike chooses the AIST pygeoapi-mf-api fork. FROST uses database `frost`.

---

### T005 · Syncable base model and server-version trigger
**ID:** T005 · **Implements:** F25, F45 · **Labels:** `backend`, `database`, `sync`, `must` · **Milestone:** Phase 1 · **Epic:** E01 · **Depends on:** T004 · **Estimate:** 1.5 d

**Description**
Provide the abstract model and database trigger that give every synced table its UUID, timestamps, soft delete and a monotonically increasing `server_version`. Pull (T025) uses `server_version` as its cursor.

**Acceptance criteria**
- [ ] `core.models.SyncableModel` (abstract) exists with the fields below. `SyncableQuerySet.alive()` excludes soft-deleted rows.
- [ ] Migration `core/0002_sync_version` creates the sequence and trigger function. `AttachSyncTrigger(table)` is a reusable migration operation used by every model ticket.
- [ ] Insert and update both bump `server_version`, including `QuerySet.update()` and admin saves (tested).
- [ ] Two concurrent transactions writing to synced tables commit their versions in order (test with two connections: the second blocks until the first commits).
- [ ] Hard delete is disabled for synced models in services and admin. `soft_delete()` sets `deleted_at` instead.

**Technical explanation**
Trigger-assigned versions catch every write path. The transaction-level advisory lock serialises writers, so a lower version can never commit after a higher one has been pulled. That rules out the classic missed-row bug in cursor-based sync. At thesis concurrency (one or two writers) the lock costs nothing noticeable.

**Database**

a) GeoDjango model code

```python
# backend/core/models.py
import uuid
from django.conf import settings
from django.db import models
from django.utils import timezone


class SyncableQuerySet(models.QuerySet):
    def alive(self):
        return self.filter(deleted_at__isnull=True)

    def changed_since(self, cursor: int):
        return self.filter(server_version__gt=cursor).order_by("server_version")


class SyncableModel(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    # Set by DB trigger bump_server_version(); value on the instance is stale after save()
    server_version = models.BigIntegerField(default=0, editable=False, db_index=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT,
        null=True, blank=True, related_name="+")
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.PROTECT,
        null=True, blank=True, related_name="+")

    objects = SyncableQuerySet.as_manager()

    class Meta:
        abstract = True

    def soft_delete(self, user=None):
        self.deleted_at = timezone.now()
        self.updated_by = user
        self.save(update_fields=["deleted_at", "updated_by", "updated_at"])
```

b) PostGIS DDL

```sql
CREATE SEQUENCE IF NOT EXISTS sync_version_seq AS bigint;

CREATE OR REPLACE FUNCTION bump_server_version() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  -- Serialise writers so versions commit in order (released at COMMIT/ROLLBACK)
  PERFORM pg_advisory_xact_lock(727274);
  NEW.server_version := nextval('sync_version_seq');
  RETURN NEW;
END $$;

-- Applied to each synced table by AttachSyncTrigger(<table>):
-- CREATE TRIGGER trg_<table>_server_version
--   BEFORE INSERT OR UPDATE ON <table>
--   FOR EACH ROW EXECUTE FUNCTION bump_server_version();

-- Columns every synced table receives (shown once; repeated in each table's DDL below):
--   id              uuid PRIMARY KEY,
--   server_version  bigint NOT NULL DEFAULT 0,
--   created_at      timestamptz NOT NULL,
--   updated_at      timestamptz NOT NULL,
--   deleted_at      timestamptz NULL,
--   created_by_id   uuid NULL REFERENCES app_user(id) DEFERRABLE INITIALLY DEFERRED,
--   updated_by_id   uuid NULL REFERENCES app_user(id) DEFERRABLE INITIALLY DEFERRED
-- plus: CREATE INDEX ON <table> (server_version);
```

c) Drift: not applicable. The equivalent local columns are defined per table (A.6).

d) Django-specific limitation
- Because the trigger sets `server_version`, the Python instance holds a stale value after `save()`. Services that return the version call `obj.refresh_from_db(fields=["server_version"])`.
- `bulk_create()` works (row triggers fire), but the returned objects do not carry the version.

**Limitations / out of scope / risks**
- Serialising all synced writes would not scale to many concurrent users. That's fine here; document it as a design limitation.

---

### T006 · Flutter app foundation
**ID:** T006 · **Implements:** F23, F72 · **Labels:** `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E01 · **Depends on:** — · **Estimate:** 2 d

**Description**
Set up the Flutter project structure, state management, routing, HTTP client, Drift database shell and configurable server URL, so feature tickets only add screens and tables.

**Acceptance criteria**
- [ ] `mobile/` is Android-only (`flutter create --platforms=android`). Package id: `rs.<you>.butterfly` (choose).
- [ ] Folders: `lib/core/` (config, http, db, location), `lib/features/<feature>/` (data, domain, ui), `lib/app.dart`.
- [ ] Riverpod for state, go_router for navigation, dio for HTTP. Logging uses `logger` in debug only.
- [ ] `AppDatabase` (Drift) opens `butterfly.sqlite` with `schemaVersion = 1` and a migration strategy using `drift_dev make-migrations` (schema snapshots committed under `mobile/drift_schemas/`).
- [ ] Settings screen: server URL with presets **Tailscale** (`https://<laptop>.<tailnet>.ts.net`) and **USB** (`http://localhost:8080`), plus a "Test connection" button calling `/api/v1/health/`.
- [ ] `build.yaml` sets `store_date_time_values_as_text: true`.
- [ ] `flutter analyze` is clean, and one widget test runs.

**Technical explanation**
- The dio interceptor chain is auth (T012), logging, then error mapping into typed failures.
- Every Drift write to a synced table goes through a repository class (the sync queue hook in T029). Never write to synced tables directly from UI code.

**Limitations / out of scope / risks**
- No iOS.
- Package versions: VERIFY at setup and pin in `pubspec.lock`.

---

### T007 · Walking skeleton: one observation from phone to QGIS
**ID:** T007 · **Implements:** F78 · **Labels:** `backend`, `mobile`, `ogc`, `must` · **Milestone:** Phase 1 · **Epic:** E01 · **Depends on:** T002, T003, T004, T005, T006 · **Estimate:** 3 d

**Description**
Prove the whole architecture with the thinnest slice: the app stores a "ping" offline and sends it to Django; Django saves it in PostGIS; a `geo` view exposes it; pygeoapi serves it; QGIS shows it. The stub tables are removed in T044.

**Acceptance criteria**
- [ ] The app has a debug-only screen with a "Drop ping" button that stores the current GPS position plus time in Drift, works in airplane mode, and has a "Send" button that POSTs pending pings.
- [ ] `POST /api/v1/skeleton/pings` accepts `{id, observed_at, lat, lon, note}` and is idempotent: posting the same `id` twice gives one row.
- [ ] View `geo.skeleton_pings` exists. pygeoapi collection `skeleton-pings` returns it at `/ogc/collections/skeleton-pings/items?f=json`.
- [ ] QGIS on the laptop loads the collection as an OGC API – Features layer.
- [ ] This runs over **Tailscale** from the real phone at least once (T009 can run in parallel; USB is fine for the first pass).
- [ ] Findings are written in `docs/architecture/skeleton-findings.md`, including **VERIFY results**: pygeoapi reads a view (yes/no), `id_field` with uuid works, and whether a `time_field` on a view works.

**Technical explanation**
This uses the real stack (GeoDjango, `geo` view, read-only role, nginx `/ogc/` route) but no auth on `/ogc/` yet (T069 adds it).

**Database**

a) GeoDjango model

```python
# backend/core/models_skeleton.py  (deleted in T044)
from django.contrib.gis.db import models

class SkeletonPing(models.Model):
    id = models.UUIDField(primary_key=True)
    observed_at = models.DateTimeField()
    geometry = models.PointField(srid=4326)
    note = models.CharField(max_length=200, blank=True)
    received_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "skeleton_ping"
```

b) PostGIS DDL

```sql
CREATE TABLE skeleton_ping (
  id          uuid PRIMARY KEY,
  observed_at timestamptz NOT NULL,
  geometry    geometry(Point, 4326) NOT NULL,
  note        varchar(200) NOT NULL DEFAULT '',
  received_at timestamptz NOT NULL
);
CREATE INDEX skeleton_ping_geometry_gist ON skeleton_ping USING gist (geometry);
CREATE VIEW geo.skeleton_pings AS
  SELECT id, observed_at, note, geometry FROM public.skeleton_ping;
```

c) Drift

```dart
class SkeletonPings extends Table {
  TextColumn get id => text()();                 // UUID v4
  DateTimeColumn get observedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get note => text().withDefault(const Constant(''))();
  BoolColumn get sent => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}
```
Difference: the phone stores lat/lon, and the server builds `Point(lon, lat)`.

d) Django limitation: none beyond T004.

**Limitations / out of scope / risks**
This is deliberately throwaway. Its value is finding integration problems in week 1 (GDAL in the image, pygeoapi with views, phone networking).

---

### T008 · CI pipeline (GitHub Actions)
**ID:** T008 · **Implements:** F46 · **Labels:** `infra`, `must` · **Milestone:** Phase 1 · **Epic:** E01 · **Depends on:** T003, T006 · **Estimate:** 1 d

**Description**
Run backend and mobile checks on every push and PR.

**Acceptance criteria**
- [ ] Workflow `backend.yml`:
  - service container `mobilitydb/mobilitydb:17-3.5-1.3`
  - installs GDAL
  - runs `ruff check`, `pytest`, `python manage.py makemigrations --check`, and `python manage.py spectacular --validate --file /tmp/schema.yaml`
- [ ] Workflow `mobile.yml`: `flutter analyze`, `flutter test`, `dart run drift_dev schema verify` (or equivalent migration test), `flutter build apk --debug`. The APK is uploaded as a workflow artifact.
- [ ] Both workflows use path filters (`backend/**`, `mobile/**`).
- [ ] A status badge is in the README.

**Technical explanation**
The APK artifact replaces a release process (F83 removed): download it from the Actions run and install it with `adb install`.

**Limitations / out of scope / risks**
- No CD (F82 removed): the laptop is the server.

---

### T009 · Phone-to-laptop connectivity: Tailscale and USB
**ID:** T009 · **Implements:** F44 · **Labels:** `infra`, `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E01 · **Depends on:** T002, T006 · **Estimate:** 1 d

**Description**
Make the phone reach the laptop over HTTPS from anywhere using Tailscale, with USB as an offline fallback for demos.

**Acceptance criteria**
- [ ] `docs/setup/tailscale.md` describes:
  - installing Tailscale on CachyOS and on the phone
  - enabling MagicDNS and **HTTPS Certificates** in the admin console
  - running `sudo tailscale serve --bg https / http://localhost:8080` (VERIFY flag syntax for your version)
- [ ] Django settings read:
  - `ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS` from env (including `<laptop>.<tailnet>.ts.net`)
  - `SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")`
  - `USE_X_FORWARDED_HOST = True`
- [ ] nginx forwards `X-Forwarded-Proto` and `X-Forwarded-Host` received from Tailscale serve. Django admin login works through the `ts.net` URL.
- [ ] The Android dev flavour has `network_security_config.xml` allowing cleartext **only** to `localhost`, for the USB route `adb reverse tcp:8080 tcp:8080`.
- [ ] From the phone on mobile data (Wi-Fi off), "Test connection" succeeds via Tailscale.

**Technical explanation**
Tailscale serve terminates TLS with a real certificate for the `ts.net` name, so Android trusts it without a custom CA. Only devices on your tailnet can reach it.

**Limitations / out of scope / risks**
- The phone must have the Tailscale app connected while it syncs. Offline-first means this only matters at sync time.
- If `tailscale serve` header behaviour differs, set the forwarded headers explicitly in nginx (VERIFY during this ticket).

---

### T010 · Backup and restore scripts
**ID:** T010 · **Implements:** F46 · **Labels:** `infra`, `must` · **Milestone:** Phase 1 · **Epic:** E01 · **Depends on:** T002 · **Estimate:** 1 d

**Description**
One command backs up the database and photos to a folder (for example an external disk). One command restores them into a clean stack.

**Acceptance criteria**
- [ ] `scripts/backup.sh <target-dir>`:
  - runs `pg_dump -Fc butterfly` (plus `frost` once it exists)
  - mirrors the MinIO `photos` bucket using `mc mirror` from the `minio/mc` image
  - writes `manifest.json` (time, git commit, migration head)
  - keeps the last 7 backups
- [ ] `scripts/restore.sh <backup-dir>` restores into an empty stack (`docker compose down -v && up`).
- [ ] A restore test is documented in `docs/setup/backup.md`: back up, wipe, restore, check row counts and that a photo opens in admin.
- [ ] The backup can optionally be encrypted (`age` or `gpg`) when a key is set in `.env` (outline §22).

**Technical explanation**
Plain shell plus `docker compose exec`. The `mc` client runs as a one-off container on the Compose network.

**Limitations / out of scope / risks**
- No scheduled backups. Run it manually before demos and after field sessions.
- **p2-compat:** restoring MobilityDB data in Phase 2 needs the same MobilityDB version (1.3) in the target image.

---
## E02 · Accounts, roles, projects and audit

### E02 · Epic: Accounts, roles, projects and audit
**Labels:** `epic`, `backend`, `admin` · **Milestone:** Phase 1 · **Implements:** F1, F2, F3, F4, F62, F71, F72, F73
Email/password login with JWT, the two roles, projects with members, per-project protocol settings and study area, the admin site foundation and the audit log.
Children: T011 · T012 · T013 · T014 · T015 · T016 · T017 · T018

---

### T011 · Custom user model and JWT auth endpoints
**ID:** T011 · **Implements:** F1 · **Labels:** `backend`, `security`, `must` · **Milestone:** Phase 1 · **Epic:** E02 · **Depends on:** T003 · **Estimate:** 1.5 d

**Description**
Users log in with email and password and receive a JWT access/refresh pair. Logout blacklists the refresh token.

**Acceptance criteria**
- [ ] `accounts.User` uses `email` as the login, a UUID primary key and the fields `name` and `organization`. It is created in the **first** migration of the project.
- [ ] `POST /api/v1/auth/login` with `{email, password}` returns `{access, refresh, user}`.
- [ ] `POST /api/v1/auth/refresh` rotates the refresh token and blacklists the old one.
- [ ] `POST /api/v1/auth/logout` with `{refresh}` blacklists it and returns 205.
- [ ] `GET /api/v1/auth/me` returns `{id, email, name, organization, groups: ["researcher"|"admin"], project_ids: [...]}`.
- [ ] Inactive users cannot log in. Five failed logins per email within 15 minutes return 429 (cache-based counter).
- [ ] Tests cover login, refresh rotation, logout blacklist, and an inactive user.

**Technical explanation**
- simplejwt settings:
  - `ACCESS_TOKEN_LIFETIME = 15 min`
  - `REFRESH_TOKEN_LIFETIME = 30 days`
  - `ROTATE_REFRESH_TOKENS = True`
  - `BLACKLIST_AFTER_ROTATION = True`
  - `rest_framework_simplejwt.token_blacklist` added to `INSTALLED_APPS`
- `USER_ID_FIELD = "id"`.
- The login serializer subclasses `TokenObtainPairSerializer` and adds the `user` payload.

**Database**

a) GeoDjango model

```python
# backend/accounts/models.py
import uuid
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, email, password=None, **extra):
        email = self.normalize_email(email)
        user = self.model(email=email, **extra)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra):
        extra.setdefault("is_staff", True)
        extra.setdefault("is_superuser", True)
        return self.create_user(email, password, **extra)


class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    username = None
    first_name = None
    last_name = None
    email = models.EmailField(unique=True)
    name = models.CharField(max_length=150)
    organization = models.CharField(max_length=200, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["name"]
    objects = UserManager()

    class Meta:
        db_table = "app_user"
```

b) PostGIS DDL (as generated; the auth M2M tables are omitted)

```sql
CREATE TABLE app_user (
  id            uuid PRIMARY KEY,
  password      varchar(128) NOT NULL,
  last_login    timestamptz NULL,
  is_superuser  boolean NOT NULL,
  email         varchar(254) NOT NULL UNIQUE,
  name          varchar(150) NOT NULL,
  organization  varchar(200) NOT NULL,
  is_staff      boolean NOT NULL,
  is_active     boolean NOT NULL,
  date_joined   timestamptz NOT NULL,
  updated_at    timestamptz NOT NULL
);
-- plus app_user_groups, app_user_user_permissions (Django M2M),
-- token_blacklist_outstandingtoken, token_blacklist_blacklistedtoken (simplejwt)
```

c) Drift: none. The current user's profile (`/auth/me`) is cached as JSON in `flutter_secure_storage` next to the tokens.

d) Django-specific limitation
- The custom user model must exist before the first `migrate`. Switching later is a painful manual migration.
- `email` uniqueness is case-sensitive in PostgreSQL. The manager normalises the domain only, so add a functional unique index on `lower(email)` (`UniqueConstraint(Lower("email"), name="app_user_email_ci")`).

**Limitations / out of scope / risks**
- No password reset by email (no mail server). Admins reset passwords in Django admin.
- No biometric unlock (F88 removed).

---

### T012 · App login, secure token storage, refresh and logout
**ID:** T012 · **Implements:** F1 · **Labels:** `mobile`, `security`, `must` · **Milestone:** Phase 1 · **Epic:** E02 · **Depends on:** T006, T011 · **Estimate:** 2 d

**Description**
Build the login screen and session handling that keep working offline after the first login.

**Acceptance criteria**
- [ ] The login screen has email and password fields, shows errors, and shows the **last successful sync time** (outline §11.2 A).
- [ ] Tokens and the `/auth/me` profile are stored in `flutter_secure_storage` (Android Keystore-backed).
- [ ] A dio interceptor refreshes the access token on 401 exactly once, with concurrent requests waiting on the same refresh. If refresh fails, it goes to the login screen without deleting local data.
- [ ] **Offline start:** if a refresh token and cached profile exist, the app opens without network. Login is only required when no session exists.
- [ ] On logout, if local unsynced changes exist, the app warns "N changes not yet synced" and offers sync first. Logout never deletes the local database. A separate "Remove all local data" option in settings has a confirmation step.
- [ ] Widget tests cover the login form validation and the interceptor refresh.

**Technical explanation**
Riverpod `authStateProvider` holds `unauthenticated | authenticated(profile) | offline(profile)`, and go_router redirects based on it.

**Limitations / out of scope / risks**
- If the refresh token expires while the phone is offline for more than 30 days, the user must log in online once. Unsynced data is kept.

---

### T013 · Two roles: groups, permissions and access rules
**ID:** T013 · **Implements:** F2, F62 · **Labels:** `backend`, `admin`, `security`, `must` · **Milestone:** Phase 1 · **Epic:** E02 · **Depends on:** T011 · **Estimate:** 1.5 d

**Description**
Create the `researcher` and `admin` groups and enforce them in DRF and Django admin, using only built-in permissions.

**Acceptance criteria**
- [ ] A data migration creates groups `researcher` (no model permissions; app only) and `admin` (all permissions of this project's apps). A later migration helper `sync_admin_group_permissions()` re-grants after new models are added. It runs in a `post_migrate` signal.
- [ ] Adding a user to `admin` sets `is_staff=True`, and removing them sets it back to `False` (`m2m_changed` signal). Researchers cannot log into `/admin/` (tested).
- [ ] DRF permission classes:
  - `IsAdminGroup`
  - `IsProjectMember` (object or `project_id` in payload)
  - `IsOwnerOrAdmin` (record `created_by == request.user`)
- [ ] Admin-only endpoints (exports, auth verify for pygeoapi) return 403 for researchers (tested).
- [ ] An admin who uses the app behaves exactly like a researcher there (sees own records), plus can see all projects.

**Technical explanation**
- Membership checks query `ProjectMembership` (T015). Admins bypass membership checks.
- Django admin needs no per-project `get_queryset()` scoping, because only admins enter it (v4 simplification).

**Limitations / out of scope / risks**
- Superuser accounts bypass groups. Create one for setup, and do daily work as a normal admin-group user so permission tests reflect reality.

---

### T014 · Django admin foundation
**ID:** T014 · **Implements:** F62 · **Labels:** `admin`, `must` · **Milestone:** Phase 1 · **Epic:** E02 · **Depends on:** T013 · **Estimate:** 1 d

**Description**
Brand the admin site and provide base ModelAdmin classes that every later admin uses.

**Acceptance criteria**
- [ ] `admin.site.site_header = "Butterfly Monitoring"`, plus `site_title` and `index_title`. A small CSS override provides logo and colours (template override of `admin/base_site.html` only).
- [ ] App sections are ordered: Projects, Transects, Visits & observations, Plants & habitat, Validation, Sync, Catalogues, Users. This is done via `AdminSite.get_app_list` override (Django 4.1+ supports `app_label` ordering; VERIFY).
- [ ] `SyncableAdmin` base:
  - `server_version`, `created_*` and `updated_*` are read-only
  - list filter "Deleted" (yes/no)
  - action "Soft delete selected" replaces the built-in delete action
  - `has_delete_permission` returns `False`
- [ ] `MapAdmin(GISModelAdmin)` base with an OSM base layer, centred on the project area when known.
- [ ] Both bases combine with `SimpleHistoryAdmin` (T018).

**Technical explanation**
`GISModelAdmin` (Django 4.0+) uses OpenLayers with an OSM layer by default. Set `gis_widget_kwargs = {"attrs": {"default_zoom": 13}}`.

**Limitations / out of scope / risks**
- Only small template overrides. No custom admin frontend (user constraint).

---

### T015 · Project and membership models, API and admin
**ID:** T015 · **Implements:** F3 · **Labels:** `backend`, `admin`, `database`, `must` · **Milestone:** Phase 1 · **Epic:** E02 · **Depends on:** T005, T013, T014 · **Estimate:** 2 d

**Description**
Admins create projects and add researchers or admins as members. Researchers see only their projects.

**Acceptance criteria**
- [ ] `Project` and `ProjectMembership` models with admin: a project change form with a `ProjectMembership` inline (user autocomplete).
- [ ] `GET /api/v1/projects` returns the caller's projects (all projects for admins), with `transect_count` and `period`.
- [ ] `GET /api/v1/projects/{id}` returns 404 for non-members (not 403, so project existence isn't leaked).
- [ ] Removing a membership hides the project from that user's next pull. Local data on their phone is not deleted (documented).
- [ ] Projects are synced (pull, T025) to members.

**Database**

a) GeoDjango model

```python
# backend/projects/models.py
from django.conf import settings
from django.contrib.gis.db import models
from simple_history.models import HistoricalRecords
from core.models import SyncableModel


class Project(SyncableModel):
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT,
                              related_name="owned_projects")
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    default_crs = models.PositiveIntegerField(default=4326)  # EPSG code, outline §8.1
    active = models.BooleanField(default=True)
    # added by later tickets: area (T016), taxon_list_version (T019)
    history = HistoricalRecords(table_name="historical_project")

    class Meta:
        db_table = "project"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(end_date__isnull=True) | models.Q(end_date__gte=models.F("start_date")),
                name="project_dates_ok"),
        ]

    def __str__(self):
        return self.name


class ProjectMembership(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name="memberships")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
                             related_name="memberships")
    added_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT,
                                 null=True, related_name="+")
    created_at = models.DateTimeField(auto_now_add=True)
    history = HistoricalRecords(table_name="historical_project_membership")

    class Meta:
        db_table = "project_membership"
        constraints = [models.UniqueConstraint(fields=["project", "user"],
                                               name="project_membership_unique")]
```

b) PostGIS DDL

```sql
CREATE TABLE project (
  id              uuid PRIMARY KEY,
  server_version  bigint NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL,
  updated_at      timestamptz NOT NULL,
  deleted_at      timestamptz NULL,
  created_by_id   uuid NULL REFERENCES app_user(id),
  updated_by_id   uuid NULL REFERENCES app_user(id),
  name            varchar(200) NOT NULL,
  description     text NOT NULL,
  owner_id        uuid NOT NULL REFERENCES app_user(id),
  start_date      date NOT NULL,
  end_date        date NULL,
  default_crs     integer NOT NULL DEFAULT 4326 CHECK (default_crs >= 0),
  active          boolean NOT NULL DEFAULT true,
  CONSTRAINT project_dates_ok CHECK (end_date IS NULL OR end_date >= start_date)
);
CREATE INDEX project_server_version_idx ON project (server_version);
CREATE TRIGGER trg_project_server_version BEFORE INSERT OR UPDATE ON project
  FOR EACH ROW EXECUTE FUNCTION bump_server_version();

CREATE TABLE project_membership (
  id          bigserial PRIMARY KEY,
  project_id  uuid NOT NULL REFERENCES project(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
  added_by_id uuid NULL REFERENCES app_user(id),
  created_at  timestamptz NOT NULL,
  CONSTRAINT project_membership_unique UNIQUE (project_id, user_id)
);
```

c) Drift

```dart
class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get defaultCrs => integer().withDefault(const Constant(4326))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get areaGeojson => text().nullable()();          // T016
  TextColumn get taxonListVersionId => text().nullable()();   // T019
  // local sync columns
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  // local-only package state (T031)
  DateTimeColumn get packageDownloadedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```
Differences from the server:
- `owner` and the audit columns are not stored locally.
- Memberships are not stored. Only projects the user can access are pulled.
- `packageDownloadedAt` is local-only.

d) Django-specific limitation
`ProjectMembership` uses a bigint PK and is **not** synced, so it has no UUID or trigger. Membership changes reach the phone indirectly, because pull scopes rows by membership.

**Limitations / out of scope / risks**
- No per-project roles. Global groups are enough (v4 decision).

---

### T016 · Project protocol settings and study area
**ID:** T016 · **Implements:** F71, F73 · **Labels:** `backend`, `admin`, `database`, `must` · **Milestone:** Phase 1 · **Epic:** E02 · **Depends on:** T015, T001 · **Estimate:** 1.5 d

**Description**
Admins configure each project's survey protocol (season, time window, weather thresholds, GPS and flag thresholds) and draw the study-area polygon. Validation (T055), flags (T056) and the app read these values instead of hard-coded constants.

**Acceptance criteria**
- [ ] A `ProjectProtocol` one-to-one model, edited as an inline on the project admin. Defaults come from T001. Creating a project auto-creates its protocol (signal).
- [ ] `Project.area` (MultiPolygon, optional) is drawn in the admin map widget or uploaded as GeoJSON/KML via an admin action.
- [ ] Both are included in pull, and the app shows a protocol summary on the transect detail screen (T033).
- [ ] Changing a threshold changes the next flag computation (tested with T056).

**Database**

a) GeoDjango model

```python
# backend/projects/models.py (continued)
from decimal import Decimal

class Project(SyncableModel):
    ...
    area = models.MultiPolygonField(srid=4326, null=True, blank=True)


class SurveyMethod(models.TextChoices):
    POLLARD_WALK = "pollard_walk", "Pollard walk"
    OTHER = "other", "Other"


class ProjectProtocol(SyncableModel):
    project = models.OneToOneField(Project, on_delete=models.CASCADE, related_name="protocol")
    protocol_version = models.CharField(max_length=20, default="1.0")
    survey_method = models.CharField(max_length=20, choices=SurveyMethod.choices,
                                     default=SurveyMethod.POLLARD_WALK)
    season_start = models.DateField()
    season_end = models.DateField()
    day_start_time = models.TimeField(default="10:00")
    day_end_time = models.TimeField(default="17:00")
    min_temperature_c = models.DecimalField(max_digits=4, decimal_places=1, default=Decimal("13.0"))
    sunny_temperature_c = models.DecimalField(max_digits=4, decimal_places=1, default=Decimal("17.0"))
    max_cloud_cover_pct_if_cool = models.PositiveSmallIntegerField(default=40)
    max_wind_beaufort = models.PositiveSmallIntegerField(default=5)
    allow_precipitation = models.BooleanField(default=False)
    target_visits_per_season = models.PositiveSmallIntegerField(default=8)
    max_distance_from_transect_m = models.DecimalField(max_digits=6, decimal_places=1, default=Decimal("20.0"))
    observation_time_tolerance_min = models.PositiveSmallIntegerField(default=5)
    gps_interval_s = models.PositiveSmallIntegerField(default=5)
    gps_interval_battery_saver_s = models.PositiveSmallIntegerField(default=15)
    gps_accuracy_warning_m = models.DecimalField(max_digits=6, decimal_places=1, default=Decimal("25.0"))
    gps_gap_s = models.PositiveSmallIntegerField(default=60)
    high_count_threshold = models.PositiveIntegerField(default=50)
    min_coverage_pct = models.PositiveSmallIntegerField(default=80)
    history = HistoricalRecords(table_name="historical_project_protocol")

    class Meta:
        db_table = "project_protocol"
        constraints = [
            models.CheckConstraint(condition=models.Q(season_end__gte=models.F("season_start")),
                                   name="protocol_season_ok"),
            models.CheckConstraint(condition=models.Q(day_end_time__gt=models.F("day_start_time")),
                                   name="protocol_day_window_ok"),
            models.CheckConstraint(condition=models.Q(max_wind_beaufort__lte=12),
                                   name="protocol_wind_ok"),
            models.CheckConstraint(condition=models.Q(max_cloud_cover_pct_if_cool__lte=100)
                                   & models.Q(min_coverage_pct__lte=100),
                                   name="protocol_pct_ok"),
            models.CheckConstraint(condition=models.Q(gps_interval_s__gte=1)
                                   & models.Q(gps_interval_battery_saver_s__gte=models.F("gps_interval_s")),
                                   name="protocol_gps_interval_ok"),
        ]
```

b) PostGIS DDL

```sql
ALTER TABLE project ADD COLUMN area geometry(MultiPolygon, 4326) NULL;
CREATE INDEX project_area_gist ON project USING gist (area);

CREATE TABLE project_protocol (
  id                              uuid PRIMARY KEY,
  server_version                  bigint NOT NULL DEFAULT 0,
  created_at                      timestamptz NOT NULL,
  updated_at                      timestamptz NOT NULL,
  deleted_at                      timestamptz NULL,
  created_by_id                   uuid NULL REFERENCES app_user(id),
  updated_by_id                   uuid NULL REFERENCES app_user(id),
  project_id                      uuid NOT NULL UNIQUE REFERENCES project(id) ON DELETE CASCADE,
  protocol_version                varchar(20) NOT NULL,
  survey_method                   varchar(20) NOT NULL
                                  CHECK (survey_method IN ('pollard_walk','other')),
  season_start                    date NOT NULL,
  season_end                      date NOT NULL,
  day_start_time                  time NOT NULL,
  day_end_time                    time NOT NULL,
  min_temperature_c               numeric(4,1) NOT NULL,
  sunny_temperature_c             numeric(4,1) NOT NULL,
  max_cloud_cover_pct_if_cool     smallint NOT NULL,
  max_wind_beaufort               smallint NOT NULL,
  allow_precipitation             boolean NOT NULL,
  target_visits_per_season        smallint NOT NULL,
  max_distance_from_transect_m    numeric(6,1) NOT NULL,
  observation_time_tolerance_min  smallint NOT NULL,
  gps_interval_s                  smallint NOT NULL,
  gps_interval_battery_saver_s    smallint NOT NULL,
  gps_accuracy_warning_m          numeric(6,1) NOT NULL,
  gps_gap_s                       smallint NOT NULL,
  high_count_threshold            integer NOT NULL,
  min_coverage_pct                smallint NOT NULL,
  CONSTRAINT protocol_season_ok        CHECK (season_end >= season_start),
  CONSTRAINT protocol_day_window_ok    CHECK (day_end_time > day_start_time),
  CONSTRAINT protocol_wind_ok          CHECK (max_wind_beaufort <= 12),
  CONSTRAINT protocol_pct_ok           CHECK (max_cloud_cover_pct_if_cool <= 100 AND min_coverage_pct <= 100),
  CONSTRAINT protocol_gps_interval_ok  CHECK (gps_interval_s >= 1 AND gps_interval_battery_saver_s >= gps_interval_s)
);
CREATE INDEX project_protocol_server_version_idx ON project_protocol (server_version);
CREATE TRIGGER trg_project_protocol_server_version BEFORE INSERT OR UPDATE ON project_protocol
  FOR EACH ROW EXECUTE FUNCTION bump_server_version();
```

c) Drift

```dart
class ProjectProtocols extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get protocolVersion => text()();
  TextColumn get surveyMethod => text()();
  DateTimeColumn get seasonStart => dateTime()();
  DateTimeColumn get seasonEnd => dateTime()();
  TextColumn get dayStartTime => text()();   // 'HH:MM'
  TextColumn get dayEndTime => text()();
  RealColumn get minTemperatureC => real()();
  RealColumn get sunnyTemperatureC => real()();
  IntColumn get maxCloudCoverPctIfCool => integer()();
  IntColumn get maxWindBeaufort => integer()();
  BoolColumn get allowPrecipitation => boolean()();
  IntColumn get targetVisitsPerSeason => integer()();
  RealColumn get maxDistanceFromTransectM => real()();
  IntColumn get observationTimeToleranceMin => integer()();
  IntColumn get gpsIntervalS => integer()();
  IntColumn get gpsIntervalBatterySaverS => integer()();
  RealColumn get gpsAccuracyWarningM => real()();
  IntColumn get gpsGapS => integer()();
  IntColumn get highCountThreshold => integer()();
  IntColumn get minCoveragePct => integer()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```
Differences from the server:
- Decimals are stored as `real`.
- Times are stored as `'HH:MM'` text (SQLite has no time type).
- `Project.area` is stored as `projects.area_geojson` (MultiPolygon GeoJSON).
- The table is read-only on the phone.

d) Django-specific limitation
- `CheckConstraint(condition=...)` is the Django 5.1+ spelling (older versions use `check=`).
- Changing defaults does not change existing rows.

**Limitations / out of scope / risks**
- Protected areas and administrative boundary layers (outline §9.1) are out; only the project boundary is supported.

---

### T017 · App project list and project home
**ID:** T017 · **Implements:** F3, F72 · **Labels:** `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E02 · **Depends on:** T012, T015 (badges fill in once T029 and T031 land) · **Estimate:** 1.5 d

**Description**
After login, the user picks a project and lands on the project home, the hub for all field work.

**Acceptance criteria**
- [ ] The project list (outline §11.2 B) shows each project's name, period, number of downloaded transects, number of unsynced changes and offline package status (`not downloaded` / `ready` / `update available`).
- [ ] Project home tiles (outline §11.2 C, minus the validation tab): **Start visit**, **Transects**, **Free observation**, **Plants & habitat**, **Map**, **Unsynced data** (with badge), **Statistics**.
- [ ] The last selected project is remembered.
- [ ] Everything works offline once the package is downloaded.

**Technical explanation**
Counts come from Drift queries. Package status comes from T031.

**Limitations / out of scope / risks**
- No in-app validation tab (F76 removed). Validation happens in Django admin only.

---

### T018 · Audit log with django-simple-history
**ID:** T018 · **Implements:** F4 · **Labels:** `backend`, `admin`, `must` · **Milestone:** Phase 1 · **Epic:** E02 · **Depends on:** T015 · **Estimate:** 1.5 d

**Description**
Record who changed what, when, from which value to which value, and why (outline §13.3).

**Decision (justified):** **django-simple-history** over django-auditlog:
1. It stores a full row snapshot per change, so the state of an observation at any past `server_version` can be read. T027 needs this for field-level conflict checks.
2. It has a built-in `history_change_reason`, which covers the mandatory reasons for lock/unlock (T043) and validation (T057).
3. `SimpleHistoryAdmin` gives a history view per object with no extra code.

django-auditlog's single JSON-diff table is lighter but cannot cheaply rebuild past row states.

**Acceptance criteria**
- [ ] `HistoricalRecords(table_name="historical_<table>")` is on Project, ProjectMembership, ProjectProtocol, Transect, TransectSection, Taxon, PlantTaxon, HabitatType, ManagementType, SurveyVisit, ButterflyObservation, Photo, PlantResourceObservation, HabitatFeature, SyncConflict. Each later model ticket adds its own line, and this ticket adds it to the models that exist now.
- [ ] `simple_history.middleware.HistoryRequestMiddleware` is installed. Changes made through DRF (JWT) record `history_user` (tested: DRF sets the user on the underlying request; VERIFY with the installed version).
- [ ] A service helper `save_with_reason(obj, user, reason)` sets `obj._change_reason`.
- [ ] Admin classes inherit `SimpleHistoryAdmin`. **Revert is disabled** (`history_revert` off via `has_change_permission` on the history view, or by overriding `history_form_view`) because reverting would bypass sync versioning.
- [ ] Test: changing an observation's taxon produces a history row with old and new taxon, user, timestamp and reason.

**Database**

a) Model code: add `history = HistoricalRecords(table_name="historical_<table>")` to each model (shown in each model ticket).

b) PostGIS DDL (example; every historical table has the same pattern)

```sql
CREATE TABLE historical_project (
  -- all columns of project, without constraints/uniques:
  id uuid NOT NULL, server_version bigint NOT NULL, created_at timestamptz NOT NULL,
  updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL, updated_by_id uuid NULL, name varchar(200) NOT NULL,
  description text NOT NULL, owner_id uuid NULL, start_date date NOT NULL, end_date date NULL,
  default_crs integer NOT NULL, active boolean NOT NULL,
  area geometry(MultiPolygon, 4326) NULL,
  -- history columns:
  history_id            serial PRIMARY KEY,
  history_date          timestamptz NOT NULL,
  history_change_reason varchar(100) NULL,
  history_type          varchar(1) NOT NULL CHECK (history_type IN ('+','~','-')),
  history_user_id       uuid NULL REFERENCES app_user(id) ON DELETE SET NULL
);
CREATE INDEX ON historical_project (id);
CREATE INDEX ON historical_project (history_date);
CREATE INDEX ON historical_project (id, server_version);   -- added by T027 for snapshot lookup
```

c) Drift: none. The audit log is server-only.

d) Django-specific limitations
- simple-history does **not** record `QuerySet.update()` or `bulk_update()`. Services must save instances one by one on audited models (enforced in code review; a test greps for `.update(` in services).
- Historical rows copy `server_version` *as Django saw it*, which is stale (T005). Add `post_create_historical_record` handling that reads the fresh value (`refresh_from_db`) before the historical row is written, or set the history row's version in a signal (VERIFY the signal order in this ticket).
- `history_change_reason` max length is 100 by default. Configure `SIMPLE_HISTORY_HISTORY_CHANGE_REASON_USE_TEXT_FIELD = True` for longer reasons.

**Limitations / out of scope / risks**
- No access-audit log (who *viewed* a record). It was only needed for sensitive species (F5 removed).

---
## E03 · Catalogues and transects

### E03 · Epic: Catalogues and transects
**Labels:** `epic`, `backend`, `admin`, `database` · **Milestone:** Phase 1 · **Implements:** F6, F18, F22, F63, F64, F79
Versioned butterfly list, plant list, habitat/management codelists, transects with sections, a map editor in admin, and seed data.
Children: T019 · T020 · T021 · T022 · T023 · T024

---

### T019 · Taxon catalogue, versioned
**ID:** T019 · **Implements:** F18 · **Labels:** `backend`, `database`, `must` · **Milestone:** Phase 1 · **Epic:** E03 · **Depends on:** T005, T015 · **Estimate:** 2 d

**Description**
Store butterfly taxa with accepted-name relations, in a way that never rewrites history: observations always point to the exact taxon row used at the time, and each project records which list release it uses.

**Acceptance criteria**
- [ ] `TaxonListVersion` and `Taxon` models with admin (search by scientific and vernacular names).
- [ ] **Versioning rule:**
  - a rename or synonymisation creates a new `Taxon` row
  - the old row gets `retired_in = <new version>` and `accepted_name = <new row>`
  - `scientific_name` is read-only in admin after creation (tested)
- [ ] Exactly one `TaxonListVersion` has `is_current = true` (partial unique index).
- [ ] `Project.taxon_list_version` FK is added. New projects default to the current version.
- [ ] Taxa reach the phone by pull: all taxa where `retired_in IS NULL` or that are referenced by the user's own observations.
- [ ] `photo_required` flag per taxon, used by rule W01 in T055.

**Database**

a) GeoDjango model

```python
# backend/catalogues/models.py
from django.db import models
from simple_history.models import HistoricalRecords
from core.models import SyncableModel


class TaxonListVersion(SyncableModel):
    version_label = models.CharField(max_length=30, unique=True)   # e.g. "2026.1"
    source = models.CharField(max_length=200)                       # e.g. "GBIF Backbone, Serbia, reviewed"
    published_at = models.DateTimeField()
    is_current = models.BooleanField(default=False)
    notes = models.TextField(blank=True)

    class Meta:
        db_table = "taxon_list_version"
        constraints = [models.UniqueConstraint(fields=["is_current"], condition=models.Q(is_current=True),
                                               name="taxon_list_version_one_current")]


class TaxonRank(models.TextChoices):
    FAMILY = "family"; GENUS = "genus"; SPECIES_GROUP = "species_group"
    SPECIES = "species"; SUBSPECIES = "subspecies"


class TaxonSource(models.TextChoices):
    GBIF = "gbif"; MANUAL = "manual"


class Taxon(SyncableModel):
    scientific_name = models.CharField(max_length=200)
    author = models.CharField(max_length=200, blank=True)
    rank = models.CharField(max_length=20, choices=TaxonRank.choices, default=TaxonRank.SPECIES)
    genus = models.CharField(max_length=100, blank=True)
    family = models.CharField(max_length=100, blank=True)
    vernacular_name_sr = models.CharField(max_length=200, blank=True)
    vernacular_name_en = models.CharField(max_length=200, blank=True)
    accepted_name = models.ForeignKey("self", on_delete=models.PROTECT, null=True, blank=True,
                                      related_name="synonyms")
    taxon_source = models.CharField(max_length=10, choices=TaxonSource.choices, default=TaxonSource.GBIF)
    taxon_source_id = models.CharField(max_length=50, blank=True)
    introduced_in = models.ForeignKey(TaxonListVersion, on_delete=models.PROTECT, related_name="introduced_taxa")
    retired_in = models.ForeignKey(TaxonListVersion, on_delete=models.PROTECT, null=True, blank=True,
                                   related_name="retired_taxa")
    active = models.BooleanField(default=True)
    photo_required = models.BooleanField(default=False)
    identification_notes = models.TextField(blank=True)
    history = HistoricalRecords(table_name="historical_taxon")

    class Meta:
        db_table = "taxon"
        constraints = [
            models.UniqueConstraint(fields=["scientific_name", "rank", "introduced_in"], name="taxon_unique_name"),
            models.CheckConstraint(condition=models.Q(rank__in=TaxonRank.values), name="taxon_rank_valid"),
            models.CheckConstraint(condition=models.Q(taxon_source__in=TaxonSource.values), name="taxon_source_valid"),
            models.CheckConstraint(condition=~models.Q(accepted_name=models.F("id")), name="taxon_not_self_synonym"),
        ]
        indexes = [models.Index(fields=["scientific_name"]), models.Index(fields=["family", "genus"])]


# projects/models.py: added in this ticket's migration
# taxon_list_version = models.ForeignKey("catalogues.TaxonListVersion", on_delete=models.PROTECT, null=True)
```

b) PostGIS DDL

```sql
CREATE TABLE taxon_list_version (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  version_label varchar(30) NOT NULL UNIQUE,
  source        varchar(200) NOT NULL,
  published_at  timestamptz NOT NULL,
  is_current    boolean NOT NULL DEFAULT false,
  notes         text NOT NULL
);
CREATE UNIQUE INDEX taxon_list_version_one_current ON taxon_list_version (is_current) WHERE is_current;

CREATE TABLE taxon (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  scientific_name      varchar(200) NOT NULL,
  author               varchar(200) NOT NULL,
  rank                 varchar(20) NOT NULL
                       CONSTRAINT taxon_rank_valid CHECK (rank IN ('family','genus','species_group','species','subspecies')),
  genus                varchar(100) NOT NULL,
  family               varchar(100) NOT NULL,
  vernacular_name_sr   varchar(200) NOT NULL,
  vernacular_name_en   varchar(200) NOT NULL,
  accepted_name_id     uuid NULL REFERENCES taxon(id),
  taxon_source         varchar(10) NOT NULL CONSTRAINT taxon_source_valid CHECK (taxon_source IN ('gbif','manual')),
  taxon_source_id      varchar(50) NOT NULL,
  introduced_in_id     uuid NOT NULL REFERENCES taxon_list_version(id),
  retired_in_id        uuid NULL REFERENCES taxon_list_version(id),
  active               boolean NOT NULL DEFAULT true,
  photo_required       boolean NOT NULL DEFAULT false,
  identification_notes text NOT NULL,
  CONSTRAINT taxon_unique_name UNIQUE (scientific_name, rank, introduced_in_id),
  CONSTRAINT taxon_not_self_synonym CHECK (accepted_name_id IS DISTINCT FROM id)
);
CREATE INDEX taxon_scientific_name_idx ON taxon (scientific_name);
CREATE INDEX taxon_family_genus_idx ON taxon (family, genus);
CREATE INDEX taxon_server_version_idx ON taxon (server_version);
-- + triggers trg_taxon_list_version_server_version, trg_taxon_server_version

ALTER TABLE project ADD COLUMN taxon_list_version_id uuid NULL REFERENCES taxon_list_version(id);
```

c) Drift

```dart
class Taxa extends Table {
  TextColumn get id => text()();
  TextColumn get scientificName => text()();
  TextColumn get author => text().withDefault(const Constant(''))();
  TextColumn get rank => text()();
  TextColumn get genus => text().withDefault(const Constant(''))();
  TextColumn get family => text().withDefault(const Constant(''))();
  TextColumn get vernacularNameSr => text().withDefault(const Constant(''))();
  TextColumn get vernacularNameEn => text().withDefault(const Constant(''))();
  TextColumn get acceptedNameId => text().nullable()();
  BoolColumn get active => boolean()();
  BoolColumn get retired => boolean().withDefault(const Constant(false))();
  BoolColumn get photoRequired => boolean().withDefault(const Constant(false))();
  TextColumn get identificationNotes => text().withDefault(const Constant(''))();
  // search helper: lower-case, diacritics stripped (č→c, ć→c, š→s, ž→z, đ→dj)
  TextColumn get searchText => text()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```
Differences from the server:
- `introduced_in` and `retired_in` collapse to a `retired` bool.
- `searchText` is local-only, built on pull.
- `taxon_list_version` is not stored locally beyond `projects.taxonListVersionId`.

d) Django-specific limitation
- The partial unique index (`condition=`) works on PostgreSQL only, which is fine here.
- `CheckConstraint` with `~Q(accepted_name=F("id"))` compiles to `NOT (accepted_name_id = id)`. That is NULL-safe in a CHECK because NULL passes.

**Limitations / out of scope / risks**
- **No distribution or phenology data**, so the "species outside range" and "unusual date" flags are out.
- The GBIF-based list is a working list, not an authoritative checklist. Say so in the thesis.

---

### T020 · Plant taxa and editable codelists
**ID:** T020 · **Implements:** F22, F64 · **Labels:** `backend`, `database`, `must` · **Milestone:** Phase 1 · **Epic:** E03 · **Depends on:** T005 · **Estimate:** 1.5 d

**Description**
*Must because transect sections need habitat types. The plant part (F22) is cheap and ships with it.*
Add the plant list used for host and nectar records, and the two codelists admins can edit: habitat types and management types. All other value lists are fixed enums in code (T001), because app logic depends on their values.

**Acceptance criteria**
- [ ] `PlantTaxon`, `HabitatType` and `ManagementType` models with admin.
- [ ] All three are pulled to the phone (active rows, plus inactive rows referenced by the user's records).
- [ ] Deactivating a value hides it from pickers but keeps it on existing records (tested in app and API).

**Database**

a) GeoDjango model

```python
# backend/catalogues/models.py (continued)
class PlantTaxon(SyncableModel):
    scientific_name = models.CharField(max_length=200, unique=True)
    family = models.CharField(max_length=100, blank=True)
    vernacular_name = models.CharField(max_length=200, blank=True)     # Serbian
    vernacular_name_en = models.CharField(max_length=200, blank=True)
    taxon_source = models.CharField(max_length=10, choices=TaxonSource.choices, default=TaxonSource.GBIF)
    taxon_source_id = models.CharField(max_length=50, blank=True)
    active = models.BooleanField(default=True)
    history = HistoricalRecords(table_name="historical_plant_taxon")

    class Meta:
        db_table = "plant_taxon"


class Codelist(SyncableModel):
    code = models.SlugField(max_length=30, unique=True)
    name_en = models.CharField(max_length=150)
    name_sr = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    sort_order = models.PositiveSmallIntegerField(default=100)
    active = models.BooleanField(default=True)

    class Meta:
        abstract = True
        ordering = ["sort_order", "name_en"]


class HabitatType(Codelist):
    eunis_code = models.CharField(max_length=20, blank=True)
    history = HistoricalRecords(table_name="historical_habitat_type")

    class Meta(Codelist.Meta):
        db_table = "habitat_type"


class ManagementType(Codelist):
    history = HistoricalRecords(table_name="historical_management_type")

    class Meta(Codelist.Meta):
        db_table = "management_type"
```

b) PostGIS DDL

```sql
CREATE TABLE plant_taxon (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  scientific_name    varchar(200) NOT NULL UNIQUE,
  family             varchar(100) NOT NULL,
  vernacular_name    varchar(200) NOT NULL,
  vernacular_name_en varchar(200) NOT NULL,
  taxon_source       varchar(10) NOT NULL CHECK (taxon_source IN ('gbif','manual')),
  taxon_source_id    varchar(50) NOT NULL,
  active             boolean NOT NULL DEFAULT true
);

CREATE TABLE habitat_type (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  code        varchar(30) NOT NULL UNIQUE,
  name_en     varchar(150) NOT NULL,
  name_sr     varchar(150) NOT NULL,
  description text NOT NULL,
  sort_order  smallint NOT NULL CHECK (sort_order >= 0),
  active      boolean NOT NULL DEFAULT true,
  eunis_code  varchar(20) NOT NULL
);

CREATE TABLE management_type ( /* same columns as habitat_type without eunis_code */ );
-- each: CREATE INDEX ... (server_version); CREATE TRIGGER ... bump_server_version()
```

c) Drift

```dart
class PlantTaxa extends Table {
  TextColumn get id => text()();
  TextColumn get scientificName => text()();
  TextColumn get family => text().withDefault(const Constant(''))();
  TextColumn get vernacularName => text().withDefault(const Constant(''))();
  TextColumn get vernacularNameEn => text().withDefault(const Constant(''))();
  BoolColumn get active => boolean()();
  TextColumn get searchText => text()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

// HabitatTypes and ManagementTypes share this shape (HabitatTypes adds eunisCode)
class HabitatTypes extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get nameEn => text()();
  TextColumn get nameSr => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get active => boolean()();
  TextColumn get eunisCode => text().withDefault(const Constant(''))();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```
Difference: `description` and the source fields are not stored on the phone.

d) Django-specific limitation
- Abstract model inheritance means two physical tables, which is intended.
- `Meta` inheritance needs the `class Meta(Codelist.Meta)` form to keep `ordering`.

**Limitations / out of scope / risks**
- Fixed enums (behaviour, life stage, etc.) can't be edited in admin. Changing them is a code change plus migration, a deliberate trade-off.

---

### T021 · Transect and section models and API
**ID:** T021 · **Implements:** F6 · **Labels:** `backend`, `database`, `must`, `p2-compat` · **Milestone:** Phase 1 · **Epic:** E03 · **Depends on:** T015, T020 · **Estimate:** 2 d

**Description**
Each transect is a fixed line, divided into numbered sections that each have a habitat type. Admins edit them (T022). Researchers read them through the API and pull.

**Acceptance criteria**
- [ ] `Transect` and `TransectSection` models. `(project, code)` is unique, and so are `(transect, sequence_number)` and `(transect, section_code)`.
- [ ] `GET /api/v1/projects/{id}/transects` and `GET /api/v1/transects/{id}` are read-only. Responses include computed `length_m` (geodesic), `section_count`, and the caller's `visit_count` and `last_visit_at`.
- [ ] `GET /api/v1/transects/{id}/visits` returns the caller's visits (admins: all visits).
- [ ] Validation: a section geometry must lie within 5 m of its transect line (`ST_DWithin` on geography). An admin form error is shown otherwise.
- [ ] Both models are synced to project members.

**Database**

a) GeoDjango model

```python
# backend/transects/models.py
from django.contrib.gis.db import models
from simple_history.models import HistoricalRecords
from core.models import SyncableModel


class Transect(SyncableModel):
    project = models.ForeignKey("projects.Project", on_delete=models.PROTECT, related_name="transects")
    code = models.CharField(max_length=20)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    target_length_m = models.DecimalField(max_digits=8, decimal_places=1, null=True, blank=True)
    habitat_summary = models.TextField(blank=True)
    active = models.BooleanField(default=True)
    geometry = models.LineStringField(srid=4326)
    history = HistoricalRecords(table_name="historical_transect")

    class Meta:
        db_table = "transect"
        constraints = [models.UniqueConstraint(fields=["project", "code"], name="transect_code_unique")]


class TransectSection(SyncableModel):
    transect = models.ForeignKey(Transect, on_delete=models.PROTECT, related_name="sections")
    section_code = models.CharField(max_length=20)
    sequence_number = models.PositiveSmallIntegerField()
    habitat_type = models.ForeignKey("catalogues.HabitatType", on_delete=models.PROTECT, null=True, blank=True)
    management_type = models.ForeignKey("catalogues.ManagementType", on_delete=models.PROTECT, null=True, blank=True)
    notes = models.TextField(blank=True)
    geometry = models.LineStringField(srid=4326)
    history = HistoricalRecords(table_name="historical_transect_section")

    class Meta:
        db_table = "transect_section"
        ordering = ["transect", "sequence_number"]
        constraints = [
            models.UniqueConstraint(fields=["transect", "sequence_number"], name="section_seq_unique"),
            models.UniqueConstraint(fields=["transect", "section_code"], name="section_code_unique"),
            models.CheckConstraint(condition=models.Q(sequence_number__gte=1), name="section_seq_positive"),
        ]
```

b) PostGIS DDL

```sql
CREATE TABLE transect (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  project_id      uuid NOT NULL REFERENCES project(id),
  code            varchar(20) NOT NULL,
  name            varchar(200) NOT NULL,
  description     text NOT NULL,
  target_length_m numeric(8,1) NULL,
  habitat_summary text NOT NULL,
  active          boolean NOT NULL DEFAULT true,
  geometry        geometry(LineString, 4326) NOT NULL,
  CONSTRAINT transect_code_unique UNIQUE (project_id, code)
);
CREATE INDEX transect_geometry_gist ON transect USING gist (geometry);
CREATE INDEX transect_server_version_idx ON transect (server_version);

CREATE TABLE transect_section (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  transect_id        uuid NOT NULL REFERENCES transect(id),
  section_code       varchar(20) NOT NULL,
  sequence_number    smallint NOT NULL CONSTRAINT section_seq_positive CHECK (sequence_number >= 1),
  habitat_type_id    uuid NULL REFERENCES habitat_type(id),
  management_type_id uuid NULL REFERENCES management_type(id),
  notes              text NOT NULL,
  geometry           geometry(LineString, 4326) NOT NULL,
  CONSTRAINT section_seq_unique  UNIQUE (transect_id, sequence_number),
  CONSTRAINT section_code_unique UNIQUE (transect_id, section_code)
);
CREATE INDEX transect_section_geometry_gist ON transect_section USING gist (geometry);
CREATE INDEX transect_section_server_version_idx ON transect_section (server_version);
-- + triggers
```

c) Drift

```dart
class Transects extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  RealColumn get targetLengthM => real().nullable()();
  RealColumn get lengthM => real().nullable()();            // computed on server, pulled
  TextColumn get habitatSummary => text().withDefault(const Constant(''))();
  BoolColumn get active => boolean()();
  TextColumn get geometryGeojson => text()();               // LineString
  RealColumn get minLat => real()();  RealColumn get minLon => real()();   // bbox for map
  RealColumn get maxLat => real()();  RealColumn get maxLon => real()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class TransectSections extends Table {
  TextColumn get id => text()();
  TextColumn get transectId => text().references(Transects, #id)();
  TextColumn get sectionCode => text()();
  IntColumn get sequenceNumber => integer()();
  TextColumn get habitatTypeId => text().nullable()();
  TextColumn get managementTypeId => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get geometryGeojson => text()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```
Differences from the server:
- Geometry is stored as GeoJSON text, plus a bbox on transects.
- `lengthM` is precomputed by the server.
- Both tables are read-only on the phone.

d) Django-specific limitation
- Geodesic length needs a geography cast. Annotate with `Length(Cast("geometry", GeographyField()))`, or use raw SQL `ST_Length(geometry::geography)`. Django's `Length` on geometry with SRID 4326 returns degrees unless the field is geography (VERIFY current behaviour; spheroid support varies).

**Limitations / out of scope / risks**
- **p2-compat:** section and transect geometries are reused in Phase 2 for station assignment (T078) and habitat-change events (T091). Keep them as plain LineStrings without Z/M dimensions.

---

### T022 · Map-based transect and section editor in admin
**ID:** T022 · **Implements:** F63 · **Labels:** `admin`, `must` · **Milestone:** Phase 1 · **Epic:** E03 · **Depends on:** T014, T021 · **Estimate:** 2 d

**Description**
Admins draw or import transects on a map, and split them into sections without hand-drawing each one.

**Acceptance criteria**
- [ ] `TransectAdmin(MapAdmin, SimpleHistoryAdmin)` uses a map widget for the line and a sections inline (`StackedInline`, small map per section, collapsed by default).
- [ ] An **Import line** admin view on a transect accepts a GPX, KML or GeoJSON upload. It reads the first LineString or track using `django.contrib.gis.gdal.DataSource` and reprojects it to 4326.
- [ ] Action **Generate N equal sections** (intermediate form asking N and a code prefix) creates sections with `ST_LineSubstring` and sequence numbers 1..N. It refuses if sections already exist, unless "replace" is ticked; replaced sections are soft-deleted.
- [ ] A warning appears in the change view when the sum of section lengths differs from the transect length by more than 2 %.
- [ ] The list shows code, name, project, active, length and section count, filtered by project.

**Technical explanation**
Section splitting in SQL:

```sql
SELECT n, ST_LineSubstring(t.geometry, (n-1)::float/:N, n::float/:N)
FROM transect t, generate_series(1, :N) n WHERE t.id = :id;
```

Splitting by fraction uses planar fractions in degrees. That's fine for transects of a few km; note it in the docs.

**Limitations / out of scope / risks**
- No splitting at habitat boundaries automatically. Admins adjust sections by editing their lines.

---

### T023 · Catalogue admin tools
**ID:** T023 · **Implements:** F64 · **Labels:** `admin`, `should` · **Milestone:** Phase 1 · **Epic:** E03 · **Depends on:** T019, T020 · **Estimate:** 1.5 d

**Description**
Make catalogue maintenance quick: search, filters, CSV import/export, and publishing a new taxon list version.

**Acceptance criteria**
- [ ] Taxon, PlantTaxon, HabitatType and ManagementType admins have search, filters (family, active, source) and `list_editable` for `active`, `photo_required` and `sort_order`.
- [ ] CSV import and export for all four, using **django-import-export**. It's justified: it saves writing and testing a custom importer, and its dry-run diff preview is useful. Pin the version and VERIFY Django 5.2 support.
- [ ] Action **Publish new taxon list version**: creates a `TaxonListVersion`, marks it current, and lets admins choose which projects switch to it.
- [ ] Action **Synonymise into…** (intermediate form): creates or links the accepted taxon and retires the selected one in the new version, following the T019 versioning rule.

**Technical explanation**
Imports go through model `save()` (not bulk), so history and triggers apply.

**Limitations / out of scope / risks**
- Imports of more than a few thousand rows will be slow because of per-row saves. That's fine for these list sizes.

---

### T024 · Seed data: butterflies of Serbia, plant list, codelists, demo project
**ID:** T024 · **Implements:** F79 · **Labels:** `backend`, `must` · **Milestone:** Phase 1 · **Epic:** E03 · **Depends on:** T019, T020, T021 · **Estimate:** 2 d

**Description**
You have no checklist, so build working lists from GBIF and a curated plant list, plus a demo project that development, tests and the simulator (T071) all use.

**Acceptance criteria**
- [ ] `manage.py import_gbif_butterflies --country RS`:
  - resolves the GBIF key for superfamily *Papilionoidea* via `/v1/species/match`
  - gets species keys via `/v1/occurrence/search?country=RS&taxonKey=<key>&facet=speciesKey&facetLimit=1000&limit=0`
  - fetches names, authors, family and genus via `/v1/species/{key}`, and Serbian/English vernacular names via `/v1/species/{key}/vernacularNames`
  - creates `TaxonListVersion "2026.1 (GBIF RS)"` and the taxa
  - the expected count is reported (probably about 150–200; VERIFY the actual number)
  - species with fewer than 3 Serbian records are listed for manual review rather than imported silently
- [ ] `database/seeds/plants.csv` holds about 60–100 known larval host and nectar plants for the imported species (e.g. *Urtica dioica*, *Lotus corniculatus*, *Knautia arvensis*, *Centaurea* spp., *Thymus* spp., *Rumex acetosa*, *Viola* spp.). `manage.py seed_plants` resolves GBIF IDs with `/v1/species/match`.
- [ ] `manage.py seed_codelists` creates the habitat types (grassland-oriented subset with EUNIS codes, e.g. dry grassland, mesic grassland, wet meadow, forest edge, shrubland, ruderal) and management types (mown, grazed, abandoned, burned, none).
- [ ] `manage.py seed_demo` creates:
  - users `admin@demo`, `researcher@demo`
  - project "Demo – Fruška Gora 2026" with a protocol and area
  - 4 transects of about 1 km with 5–8 sections each, in different habitat types (coordinates committed as GeoJSON in `database/seeds/transects.geojson`)
- [ ] All commands are idempotent (re-running creates no duplicates), and the raw GBIF responses are saved under `database/seeds/cache/` so re-runs work offline.

**Technical explanation**
Plain `requests` with polite rate limiting (≤ 3 req/s) and a `User-Agent` naming the project.

**Limitations / out of scope / risks**
- **GBIF occurrence-based lists include misidentifications and records of vagrants. They are a working list, not a vetted checklist.** List this as a limitation in the thesis.
- GBIF is migrating its backbone taxonomy (VERIFY current dataset). Store whatever key `/species/match` returns, together with `taxon_source_id`.

---
## E04 · Offline storage and synchronisation

### E04 · Epic: Offline storage and synchronisation
**Labels:** `epic`, `sync`, `backend`, `mobile` · **Milestone:** Phase 1 · **Implements:** F7, F23, F24, F25, F26, F28
Cursor-based pull, idempotent batched push, conflict detection with a Django admin resolution screen, the app's sync queue and runner, offline package download and the sync status screen. Together these cover MVP criteria 1, 7, 8 and 9: offline download, data survives restarts, sync resumes after interruption, and no duplicates.
Children: T025 · T026 · T027 · T028 · T029 · T030 · T031 · T032

**Sync protocol summary (shared by all tickets in this epic)**

```
PULL  POST /api/v1/sync/pull  {project_id, cursor, limit}
      -> {changes: {<entity_type>: [record|tombstone]}, next_cursor, has_more, server_time}
PUSH  POST /api/v1/sync/push  {device_id, mutations: [
        {mutation_id, entity_type, entity_id, operation: create|update|delete|create_batch,
         base_version, payload, client_created_at}]}
      -> {results: [{mutation_id, status: applied|merged|duplicate|conflict|rejected,
                     server_version, errors}]}
Entity types: project, project_protocol, taxon_list_version, taxon, plant_taxon, habitat_type,
management_type, transect, transect_section, survey_visit, survey_track_point,
butterfly_observation, photo, plant_resource_observation, habitat_feature, sync_conflict
(Phase 2 adds: sensor_station_link, focal_follow_session, focal_follow_point, trajectory_event)
```

---

### T025 · Pull API with server-version cursor
**ID:** T025 · **Implements:** F25, F7 · **Labels:** `backend`, `sync`, `must` · **Milestone:** Phase 1 · **Epic:** E04 · **Depends on:** T005, T015, T019, T020, T021 · **Estimate:** 2 d

**Description**
The phone asks for "everything that changed since cursor X" for one project, and gets records and tombstones in version order, in pages.

**Acceptance criteria**
- [ ] `POST /api/v1/sync/pull` returns the changes for all entity types in scope, ordered by `server_version`, at most `limit` (default 1000, max 5000) records per page, with `next_cursor` = the last returned version and `has_more`.
- [ ] Scope rules:
  - reference data: the project, its protocol, transects, sections, the catalogues (global), and the taxon list version
  - user data: the caller's **own** records (`created_by = user`) in that project
  - `sync_conflict`: the caller's own conflicts
- [ ] Soft-deleted rows come back as `{id, deleted_at, server_version}` tombstones.
- [ ] A non-member gets 404. Cursor 0 returns the full initial package (T031).
- [ ] Each entity serializer used for pull is the same one used for push (single schema), documented in OpenAPI.
- [ ] Test: interleaved writes during paging never lose a record. The T005 advisory lock guarantees in-order commits.

**Technical explanation**
- For each entity type, query `changed_since(cursor)` with scope filters and `LIMIT limit`. Merge the per-type results by `server_version`, take the first `limit`, and set `next_cursor` to the last taken version.
- Geometry is serialised as GeoJSON (`rest_framework_gis` GeometryField, or a manual `geometry.geojson`). Using djangorestframework-gis is justified because it serialises GeometryFields to and from GeoJSON with no custom code (VERIFY Django 5.2 support).

**Limitations / out of scope / risks**
- When a user loses membership, already-downloaded data stays on their phone (documented). There is no remote wipe.
- `survey_track_point` volume can be large on a fresh install, so it is paged like everything else.

---

### T026 · Push API with idempotent mutations
**ID:** T026 · **Implements:** F25, F13 · **Labels:** `backend`, `sync`, `database`, `must` · **Milestone:** Phase 1 · **Epic:** E04 · **Depends on:** T025 · **Estimate:** 2.5 d

**Description**
The phone sends a batch of changes. Each change is applied once, even if the batch is resent after a dropped connection.

**Acceptance criteria**
- [ ] Each mutation runs in its own savepoint, so one rejected mutation does not abort the batch. Results come back in input order.
- [ ] **Idempotency:** a `mutation_id` already in `sync_mutation` returns the stored result with status `duplicate` and changes nothing (tested by sending the same batch twice).
- [ ] `create` with an existing `entity_id` and an unseen `mutation_id` is treated as `update` with conflict check (T027).
- [ ] `create_batch` (track points only) inserts up to 1000 rows with `ON CONFLICT (id) DO NOTHING`.
- [ ] Every mutation runs through the entity's service function: validation (T055), ownership (`created_by` or admin), membership, the lock rule (T042), section assignment (T048), flags (T056) and history reason `"sync push"`.
- [ ] Server-owned fields (`validation_*`, `quality_flags`, `server_version`, `locked_*`, `distance_walked_m` once recomputed) are ignored if present in client payloads.
- [ ] A rejected mutation returns `{code, detail, fields}` errors that the app can show (T032).
- [ ] A 500-mutation batch completes in under 5 s on the laptop (measured in T074).

**Database**

a) GeoDjango model

```python
# backend/sync/models.py
from django.conf import settings
from django.db import models


class MutationStatus(models.TextChoices):
    APPLIED = "applied"; MERGED = "merged"; CONFLICT = "conflict"; REJECTED = "rejected"


class SyncMutation(models.Model):
    mutation_id = models.UUIDField(primary_key=True)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT)
    device_id = models.CharField(max_length=64)
    entity_type = models.CharField(max_length=40)
    entity_id = models.UUIDField()
    operation = models.CharField(max_length=15)
    base_version = models.BigIntegerField(null=True)
    status = models.CharField(max_length=10, choices=MutationStatus.choices)
    result = models.JSONField(default=dict)
    received_at = models.DateTimeField(auto_now_add=True)
    client_created_at = models.DateTimeField(null=True)

    class Meta:
        db_table = "sync_mutation"
        indexes = [models.Index(fields=["entity_type", "entity_id"]),
                   models.Index(fields=["user", "received_at"])]
        constraints = [
            models.CheckConstraint(condition=models.Q(status__in=MutationStatus.values), name="sync_mutation_status_valid"),
            models.CheckConstraint(condition=models.Q(operation__in=["create", "update", "delete", "create_batch"]),
                                   name="sync_mutation_operation_valid"),
        ]
```

b) PostGIS DDL

```sql
CREATE TABLE sync_mutation (
  mutation_id       uuid PRIMARY KEY,
  user_id           uuid NOT NULL REFERENCES app_user(id),
  device_id         varchar(64) NOT NULL,
  entity_type       varchar(40) NOT NULL,
  entity_id         uuid NOT NULL,
  operation         varchar(15) NOT NULL
                    CONSTRAINT sync_mutation_operation_valid
                    CHECK (operation IN ('create','update','delete','create_batch')),
  base_version      bigint NULL,
  status            varchar(10) NOT NULL
                    CONSTRAINT sync_mutation_status_valid
                    CHECK (status IN ('applied','merged','conflict','rejected')),
  result            jsonb NOT NULL,
  received_at       timestamptz NOT NULL,
  client_created_at timestamptz NULL
);
CREATE INDEX sync_mutation_entity_idx ON sync_mutation (entity_type, entity_id);
CREATE INDEX sync_mutation_user_time_idx ON sync_mutation (user_id, received_at);
```

c) Drift: not mirrored. The client keeps its own `sync_queue` (T029).

d) Django-specific limitation
- Nested `transaction.atomic()` blocks create savepoints, which is what isolates each mutation.
- After an exception inside a savepoint, the outer transaction stays usable only if the exception is caught **outside** the inner `atomic()` block (pattern documented in code).

**Limitations / out of scope / risks**
- `device_id` is a plain string (the app generates a UUID on first install; F86 removed). There is no per-device registry.
- `sync_mutation` grows forever. A `manage.py prune_sync_mutations --older-than 180d` command is enough.

---

### T027 · Conflict detection and SyncConflict model
**ID:** T027 · **Implements:** F26 · **Labels:** `backend`, `sync`, `database`, `must` · **Milestone:** Phase 1 · **Epic:** E04 · **Depends on:** T026, T018 · **Estimate:** 2 d

**Description**
Never silently overwrite biological data (outline §12.4: no blind last-write-wins). When the phone edits a record that changed on the server since the phone last saw it, check which fields each side changed. Merge if they don't overlap; otherwise record a conflict for an admin to resolve.

**Acceptance criteria**
- [ ] For `update` and `delete` with `base_version` ≠ the current `server_version`:
  1. load the server snapshot at `base_version` from the history table (`historical_<table>` where `id = X and server_version = base_version`)
  2. server-changed fields = diff(snapshot, current), excluding server-owned and bookkeeping fields
  3. client-changed fields = payload keys whose value differs from the snapshot
  4. if there is no overlap, apply the client fields and return status `merged`
  5. otherwise create a `SyncConflict`, apply nothing, and return status `conflict`
- [ ] If no snapshot exists (history missing), the whole record counts as conflicting.
- [ ] A `delete` against a server-changed record is always a conflict.
- [ ] `SyncConflict` is pulled to its owner (T025), so the app can list it (T032).
- [ ] Tests cover:
  - researcher edits `count` while an admin validated the taxon: `merged`
  - both changed `count`: `conflict`
  - delete after a server change: `conflict`

**Database**

a) GeoDjango model

```python
# backend/sync/models.py (continued)
from django.contrib.postgres.fields import ArrayField
from simple_history.models import HistoricalRecords
from core.models import SyncableModel


class ConflictStatus(models.TextChoices):
    OPEN = "open"
    RESOLVED_SERVER = "resolved_server"   # keep server state, drop client change
    RESOLVED_CLIENT = "resolved_client"   # apply client payload


class SyncConflict(SyncableModel):
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="sync_conflicts")
    mutation = models.OneToOneField(SyncMutation, on_delete=models.PROTECT, related_name="conflict")
    project = models.ForeignKey("projects.Project", on_delete=models.PROTECT)
    entity_type = models.CharField(max_length=40)
    entity_id = models.UUIDField()
    operation = models.CharField(max_length=15)
    base_version = models.BigIntegerField()
    server_version_at_conflict = models.BigIntegerField()
    client_payload = models.JSONField()
    server_snapshot = models.JSONField()          # current server record at conflict time
    base_snapshot = models.JSONField(null=True)   # record at base_version, if found
    conflicting_fields = ArrayField(models.CharField(max_length=60), default=list)
    status = models.CharField(max_length=20, choices=ConflictStatus.choices, default=ConflictStatus.OPEN)
    resolved_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, null=True, blank=True,
                                    related_name="+")
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolution_note = models.TextField(blank=True)
    history = HistoricalRecords(table_name="historical_sync_conflict")

    class Meta:
        db_table = "sync_conflict"
        indexes = [models.Index(fields=["status", "entity_type"]), models.Index(fields=["entity_type", "entity_id"])]
        constraints = [
            models.CheckConstraint(condition=models.Q(status__in=ConflictStatus.values), name="sync_conflict_status_valid"),
            models.CheckConstraint(
                condition=models.Q(status="open", resolved_at__isnull=True)
                | (~models.Q(status="open") & models.Q(resolved_at__isnull=False)),
                name="sync_conflict_resolution_consistent"),
        ]
```

b) PostGIS DDL

```sql
CREATE TABLE sync_conflict (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  owner_id                    uuid NOT NULL REFERENCES app_user(id),
  mutation_id                 uuid NOT NULL UNIQUE REFERENCES sync_mutation(mutation_id),
  project_id                  uuid NOT NULL REFERENCES project(id),
  entity_type                 varchar(40) NOT NULL,
  entity_id                   uuid NOT NULL,
  operation                   varchar(15) NOT NULL,
  base_version                bigint NOT NULL,
  server_version_at_conflict  bigint NOT NULL,
  client_payload              jsonb NOT NULL,
  server_snapshot             jsonb NOT NULL,
  base_snapshot               jsonb NULL,
  conflicting_fields          varchar(60)[] NOT NULL DEFAULT '{}',
  status                      varchar(20) NOT NULL DEFAULT 'open'
                              CONSTRAINT sync_conflict_status_valid
                              CHECK (status IN ('open','resolved_server','resolved_client')),
  resolved_by_id              uuid NULL REFERENCES app_user(id),
  resolved_at                 timestamptz NULL,
  resolution_note             text NOT NULL,
  CONSTRAINT sync_conflict_resolution_consistent CHECK (
    (status = 'open' AND resolved_at IS NULL) OR (status <> 'open' AND resolved_at IS NOT NULL))
);
CREATE INDEX sync_conflict_status_entity_idx ON sync_conflict (status, entity_type);
CREATE INDEX sync_conflict_entity_idx ON sync_conflict (entity_type, entity_id);
CREATE INDEX sync_conflict_server_version_idx ON sync_conflict (server_version);
-- + trigger; + CREATE INDEX ON historical_<table> (id, server_version) for every audited synced table
```

c) Drift

```dart
class SyncConflicts extends Table {          // read-only mirror for the sync screen
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get conflictingFields => text()();      // JSON array
  TextColumn get status => text()();                 // open | resolved_server | resolved_client
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  TextColumn get resolutionNote => text().withDefault(const Constant(''))();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```
Difference: the payload and snapshots are not mirrored; the phone only needs to know a conflict exists and how it ended.

d) Django-specific limitation
- The history-snapshot lookup depends on T018 storing the **fresh** `server_version` in historical rows (see T018 d).
- `ArrayField` is PostgreSQL-only.

**Limitations / out of scope / risks**
- Field-level merge compares top-level fields only. A changed geometry counts as one field.

---

### T028 · Django admin conflict resolution screen
**ID:** T028 · **Implements:** F26 · **Labels:** `admin`, `sync`, `must` · **Milestone:** Phase 1 · **Epic:** E04 · **Depends on:** T027, T014 · **Estimate:** 1.5 d

**Description**
Admins see open conflicts, compare client and server values side by side, and choose which side wins.

**Acceptance criteria**
- [ ] `SyncConflictAdmin` list: entity type, entity link, owner, project, conflicting fields, created, status. Filters: status, entity type, project, owner.
- [ ] The change view is read-only with a **side-by-side diff table** (field | base | server | client), with conflicting rows highlighted. It is a small template override: `admin/sync/syncconflict/change_form.html`.
- [ ] Action/button **Accept server**: marks `resolved_server` and *touches* the entity (a save with reason `"conflict resolved: server"`), so it gets a new `server_version` and the phone pulls the server state.
- [ ] Action/button **Accept client**: applies `client_payload` through the entity's service with conflict checks bypassed, history reason `"conflict resolved: client"`, then marks `resolved_client`.
- [ ] Both require a note (intermediate form) and are recorded in history.
- [ ] Accepting client on a locked visit is refused with a message to unlock first (T043).

**Technical explanation**
A custom `change_view` adds the diff context, and buttons post to admin URLs added with `get_urls()`.

**Limitations / out of scope / risks**
- No per-field mixed resolution (taking some fields from each side). An admin can accept one side and then edit the record normally.

---

### T029 · App sync queue
**ID:** T029 · **Implements:** F24, F23 · **Labels:** `mobile`, `sync`, `database`, `must` · **Milestone:** Phase 1 · **Epic:** E04 · **Depends on:** T006 · **Estimate:** 1.5 d

**Description**
Every local change to user data is written together with a queue entry in one Drift transaction, so nothing is lost when the app is killed (outline §12.3).

**Acceptance criteria**
- [ ] A `SyncRepository.write(entity, operation)` helper writes the row with `syncStatus = pending` and appends a queue item, atomically.
- [ ] **Coalescing:**
  - several updates to a queued entity merge into one queued update, keeping the first `baseVersion`
  - create followed by updates becomes a single create
  - create followed by delete removes both
- [ ] Track points are queued as `create_batch` items of up to 500 points.
- [ ] `sync_state` stores `deviceId` (UUID generated on first launch), per-project `lastPullCursor`, `lastSuccessfulSyncAt` and `lastSyncBytes`.
- [ ] Unit tests cover coalescing and atomicity (simulate an exception mid-write: neither row nor queue item persists).

**Database**

c) Drift (local only; no server table)

```dart
enum QueueStatus { queued, inFlight, conflict, rejected }

class SyncQueue extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get mutationId => text().unique()();          // UUID v4
  TextColumn get projectId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();                    // create|update|delete|create_batch
  IntColumn get baseVersion => integer().nullable()();
  TextColumn get payload => text()();                      // JSON
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => textEnum<QueueStatus>()();
}

class SyncStateEntries extends Table {                      // key/value
  TextColumn get key => text()();                          // e.g. 'deviceId', 'cursor:<projectId>'
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}
```
The outline's queue fields (§12.3) map directly. `upload_attachment` is not a queue operation; photo uploads are driven by the `photos.uploadStatus` column (T050).

**Limitations / out of scope / risks**
- The queue does not encrypt payloads at rest; the device's own encryption applies. Biometric unlock was removed (F88).

---

### T030 · App sync runner: push, pull, retry and backoff
**ID:** T030 · **Implements:** F24, F25 · **Labels:** `mobile`, `sync`, `must` · **Milestone:** Phase 1 · **Epic:** E04 · **Depends on:** T029, T026, T025 · **Estimate:** 2.5 d

**Description**
Run sync automatically when it makes sense and recover from every network failure without duplicates.

**Acceptance criteria**
- [ ] **Triggers:** app start, connectivity regained (`connectivity_plus`), visit finished, manual "Sync now", and every 15 minutes while in the foreground. Only one run at a time (mutex).
- [ ] **Order:**
  1. push queued items in `seq` order, in batches of 100
  2. upload photos (T050)
  3. pull until `has_more = false` for each downloaded project
- [ ] **Result handling:**
  - `applied`, `merged` and `duplicate` set the row to `synced` with the returned version and delete the queue item
  - `conflict` sets the row and queue item to `conflict` and holds later items for the same entity
  - `rejected` sets both to `rejected`, with errors kept for display
- [ ] **Network errors:** `retryCount++` and `nextAttemptAt = now + min(2^n s, 15 min) ± 20 % jitter`. The batch is retried as-is with the same `mutationId`s, so the server dedupes.
- [ ] **Pull apply** runs in one Drift transaction per page:
  - rows with local `pending` changes are **not** overwritten (the push will conflict-check them)
  - tombstones delete locally or set `deletedAt`
  - resolved `sync_conflict` rows release held queue items: `resolved_server` drops them, and `resolved_client` marks the entity synced
- [ ] Integration test against a fake server that drops the connection after the server applies a batch: re-running leaves no duplicates (MVP criterion 9).

**Technical explanation**
Bytes transferred are counted in a dio interceptor for the sync screen (outline §11.2 L "transfer size").

**Limitations / out of scope / risks**
- No background sync when the app is closed (workmanager is out of scope). Sync runs when the app is opened or brought to the foreground.

---

### T031 · App offline package download and status
**ID:** T031 · **Implements:** F7 · **Labels:** `mobile`, `backend`, `must` · **Milestone:** Phase 1 · **Epic:** E04 · **Depends on:** T030 · **Estimate:** 1.5 d

**Description**
A researcher downloads a project once while online and can then work without connectivity (MVP criteria 1 and 2).

**Acceptance criteria**
- [ ] The **Download project** button runs a pull from cursor 0 for that project, with a progress indicator (records received) and the ability to cancel and resume (cursor persisted).
- [ ] `GET /api/v1/projects/{id}/offline-package` (outline §14) exists as a thin alias returning the first pull page plus `{reference_version}`. `GET /api/v1/projects/{id}/offline-package/status` returns `{reference_version}`, the max `server_version` across reference tables.
- [ ] Project list status: `not downloaded` / `ready` / `update available` (when the server `reference_version` is newer than the local one).
- [ ] After download in airplane mode, every screen needed for a visit works (manual test script in `docs/testing/offline-checklist.md`).
- [ ] If T060 is done, the package also downloads the project's MBTiles basemap.

**Limitations / out of scope / risks**
- There's no partial package (for example "just two transects"); projects are small.

---

### T032 · App sync status screen
**ID:** T032 · **Implements:** F28 · **Labels:** `mobile`, `sync`, `must` · **Milestone:** Phase 1 · **Epic:** E04 · **Depends on:** T030 · **Estimate:** 1.5 d

**Description**
Show what's waiting to sync, what failed and why, and any conflicts (outline §11.2 L).

**Acceptance criteria**
- [ ] The screen shows pending changes per entity type, photos waiting and their total size, last successful sync time, and bytes transferred in the last sync.
- [ ] **Errors** list: rejected items with a human-readable reason (mapped from the error `code`), plus **Retry** (re-queues with a new attempt) and **Discard local change** (with confirmation; restores the server version on the next pull).
- [ ] **Conflicts** list (from `sync_conflicts`) is read-only and reads: "An admin will resolve this. Your change is kept on the server." It shows the resolution once pulled.
- [ ] **Sync now** button with live progress.
- [ ] The unsynced badge on project home (T017) matches the counts here.

**Limitations / out of scope / risks**
- Conflict resolution happens only in Django admin (v4 decision).

---
## E05 · Field visit

### E05 · Epic: Field visit
**Labels:** `epic`, `mobile`, `backend` · **Milestone:** Phase 1 · **Implements:** F8, F9, F10, F11, F12, F13, F66, F72, F87
Browse transects, start a standardised visit, track the route in the background, pause and finish with a summary, confirm true zeros, and lock visits in Django admin.
Children: T033 · T034 · T035 · T036 · T037 · T038 · T039 · T040 · T041 · T042 · T043

---

### T033 · App transect list and transect detail
**ID:** T033 · **Implements:** F72 · **Labels:** `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E05 · **Depends on:** T017, T021, T031 · **Estimate:** 2 d

**Description**
Researchers find the transect they're standing next to and start a visit from its detail page (outline §11.2 D, E).

**Acceptance criteria**
- [ ] List: code, name, distance from the current location (last known fix, straight-line to the nearest vertex), last own visit date, own visit count, downloaded flag, active status. Search by name or code, sort by distance or code.
- [ ] Detail: a map (flutter_map) with the transect line and colour-coded sections, length, section list with habitat types, habitat summary, a protocol summary (season, time window, weather thresholds from `project_protocols`), own visit history, and a **Start visit** button.
- [ ] Start visit is disabled for inactive transects. It warns (without blocking) outside the season or time window.
- [ ] Everything works offline.

**Limitations / out of scope / risks**
- Visit history shows the user's own visits only (pull scope). Admins see everyone's in Django admin.

---

### T034 · SurveyVisit model, lifecycle and API
**ID:** T034 · **Implements:** F9 · **Labels:** `backend`, `mobile`, `database`, `must`, `p2-compat` · **Milestone:** Phase 1 · **Epic:** E05 · **Depends on:** T021, T026 · **Estimate:** 2.5 d

**Description**
A visit records one standardised walk of a transect: who, when, conditions, effort and status. The status follows a fixed state machine shared by app, API and admin.

**Lifecycle (outline §7.2 statuses, all seven)**

| From | To | Who |
|---|---|---|
| `draft` | `in_progress` | app (Start) |
| `draft`, `in_progress` | `cancelled` (+ `cancel_reason`) | app |
| `in_progress` | `completed` | app (Finish) |
| `completed` | `synced` | server, automatically on first successful push of the completed visit |
| `completed`, `synced` | `reviewed` | admin |
| `completed`, `synced`, `reviewed` | `locked` | admin (T043) |
| `locked` | `reviewed` | admin unlock (T043) |

**Acceptance criteria**
- [ ] `surveys/state.py` holds a transition table and `transition(visit, to, actor, reason=None)`, raising `InvalidTransition`. It is used by push, the REST endpoints and admin. There is no extra dependency (django-fsm is not used: its maintenance status is unclear and a dict is enough).
- [ ] REST endpoints (outline §14), using the same services as push:
  - `POST /api/v1/survey-visits`
  - `GET /api/v1/survey-visits/{id}`
  - `PATCH /api/v1/survey-visits/{id}`
  - `POST /api/v1/survey-visits/{id}/complete`

  There is **no** lock endpoint; locking is admin-only.
- [ ] `cancel_reason` is required exactly when `status = cancelled`. "Missing data" means no visit row at all (outline §7.3).
- [ ] Mirrored in Drift; the app uses the same Dart transition table (shared JSON spec in `docs/requirements/visit-states.json`, with a test on both sides that reads it).

**Database**

a) GeoDjango model

```python
# backend/surveys/models.py
from django.conf import settings
from django.contrib.gis.db import models
from django.contrib.postgres.fields import ArrayField
from simple_history.models import HistoricalRecords
from core.models import SyncableModel
from projects.models import SurveyMethod


class VisitStatus(models.TextChoices):
    DRAFT = "draft"; IN_PROGRESS = "in_progress"; COMPLETED = "completed"; SYNCED = "synced"
    REVIEWED = "reviewed"; LOCKED = "locked"; CANCELLED = "cancelled"


class CancelReason(models.TextChoices):
    NOT_CONDUCTED = "not_conducted"; ABORTED_WEATHER = "aborted_weather"
    ABORTED_OTHER = "aborted_other"; INVALID_PROTOCOL = "invalid_protocol"


class Precipitation(models.TextChoices):
    NONE = "none"; DRIZZLE = "drizzle"; LIGHT_RAIN = "light_rain"; RAIN = "rain"


class SurveyVisit(SyncableModel):
    project = models.ForeignKey("projects.Project", on_delete=models.PROTECT, related_name="visits")
    transect = models.ForeignKey("transects.Transect", on_delete=models.PROTECT, related_name="visits")
    observer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="visits")
    protocol_version = models.CharField(max_length=20)
    survey_method = models.CharField(max_length=20, choices=SurveyMethod.choices, default=SurveyMethod.POLLARD_WALK)
    started_at = models.DateTimeField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    duration_seconds = models.PositiveIntegerField(null=True, blank=True)     # excludes pauses
    paused_seconds = models.PositiveIntegerField(default=0)
    distance_walked_m = models.DecimalField(max_digits=8, decimal_places=1, null=True, blank=True)
    observer_count = models.PositiveSmallIntegerField(default=1)
    observer_names = models.CharField(max_length=300, blank=True)
    temperature_start_c = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
    temperature_end_c = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
    wind_beaufort_start = models.PositiveSmallIntegerField(null=True, blank=True)
    wind_beaufort_end = models.PositiveSmallIntegerField(null=True, blank=True)
    cloud_cover_start_pct = models.PositiveSmallIntegerField(null=True, blank=True)
    cloud_cover_end_pct = models.PositiveSmallIntegerField(null=True, blank=True)
    precipitation = models.CharField(max_length=12, choices=Precipitation.choices, default=Precipitation.NONE)
    weather_suitable = models.BooleanField(null=True)
    weather_missing_reason = models.CharField(max_length=200, blank=True)
    zero_observation_confirmed = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    status = models.CharField(max_length=12, choices=VisitStatus.choices, default=VisitStatus.DRAFT)
    cancel_reason = models.CharField(max_length=20, choices=CancelReason.choices, blank=True)
    battery_saver_used = models.BooleanField(default=False)
    device_id = models.CharField(max_length=64, blank=True)
    created_offline = models.BooleanField(default=True)
    locked_at = models.DateTimeField(null=True, blank=True)
    locked_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, null=True, blank=True,
                                  related_name="+")
    lock_reason = models.TextField(blank=True)
    quality_flags = ArrayField(models.CharField(max_length=40), default=list, blank=True)   # T056
    history = HistoricalRecords(table_name="historical_survey_visit")

    class Meta:
        db_table = "survey_visit"
        indexes = [models.Index(fields=["project", "transect", "started_at"]),
                   models.Index(fields=["observer", "started_at"]),
                   models.Index(fields=["status"])]
        constraints = [
            models.CheckConstraint(condition=models.Q(status__in=VisitStatus.values), name="visit_status_valid"),
            models.CheckConstraint(condition=models.Q(precipitation__in=Precipitation.values), name="visit_precip_valid"),
            models.CheckConstraint(
                condition=(models.Q(status="cancelled") & models.Q(cancel_reason__in=CancelReason.values))
                | (~models.Q(status="cancelled") & models.Q(cancel_reason="")),
                name="visit_cancel_reason_consistent"),
            models.CheckConstraint(condition=models.Q(ended_at__isnull=True) | models.Q(started_at__isnull=True)
                                   | models.Q(ended_at__gte=models.F("started_at")), name="visit_times_ok"),
            models.CheckConstraint(condition=models.Q(observer_count__gte=1), name="visit_observer_count_ok"),
            models.CheckConstraint(condition=(models.Q(wind_beaufort_start__isnull=True) | models.Q(wind_beaufort_start__lte=12))
                                   & (models.Q(wind_beaufort_end__isnull=True) | models.Q(wind_beaufort_end__lte=12)),
                                   name="visit_wind_ok"),
            models.CheckConstraint(condition=(models.Q(cloud_cover_start_pct__isnull=True) | models.Q(cloud_cover_start_pct__lte=100))
                                   & (models.Q(cloud_cover_end_pct__isnull=True) | models.Q(cloud_cover_end_pct__lte=100)),
                                   name="visit_cloud_ok"),
            models.CheckConstraint(
                condition=~models.Q(status="locked") | models.Q(locked_at__isnull=False),
                name="visit_locked_has_timestamp"),
        ]
```

b) PostGIS DDL

```sql
CREATE TABLE survey_visit (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  project_id              uuid NOT NULL REFERENCES project(id),
  transect_id             uuid NOT NULL REFERENCES transect(id),
  observer_id             uuid NOT NULL REFERENCES app_user(id),
  protocol_version        varchar(20) NOT NULL,
  survey_method           varchar(20) NOT NULL CHECK (survey_method IN ('pollard_walk','other')),
  started_at              timestamptz NULL,
  ended_at                timestamptz NULL,
  duration_seconds        integer NULL CHECK (duration_seconds >= 0),
  paused_seconds          integer NOT NULL DEFAULT 0 CHECK (paused_seconds >= 0),
  distance_walked_m       numeric(8,1) NULL,
  observer_count          smallint NOT NULL DEFAULT 1,
  observer_names          varchar(300) NOT NULL,
  temperature_start_c     numeric(4,1) NULL,
  temperature_end_c       numeric(4,1) NULL,
  wind_beaufort_start     smallint NULL,
  wind_beaufort_end       smallint NULL,
  cloud_cover_start_pct   smallint NULL,
  cloud_cover_end_pct     smallint NULL,
  precipitation           varchar(12) NOT NULL DEFAULT 'none'
                          CONSTRAINT visit_precip_valid CHECK (precipitation IN ('none','drizzle','light_rain','rain')),
  weather_suitable        boolean NULL,
  weather_missing_reason  varchar(200) NOT NULL,
  zero_observation_confirmed boolean NOT NULL DEFAULT false,
  notes                   text NOT NULL,
  status                  varchar(12) NOT NULL DEFAULT 'draft'
                          CONSTRAINT visit_status_valid CHECK (status IN
                          ('draft','in_progress','completed','synced','reviewed','locked','cancelled')),
  cancel_reason           varchar(20) NOT NULL DEFAULT '',
  battery_saver_used      boolean NOT NULL DEFAULT false,
  device_id               varchar(64) NOT NULL,
  created_offline         boolean NOT NULL DEFAULT true,
  locked_at               timestamptz NULL,
  locked_by_id            uuid NULL REFERENCES app_user(id),
  lock_reason             text NOT NULL,
  quality_flags           varchar(40)[] NOT NULL DEFAULT '{}',
  CONSTRAINT visit_cancel_reason_consistent CHECK (
    (status = 'cancelled' AND cancel_reason IN ('not_conducted','aborted_weather','aborted_other','invalid_protocol'))
    OR (status <> 'cancelled' AND cancel_reason = '')),
  CONSTRAINT visit_times_ok CHECK (ended_at IS NULL OR started_at IS NULL OR ended_at >= started_at),
  CONSTRAINT visit_observer_count_ok CHECK (observer_count >= 1),
  CONSTRAINT visit_wind_ok CHECK ((wind_beaufort_start IS NULL OR wind_beaufort_start <= 12)
                              AND (wind_beaufort_end IS NULL OR wind_beaufort_end <= 12)),
  CONSTRAINT visit_cloud_ok CHECK ((cloud_cover_start_pct IS NULL OR cloud_cover_start_pct <= 100)
                               AND (cloud_cover_end_pct IS NULL OR cloud_cover_end_pct <= 100)),
  CONSTRAINT visit_locked_has_timestamp CHECK (status <> 'locked' OR locked_at IS NOT NULL)
);
CREATE INDEX survey_visit_proj_tr_start_idx ON survey_visit (project_id, transect_id, started_at);
CREATE INDEX survey_visit_observer_start_idx ON survey_visit (observer_id, started_at);
CREATE INDEX survey_visit_status_idx ON survey_visit (status);
CREATE INDEX survey_visit_server_version_idx ON survey_visit (server_version);
CREATE INDEX survey_visit_flags_gin ON survey_visit USING gin (quality_flags);
-- + trigger
```

c) Drift

```dart
class SurveyVisits extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get transectId => text().references(Transects, #id)();
  TextColumn get observerId => text()();
  TextColumn get protocolVersion => text()();
  TextColumn get surveyMethod => text()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  IntColumn get pausedSeconds => integer().withDefault(const Constant(0))();
  RealColumn get distanceWalkedM => real().nullable()();
  IntColumn get observerCount => integer().withDefault(const Constant(1))();
  TextColumn get observerNames => text().withDefault(const Constant(''))();
  RealColumn get temperatureStartC => real().nullable()();
  RealColumn get temperatureEndC => real().nullable()();
  IntColumn get windBeaufortStart => integer().nullable()();
  IntColumn get windBeaufortEnd => integer().nullable()();
  IntColumn get cloudCoverStartPct => integer().nullable()();
  IntColumn get cloudCoverEndPct => integer().nullable()();
  TextColumn get precipitation => text().withDefault(const Constant('none'))();
  BoolColumn get weatherSuitable => boolean().nullable()();
  TextColumn get weatherMissingReason => text().withDefault(const Constant(''))();
  BoolColumn get zeroObservationConfirmed => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get status => text()();
  TextColumn get cancelReason => text().withDefault(const Constant(''))();
  BoolColumn get batterySaverUsed => boolean().withDefault(const Constant(false))();
  TextColumn get deviceId => text()();
  DateTimeColumn get createdAt => dateTime()();
  // local-only runtime state
  DateTimeColumn get pausedAt => dateTime().nullable()();
  // sync
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<String> get customConstraints => [
    "CHECK (status IN ('draft','in_progress','completed','synced','reviewed','locked','cancelled'))",
  ];
}
```
Differences from the server:
- No `locked_*` columns: lock state arrives as `status = locked`.
- No `quality_flags` (server-only), and `pausedAt` is local runtime state.
- Decimals are stored as `real`.

d) Django-specific limitation
- The automatic `completed → synced` transition happens in the push service, not a signal, so admin edits don't trigger it.
- CHECK constraints referencing `~Q(...)` with blank strings compile as expected on PostgreSQL. VERIFY the generated SQL with `sqlmigrate`.

**Limitations / out of scope / risks**
- **p2-compat:** Phase 2 adds a nullable `weather_source` column (T085) and links from `environmental_snapshot` (T081). Both are additive. Focal-follow sessions may reference a visit (T089) without changing this table.

---

### T035 · App start-visit form
**ID:** T035 · **Implements:** F8 · **Labels:** `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E05 · **Depends on:** T033, T034, T016 · **Estimate:** 1.5 d

**Description**
A short form records the conditions at the start of the walk, then starts GPS tracking (outline §11.2 F).

**Acceptance criteria**
- [ ] Fields:
  - observer (current user, read-only)
  - observer count and other observers' names
  - temperature (°C, numeric keypad, one decimal)
  - wind (Beaufort 0–12 picker with short descriptions)
  - cloud cover (0–100 % slider, step 10)
  - precipitation chips
  - notes
  - **protocol confirmation** checkbox showing the protocol summary
- [ ] Suitability is evaluated live against the project protocol, showing which threshold fails. Starting anyway requires an explicit "Start anyway" and sets `weather_suitable = false`.
- [ ] Season and time-window warnings, without blocking.
- [ ] **Save as draft** or **Start**. Start sets `status = in_progress` and `started_at`, enqueues the create, and starts tracking (T037).
- [ ] Usable one-handed. The form opens in under 1 s (logged by T073).

**Technical explanation**
- Suitable = no precipitation (unless allowed), wind ≤ max, and either temperature ≥ `sunny_temperature_c`, or temperature ≥ `min_temperature_c` with cloud ≤ `max_cloud_cover_pct_if_cool`.
- **p2-compat:** a hidden "Auto-fill weather" button slot is reserved for T085.

**Limitations / out of scope / risks**
- No automatic weather in Phase 1; manual values are authoritative (outline §9.4).

---

### T036 · Track points: model, batch sync and walked distance
**ID:** T036 · **Implements:** F10 · **Labels:** `backend`, `database`, `sync`, `must`, `p2-compat` · **Milestone:** Phase 1 · **Epic:** E05 · **Depends on:** T034, T026 · **Estimate:** 1.5 d

**Description**
Store every recorded GPS fix of a visit, sync them in batches, and compute walked distance and the route line on the server (outline §7.4, §8.6).

**Acceptance criteria**
- [ ] The `SurveyTrackPoint` model accepts `create_batch` pushes (T026) of up to 1000 points, idempotent per point id.
- [ ] On visit completion, the server computes `distance_walked_m` from points ordered by `recorded_at`, excluding points with `accuracy_m > protocol.gps_accuracy_warning_m × 2`. It keeps the client value if the server has fewer than 2 usable points.
- [ ] The admin visit page shows the route as a read-only map: `ST_MakeLine(geometry ORDER BY recorded_at)`.
- [ ] Points are **never** thinned or simplified on the server (raw data kept for Phase 2).

**Database**

a) GeoDjango model

```python
# backend/surveys/models.py (continued)
class LocationProvider(models.TextChoices):
    GPS = "gps"; FUSED = "fused"; NETWORK = "network"; SIMULATED = "simulated"


class SurveyTrackPoint(SyncableModel):          # no HistoricalRecords: append-only, high volume
    survey_visit = models.ForeignKey(SurveyVisit, on_delete=models.CASCADE, related_name="track_points")
    recorded_at = models.DateTimeField()
    geometry = models.PointField(srid=4326)
    accuracy_m = models.DecimalField(max_digits=6, decimal_places=1, null=True, blank=True)
    altitude_m = models.DecimalField(max_digits=7, decimal_places=1, null=True, blank=True)
    speed_m_s = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    heading_deg = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    provider = models.CharField(max_length=10, choices=LocationProvider.choices, default=LocationProvider.GPS)
    sequence_number = models.PositiveIntegerField()

    class Meta:
        db_table = "survey_track_point"
        indexes = [models.Index(fields=["survey_visit", "recorded_at"])]
        constraints = [
            models.UniqueConstraint(fields=["survey_visit", "sequence_number"], name="track_point_seq_unique"),
            models.CheckConstraint(condition=models.Q(provider__in=LocationProvider.values), name="track_point_provider_valid"),
            models.CheckConstraint(condition=models.Q(heading_deg__isnull=True)
                                   | (models.Q(heading_deg__gte=0) & models.Q(heading_deg__lt=360)),
                                   name="track_point_heading_ok"),
        ]
```

b) PostGIS DDL

```sql
CREATE TABLE survey_track_point (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  survey_visit_id uuid NOT NULL REFERENCES survey_visit(id) ON DELETE CASCADE,
  recorded_at     timestamptz NOT NULL,
  geometry        geometry(Point, 4326) NOT NULL,
  accuracy_m      numeric(6,1) NULL,
  altitude_m      numeric(7,1) NULL,
  speed_m_s       numeric(5,2) NULL,
  heading_deg     numeric(5,1) NULL CONSTRAINT track_point_heading_ok CHECK (heading_deg IS NULL OR (heading_deg >= 0 AND heading_deg < 360)),
  provider        varchar(10) NOT NULL DEFAULT 'gps'
                  CONSTRAINT track_point_provider_valid CHECK (provider IN ('gps','fused','network','simulated')),
  sequence_number integer NOT NULL CHECK (sequence_number >= 0),
  CONSTRAINT track_point_seq_unique UNIQUE (survey_visit_id, sequence_number)
);
CREATE INDEX survey_track_point_visit_time_idx ON survey_track_point (survey_visit_id, recorded_at);
CREATE INDEX survey_track_point_geometry_gist ON survey_track_point USING gist (geometry);
CREATE INDEX survey_track_point_server_version_idx ON survey_track_point (server_version);
-- + trigger

-- Distance (used by the completion service):
-- SELECT ST_Length(ST_MakeLine(geometry ORDER BY recorded_at)::geography)
-- FROM survey_track_point WHERE survey_visit_id = $1 AND (accuracy_m IS NULL OR accuracy_m <= $2);
```

c) Drift

```dart
class SurveyTrackPoints extends Table {
  TextColumn get id => text()();
  TextColumn get surveyVisitId => text().references(SurveyVisits, #id)();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracyM => real().nullable()();
  RealColumn get altitudeM => real().nullable()();
  RealColumn get speedMS => real().nullable()();
  RealColumn get headingDeg => real().nullable()();
  TextColumn get provider => text().withDefault(const Constant('gps'))();
  IntColumn get sequenceNumber => integer()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<Set<Column>> get uniqueKeys => [{surveyVisitId, sequenceNumber}];
}
```
Differences from the server:
- lat/lon instead of a geometry.
- No `deletedAt`, because points are never deleted individually.
- An index on `(survey_visit_id, sequence_number)` comes from the unique key.

d) Django-specific limitation
- `bulk_create(ignore_conflicts=True)` is used for batches. Row triggers still fire, but the returned objects have no PKs or versions confirmed. That's fine, because the response only needs counts.
- `ST_MakeLine(... ORDER BY ...)` is an ordered aggregate that Django's `MakeLine` aggregate can't express, so use raw SQL.

**Limitations / out of scope / risks**
- **p2-compat:** this table is the raw input for MobilityDB trajectories in Phase 2: `(geometry, recorded_at)` pairs become a `tgeompoint` sequence (T088). Keep `provider` and `accuracy_m` so Phase 2 can filter, and never drop or resample points.

---

### T037 · App GPS tracking with an Android foreground service
**ID:** T037 · **Implements:** F10, F87 · **Labels:** `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E05 · **Depends on:** T036, T035 · **Estimate:** 3 d

**Description**
Record the observer's position at the project's interval while a visit is active, including with the screen off, and survive the app being killed.

**Acceptance criteria**
- [ ] Uses `geolocator` with `AndroidSettings(accuracy: high, intervalDuration: protocol.gpsIntervalS, distanceFilter: 0, foregroundNotificationConfig: ...)`, showing a persistent "Visit in progress: T01" notification (VERIFY the current API names).
- [ ] Manifest permissions:
  - `ACCESS_FINE_LOCATION`
  - `FOREGROUND_SERVICE`
  - `FOREGROUND_SERVICE_LOCATION` (Android 14+)
  - `POST_NOTIFICATIONS` (13+)
  - `ACCESS_BACKGROUND_LOCATION` is **not** requested if tracking always starts from the foreground (VERIFY on a test device)
- [ ] Points are buffered and written to Drift every 10 points or 30 s, whichever comes first, with `sequenceNumber` continuing across restarts.
- [ ] **Process death:** on app start with an `in_progress` visit, tracking resumes automatically and the gap is shown ("Tracking interrupted 10:42–10:47").
- [ ] Interval comes from the project protocol, with an optional per-device override in settings.
- [ ] Prompts the user once to exempt the app from battery optimisation (some manufacturers kill foreground services).
- [ ] 60 minutes with the screen off at a 5 s interval produce about 720 points with no gaps longer than 30 s on the test phone (measured in T074).

**Technical explanation**
- A `LocationSource` interface has implementations `GeolocatorSource` and `ReplaySource` (T072), so tests and demos can replay GPX.
- A Riverpod `trackingController` owns the stream.

**Limitations / out of scope / risks**
- Some OEM Android builds (Xiaomi, Huawei) are aggressive about killing services. Document the device used in the thesis.
- Battery impact is measured in T074.

---

### T038 · Battery-saving mode and GPS gap detection
**ID:** T038 · **Implements:** F87 · **Labels:** `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E05 · **Depends on:** T037 · **Estimate:** 1 d

**Description**
Let the observer trade accuracy for battery, and warn when GPS stops delivering fixes (outline §21 Battery).

**Acceptance criteria**
- [ ] A toggle on the active visit switches to `gpsIntervalBatterySaverS` and `LocationAccuracy.medium`, and sets `battery_saver_used = true` on the visit.
- [ ] It switches automatically below 20 % battery (`battery_plus`), with a snackbar.
- [ ] A banner shows "No GPS fix for N s" when no point arrives within `gps_gap_s`.
- [ ] Gaps are visible later on the visit summary (T040).

**Limitations / out of scope / risks**
- The server computes the `gps_gap` flag independently from timestamps (T056). This banner is only live feedback.

---

### T039 · App active visit screen
**ID:** T039 · **Implements:** F11 · **Labels:** `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E05 · **Depends on:** T037 · **Estimate:** 2.5 d

**Description**
This is the main field screen during a walk (outline §11.2 G): map, progress and big entry buttons.

**Acceptance criteria**
- [ ] The map shows the transect line, sections (current one highlighted), the current position with an accuracy circle, and the walked route.
- [ ] A header shows elapsed time excluding pauses, distance walked, current section code and number of observations.
- [ ] A large **Add butterfly** button (opens T045), plus **Add plant** (T052) and **Add habitat** (T054).
- [ ] **Pause/Resume:** while paused, no track points are stored and `paused_seconds` accumulates. Observations are still allowed during a pause but warned about.
- [ ] **Finish** goes to T040.
- [ ] An optional keep-screen-on toggle (`wakelock_plus`).
- [ ] Works fully offline.

**Technical explanation**
The current section is the nearest section line within `maxDistanceFromTransectM`, computed in Dart (point-to-segment distance on a local equirectangular projection). That is accurate to well under a metre at transect scale.

**Limitations / out of scope / risks**
- The map has no basemap offline unless T060 is done. Transect lines and the route still show on a blank background.

---

### T040 · Finish visit: summary, warnings and end weather
**ID:** T040 · **Implements:** F11 · **Labels:** `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E05 · **Depends on:** T039, T055 · **Estimate:** 2 d

**Description**
Before saving, show the observer what they recorded and what's missing (outline §11.2 J).

**Acceptance criteria**
- [ ] Summary: duration, distance, number of species, number of individuals, number of observations per section.
- [ ] **Warnings:**
  - missing end weather
  - route coverage below `min_coverage_pct`
  - GPS gaps
  - outside the time window
  - observations with missing required fields
- [ ] Coverage = share of points sampled every 10 m along the transect that have a route point within `maxDistanceFromTransectM`.
- [ ] End-weather fields are required unless `weather_missing_reason` is given (rule V05).
- [ ] If zero observations, the true-zero confirmation is shown (T041).
- [ ] **Finish and save** sets `status = completed`, `ended_at`, `duration_seconds`, `distance_walked_m`, stops tracking and triggers a sync.
- [ ] **Cancel visit** opens T041's cancel flow.

**Limitations / out of scope / risks**
- Coverage is an approximation on the phone. The server does not recompute it in Phase 1 (only 4 flags, T056).

---

### T041 · True-zero confirmation and cancelled-visit reasons
**ID:** T041 · **Implements:** F12, F9 · **Labels:** `mobile`, `backend`, `must` · **Milestone:** Phase 1 · **Epic:** E05 · **Depends on:** T040 · **Estimate:** 1 d

**Description**
Separate "walked the full transect and saw nothing" from "didn't go", "gave up" and "invalid" (outline §7.3).

**Acceptance criteria**
- [ ] Finishing a visit with zero transect observations requires ticking: *"No butterfly was seen during the complete standardised visit."* This sets `zero_observation_confirmed = true`.
- [ ] Server rule V06 (T055):
  - a completed visit with zero `source = transect` observations must have `zero_observation_confirmed = true`
  - a visit with observations must have it `false`

  Violations are rejected.
- [ ] Cancel flow offers four reasons: `not_conducted` (planned but not walked; can be recorded without starting), `aborted_weather`, `aborted_other` and `invalid_protocol`, plus a note.
- [ ] Exports (T064) show the visit outcome as one of `completed_with_records`, `true_zero`, `cancelled:<reason>`.
- [ ] Unit tests on both sides.

**Limitations / out of scope / risks**
- "Missing data" is represented by the absence of a visit, which can only be detected against the target visit frequency (`target_visits_per_season`) in indicators.

---

### T042 · Visit lock enforced in the API
**ID:** T042 · **Implements:** F13 · **Labels:** `backend`, `sync`, `must` · **Milestone:** Phase 1 · **Epic:** E05 · **Depends on:** T034, T026 · **Estimate:** 1 d

**Description**
Once an admin locks a visit in Django admin, nothing can change it or its records until it is unlocked (MVP criterion 13). Otherwise a phone syncing later would silently overwrite reviewed data.

**Acceptance criteria**
- [ ] Push and REST reject (`code = "visit_locked"`) any create, update or delete of a locked visit, and of any observation, track point, plant resource, habitat feature or photo belonging to a locked visit.
- [ ] Django admin: `has_change_permission` returns `False` for a locked visit and its children, with a "Locked by X on Y: reason" banner. The only way back is the Unlock action (T043).
- [ ] App: on pull, a locked visit and its records become read-only, with a lock icon. Local pending edits on it end up `rejected`, with a clear message on the sync screen.
- [ ] Tests for each child entity type.

**Limitations / out of scope / risks**
- Admins can unlock, edit and re-lock. Every step is in the audit log (T018).

---

### T043 · Admin visit review, lock and unlock with mandatory reason
**ID:** T043 · **Implements:** F66 · **Labels:** `admin`, `must` · **Milestone:** Phase 1 · **Epic:** E05 · **Depends on:** T042, T018 · **Estimate:** 1.5 d

**Description**
Admins review visits, then lock finished ones. Unlocking requires a written reason that ends up in the audit log.

**Acceptance criteria**
- [ ] `SurveyVisitAdmin` list: transect, observer, start, duration, distance, observation count, status, flags. Filters: project, transect, status, observer, date, flag.
- [ ] Inlines: observations (read-only summary with links) and a route map.
- [ ] Actions: **Mark reviewed**, **Lock**, **Unlock**. Lock and unlock use an intermediate form with a required reason (at least 10 characters) and set `locked_at`, `locked_by` and `lock_reason` (cleared on unlock).
- [ ] The history row carries the reason as `history_change_reason`.
- [ ] Invalid transitions (for example locking a draft) show an error per visit without failing the whole action.

**Limitations / out of scope / risks**
- There is no API lock endpoint (v4 decision, conflict 5).

---
## E06 · Butterfly observations and photos

### E06 · Epic: Butterfly observations and photos
**Labels:** `epic`, `mobile`, `backend` · **Milestone:** Phase 1 · **Implements:** F14, F15, F16, F17, F19, F27
Fast entry of butterfly records during a walk, optional detail, incidental records, automatic section assignment and photos with deduplicated upload.
Children: T044 · T045 · T046 · T047 · T048 · T049 · T050

---

### T044 · ButterflyObservation model and API
**ID:** T044 · **Implements:** F14, F15, F17 · **Labels:** `backend`, `database`, `sync`, `must`, `p2-compat` · **Milestone:** Phase 1 · **Epic:** E06 · **Depends on:** T034, T019, T026 · **Estimate:** 2.5 d

**Description**
This is the core biological record: what was seen, how many, where, when, how sure, and in which context (outline §8.8–§8.12). It also removes the walking-skeleton stub (T007).

**Acceptance criteria**
- [ ] The model below, with push and pull registration and REST endpoints (outline §14):
  - `POST /api/v1/observations`
  - `GET /api/v1/observations/{id}`
  - `PATCH /api/v1/observations/{id}`
  - `DELETE /api/v1/observations/{id}` (soft delete)
- [ ] `validation_status` is set by the server on create: `pending` when confidence is `photo_required`, `expert_review_required`, `unknown` or `genus_only`, or when the taxon has `photo_required` and no photo exists; otherwise `not_required`.
- [ ] Server-owned fields are read-only for clients: all `validation_*` fields and `quality_flags`.
- [ ] `behaviour` accepts a list of values from the fixed enum (multi-select, outline §8.12).
- [ ] Migration drops `skeleton_ping` and `geo.skeleton_pings` (and the pygeoapi collection in T068). The Drift migration drops `skeleton_pings`.
- [ ] `photo_count` (outline field) is computed in serializers and views, not stored.

**Database**

a) GeoDjango model

```python
# backend/observations/models.py
from django.conf import settings
from django.contrib.gis.db import models
from django.contrib.postgres.fields import ArrayField
from simple_history.models import HistoricalRecords
from core.models import SyncableModel


class Confidence(models.TextChoices):
    CONFIRMED_IN_FIELD = "confirmed_in_field"; PROBABLE = "probable"; PHOTO_REQUIRED = "photo_required"
    GENUS_ONLY = "genus_only"; SPECIES_GROUP = "species_group"; UNKNOWN = "unknown"
    EXPERT_REVIEW_REQUIRED = "expert_review_required"

class Sex(models.TextChoices):
    MALE = "male"; FEMALE = "female"; MIXED = "mixed"; UNKNOWN = "unknown"; NOT_APPLICABLE = "not_applicable"

class LifeStage(models.TextChoices):
    EGG = "egg"; LARVA = "larva"; PUPA = "pupa"; ADULT = "adult"; UNKNOWN = "unknown"

class Behaviour(models.TextChoices):
    FLYING = "flying"; RESTING = "resting"; BASKING = "basking"; NECTARING = "nectaring"
    COURTSHIP = "courtship"; MATING = "mating"; TERRITORIAL = "territorial"; OVIPOSITION = "oviposition"
    MUD_PUDDLING = "mud_puddling"; FEEDING_ON_FRUIT = "feeding_on_fruit"; FEEDING_ON_SAP = "feeding_on_sap"
    LARVAL_FEEDING = "larval_feeding"; OTHER = "other"; UNKNOWN = "unknown"

class ObservationSource(models.TextChoices):
    TRANSECT = "transect"; INCIDENTAL = "incidental"; FOCAL_FOLLOW = "focal_follow"   # focal_follow used from Phase 2
    LARVAL_SEARCH = "larval_search"; HOST_PLANT_SEARCH = "host_plant_search"

class ValidationStatus(models.TextChoices):
    NOT_REQUIRED = "not_required"; PENDING = "pending"; CONFIRMED = "confirmed"
    UNCONFIRMED = "unconfirmed"; UNDETERMINABLE = "undeterminable"


class ButterflyObservation(SyncableModel):
    project = models.ForeignKey("projects.Project", on_delete=models.PROTECT, related_name="observations")
    survey_visit = models.ForeignKey("surveys.SurveyVisit", on_delete=models.PROTECT, null=True, blank=True,
                                     related_name="observations")
    transect_section = models.ForeignKey("transects.TransectSection", on_delete=models.SET_NULL,
                                         null=True, blank=True, related_name="observations")
    observed_at = models.DateTimeField()
    taxon = models.ForeignKey("catalogues.Taxon", on_delete=models.PROTECT, related_name="observations")
    count = models.PositiveIntegerField(default=1)
    geometry = models.PointField(srid=4326)
    location_accuracy_m = models.DecimalField(max_digits=6, decimal_places=1, null=True, blank=True)
    identification_confidence = models.CharField(max_length=30, choices=Confidence.choices,
                                                 default=Confidence.CONFIRMED_IN_FIELD)
    recorded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="observations")
    sex = models.CharField(max_length=15, choices=Sex.choices, default=Sex.UNKNOWN)
    life_stage = models.CharField(max_length=10, choices=LifeStage.choices, default=LifeStage.ADULT)
    behaviour = ArrayField(models.CharField(max_length=20, choices=Behaviour.choices), default=list, blank=True)
    microhabitat = models.CharField(max_length=100, blank=True)
    flight_direction_deg = models.PositiveSmallIntegerField(null=True, blank=True)
    notes = models.TextField(blank=True)
    source = models.CharField(max_length=20, choices=ObservationSource.choices, default=ObservationSource.TRANSECT)
    # host_plant_record / nectar_plant_record FKs are added in T051
    validation_status = models.CharField(max_length=15, choices=ValidationStatus.choices,
                                         default=ValidationStatus.NOT_REQUIRED)
    validated_taxon = models.ForeignKey("catalogues.Taxon", on_delete=models.PROTECT, null=True, blank=True,
                                        related_name="+")
    validated_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, null=True, blank=True,
                                     related_name="+")
    validated_at = models.DateTimeField(null=True, blank=True)
    validation_comment = models.TextField(blank=True)
    quality_flags = ArrayField(models.CharField(max_length=40), default=list, blank=True)
    history = HistoricalRecords(table_name="historical_butterfly_observation")

    class Meta:
        db_table = "butterfly_observation"
        indexes = [models.Index(fields=["project", "observed_at"]), models.Index(fields=["taxon"]),
                   models.Index(fields=["survey_visit"]), models.Index(fields=["validation_status"])]
        constraints = [
            models.CheckConstraint(condition=models.Q(count__gte=1), name="obs_count_positive"),
            models.CheckConstraint(condition=models.Q(identification_confidence__in=Confidence.values), name="obs_confidence_valid"),
            models.CheckConstraint(condition=models.Q(sex__in=Sex.values), name="obs_sex_valid"),
            models.CheckConstraint(condition=models.Q(life_stage__in=LifeStage.values), name="obs_life_stage_valid"),
            models.CheckConstraint(condition=models.Q(source__in=ObservationSource.values), name="obs_source_valid"),
            models.CheckConstraint(condition=models.Q(validation_status__in=ValidationStatus.values), name="obs_validation_valid"),
            models.CheckConstraint(condition=models.Q(behaviour__contained_by=Behaviour.values), name="obs_behaviour_valid"),
            models.CheckConstraint(condition=~models.Q(source="transect") | models.Q(survey_visit__isnull=False),
                                   name="obs_transect_needs_visit"),
            models.CheckConstraint(condition=models.Q(flight_direction_deg__isnull=True) | models.Q(flight_direction_deg__lt=360),
                                   name="obs_flight_dir_ok"),
        ]
```

b) PostGIS DDL

```sql
CREATE TABLE butterfly_observation (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  project_id                uuid NOT NULL REFERENCES project(id),
  survey_visit_id           uuid NULL REFERENCES survey_visit(id),
  transect_section_id       uuid NULL REFERENCES transect_section(id) ON DELETE SET NULL,
  observed_at               timestamptz NOT NULL,
  taxon_id                  uuid NOT NULL REFERENCES taxon(id),
  count                     integer NOT NULL DEFAULT 1 CONSTRAINT obs_count_positive CHECK (count >= 1),
  geometry                  geometry(Point, 4326) NOT NULL,
  location_accuracy_m       numeric(6,1) NULL,
  identification_confidence varchar(30) NOT NULL
      CONSTRAINT obs_confidence_valid CHECK (identification_confidence IN ('confirmed_in_field','probable',
      'photo_required','genus_only','species_group','unknown','expert_review_required')),
  recorded_by_id            uuid NOT NULL REFERENCES app_user(id),
  sex                       varchar(15) NOT NULL
      CONSTRAINT obs_sex_valid CHECK (sex IN ('male','female','mixed','unknown','not_applicable')),
  life_stage                varchar(10) NOT NULL
      CONSTRAINT obs_life_stage_valid CHECK (life_stage IN ('egg','larva','pupa','adult','unknown')),
  behaviour                 varchar(20)[] NOT NULL DEFAULT '{}'
      CONSTRAINT obs_behaviour_valid CHECK (behaviour <@ ARRAY['flying','resting','basking','nectaring','courtship',
      'mating','territorial','oviposition','mud_puddling','feeding_on_fruit','feeding_on_sap','larval_feeding',
      'other','unknown']::varchar(20)[]),
  microhabitat              varchar(100) NOT NULL,
  flight_direction_deg      smallint NULL CONSTRAINT obs_flight_dir_ok CHECK (flight_direction_deg IS NULL OR flight_direction_deg < 360),
  notes                     text NOT NULL,
  source                    varchar(20) NOT NULL DEFAULT 'transect'
      CONSTRAINT obs_source_valid CHECK (source IN ('transect','incidental','focal_follow','larval_search','host_plant_search')),
  validation_status         varchar(15) NOT NULL DEFAULT 'not_required'
      CONSTRAINT obs_validation_valid CHECK (validation_status IN ('not_required','pending','confirmed','unconfirmed','undeterminable')),
  validated_taxon_id        uuid NULL REFERENCES taxon(id),
  validated_by_id           uuid NULL REFERENCES app_user(id),
  validated_at              timestamptz NULL,
  validation_comment        text NOT NULL,
  quality_flags             varchar(40)[] NOT NULL DEFAULT '{}',
  CONSTRAINT obs_transect_needs_visit CHECK (source <> 'transect' OR survey_visit_id IS NOT NULL)
);
CREATE INDEX butterfly_observation_geometry_gist ON butterfly_observation USING gist (geometry);
CREATE INDEX butterfly_observation_proj_time_idx ON butterfly_observation (project_id, observed_at);
CREATE INDEX butterfly_observation_taxon_idx ON butterfly_observation (taxon_id);
CREATE INDEX butterfly_observation_visit_idx ON butterfly_observation (survey_visit_id);
CREATE INDEX butterfly_observation_validation_idx ON butterfly_observation (validation_status);
CREATE INDEX butterfly_observation_flags_gin ON butterfly_observation USING gin (quality_flags);
CREATE INDEX butterfly_observation_server_version_idx ON butterfly_observation (server_version);
-- + trigger
```

c) Drift

```dart
class ButterflyObservations extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get surveyVisitId => text().nullable().references(SurveyVisits, #id)();
  TextColumn get transectSectionId => text().nullable()();
  DateTimeColumn get observedAt => dateTime()();
  TextColumn get taxonId => text().references(Taxa, #id)();
  IntColumn get count => integer().withDefault(const Constant(1))();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get locationAccuracyM => real().nullable()();
  TextColumn get identificationConfidence => text()();
  TextColumn get recordedById => text()();
  TextColumn get sex => text().withDefault(const Constant('unknown'))();
  TextColumn get lifeStage => text().withDefault(const Constant('adult'))();
  TextColumn get behaviour => text().withDefault(const Constant('[]'))();   // JSON array
  TextColumn get microhabitat => text().withDefault(const Constant(''))();
  IntColumn get flightDirectionDeg => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get source => text().withDefault(const Constant('transect'))();
  TextColumn get hostPlantRecordId => text().nullable()();     // T051
  TextColumn get nectarPlantRecordId => text().nullable()();   // T051
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<String> get customConstraints => [
    "CHECK (count >= 1)",
    "CHECK (source <> 'transect' OR survey_visit_id IS NOT NULL)",
  ];
}
```
Differences from the server:
- lat/lon instead of a geometry.
- `behaviour` is a JSON text array.
- **No validation fields and no `quality_flags`.** They are server-owned, and the app doesn't display validation (F76 removed).

d) Django-specific limitation
- `ArrayField(... choices=...)` validates choices in forms only. The DB CHECK uses `contained_by` (`<@`); VERIFY that Django renders the `contained_by` lookup inside a `CheckConstraint`, or write this one constraint as `RunSQL`.
- Admin needs a custom multi-select widget for the array (`forms.MultipleChoiceField` wrapper).

**Limitations / out of scope / risks**
- **p2-compat:** `source = focal_follow` exists now but is unused. Phase 2 links a focal-follow session to its observation from the session side (T089), so this table only gains rows, not columns.

---

### T045 · App quick butterfly entry
**ID:** T045 · **Implements:** F14 · **Labels:** `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E06 · **Depends on:** T044, T039 · **Estimate:** 2.5 d

**Description**
Record a common butterfly in a few seconds (outline §11.2 H, level 1). GPS and time fill in automatically.

**Acceptance criteria**
- [ ] A bottom sheet opens from **Add butterfly** with: recent species (last 8 used in this project), favourites (star toggle), search, count stepper (+/−, long-press to type) and **Save**.
- [ ] Search matches scientific, Serbian and English names, is diacritics-insensitive (`searchText`, T019), matches as you type, and returns in under 100 ms for 300 taxa.
- [ ] A repeat species takes **≤ 3 taps** (open, tap species, save); measured by T073.
- [ ] Position comes from the latest fix (accuracy shown, with a warning above `gpsAccuracyWarningM`). Time is "now".
- [ ] Section = current section (T039). Confidence defaults to `confirmed_in_field`.
- [ ] An **Undo** snackbar for 10 s soft-deletes the last record.
- [ ] Local table `taxon_usage` stores favourites and recent use.

**Database**

c) Drift (local only)

```dart
class TaxonUsage extends Table {
  TextColumn get projectId => text()();
  TextColumn get taxonId => text()();
  BoolColumn get isFavourite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {projectId, taxonId};
}
```

**Limitations / out of scope / risks**
- Favourites are per device and not synced (deliberate; nothing on the server needs them).

---

### T046 · App extended entry
**ID:** T046 · **Implements:** F15 · **Labels:** `mobile`, `should` · **Milestone:** Phase 1 · **Epic:** E06 · **Depends on:** T045 · **Estimate:** 1.5 d

**Description**
Optionally add detail to an observation (outline §11.2 H, level 2), during or after the walk.

**Acceptance criteria**
- [ ] An expandable section in the entry sheet, also reachable by editing an existing observation:
  - sex
  - life stage
  - behaviour (multi-select chips)
  - identification confidence
  - microhabitat
  - flight direction (compass dial, optional)
  - notes
  - photo (T050)
  - plant link (T051/T052)
- [ ] Prompts (rules W03, W04):
  - selecting `oviposition` offers "Link to host plant", picking an existing plant record of this visit or creating one
  - `life_stage = larva` offers the same
- [ ] Selecting confidence `photo_required` prompts for a photo.
- [ ] Editing a synced observation creates an `update` mutation with `baseVersion` (T029).

**Limitations / out of scope / risks**
- Edits to observations of locked visits are blocked (T042).

---

### T047 · Incidental and other-source observations
**ID:** T047 · **Implements:** F17 · **Labels:** `mobile`, `backend`, `should` · **Milestone:** Phase 1 · **Epic:** E06 · **Depends on:** T045 · **Estimate:** 1 d

**Description**
Record butterflies seen outside a standard walk: incidental sightings, larval searches and host-plant searches.

**Acceptance criteria**
- [ ] The **Free observation** tile (project home) and a map long-press open the same entry sheet with a **source** picker: `incidental`, `larval_search`, `host_plant_search`.
- [ ] No visit is needed (`survey_visit_id = null`). Position comes from GPS, or from the long-pressed or dragged map position, with accuracy set to `null` when placed manually.
- [ ] These records are excluded from per-km and per-hour indicators (T061, T062) but included in species lists and exports.

**Limitations / out of scope / risks**
- There is no effort data for incidental records, by definition.

---

### T048 · Automatic section assignment
**ID:** T048 · **Implements:** F19 · **Labels:** `backend`, `should` · **Milestone:** Phase 1 · **Epic:** E06 · **Depends on:** T044 · **Estimate:** 1 d

**Description**
Every transect observation is linked to the section it was seen in, so it can be analysed per habitat (outline §8.4).

**Acceptance criteria**
- [ ] The app sends its current-section guess (T039). If the client sends `null`, the server assigns the nearest section of the visit's transect within `max_distance_from_transect_m`.
- [ ] A client-sent section is kept unless it belongs to a different transect, which is rejected.
- [ ] Observations farther than the threshold get no section and the `far_from_transect` flag (T056).
- [ ] Admin action **Reassign sections** recomputes for selected observations (saved per row, so history applies).
- [ ] Tests with the seeded demo transects.

**Technical explanation**

```sql
SELECT s.id FROM transect_section s
WHERE s.transect_id = :transect AND s.deleted_at IS NULL
  AND ST_DWithin(s.geometry::geography, :point::geography, :max_m)
ORDER BY s.geometry::geography <-> :point::geography LIMIT 1;
```

**Limitations / out of scope / risks**
- Phone GPS error (5–15 m) can put an observation in the neighbouring section near section boundaries. Document it as a known limitation.

---

### T049 · Photo model and upload API with SHA-256 deduplication
**ID:** T049 · **Implements:** F27, F16 · **Labels:** `backend`, `database`, `sync`, `must` · **Milestone:** Phase 1 · **Epic:** E06 · **Depends on:** T044, T003 · **Estimate:** 2.5 d

**Description**
Photo metadata syncs like any record. The binary uploads separately in three resumable steps through Django to MinIO, and identical files are stored once (outline §8.13, §14 Photos).

**Acceptance criteria**
- [ ] Photo metadata arrives by push (`create`).
- [ ] `POST /api/v1/attachments/init` with `{photo_id, sha256, file_size, mime_type}`:
  - returns `{status: "exists"}` if an uploaded object with that SHA-256 already exists; the photo is linked to it immediately
  - otherwise returns `{status: "upload_required", upload_url}`
- [ ] `PUT /api/v1/attachments/{id}/content` (raw body, `Content-Type: image/jpeg`) streams to a temp file, verifies SHA-256 and size, and stores to `photos/<aa>/<bb>/<sha256>.jpg`. Mismatches return 422. Re-PUT is allowed until complete.
- [ ] `POST /api/v1/attachments/{id}/complete` sets `uploaded_at` and creates a 400 px thumbnail at `thumbs/<sha256>.jpg` (Pillow, EXIF orientation applied). It is idempotent.
- [ ] `GET /api/v1/photos/{id}/content` and `/thumbnail` are allowed for the owner or admins and streamed from storage. The phone never talks to MinIO directly.
- [ ] Max size 15 MB (nginx `client_max_body_size 20m`). Allowed types: JPEG, PNG.
- [ ] MVP criterion 9: re-uploading the same file twice creates one stored object (tested).

**Database**

a) GeoDjango model

```python
# backend/observations/models.py (continued)
class UploadStatus(models.TextChoices):
    PENDING = "pending"; UPLOADED = "uploaded"


class Photo(SyncableModel):
    observation = models.ForeignKey(ButterflyObservation, on_delete=models.CASCADE, null=True, blank=True,
                                    related_name="photos")
    # plant_resource FK added in T051
    local_path = models.CharField(max_length=500, blank=True)      # informational, from the phone
    storage_key = models.CharField(max_length=200, blank=True)     # outline: server_uri
    mime_type = models.CharField(max_length=50)
    file_size = models.PositiveIntegerField()
    sha256 = models.CharField(max_length=64)
    width = models.PositiveIntegerField(null=True, blank=True)
    height = models.PositiveIntegerField(null=True, blank=True)
    captured_at = models.DateTimeField()
    uploaded_at = models.DateTimeField(null=True, blank=True)
    upload_status = models.CharField(max_length=10, choices=UploadStatus.choices, default=UploadStatus.PENDING)
    is_primary = models.BooleanField(default=False)
    metadata_json = models.JSONField(default=dict, blank=True)
    history = HistoricalRecords(table_name="historical_photo")

    class Meta:
        db_table = "photo"
        indexes = [models.Index(fields=["sha256"]), models.Index(fields=["upload_status"])]
        constraints = [
            models.CheckConstraint(condition=models.Q(sha256__regex=r"^[0-9a-f]{64}$"), name="photo_sha256_format"),
            models.CheckConstraint(condition=models.Q(mime_type__in=["image/jpeg", "image/png"]), name="photo_mime_valid"),
            models.CheckConstraint(condition=models.Q(upload_status__in=UploadStatus.values), name="photo_upload_status_valid"),
            models.CheckConstraint(condition=~models.Q(upload_status="uploaded") | ~models.Q(storage_key=""),
                                   name="photo_uploaded_has_key"),
            models.UniqueConstraint(fields=["observation"], condition=models.Q(is_primary=True, deleted_at__isnull=True),
                                    name="photo_one_primary_per_observation"),
        ]
```

b) PostGIS DDL

```sql
CREATE TABLE photo (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  observation_id uuid NULL REFERENCES butterfly_observation(id) ON DELETE CASCADE,
  local_path     varchar(500) NOT NULL,
  storage_key    varchar(200) NOT NULL,
  mime_type      varchar(50) NOT NULL CONSTRAINT photo_mime_valid CHECK (mime_type IN ('image/jpeg','image/png')),
  file_size      integer NOT NULL CHECK (file_size >= 0),
  sha256         varchar(64) NOT NULL CONSTRAINT photo_sha256_format CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  width          integer NULL,
  height         integer NULL,
  captured_at    timestamptz NOT NULL,
  uploaded_at    timestamptz NULL,
  upload_status  varchar(10) NOT NULL DEFAULT 'pending'
                 CONSTRAINT photo_upload_status_valid CHECK (upload_status IN ('pending','uploaded')),
  is_primary     boolean NOT NULL DEFAULT false,
  metadata_json  jsonb NOT NULL DEFAULT '{}',
  CONSTRAINT photo_uploaded_has_key CHECK (upload_status <> 'uploaded' OR storage_key <> '')
);
CREATE INDEX photo_sha256_idx ON photo (sha256);
CREATE INDEX photo_upload_status_idx ON photo (upload_status);
CREATE UNIQUE INDEX photo_one_primary_per_observation ON photo (observation_id)
  WHERE is_primary AND deleted_at IS NULL;
CREATE INDEX photo_server_version_idx ON photo (server_version);
-- + trigger (T051 adds plant_resource_id and the "exactly one parent" CHECK)
```

c) Drift

```dart
enum LocalUploadStatus { pendingMeta, pendingUpload, uploaded }

class Photos extends Table {
  TextColumn get id => text()();
  TextColumn get observationId => text().nullable()();
  TextColumn get plantResourceId => text().nullable()();     // T051
  TextColumn get localPath => text()();                      // app documents dir
  TextColumn get sha256 => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSize => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  DateTimeColumn get capturedAt => dateTime()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  TextColumn get uploadStatus => textEnum<LocalUploadStatus>()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```
Differences from the server:
- No `storage_key` or `metadata_json`.
- `uploadStatus` has an extra local state, `pendingMeta`, meaning the metadata row is not yet pushed.

d) Django-specific limitation
- Large raw `PUT` bodies: read `request.stream` in chunks rather than `request.body`, and set `DATA_UPLOAD_MAX_MEMORY_SIZE` so Django doesn't refuse.
- `default_storage.save()` with django-storages S3 does a single PUT for small files and multipart above the threshold. Both are fine at 15 MB.

**Limitations / out of scope / risks**
- **MinIO maintenance status:** see A.3. Only the storage backend settings change if MinIO is swapped.
- EXIF GPS stripping was removed with F75, because photos are never public.

---

### T050 · App photo capture, compression and upload
**ID:** T050 · **Implements:** F16, F27 · **Labels:** `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E06 · **Depends on:** T049, T045, T030 (photo button moves into T046's extended section once that exists) · **Estimate:** 2.5 d

**Description**
Take photos for an observation (or a plant, after T052), keep them offline and upload them reliably when syncing.

**Acceptance criteria**
- [ ] Capture with `image_picker` (camera) or pick from the gallery. Several photos per observation, one marked primary.
- [ ] Compress to max 2048 px on the long edge, JPEG quality 85 (`flutter_image_compress`), with EXIF orientation applied. The original camera file is deleted after compression.
- [ ] Saved to `<app documents>/photos/<photoId>.jpg`. SHA-256 is computed in an isolate. The metadata row and queue item are created atomically.
- [ ] The sync runner (T030) runs after push: for each photo with `pendingUpload`, init, then PUT, then complete, with resume on failure (re-init is safe).
- [ ] An optional "Upload photos on Wi-Fi only" setting.
- [ ] Thumbnails appear in the observation detail. Deleting a photo is a soft delete that syncs.
- [ ] Local photo storage use is shown on the sync screen (T032).

**Limitations / out of scope / risks**
- If the user clears app data, un-uploaded photos are lost. A warning appears on the sync screen while photos are pending.

---
## E07 · Plants and habitat

### E07 · Epic: Plants and habitat
**Labels:** `epic`, `mobile`, `backend` · **Milestone:** Phase 1 · **Implements:** F20, F21
Map host and nectar plants as points or polygons and record habitat features. These feed research questions 1, 3 and 4 (habitat differences, specialists and host plants, oviposition microhabitats).
Children: T051 · T052 · T053 · T054

---

### T051 · PlantResourceObservation model and API
**ID:** T051 · **Implements:** F20 · **Labels:** `backend`, `database`, `sync`, `should` · **Milestone:** Phase 1 · **Epic:** E07 · **Depends on:** T044, T049, T020 · **Estimate:** 1.5 d

**Description**
A plant record says which plant, what role it plays for butterflies, where it is (point or patch polygon), and what state it's in (outline §8.15). This ticket also links butterfly observations and photos to plant records.

**Acceptance criteria**
- [ ] Model, push and pull registration, and REST (outline §14):
  - `POST /api/v1/plant-resources`
  - `PATCH /api/v1/plant-resources/{id}`
- [ ] Geometry must be `POINT` or `POLYGON` (CHECK), and be valid (`ST_IsValid`, rule V08).
- [ ] `patch_area_m2` is computed by the server for polygons when the client leaves it empty (`ST_Area(geometry::geography)`).
- [ ] Adds `ButterflyObservation.host_plant_record` and `nectar_plant_record` (nullable FKs), and `Photo.plant_resource` with a CHECK that a photo has exactly one parent.
- [ ] `plant_taxon` may be null for unidentified plants. Then `notes` is required (serializer rule).

**Database**

a) GeoDjango model

```python
# backend/resources/models.py
from django.contrib.gis.db import models
from simple_history.models import HistoricalRecords
from core.models import SyncableModel


class ResourceType(models.TextChoices):
    LARVAL_HOST = "larval_host"; NECTAR_SOURCE = "nectar_source"; OVIPOSITION_PLANT = "oviposition_plant"
    RESTING_PLANT = "resting_plant"; UNKNOWN_ASSOCIATION = "unknown_association"

class AbundanceClass(models.TextChoices):            # individuals or flowering stems in the patch
    A_1 = "1"; B_2_10 = "2-10"; C_11_100 = "11-100"; D_101_1000 = "101-1000"; E_GT_1000 = ">1000"

class PhenologyStage(models.TextChoices):
    VEGETATIVE = "vegetative"; BUDDING = "budding"; FLOWERING = "flowering"
    FRUITING = "fruiting"; SENESCENT = "senescent"

class Intensity(models.TextChoices):
    NONE = "none"; LOW = "low"; MEDIUM = "medium"; HIGH = "high"


class PlantResourceObservation(SyncableModel):
    project = models.ForeignKey("projects.Project", on_delete=models.PROTECT, related_name="plant_resources")
    survey_visit = models.ForeignKey("surveys.SurveyVisit", on_delete=models.PROTECT, null=True, blank=True,
                                     related_name="plant_resources")
    plant_taxon = models.ForeignKey("catalogues.PlantTaxon", on_delete=models.PROTECT, null=True, blank=True)
    resource_type = models.CharField(max_length=20, choices=ResourceType.choices)
    observed_at = models.DateTimeField()
    geometry = models.GeometryField(srid=4326)
    abundance_class = models.CharField(max_length=10, choices=AbundanceClass.choices, blank=True)
    patch_area_m2 = models.DecimalField(max_digits=10, decimal_places=1, null=True, blank=True)
    phenology_stage = models.CharField(max_length=12, choices=PhenologyStage.choices, blank=True)
    flowering_intensity = models.CharField(max_length=6, choices=Intensity.choices, blank=True)
    eggs_present = models.BooleanField(null=True)
    larvae_present = models.BooleanField(null=True)
    feeding_damage_present = models.BooleanField(null=True)
    notes = models.TextField(blank=True)
    history = HistoricalRecords(table_name="historical_plant_resource_observation")

    class Meta:
        db_table = "plant_resource_observation"
        indexes = [models.Index(fields=["project", "observed_at"])]
        constraints = [
            models.CheckConstraint(condition=models.Q(resource_type__in=ResourceType.values), name="plant_res_type_valid"),
            models.CheckConstraint(condition=models.Q(abundance_class__in=AbundanceClass.values + [""]), name="plant_res_abund_valid"),
            models.CheckConstraint(condition=models.Q(phenology_stage__in=PhenologyStage.values + [""]), name="plant_res_pheno_valid"),
            models.CheckConstraint(condition=models.Q(flowering_intensity__in=Intensity.values + [""]), name="plant_res_flower_valid"),
        ]


# observations/models.py additions (this ticket's migration)
#   ButterflyObservation.host_plant_record   = FK(PlantResourceObservation, SET_NULL, null=True, related_name="+")
#   ButterflyObservation.nectar_plant_record = FK(PlantResourceObservation, SET_NULL, null=True, related_name="+")
#   Photo.plant_resource = FK(PlantResourceObservation, CASCADE, null=True, related_name="photos")
#   Photo.Meta.constraints += CheckConstraint(
#       condition=Q(observation__isnull=False, plant_resource__isnull=True) | Q(observation__isnull=True, plant_resource__isnull=False),
#       name="photo_exactly_one_parent")
```

b) PostGIS DDL

```sql
CREATE TABLE plant_resource_observation (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  project_id             uuid NOT NULL REFERENCES project(id),
  survey_visit_id        uuid NULL REFERENCES survey_visit(id),
  plant_taxon_id         uuid NULL REFERENCES plant_taxon(id),
  resource_type          varchar(20) NOT NULL CONSTRAINT plant_res_type_valid CHECK (resource_type IN
                         ('larval_host','nectar_source','oviposition_plant','resting_plant','unknown_association')),
  observed_at            timestamptz NOT NULL,
  geometry               geometry(Geometry, 4326) NOT NULL,
  abundance_class        varchar(10) NOT NULL CONSTRAINT plant_res_abund_valid
                         CHECK (abundance_class IN ('1','2-10','11-100','101-1000','>1000','')),
  patch_area_m2          numeric(10,1) NULL,
  phenology_stage        varchar(12) NOT NULL CONSTRAINT plant_res_pheno_valid
                         CHECK (phenology_stage IN ('vegetative','budding','flowering','fruiting','senescent','')),
  flowering_intensity    varchar(6) NOT NULL CONSTRAINT plant_res_flower_valid
                         CHECK (flowering_intensity IN ('none','low','medium','high','')),
  eggs_present           boolean NULL,
  larvae_present         boolean NULL,
  feeding_damage_present boolean NULL,
  notes                  text NOT NULL,
  CONSTRAINT plant_res_geom_type CHECK (GeometryType(geometry) IN ('POINT','POLYGON')),
  CONSTRAINT plant_res_geom_valid CHECK (ST_IsValid(geometry))
);
CREATE INDEX plant_resource_observation_geometry_gist ON plant_resource_observation USING gist (geometry);
CREATE INDEX plant_resource_observation_proj_time_idx ON plant_resource_observation (project_id, observed_at);
CREATE INDEX plant_resource_observation_server_version_idx ON plant_resource_observation (server_version);
-- + trigger

ALTER TABLE butterfly_observation
  ADD COLUMN host_plant_record_id   uuid NULL REFERENCES plant_resource_observation(id) ON DELETE SET NULL,
  ADD COLUMN nectar_plant_record_id uuid NULL REFERENCES plant_resource_observation(id) ON DELETE SET NULL;
ALTER TABLE photo
  ADD COLUMN plant_resource_id uuid NULL REFERENCES plant_resource_observation(id) ON DELETE CASCADE,
  ADD CONSTRAINT photo_exactly_one_parent CHECK (num_nonnulls(observation_id, plant_resource_id) = 1);
```

c) Drift

```dart
class PlantResourceObservations extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get surveyVisitId => text().nullable()();
  TextColumn get plantTaxonId => text().nullable()();
  TextColumn get resourceType => text()();
  DateTimeColumn get observedAt => dateTime()();
  TextColumn get geometryGeojson => text()();            // Point or Polygon
  RealColumn get lat => real()();                        // point, or polygon centroid
  RealColumn get lon => real()();
  TextColumn get abundanceClass => text().withDefault(const Constant(''))();
  RealColumn get patchAreaM2 => real().nullable()();
  TextColumn get phenologyStage => text().withDefault(const Constant(''))();
  TextColumn get floweringIntensity => text().withDefault(const Constant(''))();
  BoolColumn get eggsPresent => boolean().nullable()();
  BoolColumn get larvaePresent => boolean().nullable()();
  BoolColumn get feedingDamagePresent => boolean().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```
Differences from the server:
- GeoJSON text, plus a centroid lat/lon for lists and the map.
- The polygon area shown in the app is computed locally for display only; the server value is authoritative.

d) Django-specific limitation
- `GeometryField` (generic) maps to `geometry(Geometry,4326)`, and the type restriction must be a raw CHECK (`GeometryType`). Add it with `RunSQL`, because `CheckConstraint` can't call PostGIS functions portably (VERIFY whether a `Func` expression works in your Django version).
- QGIS splits mixed-geometry layers into sublayers; the pygeoapi collection serves both types.

**Limitations / out of scope / risks**
- Lines (hedgerows) are not allowed for plants. Use habitat features for linear elements.

---

### T052 · App plant entry with point and polygon drawing
**ID:** T052 · **Implements:** F20 · **Labels:** `mobile`, `should` · **Milestone:** Phase 1 · **Epic:** E07 · **Depends on:** T051, T050 · **Estimate:** 2.5 d

**Description**
Record a plant resource quickly as a point, or as a patch polygon by walking around it or tapping vertices (outline §11.2 I).

**Acceptance criteria**
- [ ] Form fields:
  - plant species (search, same mechanism as taxa)
  - relation to butterflies (`resource_type`)
  - abundance class
  - phenology stage
  - flowering intensity
  - eggs, larvae and feeding damage (tri-state)
  - photos
  - notes
- [ ] Geometry modes:
  - **Point**: current GPS, or tap/drag on the map
  - **Polygon (tap)**: tap vertices on the map, with undo and close
  - **Polygon (walk)**: record GPS vertices every 2 m while walking the patch edge, then close
- [ ] Self-intersecting polygons are blocked with a message. The area is shown while drawing.
- [ ] The reusable widget `GeometryCaptureWidget(modes: {point, line, polygon})` is shared with T054.
- [ ] Reachable from the active visit (linked to the visit), from the project home "Plants & habitat" tile (not linked), and from T046's plant link.

**Limitations / out of scope / risks**
- Walking a polygon edge with phone GPS gives coarse shapes for small patches (under about 10 m). Tap mode is better there.

---

### T053 · HabitatFeature model and API
**ID:** T053 · **Implements:** F21 · **Labels:** `backend`, `database`, `sync`, `should`, `p2-compat` · **Milestone:** Phase 1 · **Epic:** E07 · **Depends on:** T020, T026 · **Estimate:** 1.5 d

**Description**
Describe habitat elements and their structure (outline §8.16): vegetation height, cover, flowers, management and disturbance, as a point, line or polygon.

**Acceptance criteria**
- [ ] Model, push and pull registration, and REST (outline §14):
  - `POST /api/v1/habitat-features`
  - `PATCH /api/v1/habitat-features/{id}`
- [ ] Geometry is `POINT`, `LINESTRING` or `POLYGON`, and must be valid.
- [ ] Percentages are 0–100.
- [ ] `habitat_type` is required, and `management_type` is optional (FK to codelists, T020).

**Database**

a) GeoDjango model

```python
# backend/resources/models.py (continued)
class MowingStatus(models.TextChoices):
    UNMOWN = "unmown"; RECENTLY_MOWN = "recently_mown"; MOWN_THIS_SEASON = "mown_this_season"; UNKNOWN = "unknown"

class Disturbance(models.TextChoices):
    NONE = "none"; TRAMPLING = "trampling"; VEHICLE_TRACKS = "vehicle_tracks"; FIRE = "fire"
    EROSION = "erosion"; DUMPING = "dumping"; OTHER = "other"


class HabitatFeature(SyncableModel):
    project = models.ForeignKey("projects.Project", on_delete=models.PROTECT, related_name="habitat_features")
    survey_visit = models.ForeignKey("surveys.SurveyVisit", on_delete=models.PROTECT, null=True, blank=True,
                                     related_name="habitat_features")
    habitat_type = models.ForeignKey("catalogues.HabitatType", on_delete=models.PROTECT)
    management_type = models.ForeignKey("catalogues.ManagementType", on_delete=models.PROTECT, null=True, blank=True)
    observed_at = models.DateTimeField()
    geometry = models.GeometryField(srid=4326)
    vegetation_height_cm = models.PositiveSmallIntegerField(null=True, blank=True)
    shrub_cover_pct = models.PositiveSmallIntegerField(null=True, blank=True)
    tree_cover_pct = models.PositiveSmallIntegerField(null=True, blank=True)
    bare_ground_pct = models.PositiveSmallIntegerField(null=True, blank=True)
    flower_abundance_class = models.CharField(max_length=6, choices=Intensity.choices, blank=True)
    grazing_intensity = models.CharField(max_length=6, choices=Intensity.choices, blank=True)
    mowing_status = models.CharField(max_length=20, choices=MowingStatus.choices, blank=True)
    disturbance_type = models.CharField(max_length=15, choices=Disturbance.choices, blank=True)
    notes = models.TextField(blank=True)
    history = HistoricalRecords(table_name="historical_habitat_feature")

    class Meta:
        db_table = "habitat_feature"
        constraints = [
            models.CheckConstraint(
                condition=(models.Q(shrub_cover_pct__isnull=True) | models.Q(shrub_cover_pct__lte=100))
                & (models.Q(tree_cover_pct__isnull=True) | models.Q(tree_cover_pct__lte=100))
                & (models.Q(bare_ground_pct__isnull=True) | models.Q(bare_ground_pct__lte=100)),
                name="habitat_pct_ok"),
            models.CheckConstraint(condition=models.Q(flower_abundance_class__in=Intensity.values + [""]), name="habitat_flower_valid"),
            models.CheckConstraint(condition=models.Q(grazing_intensity__in=Intensity.values + [""]), name="habitat_grazing_valid"),
            models.CheckConstraint(condition=models.Q(mowing_status__in=MowingStatus.values + [""]), name="habitat_mowing_valid"),
            models.CheckConstraint(condition=models.Q(disturbance_type__in=Disturbance.values + [""]), name="habitat_disturbance_valid"),
        ]
```

b) PostGIS DDL

```sql
CREATE TABLE habitat_feature (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  project_id             uuid NOT NULL REFERENCES project(id),
  survey_visit_id        uuid NULL REFERENCES survey_visit(id),
  habitat_type_id        uuid NOT NULL REFERENCES habitat_type(id),
  management_type_id     uuid NULL REFERENCES management_type(id),
  observed_at            timestamptz NOT NULL,
  geometry               geometry(Geometry, 4326) NOT NULL,
  vegetation_height_cm   smallint NULL CHECK (vegetation_height_cm >= 0),
  shrub_cover_pct        smallint NULL,
  tree_cover_pct         smallint NULL,
  bare_ground_pct        smallint NULL,
  flower_abundance_class varchar(6) NOT NULL CONSTRAINT habitat_flower_valid CHECK (flower_abundance_class IN ('none','low','medium','high','')),
  grazing_intensity      varchar(6) NOT NULL CONSTRAINT habitat_grazing_valid CHECK (grazing_intensity IN ('none','low','medium','high','')),
  mowing_status          varchar(20) NOT NULL CONSTRAINT habitat_mowing_valid CHECK (mowing_status IN ('unmown','recently_mown','mown_this_season','unknown','')),
  disturbance_type       varchar(15) NOT NULL CONSTRAINT habitat_disturbance_valid CHECK (disturbance_type IN
                         ('none','trampling','vehicle_tracks','fire','erosion','dumping','other','')),
  notes                  text NOT NULL,
  CONSTRAINT habitat_pct_ok CHECK ((shrub_cover_pct IS NULL OR shrub_cover_pct <= 100)
    AND (tree_cover_pct IS NULL OR tree_cover_pct <= 100) AND (bare_ground_pct IS NULL OR bare_ground_pct <= 100)),
  CONSTRAINT habitat_geom_type CHECK (GeometryType(geometry) IN ('POINT','LINESTRING','POLYGON')),
  CONSTRAINT habitat_geom_valid CHECK (ST_IsValid(geometry))
);
CREATE INDEX habitat_feature_geometry_gist ON habitat_feature USING gist (geometry);
CREATE INDEX habitat_feature_server_version_idx ON habitat_feature (server_version);
-- + trigger
```

c) Drift

```dart
class HabitatFeatures extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get surveyVisitId => text().nullable()();
  TextColumn get habitatTypeId => text()();
  TextColumn get managementTypeId => text().nullable()();
  DateTimeColumn get observedAt => dateTime()();
  TextColumn get geometryGeojson => text()();          // Point, LineString or Polygon
  RealColumn get lat => real()();                      // representative point
  RealColumn get lon => real()();
  IntColumn get vegetationHeightCm => integer().nullable()();
  IntColumn get shrubCoverPct => integer().nullable()();
  IntColumn get treeCoverPct => integer().nullable()();
  IntColumn get bareGroundPct => integer().nullable()();
  TextColumn get flowerAbundanceClass => text().withDefault(const Constant(''))();
  TextColumn get grazingIntensity => text().withDefault(const Constant(''))();
  TextColumn get mowingStatus => text().withDefault(const Constant(''))();
  TextColumn get disturbanceType => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```
Differences from the server: GeoJSON text plus a representative point.

d) Django-specific limitation: same as T051 for the geometry-type CHECK.

**Limitations / out of scope / risks**
- **p2-compat:** habitat polygons are what Phase 2 intersects with focal-follow trajectories to derive `habitat_change` events (T091). Polygons drawn here make that analysis possible.

---

### T054 · App habitat feature entry
**ID:** T054 · **Implements:** F21 · **Labels:** `mobile`, `should` · **Milestone:** Phase 1 · **Epic:** E07 · **Depends on:** T053, T052 · **Estimate:** 1.5 d

**Description**
Record a habitat feature with the shared geometry widget and fast structure inputs.

**Acceptance criteria**
- [ ] Habitat type and management pickers (from codelists), vegetation height (cm), cover sliders (shrub, tree, bare ground; 0–100 in steps of 5), flower abundance, grazing, mowing, disturbance and notes.
- [ ] Point, line and polygon capture via `GeometryCaptureWidget` (T052).
- [ ] Reachable from the active visit and from "Plants & habitat" on project home.

**Limitations / out of scope / risks**
- No photos on habitat features (not in the outline; add later if needed).

---
## E08 · Validation and data quality

### E08 · Epic: Validation and data quality
**Labels:** `epic`, `backend`, `admin` · **Milestone:** Phase 1 · **Implements:** F30, F31, F32, F33
Input rules shared by app and server, four automatic quality flags, an admin validation queue and a validation history.
Children: T055 · T056 · T057 · T058

---

### T055 · Input validation rules (shared by app and server)
**ID:** T055 · **Implements:** F30 · **Labels:** `backend`, `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E08 · **Depends on:** T034, T044, T016 · **Estimate:** 2 d

**Description**
Implement the outline §13.1 rules once as a written spec, then in both Django (authoritative) and Dart (immediate feedback). Hard errors block a save; warnings inform.

**Acceptance criteria**
- [ ] `docs/requirements/validation-rules.md` lists each rule with an ID, both implementations reference those IDs, and each rule has a test on each side.
- [ ] **Hard rules (server rejects, app blocks):**
  - **V01** `count ≥ 1`
  - **V02** an observation has `observed_at` and a geometry
  - **V03** a `source = transect` observation belongs to a visit in `in_progress` or `completed`, never `cancelled` or `locked`
  - **V04** `observed_at` is within `[started_at − tol, ended_at + tol]` of its visit (`tol = observation_time_tolerance_min`)
  - **V05** a completed visit has start and end weather, or `weather_missing_reason`
  - **V06** true-zero consistency (T041)
  - **V07** enum values are valid
  - **V08** geometry is valid and of an allowed type
- [ ] **Warnings (saved, and shown in the app):**
  - **W01** taxon `photo_required` and no photo: sets `validation_status = pending`
  - **W02** GPS accuracy worse than `gps_accuracy_warning_m`
  - **W03** `oviposition` without a host-plant link: prompt
  - **W04** `life_stage = larva` without a host-plant link: prompt
  - **W06** weather outside protocol thresholds
  - **W07** visit outside the season or time window
- [ ] Server errors use field-level codes (`{"fields": {"observed_at": ["V04"]}}`), and the app maps codes to readable messages.

**Technical explanation**
- Server: one `validate_<entity>(data, context)` function per entity in `<app>/rules.py`, called by DRF serializers and the push service.
- App: pure Dart functions in `lib/core/validation/`.

**Limitations / out of scope / risks**
- **W05** (species outside known range) is not implemented: there is no distribution data.

---

### T056 · Automatic quality flags
**ID:** T056 · **Implements:** F31 · **Labels:** `backend`, `should` · **Milestone:** Phase 1 · **Epic:** E08 · **Depends on:** T055, T036, T048 · **Estimate:** 1.5 d

**Description**
Compute four flags on the server after each push. A flag never rejects data (outline §13.2); it marks records for admin attention.

**Acceptance criteria**
- [ ] **Flags** (codes stored in `quality_flags`):
  - `outside_project_area`: observation not within `project.area` (skipped when the area is null)
  - `far_from_transect`: a transect observation farther than `max_distance_from_transect_m` from its transect line
  - `high_count`: `count > high_count_threshold`
  - `gps_gap` (on the visit): any gap between consecutive track points over `gps_gap_s`, outside pauses
- [ ] Flags are computed in the push service after save, for the affected records only. Recompute is available as an admin action and as `manage.py recompute_flags --project`.
- [ ] Admin list filter "Has flag: …" on observations and visits uses the array-contains lookup.
- [ ] Changing a protocol threshold and recomputing changes the flags (tested).

**Technical explanation**
The GPS gap uses window functions:

```sql
SELECT max(recorded_at - lag(recorded_at) OVER (ORDER BY recorded_at)) ... FROM survey_track_point WHERE survey_visit_id = $1
```

Pauses don't produce points, so a gap during a pause is excluded by comparing against the visit's pause intervals. The phone sends `paused_intervals` in the visit payload's `notes_meta` JSON, or simplest, the server tolerates gaps that equal `paused_seconds` ± 30 s. Keep it simple and document it.

**Limitations / out of scope / risks**
- **Cut flags (v4):** rare species, unusual phenological date, duplicate within a short time, insufficient coverage (shown in app only), excessive speed, unfavourable weather (covered by warning W06).

---

### T057 · Admin validation queue
**ID:** T057 · **Implements:** F32 · **Labels:** `admin`, `should` · **Milestone:** Phase 1 · **Epic:** E08 · **Depends on:** T049, T058, T014 · **Estimate:** 2 d

**Description**
Admins work through observations that need expert confirmation. They look at photos, then confirm, change the species, or mark the record unconfirmed or undeterminable (outline §6.2).

**Acceptance criteria**
- [ ] Proxy model `ValidationQueueItem(ButterflyObservation)` with its own admin, listed under **Validation**. Default queryset: `validation_status = pending`, or any flag, and not deleted.
- [ ] `list_display`: primary photo thumbnail (`<img>` from `/api/v1/photos/{id}/thumbnail`, admin session auth), taxon, count, life stage, observed at, recorder, confidence, flags, project.
- [ ] Filters: project, family, confidence, flag, date. Search: taxon names.
- [ ] Bulk actions: **Confirm**, **Mark unconfirmed**, **Mark undeterminable**.
- [ ] **Change taxon** is an intermediate form with taxon autocomplete and a required comment. It sets `validated_taxon`; `taxon` keeps what the recorder entered.
- [ ] Each action sets `validation_status`, `validated_by`, `validated_at` and `validation_comment`, writes a `ValidationEvent` (T058) and a history reason `"validation: <decision>"`.
- [ ] The change view shows all photos at full size (inline read-only gallery) and a small read-only map.
- [ ] Records of locked visits are view-only (T042).

**Technical explanation**
- Thumbnail endpoint permission: `IsAdminGroup` with `SessionAuthentication` enabled for that view only, so the admin browser session works.
- "Effective taxon" for analysis and export = `validated_taxon` if set, else `taxon`.

**Limitations / out of scope / risks**
- No in-app validation (F76 removed).

---

### T058 · Validation history
**ID:** T058 · **Implements:** F33 · **Labels:** `backend`, `database`, `should` · **Milestone:** Phase 1 · **Epic:** E08 · **Depends on:** T044 · **Estimate:** 1 d

**Description**
Keep an explicit, queryable record of every validation decision (outline §13.3 "validation decision", §15 `validation_history.csv`). It's separate from the generic audit log so analysis doesn't have to parse history tables.

**Acceptance criteria**
- [ ] The `ValidationEvent` model is written only by validation services (T057).
- [ ] A read-only inline on the observation admin, newest first.
- [ ] Included in exports as `validation_history.csv` (T064).

**Database**

a) GeoDjango model

```python
# backend/validation/models.py
import uuid
from django.conf import settings
from django.db import models


class Decision(models.TextChoices):
    CONFIRMED = "confirmed"; CHANGED_TAXON = "changed_taxon"; UNCONFIRMED = "unconfirmed"
    UNDETERMINABLE = "undeterminable"; RESET = "reset"


class ValidationEvent(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    observation = models.ForeignKey("observations.ButterflyObservation", on_delete=models.PROTECT,
                                    related_name="validation_events")
    decision = models.CharField(max_length=20, choices=Decision.choices)
    previous_status = models.CharField(max_length=15)
    new_status = models.CharField(max_length=15)
    previous_taxon = models.ForeignKey("catalogues.Taxon", on_delete=models.PROTECT, null=True, related_name="+")
    new_taxon = models.ForeignKey("catalogues.Taxon", on_delete=models.PROTECT, null=True, related_name="+")
    comment = models.TextField(blank=True)
    decided_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")
    decided_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "validation_event"
        ordering = ["-decided_at"]
        indexes = [models.Index(fields=["observation", "decided_at"])]
        constraints = [
            models.CheckConstraint(condition=models.Q(decision__in=Decision.values), name="validation_decision_valid"),
            models.CheckConstraint(condition=~models.Q(decision="changed_taxon") | models.Q(new_taxon__isnull=False),
                                   name="validation_changed_needs_taxon"),
        ]
```

b) PostGIS DDL

```sql
CREATE TABLE validation_event (
  id                uuid PRIMARY KEY,
  observation_id    uuid NOT NULL REFERENCES butterfly_observation(id),
  decision          varchar(20) NOT NULL CONSTRAINT validation_decision_valid
                    CHECK (decision IN ('confirmed','changed_taxon','unconfirmed','undeterminable','reset')),
  previous_status   varchar(15) NOT NULL,
  new_status        varchar(15) NOT NULL,
  previous_taxon_id uuid NULL REFERENCES taxon(id),
  new_taxon_id      uuid NULL REFERENCES taxon(id),
  comment           text NOT NULL,
  decided_by_id     uuid NOT NULL REFERENCES app_user(id),
  decided_at        timestamptz NOT NULL,
  CONSTRAINT validation_changed_needs_taxon CHECK (decision <> 'changed_taxon' OR new_taxon_id IS NOT NULL)
);
CREATE INDEX validation_event_obs_time_idx ON validation_event (observation_id, decided_at);
```

c) Drift: none. The table is server-only.

d) Django-specific limitation
Append-only by convention: the admin has no add, change or delete permission for this model. A DB-level guard is optional (`REVOKE UPDATE, DELETE ON validation_event FROM django_app` won't work, because Django owns the table; skip).

**Limitations / out of scope / risks**
- Validators can't be notified (no e-mail); admins check the queue.

---
## E09 · Map, indicators and export

### E09 · Epic: Map, indicators and export
**Labels:** `epic`, `mobile`, `backend`, `admin` · **Milestone:** Phase 1 · **Implements:** F29, F34, F35, F36, F37, F67, F74
The app map with layers and filters, an optional offline basemap, indicators in admin and in the app, environmental snapshots (manual source), and exports, implemented once and used by both the API and admin.
Children: T059 · T060 · T061 · T062 · T063 · T064 · T065 · T066

---

### T059 · App map screen with layers and filters
**ID:** T059 · **Implements:** F34 · **Labels:** `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E09 · **Depends on:** T044, T036 (plant/habitat layers added when T051/T053 are done) · **Estimate:** 2.5 d

**Description**
A project map showing everything the researcher has offline, with filters (outline §11.2 K).

**Acceptance criteria**
- [ ] **Layers** (toggle sheet): transects, sections, own observations (clustered with `flutter_map_marker_cluster`), plants, habitats, a selected visit's route, and the basemap.
- [ ] **Filters:** visit, species, date range, life stage, behaviour, habitat type. The validation-status filter is dropped because the app doesn't store it.
- [ ] Tapping a feature shows a popup with key fields and an "Open" link to its detail or edit screen.
- [ ] 5,000 observation markers render and pan smoothly on the test phone (timed in T074).
- [ ] The online basemap uses OSM tiles with a correct `User-Agent` (`rs.<you>.butterfly`) and the attribution shown. Viewed tiles are cached (flutter_map tile caching). There is **no bulk prefetch** (OSM tile usage policy forbids it).

**Limitations / out of scope / risks**
- Protected-area layers are cut. Sensor stations arrive in Phase 2 (T080).

---

### T060 · Offline basemap from MBTiles
**ID:** T060 · **Implements:** F29 · **Labels:** `mobile`, `backend`, `could` · **Milestone:** Phase 1 · **Epic:** E09 · **Depends on:** T059, T031 · **Estimate:** 2 d

**Description**
Show a real basemap in the field without connectivity, using an MBTiles file produced legally for the small study area.

**Acceptance criteria**
- [ ] `docs/setup/basemap.md` explains producing an MBTiles file for the project area in QGIS (*Processing → Generate XYZ tiles (MBTiles)*, zoom 12–18). The source must allow offline use, for example your own styling of an OSM extract from Geofabrik, or an open orthophoto with a compatible licence. **Not** by scraping tile servers.
- [ ] `Project.basemap` is a FileField in MinIO, uploaded in admin. The offline package (T031) downloads it when present.
- [ ] The app renders it with an MBTiles tile provider for flutter_map (package choice: VERIFY, e.g. `flutter_map_mbtiles`) and falls back to cached online tiles.
- [ ] The file size is shown before download. Typical: 20–80 MB for a few km².

**Limitations / out of scope / risks**
- **Could:** skip it if time is short. Simulated field days can run online, and transects and routes draw without a basemap.

---

### T061 · Indicators: server SQL views and admin report
**ID:** T061 · **Implements:** F35 · **Labels:** `backend`, `admin`, `database`, `should` · **Milestone:** Phase 1 · **Epic:** E09 · **Depends on:** T044, T041, T058 · **Estimate:** 1.5 d

**Description**
Compute the monitoring indicators (outline §16, trimmed) once in SQL. Admins browse them in Django admin, and exports reuse them.

**Acceptance criteria**
- [ ] **View `report_transect_indicators`** (per transect × year): visits completed, true-zero visits, total duration (h), total distance (km), species count, individuals, observations, confirmed and to-review counts, individuals per km, individuals per hour, and target visits vs actual.
- [ ] **View `report_species_phenology`** (per project × taxon × ISO week): individuals, observations, first and last date.
- [ ] **View `report_behaviour_counts`** (per project × behaviour value): count. Reproductive records = behaviour ∩ {courtship, mating, oviposition} or life stage ∈ {egg, larva, pupa}.
- [ ] Only `source = transect` observations of non-cancelled visits count towards per-km and per-hour figures. Effective taxon = `COALESCE(validated_taxon_id, taxon_id)`.
- [ ] Unmanaged models over the views, with read-only admin changelists, filters (project, year, transect) and CSV export (T065).
- [ ] A test seeds known data and checks every number.

**Database**

a) Model code (unmanaged)

```python
# backend/reports/models.py
from django.db import models

class TransectIndicators(models.Model):
    row_id = models.CharField(max_length=80, primary_key=True)   # transect_id || ':' || year
    project_id = models.UUIDField()
    transect_id = models.UUIDField()
    transect_code = models.CharField(max_length=20)
    year = models.IntegerField()
    visits_completed = models.IntegerField()
    true_zero_visits = models.IntegerField()
    total_hours = models.DecimalField(max_digits=8, decimal_places=2)
    total_km = models.DecimalField(max_digits=8, decimal_places=2)
    species_count = models.IntegerField()
    individuals = models.IntegerField()
    observations = models.IntegerField()
    confirmed_obs = models.IntegerField()
    to_review_obs = models.IntegerField()
    target_visits = models.IntegerField()
    individuals_per_km = models.DecimalField(max_digits=8, decimal_places=2, null=True)
    individuals_per_hour = models.DecimalField(max_digits=8, decimal_places=2, null=True)

    class Meta:
        managed = False
        db_table = "report_transect_indicators"
```

b) PostGIS DDL (main view; the phenology and behaviour views follow the same pattern)

```sql
CREATE VIEW report_transect_indicators AS
WITH v AS (
  SELECT id, project_id, transect_id, extract(year FROM started_at)::int AS year,
         coalesce(duration_seconds, 0) AS duration_s, coalesce(distance_walked_m, 0) AS distance_m,
         zero_observation_confirmed
  FROM survey_visit
  WHERE deleted_at IS NULL AND status IN ('completed','synced','reviewed','locked')
),
per_visit AS (            -- pre-aggregate per visit so duration/distance are not double counted
  SELECT v.id, v.project_id, v.transect_id, v.year, v.duration_s, v.distance_m, v.zero_observation_confirmed,
         coalesce(sum(o.count), 0) AS individuals, count(o.id) AS observations,
         count(o.id) FILTER (WHERE o.validation_status = 'confirmed') AS confirmed_obs,
         count(o.id) FILTER (WHERE o.validation_status = 'pending')   AS to_review_obs
  FROM v LEFT JOIN butterfly_observation o
         ON o.survey_visit_id = v.id AND o.deleted_at IS NULL AND o.source = 'transect'
  GROUP BY v.id, v.project_id, v.transect_id, v.year, v.duration_s, v.distance_m, v.zero_observation_confirmed
),
species AS (
  SELECT v.transect_id, v.year, count(DISTINCT coalesce(o.validated_taxon_id, o.taxon_id)) AS species_count
  FROM v JOIN butterfly_observation o
         ON o.survey_visit_id = v.id AND o.deleted_at IS NULL AND o.source = 'transect'
  GROUP BY v.transect_id, v.year
)
SELECT pv.transect_id::text || ':' || pv.year                              AS row_id,
       pv.project_id, pv.transect_id, t.code AS transect_code, pv.year,
       count(*)                                                            AS visits_completed,
       count(*) FILTER (WHERE pv.zero_observation_confirmed)               AS true_zero_visits,
       round(sum(pv.duration_s) / 3600.0, 2)                               AS total_hours,
       round(sum(pv.distance_m) / 1000.0, 2)                               AS total_km,
       coalesce(max(s.species_count), 0)                                   AS species_count,
       sum(pv.individuals)                                                 AS individuals,
       sum(pv.observations)                                                AS observations,
       sum(pv.confirmed_obs)                                               AS confirmed_obs,
       sum(pv.to_review_obs)                                               AS to_review_obs,
       max(pp.target_visits_per_season)                                    AS target_visits,
       round(sum(pv.individuals) / nullif(sum(pv.distance_m) / 1000.0, 0), 2) AS individuals_per_km,
       round(sum(pv.individuals) / nullif(sum(pv.duration_s) / 3600.0, 0), 2) AS individuals_per_hour
FROM per_visit pv
JOIN transect t ON t.id = pv.transect_id
JOIN project_protocol pp ON pp.project_id = pv.project_id
LEFT JOIN species s ON s.transect_id = pv.transect_id AND s.year = pv.year
GROUP BY pv.project_id, pv.transect_id, t.code, pv.year;
```

c) Drift: none (server-only; the app computes its own local version in T062).

d) Django-specific limitation
- Unmanaged models need a single-column primary key. The views expose a synthetic `row_id`.
- Views are created via `RunSQL` (see T004 d).

**Limitations / out of scope / risks**
- No statistical modelling; that is done in R (outline §16).

---

### T062 · App statistics screen
**ID:** T062 · **Implements:** F35 · **Labels:** `mobile`, `should` · **Milestone:** Phase 1 · **Epic:** E09 · **Depends on:** T044, T041 · **Estimate:** 1.5 d

**Description**
Researchers see simple indicators for their own data offline.

**Acceptance criteria**
- [ ] Per transect and period, from local data: visits, true zeros, species, individuals, individuals per km, individuals per hour, and the top 10 species.
- [ ] A weekly phenology bar chart for a chosen species (`fl_chart`).
- [ ] A note on screen: "Your records only. Project-wide figures are in the admin reports."
- [ ] Uses the same definitions as T061; a Dart unit test uses the same fixture numbers as T061's test.

**Limitations / out of scope / risks**
- Only the researcher's own data, because pull is scoped to own records.

---

### T063 · EnvironmentalSnapshot model with manual source
**ID:** T063 · **Implements:** F74 · **Labels:** `backend`, `database`, `must`, `p2-compat` · **Milestone:** Phase 1 · **Epic:** E09 · **Depends on:** T034, T044 · **Estimate:** 1 d

**Description**
*Must (although F74 is Should) because Phase 2 SensorThings and EDR snapshots build on this table. Shipping it in Phase 1 keeps Part 2 additive.*
Store environmental values attached to a visit or observation, so analysis is reproducible even if a remote source changes (outline §8.18). Phase 1 fills it from the manual start and end weather. Phase 2 adds SensorThings and EDR rows **without schema changes**.

**Acceptance criteria**
- [ ] When a visit reaches `completed`, the server creates two snapshots (start and end) with `source_type = manual`.
  - Wind Beaufort is converted to m/s using the midpoint of the Beaufort range.
  - The original Beaufort value is kept in `raw_payload_json`.
- [ ] Re-completing (after an edit) replaces the manual snapshots of that visit, never duplicating them.
- [ ] Included in exports as `environmental_snapshots.csv`.
- [ ] Read-only inline on the visit admin.

**Database**

a) GeoDjango model

```python
# backend/environment/models.py
import uuid
from django.db import models


class SourceType(models.TextChoices):
    MANUAL = "manual"; SENSORTHINGS = "sensorthings"; EDR = "edr"; OTHER_API = "other_api"

class SnapshotMoment(models.TextChoices):
    START = "start"; END = "end"; VISIT_MEAN = "visit_mean"; AT_OBSERVATION = "at_observation"


class EnvironmentalSnapshot(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    survey_visit = models.ForeignKey("surveys.SurveyVisit", on_delete=models.CASCADE, null=True, blank=True,
                                     related_name="environmental_snapshots")
    observation = models.ForeignKey("observations.ButterflyObservation", on_delete=models.CASCADE,
                                    null=True, blank=True, related_name="environmental_snapshots")
    source_type = models.CharField(max_length=15, choices=SourceType.choices)
    moment = models.CharField(max_length=15, choices=SnapshotMoment.choices)
    source_uri = models.TextField(blank=True)
    retrieved_at = models.DateTimeField(auto_now_add=True)
    phenomenon_time_start = models.DateTimeField()
    phenomenon_time_end = models.DateTimeField(null=True, blank=True)    # interval if aggregated
    temperature_c = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
    relative_humidity_pct = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
    wind_speed_m_s = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    wind_direction_deg = models.DecimalField(max_digits=5, decimal_places=1, null=True, blank=True)
    cloud_cover_pct = models.DecimalField(max_digits=4, decimal_places=1, null=True, blank=True)
    precipitation_mm = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    solar_radiation_w_m2 = models.DecimalField(max_digits=6, decimal_places=1, null=True, blank=True)
    is_simulated = models.BooleanField(default=False)          # Phase 2 STA/EDR values are simulated
    raw_payload_json = models.JSONField(default=dict, blank=True)

    class Meta:
        db_table = "environmental_snapshot"
        indexes = [models.Index(fields=["survey_visit", "source_type"])]
        constraints = [
            models.CheckConstraint(condition=models.Q(survey_visit__isnull=False) | models.Q(observation__isnull=False),
                                   name="env_snapshot_has_target"),
            models.CheckConstraint(condition=models.Q(source_type__in=SourceType.values), name="env_snapshot_source_valid"),
            models.CheckConstraint(condition=models.Q(moment__in=SnapshotMoment.values), name="env_snapshot_moment_valid"),
            models.UniqueConstraint(fields=["survey_visit", "source_type", "moment"],
                                    condition=models.Q(observation__isnull=True), name="env_snapshot_unique_visit_moment"),
        ]
```

b) PostGIS DDL

```sql
CREATE TABLE environmental_snapshot (
  id                     uuid PRIMARY KEY,
  survey_visit_id        uuid NULL REFERENCES survey_visit(id) ON DELETE CASCADE,
  observation_id         uuid NULL REFERENCES butterfly_observation(id) ON DELETE CASCADE,
  source_type            varchar(15) NOT NULL CONSTRAINT env_snapshot_source_valid
                         CHECK (source_type IN ('manual','sensorthings','edr','other_api')),
  moment                 varchar(15) NOT NULL CONSTRAINT env_snapshot_moment_valid
                         CHECK (moment IN ('start','end','visit_mean','at_observation')),
  source_uri             text NOT NULL,
  retrieved_at           timestamptz NOT NULL,
  phenomenon_time_start  timestamptz NOT NULL,
  phenomenon_time_end    timestamptz NULL,
  temperature_c          numeric(4,1) NULL,
  relative_humidity_pct  numeric(4,1) NULL,
  wind_speed_m_s         numeric(5,2) NULL,
  wind_direction_deg     numeric(5,1) NULL,
  cloud_cover_pct        numeric(4,1) NULL,
  precipitation_mm       numeric(6,2) NULL,
  solar_radiation_w_m2   numeric(6,1) NULL,
  is_simulated           boolean NOT NULL DEFAULT false,
  raw_payload_json       jsonb NOT NULL DEFAULT '{}',
  CONSTRAINT env_snapshot_has_target CHECK (survey_visit_id IS NOT NULL OR observation_id IS NOT NULL)
);
CREATE INDEX environmental_snapshot_visit_source_idx ON environmental_snapshot (survey_visit_id, source_type);
CREATE UNIQUE INDEX env_snapshot_unique_visit_moment ON environmental_snapshot (survey_visit_id, source_type, moment)
  WHERE observation_id IS NULL;
```

c) Drift: none. Snapshots are created on the server and not needed offline.

d) Django-specific limitation
Not a `SyncableModel` (server-only), so it has no trigger and no history. That's fine, because rows are derived data that can be regenerated.

**Limitations / out of scope / risks**
- **p2-compat:**
  - Phase 2 adds rows with `source_type = sensorthings` (T081) or `edr` (T084), with `is_simulated = true`.
  - The `moment` values `visit_mean` and `at_observation` are there for those sources.
  - A nullable `station_link` FK is added in T081 (additive).
- Outline field `phenomenon_time` is split into start and end because STA and EDR values can be intervals.

---

### T064 · Export service and admin-only export API
**ID:** T064 · **Implements:** F36 · **Labels:** `backend`, `must` · **Milestone:** Phase 1 · **Epic:** E09 · **Depends on:** T044, T063 (plant, habitat and validation datasets added when T051/T053/T058 are done) · **Estimate:** 2.5 d

**Description**
Build one export module that produces every dataset in CSV, GeoJSON and JSON, plus a zipped bundle with metadata (outline §15). The API endpoints are admin-only (v4 rule: only admins download data). Admin actions (T065) reuse the same module.

**Acceptance criteria**
- [ ] **Datasets:**
  - `survey_visits`
  - `butterfly_observations`
  - `transects`
  - `transect_sections`
  - `plant_resources`
  - `habitat_features`
  - `environmental_snapshots`
  - `validation_history`
  - `track_points` (optional, large)
- [ ] `GET /api/v1/exports/{dataset}?format=csv|geojson|json&project=&from=&to=` streams the response (`StreamingHttpResponse`).
- [ ] `GET /api/v1/exports/bundle?project=` returns a ZIP of all CSVs plus `metadata.json`.
- [ ] **Every export keeps** (outline §15):
  - stable UUIDs
  - CRS: GeoJSON is CRS84 lon/lat per RFC 7946, and CSV has `lon`, `lat` (points) or `geometry_wkt` plus `crs = EPSG:4326` in metadata
  - timestamps in ISO 8601 with offset
  - a missing-value code (default `NA`, configurable)
  - `protocol_version`
  - taxon list version
  - validation status and effective taxon
  - effort fields (duration, distance, observer count)
  - visit outcome (T041)
- [ ] `metadata.json`: export time, user, filters, versions, missing-value code, row counts, and a short data dictionary (column → description) generated from model `help_text`.
- [ ] CSV is UTF-8 with an optional BOM (`?excel=1`) and reads cleanly in R (`readr::read_csv`) and Python (`pandas.read_csv`); a test round-trips one file.
- [ ] Researchers get 403 (tested).

**Technical explanation**
- `exports/datasets.py` defines each dataset as a SQL query plus column list. `exports/writers.py` has CSV, GeoJSON and JSON writers working on row iterators (server-side cursors, `chunk_size=2000`).
- **Single implementation:** both the API and admin actions call `exports.service.export(dataset, fmt, filters)`.

**Limitations / out of scope / risks**
- Darwin Core export removed (F38).
- GeoPackage export is in T066 (Could).

---

### T065 · Admin export actions
**ID:** T065 · **Implements:** F67 · **Labels:** `admin`, `should` · **Milestone:** Phase 1 · **Epic:** E09 · **Depends on:** T064 · **Estimate:** 1 d

**Description**
Export straight from Django admin lists and from a project page, reusing T064.

**Acceptance criteria**
- [ ] Actions **Export selected as CSV** and **Export selected as GeoJSON** on visits, observations, plant resources, habitat features, transects, validation events and the report views.
- [ ] An **Export project bundle (ZIP)** button on the project change page (small `change_form` template override with an object-tools link).
- [ ] Output is identical to the API for the same filter (test compares bytes).

**Limitations / out of scope / risks**
- Large selections run synchronously. That's fine for pilot volumes (tens of thousands of rows).

---

### T066 · GeoPackage export
**ID:** T066 · **Implements:** F37 · **Labels:** `backend`, `could` · **Milestone:** Phase 1 · **Epic:** E09 · **Depends on:** T064, T067 · **Estimate:** 1 d

**Description**
Provide a single GeoPackage with all spatial layers for QGIS users.

**Acceptance criteria**
- [ ] `format=gpkg` on the bundle endpoint and the admin project button produce a `.gpkg` with layers built from the `geo` views (T067): transects, sections, observations, plant resources (split into point and polygon layers), habitat features (split by type), plus non-spatial tables (visits, snapshots, validation history).
- [ ] Created with `ogr2ogr -f GPKG out.gpkg PG:"<dsn>" -sql "<query>" -nln <layer>` per layer (GDAL is already in the image).
- [ ] Opens in QGIS with correct CRS and attribute types (checked manually; screenshot in docs).

**Limitations / out of scope / risks**
- **Could.** CSV and GeoJSON already cover R and QGIS.

---
## E10 · OGC API – Features

### E10 · Epic: OGC API – Features (pygeoapi, read-only)
**Labels:** `epic`, `ogc` · **Milestone:** Phase 1 · **Implements:** F39, F40, F41, F43, F45, F68
Read-only views in `geo`, five pygeoapi collections with filtering and paging, token-protected access for admins through nginx, and an interoperability test with QGIS and the OGC test suite (MVP criterion 11).
Children: T067 · T068 · T069 · T070

---

### T067 · `geo` views for the five collections
**ID:** T067 · **Implements:** F40, F45 · **Labels:** `database`, `ogc`, `must` · **Milestone:** Phase 1 · **Epic:** E10 · **Depends on:** T044, T021, T004 (plant/habitat views added when T051/T053 are done) · **Estimate:** 2 d

**Description**
Publish clean, flattened, read-only views for pygeoapi. Each has a unique `id`, a single geometry column and analysis-friendly attributes, and excludes soft-deleted rows and internal sync columns.

**Acceptance criteria**
- [ ] The views `geo.transects`, `geo.transect_sections`, `geo.butterfly_observations`, `geo.plant_resources` and `geo.habitat_features` are created by migration (`CreateView` from T004).
- [ ] Arrays become comma-separated text (`behaviour`, `quality_flags`), because array attributes are poorly supported in OGC API Features clients and QGIS.
- [ ] Taxon names and codelist labels are joined in (no foreign-key lookups needed by clients). Observations expose both `taxon_*` (as recorded) and `effective_*` (validated if set).
- [ ] `pygeoapi_ro` can `SELECT` all five views, and cannot read any `public` table (test).
- [ ] A test selects one row from every view after migrations (catches view breakage when models change).

**Database**

b) PostGIS DDL (two shown in full; the rest follow the same pattern)

```sql
CREATE VIEW geo.butterfly_observations AS
SELECT o.id,
       o.project_id,
       p.name                                         AS project_name,
       o.survey_visit_id,
       t.code                                         AS transect_code,
       s.section_code,
       o.observed_at,
       o.source,
       tx.scientific_name                             AS taxon_scientific_name,
       tx.vernacular_name_en                          AS taxon_vernacular_name_en,
       tx.vernacular_name_sr                          AS taxon_vernacular_name_sr,
       COALESCE(vt.scientific_name, tx.scientific_name) AS effective_scientific_name,
       COALESCE(vt.family, tx.family)                 AS effective_family,
       o.count,
       o.sex,
       o.life_stage,
       array_to_string(o.behaviour, ',')              AS behaviour,
       o.identification_confidence,
       o.validation_status,
       o.location_accuracy_m,
       array_to_string(o.quality_flags, ',')          AS quality_flags,
       u.name                                         AS recorded_by_name,
       tlv.version_label                              AS taxon_list_version,
       o.geometry
FROM public.butterfly_observation o
JOIN public.project p              ON p.id = o.project_id
JOIN public.taxon tx               ON tx.id = o.taxon_id
LEFT JOIN public.taxon vt          ON vt.id = o.validated_taxon_id
LEFT JOIN public.taxon_list_version tlv ON tlv.id = p.taxon_list_version_id
LEFT JOIN public.survey_visit v    ON v.id = o.survey_visit_id
LEFT JOIN public.transect t        ON t.id = v.transect_id
LEFT JOIN public.transect_section s ON s.id = o.transect_section_id
JOIN public.app_user u             ON u.id = o.recorded_by_id
WHERE o.deleted_at IS NULL;

CREATE VIEW geo.transects AS
SELECT t.id, t.project_id, p.name AS project_name, t.code, t.name, t.description,
       t.target_length_m, round(ST_Length(t.geometry::geography)::numeric, 1) AS length_m,
       t.habitat_summary, t.active,
       (SELECT count(*) FROM public.transect_section s WHERE s.transect_id = t.id AND s.deleted_at IS NULL) AS section_count,
       t.geometry
FROM public.transect t JOIN public.project p ON p.id = t.project_id
WHERE t.deleted_at IS NULL;

-- geo.transect_sections: id, transect_id, transect_code, section_code, sequence_number,
--   habitat_type_code, habitat_type_name_en, management_type_code, length_m, notes, geometry
-- geo.plant_resources: id, project_id, survey_visit_id, observed_at, plant_scientific_name, resource_type,
--   abundance_class, patch_area_m2, phenology_stage, flowering_intensity, eggs_present, larvae_present,
--   feeding_damage_present, geometry_type (GeometryType(geometry)), geometry
-- geo.habitat_features: id, project_id, observed_at, habitat_type_code, habitat_type_name_en,
--   management_type_code, vegetation_height_cm, shrub_cover_pct, tree_cover_pct, bare_ground_pct,
--   flower_abundance_class, grazing_intensity, mowing_status, disturbance_type, geometry_type, geometry
-- Grants come from ALTER DEFAULT PRIVILEGES (T004); add explicit GRANT SELECT as a safety net:
GRANT SELECT ON ALL TABLES IN SCHEMA geo TO pygeoapi_ro;
```

d) Django-specific limitation
Views aren't tracked by the autodetector. A model change that removes or renames a column used here needs `DROP VIEW ... ; CREATE VIEW ...` in the same migration. `CREATE OR REPLACE VIEW` can only append columns.

**Limitations / out of scope / risks**
- `recorded_by_name` is exposed because pygeoapi is admin-only (T069). If pygeoapi is ever made public, remove it.
- **p2-compat:** Phase 2 adds `geo.sensor_stations` (T080) and possibly focal-follow views (T094), as new views without changing these.

---

### T068 · pygeoapi collections, filtering and paging
**ID:** T068 · **Implements:** F39, F40, F41 · **Labels:** `ogc`, `infra`, `must` · **Milestone:** Phase 1 · **Epic:** E10 · **Depends on:** T067, T007 · **Estimate:** 1.5 d

**Description**
Configure pygeoapi to serve the five views as OGC API – Features collections, read-only, with bbox, datetime, property filtering and paging.

**Acceptance criteria**
- [ ] `pygeoapi/config/pygeoapi-config.yml`:
  - server `url: http://localhost:8080/ogc` (set it to the Tailscale URL if you browse it from elsewhere)
  - metadata: title, description, keywords, contact, licence CC-BY-4.0 (your choice)
  - the 5 resources below
  - no `editable: true` anywhere
- [ ] Each collection uses provider `PostgreSQL` with:
  - `data: {host: db, dbname: butterfly, user: pygeoapi_ro, password: ${PYGEOAPI_DB_PASSWORD}, search_path: [geo, public]}`
  - `id_field: id`, `table: <view>`, `geom_field: geometry`
  - `time_field: observed_at` where present (VERIFY support in 0.24's PostgreSQL provider)
  - `title_field`
- [ ] Collection ids: `transects`, `transect-sections`, `butterfly-observations`, `plant-resources`, `habitat-features` (outline §9.1).
- [ ] Extents: spatial from the project areas (or all transects); temporal from the season.
- [ ] Working queries (scripted in `scripts/ogc-smoke.sh`):
  - `?bbox=…`
  - `?datetime=2026-06-01T00:00:00Z/2026-06-30T23:59:59Z`
  - `?effective_family=Lycaenidae`
  - `?limit=100&offset=100`, with next/prev links
  - `?f=json`, `?f=html`
  - CQL2 `filter=` if supported by the provider (VERIFY)
- [ ] The OpenAPI document is regenerated on container start (`pygeoapi openapi generate`).
- [ ] The skeleton collection from T007 is removed.

**Technical explanation**
pygeoapi listens inside the Compose network only. nginx proxies `/ogc/` to it (port per image docs: VERIFY).

**Limitations / out of scope / risks**
- pygeoapi builds links from `server.url`. One URL is configured, so links point to localhost even when accessed via Tailscale. That's acceptable because QGIS runs on the laptop.
- No write support (F42 removed).

---

### T069 · Token-protected pygeoapi access for admins
**ID:** T069 · **Implements:** F68 · **Labels:** `ogc`, `security`, `infra`, `must` · **Milestone:** Phase 1 · **Epic:** E10 · **Depends on:** T068, T011, T013 · **Estimate:** 1.5 d

**Description**
Only admins can read the OGC API, authenticated with a token checked by Django through nginx `auth_request`. Desktop tools get a long-lived personal token, because 15-minute JWTs are impractical in QGIS.

**Acceptance criteria**
- [ ] Django `GET /api/v1/auth/verify/` (called only by nginx) returns:
  - **204** when the request carries a valid `Authorization: Bearer <JWT>`, `Authorization: Token <personal token>` or (fallback) `Basic <email:password>`, **and** the user is active and in `admin`
  - **401** with `WWW-Authenticate: Basic realm="ogc"` when there are no or bad credentials
  - **403** for a non-admin
- [ ] **Personal API tokens:** DRF `rest_framework.authtoken` (one token per admin), created and revoked in Django admin. Justification: built into DRF, revocable and simple.
- [ ] nginx config is added to `infrastructure/nginx/`:

```nginx
location /ogc/ {
    auth_request /_auth;
    auth_request_set $auth_www $upstream_http_www_authenticate;
    error_page 401 = @ogc_401;
    proxy_pass http://pygeoapi:80/;              # VERIFY container port
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}
location @ogc_401 {
    add_header WWW-Authenticate $auth_www always;
    return 401;
}
location = /_auth {
    internal;
    proxy_pass http://django:8000/api/v1/auth/verify/;
    proxy_pass_request_body off;
    proxy_set_header Content-Length "";
    proxy_set_header Authorization $http_authorization;
    proxy_cache auth_cache;                      # proxy_cache_path ... keys_zone=auth_cache:1m
    proxy_cache_key $http_authorization;
    proxy_cache_valid 204 60s;                   # avoid one Django hit per tile/page request
}
```

- [ ] Tests:
  - no token: 401
  - researcher JWT: 403
  - admin JWT: 200
  - admin personal token: 200
  - revoked token: 401 after at most 60 s (cache TTL)
- [ ] `docs/setup/ogc-access.md` covers:
  - **QGIS**: an Authentication configuration of type "API Header" with `Authorization: Token <key>` (VERIFY availability in your QGIS version), or type "Basic" as fallback
  - **Python**: `requests` with headers
  - **R**: `httr2` header, or `sf::st_read()` with `GDAL_HTTP_HEADERS` (VERIFY GDAL version)

**Limitations / out of scope / risks**
- Basic auth sends the password with every request. Over Tailscale it is TLS-encrypted, and on localhost it never leaves the laptop. Prefer personal tokens.
- The auth cache means revocation takes up to 60 s.

---

### T070 · QGIS interoperability and OGC conformance test
**ID:** T070 · **Implements:** F43 · **Labels:** `ogc`, `evaluation`, `must` · **Milestone:** Phase 1 · **Epic:** E10 · **Depends on:** T069, T071 · **Estimate:** 1.5 d

**Description**
Show that standard clients can use the data (outline §20.1). This is evidence for the thesis.

**Acceptance criteria**
- [ ] **QGIS** (version recorded): add an OGC API – Features connection with the token, load all 5 collections, check attribute types and geometry, and use the Temporal Controller on observations. Screenshots go in `evaluation/interop/`.
- [ ] **Python notebook:** reads each collection with `geopandas.read_file(url)` (or requests plus `GeoDataFrame.from_features`) with the token, and pages through more than 1000 features of simulated data.
- [ ] **R script:** reads observations with `sf` or `httr2` and plots a phenology chart.
- [ ] **OGC CITE:** run the executable test suite for OGC API – Features Part 1 (`ets-ogcapi-features10`, Docker image from OGC, VERIFY name and tag) against pygeoapi. Run it directly on the internal port in a `test` compose profile, because the test harness may not send auth headers. Save the HTML report, and explain any failures.
- [ ] Results table (client, operation, result, notes) in `evaluation/interop/results.md`.

**Limitations / out of scope / risks**
- A CITE pass on pygeoapi's core is expected (it is a reference implementation). Failures are more likely to come from our views, for example datetime handling.

---
## E11 · Simulated data and evaluation (Part 1)

### E11 · Epic: Simulated data and evaluation (Part 1)
**Labels:** `epic`, `evaluation` · **Milestone:** Phase 1 · **Implements:** F61 (P1 part), F80
No real field season is available before the deadline. This epic makes simulated field days realistic and reproducible, instruments the app, and runs the Part 1 evaluation: functionality, data quality, usability, performance and sync robustness.
Children: T071 · T072 · T073 · T074 · T075

---

### T071 · Simulated field-day generator
**ID:** T071 · **Implements:** F80 · **Labels:** `backend`, `evaluation`, `must`, `p2-compat` · **Milestone:** Phase 1 · **Epic:** E11 · **Depends on:** T024, T026, T036, T044, T049 (plants/habitats generated when T051/T053 are done) · **Estimate:** 2.5 d

**Description**
Generate a full season of believable survey data, deterministically from a seed, and push it through the real sync API. This exercises the whole pipeline and feeds indicators, exports, OGC and evaluation.

**Acceptance criteria**
- [ ] `manage.py simulate_season --project <id> --start 2026-05-01 --end 2026-08-31 --visits-per-transect 8 --seed 42 [--direct]`:
  - **Weather per day:** a shared Python module `simweather` (in `simulator/simweather/`, also used by T079 in Phase 2) produces a daily story of temperature, cloud, wind and rain. Visits fall mostly on suitable days. About 10 % are cancelled, with reasons.
  - **Tracks:** walk each transect at 0.8–1.2 m/s, one point per protocol interval, Gaussian GPS noise with σ equal to a sampled accuracy of 3–8 m, and occasional gaps of 60–120 s.
  - **Observations:** species are drawn from the seeded list with per-habitat weights and a Gaussian flight-period curve per species (parameters derived deterministically from the taxon id). Counts follow a Poisson distribution. Confidence mix: 80 % `confirmed_in_field`, 15 % `probable`, 5 % `photo_required` with a placeholder photo.
  - **Plants and habitats:** a few plant resources (points and polygons) and habitat features per transect.
  - **Injected anomalies** to test flags and dedup: high counts, records far from the transect, GPS gaps, true-zero visits, and **duplicate batch submissions**.
- [ ] Default mode pushes through `/api/v1/sync/push` with the demo researcher's token (end-to-end). `--direct` writes via services for speed.
- [ ] The same seed gives identical data (test compares exports).
- [ ] Also exports `database/seeds/transects.gpx` for T072.

**Limitations / out of scope / risks**
- Simulated ecology is plausible, not realistic. The thesis evaluates the **system**, not butterfly ecology. State this clearly.
- **p2-compat:** `simweather` keeps Phase 2 sensor data (T079) consistent with the manual weather recorded on simulated visits.

---

### T072 · GPS replay in the app
**ID:** T072 · **Implements:** F80 · **Labels:** `mobile`, `evaluation`, `must` · **Milestone:** Phase 1 · **Epic:** E11 · **Depends on:** T037 · **Estimate:** 1.5 d

**Description**
Run a complete visit indoors (for tests, demos and evaluation sessions) by replaying a GPX track instead of real GPS.

**Acceptance criteria**
- [ ] In the dev flavour only, Settings → "Location source: Device GPS | Replay GPX" with a file picker or bundled transect GPX, and speed 1×, 5× or 20×.
- [ ] `ReplaySource` implements `LocationSource` (T037), emitting positions with timestamps, accuracy and `provider = simulated`.
- [ ] An `integration_test` drives a full visit on the emulator with replay: start, 10 observations, a plant polygon, finish, sync. It asserts the server state through the API.
- [ ] Documents Android emulator GPX playback (Extended controls → Location) as an alternative.

**Limitations / out of scope / risks**
- Replay does not reproduce real GPS behaviour (multipath, cold start). Battery and accuracy measurements in T074 use real GPS.

---

### T073 · Evaluation instrumentation in the app
**ID:** T073 · **Implements:** F61 · **Labels:** `mobile`, `evaluation`, `must` · **Milestone:** Phase 1 · **Epic:** E11 · **Depends on:** T045, T035 · **Estimate:** 1.5 d

**Description**
Measure the usability metrics from outline §20.3 automatically during sessions.

**Acceptance criteria**
- [ ] An **Evaluation mode** toggle in settings (off by default). When on, events are logged to a local table:
  - opening the visit form and starting a visit (time to start)
  - opening the observation sheet and saving (entry time)
  - taps inside the observation sheet (via a `Listener` wrapper)
  - validation errors shown
  - sync start and end, with bytes and outcome
- [ ] **Export events as CSV** via the share sheet (`share_plus`), with a session id and device info header.
- [ ] Logging adds less than 5 ms per event (no UI jank).

**Database**

c) Drift (local only)

```dart
class EvalEvents extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get sessionId => text()();
  TextColumn get eventType => text()();     // visit_form_open, visit_started, obs_open, obs_saved, tap, error, sync_start, sync_end
  TextColumn get entityId => text().nullable()();
  DateTimeColumn get at => dateTime()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();   // JSON
}
```

**Limitations / out of scope / risks**
- Tap counts only cover the observation sheet. That's enough for the "taps per common record" metric.

---

### T074 · Performance, sync robustness and battery tests
**ID:** T074 · **Implements:** F61 · **Labels:** `evaluation`, `backend`, `mobile`, `must` · **Milestone:** Phase 1 · **Epic:** E11 · **Depends on:** T071, T072, T030, T059 · **Estimate:** 2 d

**Description**
Measure the outline §20.4 performance items and the MVP sync guarantees, with scripts that can be re-run.

**Acceptance criteria**
- [ ] **Server:** push and pull throughput for 100, 500 and 1000 mutations, plus p50 and p95 response times for the main endpoints and OGC items, using `pytest-benchmark` or a small `httpx` script. Results go to `evaluation/results/server_perf.csv`.
- [ ] **App:**
  - Drift insert of 1000 observations
  - map load with 5k markers
  - local DB size after a simulated season (pulled)
  - photo upload throughput over Tailscale

  Integration-test timings go to `evaluation/results/app_perf.csv`.
- [ ] **Sync robustness (MVP criteria 7–9):**
  1. kill the app mid-visit, then check no data was lost
  2. turn on airplane mode during a push, then check it resumes with no duplicates (scripted with a fault-injecting dio adapter, plus one manual run on device)
  3. resend the same batch, then check the counts are unchanged

  A pass/fail table is produced.
- [ ] **Battery:** two 60-minute real-GPS walks (or bench runs with the screen off) at 5 s and 15 s intervals, measured with `adb shell dumpsys batterystats`, giving % drain per hour.
- [ ] **MVP criterion 4:** a visit with 50+ observations, then a restart, shows no loss.

**Limitations / out of scope / risks**
- One test phone, so results are device-specific. Report the model and Android version.

---

### T075 · Usability kit and Part 1 evaluation run
**ID:** T075 · **Implements:** F61 · **Labels:** `evaluation`, `docs`, `must` · **Milestone:** Phase 1 · **Epic:** E11 · **Depends on:** T073, T074, T070 · **Estimate:** 2 d

**Description**
Prepare and run the evaluation session with your biologist, then compute the data-quality metrics (outline §20.2, §20.3).

**Acceptance criteria**
- [ ] `evaluation/usability/`:
  - task script: start a visit, record 10 observations (2 with extended fields), add a plant polygon, finish, sync
  - SUS questionnaire (10 items, Serbian and English)
  - a short semi-structured interview guide
  - a consent note
- [ ] **Session:** an outdoor walk on a real path with "planted" species cards along the route (the outline §29 simulated field day, with no real butterflies needed), in evaluation mode. Also do the same 10 records on a paper form, timed, for the paper-vs-digital comparison.
- [ ] `evaluation/analysis.ipynb` computes:
  - SUS score
  - time per observation, taps per common record and time to start a visit (from T073)
  - error rate
  - the outline §20.2 data-quality metrics from SQL: % complete records, % valid geometry, duplicates, failed syncs, % with photo, % confirmed, true-zero visits
- [ ] A results summary in `evaluation/results/part1-summary.md`, ready for the thesis.

**Limitations / out of scope / risks**
- With **one** biologist, SUS is qualitative evidence, not a statistic. Say so, and support it with the timing data and your own repeated runs.

---
# Part C: Phase 2 tickets (milestone `Phase 2 – Thesis Part 2`)

Phase 2 adds three OGC standards on top of a finished Phase 1. No Phase 2 ticket changes a Phase 1 table destructively: every schema change is an added table or a nullable column. Each standard starts with a short study ticket (F89), so Part 2 has both a research half and an implementation half.

## E12 · OGC SensorThings API (simulated microclimate stations)

### E12 · Epic: OGC SensorThings API
**Labels:** `epic`, `ogc`, `research` · **Milestone:** Phase 2 · **Implements:** F47, F48, F49, F50, F69, F89
Run FROST-Server, register simulated microclimate stations from Django admin, feed them with a realistic simulator, show stations on maps and in OGC collections, and attach sensor values to visits.
Children: T076 · T077 · T078 · T079 · T080 · T081

**Risk note:**
- FROST-Server is a separate Java service with its own database migrations and memory needs (roughly 0.5–1 GB). It is mature and actively released (2.x), so the main risk is integration effort, not stability.
- There are no real sensors, so everything shown is simulated (thesis honesty: label it everywhere).

**Fallback:**
- If FROST can't be made to work in time, keep the simulator writing directly into `environmental_snapshot` (source `other_api`, `is_simulated = true`) and describe the SensorThings mapping on paper (T076).
- A lighter alternative server, if needed, is a pygeoapi SensorThings bridge reading from another STA implementation (VERIFY options), but FROST remains the reference choice.

---

### T076 · Standards study: SensorThings API
**ID:** T076 · **Implements:** F89 · **Labels:** `research`, `docs`, `must` · **Milestone:** Phase 2 · **Epic:** E12 · **Depends on:** — · **Estimate:** 1 d

**Description**
Write the research note that Part 2's SensorThings chapter builds on.

**Acceptance criteria**
- [ ] `docs/standards/sensorthings.md` covers:
  - the STA 1.1 entity model (Thing, Location, HistoricalLocation, Sensor, ObservedProperty, Datastream, Observation, FeatureOfInterest)
  - the mapping to this project, with the example from outline §9.2 adapted to simulated stations
  - FROST-Server (version, persistence, plugins)
  - how pygeoapi bridges STA (SensorThings Features provider, SensorThingsEDR provider)
  - MQTT (described, not implemented; F51 removed)
  - what is simulated and why
- [ ] It includes a diagram of entity relations and data flow (simulator → FROST → Django snapshots → exports).
- [ ] References the OGC standard document and FROST docs with versions.

**Limitations / out of scope / risks**
- This is a description, not a literature review. Keep it to 3–5 pages.

---

### T077 · FROST-Server deployment
**ID:** T077 · **Implements:** F47 · **Labels:** `infra`, `ogc`, `must` · **Milestone:** Phase 2 · **Epic:** E12 · **Depends on:** T076, T002, T069 · **Estimate:** 1.5 d

**Description**
Add FROST-Server to the Compose stack with its own database, behind nginx with the same admin-only auth as pygeoapi.

**Acceptance criteria**
- [ ] `db-init/02-frost.sql` creates database `frost`, role `frost` and `CREATE EXTENSION postgis` in `frost`. The init script runs on fresh volumes; a `scripts/create-frost-db.sh` handles existing ones.
- [ ] Compose service `frost` (image `fraunhoferiosb/frost-server:<2.x>`, pinned; VERIFY current tag) with environment:
  - `serviceRootUrl=http://localhost:8080/sta`
  - `persistence_db_driver=org.postgresql.Driver`
  - `persistence_db_url=jdbc:postgresql://db:5432/frost`
  - `persistence_db_username=frost`, plus password
  - `persistence_autoUpdateDatabase=true`
  - MQTT disabled (VERIFY the env names against FROST's docker docs)
- [ ] nginx `/sta/` uses the same `auth_request` as `/ogc/` (admins only). Internal services (Django, pygeoapi, simulator) reach FROST directly on the Compose network without auth.
- [ ] `GET /sta/v1.1/` lists the entity sets. Health check configured.
- [ ] Backups (T010) include the `frost` database.

**Technical explanation**
A separate database keeps FROST's Liquibase migrations away from Django's (decision in step1b §3).

**Limitations / out of scope / risks**
- FROST's own auth plugins are not used; the proxy is the single auth point.
- Memory: give the container `-Xmx768m` (VERIFY the env var).

---

### T078 · Sensor station links and registration in FROST from Django admin
**ID:** T078 · **Implements:** F48, F49 · **Labels:** `backend`, `admin`, `database`, `ogc`, `must` · **Milestone:** Phase 2 · **Epic:** E12 · **Depends on:** T077, T021 · **Estimate:** 2 d

**Description**
Admins define simulated stations in Django admin (where, which habitat, which transects they serve). One action creates the matching Thing, Location, Sensor, ObservedProperties, Datastreams and FeatureOfInterest in FROST, and stores their ids (outline §8.17).

**Acceptance criteria**
- [ ] `SensorStationLink` model with a map admin.
- [ ] Action **Register in FROST** posts a deep insert:
  - **Thing** with `properties` {project_id, habitat_type, simulated: true}
  - **Location**: the station point
  - **Sensor**: "Virtual microclimate sensor v1", with metadata describing the simulation
  - **ObservedProperties** (shared, created once): air temperature, relative humidity, wind speed, global solar radiation, with definition URIs from CF standard names
  - four **Datastreams**, 10-minute, `OM_Measurement`, with units: °C, %, m/s, W/m²
  - **FeatureOfInterest**: the habitat polygon if linked, else the station point

  It stores `sensorthings_thing_id` and `sensorthings_datastream_ids`, and is idempotent: re-running updates instead of duplicating.
- [ ] Action **Check FROST status** verifies that the stored ids exist.
- [ ] Stations are synced to project members (read-only on the phone) for the map layer (T080).

**Database**

a) GeoDjango model

```python
# backend/environment/models.py (continued)
from django.contrib.gis.db import models as gis_models
from simple_history.models import HistoricalRecords
from core.models import SyncableModel


class SensorStationLink(SyncableModel):
    project = models.ForeignKey("projects.Project", on_delete=models.PROTECT, related_name="sensor_stations")
    code = models.CharField(max_length=20)
    name = models.CharField(max_length=200)
    geometry = gis_models.PointField(srid=4326)
    habitat_type = models.ForeignKey("catalogues.HabitatType", on_delete=models.PROTECT, null=True, blank=True)
    habitat_feature = models.ForeignKey("resources.HabitatFeature", on_delete=models.SET_NULL, null=True, blank=True)
    transects = models.ManyToManyField("transects.Transect", blank=True, related_name="sensor_stations",
                                       db_table="sensor_station_link_transect")
    sensorthings_thing_id = models.CharField(max_length=64, blank=True)          # FROST ids may be numeric or strings
    sensorthings_datastream_ids = models.JSONField(default=dict, blank=True)      # {"air_temperature": "12", ...}
    is_simulated = models.BooleanField(default=True)
    active = models.BooleanField(default=True)
    metadata_json = models.JSONField(default=dict, blank=True)
    history = HistoricalRecords(table_name="historical_sensor_station_link")

    class Meta:
        db_table = "sensor_station_link"
        constraints = [models.UniqueConstraint(fields=["project", "code"], name="sensor_station_code_unique")]
```

b) PostGIS DDL

```sql
CREATE TABLE sensor_station_link (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  project_id                  uuid NOT NULL REFERENCES project(id),
  code                        varchar(20) NOT NULL,
  name                        varchar(200) NOT NULL,
  geometry                    geometry(Point, 4326) NOT NULL,
  habitat_type_id             uuid NULL REFERENCES habitat_type(id),
  habitat_feature_id          uuid NULL REFERENCES habitat_feature(id) ON DELETE SET NULL,
  sensorthings_thing_id       varchar(64) NOT NULL,
  sensorthings_datastream_ids jsonb NOT NULL DEFAULT '{}',
  is_simulated                boolean NOT NULL DEFAULT true,
  active                      boolean NOT NULL DEFAULT true,
  metadata_json               jsonb NOT NULL DEFAULT '{}',
  CONSTRAINT sensor_station_code_unique UNIQUE (project_id, code)
);
CREATE INDEX sensor_station_link_geometry_gist ON sensor_station_link USING gist (geometry);
CREATE INDEX sensor_station_link_server_version_idx ON sensor_station_link (server_version);
CREATE TABLE sensor_station_link_transect (
  id bigserial PRIMARY KEY,
  sensorstationlink_id uuid NOT NULL REFERENCES sensor_station_link(id) ON DELETE CASCADE,
  transect_id uuid NOT NULL REFERENCES transect(id) ON DELETE CASCADE,
  UNIQUE (sensorstationlink_id, transect_id)
);
-- + trigger on sensor_station_link
```

c) Drift

```dart
class SensorStationLinks extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get code => text()();
  TextColumn get name => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get habitatTypeId => text().nullable()();
  TextColumn get transectIds => text().withDefault(const Constant('[]'))();   // JSON array
  BoolColumn get isSimulated => boolean().withDefault(const Constant(true))();
  BoolColumn get active => boolean()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```
Differences from the server:
- The M2M relation is flattened to a JSON array.
- FROST ids are not stored on the phone (the phone never calls FROST).

d) Django-specific limitation
- The M2M through table is not a `SyncableModel`. Transect links change rarely, so the station row is re-saved (bumping its version) whenever its links change (`m2m_changed` signal), and the app gets the new list on pull.
- The Drift schema migration adds this table (`schemaVersion` + 1).

**Limitations / out of scope / risks**
- **p2-compat:** this is the only new synced table in E12, so it is purely additive.

---

### T079 · Sensor data simulator
**ID:** T079 · **Implements:** F69 · **Labels:** `backend`, `infra`, `must` · **Milestone:** Phase 2 · **Epic:** E12 · **Depends on:** T078, T071 · **Estimate:** 2.5 d

**Description**
A small Python service that generates realistic 10-minute series for each simulated station and posts them to FROST. It backfills the simulated season and can also run "live".

**Acceptance criteria**
- [ ] `simulator/` container (Python 3.12, `requests`, `numpy`), reading stations and datastream ids from Django (`GET /api/v1/stations?project=`, admin token).
- [ ] **Models**, all deterministic from a seed and consistent with `simweather` daily weather (T071):
  - **temperature:** daily mean from `simweather`, plus a diurnal sine (peak about 15:00), plus a habitat offset (dry grassland +1.5 °C, forest edge −1.0 °C, etc.), plus AR(1) noise
  - **relative humidity:** inversely related to temperature, plus noise, clamped to 20–100 %
  - **wind speed:** Weibull (k = 2) with a scale from the daily wind, rising in the afternoon
  - **solar radiation:** clear-sky estimate from solar elevation (date, lat, lon) × a cloud factor from the daily cloud cover, 0 at night
- [ ] **Backfill mode:** `simulate --from 2026-05-01 --to 2026-08-31` posts in batches using the FROST `CreateObservations` dataArray extension (VERIFY support in the deployed version). It is idempotent per (datastream, phenomenonTime): skip if present.
- [ ] **Live mode:** posts the current 10-minute values on a schedule (compose profile `live`).
- [ ] Every Datastream has `properties.simulated = true`, and the Sensor description says "simulated".
- [ ] Plots of one week per station are saved in `evaluation/simulator/` as a sanity check.

**Technical explanation**
About 17.5k observations per datastream per four months. With 4 datastreams × 4 stations that's about 280k rows in FROST, which is fine for PostgreSQL.

**Limitations / out of scope / risks**
- This is a statistical toy, not a microclimate model. Its purpose is to make the standards integration demonstrable.

---

### T080 · Station map layer and OGC collections
**ID:** T080 · **Implements:** F49 · **Labels:** `ogc`, `mobile`, `should` · **Milestone:** Phase 2 · **Epic:** E12 · **Depends on:** T078, T079, T068 · **Estimate:** 1.5 d

**Description**
Show stations on the app map and expose them as OGC API – Features in two ways, both of which go into the thesis comparison.

**Acceptance criteria**
- [ ] View `geo.sensor_stations` (id, project, code, name, habitat type, simulated, geometry) and pygeoapi collection **`sensor-stations`** (PostgreSQL provider), giving the outline §9.1 collection.
- [ ] A second collection, **`sta-datastreams`**, uses pygeoapi's **SensorThings** Features provider directly on FROST (`data: http://frost:8080/FROST-Server/v1.1/`, `entity: Datastreams`, `expand: Thing/Locations,Observations($orderby=phenomenonTime desc;$top=1)`). This shows pygeoapi as an STA bridge.
- [ ] App map layer "Sensor stations" (from pulled `sensor_station_links`). The popup shows the latest values online via `GET /api/v1/stations/{id}/latest`, where Django queries FROST. When offline it shows "Latest values need a connection".
- [ ] Both collections open in QGIS.

**Limitations / out of scope / risks**
- QGIS also has a native SensorThings data provider (3.36+, VERIFY). Test it in T095.

---

### T081 · Environmental snapshots from SensorThings
**ID:** T081 · **Implements:** F50 · **Labels:** `backend`, `ogc`, `must`, `p2-compat` · **Milestone:** Phase 2 · **Epic:** E12 · **Depends on:** T079, T063 · **Estimate:** 2 d

**Description**
When a visit is completed (or on demand), fetch the station measurements for the visit window and store them as snapshots next to the manual weather. That makes the "temperature vs activity" question (outline §4 Q2) analysable and reproducible.

**Acceptance criteria**
- [ ] Station choice: a station linked to the visit's transect. Otherwise the nearest active station within 5 km, else none (logged).
- [ ] For each datastream, query FROST:

  ```
  Datastreams(<id>)/Observations?$filter=phenomenonTime ge <start> and phenomenonTime le <end>&$orderby=phenomenonTime&$top=1000
  ```

  It stores:
  - a `visit_mean` snapshot (means over the window)
  - `start` and `end` snapshots (nearest values)

  All with `source_type = sensorthings`, `source_uri` = the exact query URL, `is_simulated = true`, and the raw response in `raw_payload_json`.
- [ ] Adds a nullable `station_link` FK to `environmental_snapshot` (additive migration).
- [ ] Trigger: `transaction.on_commit` after a visit becomes `completed`, with a 5 s timeout. Failures are logged and left for the backfill command `manage.py fetch_sta_snapshots --missing`, and an admin action is also available.
- [ ] Optional (Should): an `at_observation` snapshot per observation (value interpolated at `observed_at`), behind a flag.
- [ ] The export (T064) includes the new rows. The thesis table compares manual vs station values per visit.

**Database**

b) PostGIS DDL (additive)

```sql
ALTER TABLE environmental_snapshot
  ADD COLUMN station_link_id uuid NULL REFERENCES sensor_station_link(id) ON DELETE SET NULL;
CREATE INDEX environmental_snapshot_station_idx ON environmental_snapshot (station_link_id);
```

a) Model: `station_link = models.ForeignKey("environment.SensorStationLink", on_delete=models.SET_NULL, null=True, blank=True)`

c) Drift: none (server-only table).

d) Django-specific limitation: the outbound HTTP call happens after commit, outside the request transaction, so a slow FROST never blocks a push.

**Limitations / out of scope / risks**
- No worker queue, so a missed fetch is retried only by the backfill command or admin action (documented).

---
## E13 · OGC API – Environmental Data Retrieval (EDR)

### E13 · Epic: OGC API – EDR
**Labels:** `epic`, `ogc`, `research` · **Milestone:** Phase 2 · **Implements:** F52, F53, F55, F89
Expose simulated weather through EDR in pygeoapi, query it for each visit, and offer weather auto-fill in the app.
Children: T082 · T083 · T084 · T085

**Risk note:**
- EDR is in pygeoapi core, but the providers have limited query types:
  - `SensorThingsEDR` supports **area, cube, items and locations**, but **not position, radius, trajectory or corridor**
  - `xarray-edr` supports **position and cube**
- So "weather at a point" needs a gridded dataset, and along-transect corridor queries (F54) are not possible without a custom provider (F54 removed).
- Few desktop clients read CoverageJSON. QGIS support is unclear (VERIFY).

**Fallback:** if the gridded collection fails, use `locations` queries on the station collection (weather at the station linked to the transect) for F53. If EDR as a whole slips, keep the SensorThings snapshots (T081) and document EDR from the study ticket.

---

### T082 · Standards study: OGC API – EDR
**ID:** T082 · **Implements:** F89 · **Labels:** `research`, `docs`, `must` · **Milestone:** Phase 2 · **Epic:** E13 · **Depends on:** — · **Estimate:** 1 d

**Description**
Write the research note for the EDR chapter.

**Acceptance criteria**
- [ ] `docs/standards/edr.md` covers:
  - query types (position, area, cube, trajectory, corridor, radius, items, locations, instances)
  - response formats (CoverageJSON, GeoJSON, CSV)
  - pygeoapi providers and their supported queries
  - how EDR differs from SensorThings (data retrieval vs sensor management)
  - the butterfly use cases: weather at visit time and place, seasonal series per site
  - which use cases are possible with available providers and which are not
- [ ] A short table: use case, EDR query, provider, status.

---

### T083 · EDR collections in pygeoapi
**ID:** T083 · **Implements:** F52 · **Labels:** `ogc`, `infra`, `must` · **Milestone:** Phase 2 · **Epic:** E13 · **Depends on:** T082, T079, T068 · **Estimate:** 2 d

**Description**
Publish two EDR collections: one over the FROST stations, and one over a gridded simulated weather dataset that supports point queries.

**Acceptance criteria**
- [ ] Collection **`weather-stations`**:
  - provider `SensorThingsEDR`, `data: http://frost:8080/FROST-Server/v1.1/`
  - plus the matching `SensorThings` feature provider required for `items` (per pygeoapi docs)
  - working queries: `/locations/{id}?datetime=…&parameter-name=…`, `/area?coords=POLYGON(…)&datetime=…`, `/cube?bbox=…&datetime=…`
- [ ] **Grid export:** the simulator (T079) gains `export-grid --resolution 250m --from --to --out /data/weather_grid.nc`. It writes a NetCDF over the project area, hourly, with variables `tas` (°C), `hurs` (%), `wind_speed` (m/s) and `rsds` (W/m²), interpolated from stations with inverse-distance weighting, and with CF-convention attributes.
- [ ] Collection **`weather-grid`**: provider `xarray-edr` on that NetCDF (`x_field: lon`, `y_field: lat`, `time_field: time`). Working queries: `/position?coords=POINT(lon lat)&datetime=…` and `/cube?bbox=…`.
- [ ] Both are behind `/ogc/` auth (T069). A smoke script runs each query type and checks for a 200 with CoverageJSON.

**Technical explanation**
`xarray` and `netCDF4` must be present in the pygeoapi image. Extend the image with a small Dockerfile if they're missing (VERIFY).

**Limitations / out of scope / risks**
- The grid is derived from simulated stations, so it is doubly synthetic. Its purpose is to demonstrate position queries.

---

### T084 · Weather for a visit via EDR
**ID:** T084 · **Implements:** F53 · **Labels:** `backend`, `ogc`, `must` · **Milestone:** Phase 2 · **Epic:** E13 · **Depends on:** T083, T081 · **Estimate:** 1.5 d

**Description**
For each completed visit, query EDR at the transect's midpoint for the visit window and store the result, so manual, SensorThings and EDR values can be compared.

**Acceptance criteria**
- [ ] The service calls pygeoapi internally (`http://pygeoapi/collections/weather-grid/position?coords=POINT(x y)&datetime=start/end&parameter-name=tas,hurs,wind_speed,rsds&f=json`), parses the CoverageJSON, and stores `visit_mean`, `start` and `end` snapshots with `source_type = edr`, `source_uri` = the query URL, and `is_simulated = true`.
- [ ] Triggered like T081 (on commit plus a backfill command `fetch_edr_snapshots --missing`).
- [ ] Export plus a notebook cell comparing manual vs STA vs EDR per visit (temperature and wind) for the thesis.

**Limitations / out of scope / risks**
- The transect midpoint represents the whole transect. That's acceptable for transects of about 1 km.

---

### T085 · Weather auto-fill in the app
**ID:** T085 · **Implements:** F55 · **Labels:** `mobile`, `backend`, `should`, `p2-compat` · **Milestone:** Phase 2 · **Epic:** E13 · **Depends on:** T084, T035 · **Estimate:** 1.5 d

**Description**
When online, the start and end weather forms can be pre-filled from EDR. The observer can always override, and manual values stay authoritative (outline §9.4).

**Acceptance criteria**
- [ ] `GET /api/v1/weather/current?lat=&lon=&time=` is available to researchers. Django calls the EDR grid (position) and returns:
  - temperature
  - wind in m/s and converted to Beaufort
  - humidity
  - a cloud-cover estimate (1 − rsds/clear-sky)
  - `source: "edr (simulated)"`
- [ ] In the start-visit and finish forms, an **Auto-fill weather** button (the T035 slot) fills the fields and marks them "auto". Any edit clears the mark. The button is hidden when offline.
- [ ] Adds `survey_visit.weather_source` (`manual` | `edr_autofill` | `edr_autofill_edited`): a nullable server column plus a Drift migration step.
- [ ] A clear "Simulated data" badge appears while auto-filled values are shown.

**Database**

b) PostGIS DDL (additive)

```sql
ALTER TABLE survey_visit ADD COLUMN weather_source varchar(20) NULL
  CHECK (weather_source IS NULL OR weather_source IN ('manual','edr_autofill','edr_autofill_edited'));
```

a) Model: `weather_source = models.CharField(max_length=20, choices=WeatherSource.choices, null=True, blank=True)` plus a CheckConstraint.

c) Drift: `TextColumn get weatherSource => text().nullable()();` added in `schemaVersion` N+1 with `m.addColumn(surveyVisits, surveyVisits.weatherSource)`.

d) Django-specific limitation: a nullable column with no default means existing rows stay NULL, which is interpreted as `manual`.

**Limitations / out of scope / risks**
- Without connectivity in the field, auto-fill is unavailable. That's expected, and why manual entry stays primary.

---
## E14 · OGC API – Moving Features and MobilityDB

### E14 · Epic: OGC API – Moving Features and MobilityDB
**Labels:** `epic`, `ogc`, `research` · **Milestone:** Phase 2 · **Implements:** F56, F57, F58, F59, F60, F70, F89
Record short focal-follow sessions of individual butterflies, store trajectories in MobilityDB, derive behaviour events, and publish them through OGC API – Moving Features.
Children: T086 · T087 · T088 · T089 · T090 · T091 · T092 · T093 · T094

**Risk note:**
- **Moving Features is not in pygeoapi core.** As of the 0.24 docs it is only on the roadmap. The most complete implementation found is AIST's **fork** `aistairc/pygeoapi-mf-api`, used with MobilityDB/PyMEOS in a FOSS4G 2026 workshop. Its maintenance status, pygeoapi base version and expected table layout are unverified (VERIFY in T087).
- MobilityDB 1.3 is current. There's no Django field type, so it needs raw SQL.
- Phone GPS (5–15 m) is coarse for butterfly movements of a few metres (outline §9.3, §21).

**Fallback:**
- If the fork is stale or incompatible, implement the OGC API – MF Part 1 read endpoints in DRF on top of MobilityDB's `asMFJSON` output (T092/T093 option B), and declare partial conformance.
- If MobilityDB itself is blocked, store trajectories as PostGIS `LineStringM` (M = epoch seconds) and build MF-JSON in Python. That is plain PostGIS, the original default.

---

### T086 · Standards study: OGC API – Moving Features
**ID:** T086 · **Implements:** F89 · **Labels:** `research`, `docs`, `must` · **Milestone:** Phase 2 · **Epic:** E14 · **Depends on:** — · **Estimate:** 1 d

**Description**
Write the research note for the Moving Features chapter.

**Acceptance criteria**
- [ ] `docs/standards/moving-features.md` covers:
  - the MF-JSON encoding
  - OGC API – MF Part 1 resources: collections, items (MovingFeature), `tgsequence` (temporal geometry), `tproperties` (temporal properties)
  - temporal geometry types and interpolation
  - MobilityDB/MEOS types (`tgeompoint`, `tgeogpoint`, `ttext`) and how they map to MF-JSON
  - pygeoapi status (roadmap only), the AIST fork, and other implementations found
  - the GPS-accuracy caveat and how a focal follow is recorded (observer GPS vs tapped estimates)
- [ ] Records the exact standard document version (VERIFY the current OGC API – MF Part 1 document number and status).

---

### T087 · MobilityDB research and design spike
**ID:** T087 · **Implements:** F70 · **Labels:** `research`, `database`, `must` · **Milestone:** Phase 2 · **Epic:** E14 · **Depends on:** T086, T071 · **Estimate:** 2 d (time-boxed)

**Description**
Confirm MobilityDB with evidence, design trajectory storage, and decide how Moving Features will be served. The output is an architecture decision record.

**Acceptance criteria**
- [ ] On a scratch database (same image), enable the extension and build `tgeompoint` sequences from simulated `survey_track_point` data. Record the exact constructor functions that work in 1.3 (VERIFY names such as `tgeompoint(geom, t)` and `tgeompointSeq(array_agg(...))`).
- [ ] Run the needed queries in **both** MobilityDB and plain PostGIS (LineStringM or ordered points), and record SQL length and timings:
  1. trajectory length in metres
  2. speed profile
  3. time spent inside each habitat polygon
  4. stops (speed below a threshold for at least N s)
  5. position at time t
  6. MF-JSON output
- [ ] Clone and run `aistairc/pygeoapi-mf-api` in a container against the scratch data. Record its base pygeoapi version, last commit date, the expected schema and tables, and whether it serves `tgsequence`.
- [ ] Write `docs/adr/0001-trajectory-storage.md`: the decision (MobilityDB expected), and the serving option, either **(A)** the AIST fork as a second pygeoapi service, or **(B)** DRF endpoints, with reasons.
- [ ] Choose the metric strategy: store `tgeompoint` in EPSG:4326 for output, and use `transform(trip, 32634)` (UTM 34N, which covers Serbia) for metres, or use `tgeogpoint` (VERIFY function support).

**Limitations / out of scope / risks**
- Time-boxed. If the fork doesn't run within the box, choose option B.

---

### T088 · Enable MobilityDB and trajectory storage
**ID:** T088 · **Implements:** F57 · **Labels:** `database`, `infra`, `must` · **Milestone:** Phase 2 · **Epic:** E14 · **Depends on:** T087, T089 · **Estimate:** 2 d

**Description**
Turn on MobilityDB in the main database and build trajectories from Phase 1 track points and Phase 2 focal-follow points.

**Acceptance criteria**
- [ ] The DB service sets `shared_preload_libraries = 'postgis-3'` and `max_locks_per_transaction = 128` via `command:` arguments, if MobilityDB requires them (VERIFY in the image docs).
- [ ] Django migration: `CREATE EXTENSION IF NOT EXISTS mobilitydb CASCADE;`.
- [ ] Creates `mobility` schema **only if ADR option A** needs it. Otherwise the tables live in `public`.
- [ ] Tables are rebuilt by SQL functions called after pushes (`on_commit`) and by `manage.py rebuild_trajectories`:
  - `focal_follow_trajectory`: one row per session, built from `focal_follow_point`
  - `visit_route_trajectory`: one row per visit, built from `survey_track_point`. This shows Phase 1 data reused in Phase 2 with no schema change.
- [ ] Backups and restore tested with MobilityDB data (same version on both sides).

**Database**

a) Model code: no GeoDjango field exists for temporal types. The tables are created by `RunSQL`, with unmanaged models exposing only the scalar columns:

```python
# backend/mobility/models.py
from django.db import models

class FocalFollowTrajectory(models.Model):
    session = models.OneToOneField("mobility.FocalFollowSession", on_delete=models.DO_NOTHING,
                                   primary_key=True, db_column="session_id")
    point_count = models.IntegerField()
    built_at = models.DateTimeField()
    # 'trip tgeompoint' exists in the table but is read via raw SQL only

    class Meta:
        managed = False
        db_table = "focal_follow_trajectory"
```

b) DDL (function names to VERIFY against MobilityDB 1.3 docs during T087)

```sql
CREATE EXTENSION IF NOT EXISTS mobilitydb CASCADE;

CREATE TABLE focal_follow_trajectory (
  session_id  uuid PRIMARY KEY REFERENCES focal_follow_session(id) ON DELETE CASCADE,
  trip        tgeompoint NOT NULL,             -- SRID 4326, linear interpolation
  point_count integer NOT NULL,
  built_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX focal_follow_trajectory_trip_gist ON focal_follow_trajectory USING gist (trip);

CREATE TABLE visit_route_trajectory (
  survey_visit_id uuid PRIMARY KEY REFERENCES survey_visit(id) ON DELETE CASCADE,
  trip            tgeompoint NOT NULL,
  point_count     integer NOT NULL,
  built_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX visit_route_trajectory_trip_gist ON visit_route_trajectory USING gist (trip);

CREATE OR REPLACE FUNCTION rebuild_focal_follow_trajectory(p_session uuid) RETURNS void
LANGUAGE sql AS $$
  INSERT INTO focal_follow_trajectory (session_id, trip, point_count, built_at)
  SELECT p_session,
         tgeompointSeq(array_agg(tgeompoint(geometry, recorded_at) ORDER BY recorded_at)),
         count(*), now()
  FROM focal_follow_point
  WHERE session_id = p_session AND deleted_at IS NULL
  GROUP BY 1
  HAVING count(*) >= 2
  ON CONFLICT (session_id) DO UPDATE
    SET trip = EXCLUDED.trip, point_count = EXCLUDED.point_count, built_at = now();
$$;
```

c) Drift: none. Trajectories are server-derived; the phone has the raw points (T089).

d) Django-specific limitation
- Django can't migrate or query `tgeompoint` columns natively. Use raw SQL in services, and unmanaged models for scalar columns.
- `manage.py migrate` on an empty database must run after the extension is created (the migration order is enforced with a dependency).
- `pg_dump`/`pg_restore` need MobilityDB installed at the same version on the target.

**Limitations / out of scope / risks**
- **p2-compat:** `visit_route_trajectory` reads Phase 1 `survey_track_point` unchanged, which shows the Phase 1 design didn't block Phase 2.

---

### T089 · Focal-follow data model and sync
**ID:** T089 · **Implements:** F58 · **Labels:** `backend`, `database`, `sync`, `must` · **Milestone:** Phase 2 · **Epic:** E14 · **Depends on:** T087, T044, T026 · **Estimate:** 2 d

**Description**
Model a focal-follow session (one individual followed for a few minutes), its positions and its events. These sync through the existing push/pull with three new entity types.

**Acceptance criteria**
- [ ] Models below. New push/pull entity types: `focal_follow_session`, `focal_follow_point` (with `create_batch`) and `trajectory_event`.
- [ ] A session links to the `ButterflyObservation` with `source = focal_follow` created at start (same taxon), and optionally to the visit during which it happened.
- [ ] Locking (T042) also covers sessions attached to locked visits.
- [ ] Admin: a session list with a map of points and an events inline.

**Database**

a) GeoDjango model

```python
# backend/mobility/models.py (continued)
from django.conf import settings
from django.contrib.gis.db import models as gis
from simple_history.models import HistoricalRecords
from core.models import SyncableModel


class PositionMethod(models.TextChoices):
    OBSERVER_GPS = "observer_gps"; MANUAL_ESTIMATE = "manual_estimate"; MIXED = "mixed"

class PointMethod(models.TextChoices):
    OBSERVER_GPS = "observer_gps"; MANUAL_ESTIMATE = "manual_estimate"

class EventType(models.TextChoices):
    LANDING = "landing"; FEEDING = "feeding"; RESTING = "resting"; TERRITORIAL = "territorial"
    OVIPOSITION = "oviposition"; ROAD_CROSSING = "road_crossing"; HABITAT_CHANGE = "habitat_change"
    LOST_SIGHT = "lost_sight"; OTHER = "other"


class FocalFollowSession(SyncableModel):
    project = models.ForeignKey("projects.Project", on_delete=models.PROTECT, related_name="focal_follows")
    survey_visit = models.ForeignKey("surveys.SurveyVisit", on_delete=models.PROTECT, null=True, blank=True,
                                     related_name="focal_follows")
    observation = models.OneToOneField("observations.ButterflyObservation", on_delete=models.PROTECT,
                                       related_name="focal_follow")
    taxon = models.ForeignKey("catalogues.Taxon", on_delete=models.PROTECT)
    individual_label = models.CharField(max_length=50, blank=True)
    started_at = models.DateTimeField()
    ended_at = models.DateTimeField(null=True, blank=True)
    position_method = models.CharField(max_length=20, choices=PositionMethod.choices)
    recorded_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")
    lost_sight = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    history = HistoricalRecords(table_name="historical_focal_follow_session")

    class Meta:
        db_table = "focal_follow_session"
        constraints = [
            models.CheckConstraint(condition=models.Q(position_method__in=PositionMethod.values), name="ff_method_valid"),
            models.CheckConstraint(condition=models.Q(ended_at__isnull=True) | models.Q(ended_at__gte=models.F("started_at")),
                                   name="ff_times_ok"),
        ]


class FocalFollowPoint(SyncableModel):          # no history: append-only
    session = models.ForeignKey(FocalFollowSession, on_delete=models.CASCADE, related_name="points")
    recorded_at = models.DateTimeField()
    geometry = gis.PointField(srid=4326)
    accuracy_m = models.DecimalField(max_digits=6, decimal_places=1, null=True, blank=True)
    method = models.CharField(max_length=20, choices=PointMethod.choices)
    sequence_number = models.PositiveIntegerField()

    class Meta:
        db_table = "focal_follow_point"
        indexes = [models.Index(fields=["session", "recorded_at"])]
        constraints = [
            models.UniqueConstraint(fields=["session", "sequence_number"], name="ff_point_seq_unique"),
            models.CheckConstraint(condition=models.Q(method__in=PointMethod.values), name="ff_point_method_valid"),
        ]


class TrajectoryEvent(SyncableModel):
    session = models.ForeignKey(FocalFollowSession, on_delete=models.CASCADE, related_name="events")
    event_type = models.CharField(max_length=20, choices=EventType.choices)
    occurred_at = models.DateTimeField()
    ended_at = models.DateTimeField(null=True, blank=True)      # for durations (resting, feeding)
    geometry = gis.PointField(srid=4326, null=True, blank=True)
    plant_resource = models.ForeignKey("resources.PlantResourceObservation", on_delete=models.SET_NULL,
                                       null=True, blank=True)
    derived = models.BooleanField(default=False)              # True = computed by T091, False = recorded
    notes = models.TextField(blank=True)
    history = HistoricalRecords(table_name="historical_trajectory_event")

    class Meta:
        db_table = "trajectory_event"
        indexes = [models.Index(fields=["session", "occurred_at"])]
        constraints = [models.CheckConstraint(condition=models.Q(event_type__in=EventType.values), name="traj_event_type_valid")]
```

b) PostGIS DDL

```sql
CREATE TABLE focal_follow_session (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  project_id       uuid NOT NULL REFERENCES project(id),
  survey_visit_id  uuid NULL REFERENCES survey_visit(id),
  observation_id   uuid NOT NULL UNIQUE REFERENCES butterfly_observation(id),
  taxon_id         uuid NOT NULL REFERENCES taxon(id),
  individual_label varchar(50) NOT NULL,
  started_at       timestamptz NOT NULL,
  ended_at         timestamptz NULL,
  position_method  varchar(20) NOT NULL CONSTRAINT ff_method_valid
                   CHECK (position_method IN ('observer_gps','manual_estimate','mixed')),
  recorded_by_id   uuid NOT NULL REFERENCES app_user(id),
  lost_sight       boolean NOT NULL DEFAULT false,
  notes            text NOT NULL,
  CONSTRAINT ff_times_ok CHECK (ended_at IS NULL OR ended_at >= started_at)
);

CREATE TABLE focal_follow_point (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  session_id      uuid NOT NULL REFERENCES focal_follow_session(id) ON DELETE CASCADE,
  recorded_at     timestamptz NOT NULL,
  geometry        geometry(Point, 4326) NOT NULL,
  accuracy_m      numeric(6,1) NULL,
  method          varchar(20) NOT NULL CONSTRAINT ff_point_method_valid CHECK (method IN ('observer_gps','manual_estimate')),
  sequence_number integer NOT NULL,
  CONSTRAINT ff_point_seq_unique UNIQUE (session_id, sequence_number)
);
CREATE INDEX focal_follow_point_session_time_idx ON focal_follow_point (session_id, recorded_at);
CREATE INDEX focal_follow_point_geometry_gist ON focal_follow_point USING gist (geometry);

CREATE TABLE trajectory_event (
  id uuid PRIMARY KEY, server_version bigint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL, deleted_at timestamptz NULL,
  created_by_id uuid NULL REFERENCES app_user(id), updated_by_id uuid NULL REFERENCES app_user(id),
  session_id        uuid NOT NULL REFERENCES focal_follow_session(id) ON DELETE CASCADE,
  event_type        varchar(20) NOT NULL CONSTRAINT traj_event_type_valid CHECK (event_type IN
                    ('landing','feeding','resting','territorial','oviposition','road_crossing','habitat_change','lost_sight','other')),
  occurred_at       timestamptz NOT NULL,
  ended_at          timestamptz NULL,
  geometry          geometry(Point, 4326) NULL,
  plant_resource_id uuid NULL REFERENCES plant_resource_observation(id) ON DELETE SET NULL,
  derived           boolean NOT NULL DEFAULT false,
  notes             text NOT NULL
);
CREATE INDEX trajectory_event_session_time_idx ON trajectory_event (session_id, occurred_at);
-- + server_version indexes and triggers on all three tables
```

c) Drift

```dart
class FocalFollowSessions extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text().references(Projects, #id)();
  TextColumn get surveyVisitId => text().nullable()();
  TextColumn get observationId => text()();
  TextColumn get taxonId => text()();
  TextColumn get individualLabel => text().withDefault(const Constant(''))();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get positionMethod => text()();
  BoolColumn get lostSight => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class FocalFollowPoints extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(FocalFollowSessions, #id)();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracyM => real().nullable()();
  TextColumn get method => text()();
  IntColumn get sequenceNumber => integer()();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  @override
  Set<Column> get primaryKey => {id};
}

class TrajectoryEvents extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(FocalFollowSessions, #id)();
  TextColumn get eventType => text()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lon => real().nullable()();
  TextColumn get plantResourceId => text().nullable()();
  BoolColumn get derived => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get serverVersion => integer().nullable()();
  TextColumn get syncStatus => textEnum<SyncStatus>()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
```
Differences from the server:
- lat/lon instead of geometry.
- `recorded_by` is not stored (it is the current user).
- Derived events (`derived = true`) arrive by pull.

d) Django-specific limitation: none beyond the earlier tickets. All three are ordinary GeoDjango models. Only the trajectory tables (T088) need raw SQL.

**Limitations / out of scope / risks**
- **p2-compat:** new tables only. `butterfly_observation` is unchanged; it already has `source = focal_follow`.

---

### T090 · App focal-follow session
**ID:** T090 · **Implements:** F58 · **Labels:** `mobile`, `must` · **Milestone:** Phase 2 · **Epic:** E14 · **Depends on:** T089, T037, T045 · **Estimate:** 2.5 d

**Description**
Follow one butterfly for a few minutes, recording its path and behaviour with minimal taps.

**Acceptance criteria**
- [ ] **Start:** "Follow an individual" from the active visit or project home. Pick the species (quick picker from T045) and an optional label (for example "F1"). This creates the session and its `focal_follow` observation.
- [ ] **Position modes:**
  - **Observer GPS**: 1–2 s interval via `LocationSource`
  - **Tap estimate**: tap the map where the butterfly is now; each tap records a point with the current time
  - **Mixed**: both at once
- [ ] An event button row: land, feed, rest (start/stop), territorial, oviposit (links a plant), road crossing, lost sight (ends the session).
- [ ] **Stop** shows a summary: duration, path length, number of events, and a mini-map of the path.
- [ ] A banner shows GPS accuracy, with the warning "Phone GPS is too coarse for small movements; prefer tap estimates" when accuracy is over 5 m (outline §9.3).
- [ ] Works offline. Points are batched like track points.

**Limitations / out of scope / risks**
- Tap estimates depend on the observer's judgement. The thesis must describe the method (outline §9.3).

---

### T091 · Behaviour events on trajectories
**ID:** T091 · **Implements:** F59 · **Labels:** `backend`, `database`, `should` · **Milestone:** Phase 2 · **Epic:** E14 · **Depends on:** T088, T089, T053 · **Estimate:** 1.5 d

**Description**
Besides events recorded in the app, derive events from the trajectory: habitat changes and stops.

**Acceptance criteria**
- [ ] **`habitat_change`:** intersect the trajectory with habitat-feature polygons and create an event at each entry into a different habitat type (MobilityDB `atGeometry`/`eintersects`, VERIFY names, or the PostGIS fallback over consecutive points).
- [ ] **Stops:** speed below 0.2 m/s for at least 10 s creates a `resting` event with `ended_at` (MobilityDB `speed()` plus `whenTrue`/`atValues`, VERIFY names).
- [ ] Derived events have `derived = true`. Rebuilding deletes and recreates only derived events.
- [ ] Events are exposed as temporal properties in the MF API (T093).

**Limitations / out of scope / risks**
- Thresholds are heuristic and documented, not validated against real behaviour.

---

### T092 · Moving Features API: service and collections
**ID:** T092 · **Implements:** F56 · **Labels:** `ogc`, `infra`, `must` · **Milestone:** Phase 2 · **Epic:** E14 · **Depends on:** T087, T088 · **Estimate:** 2 d

**Description**
Stand up the Moving Features endpoint chosen in the ADR and serve focal-follow sessions as a collection of moving features.

**Acceptance criteria**
- **Option A (AIST fork):**
  - [ ] Compose service `pygeoapi-mf` built from a pinned commit of `aistairc/pygeoapi-mf-api`, configured to read the tables or views it expects. Create them as views over `focal_follow_trajectory` in schema `mobility` if needed.
  - [ ] nginx `/ogc-mf/` with the same `auth_request` (admin-only).
- **Option B (DRF):**
  - [ ] Django app `mfapi` with read-only endpoints under `/api/v1/mf/`:
    - landing page
    - `conformance`
    - `collections`
    - `collections/{collectionId}`
    - `collections/{collectionId}/items`: MovingFeature summaries with id, temporal extent, bbox and properties (taxon, label, method)
    - `collections/{collectionId}/items/{mFeatureId}`
- [ ] Collections: `focal-follows` (sessions) and `observer-routes` (visit routes from Phase 1 data).
- [ ] Paging with `limit` and `bbox`/`datetime` filters on items.

**Limitations / out of scope / risks**
- Read-only. MF-API's create/update operations are not implemented (writes go through sync, as in Phase 1).

---

### T093 · Moving Features API: temporal geometry and properties
**ID:** T093 · **Implements:** F56, F59 · **Labels:** `ogc`, `must` · **Milestone:** Phase 2 · **Epic:** E14 · **Depends on:** T092 (behaviour tproperty needs T091) · **Estimate:** 1.5 d

**Description**
Serve the actual trajectories and temporal properties in MF-JSON.

**Acceptance criteria**
- [ ] `items/{id}/tgsequence` returns a MF-JSON `MovingPoint` (coordinates, datetimes, interpolation `Linear`), generated with MobilityDB `asMFJSON(trip)` (VERIFY the function and output shape).
- [ ] `items/{id}/tproperties` lists `behaviour` (ttext, step interpolation, from events) and `speed` (tfloat, linear). `items/{id}/tproperties/{name}` returns values over time.
- [ ] `?datetime=` sub-setting on `tgsequence` uses MobilityDB `atTime` (VERIFY).
- [ ] Output validates against the MF-JSON schema (VERIFY the schema location) in a test.
- [ ] Conformance classes are declared honestly (partial where applicable).

**Limitations / out of scope / risks**
- If option A's fork already serves these resources, this ticket becomes configuration plus validation only.

---

### T094 · Trajectory display
**ID:** T094 · **Implements:** F60 · **Labels:** `mobile`, `ogc`, `must` · **Milestone:** Phase 2 · **Epic:** E14 · **Depends on:** T090, T093 · **Estimate:** 2 d

**Description**
Show trajectories with time in the app, in QGIS and through an MF-aware client.

**Acceptance criteria**
- [ ] **App:** a focal-follow detail screen with the path polyline coloured by speed, event markers, and a **time slider** moving a marker along the path (interpolated locally from points). The map layer "Focal follows" is added to T059.
- [ ] **QGIS:** view `geo.focal_follow_points` (point, time, session, method) as a pygeoapi Features collection, animated with the Temporal Controller. Screenshots for the thesis.
- [ ] **MF client:** load `/ogc-mf/` or `/api/v1/mf/` in an MF-API-capable client, for example STINUUM (used in the FOSS4G 2026 MF workshop; VERIFY setup), or a small Leaflet/MapLibre page in `evaluation/mf-viewer/` that reads `tgsequence`.
- [ ] Recorded results feed T095.

**Limitations / out of scope / risks**
- The time slider in the app interpolates linearly between recorded points. Gaps when sight is lost are shown as breaks.

---
## E15 · Part 2 evaluation

### E15 · Epic: Part 2 evaluation
**Labels:** `epic`, `evaluation`, `research` · **Milestone:** Phase 2 · **Implements:** F61 (P2 part), F70, F89
Evaluate the three standards with external clients and conformance tools, compare PostGIS and MobilityDB, and write the comparison that closes Part 2.
Children: T095 · T096 · T097

---

### T095 · Interoperability and conformance evaluation of SensorThings, EDR and Moving Features
**ID:** T095 · **Implements:** F61 · **Labels:** `evaluation`, `ogc`, `must` · **Milestone:** Phase 2 · **Epic:** E15 · **Depends on:** T083, T094 (pygeoapi STA bridge test needs T080) · **Estimate:** 2 d

**Description**
Show which standard clients can consume each service, and how fast.

**Acceptance criteria**
- [ ] **SensorThings:**
  - QGIS native SensorThings provider (VERIFY version)
  - a Python client (`requests` or an STA client library)
  - optional: OGC CITE `ets-sta10`, if available (VERIFY)
- [ ] **EDR:** a Python notebook reading CoverageJSON for each supported query, with a check for QGIS or another EDR client (VERIFY), and the EDR CITE suite if available.
- [ ] **Moving Features:** STINUUM or the custom viewer (T094), plus validation of MF-JSON output.
- [ ] Response times (p50/p95) for typical requests on the simulated season.
- [ ] Results table (standard, client, operation, result, time, notes) in `evaluation/interop/part2-results.md`.

---

### T096 · PostGIS vs MobilityDB comparison
**ID:** T096 · **Implements:** F61, F70 · **Labels:** `evaluation`, `database`, `should` · **Milestone:** Phase 2 · **Epic:** E15 · **Depends on:** T087, T088, T091 · **Estimate:** 1.5 d

**Description**
Turn the T087 spike into a proper, reproducible comparison for the thesis.

**Acceptance criteria**
- [ ] The same six queries (T087) on the simulated season: all observer routes, plus simulated focal follows (add a generator option to T071 if needed), in both implementations.
- [ ] Metrics: execution time (median of 10 runs, warm cache), SQL lines, correctness check (results equal within tolerance), storage size.
- [ ] A results table and a short discussion in `evaluation/results/postgis-vs-mobilitydb.md`.

---

### T097 · Standards comparison write-up
**ID:** T097 · **Implements:** F89 · **Labels:** `research`, `docs`, `must` · **Milestone:** Phase 2 · **Epic:** E15 · **Depends on:** T095 (+ T096 if done) · **Estimate:** 1 d

**Description**
Close Part 2 with a synthesis of what each standard adds to butterfly monitoring, what it cost, and how mature the tools are.

**Acceptance criteria**
- [ ] `docs/standards/comparison.md` has a table per standard: purpose in this system, implementation used, effort (days from these tickets), maturity of tools, client support found, limitations, and recommendation.
- [ ] It states plainly that sensor data is simulated, along with the GPS-accuracy caveat for Moving Features.

---
# Part D: Epic overview, build order and capacity

## D.1 Epic overview

Estimates are ideal working days for one developer. "Must", "Should" and "Could" follow the v4 MoSCoW tags (Part A.1), with the two promotions noted in T020 and T063.

| Epic | Name | Milestone | Implements | Tickets | Must (d) | Should (d) | Could (d) | Total (d) |
|---|---|---|---|---|---|---|---|---|
| E01 | Foundations and infrastructure | Phase 1 | F44, F45, F46, F77, F78 | T001–T010 (10) | 16 | – | – | 16 |
| E02 | Accounts, roles, projects and audit | Phase 1 | F1, F2, F3, F4, F62, F71, F72, F73 | T011–T018 (8) | 12.5 | – | – | 12.5 |
| E03 | Catalogues and transects | Phase 1 | F6, F18, F22, F63, F64, F79 | T019–T024 (6) | 9.5 | 1.5 | – | 11 |
| E04 | Offline storage and synchronisation | Phase 1 | F7, F23, F24, F25, F26, F28 | T025–T032 (8) | 15 | – | – | 15 |
| E05 | Field visit | Phase 1 | F8, F9, F10, F11, F12, F13, F66, F72, F87 | T033–T043 (11) | 19.5 | – | – | 19.5 |
| E06 | Butterfly observations and photos | Phase 1 | F14, F15, F16, F17, F19, F27 | T044–T050 (7) | 10 | 3.5 | – | 13.5 |
| E07 | Plants and habitat | Phase 1 | F20, F21 | T051–T054 (4) | – | 7 | – | 7 |
| E08 | Validation and data quality | Phase 1 | F30, F31, F32, F33 | T055–T058 (4) | 2 | 4.5 | – | 6.5 |
| E09 | Map, indicators and export | Phase 1 | F29, F34, F35, F36, F37, F67, F74 | T059–T066 (8) | 6 | 4 | 3 | 13 |
| E10 | OGC API – Features (pygeoapi, read-only) | Phase 1 | F39, F40, F41, F43, F45, F68 | T067–T070 (4) | 6.5 | – | – | 6.5 |
| E11 | Simulated data and evaluation (Part 1) | Phase 1 | F61 (P1 part), F80 | T071–T075 (5) | 9.5 | – | – | 9.5 |
| E12 | OGC SensorThings API | Phase 2 | F47, F48, F49, F50, F69, F89 | T076–T081 (6) | 9 | 1.5 | – | 10.5 |
| E13 | OGC API – EDR | Phase 2 | F52, F53, F55, F89 | T082–T085 (4) | 4.5 | 1.5 | – | 6 |
| E14 | OGC API – Moving Features and MobilityDB | Phase 2 | F56, F57, F58, F59, F60, F70, F89 | T086–T094 (9) | 15 | 1.5 | – | 16.5 |
| E15 | Part 2 evaluation | Phase 2 | F61 (P2 part), F70, F89 | T095–T097 (3) | 3 | 1.5 | – | 4.5 |
| **Phase 1** | | | | **75** | **106.5** | **20.5** | **3** | **130** |
| **Phase 2** | | | | **22** | **31.5** | **6** | **–** | **37.5** |
| **All** | | | | **97** | **138** | **26.5** | **3** | **167.5** |

Every v4 feature is implemented by at least one ticket, and no removed feature appears in any ticket. The full feature → ticket index is in D.6.

## D.2 Suggested build order

The order follows the dependencies in each ticket. Each stage ends with something you can demonstrate, so a stage is a natural point to stop, write and show your supervisor.

### Phase 1 (milestone `Phase 1 – Thesis Part 1`)

| Stage | Tickets, in order | Must (d) | Cumulative (d) | Done when you can show… |
|---|---|---|---|---|
| 1 · Foundations | T001, T002, T003, T006, T004, T005, T009, T007, T008, T010 | 16 | 16 | One observation typed on the phone, synced over Tailscale, visible in QGIS (T007). CI green. A backup restored once. |
| 2a · Accounts and projects | T011, T013, T014, T012, T015, T016, T018, T017 | 12.5 | 28.5 | An admin creates a project and adds a researcher, who logs in on the phone and sees it. History is recorded. **→ Velocity checkpoint (D.4).** |
| 2b · Catalogues and transects | T019, T020, T021, T022, T024 | 9.5 | 38 | A seeded project with the Serbian butterfly list, plants, codelists and a transect split into sections. |
| 3 · Sync core | T025, T026, T029, T030, T027, T028, T031, T032 | 15 | 53 | Two phones edit the same record offline, both sync, the conflict appears in Django admin and is resolved there. Offline package downloads. **→ Re-check velocity.** |
| 4 · Field visit and observations | T033, T034, T035, T036, T037, T042, T039, T044, T045, T055, T040, T041, T043, T038 | 26.5 | 79.5 | A full walk in airplane mode: start a visit, track GPS in the background, record butterflies, finish with a true zero where needed, sync, then lock the visit in admin. |
| 5 · Photos, environment, export, OGC | T049, T050, T063, T064, T067, T068, T069, T059 | 16 | 95.5 | Photos land in MinIO. An admin exports CSV/GeoJSON and loads `/ogc` collections in QGIS with a token. The app map shows the day's data. |
| 6 · Simulation and evaluation | T071, T072, T070, T073, T074, T075 | 11 | 106.5 | A simulated season in the database, GPS replay on the phone, OGC conformance results, and the Part 1 evaluation data. |

**Should and Could fill (Phase 1).** Only when the checkpoint allows, in this order: T046, T048, T051, T052, T053, T054, T058, T057, T056, T047, T061, T062, T065, T023, T060, T066 (20.5 d Should, 3 d Could). Plants and habitat (E07) come first because they are part of the outline's research question. The validation queue comes next because admins need it once real data arrives.

### Phase 2 (milestone `Phase 2 – Thesis Part 2`)

| Stage | Tickets, in order | Must (d) | Should (d) | Done when you can show… |
|---|---|---|---|---|
| 7 · SensorThings | T076, T077, T078, T079, T081, T080 | 9 | 1.5 | Simulated stations registered from Django admin, streaming into FROST, and their values attached to visits. |
| 8 · EDR | T082, T083, T084, T085 | 4.5 | 1.5 | Weather for a visit's place and time fetched through `/ogc/collections/.../position` and `/area`. |
| 9 · Moving Features + MobilityDB | T086, T087, T089, T088, T090, T092, T091, T093, T094 | 15 | 1.5 | A focal-follow track recorded on the phone, stored as `tgeompoint`, served as MF-JSON and drawn in the app. |
| 10 · Evaluation | T095, T096, T097 | 3 | 1.5 | Conformance results for all three standards and the comparison chapter draft. |

The three study tickets (T076, T082, T086) have no dependencies. They are reading and writing, not code, so you can do them whenever you are blocked on something else late in Phase 1 without breaking the "no Phase 2 proof of concept in Phase 1" rule. T091 needs `HabitatFeature` (T053, a Phase 1 Should); if T053 was skipped, T091 is skipped too.

## D.3 Capacity check

**Available time.** From 13 October 2026 to the end of January 2027 there are 79 weekdays. After public holidays and a short break over New Year, that leaves about **75 working days**. Reserve about 15 of those for writing the thesis, and you have about **60 development days**, assuming you work on this full time. If the deadline is the end of February, add about 20 days.

| Scope | Estimate (d) | Ratio to ~60 days |
|---|---|---|
| Phase 1 Must | 106.5 | 1.8× |
| Phase 1 Must + Phase 2 Must | 138 | 2.3× |
| Everything (Must + Should + Could) | 167.5 | 2.8× |

**The full Must list does not fit by February at the estimated pace.** The estimates are deliberately honest about testing, Android quirks and documentation. You may well go faster than them, especially on the Django models, admin and DRF boilerplate, where AI-assisted coding helps a lot. You are unlikely to go much faster on GPS, sync and debugging on a real phone. Don't plan on hope: measure your pace through Stage 2a, then decide (D.4).

Where you land on 1 February with ~60 development days, by pace `r` (actual days ÷ estimated days):

| Pace `r` | Estimated days completed | Where you are |
|---|---|---|
| 1.0 (as estimated) | ~60 | Early in Stage 4: visits can be started, but GPS tracking and observations are not done |
| 0.7 | ~86 | Stage 5: Phase 1 core works; OGC and export not finished |
| 0.5 | ~120 | End of Stage 8: Phase 1 done, SensorThings and EDR done, Moving Features not started |
| 0.43 or faster | ~138 | All Must tickets in both phases |

## D.4 Velocity checkpoint and cut lines

**Track actual days from day one.** When you close an issue, add a line `Actual: x d`. If you use a GitHub Project board, add two number fields, `Estimate` and `Actual`, which makes the sum trivial.

**Checkpoint after Stage 2a** (T001–T018, 28.5 estimated days). Compute `r = actual days ÷ 28.5` and pick a row. Re-check after Stage 3 (53 estimated days), because the first weeks include one-off setup and are a noisy sample. The thresholds assume ~60 development days; if your deadline is the end of February, multiply them by 4/3.

**Decision (14 October 2026):** Part 2 has a later deadline, so February covers Phase 1 only. At `r` ≤ 0.56 every Phase 1 Must ticket fits in ~60 days; above that, apply cut line A. Phase 2 runs after February, in full unless its own deadline calls for cut line B. The table below still applies if that changes.

| Pace `r` | Plan |
|---|---|
| ≤ 0.43 | Keep every Must in both phases. Start pulling Should tickets after Stage 6 if the Stage 3 re-check agrees. |
| 0.43–0.5 | Apply **cut line A** to Phase 1 and **cut line B** to Phase 2 (about 123.5 d in total). |
| 0.5–0.6 | Phase 1 with cut line A (about 100 d) for February. Part 2 becomes the three studies plus the write-up (T076, T082, T086, T097: 4 d), unless Part 2 has a later deadline; then run cut line B after February. |
| > 0.6 | Even trimmed Phase 1 doesn't fit. Talk to your supervisor before going further. Deeper cuts would remove what Part 1 is about (offline sync and conflicts). |

### Cut line A: trims to Phase 1 Must tickets

Each trim keeps the feature but makes it smaller. Nothing here touches the Phase 2 foundations (track points, `EnvironmentalSnapshot`, the `geo` schema).

| Ticket | Trim | Saves (d) |
|---|---|---|
| T016 | Draw the study area in the admin widget only; drop the GeoJSON/KML upload action. | 0.5 |
| T017 | A plain project list with a simple home (Transects, Sync); no counters. | 0.5 |
| T022 | Drop GPX/KML import and "Generate N sections". Draw lines in the default widget and load demo transects from GeoJSON in T024. | 1 |
| T028 | Drop the side-by-side template. Show the base, server and client payloads as read-only fields with the two actions. | 0.5 |
| T032 | Keep errors, conflicts and Sync now; drop byte and photo-size statistics. | 0.5 |
| T038 | Keep the GPS gap banner; drop the battery-saver mode. | 0.5 |
| T059 | Transect, sections, route and observations only; no filters. | 1 |
| T064 | CSV and GeoJSON for visits, observations and transects; no ZIP bundle. | 1 |
| T073 | Log visit start and observation save times only; drop tap counting. | 0.5 |
| T074 | Drop the battery test; keep the sync and performance tests. | 0.5 |
| **Total** | | **6.5** |

Cut line A only saves about 6.5 days. It cannot close the gap on its own: your real levers are your pace and the Part 2 deadline.

### Cut line B: minimum Phase 2

Keep a working implementation of all three standards, but drop the app-side features and the extras.

| Keep (23.5 d) | Drop (14 d) |
|---|---|
| **SensorThings:** T076, T077, T078, T079, T081 | T080 station map layer and collections |
| **EDR:** T082, T083 | T084 visit weather via EDR, T085 app auto-fill |
| **Moving Features:** T086, T087, T088, T092, T093, using **visit routes from Phase 1 track points** as the moving features | T089 focal-follow model, T090 app focal follow, T091 behaviour events, T094 trajectory display |
| **Evaluation:** T095 (tested with curl and QGIS instead of the app), T097 | T096 PostGIS vs MobilityDB comparison |

Under cut line B, T088 builds only `visit_route_trajectory`, so its dependency on T089 goes away. This is also a good thesis story: Phase 1 data is reused by a Phase 2 standard with no schema change.

## D.5 Importing into GitHub

1. Create the two milestones and the labels from Part A.8.
2. Create the epics E01–E15 first, then the tickets T001–T097 in ID order. Keep the ID at the start of each issue title (`T025 · Pull API with server-version cursor`), so `Depends on: T0xx` stays searchable without rewriting it into issue numbers.
3. Attach each ticket to its epic as a sub-issue.
4. Optional: a GitHub Project board with the fields `Estimate` and `Actual` (D.4), grouped by stage.

## D.6 Feature → ticket index

| Feature | Tickets |
|---|---|
| F1 | T011, T012 |
| F2 | T013 |
| F3 | T015, T017 |
| F4 | T018 |
| F6 | T021 |
| F7 | T025, T031 |
| F8 | T035 |
| F9 | T034, T041 |
| F10 | T036, T037 |
| F11 | T039, T040 |
| F12 | T041 |
| F13 | T026, T042 |
| F14 | T044, T045 |
| F15 | T044, T046 |
| F16 | T049, T050 |
| F17 | T044, T047 |
| F18 | T019 |
| F19 | T048 |
| F20 | T051, T052 |
| F21 | T053, T054 |
| F22 | T020 |
| F23 | T006, T029 |
| F24 | T029, T030 |
| F25 | T005, T025, T026, T030 |
| F26 | T027, T028 |
| F27 | T049, T050 |
| F28 | T032 |
| F29 | T060 |
| F30 | T055 |
| F31 | T056 |
| F32 | T057 |
| F33 | T058 |
| F34 | T059 |
| F35 | T061, T062 |
| F36 | T064 |
| F37 | T066 |
| F39 | T068 |
| F40 | T067, T068 |
| F41 | T068 |
| F43 | T070 |
| F44 | T002, T003, T009 |
| F45 | T004, T005, T067 |
| F46 | T003, T008, T010 |
| F47 | T077 |
| F48 | T078 |
| F49 | T078, T080 |
| F50 | T081 |
| F52 | T083 |
| F53 | T084 |
| F55 | T085 |
| F56 | T092, T093 |
| F57 | T088 |
| F58 | T089, T090 |
| F59 | T091, T093 |
| F60 | T094 |
| F61 | T073, T074, T075, T095, T096 |
| F62 | T013, T014 |
| F63 | T022 |
| F64 | T020, T023 |
| F66 | T043 |
| F67 | T065 |
| F68 | T069 |
| F69 | T079 |
| F70 | T087, T096 |
| F71 | T016 |
| F72 | T006, T017, T033 |
| F73 | T016 |
| F74 | T063 |
| F77 | T001 |
| F78 | T007 |
| F79 | T024 |
| F80 | T071, T072 |
| F87 | T037, T038 |
| F89 | T076, T082, T086, T097 |
