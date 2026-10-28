# Decisions

Running log of architectural and scope decisions. Newest at the bottom. Future sessions: read this
before changing anything structural, and add an entry when you make a choice a later session would
otherwise have to rediscover or might undo.

Format:

```
## D-NNN · Title
Date · Status (accepted / superseded by D-NNN) · Tickets
Decision. Why. Consequences.
```

Entries D-001 to D-020 record decisions made while planning (feature reviews and ticket writing,
October 2026) before any code existed.

---

## D-001 · Django instead of Flask
2026-10 · accepted · T003
The outline's first version assumed Flask. The backend is Django 5.2 LTS with GeoDjango and DRF:
the admin replaces a separate admin UI, and 5.2 is supported until April 2028.

## D-002 · Two roles via Django groups
2026-10 · accepted · T013, T014
`researcher` (app only, `is_staff = False`) and `admin` (app + Django admin, all projects). No role
field on the user and no custom permission framework. The outline's coordinator and validator roles
are folded into `admin`. Admins create projects and add members.

## D-003 · Admin-only operations live in Django admin
2026-10 · accepted · T028, T043, T057, T064
Validation, conflict resolution, visit lock/unlock and export are done in Django admin. The outline's
validation, conflict-resolution and lock API endpoints are dropped; the app only shows its own
conflicts. The API still rejects edits to a locked visit (T042).

## D-004 · Schemas: `public` for Django, `geo` for views only
2026-10 · accepted · T004, T067
One database `butterfly`. Django uses `public`; history tables sit next to their models. Schema `geo`
holds views created by migrations, readable by `pygeoapi_ro` only. The outline's `app`, `audit`,
`sensorthings` schemas are not used; `mobility` only if T087 needs it. FROST gets its own database
`frost`. Views must not set `security_invoker`.

## D-005 · Sync cursor from a trigger-assigned `server_version`
2026-10 · accepted · T005, T025
A global sequence assigned by a `BEFORE INSERT OR UPDATE` trigger, with a transaction advisory lock
so versions commit in order. Catches every write path including `QuerySet.update()`. Serialises
writers, which is fine at thesis scale and is a documented limitation.

## D-006 · Client-generated UUIDs, soft deletes
2026-10 · accepted · T005, T026
The phone generates UUID v4 keys and the server never re-keys. Synced rows are soft-deleted
(`deleted_at`) so deletions propagate on pull.

## D-007 · No blind last-write-wins
2026-10 · accepted · T027, T028
Conflicting edits are detected per field; unresolved ones become `SyncConflict` rows resolved by an
admin (outline §12.4).

## D-008 · Enums as `TextChoices` + CHECK constraint
2026-10 · accepted · all model tickets
Not native PostgreSQL `ENUM`: `makemigrations` regenerates CHECK constraints, while enum changes need
hand-written migrations.

## D-009 · Audit with django-simple-history
2026-10 · accepted · T018
Over django-auditlog: full row snapshots, built-in change reason (needed for lock/unlock and
validation), admin history views. Revert is disabled because it would bypass sync versioning. Bulk
`update()` on audited models is not allowed. `survey_track_point` is not audited.

## D-010 · pygeoapi read-only and admin-only
2026-10 · accepted · T068, T069
No OGC transactions (F42 removed): writes would bypass validation, audit, locking and sync. Access
through nginx `auth_request` to Django, accepting a Bearer JWT or HTTP Basic (for QGIS, R, Python).

## D-011 · nginx, not Traefik
2026-10 · accepted · T002
Static routing (four paths) and a built-in `auth_request` module; Traefik's discovery adds nothing.

## D-012 · Laptop hosting, reached over Tailscale
2026-10 · accepted · T002, T009
No VPS or CD. The phone reaches the laptop through `tailscale serve` (real TLS certificate) or USB
with `adb reverse`. The dev flavour allows cleartext to `localhost` only.

## D-013 · Photos go through Django
2026-10 · accepted · T049, T050
No presigned MinIO URLs: they are signed for one hostname, which breaks when the phone sees the laptop
under a different address. The last official MinIO image is pinned; any S3-compatible store can
replace it via django-storages settings.

## D-014 · No Celery or worker service
2026-10 · accepted · T003
Exports and thumbnails run synchronously at thesis data volumes.

## D-015 · Android only
2026-10 · accepted · T006, T037
Background GPS is an Android foreground service. No iOS work.

## D-016 · Database image includes MobilityDB from day one
2026-10 · accepted · T002, T088
`mobilitydb/mobilitydb:17-3.5-1.3` behaves as plain PostGIS until Phase 2 runs
`CREATE EXTENSION mobilitydb`, so no image swap or data migration later.

## D-017 · MobilityDB is the Phase 2 target
2026-10 · accepted · T087, T088
It lines up with the AIST `pygeoapi-mf-api` fork. T087 is a research and design spike; plain PostGIS
and MF-shaped DRF endpoints are the fallback.

## D-018 · Simulated data instead of real sensors and a live pilot
2026-10 · accepted · T071, T079
No real microclimate stations; a simulator feeds FROST in Phase 2. The field season is over, so
Phase 1 evaluation runs on simulated field days plus one session with a biologist.

## D-019 · February covers Phase 1 only
2026-10-14 · accepted · roadmap #2
Part 2 has a later deadline. Measure pace after Stage 2a; above r = 0.56 apply cut line A.

## D-020 · Ticket status lives in docs/TICKETS.md
2026-10-14 · accepted · repo setup
The GitHub CLI is not used, so Claude Code cannot read or edit issues. The full ticket text is in
`docs/TICKET_DETAILS.md` (same as the issues) and the status is tracked in `docs/TICKETS.md`, which
`/next-ticket` and `/finish-ticket` update. A ticket's final commit carries `Closes #<issue>`, so
GitHub closes the issue when the commit is pushed to `main`.

## D-021 · No automated tests and no CI for now
2026-10-14 · accepted · all tickets, T008
The goal is a development build demonstrated to the supervisor. Acceptance criteria that only ask
for automated tests or CI are skipped, T008 (CI) is dropped, and each ticket is checked by running it
by hand. Tests and CI can be added later on request.

## D-022 · Backend commands run in the django container; pip + requirements.txt
2026-10-14 · accepted · T002, T003
The dev compose file mounts the source, so `manage.py` and ruff run through
`docker compose exec django`, and the laptop needs no Python setup beyond Docker. Dependencies are
pinned in `backend/requirements.txt` and installed in the image (no uv/poetry).

## D-023 · Formatting
2026-10-14 · accepted · T003, T006
Python: `ruff format` + `ruff check`, line length 100, in `backend/pyproject.toml`. Dart: `dart format`
defaults with `flutter_lints`. Android package id `rs.amilojkovic.butterfly`.

## D-025 · MinIO image: Chainguard build, pinned by digest
2026-10-14 · accepted · T002
The official MinIO images (Docker Hub `minio/minio`, `quay.io/minio/minio`) can no longer be pulled, so
the last-official-image pin in the T002 ticket is impossible. The stack uses
`cgr.dev/chainguard/minio` (MinIO RELEASE.2026-09-22T19-25-18Z), pinned by digest because the free
tier only offers `latest`. Django talks plain S3 through django-storages, so a later swap
(Garage, SeaweedFS) is a settings change. The image has no `mc` or `curl`; its health check uses bash.

## D-026 · accounts.User created in T003
2026-10-14 · accepted · T003, T011
`AUTH_USER_MODEL = "accounts.User"` must point at an existing model before the first migration, so T003
creates the minimal User (code from T011) with `accounts/0001_initial`. T011 only adds the JWT endpoints,
groups, throttling and `token_blacklist`. In development Django reaches MinIO with the MinIO root user
until a service account exists (T049).

## D-027 · Django apps live in backend/apps/
2026-10-14 · accepted · T003
The 13 apps are packages under `backend/apps/` (`INSTALLED_APPS` uses `apps.<name>`) instead of sitting in
the root of `backend/`. App labels stay `<name>`, so `accounts.User`, table names and migration
dependencies are unchanged. Models stay in each app (`models.py`, or `models/` once an app grows).

## D-028 · App server URL in shared_preferences; Riverpod 3 and provider wiring
2026-10-15 · accepted · T006
The server URL is one string, so it lives in `shared_preferences` (key `server_url`), not in a Drift
table. `main()` awaits `SharedPreferences.getInstance()` and overrides `sharedPreferencesProvider`, so
reads are synchronous. `ServerUrlNotifier` (Riverpod 3 `Notifier`) trims, strips trailing slashes,
accepts only http(s) URLs with a host and rejects the `<laptop>` placeholder. `dioProvider` watches
`serverUrlProvider`, so saving a new URL rebuilds the client. "Test connection" calls
`<typed url>/api/v1/health/` with a full URL, so it works before saving. `AppDatabase` is public
(Dart privacy is per file); writes to synced tables go through repositories, not widgets.
Codegen: `dart run build_runner build` (the `--delete-conflicting-outputs` flag was removed).

## D-029 · Sync trigger, advisory lock and hard-delete guard
2026-10-15 · accepted · T005
`core/0002_sync_version` creates `sync_version_seq` and `bump_server_version()`; each synced table
adds `AttachSyncTrigger(table)` (`apps.core.migration_ops`) after its `CreateModel`. The trigger takes
`pg_advisory_xact_lock(727274)`, so all writes to synced tables are serialised until commit and
versions commit in order (verified with two connections: the second writer blocks until the first
commits). This does not scale to many concurrent writers; fine for a thesis-sized deployment.
`server_version` on a Python instance is stale after `save()`: use
`refresh_from_db(fields=["server_version"])`. `bulk_create()` fires the trigger but returned objects
carry no version. Hard delete is blocked: `SyncableModel.delete()` and `SyncableQuerySet.delete()`
raise `NotImplementedError`, and admin classes extend `core.admin.SyncableAdmin` (no delete
permission, no bulk delete action). Use `soft_delete()`.

## D-030 · Forwarded host and scheme through nginx
2026-10-15 · accepted · T009
Tailscale serve terminates HTTPS and sends the `ts.net` name; nginx passes `X-Forwarded-Proto` and
`X-Forwarded-Host` (each falling back to `$scheme` / `$http_host` when absent, so plain
`localhost:8080` and USB still work), and Django sets `USE_X_FORWARDED_HOST = True` next to
`SECURE_PROXY_SSL_HEADER`. `ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS` come from `.env`. The cleartext
exception for `localhost` lives only in the Android debug source set (`src/debug`), since the project
has no product flavours. Setup steps: `docs/setup/tailscale.md`.

## D-031 · Backup and restore scripts
2026-10-15 · accepted · T010
`scripts/backup.sh <dir>` writes `butterfly-<UTC>/` with `butterfly.dump` (`pg_dump -Fc`, plus
`frost.dump` once that database exists), `photos/` and `manifest.json`, and keeps the newest 7
`butterfly-*` folders. `scripts/restore.sh <dir>` runs `down -v`, starts `db` and `minio`, runs
`pg_restore --create --clean` as the superuser (this recreates the database with its owner and grants;
the roles already exist from `db-init`), mirrors the photos back and starts the stack. `mc` comes from
`cgr.dev/chainguard/minio-client`, pinned by digest, because `minio/mc` can no longer be pulled (same
reason as D-025). That image has no shell, so each `mc` command is its own `docker run`. Encryption uses
`gpg` (not `age`): `BACKUP_ENCRYPTION_KEY` in `.env` is a gpg recipient; the dump becomes
`*.dump.gpg` and the photos one `photos.tar.gpg`; restore decrypts with the private key in the keyring.

## D-032 · Login throttling uses a per-process cache
Five failed logins per lowercased email within 15 minutes return 429 (`apps/accounts/services.py`). The
counter lives in Django's cache, set explicitly to `LocMemCache`, so it is per process: exact with the
single dev `runserver` worker, up to 5 × workers if the server ever runs several. A shared cache
(database or Redis) is not worth a new table or service for a solo laptop deployment. A successful login
clears the counter, and a locked email gets 429 even with the right password. `/auth/me` returns
`project_ids: []` until Project exists (T015), and `groups` is empty until T013 creates the groups.

## D-033 · Users are created by admins; no self-registration
There is no sign-up endpoint. Admins create accounts (Django admin once T014/T015 exist; `createsuperuser`
or the shell before that), choose the group and add the user to projects. Passwords are reset by an admin
(no mail server). If registration is wanted later, add request-and-approve: a public endpoint creates a
user with `is_active=False` and an unusable password, an admin activates it and sets the password. That
needs no model or migration change (`is_active`, `name` and `organization` exist). Open sign-up is not
planned: a new account would have no group or project anyway.

## D-034 · Role groups: created by migration, permissions granted in post_migrate
2026-10 · accepted · T013
Migration `accounts.0003_groups` creates `researcher` and `admin`. Django creates permission rows only
after all migrations, so `sync_admin_group_permissions()` (accounts/services.py) runs from `post_migrate`
and gives `admin` every permission of the `apps.*` models; new models are picked up on the next `migrate`.
`is_staff` follows `admin` membership through `m2m_changed` (superusers keep `is_staff`). Admins may edit
any record (`IsOwnerOrAdmin`). `IsProjectMember` admits only admins until `ProjectMembership` exists
(T015, marked TODO there). `GET /api/v1/auth/admin-check` is a small admin-only endpoint that shows the
403 for researchers until the export and pygeoapi endpoints exist.

## D-035 · Branded AdminSite through an AdminConfig, ordered by app label
2026-10 · accepted · T014
`apps.core.admin_config.CoreAdminConfig` (a `django.contrib.admin` `AdminConfig` with `default_site`) replaces
`django.contrib.admin` in `INSTALLED_APPS`, so `@admin.register` keeps working and the site is
`ButterflyAdminSite`. It must live in its own module: importing `AdminConfig` into `core/apps.py` makes Django
see two default configs. `apps.core` is listed first so its `admin/base_site.html` wins over the stock one.
The VERIFY is settled: section order is a sort on `app["app_label"]` in `get_app_list` (`APP_ORDER` in
`admin_site.py`; unlisted apps go last). Only the labels in that list are placed, so a new app needs adding there.
`SyncableAdmin` and `MapAdmin` are plain bases: use `class XAdmin(SimpleHistoryAdmin, SyncableAdmin)` (T018).
"Soft delete selected" saves row by row (no `QuerySet.update()`), so the trigger and history both fire.

## D-036 · Project scope lives in `projects_for(user)`; membership removal keeps local data
2026-10 · accepted · T015
`apps/projects/services.py` has `projects_for(user)` (admins: all live projects; others: projects they are a
member of) and `is_member()`. The projects API, `/auth/me` `project_ids` and `IsProjectMember` use them, and
the pull (T025) must too. A non-member gets 404 on `/projects/{id}`. `ProjectMembership` is not synced (bigint
PK, no trigger): removing one simply stops the project from appearing in the user's next pull. Nothing tells
the phone to delete it, so rows already downloaded stay on the device (documented behaviour, not a bug).
`transect_count` is annotated as a constant 0 until `Transect` exists (T021). `accounts.User` got a minimal
admin (T015) because the membership inline uses user autocomplete; admins create accounts there (D-033).

## D-037 · Admin restore action, field-level date error, theme CSS selectors
2026-10 · accepted · T015
`SyncableAdmin` has "Restore selected" (clears `deleted_at` row by row, so the trigger bumps `server_version`
and phones pull the row again) next to "Soft delete selected". `Project.clean()` raises the date error on
`end_date`; a bare `CheckConstraint` only gives a form-level message. Admin colours (`core/admin.css`) use the
same selectors as Django (`html[data-theme="light"], :root`, `html[data-theme="dark"]`, and a
`prefers-color-scheme: dark` block for Auto), otherwise Django's blue wins. Admin forms for synced models list
fields explicitly (see `ProjectAdmin`), because inherited sync fields otherwise come first.

