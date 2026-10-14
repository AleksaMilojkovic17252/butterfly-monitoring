# Project outline

Summary and scope of the butterfly monitoring system. The full original specification is
[reference/development-plan.md](reference/development-plan.md) (headings in English, body mostly
Serbian). Where it conflicts with the decisions below, the decisions win (feature list v4, frozen
12 October 2026; see [DECISIONS.md](DECISIONS.md)).

## What it is

An interoperable mobile GIS system for biologists who run standardised field surveys of day-flying
butterflies. It supports:

- standardised transect surveys (Pollard walk) with visit metadata, effort and weather
- individual butterfly records: count, sex, life stage, behaviour, identification confidence, photos
- mapping host plants, nectar plants and habitat features
- linking records to weather and microclimate data (Phase 2)
- working without a connection and syncing later to a central server
- viewing records on a map with basic indicators
- exporting data for R, Python and QGIS, and publishing it through OGC services

The thesis presents this as building and evaluating a system based on OGC standards, not as
implementing every standard from scratch.

**Thesis titles (outline §2):** *Razvoj interoperabilne mobilne GIS aplikacije za standardizovano
praćenje dnevnih leptira, njihovih staništa i uslova sredine primenom OGC standarda.*

## Goals

Build and test a mobile GIS system for collecting, storing, exchanging, displaying and analysing data
on butterfly distribution, abundance, phenology, behaviour, habitat, host and nectar plants, weather
and field effort (outline §3). The system should let two or three of the outline's biological
research questions (§4) be demonstrated, for example how species richness differs between habitat
types, or whether specialist species track their host plants. Question 7, how reliably mobile data
can be standardised, synced and exchanged through OGC services, is the technical core.

## Users and roles

| Role | Does |
|---|---|
| `researcher` | Uses the app only: downloads projects and transects, runs visits, records data offline, syncs, sees own data. Member of specific projects. |
| `admin` | Everything a researcher does, plus Django admin: creates projects and adds members, edits transects and catalogues, validates records, resolves sync conflicts, locks/unlocks visits, exports, uses pygeoapi. |

Two roles only (the outline's coordinator and expert-validator roles are folded into `admin`).

## Scope

### Phase 1: thesis Part 1 (target: February 2027)

MVP from outline §5.1, as tickets T001–T075:

1. Users, JWT login, two roles, projects with membership, audit history
2. Taxon and plant catalogues (Serbian butterfly list from GBIF, curated plant list), codelists
3. Transects and sections drawn in Django admin; per-project protocol settings and study area
4. Offline package download; Drift local database; sync queue; idempotent push/pull; conflict detection with resolution in Django admin
5. Field visit: start form, 7-status lifecycle, background GPS tracking (Android foreground service), pause/finish, true-zero confirmation, visit locking
6. Butterfly observations (quick and extended entry, incidental records, photos, automatic section assignment)
7. Host/nectar plants and habitat features (Should)
8. Input validation, quality flags, validation queue and history
9. App map, indicators, manual environmental snapshot, CSV/GeoJSON/JSON export (GeoPackage: Could)
10. OGC API – Features through pygeoapi, read-only, admin-only via token or Basic auth; QGIS interoperability test
11. Simulated field days, GPS replay, evaluation instrumentation, performance/sync/battery tests, usability session with one biologist

### Phase 2: thesis Part 2 (after February)

Tickets T076–T097. Each standard starts with a short study ticket.

- **OGC SensorThings API:** FROST-Server (own database), simulated microclimate stations, snapshots attached to visits
- **OGC API – EDR:** weather for a visit's place and time; optional auto-fill in the app
- **OGC API – Moving Features + MobilityDB:** focal-follow tracks stored as `tgeompoint`, served as MF-JSON, displayed in the app
- **Evaluation:** conformance and interoperability tests, PostGIS vs MobilityDB comparison, standards write-up

### Out of scope

Removed in v4 (no tickets): sensitive-location generalisation (F5), Darwin Core export (F38), OGC
transactions (F42), MQTT (F51), along-transect EDR (F54), sync monitoring (F65), photo privacy/EXIF
stripping (F75), in-app validation status (F76), error monitoring (F81), deployment/CD (F82), mobile
release process (F83), a live pilot (F84), documentation as tickets (F85), device model (F86),
biometric unlock (F88). The outline itself excludes species recognition from photos, a public
portal, an advanced dashboard, ML and a national system. No iOS. No real sensors.

## Constraints

- One developer, about 60 development days before February; the Must list is larger than that.
  Pace is measured after Stage 2a and cut lines apply (roadmap issue #2, D.3–D.4).
- The developer's laptop (CachyOS) is the only server. No VPS, no production deployment.
- Field season is over until spring, so evaluation runs on simulated field days plus one biologist.
- MinIO community images are no longer published; the last official image is pinned (CONVENTIONS.md A.3).

## Where to find more

- Tickets and build order: [TICKETS.md](TICKETS.md), GitHub issues #2 (roadmap) and #3–#17 (epics)
- Conventions: [CONVENTIONS.md](CONVENTIONS.md) (issue #1)
- Data model: outline §8 and the "Database" section of each model ticket
- Field protocol: outline §7, and `docs/requirements/` once T001 is done
