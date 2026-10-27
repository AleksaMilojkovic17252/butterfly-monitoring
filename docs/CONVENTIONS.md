# Conventions

Shared decisions every ticket refers to ("Part A" in the tickets). Copied from GitHub issue #1, which stays the source of truth: if they differ, the issue wins, so update this file to match.

## A.1 Feature list v4 (what these tickets cover)

- **Phase 1 (thesis Part 1):** F1–F4, F6–F37 (except F5), F39–F41, F43–F46, F61 (P1 part), F62–F64, F66–F68, F71–F74, F77–F80, F87.
- **Phase 2 (thesis Part 2):** F47–F50, F52, F53, F55–F60, F61 (P2 part), F69, F70, F89.
- **Removed (no tickets):** F5, F38, F42, F51, F54, F65, F75, F76, F81, F82, F83, F84, F85, F86, F88.
- **v4 changes:** two roles (F2, F62); admins create projects and add members (F3); validation, conflicts, exports and pygeoapi are admin-only; lock/unlock lives in Django admin and the API enforces it (F13, F66); MobilityDB is the Phase 2 target (F57 Must; F70 becomes a research and design spike, with plain PostGIS as the fallback); F89 [PROPOSED] adds a Phase 2 study per standard; the laptop is the only server, reached over **Tailscale**.

## A.2 Roles (F2)

| Group | App | Django admin | Data scope |
|---|---|---|---|
| `researcher` | yes | **no** (`is_staff = False`) | projects where they are a member; in the app, only their own visits and observations |
| `admin` | yes (same as researcher) | yes, all models | all projects; only admins validate, resolve conflicts, lock/unlock, export, and use pygeoapi |

There is no custom permission framework. The `admin` group holds all model permissions through a data migration (T013). DRF permission classes check either project membership or admin-group membership.

## A.3 Runtime layout (all on your CachyOS laptop)

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

## A.4 Version pins (all VERIFY at T002/T003; pin exact versions in lock files)

| Component | Target | Note |
|---|---|---|
| Python | 3.12 | |
| Django | 5.2 LTS | LTS until April 2028; safer than 6.x for a thesis |
| djangorestframework | 3.16.x | VERIFY Django 5.2 support |
| djangorestframework-simplejwt | 5.5.x | uses the `token_blacklist` app for logout |
| drf-spectacular | 0.28.x | VERIFY |
| django-simple-history | 3.8+ | VERIFY Django 5.2 support |
| django-import-export | 4.4.1 | CSV import/export of catalogues (T023); approved for T023 |
| django-storages[s3] + boto3 | 1.14.x | |
| psycopg | 3.2.x | |
| requests | 2.34.x | GBIF calls of the seed commands (T024); approved for T024 |
| pygeoapi | 0.24.x | 0.24.0 released mid-2026 |
| PostgreSQL / PostGIS / MobilityDB | 17 / 3.5 / 1.3 | image `mobilitydb/mobilitydb:17-3.5-1.3` (built on `postgis/postgis`) |
| FROST-Server (P2) | 2.x latest | VERIFY current tag (2.7.x/2.8.x seen) |
| Flutter | current stable | VERIFY |
| drift / drift_flutter | 2.x | |
| flutter_map + latlong2 | 8.3.2 / 0.10.1 | transect map (T033); approved for T033 |
| geolocator | latest | Android foreground service via `foregroundNotificationConfig` (VERIFY API) |
| flutter_riverpod, go_router, dio, uuid, flutter_secure_storage, image_picker, flutter_image_compress, crypto | latest | |
| connectivity_plus | latest | network-change trigger of the sync runner (T030); approved for T030 |
| permission_handler | 13.0.2 | notification permission and the battery-optimisation dialog of GPS tracking (T037); approved for T037 |
| Android build: AGP / Gradle / compileSdk | 9.2.1 / 9.4.1 / 37 | raised in T037 for permission_handler_android 14 (needs compileSdk 37); `compileSdk` is set in `app/build.gradle.kts`, not taken from Flutter (36) |

## A.5 Database conventions (apply to every table ticket)

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

## A.6 Drift (SQLite) conventions

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

## A.7 API conventions

- **Paths:** base path `/api/v1/`. JSON only. OpenAPI via drf-spectacular at `/api/v1/schema/`, with Swagger UI at `/api/v1/docs/`.
- **Auth:** `Authorization: Bearer <JWT access>`. Access tokens last 15 min and refresh tokens 30 days, with rotation and blacklist on.
- **Errors:** a consistent body, `{"code": "...", "detail": "...", "fields": {...}}`.
- **Sync is the main write path.** The app writes through `POST /api/v1/sync/push`. The outline's REST endpoints (`POST /survey-visits`, etc.) exist as normal DRF viewsets for testing and docs, but share the same service-layer functions, so the rules live in one place.

## A.8 Labels and milestones

**Milestones:** `Phase 1 – Thesis Part 1`, `Phase 2 – Thesis Part 2`.

**Labels:**
- type: `epic`, `backend`, `mobile`, `admin`, `database`, `sync`, `ogc`, `infra`, `research`, `evaluation`, `docs`, `security`
- priority: `must`, `should`, `could`
- `p2-compat`: the ticket contains a note on keeping the Phase 1 design compatible with Phase 2