## D-038 · Protocol row created by signal, study area imported through GDAL
2026-10 · accepted · T016
Every `Project` gets a `ProjectProtocol` from a `post_save` receiver (`projects/signals.py`, calling
`services.create_default_protocol`); the season has no model default, so it is 1 Apr – 30 Sep of the project's
start year. Migration `projects/0002` creates protocols for projects that already existed. Because of the signal
the protocol inline is hidden on the add form (the row does not exist yet) and shown when editing, without add or
delete. `Project.area` is edited in the admin map widget (`ProjectAdmin` also extends `MapAdmin`, centred on the
area) or replaced by the "Import study area" action, which reads GeoJSON or KML with GeoDjango's GDAL
`DataSource` (no new dependency), reprojects to 4326, drops Z and merges all polygons. The projects API returns
`area` (GeoJSON geometry) and a nested read-only `protocol`; the pull (T025) reuses that serializer. Deferred:
the app's protocol summary (T033) and the "threshold change changes the flags" check (T056).
Also in T016: field explanations are `help_texts` dicts in the admin (`HelpTextMixin`), not model `help_text`, so
wording changes need no migration. `MapAdmin` opens on Serbia (lon 20.8, lat 44.0, zoom 7) and zooms to 13 when
the object has an area. `SECURE_REFERRER_POLICY = "strict-origin-when-cross-origin"` is needed because Django's
default (`same-origin`) sends no Referer and tile.openstreetmap.org then answers 403 "Access blocked" to the admin
map. The projects routes have no trailing slash (`/api/v1/projects`).

## D-039 · Server time zone is UTC
2026-10 · accepted
`TIME_ZONE = "UTC"` (it was Europe/Belgrade), so API timestamps end in `Z` and the admin shows UTC, as CONVENTIONS 8 says. Stored data is unchanged (`timestamptz` holds the instant). Follow-ups are notes under T026 (reject offset-less datetimes in push input) and T029 (the app sends UTC).

