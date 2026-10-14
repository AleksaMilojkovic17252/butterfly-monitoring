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

## D-020 · GitHub Issues are the ticket source of truth
2026-10-14 · accepted · repo setup
`docs/TICKETS.md` is generated from the issues by `scripts/tickets_index.py`. Status is the issue's
state plus an `in-progress` label. Issues close when their PR merges.
