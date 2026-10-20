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
`device_id`, `mutations` not a list, more than 1000). Items are validated one by one, so a malformed item is rejected, not a
reason to fail the batch. `client_created_at` needs a UTC offset (`core.serializers.UTCDateTimeField`); handlers must do the
same for datetimes in their payloads.
`services.push` is one `transaction.atomic(durable=True)` with a savepoint per mutation. Errors are caught outside the inner
`atomic()` (Django needs that to keep the outer transaction usable): DRF `APIException`, `Http404`, Django
`PermissionDenied` and `ValidationError`, `IntegrityError` (`integrity_error`). **Any other exception propagates**, so the
whole batch rolls back with a 500 and the phone retries later; a bug shows in the logs and is not stored as a rejection.
A per-user advisory lock (`pg_advisory_xact_lock(727275, hashtext(user id))`, two-key form so it never meets the global lock
727274 of D-029) makes a retry of a still-running batch wait and then see `duplicate`, instead of applying everything twice.
`sync_mutation` stores `applied` and `rejected` (also `merged`/`conflict` for T027); `duplicate` exists only in responses
(the stored result with the status replaced). Malformed items and a `mutation_id` that belongs to another user
(`mutation_id_taken`, never leaks the other result) are not stored. `prune_sync_mutations --older-than 180d` deletes old rows.
**Handler slot:** `SyncEntity.push: PushHandlers | None` (`apps/sync/handlers.py`, a leaf module that imports only `core`, so
app services can import it). The framework has checked the shape, deduplicated, removed server-owned fields, turned a create
of an existing id into an update, loaded the row `FOR UPDATE`, checked ownership (`created_by` or admin) and `base_version`.
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
Shown by hand with `tmp/t026/smoke.py` and temporary handlers (no type the phone writes exists yet; D-021): savepoints and
order, resending a batch, concurrent retry from two threads, 1000-row batches, ownership, history reason, server-owned
fields. 500 updates took about 3.3 s on the laptop; the real measurement is T074.