## D-040 · Audit log details: no revert, fresh `server_version`, reasons through a helper
2026-10 · accepted · T018
Admin classes for audited models extend `core.admin.HistoryAdmin` (a `SimpleHistoryAdmin`) first:
`class XAdmin(HistoryAdmin, SyncableAdmin)`. `SIMPLE_HISTORY_REVERT_DISABLED = True` only hides the Revert button and
makes the version page read-only, so `HistoryAdmin.history_form_view` also refuses POST with 403. A
`pre_create_historical_record` receiver (`core/history.py`) reads `server_version` from the database before the
history row is saved: simple-history writes history in `post_save`, after the BEFORE trigger (T005) has set the new
version, so the history row matches the live row while the instance still holds the old value (T027 looks up past
states by `(id, server_version)`). History rows from before T018 keep their stale versions. Changes that need a
reason go through `core.history.save_with_reason(obj, user, reason)`, which sets `_change_reason`, `_history_user`
(so it works outside a request) and `updated_by`. `SIMPLE_HISTORY_HISTORY_CHANGE_REASON_USE_TEXT_FIELD = True` makes
`history_change_reason` a text column (migration `projects/0003`; later model tickets get it automatically).
VERIFY result (3.13.0): with JWT auth, `HistoryRequestMiddleware` keeps the Django request, and DRF writes the
authenticated user back onto it (`Request.user` setter), so `history_user` is set for API writes. This was checked with a
throwaway DRF view, since no project API writes yet. `diff_against` leaves out non-editable fields (`server_version`,
`updated_at`). Not audited: `User`, whose `is_staff` sync uses `QuerySet.update()`.
Admin change reason (added in T018 at the user's request): on edit, Save in a `HistoryAdmin` change form opens a
dialog (`admin/core/history_change_form.html`, `core/change_reason.js`) asking for an **optional** reason, posted as
`_change_reason`. `HistoryAdmin.save_model` puts it on the object, and `save_related` puts it on every inline instance
(it uses `save_related`, not `save_formset`, because `ProjectAdmin.save_formset` does not call `super()`). Add forms and
admin actions (soft delete, restore, area import) do not ask. Mandatory reasons stay with T043 and T057.

## D-041 · Editable map widget: one feature per part, Shift + click removes a vertex
2026-10 · accepted · T098
`apps.core.widgets.EditableMapWidget` (subclass of Django's `OSMWidget`; template `core/widgets/editable_map.html`, a
copy of Django's map template; `core/editable_map.js` extends Django's `MapWidget`) splits a Multi* value into one
feature per part and joins them back on save; an empty map saves NULL. It is set on `ProjectAdmin` only
(`gis_widget`); T022 can use it for transects and sections (template blocks `delete_selected_label` and `help` reword it,
`attrs["help_note"]` adds a line to the help). No mode switch: a click on empty map starts a part, a click on an existing
part selects it (so a part cannot start inside another), and Modify works on all parts without selecting first. The
Delete key removes the selected part unless focus is in a form field. The widget's `Media` lists `gis/js/OLMapWidget.js`
before its own script, or Django's media merge loads ours first.
VERIFY result (OpenLayers 7.2.2): Django's Shift + click vertex delete added a vertex, because Modify inserts a vertex on
pointer-down on an edge (`insertVertexCondition` defaults to `always`) and then ignores the next click. Setting
`insertVertexCondition` to "not Shift" makes Shift + click remove a vertex; checked by hand in the browser. Shift + drag
is still freehand drawing.

## D-042 · App projects live in a Drift table, refreshed from the projects API until the pull exists
2026-10-19 · accepted · T017
The app keeps projects in a Drift `project` table (schema v3), so the project list and project home work offline. It is a
read-only reference table: the columns match the server (`area` is GeoJSON text), with `serverVersion` and `deletedAt`
but no `syncStatus`. Until the pull (T025/T030) exists, `ProjectRepository.refreshFromServer()` upserts the rows from
`GET /api/v1/projects`; it runs quietly when the list opens and on pull-to-refresh. T030/T031 replace it with the pull and
can drop the method. Projects the server stops returning stay on the phone (D-036). The protocol is not stored yet (T033).
The last opened project id is in `shared_preferences` (`last_project_id`). After login or app start the router goes to
`/projects/<id>` (nested under `/`, so back leads to the list); "Remove data" clears it. The per-project numbers are
placeholder `FutureProvider.family`s in `project_stats.dart` for T030/T031 to fill in. `dart run drift_dev
make-migrations` also generates `test/drift/.../migration_test.dart`; it is deleted (D-021).

## D-043 · Taxon renames add a row; new projects default to the current list release
2026-10-19 · accepted · T019
A taxon's `scientific_name` is read-only in the admin after creation. A rename or synonymisation goes through
`catalogues.services.retire_and_replace_taxon` (admin action "Rename / synonymise…" on the taxon list): it adds a new
`Taxon` row introduced in the chosen `TaxonListVersion`, copies the other fields, and sets `retired_in` and
`accepted_name` on the old row (saved with a history reason). Observations keep pointing at the old row.
`make_current` / `clear_other_current` move `is_current` between releases (the admin does the same when a release is saved
as current), because the partial unique index allows only one current row at a time. `Project.taxon_list_version` is
nullable and filled by a `pre_save` signal on create (like the protocol signal, D-038) with the current release, or left
empty when there is none; existing projects are not backfilled. `taxa_for(user)` is the scope the pull (T025) must use: for
now every live taxon with `retired_in IS NULL`; T044 adds the retired taxa the user's own observations reference.

## D-044 · Plant taxa and codelists are pulled with their inactive rows
2026-10-19 · accepted · T020
`PlantTaxon`, `HabitatType` and `ManagementType` are synced, audited models. `active = false` is the only way to
retire a value: the row stays, keeps its history and is still pulled, so records that use it keep showing it; pickers
filter on `active`. `catalogues.services.plant_taxa_for`, `habitat_types_for` and `management_types_for` are the scopes
the pull (T025) must use. They return every live row, inactive ones included, which is wider than the ticket's
"inactive rows referenced by the user's records": the lists are small and the narrowing would need the T021, T051 and
T053 foreign keys. Revisit it only if the package size matters. `Codelist` is abstract, so each codelist is its own table.

## D-045 · Transect sections must lie inside a 5 m buffer; geodesic length via `::geography`
2026-10-19 · accepted · T021
`TransectSection.clean()` calls `transects.services.section_lies_along`, which requires
`ST_Covers(ST_Buffer(transect::geography, 5)::geometry, section)`. The ticket named `ST_DWithin`, but that only tests the
closest point, so a section that touches the line once and then runs off would pass. The check uses the transect instance
in memory, so T022's inline editor also checks against an edited, unsaved line. `clean()` also raises the
`section_seq_positive` rule on `sequence_number` (as D-037 did for project dates). Lengths are
`ST_Length(geometry::geography)` (`services.GeodesicLength`), in metres. Django 5.2's own `Length()` on a 4326 geometry gives
the same value, but it returns a `Distance` object. `transects_for(user)` (live transects of `projects_for(user)`, inactive
ones included) and `sections_for(user)` are the scopes the pull (T025) must use; `Project.transect_count` counts live
transects. `visit_count` and `last_visit_at` are fixed placeholders and `/transects/{id}/visits` does not exist until T034.
Geometry is returned as GeoJSON geometry objects, like `Project.area`.
The admin draws both lines with `core.widgets.LineMapWidget`, the D-041 widget with line wording (template
`core/widgets/line_map.html` overrides the `help` and `delete_selected_label` blocks). An admin found that a line keeps
growing with every click; its "?" popup says a line ends with a double-click and that a field holds one line.
`EditableMapWidget.setReference(geojson)` draws a read-only geometry (4326 GeoJSON) under the editable features, fits
the view to it, and adds an `ol.interaction.Snap` on it; the widget instance is on its wrapper element as `editableMap`.
The section form uses it (`transects/section_map.js`): picking a transect fetches its line from the admin URL
`transect-line/<id>/` (transect field's `data-line-url`) and shows it dashed. T022's section inline can reuse the same call.

## D-046 · Transect editor: sections cut in UTM, partial unique constraints, shared GIS file reader
2026-10-19 · accepted · T022
`TransectAdmin` has a collapsed `TransectSectionInline` (small `LineMapWidget` per row and a "Remove" tick box per
row), an **Import line** page (`<id>/import-line/`, button beside History) and the list action
**Generate N equal sections…**. `transects.services.split_line` cuts the line into N pieces with `ST_LineSubstring` in the
line's UTM zone (`utm_srid`: `32600/32700 + zone` from the centroid) and transforms each piece back to 4326, so the pieces
are equal in metres. The ticket's planar version is off at 44 °N (a degree of longitude is about 72 % of a degree of
latitude): an L-shaped line cut in two gave about 57 % / 43 %. Checked by hand: an L of 1 999 m gave 2 × 999.4 m and
4 × 499.7 m, neighbours share their end point, and every piece passes the 5 m rule of D-045. Section codes are
`<prefix><number>`, at most 200 sections. "Replace" soft-deletes the live sections first.
`section_seq_unique` and `section_code_unique` are now **partial unique indexes** (`WHERE deleted_at IS NULL`, migration
`transects/0002`), a change from T021's plain `UNIQUE`: a soft-deleted section no longer blocks its code or number, which
"replace" and "soft delete, then add the same code" both need. `Transect (project, code)` is unchanged. Consequences: the
phone may hold a soft-deleted and a live section with the same code, so T033 must ignore rows with `deleted_at` set (the
Drift tables have no unique constraint on them), and `SyncableAdmin.restore_selected` now skips a row whose index slot a
live row has taken and names it in an error message instead of failing.
The line import takes GPX, KML or GeoJSON and uses the first LineString, or the first line of the first MultiLineString
(a GPX track); points are ignored. GDAL names lines with elevation `LineString25D`, so the type check strips that suffix.
`apps/core/geo_files.open_datasource(uploaded, suffixes, error)` holds the shared part (suffix check, temp file, GDAL
errors) and `projects.services.multipolygon_from_file` uses it too. The "sections add up to the transect" warning
(over 2 %, geodesic lengths) is a message on the GET of the change form. Imported lines and generated sections get a
history reason (`save_with_reason`). The inline has "Add another". Django's map widget does not support it: the widget template's `<script>` is cloned with the
new row and never runs. So `editable_map.html` repeats the options as `data-` attributes and skips the script for the empty
form (its id holds `__prefix__`, so `clone()` copies a plain `<div>`); `EditableMapWidget.initIn(root)` builds the widget for
a row from them; `transect_inline_maps.js` calls it on Django's `formset:added` event and sets the dashed transect line on the
new map. Checked in headless Chromium (chromedriver and the WebDriver API): on a saved transect and on the add page, a section
added this way, with its line drawn on its map, was saved. Inline validation uses the edited, unsaved transect line also for new rows.
`SectionFormSet.clean` rejects a section code or number used twice among the kept rows (rows ticked "Remove" are skipped): the
partial unique indexes are not checked by Django's form validation, so a clash would have been an `IntegrityError` (500). The
Delete key is one document-level listener for all maps, not one per widget, and `initIn` points the help button's
`aria-describedby` at the renumbered id of the help text (Django's `inlines.js` renumbers only `id`, `name` and `for`).
Each section map in the inline shows the whole transect as the dashed reference line (`transects/transect_inline_maps.js`).
The line is read from the transect's own map, so it follows edits made on the page before saving (add, remove and
`modifyend` on that map redraw it without changing the views). The section lines are drawn solid, 4 px wide like the
reference, in crimson `#c2255c` on top of it: `EditableMapWidget` styles its features with `attrs["feature_color"]`, which the
transects admin sets on the section widgets (inline and section page) only.
The "?" popup was cut off under the small inline maps because Django's `.form-row { overflow: hidden }` clips it at the row.
`editable_map.css` sets `.form-row:has(.editable_map)` to `overflow: visible; display: flow-root` (flow-root still contains
the floated map), and `section_inline.css` widens the popup to 32em there. Not checked in a browser. The Sections group is one closed `<details>`, so its maps are
laid out at zero size: `EditableMapWidget.fitReference()` does nothing until the map has a size, and the script calls it
when the group opens. `setReference(geojson, fit = true)` gained the `fit` flag for the live redraw.

Removing a section from the inline: the "Remove" box is Django's formset delete box with a new label. `TransectAdmin.save_formset`
calls `soft_delete` on `formset.deleted_objects` (saved with `commit=False`, so nothing is erased) before it saves the other rows,
so a code or number freed by a removed row can be reused in the same save. The history row carries the change reason from the
dialog. The other sections keep their numbers (no renumbering). "Restore selected" on the Transect sections list undoes it.
Django's inline delete check (`DeleteProtectedModelForm`) refuses a removal when a protected foreign key points at the row: when
a later ticket adds `on_delete=PROTECT` references to `TransectSection`, a section with records will not be removable here,
although a soft delete would be safe; revisit then.

## D-047 · Seed data: GBIF families instead of the superfamily, files in `database/seeds` mounted as `/seeds`
2026-10-19 · accepted · T024
`/v1/species/match?name=Papilionoidea&rank=superfamily` answers "no match": the GBIF backbone has no superfamily node. VERIFY
result: `import_gbif_butterflies` resolves the six families (Hesperiidae, Lycaenidae, Nymphalidae, Papilionidae, Pieridae,
Riodinidae; `/species/match` with `kingdom=Animalia`, `rank=family`), which together are Papilionoidea in the modern sense,
and merges their `facet=speciesKey` counts. Run on 2026-10-19: 206 species keys with records in Serbia, 198 imported, 8 listed
for manual review (fewer than 3 records). 4 of the imported ones have backbone status `DOUBTFUL` (for example *Lasiommata
megera*): real species that the backbone's source checklists do not cover, so they are imported with a note in
`identification_notes`; names with another status (synonyms) are listed, not imported. The expected 150–200 was right.
Re-running creates nothing. Existing rows are never updated (admins may have edited them: `photo_required`, notes, names).
`seed_plants` names are matched with `rank=species` or `rank=genus` (`spp.`) and `kingdom=Plantae`; only an `EXACT` match at that
rank is accepted, and a miss is saved as `manual`. The backbone uses *Chamaenerion angustifolium*, so `plants.csv` does too.
The commands live next to what they fill (`catalogues`, `projects`), `core/gbif.py` is the shared client (`requests`, approved for
this ticket and pinned in `requirements.txt`; 3 requests per second; every response cached as JSON). The django container only
mounts `./backend`, so `compose.dev.yaml` mounts `./database/seeds` as `/seeds` and `SEEDS_DIR` points there. `seed_demo` links
the project to the `2026.1 (GBIF RS)` release when it exists, not to whichever release is current, because a development database
can hold test releases. The demo transects are drawn illustrations near Fruška Gora (not surveyed); sections are cut with
`transects.services.generate_sections` and then given habitat and management types. The demo emails (`admin@demo`) have no
top-level domain: login, the admin and `/auth/me` all accept them (checked by hand).
Review fixes (same ticket): `import_gbif_butterflies` writes the release and its taxa in one transaction, `seed_plants` asks GBIF
first and writes in a short transaction afterwards, and cache files are written to a `.tmp` file and renamed. `seed_demo` only runs
with `DEBUG` on, adds groups only to users it creates, re-links an existing demo project to the GBIF list, and skips a soft-deleted
transect (its `(project, code)` constraint covers deleted rows). No retry or backoff on GBIF errors: the cache keeps what was
fetched, so running the command again continues where it stopped.

## D-048 · Catalogue CSV import/export and release publishing
2026-10 · accepted · T023
`django-import-export` 4.4.1 (approved for this ticket; pulls `tablib` and `diff-match-patch`, which are not pinned). VERIFY
result: it works with Django 5.2.18, and the admin passes `user=request.user` to `import_data`, so `before_save_instance` gets
it in `kwargs["user"]` and sets `created_by`, `updated_by`, the history user and the reason "CSV import". CSV is the only
format. Import needs both the `add` and the `change` permission (`CatalogueAdminMixin.has_import_permission`, since import
creates and updates rows and the library's setting takes one code only); export needs `view`
(`IMPORT_EXPORT_EXPORT_PERMISSION_CODE`).
Rows match on natural keys, so the CSV has no UUIDs and no sync columns: taxa on `(scientific_name, rank, introduced_in)`
(the `taxon_unique_name` constraint), plants on `scientific_name`, codelists on `code`; `introduced_in` is a release label. Rows
are saved one by one (`use_bulk = False`) so the sync trigger and history fire, and `clean_model_instances` turns a bad `rank`,
`taxon_source` or slug into a row error. Boolean columns use `StrictBooleanWidget` (1/0/true/false/empty): the library default
reads any other value, such as `yes`, as `False` without an error. `retired_in` and `accepted_name` are exported but read-only on import: retiring and
renaming go only through the admin actions, so a CSV can never rename or retire a taxon (T019 rule: a changed key is a new row).
Known limit: the natural keys are unique across soft-deleted rows too, so importing a row whose key matches a soft-deleted row
updates it but leaves it deleted. An unknown `introduced_in` label shows as a "matching query does not exist" row error.
Publishing a release is a button on the taxon list version changelist (`publish/` view), not a list action, because it creates
the release. `services.publish_list_version` creates it, makes it current and switches only the ticked projects (each saved with
the reason "Switched to taxon list …"); unticked projects stay where they are. The label is checked on the form because it is
unique including deleted rows.
"Synonymise into existing…" is a second action beside T019's "Rename / synonymise…", which is unchanged and still creates the
accepted name. The new one (`services.synonymise_taxon`) only links one or more selected taxa to an existing accepted taxon,
retiring them in the chosen release (default: the current one); all selected taxa are saved in one transaction, so one error
saves nothing. A taxon that is still the accepted name of other live taxa cannot be synonymised, so chains A → B → C never
form; change those taxa's accepted name first.
`list_editable` is on for the four admins, but soft-deleted rows are shown read-only in the changelist form.

## D-049 · Pull: one snapshot per page, scopes with tombstones, sync registry
2026-10 · accepted · T025
`POST /api/v1/sync/pull {project_id, cursor, limit}` (limit default 1000, max 5000) returns
`{changes: {<entity_type>: [...]}, next_cursor, has_more, server_time}`. Every entity type has a key, with an empty list when
nothing changed. `sync.services.pull` runs in one transaction that starts with
`SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY`: the page is built from one query per entity, and under READ
COMMITTED each would see its own snapshot, so a row committed in between could appear while an earlier type missed a lower
version that committed at the same time, and `next_cursor` would jump past it. With one snapshot and versions committing in
order (T005 advisory lock, D-029) every page is a prefix of the commit order. The boundary comes from a first pass over the
versions alone (`limit + 1` per entity, pooled and sorted; versions are unique because they come from one sequence), then the
rows up to `next_cursor` are fetched per entity. Checked by hand with a smoke script (paging, tombstones, interleaved
writes) and an uncommitted write on a second database connection while pulling: the row stayed out of the page and
`next_cursor` stayed below its version until it committed (D-021, no automated test). `pull` uses
`transaction.atomic(durable=True)`, so calling it inside an outer transaction fails loudly.
`apps/sync/registry.ENTITIES` is the one list of synced entity types: `(entity_type, serializer, pull_scope)`. T026 adds the
push handlers to it, and T027, T034, T036, T044 and T049 add the user-data types (scoped to `created_by = user`).
The `*SyncSerializer` classes (`projects`, `catalogues`, `transects`) describe the row as stored, with the column names of
the phone, minus `created_by`, `updated_by` and the project `owner`. Pull and push share them, and the OpenAPI schema shows
each type as `oneOf` record or tombstone. They are not the REST serializers, which nest and annotate for the screens.
Geometry goes out as GeoJSON through `core.serializers.GeoJSONField` (read-only, moved from `transects`); there is no
djangorestframework-gis.
The `pull_*` scopes (`projects`, `catalogues`, `transects` services) take `(user, project)` and return every row in scope,
**soft-deleted ones included**; the `*_for(user)` scopes stay live-only for the REST API. Deleted rows go out as
`{id, deleted_at, server_version}` tombstones, also at cursor 0 (the phone may hold the row from an earlier package).
**All taxa are pulled, retired ones included. This amends D-043**: retiring a taxon bumps its version, and under the
`retired_in IS NULL` rule it would leave the scope at that moment, so a phone would never learn it was retired. The app filters
retired and inactive rows in its pickers; T044 has nothing to add for taxa. All taxon list versions are pulled too, because
taxa point at them through `introduced_in` and `retired_in`. Plants and codelists keep D-044, plus tombstones.
A project the caller cannot see (non-member, unknown id, or soft-deleted) is a 404 (D-036). A deleted project therefore has no
tombstone in the pull; the phone drops projects that are no longer in the projects list. Sections of a soft-deleted
transect are still sent as live records, since deleting a transect does not delete its sections; the sync runner (T030) must
not treat them as orphans.
`cursor` is capped at 2^63 - 1 (the bigint range), so a larger value is a 400. `TransectSyncSerializer.length_m` uses the pull
annotation when it is there and otherwise asks the database (`transects.services.geodesic_length_m`), so push (T026) can
serialize a plain `Transect`. A 404 now has the body code `not_found` (it was `error`, because Django's `Http404` has no
`default_code`); this also applies to `/projects/{id}`.

## D-050 · Push: savepoints, idempotency, handler slot, stale-version stand-in
2026-10 · accepted · T026
`POST /api/v1/sync/push {device_id, mutations: [{mutation_id, entity_type, entity_id, operation, base_version, payload,
client_created_at}]}` returns `{results: [{mutation_id, status, server_version, errors}]}` in input order. `errors` is `[]`
unless the mutation is `rejected`, then one `{code, detail, fields}` item (`core.exceptions.error_body`, shared with the REST
handler). `server_version` is the row's new version after create/update/delete, the current one for a no-op, and null for
`create_batch` and for rejections. The response is **200 with a status per item**; a 400 is only for a bad envelope (no
`device_id`, `mutations` not a list, more than 1000). Items are validated one by one, so a malformed item (also a non-object) is rejected, not a
reason to fail the batch; its `mutation_id` is echoed only when it is a UUID. `client_created_at` needs a UTC offset (`core.serializers.UTCDateTimeField`); handlers must do the
same for datetimes in their payloads.
`services.push` is one `transaction.atomic(durable=True)` with a savepoint per mutation. Errors are caught outside the inner
`atomic()` (Django needs that to keep the outer transaction usable): DRF `APIException`, `Http404`, Django
`PermissionDenied` and `ValidationError`, `IntegrityError` (`integrity_error`) and `DataError` (`invalid_data`: a value too long
or out of range), so one bad value cannot poison the batch. **Any other exception propagates**, so the
whole batch rolls back with a 500 and the phone retries later; a bug shows in the logs and is not stored as a rejection.
A per-user advisory lock (`pg_advisory_xact_lock(727275, hashtext(user id))`, two-key form so it never meets the global lock
727274 of D-029) makes a retry of a still-running batch wait and then see `duplicate`, instead of applying everything twice.
`sync_mutation` stores `applied` and `rejected` (also `merged`/`conflict` for T027); `duplicate` exists only in responses.
A stored **applied** result comes back as `duplicate`; a stored **rejection comes back as `rejected`**, unchanged, because
`duplicate` reads as "already applied" (this narrows the ticket text). A rejected change is retried under a new `mutation_id`. Malformed items and a `mutation_id` that belongs to another user
(`mutation_id_taken`, never leaks the other result) are not stored. `prune_sync_mutations --older-than 180d` deletes old rows.
**Handler slot:** `SyncEntity.push: PushHandlers | None` (`apps/sync/handlers.py`, a leaf module that imports only `core`, so
app services can import it). The framework has checked the shape, deduplicated, removed server-owned fields, turned a create
of an existing id into an update, loaded the row `FOR UPDATE`, checked ownership (`created_by` or admin) and `base_version`.
`create_batch` gets none of the row checks (`entity_id` is the parent): the handler checks that the user may add rows to it.
The handler calls the entity's service function, which owns validation (T055), project membership, the visit lock (T042),
section assignment (T048) and quality flags (T056), and saves with `PUSH_REASON = "sync push"` (`save_pushed`,
`soft_delete_pushed`). **Every type registered today has `push=None`** and answers `read_only_entity`; T034, T036, T044 and
T049 register theirs. A missing callable is `operation_not_allowed`.
**Server-owned fields** dropped from every payload: `id server_version created_by updated_by updated_at deleted_at
quality_flags`, any `validation_*` or `locked_*`, and `SyncEntity.server_owned` (e.g. `distance_walked_m` for T036).
`created_at` is kept: the phone sets it for records created offline. In `create_batch` rows `id` is kept.
**`create_batch`:** `entity_id` is the parent record (the visit), `payload.rows` holds 1 to 1000 rows that carry their own
`id`; the handler uses `insert_batch` (`bulk_create(ignore_conflicts=True)`, `ON CONFLICT DO NOTHING`), which writes no history
and returns no `server_version` (right for track points, CONVENTIONS A.5.7).
**`stale_version` is the stand-in until T027:** an `update`/`delete` whose `base_version` differs from the row's
`server_version`, and a `create` of an existing id (null `base_version`), is rejected with `stale_version`. T027 replaces
it with merge or a `SyncConflict`. A `delete` of an already deleted row is `applied` and changes nothing; an `update` of a
deleted row is rejected `deleted`.
**Known gap for T027:** a `create` of an existing id is `stale_version` even when it is the phone's own resend, for example
after the stored mutation row was pruned (180 days) or when the phone re-queued the create under a new `mutation_id`. T027
should treat a create of the user's own existing row as an update against the current version, or a no-op.
Shown by hand with `tmp/t026/smoke.py` and temporary handlers (no type the phone writes exists yet; D-021): savepoints and
order, resending a batch, concurrent retry from two threads, 1000-row batches, ownership, history reason, server-owned
fields. 500 updates took about 3.3 s on the laptop; the real measurement is T074.

## D-051 · App sync queue: write helper, coalescing only unsent items, sync_state keys
2026-10 · accepted · T029
`SyncRepository.write` (`lib/core/sync/sync_repository.dart`) is the only code that changes a synced row. `entityType` is both
the server's entity type and the local Drift table name (`survey_visit`, ...), so the helper can mark a row with plain SQL
(`UPDATE "<entityType>" SET sync_status = ? WHERE id = ?`) without knowing the table class. The helper sets `sync_status =
pending` itself; the caller's `writeRow` only upserts the data. One Drift transaction, **queue item first**, then the row, so an
exception anywhere rolls back both. `SyncColumns` (mixin: `serverVersion`, `syncStatus`, `deletedAt`) exists but no table uses
it yet; T034 and later add it.
**Coalescing only into an unsent item**: the latest queue item of the entity (highest `seq`) is merged into only when it is
`queued` with `retryCount == 0`. Once an item has been sent, the server may already have applied its `mutation_id`; merging new
changes into it would make the server answer `duplicate` and the changes would be lost. Rules: update + update gives one update
(payload merged, first `baseVersion`, `mutationId` and `seq` kept); create + update gives one create; create + delete removes
the item and hard-deletes the local row, because the server never saw it (soft delete is for synced rows only). Anything else
inserts a new item. The old `seq` is kept so a visit's create still goes before the observations queued after it.
**T030 obligation:** the runner must raise `retryCount` or set `inFlight` before it sends an item.
**Track points** go through `writeBatch` as `create_batch` items with `entity_id` = the visit (D-050), at most 500 rows per item.
An unsent batch of the same parent is filled up to 500 first; the rest goes into new items.
**`sync_state` keys** (`SyncStateRepository`, table `sync_state`): `deviceId` (UUID v4), `cursor:<projectId>` (int as text; missing
means never pulled, cursor 0), `lastSuccessfulSyncAt` (UTC ISO-8601), `lastSyncBytes` (int as text). `deviceId` is created
lazily on the first read (in practice the first launch that syncs), inside a transaction so two callers cannot make two ids.
"Remove data" (`LocalDataRepository.clearAll`) deletes every table, so it also wipes the queue and `deviceId`; a new id is made
on the next read. `LastSyncNotifier` stays on shared_preferences for the login screen; T030 decides how it joins
`lastSuccessfulSyncAt`.
Schema is now v4 (`from3To4` creates `sync_queue`, `sync_state` and the index `sync_queue_entity` on `entity_type, entity_id, seq`,
which `_latestItem` uses on every write). Shown by a temporary smoke test (in-memory database,
throwaway tables, nine cases for coalescing, atomicity, batching and `sync_state`) and a v3 to v4 upgrade check with Drift's `SchemaVerifier`
(`tmp/t029/`); nothing committed (D-021).
`SyncRepository.unsyncedCount()` counts every item still in the queue (`queued`, `inFlight`, `conflict`, `rejected`), because
items leave the queue only when the server accepted them; T030 feeds it into the pending-changes badge.
**Open points found in review, for later tickets:**
- **T034/T035:** deleting a visit whose create was never sent drops only the visit's own queue item. Queued children
  (observations, `create_batch` track points) stay and would be pushed without a parent. Their repositories must cancel or
  delete them in the same transaction.
- **T034:** `write()` uses `customUpdate` without `updates:`, so Drift streams on feature tables do not refresh from it. Fix it
  where the table classes exist (pass `updates:` or call `markTablesUpdated`).
- **T030/T027:** `write()` sets `pending` on any edit, which clears `conflict` or `rejected` on a row. Decide how a local edit
  of such a row behaves; the stale `baseVersion` will conflict again.
- **T030:** `syncStatus` defaults to `pending`, so pull must set `synced` explicitly when it inserts or updates rows.
- **T036:** `writeBatch` rewrites the whole unsent batch JSON on each call, so the track recorder should buffer GPS fixes and
  call it every few seconds, not per fix.
- **Remove data:** `clearAll` also wipes unsent changes. The Remove-data screen should warn when `unsyncedCount()` is above 0.

## D-052 · Conflicts: three-way merge on the sync serializer, create resend against the creation version
2026-10 · accepted · T027, *amends D-050*
A stale `update`/`delete` (`base_version` ≠ the row's `server_version`) is no longer rejected `stale_version`. `sync.services._merge`
compares three states: the **base** (the history row at `(id, server_version = base_version)`, D-040), the **current** row, and the
client **payload**. Non-overlapping changes merge (status `merged`); an overlap creates a `SyncConflict` and applies nothing
(`conflict`). `SyncConflict` (`sync_conflict`, audited, pulled to its owner as entity type `sync_conflict`) is the ticket's model; an
admin resolves it in T028. Shown by hand with `tmp/t027/smoke.py` and temporary `transect` handlers (no type the phone writes
exists yet; the ticket's `count` is `name`, "admin validated the taxon" is an admin change of `description`; D-021).
- **Merge applies only the client-changed fields**, never the whole payload: the phone may send unchanged fields with their old
  values, and applying them would revert the admin's change. The handler's `update` gets `{k: payload[k] for k in client_changed}`.
- **Comparison is on the sync serializer's JSON form** (`entity.serializer`, the one schema of D-049). `_json(v)` =
  `json.loads(JSONRenderer().render(v))`. Base and current snapshots are `_json(serializer(instance).data)` (for the base,
  `historical_row.instance`). *Server-changed* = keys of the current snapshot, after the T026 server-owned/bookkeeping exclusions
  (`SERVER_OWNED_FIELDS`, `validation_*`, `locked_*`, `entity.server_owned`), whose value differs from the base. *Client-changed* =
  payload keys that are **writable** fields of the sync serializer and whose normalised value differs from the base; a value is
  normalised with `_json(field.to_representation(field.to_internal_value(v)))`, and one that fails that is compared raw (so it
  counts as changed and the handler rejects it if it is applied). Read-only and unknown keys are not compared. **Later tickets:** a
  field the phone writes (geometry in T036/T044) must be writable in its sync serializer, or it is never conflict-checked.
- **Missing snapshot** (no history row at `base_version`, or the model is not audited): conflict with `base_snapshot = null` and
  `conflicting_fields` = every key of the current snapshot ("whole record").
- **Stale delete is always a conflict**, even when only server-owned fields changed; `conflicting_fields` are the server-changed
  fields and may be empty.
- **`update`/`delete` with a null `base_version`** is a validation error (`{"base_version": ["Required for update and delete."]}`),
  not a conflict.
- **No client changes at all** on a stale update (an identical resend): `merged`, nothing saved, `server_version` = the current one.
- **Create of an existing row (the D-050 gap):** treated as an `update` whose base is the row's *creation* version (`server_version`
  of its first `history_type="+"` row), then merged. It always goes through the merge, even when the row is untouched since the
  create, so an exact resend changes nothing and does not bump the version. Admin edits since the create are kept; a real overlap is a
  conflict; no creation history row means the snapshot is missing, so a conflict.
- **`SyncConflict.operation`** is what the server would apply: `update` or `delete` (a create resend is stored as `update`), so
  T028's "accept client" can run it through the handler. `base_version` is the effective base (0 when no creation row was found).
- **Project of a conflict:** new `PushHandlers.project_of(instance) -> Project`, required for every type that registers `create`,
  `update` or `delete` (a resent `create` is merged like an update). `PushHandlers.__post_init__` raises `ImproperlyConfigured`
  without it, so a type that forgets it fails when the registry is imported, not on the first conflict.
- **Unstorable conflict payload:** the conflict row is saved in its own savepoint together with its mutation. If the database refuses
  it (`DataError` for a `\u0000` in a string, which jsonb cannot hold; `IntegrityError`; `ValueError`), the mutation is stored as
  `rejected` (`invalid_data`) and the rest of the batch goes on, instead of a 500 that rolls the batch back and is retried forever.
- **Duplicates:** a stored `conflict` comes back unchanged as `conflict` (like `rejected`), with no second `SyncConflict`; `merged`
  comes back as `duplicate`. The conflict row is saved with the stored mutation (`mutation` is a one-to-one `PROTECT`), so
  `prune_sync_mutations` skips mutations that have a conflict.
- **History index:** `HistoryVersionIndex("historical_<table>")` (`core.migration_ops`) creates `historical_<table>_version_idx ON
  historical_<table> (id, server_version)`. It is applied to every audited synced table (catalogues `0003`, projects `0005`, transects
  `0003`, `sync_conflict`) and must be added with the migration of every later audited synced table. `project_membership` is audited
  but not a synced entity, so it has none.
- **Limits:** field-level merge is top-level only (a geometry is one field). History rows from before T018 keep their stale versions
  (D-040), so a base looked up for an old reference row may be wrong; none of those types is pushable. A historical instance's derived,
  read-only values (`length_m` of a transect) are computed from the current row, so they can show the current value in a base snapshot;
  the stored geometry in the same snapshot is the historical one. The "whole record" field list therefore also contains derived fields.
- **Deferred:** the Drift `SyncConflicts` mirror (ticket section c) to T030, whose criteria already consume `sync_conflict` rows.

## D-053 · Conflict resolution: read-only admin screen, accept client applies only the client's changes
2026-10 · accepted · T028
`SyncConflictAdmin` (`apps/sync/admin.py`) lists conflicts, shows a read-only change view with a diff table (field | base | server |
client; conflicting rows highlighted; the three JSON fields are not shown as form fields) and two buttons, **Accept server** and
**Accept client**. Each opens a form with a required note and calls `sync.services.resolve_conflict(conflict_id, side, user, note)` in one
transaction. Shown by hand with `tmp/t028/smoke.py` and temporary `transect` handlers (no type the phone writes exists yet, so Accept
client in the browser only shows the "cannot be changed by the app" error; D-021, D-052).
- **Accept client applies only the client-changed fields**: the payload keys that differ from `base_snapshot` (`_client_changed`, the
  same rule as the merge). Without a base snapshot the whole payload is applied. A `delete` conflict runs the handler's `delete`. The
  handler is called directly, so `_merge` and the `base_version` check are bypassed. Sending the whole payload would revert admin
  changes to fields the client never touched, as in D-052.
- **History reason:** handlers save through `save_pushed` / `soft_delete_pushed`, which read the reason from a `ContextVar`
  (`handlers.push_reason(reason)`, default `PUSH_REASON`). Accept client wraps the handler call in
  `push_reason("conflict resolved: client")`. A handler that saves another way keeps its own reason, so every pushable type must use the two helpers.
- **The handler runs as the resolving admin**, so the entity's history shows who applied it; admins pass the ownership and membership checks.
- **Locked visit:** T042's services raise code `visit_locked`; Accept client shows "unlock it first" and any other handler error shows
  its detail and fields. The conflict stays open and everything rolls back. T028 adds no lock check of its own.
- **Accept server touches the entity**: `save_with_reason(row, admin, "conflict resolved: server")` on the row loaded with
  `select_for_update` through `_base_manager`. The trigger bumps `server_version` even with no field change, so the phone pulls the server
  state (a tombstone if the row is deleted).
- **Refusals** (`ResolutionError`, shown as a form error, nothing saved): blank note, conflict not open, unknown entity type, missing
  row, `push=None` type or an operation the handler lacks, Accept client `update` on a soft-deleted row ("restore it first"). Accept
  client `delete` on an already deleted row resolves without calling the handler. A handler `ValueError` is also a refusal here (in a push it stays a bug, D-050).
- **The note** is stored in `resolution_note`; the conflict is saved with reason `"conflict resolved: <side>"`, so its history holds the
  note, the status change and the reason. The entity's history reason is exactly the ticket's string.
- **Read-only:** `has_add_permission` and `has_change_permission` are False, so there is no edit form and the soft delete / restore actions
  disappear. Resolving needs `sync.change_syncconflict` (the admin group has it) and `status = open`; a researcher has no admin access.
- **Changed since the conflict:** while a conflict is open and the row's `server_version` differs from `server_version_at_conflict`, the
  change view and the form warn (not after resolving, which touches the row itself). The diff always shows the stored snapshots.
- **Limits:** buttons on the change view only, no bulk actions; no per-field mixed resolution (ticket); the diff compares top-level
  fields as JSON text.

## D-054 · App sync runner: batch rules, rebase after push, pull apply, triggers
2026-10 · accepted · T030
`SyncRunner.run` (`lib/core/sync/sync_runner.dart`) is one run at a time (a second call joins the running Future). It does:
`recoverInFlight`, the push loop, the photo placeholder, `ProjectRepository.refreshFromServer`, the pull per project, then the
bookkeeping. It never throws: a failure comes back as a `SyncResult` with `ok` false. A manual run (button, pull-to-refresh)
ignores the back-off delays; automatic runs do not. A manual call that finds an automatic run going waits for it and then runs
again, so the request is not lost.
- **Reference tables** (schema v5): `project_protocol`, `taxon_list_version`, `taxon`, `plant_taxon`, `habitat_type`,
  `management_type`, `transect`, `transect_section`, and the `sync_conflict` mirror. Written only by pull, so they have `serverVersion`
  and `deletedAt` but no `syncStatus`; `sync_conflict` is the exception (it needs `pending` for the rule below). Foreign keys are
  `<name>Id` text columns; `created_at`/`updated_at` are not stored (except `sync_conflict.createdAt`); decimals are `real`,
  geometry and lists are JSON text. `rank` and `status` are plain text, not `textEnum`: the server values (`species_group`,
  `resolved_server`) are not Dart enum names. SQLite foreign keys are off, so a page may hold a child before its parent.
- **All local projects are pulled** until T031 narrows it to downloaded ones. `refreshFromServer` is now the project-discovery step
  of every run; its failure ends the run with an error.
- **Batch rules** (`nextBatch`): `queued` items in `seq` order, at most 100. An entity with a `conflict` item is held (its items are
  skipped). The batch stops, not skips, at the first item that is not due yet (unless manual) and before an `update`/`delete` of an
  entity already in the batch, so later items never overtake earlier ones. A `rejected` item does not hold later items.
- **Rebase:** an `update` queued after a create has `baseVersion` null (the row has no version yet) and the server rejects that
  (D-052). So `applyPushResults` sets the returned `server_version` on the row and gives the entity's remaining `update`/`delete`
  items that version as `baseVersion`. **Guidance for T034+:** update payloads carry only the changed fields, so a rebase after
  `merged` cannot revert server changes. The row becomes `synced` only when no other item of the entity is left.
- **Sending:** `markSending` flips the batch to `inFlight` and returns the rows as the queue holds them at that moment; the run
  sends those, not the rows `nextBatch` read, because an edit can be merged into a still-queued item in between. Any exception from
  `push` (a reply the app cannot read, not only a network error) goes through `markNetworkFailure` and ends the run, so the batch
  backs off and does not stay `inFlight`.
- **`recoverInFlight`** runs at the start of each run: items left `inFlight` go back to `queued` with `retryCount + 1`, so they no longer
  count as unsent (D-051) and keep their `mutationId`. A missing result for an item is treated as a network failure.
- **Pull apply** (`PullApplier`): one transaction per page, with the cursor `cursor:<projectId>`. `sync_conflict` is applied first.
  Live rows are upserted and reset `deleted_at`; a tombstone only sets `deleted_at` and `server_version` (D-049). Types without a
  local table are ignored. For tables with `sync_status` (today `sync_conflict`) an incoming row is dropped when the local row is
  not `synced` (`pending`, `conflict` or `rejected`), so a local change the server has not accepted is never overwritten. Pulled
  rows are written `synced`. A page that says `has_more` but does not advance the cursor ends the run with an error.
- **Conflict release:** acts only when the queue still holds a `conflict` item for the entity, so a re-pull does nothing.
  `resolved_server` deletes that item and every later item of the entity and sets the row `synced`. `resolved_client` deletes the
  conflict item and sets the row `synced`, or `pending` when other items are still queued (the plan said only `synced`; leaving
  `conflict` would mark the row for ever). The row is touched only if its table is in `_db.allTables`.
  **Known limits:** a local edit made while a conflict was open, with the row on an earlier page than the resolution, keeps
  stale data. After `resolved_client` the released update keeps its old `baseVersion`; check in the manual run (step 11) that the
  server does not conflict it again.
- **`ok`** means no error and nothing sendable left (`nextBatch(ignoreBackoff: true, max: 1)` is empty). Held, `conflict` and
  `rejected` items do not count, so an open conflict does not make every run fail. The run saves `lastSyncBytes` always and
  `lastSuccessfulSyncAt` plus `lastSyncProvider` only when `ok` (this joins the two stores, D-051).
- **Byte counter:** `TransferCounter`, a dio interceptor after the auth interceptor. It counts request bodies as encoded JSON,
  responses by `content-length` or encoded body, and error responses; headers, URLs and bodies that are not text or JSON (a `FormData`
  upload, T050) are not counted. It is reset at the start of a
  run, so the figure covers the whole run, project refresh included.
- **Triggers** (`syncTriggersProvider`, watched in `App`): login or app start (profile null to non-null, `fireImmediately`), app
  resume plus a 15-minute timer while in the foreground, and connectivity going from none to some (the starting state is read once).
  All need a profile (an offline session counts). `connectivity_plus` is the one new dependency.
  `TODO(T040)`: the finish-visit flow calls `run()`. `TODO(T050)`: photo upload goes between push and pull.
- **UI:** `pendingChangesProvider` and `projectPendingChangesProvider` are streams of `watchUnsyncedCount`; a "Sync" tile in Settings
  and pull-to-refresh on the project list call `syncNowProvider`; a progress bar shows under the project list's app bar while a run goes.
- **Shown by** a temporary smoke test (`tmp/t030/`, ten cases: batches, results, back-off, drop after apply, rebase, recovery, pull,
  release, mutex, bookkeeping; in-memory database, fake server); nothing committed (D-021). The release case cannot check the
  entity row's `sync_status`, because its throwaway table is not in `_db.allTables`; the first real synced table (T034) does.
- **Open, for a later ticket (found in review):** every `DioException` from a push, including a permanent 4xx (400, 413), goes
  through `markNetworkFailure`, so such a batch is retried for ever with growing back-off and, because `nextBatch` stops at an item
  that is not due, blocks the items behind it. The plan chose "retry" (a 500 rolled the batch back). A later ticket should treat
  non-retryable statuses (4xx except 401, 408, 429) differently, for example by marking the items `rejected`. Also open: a pull
  downloads the global catalogues once per project until T031 narrows the pull to downloaded projects.
- **Closes from D-051:** the runner raises `retryCount`/sets `inFlight` before sending; pull sets `synced` explicitly; `LastSyncNotifier`
  and `lastSuccessfulSyncAt` are written together. **Still open:** a local edit of a `conflict`/`rejected` row sets it `pending`
  again (`write()`); T034 must make `write()` refresh Drift streams (`updates:`).
- **Who wrote what:** the developer wrote the tables, the transfer counter, `SyncApi`, the queue methods (`recoverInFlight`,
  `nextBatch`, `markSending`, `markNetworkFailure`, `backoffDelay`), the runner and the triggers. Claude wrote, at the developer's
  request: `PullApplier` and its mappers, `applyPushResults` with its helpers, `watchUnsyncedCount`, tidy-ups of `nextBatch` and
  `recoverInFlight`, the connectivity start check, the Settings tile, the project-list changes, the doc comments, and the smoke test.

## D-055 · Offline package: reference version, downloaded flag, download through the runner
2026-10 · accepted · T031
**Reference tables** are every pull entity except `sync_conflict`: `project`, `project_protocol`, `taxon_list_version`, `taxon`,
`plant_taxon`, `habitat_type`, `management_type`, `transect`, `transect_section`. They carry `reference=True` on `SyncEntity`
(`sync/registry.py`); the user data of T034+ leaves it False. `reference_version` is the max `server_version` over the pull scopes of
those entities, deleted rows included (a deletion counts as an update), 0 when empty.
**Endpoints:** `GET /api/v1/projects/{id}/offline-package` (the first pull page from cursor 0 plus `reference_version`, one snapshot) and
`.../offline-package/status` (`{reference_version}`); a non-member gets a 404 (D-036). `sync.services.pull` was split into
`_pull_snapshot` (the transaction and its isolation level, D-049), `_pull_page` and `_reference_version`; `pull` itself behaves as before.
**The app does not call the `offline-package` alias.** It downloads with `POST /sync/pull`, page by page, so `PullApplier.applyPage` saves
the cursor after every page; that is what makes cancel and resume work. The alias is there for the outline §14 API. The app calls only
`.../offline-package/status`.
**Local state** (`sync_state`, no schema change): `downloaded:<projectId>` = `1`, set when a download reaches `has_more = false`. The
existing `cursor:<projectId>` is the local version.
**Status** (`ProjectRepository.offlinePackageStatus`, wrapped by `offlinePackageStatusProvider`): no flag is `notDownloaded` (a cancelled, half-done download too; Download continues from
the saved cursor). With the flag, the server's `reference_version` greater than the local cursor is `updateAvailable`, else `ready`. If the
status request fails (offline) the answer is `ready`. The provider watches `syncRunnerProvider.select((s) => s.last)`, so it is
recomputed after every run and download.
**Only downloaded projects are pulled** by the sync runner. This closes the open point of D-054 ("all local projects are pulled until T031").
A project pulled before T031 has a cursor but no flag; pressing Download once resumes from the cursor and sets the flag.
**One pull at a time:** `SyncRunner.download(projectId)` waits for any run in progress (`_current`), then runs and sets `_current` with
no `await` in between. While a download runs, a manual `run()` waits and then runs (the download is not manual), and an automatic
`run()` joins the download's Future and is skipped until the next trigger. `cancelDownload()` cancels a dio `CancelToken`; the cursor of
the last applied page stays.
**A download is not a sync run:** it does not push and does not touch `lastSuccessfulSyncAt`, `lastSyncBytes` or `lastSyncProvider`. It does
replace `SyncRunState.last`, which only the status provider watches.
**Catalogues are still downloaded once per project**, because cursors are per project: the first download of a second project pulls the
global catalogues again. So the D-054 point is closed only in part: projects that were never downloaded are no longer pulled.
**Checklist:** `docs/testing/offline-checklist.md` is written in full; steps 1-4 are run in T031, the rest by the tickets that add the screens
(list under T031 in TICKETS.md). T060 (MBTiles) is `todo`, so that criterion does not apply yet.
**Found in the manual run: circular provider dependency on token refresh.** `authRepositoryProvider` watched `dioProvider`, and the dio's
`AuthInterceptor` refresh callback reads `authRepositoryProvider`, so every 401 (an expired access token) ended in a
`CircularDependencyError` and no sync could run until the next login. `AuthRepository` now takes a `Dio Function()` and reads the
authed dio only in `fetchProfile`. Checked with a throwaway test (local server answering 401, then the refresh, then 200;
`tmp/t031/auth_refresh_repro_test.dart`, not committed, D-021). Dates from T012/T030.
**Open points from the review (not fixed, for later):** the status call maps every `DioException` (a 404 or 500 too) to `ready`; only a missing
response (offline) should. A project pulled before T031 has a cursor but no `downloaded` flag, so it is not synced until Download is
pressed once. Every run re-asks the status of each downloaded project (one GET each). A cancel during the last page is ignored: the download
completes. `GET .../offline-package` returns only the first page, so it is not a complete package by itself.

## D-056 · Sync status screen: per-project counts, local conflict project, retry under a new id, discard resets the cursor
2026-10 · accepted · T032
**The screen is per project** (`/projects/:id/sync`, opened from the **Unsynced data** tile). Its total is `projectPendingChangesProvider`,
the query behind the tile's badge, so the two always match. The per-type rows (`SyncStatusRepository.watchPendingByType`) group the same
rows by `entityType`, in any status; a `create_batch` counts as one, as in the badge. `SyncStatusRepository` only reads; every write stays in
`SyncRepository`.
**`sync_conflict.projectId` is local** (schema v5 → v6, nullable). The server's conflict rows carry no project, so `PullApplier.applyPage`
adds `project_id` to each incoming conflict map from the page's project. Nothing changes on the server. The v6 step also deletes every
`cursor:%` row in `sync_state` (the `downloaded:` flags stay), so the next sync pulls each downloaded project from 0 once and fills
`projectId` on the old conflict rows. The cost is one full re-pull per project after the upgrade.
**Retry uses a new `mutationId`.** The server answers a resent rejected id with the same rejection (D-050). `SyncRepository.retry` sets the
item `queued` under a new UUID, `retryCount` 0, no back-off and no `lastError`, and the row `pending`. `retryCount` 0 makes the item
"unsent" again, so new edits may merge into it; that is correct because nothing has been sent under the new id. The screen syncs at once
after a retry.
**Discard drops every queue item of the entity** (later ones were built on the discarded one), in one transaction. A `create_batch`: its
child rows are deleted. A rejected create the server never had (`server_version` null): the row is deleted. Otherwise the row becomes
`synced` and the project's pull cursor goes to 0, so the next sync pulls the whole project again and the server version overwrites the
discarded change (the applier skips only rows that are not `synced`). The cost is a full re-pull of that project. Child rows of a deleted
parent (track points of a visit) are not handled: `TODO(T036)`.
**Live progress:** `SyncRunState` gains `phase` (`pushing` / `pulling`) and `sent`; `received` already existed. `_run` emits after each
push batch and, in `onPage`, after each pulled page. Every emit repeats `running` and `last`, because a new state resets what it leaves
out. The project list's progress bar reads only `running`.
**Error messages:** `syncErrorMessage` reads the first `{code, detail, fields}` of `lastError` and maps the code: `validation_error` (with the
field names), `not_found`, `permission_denied`, `deleted`, `visit_locked` (raised from T042), `read_only_entity` / `unknown_entity_type` /
`operation_not_allowed` (one text), `integrity_error`, `invalid_data`, `mutation_id_taken`. An unknown code shows `detail`; text that is not
JSON is shown as it is. The list was checked against `apps/sync/services.py` and `apps/core/exceptions.py`. `entityTypeLabel` has names
for the reference types only; visits and observations are `TODO(T034)`.
**The screen** (`SyncStatusScreen`) is a `ListView` in a `SafeArea` (`top: false`), so the system navigation buttons do not cover the last
card: the Sync now card with progress, a Waiting to sync card (total, one row per type, photos, last successful sync, bytes of the last
sync), Errors, Conflicts. The last sync shows as "5 minutes ago" / "2 days ago" (`_timeAgo`, computed when the screen builds, it does
not tick). A redesign from Mobbin references (one status card, hiding empty sections) was tried and reverted at the developer's request:
the plain layout shows all the data the ticket asks for. Section titles carry the same 4 px as a `Card` margin, so they line up.
**Known risks (found in the review, accepted for T032):**
- *Old resolved conflicts after a re-pull.* A pull from cursor 0 (after the v6 upgrade, or after any Discard) delivers resolved conflicts
  again, and `PullApplier._releaseConflicts` matches a held queue item by entity only. If the same entity has a newer open conflict (it
  conflicted, was resolved, was edited again and conflicted again) and the re-pull comes before that one is resolved, the old
  `resolved_server` conflict drops the newer held item and its later items, and the row becomes `synced`: the change is lost locally while
  the conflict stays open on the server. Fix for a later ticket: send `mutation_id` in the conflict pull, store it locally (schema bump)
  and release only the item with that id. A time check against `created_at` was rejected: it trusts the phone's clock.
- *Discard during a sync.* The screen refuses a Discard if a run started while its dialog was open, but a run starting between that check
  and the transaction can still overwrite the reset cursor. The window is a few milliseconds.
- *Discard in a project that is not downloaded:* only downloaded projects are pulled, so the row stays `synced` with the discarded values
  until the project is downloaded.
- `retry` does not check that the item still exists; the stream-driven UI cannot call it with a stale item. `retry` and `discard` write
  entity rows with `customUpdate` and no `updates:`, so streams on entity tables refresh late (the D-051 gap, relevant from T034).
- After the v6 step every downloaded project shows `updateAvailable` until the first sync (the cursor is 0).
- `discard` of a `create_batch` deletes the child rows of every batch of the parent (their queue items go too); checked in the smoke test.
**Photos waiting is a placeholder** (`pendingPhotosProvider`, 0 and 0 bytes) until T050 (`TODO(T050)`).
**Who wrote what:** the developer wrote the `projectId` column, the v6 step, the applier change, the three read queries, `retry` and the
first version of the runner state and emits. Claude wrote, at the developer's request: the doc comments in `sync_conflicts.dart`,
`sync_status_repository.dart`, `retry` and the runner; the return statement of `watchPendingByType`; the batch branch and then the whole of
`discard`; the fix of the pull emits in the runner; and, so the developer could test the UI, the providers, `sync_error_message.dart`,
`SyncStatusScreen`, the route and the tile `onTap`, then the `SafeArea`, `_timeAgo` and the section-title padding. The throwaway smoke test and the debug seed patch are in `tmp/t032/` (not committed).

## D-057 · Transect list and detail: package flag as "downloaded", nearest-vertex distance, warnings shared with T035
2026-10 · accepted · T033
**Screens:** `TransectListScreen` at `/projects/:id/transects` (opened from the **Transects** tile) and `TransectDetailScreen` at
`/projects/:id/transects/:transectId`. They read Drift only, through `TransectRepository` (read-only: transects, sections joined to
`habitat_type`, the project protocol), so they work offline.
**"Downloaded" flag:** a transect is on the phone only after a pull, so each row shows the project's `downloaded:<projectId>` flag
(D-055) through `projectDownloadedProvider` (`project_stats.dart`, recomputed after every sync run and download). There is no
per-transect download (T031: no partial packages).
**Distance:** straight line from the last known position (`lastKnownPositionProvider`, `getLastKnownPosition`, never waits for a fix) to
the nearest vertex of the transect line, with latlong2's `Distance`. The app bar's location button takes a fresh fix
(`currentPositionProvider`), which the screen keeps and prefers. Without a position the distance is "—" and the distance sort falls
back to code.
**Map:** flutter_map 8.3.2 and latlong2 0.10.1 (approved for T033), OSM tiles with `userAgentPackageName: rs.amilojkovic.butterfly`.
The whole line is a wide grey band, and each section is drawn over it in a colour from an 8-colour palette by walking order
(`sectionColor`, also used for the dots in the section list). flutter_map 8.x caches the tiles it has shown by default
(`BuiltInMapCachingProvider`, VERIFY done in T033), so an area seen online usually still has a basemap offline. Otherwise the lines are
drawn on a plain background. The offline basemap proper is T060.
**Season and time-window warnings** are `seasonWarning` / `timeWindowWarning` in `features/transects/domain/protocol_window.dart`, and
the summary is the `ProtocolSummary` widget. T035 reuses both. The season is compared by local calendar date, with both ends counting as
inside. The day window uses local wall-clock time. Start visit is disabled for an inactive transect; outside the window it asks
"Start anyway" and does not block.
**Placeholders:** own visit count, last visit and history come from `transectVisitStatsProvider` / `transectVisitsProvider`
(`visit_stats.dart`, `TODO(T034)`), which emit no visits until the phone has a `survey_visit` table. Start visit ends in a snackbar
until the start-visit form exists (`TODO(T035)`). The outline's "filter po području" is not in the criteria and was not built.

## D-058 · Visit lifecycle: a dict table, `transition()` does not save, push-only synced step, two spec tests
2026-10 · accepted · T034
**State table:** `apps/surveys/state.py` `TRANSITIONS = {(from, to): actor}` with actor `app` (the visit's creator, or an admin acting
for them), `server` (`actor=None`, the push service itself) or `admin`. The same table is `visitTransitions` in
`mobile/lib/features/visits/domain/visit_status.dart`; the spec both copy is `docs/requirements/visit-states.json`. `transition(visit, to,
actor, reason=None)` checks the move and the actor and sets fields **on the instance only**; callers save with their own history reason
(`sync push`, `REST API`, `marked reviewed`). `reason` is the `cancel_reason` for `cancelled` (must be a `CancelReason` value) and the lock
reason for `locked`, which also sets `locked_at`/`locked_by` (the DB constraint needs them; the lock UI is T043). Leaving `locked` clears
the three lock fields; the history keeps them. `InvalidTransition` is a DRF `APIException` (409, code `invalid_transition`), so push
stores it as a rejection and REST returns the standard body; the app's `syncErrorMessage` names it.
**Several moves in one push:** the phone works offline and its queue merges unsent updates (D-051), so one push can carry several app
moves: a new visit first pushed as `completed`, or a synced draft that was then started and finished offline and arrives as one update
`draft → completed`. `state.steps_between(from, to)` gives the direct move when the table has one, otherwise the shortest chain of app moves
(draft → in_progress → completed), or None. `state.move_to(visit, to, actor, reason)` walks it, each step through `transition()`; both
`build_new_visit` (from `draft`) and `apply_visit_changes` use it. Admin and server moves are never chained, so a status the app cannot reach
(`synced`, `reviewed`, `locked`) is still `invalid_transition`. (Found in code review: the first version chained moves only for creates.)
**`completed → synced`** happens only in the push handlers (`mark_synced_if_completed`, in the same save as the change), never in REST,
admin or a signal (ticket d). So `POST /survey-visits/{id}/complete` leaves a visit `completed`. **A pushed `status: completed` for a visit
that is already `synced` is no change**, not a move back: a phone that has not pulled since its push still holds `completed`.
**Services:** `apps/surveys/services.py` builds a change on the instance (`build_new_visit`, `apply_visit_changes`) and saves through
`save_visit`, which runs `validate_constraints()` first so a broken CHECK comes back as a field error, not `integrity_error`, and reloads
`server_version` after the save (the trigger writes it, D-029), so REST answers the real version. Push, REST and admin all call these. `sync.handlers.current_push_reason()` was added so a service that saves on its own still uses the push reason
(D-053). The REST views read input with `SurveyVisitSyncSerializer` (the push schema) and answer with `SurveyVisitSerializer` (adds the
server-owned fields). `deleted_at` is read-only in the sync serializer: push strips it anyway, but REST validates with the same class, and
a client must not delete a visit. The visit endpoints accept **JSON only** (`parser_classes = [JSONParser]`, a form body is 415) and refuse a
body that is not an object (400). `POST /survey-visits` takes the client's `id` (or makes one); an existing id is a 400.
`GET /transects/{id}/visits` lives in the surveys app (surveys depends on transects, not the other way round) and sorts
`started_at DESC NULLS LAST`, so unstarted drafts come last as on the phone. The admin action "Mark as reviewed" reloads each visit with
`select_for_update()` inside its own transaction, so it never saves an older copy over a push that landed meanwhile.
**Rules chosen with the developer:**
- *Observer:* a researcher's visit always has `observer = caller` (left out, it defaults to the caller; anything else is a
  `validation_error`). An admin may name any member of the project or another admin.
- *Visit count and last visit:* live visits not in `draft` or `cancelled` (`COUNTED_STATUSES`, the same list in `VisitRepository`); last
  visit = latest `started_at`. Researchers count their own (`created_by`), admins all. `with_stats` takes the visit count and last visit
  from subqueries on `surveys.services.counted_visits(user)`, not from a second join: joining sections and visits together would build
  sections × visits rows per transect.
- *No delete handler:* a visit is cancelled, not deleted, so a pushed `delete` is `operation_not_allowed`. A local create that was never
  sent can still be removed by the queue's create + delete coalescing (D-051).
- *Tests:* the ticket's "test on both sides" is written, an exception to D-021 the developer chose: `backend/apps/surveys/tests.py`
  (`SimpleTestCase`, no database; `manage.py test apps.surveys`) and `mobile/test/visit_status_test.dart`. The django container now mounts
  `./docs/requirements` read-only at `/docs/requirements` (`compose.dev.yaml`), so the test finds the file at `BASE_DIR.parent / "docs"`
  in the container and on the host.
**Scopes:** pull = the project's visits with `created_by = user`, deleted rows included; REST = `visits_for(user)` (live, in
`projects_for(user)`, researchers only their own). Not reference data (`reference=False`). `distance_walked_m` is server-owned (T036).
**App:** Drift `survey_visit` (schema v7, `from6To7`), `SyncColumns` mixin (its first user), plus `createdOffline` from the server and
local-only `pausedAt`. `PullApplier` maps it; the pending-row guard already applies because the table has `sync_status`.
`SyncRepository`'s raw SQL writes now pass `updates: _tablesOf(entityType)`, so streams on feature tables refresh after `write`, `retry`,
`discard` and push results (closes the D-051/D-054/D-056 point). `VisitRepository` is read-only (T035 adds writes); the transect list and
detail read it, and the detail shows `visitStatusLabel`.
**VERIFY done:** `sqlmigrate surveys 0001` shows `visit_cancel_reason_consistent` as `(status = 'cancelled' AND cancel_reason IN (...)) OR
(NOT (status = 'cancelled') AND cancel_reason = '')`, as the ticket's DDL. The model also has `visit_survey_method_valid` (the DDL's
inline CHECK).
**Shown by hand:** `tmp/t034/smoke.py` (53 checks, all passing after the review fixes: push lifecycle, offline-completed create, draft → completed in one update, illegal moves, observer, cancel reason, delete,
ownership, history reasons, pull scope, the four REST endpoints, no `/lock`, transect list and stats, the admin action and its refusal),
run in the container; it soft-deletes its visits. The Drift v6 → v7 step was checked with the generated migration test, kept in
`tmp/t034/drift_migration_test/` (not committed).
**Obligation for T035 (from the code review):** update payloads must carry only the fields the phone changed (D-054). The conflict merge
(D-052) does not know that `completed` on the phone equals `synced` on the server, so an update that resends an unchanged
`status: completed` after the server moved the visit on (for example to `reviewed`) would be a conflict on `status`.
**Found on the way (not fixed, for a later ticket):** the admin group's permissions are granted on accounts' `post_migrate`
(D-034), which runs before Django creates the permissions of apps listed after `accounts`. A new app's permissions reach the group only on
the next `migrate`. Here a second `migrate` fixed it; a fresh database would need the same.

## D-059 · Start-visit form: one draft per transect, what Start needs, one visit in progress, changed-fields updates
2026-10 · accepted · T035
**Screen:** `StartVisitScreen` at `/projects/:id/transects/:transectId/start`, opened from Start visit on the transect detail after its
season/time-window dialog (D-057); the form shows the same warnings again as a card that does not block. It reads Drift and the
in-memory profile only, so it opens offline; measured 200–260 ms from the tap (debug build).
**Draft:** the form opens the logged-in user's newest `draft` of the transect (`transectDraftProvider`), and Save draft / Start
update that row instead of making a second one. Drafts and the visit in progress are filtered by `observer_id` = the current user,
because logout keeps the local database, so another user's visits can still be on the phone. The detail button then reads "Continue draft". Without this a draft could not be reached again: the
visit history lists only started visits. Nothing is required for a draft.
**Start needs** temperature, wind, cloud cover and the protocol checkbox. The cloud slider starts "Not set" (null) and gets a value only
when touched, so 0 % is never stored by accident. It sits at 0 while "Not set", and `Slider.onChanged` skips a value equal to its
position, so `onChangeEnd` sets the value too (otherwise 0 % could not be picked; found in code review). The observer count stops at
20 (no protocol limit; guards against a stuck finger). The checkbox is a gate only; no column stores it.
**Weather check:** `failedWeatherThresholds` (`features/visits/domain/weather_check.dart`) returns the failing thresholds as sentences:
precipitation other than `none` unless `allow_precipitation`, wind above `max_wind_beaufort`, and below `sunny_temperature_c` either
temperature below `min_temperature_c` or cloud above `max_cloud_cover_pct_if_cool`. `weather_suitable` is the result (true/false), or null
while the weather is incomplete (drafts only). Unsuitable weather needs "Start anyway" and is stored `false`. No `weather_missing_reason`
is asked for here (T040/T055, V05). Beaufort 0–12 labels and field hints and the precipitation labels are in `beaufort.dart`.
**One visit in progress:** Start is refused (dialog naming the transect) while the user has a local visit `in_progress`, because
tracking (T037) follows one visit. The form checks first, for the dialog; `VisitRepository.start` checks again inside its write
transaction and throws a `StateError`, so any later caller is held to the rule too. Until T040/T041 can finish or cancel a visit, a started test visit blocks new starts on that phone; an admin can
cancel it on the server (`state.move_to(visit, "cancelled", admin, reason)`), and the next pull brings that back.
**Writes** (`VisitRepository.saveDraft` / `start`, through `SyncRepository.write`): a new visit queues a `create` with every field the
phone sets (`project`, `transect`, `observer`, `protocol_version` and `survey_method` from the project protocol, `device_id` from
`sync_state`, `created_at`, `status`, `started_at` and the form's fields). An existing draft queues an `update` with only the fields that
differ from the draft **as the form opened it** (D-058 obligation): a pull may change the row while the form is open, and comparing
with the fresh row would send those server values back as the user's edits. `baseVersion` and the status check use the row as it is
now, read in the same transaction (the runner's rebase fills in the version after a create, D-054); a draft that was deleted or moved
on meanwhile is a `StateError`. The local row gets all of the form's columns; the server's merged row comes back on the next pull.
Nothing changed queues nothing. An unsent create absorbs the update (D-051). `start` checks `appMayMove(status, 'in_progress')`.
**Riverpod 3 pauses a provider nobody listens to**, so `ref.read(someStreamProvider.future)` from a button handler can wait for ever
(found on the phone: Start did nothing). The form `watch`es `visitInProgressProvider` (and that visit's transect) in `build` and reads
`.value` in the handler. Use the same pattern elsewhere.
**The form stays up** while a provider reloads (`hasValue`, not `is AsyncData`), so typed values are not lost; without a profile it
says "You are logged out", not "download the project".
**Placeholders:** `TODO(T037)` start tracking in `VisitRepository.start`; `TODO(T039)` after Start the app returns to the transect detail
with a snackbar; `TODO(T073)` the `visit_form_open` event; a comment marks the T085 "Auto-fill weather" slot in the weather card.

## D-060 · Track points: batch-only entity, not pulled, distance from the track with the phone's figure as fallback
2026-10 · accepted · T036, *amends D-050 and D-058*
**Model:** `SurveyTrackPoint` (`survey_track_point`, `apps/surveys/models.py`) as the ticket's section a, with the sync trigger and no
history (CONVENTIONS A.5.7). Points are never thinned, simplified or deleted by the server: they are the raw input for T088.
**Push only:** the registry entry has `PushHandlers(create_batch=surveys.push_track_points)` and nothing else, so a single `create`,
`update` or `delete` is `operation_not_allowed` and no `project_of` is needed. The pull scope is empty (`pull_track_points` returns
`none()`), so the pull's `survey_track_point` key is always `[]`. The phone that recorded a route already has it, and pulling every
pushed batch straight back would double the track traffic (T074). The cost: after Remove data or a reinstall, old routes exist only on
the server (T059's route layer shows local points).
**Batch handler:** the visit must be live (else `not_found`), the caller's own (or an admin's) and in a project the caller is a member
of. Rows are validated with `SurveyTrackPointSyncSerializer(many=True)`; **one bad row rejects the whole batch**, and the error names
the row (`fields: {"rows[3].heading_deg": [...]}`) so the phone's sync error message says which point. `geometry` is a GeoJSON Point
(`core.serializers.WritableGeoJSONField`, also meant for T044); the phone sends its `lat`/`lon` that way. `heading_deg` is checked in
the serializer too, so it is a field error and not `integrity_error`. `insert_batch` (`ON CONFLICT DO NOTHING`) makes a resend harmless;
it also **silently skips** a new id that reuses a `(visit, sequence_number)` pair. The visit lock (T042) is not checked yet.
**Distance (amends D-050 and D-058):** `distance_walked_m` is no longer server-owned. The phone may send its own figure (T040), and the
server replaces it whenever it has at least two usable points: `walked_distance_m` = `ST_Length(ST_MakeLine(geometry ORDER BY
recorded_at, sequence_number)::geography)` over live points with `accuracy_m` null or at most `2 × protocol.gps_accuracy_warning_m`
(raw SQL: Django's `MakeLine` cannot order), rounded to 0.1 m. `sequence_number` only breaks ties. It runs in `push_create`,
`push_update`, REST `update_visit` and `complete_visit` when the visit ends up `completed` or `synced` (`set_distance_if_finished`), and **after every
batch** for a visit already finished (`refresh_distance`). The second path is needed because a visit started and finished offline
reaches the server as one `create(status=completed)` *before* its track batches: the queue merges the finish into the unsent create and
keeps its `seq` (D-051). That save uses the push reason and happens only when the value changed, so a resend writes no history row;
a visit finished offline gets one history row per batch that changes its distance. The column does not record whether a stored value
came from the server or the phone.
**Admin:** the visit page ends with a read-only "Route" field (`route_map`): the route of every live point in recorded order, unfiltered
(`surveys.services.route_geojson`), drawn solid over the dashed transect line by `surveys/route_map.js` with the OpenLayers build
Django's map widget loads (`OSMWidget().media`), plus the point count. Fewer than two points shows "No route".
**App:** Drift `survey_track_point` (schema v8, `from7To8`), as section c: `lat`/`lon`, `serverVersion`/`syncStatus` but no
`deletedAt` (so not the `SyncColumns` mixin), unique `(survey_visit_id, sequence_number)` and a provider CHECK. `SyncRepository.discard`
of a visit create the server never had now also deletes that visit's track points and their queued batches, which would otherwise be
pushed for a visit the server never gets (closes the `TODO(T036)` of D-056). The sync screen names the type "Track points". Writing
points is T037.
**Shown by** `tmp/t036/smoke.py` (55 checks, run in the container: 1000-row batch in 0.27 s, 1001 rejected, resend and duplicate,
bad rows, ownership, not-found, single operations refused, empty pull, distance with an outlier left out and one at exactly 2× kept,
client value kept with 0, 1 or only inaccurate points, the offline-finish path, REST complete, the admin page). It keeps one visit
("t036 demo route") for the admin map and soft-deletes the rest with their points. The Drift v7 → v8 step was checked with the generated
migration test, and `discard` with a throwaway test (both in `tmp/t036/`, not committed; D-021).

## D-061 · GPS tracking: follows this phone's visit, buffered writes, resume marker, permissions before Start
2026-10 · accepted · T037, *amends D-054*

**Driver:** `TrackingController` (`features/visits/domain/tracking_controller.dart`, a `NotifierProvider` kept alive by `App`) follows
`deviceVisitInProgressProvider`: the `in_progress` visit whose `device_id` is this phone's, by any user. It does not follow the
logged-in user's visit, so an expired session or a logout does not stop the recording of a walk. Only Remove data, or the visit leaving
`in_progress` (finish T040, cancel T041, or a pull), ends it, and a visit walked on another phone is never tracked here. The provider
is rebuilt when the user changes so the device id is read again after Remove data. The controller acts only when the visit id changes
(`_handledVisitId`), so edits to the row do not restart tracking. `stop()` (for T040) flushes and does not restart for the same visit.
**Source:** `LocationSource` / `GeolocatorSource` (`core/location/location_source.dart`): `AndroidSettings(high, intervalDuration,
distanceFilter: 0, ForegroundNotificationConfig(setOngoing, enableWakeLock))`. The notification reads "Visit in progress: <code>". `WAKE_LOCK`
is in the manifest because `enableWakeLock` needs it. `ACCESS_BACKGROUND_LOCATION` is not requested (T037 VERIFY). Swiping the app away
stops the service, since geolocator binds it to the Flutter engine, and the next start resumes. T072 adds a replay source.
**Interval:** the per-device override (`gps_interval_override_s` in SharedPreferences, Settings) or the protocol's `gps_interval_s`, or 5 s
when the protocol is missing. It is read when tracking starts.
**Buffer:** fixes are numbered from `MAX(sequence_number) + 1` and written every 10 points or 30 s through `TrackPointRepository.addPoints`
(`writeBatch`, one transaction with the queue item). Writes run one after another. A fix not newer than the last stored or buffered one
(the cached position some phones deliver first) is dropped, so `recorded_at` and `sequence_number` stay in the same order. Writes are
skipped when the visit is no longer on the phone. Points are stored as `provider = 'fused'` and rounded to the server's decimals,
with out-of-range values sent as null, because one bad row rejects the whole batch (D-060). Up to 30 s of buffered fixes are lost if
the process dies.
**Resume:** a visit whose `started_at` is before the controller was created (an earlier run of the app) gets "Tracking interrupted
<last point or start>–<first new fix>" on the tracking card. The marker is not stored: gaps can be computed from the points (T038/T040).
**Card:** `TrackingStatusCard` on project home and transect detail shows the transect, interval, point count and last fix, the
interruption, a location problem (cleared by the next fix, with Try again only when GPS is not running) and a save problem (kept).
T039's active visit screen takes it over.
**Permissions:** `prepareTracking` runs before `VisitRepository.start`, so the service starts while the app is in front (Android 14).
It asks for location if unanswered, then for notifications (Android 13+), and once per install (`battery_optimisation_prompted`) shows
an explanation, then `Permission.ignoreBatteryOptimizations.request()` (`permission_handler`, CONVENTIONS A.4). The controller itself
does not ask for location, so a refusal is not asked twice.
**Sync runner (amends D-054):** a run is `ok` if no item that was in the queue when it started is left over (`SyncRepository.lastSeq()`).
Otherwise track batches queued during the run, including the last flush after a pull ends the visit, made it report "Sync did not
finish".
**Not done (code review):** the buffer is not written when the provider is disposed, which happens only when the app goes away. A gap
inside one app run (location off, then Try again) shows no interruption; that is T038's banner.

## D-062 · Visit lock: a push guard before the merge, `ensure_unlocked` for every child, admin edits unlocked visits, locked pulls reject queued changes
2026-10 · accepted · T042, *amends D-050, D-058 and D-060*
**Error:** `surveys.state.VisitLocked` (409, code `visit_locked`; the detail names who locked it, when and why) and
`ensure_unlocked(visit)`. Every service that changes a visit or one of its records calls it with the parent visit:
`apply_visit_changes` (REST PATCH, push update, Accept client), `complete_visit` (before its status check, so the answer is
`visit_locked`, not `invalid_transition`), `push_track_points`, `mark_reviewed` and `admin_save_visit`. **Later child tickets
(T044 observations, plant resources, habitat features, T049 photos) must call it in their create, update and delete services**,
with the visit loaded `FOR UPDATE`.
**Push guard (amends D-050):** `PushHandlers.guard(user, instance)`, optional. `sync.services._apply` calls it after the ownership
and deleted checks and *before* the resend/`base_version` branch. Without it, a stale update of a locked visit went to `_merge` and
became a `SyncConflict` (or a silent `merged` with no change) instead of a rejection. `survey_visit` registers
`guard=surveys.guard_visit`; a child type registers a guard that checks its visit (e.g. `ensure_unlocked(obs.survey_visit)`).
`create_batch` gets no row checks, so its handler checks the lock itself. A visit cannot be created locked (`move_to` from `draft`
refuses it) and has no delete (D-058). Order: another user still gets `permission_denied` before `visit_locked`; an admin's push is
refused too. Accept server in conflict resolution still touches a locked row (an admin action); Accept client fails with "Unlock it
first" (D-053).
**"Mark as reviewed" refuses a locked visit.** `locked → reviewed` is the unlock, which T043 does with a reason; the bulk action used
to clear the lock silently.
**Admin edits (amends D-058):** an unlocked visit is now editable. Fixed fields (`SurveyVisitAdmin.fixed_fields`): `status`,
`cancel_reason`, `project`, `distance_walked_m`, `locked_*`, `quality_flags`, `device_id`, `created_offline`, `deleted_at`, plus the
sync fields. That is more than the TICKETS note listed: a visit cannot change project, the cancel reason belongs to the cancel flow,
and the device and offline flag record where the visit came from. `SurveyVisitAdminForm.clean()` reloads the row `FOR UPDATE`
(Django admin validates and saves in one transaction, so the lock holds until the save), refuses a locked row first, then compares the
hidden `opened_version` (the `server_version` the form was opened with) and refuses with "changed after you opened it, reload" if the
row moved on: Django's `changed_data` compares the POST with the *reloaded* row, so without this a form opened before a phone push
would write its old values over it (code review). Then `services.check_admin_edit` (transect in the project, observer a member) runs on
the reloaded row with only the changed fields set; a refusal is a form error, not a 500. The table's constraints are left to the
ModelForm (none mixes an editable field with a read-only one). `save_model` saves that row through `services.admin_save_visit` with the
change-reason dialog's text (`admin edit` when blank). `opened_version` is added to the fields only on an edit form (a read-only page
would fail to look it up). The distance is not recomputed. A locked visit: `has_change_permission(obj)` is False (read-only page, a POST is 403), and
`admin/surveys/surveyvisit/change_form.html` shows "Locked by X on Y: reason" in `form_top`. **Child admins (T044+)** return
`not services.is_locked(obj.survey_visit)` from `has_change_permission`.
**App:** no schema change; the lock arrives as `status = locked` (D-058). `visitIsLocked(status)` in `visit_status.dart`.
`PullApplier._rejectChangesToLockedVisits` runs for every pulled `survey_visit` with status `locked`, before the pending guard: the
visit's never-sent items (`queued` with `retryCount` 0: its updates and its `survey_track_point` batches, both with `entityId` = the
visit) become `rejected` with
`lastError = [{code: visit_locked, ...}]`, and the row becomes `synced`, so the guard lets the locked server row in. Items the server
already rejected keep their own message. An item sent before (`retryCount` > 0, e.g. its reply was lost) stays queued, because the
server may already have it and then answers `duplicate`; Discard of it would delete points the server holds (code review). `conflict`
items stay (they are settled on the server); while one exists the row keeps its
local values and shows as locked only after the conflict is resolved. `TODO(T044)`: observations' queued changes. The rule lives in
`PullApplier` (which already rewrites queue items in `_releaseConflicts`), not in `SyncRepository` as first planned.
`VisitRepository._update` throws `StateError` for a locked visit, and `TrackPointRepository.addPoints` writes nothing for one. The
transect's "My visits" list shows `Icons.lock_outline` with "Locked". The sync screen hides Retry on a rejected item while its visit is locked on the phone
(`lockedVisitIdsProvider`, matched on `entityId`), whatever the error code; after an unlock is pulled, Retry comes back (the code review
found that keying it on the stored `visit_locked` code hid Retry for good). The message: "An admin has locked this visit, so this
change was not accepted. Discard it, or retry after the visit is unlocked." (true for both the pull-time and the server rejection). Discarding a rejected
track-point batch deletes those points locally (D-056); the server keeps what it had.
**Closes D-060's "the visit lock (T042) is not checked yet".**
**Shown by hand:** `tmp/t042/smoke.py` (43 checks, run in the container): push update with a current, a stale overlapping and a stale
non-overlapping version, an empty update, a resent create (all `visit_locked`, no new conflict, nothing changed), the track batch,
another user and an admin, REST PATCH and `/complete` (409), Accept client, Mark as reviewed (service and action), admin permission,
banner, 403 on POST, the edit form (valid edit, observer outside the project, a lock that lands while the form is open), and after an
unlock the same pushes applied. It leaves one visit "t042 locked demo" locked for the browser. The pull rule was checked with a
throwaway Drift test (`tmp/t042/locked_pull_test.dart`, 6 cases; not committed). "Tests for each child entity type" was skipped
(D-021). The admin form part of the smoke script also covers a push while the form is open (refused, push kept), a reload then an
edit (only that field changes) and a broken time constraint.
**On the phone (Galaxy S24, USB):** (a) a synced FG3 visit locked on the server showed the lock icon and "Locked" after a sync, with
no queue items. (b) A walk on FG4 was tracking (created on the server with this phone's device id, so the tracker picked it up), the
USB link was cut while a 10-point batch queued, the visit was completed and locked on the server, and on reconnect the server rejected
the batch with `visit_locked`; the visit became `locked`/`synced`, tracking and its notification stopped, and the card showed the message
with Discard only. After a server unlock (`reviewed`) and a sync, Retry appeared and sent the 10 points.
**Late track batches (open, for T040/T043):** a lock never comes from losing signal; it is an admin action on a finished visit. But
a visit finished offline can reach the server before all its track batches (one push carries at most 100 items), and a lock in that
gap would refuse the rest. Chosen with the developer: T040 sends the phone's track point count on finish, and T043's Lock warns or
refuses until the server has that many points (notes under both tickets in TICKETS.md). Accepting late batches on a locked visit was
the alternative; it contradicts T042's criterion.
**Code review findings not taken:** a DB trigger instead of the per-service calls (a larger change than this ticket; the per-entity
guard and `ensure_unlocked` are the rule for T044+), batching the per-visit queries in the pull (few locked visits per page),
`visitIsLocked` in `PullApplier` (`core/` would import `features/`), and the repeated checks in `complete_visit` / after the form
(cheap; the service keeps the rule in one place).

## D-063 · Active visit screen: pause stops GPS, `paused_seconds` sent on Resume, current section and distance on the phone
2026-10 · accepted · T039, *amends D-059*
**Screen:** `ActiveVisitScreen` (`features/visits/ui/active_visit_screen.dart`) at `/projects/:id/visits/:visitId`, nested under
project home. After Start, the start form is replaced by it (`pushReplacement`), so back goes to the transect detail. The tracking card
on project home and the transect detail opens it. Leaving the screen does not end the visit. It reads only Drift and the tracker, so
it works offline (the basemap needs cached tiles, T060). A visit that is no longer `in_progress` (pulled as cancelled or locked) shows
only a message.
**Pause (chosen with the developer):** Pause sets the local `pausedAt` (`VisitRepository.pause`, a plain Drift update with nothing
queued; the pull leaves the column alone because its companion value is absent). `TrackingController` follows the row and **stops the
GPS stream** while `pausedAt` is set. That also removes the foreground service and its notification, and saves battery. Resume
(`VisitRepository.resume`) adds `now − pausedAt` to `pausedSeconds`, clears `pausedAt` and queues an `update` with only
`paused_seconds` (D-059's changed-fields rule; the server accepts it, it is not server-owned). The tracker then starts GPS again,
without a "Tracking interrupted" marker, because Resume is pressed in the foreground, which Android 14 needs. An app start with a paused
visit leaves GPS off until Resume. `stop()` (T040) now sets `_stopped`, so a later resume of the same visit does not restart
tracking. While paused, Add butterfly/plant/habitat first ask "Record anyway?".
**Consequences for later tickets:**
- T040 must close an open pause before computing `duration_seconds`.
- T038's banner must stay quiet while `TrackingState.paused`.
- Only the *total* paused time is stored, so a pause cannot be told apart from a GPS gap in the points. T038, T040 and T056's
  "outside pauses" have to settle that; notes are under those tickets (developer's choice: not widened here).

**Header:** walking time = now − `startedAt` − `pausedSeconds` − the running pause (`walking_time.dart`), redrawn every second. A
gap from a killed app counts as walking time.
- **Distance** = `routeLengthM` (`route_length.dart`) over the stored points, with the server's accuracy rule (D-060: accuracy null
  or ≤ 2 × `gpsAccuracyWarningM`), geodesic per step. Stored points arrive with the buffer (≤ 30 s, D-061), so the figure and the
  drawn route lag that much. The route line runs on to the newest fix, which `TrackingState.lastPosition` now carries on every fix.
- **Current section** = the nearest section line within `maxDistanceFromTransectM` (20 m when the protocol is missing), as a
  point-to-segment distance on a local equirectangular plane (`distanceToLineM` in `geo_line.dart`). Otherwise it is "—".
  `currentSectionProvider(visitId)` is for T045 to store the section.
- **Observation count:** 0 until T044 (`visitObservationCountProvider`, `TODO(T044)`).

**Map:** `TransectMap` takes an optional `currentSection` (drawn wide with a white border) and `overlays`: the route (all stored
points, unfiltered, as the admin map, always black: it is recorded data), plus the newest fix with an accuracy circle, grey while
paused or when GPS is not running. When GPS starts again (Resume, Try again) `lastPosition` is cleared until the first new fix, so an
old spot never counts as the current position or section. After an app start while paused there is no position until Resume.
**Keep screen on:** an app-bar toggle, stored per device (`keep_screen_on` in SharedPreferences, `keep_screen_on.dart`). The screen
calls `WakelockPlus.toggle` while it is open and `disable` when it closes. A tap shows a 2 s snackbar saying which way it went (developer's request: a
tooltip only shows on a long press, which a thumb in the field never does); the tooltip stays as TalkBack's label. `wakelock_plus` is pinned at 1.8.0 (CONVENTIONS A.4):
1.8.1+ needs `dbus ^0.8`, which conflicts with `geolocator_linux`'s `^0.7`.
**Tracking messages:** the interruption, problem and save-problem rows moved from `TrackingStatusCard` into `TrackingMessages`, used
by both the card and the screen.
**Placeholders:** Add butterfly (`TODO(T045)`), Add plant (`TODO(T052)`), Add habitat (`TODO(T054)`) and Finish (`TODO(T040)`) show
"coming in a later version".
**From the code review:**
- Only `WalkingTimeFigure` ticks every second, so the map is rebuilt only when data changes.
- Pause/Resume is disabled when this phone does not record the visit's route, since another phone would send its own `paused_seconds`.
- A "Tracking interrupted" still waiting for its first fix survives a pause.
- `saveProblem` stays for the rest of the visit, across pauses.
- `visitRouteProvider` and `currentSectionProvider` are `autoDispose`.

**Cloud cover starts at 0 % (developer's request, amends D-059):** the start form's slider sat at 0 while showing "Not set", which
looked like a value. Now the value is 0 % from the start (a draft without one opens at 0 %), so the screen and the stored value agree.
Start no longer asks for cloud cover; the hint reads "Fill in temperature and wind".
**Empty lines (found by the developer):** flutter_map asserts when a `Polyline` has no points (it builds its bounding box from them).
Right after Start the route is empty until the first fix, so the map flashed a red error. The route layer is drawn only from two
points, and `TransectMap` skips an empty transect or section line, which can occur while it is still loading.

Not taken: returning the section index from `currentSectionProvider` instead of finding it again in the screen (a few sections, a
cheap search). Also not taken: drawing the route when `TransectMap` has no transect line: a visit starts from a transect on the phone,
so the line is there.

## D-064 · Mobile UI: one widget per file, screens in `ui/`, the rest in `ui/widgets/`
2026-10 · accepted · T039 (developer's request)
Screen files had grown to 300–600 lines with several widgets each, which made them hard to read. Now:
- `features/<feature>/ui/` holds the screens (the widgets the router opens) and UI helpers that are not widgets
  (`tracking_permissions.dart`, `project_period.dart`).
- `features/<feature>/ui/widgets/` holds every other widget, **one public widget per file**, the file named after the widget
  (`VisitHeader` → `visit_header.dart`). A `State` class stays in the file of its widget, and a private helper (a formatter, a
  constant) stays in the file of the one widget that uses it.
- Dart privacy is per file, so the moved widgets lost their `_`: names say where they belong (`FormSectionTitle`,
  `DetailSectionTitle`, `SyncSectionTitle` are kept apart rather than shared, since they differ or belong to one screen each).
- The loaded body of a screen that first waits for data is a `…View` widget (`ActiveVisitView`, `TransectDetailView`,
  `ProjectHomeView`); `StartVisitForm` is the start-visit form's.
- `TransectMap`, `ProtocolSummary` and `TrackingStatusCard` moved into `ui/widgets/`. `trackingTime` moved with `TrackingMessages`,
  and the sync screen's operation label became `operationLabel` beside `entityTypeLabel` (`sync_error_message.dart`), since both
  cards use it.
Not taken: `part` files (they keep `_` names but split one library over files, which reads worse) and one folder per screen.

## D-065 · Butterfly observations: rules in `observations.services`, validation status on create only, first push delete, skeleton removed
2026-10 · accepted · T044, *builds on D-049, D-050, D-052, D-053, D-058, D-062*
**Services (`apps/observations/services.py`)** copy the shape of `surveys.services`: build or change the instance
(`build_new_observation`, `apply_observation_changes`), then `save_observation` (checks the table's constraints, so a broken rule is a
400 with a message, then `save_with_reason`). REST, push and admin call them.
- **Context (`_check_context`):** the project is live; the user is an admin or a member (else 403); the taxon is not soft-deleted
  (a *retired* taxon is allowed, D-043); a visit must be visible through `visits_for(user)` (so a researcher cannot add to someone
  else's visit), in the same project, and unlocked; the section must be live and on the visit's transect, or, with no visit, on a live
  transect of the project.
- **Recorder (`_check_recorder`):** a researcher records as themselves (the default when `recorded_by` is left out); an admin may name
  any project member or admin.
- **Lock (amends D-062's list):** `_lock_visit` loads the visit `FOR UPDATE` and calls `ensure_unlocked` first in update, delete and
  push delete. `guard_observation` is the push guard, so a stale update or delete of an observation of a locked visit is
  `visit_locked`, not a conflict. `project` and `survey_visit` cannot change (400 "Cannot be changed"); a changed section, taxon or
  recorder is checked again.
- **Admin:** `check_admin_edit` / `admin_save_observation` as for visits. No add; an observation of a locked visit opens read-only;
  `behaviour` is a checkbox field; the validation fields, `quality_flags`, project, visit and `photo_count` are read-only.
**`validation_status` is set on create only (decision 2026-10-28):** `pending` for confidence `photo_required`,
`expert_review_required`, `unknown` or `genus_only`, or when the taxon has `photo_required` (a new observation never has a photo yet);
else `not_required`. A value the client sends is never read (the sync serializer has no such field). A later PATCH of the confidence
or taxon does not recompute it, and neither does a photo arriving in T049: re-evaluation belongs to T055 (W01) and T057.
**Server-owned fields:** the sync serializer excludes `created_by`, `updated_by`, every `validation_*` field and `quality_flags`, so
push, REST POST and REST PATCH ignore them; the pull row has none of them either. `photo_count` is a computed output field
(`services.photo_count`, always 0 until T049, `TODO(T049)`); there is no column.
**First push `delete` and REST DELETE:** push delete uses `soft_delete_pushed` (D-053) and a second delete is `applied` again (D-050).
REST `DELETE /observations/{id}` is 204 with reason "REST API"; the row then leaves `observations_for`, so a second call is 404.
There is no list endpoint (outline 14).
**`contained_by` VERIFY:** Django 5.2 renders `models.Q(behaviour__contained_by=Behaviour.values)` in a `CheckConstraint` correctly,
as `CHECK ("behaviour" <@ (ARRAY['flying', ...])::varchar(20)[])`, so no `RunSQL`. The serializer maps the array to
`ListField(child=ChoiceField)` and `validate_behaviour` drops repeated values, keeping the order; the model field keeps `blank=True`,
or DRF would reject an empty list.
**Names:** index names are shortened (`butterfly_obs_*`, Django allows 30 characters); a GIN index on `quality_flags`, as on visits.
**Skeleton drop:** `core/0004_drop_skeleton_ping` drops the view `geo.skeleton_pings`, then the model; reversing recreates the view.
The pygeoapi `skeleton-pings` collection is removed in T044, not T068 (`resources: {}` until T068 adds the real ones; pygeoapi starts
and lists no collections). The `/skeleton/pings` endpoint, the Drift table, the debug screen and its route are gone.
`docs/architecture/skeleton-findings.md` stays as the historical record.
**App (schema v9):** `butterfly_observation` table (name equals the entity type), filled by pull; no entry UI until T045. `from8To9`
drops `skeleton_ping`, creates the table and clears the pull cursors (as `from5To6`), so observations the server sent before the
upgrade are pulled again. A locked visit's queued, never-sent observation changes are rejected like the visit's own (D-062). The
header's observation count reads the table (`watchObservationCount`). Not done: dropping a never-sent visit's observations on discard
(`TODO(T045)`), since rows exist only from T045.


## D-066 · Quick butterfly entry: stored `searchText`, a fix of its own when there is no live one, Undo is a sync `delete`
2026-10 · accepted · T045, *builds on D-063, D-064, D-065*
**Sheet:** Add butterfly opens `QuickButterflySheet` (`features/observations/`). A tile only selects, so a repeat species is open, tap, Save
(3 taps; T073 measures it). The count starts at 1 each time. Recent (last 8 used in the project) and Favourites show while the search is
empty. The sheet returns `(id, label)`, and the active visit screen shows "Saved: name × count" with Undo for 10 s (`persist: false`: in
Flutter 3.47 a snackbar with an action never closes by itself otherwise). Undo uses the repository captured before the sheet opened, so it
works after the screen is left.
**Search:** `taxon.searchText` is a **stored column** (as T019 specified), built on pull and backfilled by the v10 migration. It holds the
scientific, Serbian and English names lower-cased without diacritics (`search_text.dart`). **`đ` becomes `dj`**, so typing a plain "d" does
not find it. Taxa are filtered in memory on every key. Measured on the phone (debug build, 300 taxa): at most 0.46 ms, against the 100 ms
criterion. The picker lists taxa that are `active`, not retired and not deleted.
**Position:** the newest fix is used only when it is **live** (same visit, recording, not paused): `lastPosition` is kept during a pause, so a
paused "Record anyway" would otherwise store an old spot. Without a live fix, Save asks `currentPositionProvider` for one fix (up to 15 s,
then the last known position) behind a spinner, and stays open with the reason if that fails. The sheet cannot be closed while it waits.
**Section (decided with the developer):** with a live fix it is `currentSectionProvider`. With a fresh fix it is worked out from that fix
(`sectionAt`, extracted from the provider), not read from the tracker, whose position is stale or cleared in that case. Accuracy is rounded to
one decimal (`Decimal(6,1)` on the server). Confidence is `confirmed_in_field`, source `transect`, recorder the signed-in user.
**Undo:** a sync `delete`. A create the server never saw disappears with its queue item. A synced row is soft-deleted and a `delete` with
`baseVersion` is queued (shown on the phone, then in the server). The usage is recorded in the same transaction as the create, so Undo does
not roll back "recent". The sync screen's "Sync finished" snackbar replaces the Undo one: pressing Sync now within the 10 s loses the Undo.
**`taxon_usage`** is local only (no `SyncColumns`, no foreign keys): favourites are per device (ticket text).
**Discard (closes D-065's open point):** discarding a never-sent visit create also deletes the visit's observations and their queue items
(an observation cannot reach the server before its visit).
**Shown by hand** on the phone and with throwaway tests in `tmp/t045/` (not committed, D-021): the v9 to v10 migration and backfill, the
discard rule and the rounding. A Niš test project (`tmp/t045/seed_nis.py`, not committed) puts a transect under the developer's test spot.


## D-067 · Validation rules: pure rule modules called from `save_*`, rule IDs as messages, V06 split, zone on the protocol
2026-10 · accepted · T055, *builds on D-050, D-058, D-059, D-065, D-066; narrows the ticket text*
**Spec and code:** `docs/requirements/validation-rules.md` lists every rule (V01-V08, W01-W04, W06, W07; W05 is out of scope). The server rules
are pure functions in `observations/rules.py` and `surveys/rules.py` (no database, so `SimpleTestCase` runs them); the app has the same in
`lib/core/validation/` (`observation_rules.dart`, `visit_rules.dart`). Each rule is one small function with a `# V04`-style comment.
**Called from the services, not the serializers (narrows the ticket's "called by DRF serializers and the push service"):** REST, push and admin
all reach `save_observation` and `save_visit`, so the rules run there, before `validate_constraints()`. One place covers every caller.
**The message is the rule ID.** A violation is `ValidationError({"observed_at": ["V04"]})`, which `error_body` already turns into
`{"code": "validation_error", "fields": {...}}`; push stores the same body (D-050). The serializers the rules sit behind give the IDs too
(`count` `min_value` = V01, required `observed_at`/`geometry` = V02, `invalid_choice` = V07, `WritableGeoJSONField` `wrong_type`/`invalid` = V08;
`behaviour` is a plain list of strings checked in `validate_behaviour`, so a bad item is one `["V07"]` and not one error per index). The app's
`ruleMessages` map the IDs to sentences, and `syncErrorMessage` shows "Not accepted: <sentence> (<field>)."
**V03** accepts `in_progress`, `completed`, `synced` and `reviewed` (`synced` and `reviewed` are "completed" seen from the server: a phone that
pushes after the visit moved on must still be accepted). A locked visit is already `visit_locked` before the rule runs. A transect
observation with no visit is V03 as well.
**V04** applies to every observation that has a visit, whatever its source (the ticket text names no source).
**V06 is split.** The server enforces only "confirmed zero but has observations": it rejects a visit with `zero_observation_confirmed` that has
live transect observations, and a new or changed transect observation on such a visit. "Completed with 0 observations needs the tick" is in
Dart only (T041 calls it on Finish; the admin sees it at review, T043). Reason: a visit never sent before it was finished reaches the server as
one coalesced create with `status = completed` (D-051), ahead of its observations in the queue, so the server would see 0 and reject a good visit.
**W01** is the existing `validation_status = pending` on create (D-065); `initial_validation_status` calls the rule function. `photo_count` is
0 until T049. **W03/W04** fire on `oviposition` and on `life_stage = larva` and always will until T051 adds the host-plant link
(`TODO(T051)` on both sides); there is no UI for them yet (`TODO(T046)`, the quick entry cannot set behaviour or life stage). The server has
`visit_warnings` (W06, W07) for the spec and tests; no service calls it because warnings are not stored.
**Time zone (decided with the developer):** every stored time is UTC. Only the protocol's wall-clock settings (the daily window and the season
dates) need a zone, so `ProjectProtocol.time_zone` (an IANA name, validated with `zoneinfo`, default `Europe/Belgrade`, set per project in the
admin) holds the study site's zone and W07 on the server reads it. A project abroad picks its own. The **app still uses the phone's zone** for
W07, which is the site's zone while the researcher is there; reading the protocol's zone in the app needs a zone database (the `timezone`
package) and a Drift column: ticket T104. Existing protocol rows keep their `server_version`, so phones are not sent the new field
until a row changes; harmless while the app ignores it, to be checked by the ticket that reads it.
**App wiring:** `createQuick` and `VisitRepository._create`/`_update` run the rules and throw a `StateError` with the messages (today only
V07 can fire on a visit write, because the app cannot complete a visit before T040). `PositionLine` uses `isPoorAccuracy` (W02). The quick
sheet shows the W01 line for a photo-required species. `weather_check.dart` (W06) and `protocol_window.dart` (W07) moved from the visits and
transects domains to `core/validation/` (`git mv`), and the visit codelists (statuses, cancel reasons, precipitation) moved there too (`visit_values.dart`), so nothing in `core/validation` imports from `features/`.
**`mark_reviewed` and locking now go through V05** (they save through `save_visit`): an old visit without end weather and without a reason gets
a field error in the admin. Intended.
**Tests (an exception to D-021, as D-058, asked for by the ticket):** `observations/tests.py` and `surveys/tests.py` (`SimpleTestCase`, 37
tests), `test/validation/*` and `test/sync_error_message_test.dart` (plain Dart, no Drift; `flutter test`, 50 in all).


## D-068 · Finish visit: pause list, track point count, coverage and gaps on the phone
2026-10 · accepted · T040, *builds on D-051, D-060, D-061, D-062, D-063, D-064, D-066, D-067*
**Two new `survey_visit` fields (decided with the developer), sent by the phone.** `pauses` (server `JSONField`, Drift text column, default
`[]`) is the list of `{"started_at", "ended_at"}` in UTC. `VisitRepository.resume` appends the pause it closes and sends `pauses` in the same
`update` as `paused_seconds`; Finish does the same for a pause still running. It closes D-063's "only the total paused time is stored" point
for T038, T040 and T056: the Finish screen leaves pauses out of the GPS-gap warning, and T056's `gps_gap` ("outside pauses") reads the same
list. `track_point_count` (nullable integer) is how many points the phone recorded, sent on Finish; it closes D-062's "T040 sends the count",
and T043's Lock compares it with the points the server has. Null for a visit finished before T040 or through REST.
**`validate_pauses`** (sync serializer, so push and REST): a list of at most 500 dicts with exactly `started_at` and `ended_at`, both ISO 8601
with a UTC offset, `ended_at` not before `started_at`. They are stored as UTC strings with a `Z`. A bad value is a 400 with `fields.pauses`.
Both fields are read-only in the admin (`fixed_fields`). A stale update carrying `pauses` merges with a server edit (`_merge` compares the
lists as JSON; checked in `tmp/t040/smoke.py`). Drift is at schema 11; no cursor reset, the defaults agree with the server's.
**Finish order:** (1) `VisitRepository.checkCanFinish` runs the V05/V06/V07 rules without writing and without touching the tracker; a
`VisitRuleError` (field to rule IDs) is worded for the observer by the screen; (2) when this phone recorded the route,
`TrackingController.stop()` flushes the buffer; (3) `VisitRepository.finish` closes a running pause (`closePause`, shared with Resume),
works out `duration_seconds` (never below 0), counts the points and sums the distance, checks the same rules again, and queues one `update`
with only the fields that changed; (4) a sync starts without waiting; (5) go to the transect detail with "Visit saved". **If the save is
refused after the tracker was stopped** (an admin's lock or a cancel arrived by a pull in those seconds), `TrackingController.restart()` starts
tracking again; it does nothing when the visit is no longer in progress.
**Count and distance only from the recording phone:** `finish` sends `track_point_count` and `distance_walked_m` (one decimal, the server's
`Decimal(8,1)`) only when the visit's `deviceId` is this phone's. A visit walked on another phone has no points here; the Finish screen then
shows "The route was recorded on another phone." instead of coverage and gaps. The screen decides this from `deviceVisitInProgressProvider`.
**Coverage** is defined in `protocol.md` §6 (samples every 10 m plus the end point, usable point within the limit, fewer than 2 usable points
gives none), in `route_coverage.dart`, and is only a warning. The accuracy rule is `isUsablePoint`, extracted from `routeLengthM`.
**GPS gaps** (`gps_gaps.dart`): for each pair of consecutive points (all points, recorded order) the time between them minus its overlap with
the pauses; a gap when that is more than `gps_gap_s`. The stretch from the last point to now is checked as well (`trailingGpsGap`), with a
pause still running counted as a pause; it is worked out on each build because it moves with the clock. The screen lists at most 5 and counts
the rest. The slow parts (distance, coverage, the pair gaps) are `RouteStats`, worked out once per route and not on every keystroke.
`parsePauses` skips a bad item instead of returning an empty list, because the list is sent back on Resume and Finish.
**True zero moved here from T041:** with 0 live `source = transect` observations the screen shows T041's checkbox ("No butterfly was seen
during the complete standardised visit.") and sets `zero_observation_confirmed`; without it rule V06 (Dart) blocks Finish. T041 keeps the
cancel reasons, the export outcome and its tests. **Cancel visit** is a placeholder until T041 (`TODO(T041)`).
**Moved out of the start form** so both screens use them, without changing the start form: `temperatureFormatter` and `parseTemperature`
(`ui/temperature_input.dart`) and the Beaufort sheet (`ui/widgets/wind_picker_sheet.dart`). Cloud cover starts at 0 % (D-063);
precipitation is one column for the whole visit and is not asked again.
**Warnings** (none blocks): end weather missing or outside the protocol (V05/W06 for the end values only), coverage, GPS gaps, outside the
season or the daily window (for `startedAt`), and observations a hard rule would refuse today (`ObservationInput.fromObservation`,
`visitStatus: 'completed'`). Coverage and gaps read the stored points, which lag the live position by up to 30 s (D-061).
**Checked without the UI** (the developer runs the phone steps, `tmp/t040/UI_TESTS.md`): `tmp/t040/smoke.py` (push with both fields, a bad
`pauses`, a coalesced completed create, the admin page) and throwaway Dart tests in `tmp/t040/mobile_tests/` (the v10 to v11 migration,
coverage and gaps cases, the pauses round trip). Not committed (D-021).

## D-069 · Cancel flow: V09, observations of an aborted visit kept, outcome from the flag, "not conducted" from the start form
2026-10 · accepted · T041, *builds on D-051, D-054, D-067, D-068*
**Four reasons, two groups (decided with the developer).** `not_conducted` is for a visit that was never started, `aborted_weather`,
`aborted_other` and `invalid_protocol` for one that was. New hard rule **V09**: `cancel_reason = not_conducted` exactly when `started_at`
is empty (error on `cancel_reason`). It reads `started_at`, not the previous status, because `steps_between` takes a visit that was created
offline and cancelled from draft straight to `cancelled`, even if it was started. The app offers only the fitting reasons
(`startedCancelReasons`); the server rejects a mismatch. `surveys.services.check_admin_edit` now runs the visit rules too, so an admin edit
that breaks V05, V06 or V09 is a form error and not an exception from `save_visit` after the form. In the admin the rule ID is never
shown: `core.admin.add_validation_errors` replaces it with a sentence and marks an editable field in red (V09 marks *Started at*, because
*Cancel reason* is read-only there). The visit admin and the observation admin both use it; the sentences are in each `admin.py`.
**Observations of an aborted visit are kept.** V03 (both sides) also accepts a transect observation on a `cancelled` visit with a
`started_at`. Without it, a visit aborted offline loses its butterflies at sync: the coalesced create (`cancelled`) reaches the server
before the observation creates (D-051). A not-conducted visit still takes none. The quick entry stays in-progress only (D-066). The visit
is not a valid visit (protocol §6), but its records stay in species lists and exports.
**Outcome from the flag.** `SurveyVisit.outcome` is `true_zero` or `completed_with_records` from `zero_observation_confirmed`, not from a
count: the app enforces V06 both ways on Finish (D-067) and an export costs no query per row. Cancelled gives `cancelled:<reason>`, a draft
or a visit in progress `""`. T064 puts it in the exports; the admin shows it as a read-only column and field.
**The note is the `notes` field** (no new column, no migration). The sheet starts with the visit's notes and `notes` is sent only when it
changed (D-054).
**Not conducted is recorded from the start-visit form** ("Not conducted…" in the app bar), with or without a saved draft: no draft creates
a `cancelled` visit with no `started_at` and the default values (the form's weather is not stored, the walk did not happen); a draft is
cancelled and keeps its stored values. No tracking permission is asked. The transect's "My visits" list now also lists cancelled visits
without a `started_at`, dated by `created_at` (`watchListedVisits`).
**One end-of-walk calculation.** `VisitRepository._endOfWalk` (closed pause, `duration_seconds`, and when recorded here the track point count
and distance) is shared by `finish` and `cancel`; `finish` behaves as before. `cancel` leaves the end weather and the true-zero flag alone,
and the Finish screen stops the tracker first, as for Finish.
