# Tickets

Ticket list for Claude Code, generated once from the GitHub issues on 2026-10-14. The issue text
stays on GitHub (ticket `Tnnn` is issue #(nnn + 17), epic `Enn` is issue #(nn + 2); conventions in
issue #1 and [CONVENTIONS.md](CONVENTIONS.md), roadmap and cut lines in issue #2).

**This file is the status tracker.** `/next-ticket` and `/finish-ticket` update the Status column
and the status in each ticket's heading line. Statuses:

- `todo`: not started
- `in progress`: being worked on
- `done`: finished and merged into `main`
- `dropped`: not doing it (T008 CI is dropped: no tests or CI for now, see DECISIONS.md D-021)

A ticket is **ready** when it is `todo` and every ticket in its "Depends on" column is `done` or
`dropped`. Notes in parentheses under a ticket (for example "added when T051 is done") do not block.

## Build order

Work tickets in this order (roadmap issue #2, D.2). `/next-ticket` picks the first ready ticket in this list. Phase 1 is the February target; Phase 2 comes after.

- **1 · Foundations:** T001, T002, T003, T006, T004, T005, T009, T007, T008, T010
- **2a · Accounts and projects:** T011, T013, T014, T012, T015, T016, T018, T017
- **2b · Catalogues and transects:** T019, T020, T021, T022, T024
- **3 · Sync core:** T025, T026, T029, T030, T027, T028, T031, T032
- **4 · Field visit and observations:** T033, T034, T035, T036, T037, T042, T039, T044, T045, T055, T040, T041, T043, T038
- **5 · Photos, environment, export, OGC:** T049, T050, T063, T064, T067, T068, T069, T059
- **6 · Simulation and evaluation:** T071, T072, T070, T073, T074, T075
- **P1 Should/Could fill (only if the velocity checkpoint allows):** T046, T048, T051, T052, T053, T054, T058, T057, T056, T047, T061, T062, T065, T023, T060, T066
- **7 · SensorThings (Phase 2):** T076, T077, T078, T079, T081, T080
- **8 · EDR (Phase 2):** T082, T083, T084, T085
- **9 · Moving Features + MobilityDB (Phase 2):** T086, T087, T089, T088, T090, T092, T091, T093, T094
- **10 · Evaluation (Phase 2):** T095, T096, T097

## Index

| ID | Issue | Title | Phase | Priority | Depends on | Est. | Status |
|---|---|---|---|---|---|---|---|
| T001 | [#18](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/18) | Requirements baseline: protocol, mandatory fields, codelists, ER diagram | P1 | must | — | 2 d | done |
| T002 | [#19](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/19) | Monorepo layout and Docker Compose stack | P1 | must | — | 2 d | done |
| T003 | [#20](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/20) | Django project bootstrap | P1 | must | T002 | 1.5 d | done |
| T004 | [#21](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/21) | Database schema strategy: `geo` schema and read-only role | P1 | must | T003 | 1 d | todo |
| T005 | [#22](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/22) | Syncable base model and server-version trigger | P1 | must | T004 | 1.5 d | todo |
| T006 | [#23](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/23) | Flutter app foundation | P1 | must | — | 2 d | todo |
| T007 | [#24](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/24) | Walking skeleton: one observation from phone to QGIS | P1 | must | T002, T003, T004, T005, T006 | 3 d | todo |
| T008 | [#25](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/25) | CI pipeline (GitHub Actions) | P1 | must | T003, T006 | 1 d | dropped |
| T009 | [#26](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/26) | Phone-to-laptop connectivity: Tailscale and USB | P1 | must | T002, T006 | 1 d | todo |
| T010 | [#27](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/27) | Backup and restore scripts | P1 | must | T002 | 1 d | todo |
| T011 | [#28](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/28) | Custom user model and JWT auth endpoints | P1 | must | T003 | 1.5 d | todo |
| T012 | [#29](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/29) | App login, secure token storage, refresh and logout | P1 | must | T006, T011 | 2 d | todo |
| T013 | [#30](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/30) | Two roles: groups, permissions and access rules | P1 | must | T011 | 1.5 d | todo |
| T014 | [#31](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/31) | Django admin foundation | P1 | must | T013 | 1 d | todo |
| T015 | [#32](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/32) | Project and membership models, API and admin | P1 | must | T005, T013, T014 | 2 d | todo |
| T016 | [#33](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/33) | Project protocol settings and study area | P1 | must | T001, T015 | 1.5 d | todo |
| T017 | [#34](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/34) | App project list and project home | P1 | must | T012, T015 | 1.5 d | todo |
| T018 | [#35](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/35) | Audit log with django-simple-history | P1 | must | T015 | 1.5 d | todo |
| T019 | [#36](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/36) | Taxon catalogue, versioned | P1 | must | T005, T015 | 2 d | todo |
| T020 | [#37](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/37) | Plant taxa and editable codelists | P1 | must | T005 | 1.5 d | todo |
| T021 | [#38](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/38) | Transect and section models and API | P1 | must | T015, T020 | 2 d | todo |
| T022 | [#39](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/39) | Map-based transect and section editor in admin | P1 | must | T014, T021 | 2 d | todo |
| T023 | [#40](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/40) | Catalogue admin tools | P1 | should | T019, T020 | 1.5 d | todo |
| T024 | [#41](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/41) | Seed data: butterflies of Serbia, plant list, codelists, demo project | P1 | must | T019, T020, T021 | 2 d | todo |
| T025 | [#42](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/42) | Pull API with server-version cursor | P1 | must | T005, T015, T019, T020, T021 | 2 d | todo |
| T026 | [#43](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/43) | Push API with idempotent mutations | P1 | must | T025 | 2.5 d | todo |
| T027 | [#44](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/44) | Conflict detection and SyncConflict model | P1 | must | T018, T026 | 2 d | todo |
| T028 | [#45](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/45) | Django admin conflict resolution screen | P1 | must | T014, T027 | 1.5 d | todo |
| T029 | [#46](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/46) | App sync queue | P1 | must | T006 | 1.5 d | todo |
| T030 | [#47](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/47) | App sync runner: push, pull, retry and backoff | P1 | must | T025, T026, T029 | 2.5 d | todo |
| T031 | [#48](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/48) | App offline package download and status | P1 | must | T030 | 1.5 d | todo |
| T032 | [#49](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/49) | App sync status screen | P1 | must | T030 | 1.5 d | todo |
| T033 | [#50](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/50) | App transect list and transect detail | P1 | must | T017, T021, T031 | 2 d | todo |
| T034 | [#51](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/51) | SurveyVisit model, lifecycle and API | P1 | must | T021, T026 | 2.5 d | todo |
| T035 | [#52](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/52) | App start-visit form | P1 | must | T016, T033, T034 | 1.5 d | todo |
| T036 | [#53](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/53) | Track points: model, batch sync and walked distance | P1 | must | T026, T034 | 1.5 d | todo |
| T037 | [#54](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/54) | App GPS tracking with an Android foreground service | P1 | must | T035, T036 | 3 d | todo |
| T038 | [#55](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/55) | Battery-saving mode and GPS gap detection | P1 | must | T037 | 1 d | todo |
| T039 | [#56](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/56) | App active visit screen | P1 | must | T037 | 2.5 d | todo |
| T040 | [#57](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/57) | Finish visit: summary, warnings and end weather | P1 | must | T039, T055 | 2 d | todo |
| T041 | [#58](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/58) | True-zero confirmation and cancelled-visit reasons | P1 | must | T040 | 1 d | todo |
| T042 | [#59](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/59) | Visit lock enforced in the API | P1 | must | T026, T034 | 1 d | todo |
| T043 | [#60](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/60) | Admin visit review, lock and unlock with mandatory reason | P1 | must | T018, T042 | 1.5 d | todo |
| T044 | [#61](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/61) | ButterflyObservation model and API | P1 | must | T019, T026, T034 | 2.5 d | todo |
| T045 | [#62](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/62) | App quick butterfly entry | P1 | must | T039, T044 | 2.5 d | todo |
| T046 | [#63](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/63) | App extended entry | P1 | should | T045 | 1.5 d | todo |
| T047 | [#64](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/64) | Incidental and other-source observations | P1 | should | T045 | 1 d | todo |
| T048 | [#65](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/65) | Automatic section assignment | P1 | should | T044 | 1 d | todo |
| T049 | [#66](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/66) | Photo model and upload API with SHA-256 deduplication | P1 | must | T003, T044 | 2.5 d | todo |
| T050 | [#67](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/67) | App photo capture, compression and upload | P1 | must | T030, T045, T049 | 2.5 d | todo |
| T051 | [#68](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/68) | PlantResourceObservation model and API | P1 | should | T020, T044, T049 | 1.5 d | todo |
| T052 | [#69](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/69) | App plant entry with point and polygon drawing | P1 | should | T050, T051 | 2.5 d | todo |
| T053 | [#70](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/70) | HabitatFeature model and API | P1 | should | T020, T026 | 1.5 d | todo |
| T054 | [#71](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/71) | App habitat feature entry | P1 | should | T052, T053 | 1.5 d | todo |
| T055 | [#72](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/72) | Input validation rules (shared by app and server) | P1 | must | T016, T034, T044 | 2 d | todo |
| T056 | [#73](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/73) | Automatic quality flags | P1 | should | T036, T048, T055 | 1.5 d | todo |
| T057 | [#74](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/74) | Admin validation queue | P1 | should | T014, T049, T058 | 2 d | todo |
| T058 | [#75](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/75) | Validation history | P1 | should | T044 | 1 d | todo |
| T059 | [#76](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/76) | App map screen with layers and filters | P1 | must | T036, T044 | 2.5 d | todo |
| T060 | [#77](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/77) | Offline basemap from MBTiles | P1 | could | T031, T059 | 2 d | todo |
| T061 | [#78](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/78) | Indicators: server SQL views and admin report | P1 | should | T041, T044, T058 | 1.5 d | todo |
| T062 | [#79](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/79) | App statistics screen | P1 | should | T041, T044 | 1.5 d | todo |
| T063 | [#80](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/80) | EnvironmentalSnapshot model with manual source | P1 | must | T034, T044 | 1 d | todo |
| T064 | [#81](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/81) | Export service and admin-only export API | P1 | must | T044, T063 | 2.5 d | todo |
| T065 | [#82](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/82) | Admin export actions | P1 | should | T064 | 1 d | todo |
| T066 | [#83](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/83) | GeoPackage export | P1 | could | T064, T067 | 1 d | todo |
| T067 | [#84](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/84) | `geo` views for the five collections | P1 | must | T004, T021, T044 | 2 d | todo |
| T068 | [#85](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/85) | pygeoapi collections, filtering and paging | P1 | must | T007, T067 | 1.5 d | todo |
| T069 | [#86](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/86) | Token-protected pygeoapi access for admins | P1 | must | T011, T013, T068 | 1.5 d | todo |
| T070 | [#87](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/87) | QGIS interoperability and OGC conformance test | P1 | must | T069, T071 | 1.5 d | todo |
| T071 | [#88](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/88) | Simulated field-day generator | P1 | must | T024, T026, T036, T044, T049 | 2.5 d | todo |
| T072 | [#89](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/89) | GPS replay in the app | P1 | must | T037 | 1.5 d | todo |
| T073 | [#90](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/90) | Evaluation instrumentation in the app | P1 | must | T035, T045 | 1.5 d | todo |
| T074 | [#91](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/91) | Performance, sync robustness and battery tests | P1 | must | T030, T059, T071, T072 | 2 d | todo |
| T075 | [#92](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/92) | Usability kit and Part 1 evaluation run | P1 | must | T070, T073, T074 | 2 d | todo |
| T076 | [#93](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/93) | Standards study: SensorThings API | P2 | must | — | 1 d | todo |
| T077 | [#94](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/94) | FROST-Server deployment | P2 | must | T002, T069, T076 | 1.5 d | todo |
| T078 | [#95](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/95) | Sensor station links and registration in FROST from Django admin | P2 | must | T021, T077 | 2 d | todo |
| T079 | [#96](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/96) | Sensor data simulator | P2 | must | T071, T078 | 2.5 d | todo |
| T080 | [#97](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/97) | Station map layer and OGC collections | P2 | should | T068, T078, T079 | 1.5 d | todo |
| T081 | [#98](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/98) | Environmental snapshots from SensorThings | P2 | must | T063, T079 | 2 d | todo |
| T082 | [#99](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/99) | Standards study: OGC API – EDR | P2 | must | — | 1 d | todo |
| T083 | [#100](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/100) | EDR collections in pygeoapi | P2 | must | T068, T079, T082 | 2 d | todo |
| T084 | [#101](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/101) | Weather for a visit via EDR | P2 | must | T081, T083 | 1.5 d | todo |
| T085 | [#102](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/102) | Weather auto-fill in the app | P2 | should | T035, T084 | 1.5 d | todo |
| T086 | [#103](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/103) | Standards study: OGC API – Moving Features | P2 | must | — | 1 d | todo |
| T087 | [#104](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/104) | MobilityDB research and design spike | P2 | must | T071, T086 | 2 d (time-boxed) | todo |
| T088 | [#105](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/105) | Enable MobilityDB and trajectory storage | P2 | must | T087, T089 | 2 d | todo |
| T089 | [#106](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/106) | Focal-follow data model and sync | P2 | must | T026, T044, T087 | 2 d | todo |
| T090 | [#107](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/107) | App focal-follow session | P2 | must | T037, T045, T089 | 2.5 d | todo |
| T091 | [#108](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/108) | Behaviour events on trajectories | P2 | should | T053, T088, T089 | 1.5 d | todo |
| T092 | [#109](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/109) | Moving Features API: service and collections | P2 | must | T087, T088 | 2 d | todo |
| T093 | [#110](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/110) | Moving Features API: temporal geometry and properties | P2 | must | T092 | 1.5 d | todo |
| T094 | [#111](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/111) | Trajectory display | P2 | must | T090, T093 | 2 d | todo |
| T095 | [#112](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/112) | Interoperability and conformance evaluation of SensorThings, EDR and Moving Features | P2 | must | T083, T094 | 2 d | todo |
| T096 | [#113](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/113) | PostGIS vs MobilityDB comparison | P2 | should | T087, T088, T091 | 1.5 d | todo |
| T097 | [#114](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/114) | Standards comparison write-up | P2 | must | T095 | 1 d | todo |

## Acceptance criteria

### T001 · Requirements baseline: protocol, mandatory fields, codelists, ER diagram
[#18](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/18) · E01 · P1 · must · labels: `docs`, `must` · implements F77 · est. 2 d · **done**

Note: the Mermaid diagram was not rendered here (no Mermaid tooling); the paper field day was drafted with the developer, not run with real data.

Depends on: —

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

### T002 · Monorepo layout and Docker Compose stack
[#19](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/19) · E01 · P1 · must · labels: `infra`, `must` · implements F44 · est. 2 d · **done**

Depends on: —

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

### T003 · Django project bootstrap
[#20](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/20) · E01 · P1 · must · labels: `backend`, `must` · implements F44, F46 · est. 1.5 d · **done**

Note: skipped the pytest and storage-test criterion (D-021). `accounts.User` and its initial migration were pulled forward from T011 so `AUTH_USER_MODEL` works from the first migration.

Depends on: T002

- [ ] Apps exist (empty where not yet used): `core`, `accounts`, `projects`, `catalogues`, `transects`, `surveys`, `observations`, `resources`, `sync`, `validation`, `exports`, `environment`, `reports`.
- [ ] `DATABASES` uses `django.contrib.gis.db.backends.postgis`, and `AUTH_USER_MODEL = "accounts.User"` is set **before the first migration** (see T011).
- [ ] `STORAGES["default"]` is the django-storages S3 backend pointing at MinIO (`AWS_S3_ENDPOINT_URL=http://minio:9000`, bucket `photos`, `AWS_S3_ADDRESSING_STYLE="path"`). A test uploads and deletes a file.
- [ ] `/api/v1/schema/` returns OpenAPI 3, and `/api/v1/docs/` serves Swagger UI.
- [ ] `GET /api/v1/health/` returns `{"status":"ok","db":true,"storage":true}`.
- [ ] pytest + pytest-django run against a test database. `python manage.py makemigrations --check` passes.

### T004 · Database schema strategy: `geo` schema and read-only role
[#21](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/21) · E01 · P1 · must · labels: `database`, `must`, `p2-compat` · implements F45 · est. 1 d · **todo**

Depends on: T003

- [ ] Migration `core/0001_schemas` creates the `geo` schema owned by `django_app` and grants `USAGE ON SCHEMA geo TO pygeoapi_ro`.
- [ ] `ALTER DEFAULT PRIVILEGES FOR ROLE django_app IN SCHEMA geo GRANT SELECT ON TABLES TO pygeoapi_ro;` makes every future view readable automatically.
- [ ] `pygeoapi_ro` has **no** privileges on `public` tables. A test connects as `pygeoapi_ro` and gets `permission denied` on `SELECT * FROM public.app_user`.
- [ ] `core/migration_ops.py` provides `CreateView(name, sql)`, a `RunSQL` wrapper with reverse `DROP VIEW`, used by T067.
- [ ] `docs/architecture/database.md` explains the layout (A.5 item 1) and why the outline's `app`/`audit`/`sensorthings`/`mobility` schemas are not used in Phase 1.

### T005 · Syncable base model and server-version trigger
[#22](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/22) · E01 · P1 · must · labels: `backend`, `database`, `sync`, `must` · implements F25, F45 · est. 1.5 d · **todo**

Depends on: T004

- [ ] `core.models.SyncableModel` (abstract) exists with the fields below. `SyncableQuerySet.alive()` excludes soft-deleted rows.
- [ ] Migration `core/0002_sync_version` creates the sequence and trigger function. `AttachSyncTrigger(table)` is a reusable migration operation used by every model ticket.
- [ ] Insert and update both bump `server_version`, including `QuerySet.update()` and admin saves (tested).
- [ ] Two concurrent transactions writing to synced tables commit their versions in order (test with two connections: the second blocks until the first commits).
- [ ] Hard delete is disabled for synced models in services and admin. `soft_delete()` sets `deleted_at` instead.

### T006 · Flutter app foundation
[#23](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/23) · E01 · P1 · must · labels: `mobile`, `must` · implements F23, F72 · est. 2 d · **todo**

Depends on: —

- [ ] `mobile/` is Android-only (`flutter create --platforms=android`). Package id: `rs.<you>.butterfly` (choose).
- [ ] Folders: `lib/core/` (config, http, db, location), `lib/features/<feature>/` (data, domain, ui), `lib/app.dart`.
- [ ] Riverpod for state, go_router for navigation, dio for HTTP. Logging uses `logger` in debug only.
- [ ] `AppDatabase` (Drift) opens `butterfly.sqlite` with `schemaVersion = 1` and a migration strategy using `drift_dev make-migrations` (schema snapshots committed under `mobile/drift_schemas/`).
- [ ] Settings screen: server URL with presets **Tailscale** (`https://<laptop>.<tailnet>.ts.net`) and **USB** (`http://localhost:8080`), plus a "Test connection" button calling `/api/v1/health/`.
- [ ] `build.yaml` sets `store_date_time_values_as_text: true`.
- [ ] `flutter analyze` is clean, and one widget test runs.

### T007 · Walking skeleton: one observation from phone to QGIS
[#24](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/24) · E01 · P1 · must · labels: `backend`, `mobile`, `ogc`, `must` · implements F78 · est. 3 d · **todo**

Depends on: T002, T003, T004, T005, T006

- [ ] The app has a debug-only screen with a "Drop ping" button that stores the current GPS position plus time in Drift, works in airplane mode, and has a "Send" button that POSTs pending pings.
- [ ] `POST /api/v1/skeleton/pings` accepts `{id, observed_at, lat, lon, note}` and is idempotent: posting the same `id` twice gives one row.
- [ ] View `geo.skeleton_pings` exists. pygeoapi collection `skeleton-pings` returns it at `/ogc/collections/skeleton-pings/items?f=json`.
- [ ] QGIS on the laptop loads the collection as an OGC API – Features layer.
- [ ] This runs over **Tailscale** from the real phone at least once (T009 can run in parallel; USB is fine for the first pass).
- [ ] Findings are written in `docs/architecture/skeleton-findings.md`, including **VERIFY results**: pygeoapi reads a view (yes/no), `id_field` with uuid works, and whether a `time_field` on a view works.

### T008 · CI pipeline (GitHub Actions)
[#25](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/25) · E01 · P1 · must · labels: `infra`, `must` · implements F46 · est. 1 d · **dropped**

Depends on: T003, T006

- [ ] Workflow `backend.yml`:
  - service container `mobilitydb/mobilitydb:17-3.5-1.3`
  - installs GDAL
  - runs `ruff check`, `pytest`, `python manage.py makemigrations --check`, and `python manage.py spectacular --validate --file /tmp/schema.yaml`
- [ ] Workflow `mobile.yml`: `flutter analyze`, `flutter test`, `dart run drift_dev schema verify` (or equivalent migration test), `flutter build apk --debug`. The APK is uploaded as a workflow artifact.
- [ ] Both workflows use path filters (`backend/**`, `mobile/**`).
- [ ] A status badge is in the README.

### T009 · Phone-to-laptop connectivity: Tailscale and USB
[#26](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/26) · E01 · P1 · must · labels: `infra`, `mobile`, `must` · implements F44 · est. 1 d · **todo**

Depends on: T002, T006

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

### T010 · Backup and restore scripts
[#27](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/27) · E01 · P1 · must · labels: `infra`, `must` · implements F46 · est. 1 d · **todo**

Depends on: T002

- [ ] `scripts/backup.sh <target-dir>`:
  - runs `pg_dump -Fc butterfly` (plus `frost` once it exists)
  - mirrors the MinIO `photos` bucket using `mc mirror` from the `minio/mc` image
  - writes `manifest.json` (time, git commit, migration head)
  - keeps the last 7 backups
- [ ] `scripts/restore.sh <backup-dir>` restores into an empty stack (`docker compose down -v && up`).
- [ ] A restore test is documented in `docs/setup/backup.md`: back up, wipe, restore, check row counts and that a photo opens in admin.
- [ ] The backup can optionally be encrypted (`age` or `gpg`) when a key is set in `.env` (outline §22).

### T011 · Custom user model and JWT auth endpoints
[#28](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/28) · E02 · P1 · must · labels: `backend`, `security`, `must` · implements F1 · est. 1.5 d · **todo**

Depends on: T003

- [ ] `accounts.User` uses `email` as the login, a UUID primary key and the fields `name` and `organization`. It is created in the **first** migration of the project.
- [ ] `POST /api/v1/auth/login` with `{email, password}` returns `{access, refresh, user}`.
- [ ] `POST /api/v1/auth/refresh` rotates the refresh token and blacklists the old one.
- [ ] `POST /api/v1/auth/logout` with `{refresh}` blacklists it and returns 205.
- [ ] `GET /api/v1/auth/me` returns `{id, email, name, organization, groups: ["researcher"|"admin"], project_ids: [...]}`.
- [ ] Inactive users cannot log in. Five failed logins per email within 15 minutes return 429 (cache-based counter).
- [ ] Tests cover login, refresh rotation, logout blacklist, and an inactive user.

### T012 · App login, secure token storage, refresh and logout
[#29](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/29) · E02 · P1 · must · labels: `mobile`, `security`, `must` · implements F1 · est. 2 d · **todo**

Depends on: T006, T011

- [ ] The login screen has email and password fields, shows errors, and shows the **last successful sync time** (outline §11.2 A).
- [ ] Tokens and the `/auth/me` profile are stored in `flutter_secure_storage` (Android Keystore-backed).
- [ ] A dio interceptor refreshes the access token on 401 exactly once, with concurrent requests waiting on the same refresh. If refresh fails, it goes to the login screen without deleting local data.
- [ ] **Offline start:** if a refresh token and cached profile exist, the app opens without network. Login is only required when no session exists.
- [ ] On logout, if local unsynced changes exist, the app warns "N changes not yet synced" and offers sync first. Logout never deletes the local database. A separate "Remove all local data" option in settings has a confirmation step.
- [ ] Widget tests cover the login form validation and the interceptor refresh.

### T013 · Two roles: groups, permissions and access rules
[#30](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/30) · E02 · P1 · must · labels: `backend`, `admin`, `security`, `must` · implements F2, F62 · est. 1.5 d · **todo**

Depends on: T011

- [ ] A data migration creates groups `researcher` (no model permissions; app only) and `admin` (all permissions of this project's apps). A later migration helper `sync_admin_group_permissions()` re-grants after new models are added. It runs in a `post_migrate` signal.
- [ ] Adding a user to `admin` sets `is_staff=True`, and removing them sets it back to `False` (`m2m_changed` signal). Researchers cannot log into `/admin/` (tested).
- [ ] DRF permission classes:
  - `IsAdminGroup`
  - `IsProjectMember` (object or `project_id` in payload)
  - `IsOwnerOrAdmin` (record `created_by == request.user`)
- [ ] Admin-only endpoints (exports, auth verify for pygeoapi) return 403 for researchers (tested).
- [ ] An admin who uses the app behaves exactly like a researcher there (sees own records), plus can see all projects.

### T014 · Django admin foundation
[#31](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/31) · E02 · P1 · must · labels: `admin`, `must` · implements F62 · est. 1 d · **todo**

Depends on: T013

- [ ] `admin.site.site_header = "Butterfly Monitoring"`, plus `site_title` and `index_title`. A small CSS override provides logo and colours (template override of `admin/base_site.html` only).
- [ ] App sections are ordered: Projects, Transects, Visits & observations, Plants & habitat, Validation, Sync, Catalogues, Users. This is done via `AdminSite.get_app_list` override (Django 4.1+ supports `app_label` ordering; VERIFY).
- [ ] `SyncableAdmin` base:
  - `server_version`, `created_*` and `updated_*` are read-only
  - list filter "Deleted" (yes/no)
  - action "Soft delete selected" replaces the built-in delete action
  - `has_delete_permission` returns `False`
- [ ] `MapAdmin(GISModelAdmin)` base with an OSM base layer, centred on the project area when known.
- [ ] Both bases combine with `SimpleHistoryAdmin` (T018).

### T015 · Project and membership models, API and admin
[#32](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/32) · E02 · P1 · must · labels: `backend`, `admin`, `database`, `must` · implements F3 · est. 2 d · **todo**

Depends on: T005, T013, T014

- [ ] `Project` and `ProjectMembership` models with admin: a project change form with a `ProjectMembership` inline (user autocomplete).
- [ ] `GET /api/v1/projects` returns the caller's projects (all projects for admins), with `transect_count` and `period`.
- [ ] `GET /api/v1/projects/{id}` returns 404 for non-members (not 403, so project existence isn't leaked).
- [ ] Removing a membership hides the project from that user's next pull. Local data on their phone is not deleted (documented).
- [ ] Projects are synced (pull, T025) to members.

### T016 · Project protocol settings and study area
[#33](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/33) · E02 · P1 · must · labels: `backend`, `admin`, `database`, `must` · implements F71, F73 · est. 1.5 d · **todo**

Depends on: T001, T015

- [ ] A `ProjectProtocol` one-to-one model, edited as an inline on the project admin. Defaults come from T001. Creating a project auto-creates its protocol (signal).
- [ ] `Project.area` (MultiPolygon, optional) is drawn in the admin map widget or uploaded as GeoJSON/KML via an admin action.
- [ ] Both are included in pull, and the app shows a protocol summary on the transect detail screen (T033).
- [ ] Changing a threshold changes the next flag computation (tested with T056).

### T017 · App project list and project home
[#34](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/34) · E02 · P1 · must · labels: `mobile`, `must` · implements F3, F72 · est. 1.5 d · **todo**

Depends on: T012, T015
Notes: badges fill in once T029 and T031 land

- [ ] The project list (outline §11.2 B) shows each project's name, period, number of downloaded transects, number of unsynced changes and offline package status (`not downloaded` / `ready` / `update available`).
- [ ] Project home tiles (outline §11.2 C, minus the validation tab): **Start visit**, **Transects**, **Free observation**, **Plants & habitat**, **Map**, **Unsynced data** (with badge), **Statistics**.
- [ ] The last selected project is remembered.
- [ ] Everything works offline once the package is downloaded.

### T018 · Audit log with django-simple-history
[#35](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/35) · E02 · P1 · must · labels: `backend`, `admin`, `must` · implements F4 · est. 1.5 d · **todo**

Depends on: T015

- [ ] `HistoricalRecords(table_name="historical_<table>")` is on Project, ProjectMembership, ProjectProtocol, Transect, TransectSection, Taxon, PlantTaxon, HabitatType, ManagementType, SurveyVisit, ButterflyObservation, Photo, PlantResourceObservation, HabitatFeature, SyncConflict. Each later model ticket adds its own line, and this ticket adds it to the models that exist now.
- [ ] `simple_history.middleware.HistoryRequestMiddleware` is installed. Changes made through DRF (JWT) record `history_user` (tested: DRF sets the user on the underlying request; VERIFY with the installed version).
- [ ] A service helper `save_with_reason(obj, user, reason)` sets `obj._change_reason`.
- [ ] Admin classes inherit `SimpleHistoryAdmin`. **Revert is disabled** (`history_revert` off via `has_change_permission` on the history view, or by overriding `history_form_view`) because reverting would bypass sync versioning.
- [ ] Test: changing an observation's taxon produces a history row with old and new taxon, user, timestamp and reason.

### T019 · Taxon catalogue, versioned
[#36](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/36) · E03 · P1 · must · labels: `backend`, `database`, `must` · implements F18 · est. 2 d · **todo**

Depends on: T005, T015

- [ ] `TaxonListVersion` and `Taxon` models with admin (search by scientific and vernacular names).
- [ ] **Versioning rule:**
  - a rename or synonymisation creates a new `Taxon` row
  - the old row gets `retired_in = <new version>` and `accepted_name = <new row>`
  - `scientific_name` is read-only in admin after creation (tested)
- [ ] Exactly one `TaxonListVersion` has `is_current = true` (partial unique index).
- [ ] `Project.taxon_list_version` FK is added. New projects default to the current version.
- [ ] Taxa reach the phone by pull: all taxa where `retired_in IS NULL` or that are referenced by the user's own observations.
- [ ] `photo_required` flag per taxon, used by rule W01 in T055.

### T020 · Plant taxa and editable codelists
[#37](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/37) · E03 · P1 · must · labels: `backend`, `database`, `must` · implements F22, F64 · est. 1.5 d · **todo**

Depends on: T005

- [ ] `PlantTaxon`, `HabitatType` and `ManagementType` models with admin.
- [ ] All three are pulled to the phone (active rows, plus inactive rows referenced by the user's records).
- [ ] Deactivating a value hides it from pickers but keeps it on existing records (tested in app and API).

### T021 · Transect and section models and API
[#38](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/38) · E03 · P1 · must · labels: `backend`, `database`, `must`, `p2-compat` · implements F6 · est. 2 d · **todo**

Depends on: T015, T020

- [ ] `Transect` and `TransectSection` models. `(project, code)` is unique, and so are `(transect, sequence_number)` and `(transect, section_code)`.
- [ ] `GET /api/v1/projects/{id}/transects` and `GET /api/v1/transects/{id}` are read-only. Responses include computed `length_m` (geodesic), `section_count`, and the caller's `visit_count` and `last_visit_at`.
- [ ] `GET /api/v1/transects/{id}/visits` returns the caller's visits (admins: all visits).
- [ ] Validation: a section geometry must lie within 5 m of its transect line (`ST_DWithin` on geography). An admin form error is shown otherwise.
- [ ] Both models are synced to project members.

### T022 · Map-based transect and section editor in admin
[#39](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/39) · E03 · P1 · must · labels: `admin`, `must` · implements F63 · est. 2 d · **todo**

Depends on: T014, T021

- [ ] `TransectAdmin(MapAdmin, SimpleHistoryAdmin)` uses a map widget for the line and a sections inline (`StackedInline`, small map per section, collapsed by default).
- [ ] An **Import line** admin view on a transect accepts a GPX, KML or GeoJSON upload. It reads the first LineString or track using `django.contrib.gis.gdal.DataSource` and reprojects it to 4326.
- [ ] Action **Generate N equal sections** (intermediate form asking N and a code prefix) creates sections with `ST_LineSubstring` and sequence numbers 1..N. It refuses if sections already exist, unless "replace" is ticked; replaced sections are soft-deleted.
- [ ] A warning appears in the change view when the sum of section lengths differs from the transect length by more than 2 %.
- [ ] The list shows code, name, project, active, length and section count, filtered by project.

### T023 · Catalogue admin tools
[#40](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/40) · E03 · P1 · should · labels: `admin`, `should` · implements F64 · est. 1.5 d · **todo**

Depends on: T019, T020

- [ ] Taxon, PlantTaxon, HabitatType and ManagementType admins have search, filters (family, active, source) and `list_editable` for `active`, `photo_required` and `sort_order`.
- [ ] CSV import and export for all four, using **django-import-export**. It's justified: it saves writing and testing a custom importer, and its dry-run diff preview is useful. Pin the version and VERIFY Django 5.2 support.
- [ ] Action **Publish new taxon list version**: creates a `TaxonListVersion`, marks it current, and lets admins choose which projects switch to it.
- [ ] Action **Synonymise into…** (intermediate form): creates or links the accepted taxon and retires the selected one in the new version, following the T019 versioning rule.

### T024 · Seed data: butterflies of Serbia, plant list, codelists, demo project
[#41](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/41) · E03 · P1 · must · labels: `backend`, `must` · implements F79 · est. 2 d · **todo**

Depends on: T019, T020, T021

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

### T025 · Pull API with server-version cursor
[#42](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/42) · E04 · P1 · must · labels: `backend`, `sync`, `must` · implements F25, F7 · est. 2 d · **todo**

Depends on: T005, T015, T019, T020, T021

- [ ] `POST /api/v1/sync/pull` returns the changes for all entity types in scope, ordered by `server_version`, at most `limit` (default 1000, max 5000) records per page, with `next_cursor` = the last returned version and `has_more`.
- [ ] Scope rules:
  - reference data: the project, its protocol, transects, sections, the catalogues (global), and the taxon list version
  - user data: the caller's **own** records (`created_by = user`) in that project
  - `sync_conflict`: the caller's own conflicts
- [ ] Soft-deleted rows come back as `{id, deleted_at, server_version}` tombstones.
- [ ] A non-member gets 404. Cursor 0 returns the full initial package (T031).
- [ ] Each entity serializer used for pull is the same one used for push (single schema), documented in OpenAPI.
- [ ] Test: interleaved writes during paging never lose a record. The T005 advisory lock guarantees in-order commits.

### T026 · Push API with idempotent mutations
[#43](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/43) · E04 · P1 · must · labels: `backend`, `sync`, `database`, `must` · implements F25, F13 · est. 2.5 d · **todo**

Depends on: T025

- [ ] Each mutation runs in its own savepoint, so one rejected mutation does not abort the batch. Results come back in input order.
- [ ] **Idempotency:** a `mutation_id` already in `sync_mutation` returns the stored result with status `duplicate` and changes nothing (tested by sending the same batch twice).
- [ ] `create` with an existing `entity_id` and an unseen `mutation_id` is treated as `update` with conflict check (T027).
- [ ] `create_batch` (track points only) inserts up to 1000 rows with `ON CONFLICT (id) DO NOTHING`.
- [ ] Every mutation runs through the entity's service function: validation (T055), ownership (`created_by` or admin), membership, the lock rule (T042), section assignment (T048), flags (T056) and history reason `"sync push"`.
- [ ] Server-owned fields (`validation_*`, `quality_flags`, `server_version`, `locked_*`, `distance_walked_m` once recomputed) are ignored if present in client payloads.
- [ ] A rejected mutation returns `{code, detail, fields}` errors that the app can show (T032).
- [ ] A 500-mutation batch completes in under 5 s on the laptop (measured in T074).

### T027 · Conflict detection and SyncConflict model
[#44](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/44) · E04 · P1 · must · labels: `backend`, `sync`, `database`, `must` · implements F26 · est. 2 d · **todo**

Depends on: T018, T026

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

### T028 · Django admin conflict resolution screen
[#45](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/45) · E04 · P1 · must · labels: `admin`, `sync`, `must` · implements F26 · est. 1.5 d · **todo**

Depends on: T014, T027

- [ ] `SyncConflictAdmin` list: entity type, entity link, owner, project, conflicting fields, created, status. Filters: status, entity type, project, owner.
- [ ] The change view is read-only with a **side-by-side diff table** (field | base | server | client), with conflicting rows highlighted. It is a small template override: `admin/sync/syncconflict/change_form.html`.
- [ ] Action/button **Accept server**: marks `resolved_server` and *touches* the entity (a save with reason `"conflict resolved: server"`), so it gets a new `server_version` and the phone pulls the server state.
- [ ] Action/button **Accept client**: applies `client_payload` through the entity's service with conflict checks bypassed, history reason `"conflict resolved: client"`, then marks `resolved_client`.
- [ ] Both require a note (intermediate form) and are recorded in history.
- [ ] Accepting client on a locked visit is refused with a message to unlock first (T043).

### T029 · App sync queue
[#46](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/46) · E04 · P1 · must · labels: `mobile`, `sync`, `database`, `must` · implements F24, F23 · est. 1.5 d · **todo**

Depends on: T006

- [ ] A `SyncRepository.write(entity, operation)` helper writes the row with `syncStatus = pending` and appends a queue item, atomically.
- [ ] **Coalescing:**
  - several updates to a queued entity merge into one queued update, keeping the first `baseVersion`
  - create followed by updates becomes a single create
  - create followed by delete removes both
- [ ] Track points are queued as `create_batch` items of up to 500 points.
- [ ] `sync_state` stores `deviceId` (UUID generated on first launch), per-project `lastPullCursor`, `lastSuccessfulSyncAt` and `lastSyncBytes`.
- [ ] Unit tests cover coalescing and atomicity (simulate an exception mid-write: neither row nor queue item persists).

### T030 · App sync runner: push, pull, retry and backoff
[#47](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/47) · E04 · P1 · must · labels: `mobile`, `sync`, `must` · implements F24, F25 · est. 2.5 d · **todo**

Depends on: T025, T026, T029

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

### T031 · App offline package download and status
[#48](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/48) · E04 · P1 · must · labels: `mobile`, `backend`, `must` · implements F7 · est. 1.5 d · **todo**

Depends on: T030

- [ ] The **Download project** button runs a pull from cursor 0 for that project, with a progress indicator (records received) and the ability to cancel and resume (cursor persisted).
- [ ] `GET /api/v1/projects/{id}/offline-package` (outline §14) exists as a thin alias returning the first pull page plus `{reference_version}`. `GET /api/v1/projects/{id}/offline-package/status` returns `{reference_version}`, the max `server_version` across reference tables.
- [ ] Project list status: `not downloaded` / `ready` / `update available` (when the server `reference_version` is newer than the local one).
- [ ] After download in airplane mode, every screen needed for a visit works (manual test script in `docs/testing/offline-checklist.md`).
- [ ] If T060 is done, the package also downloads the project's MBTiles basemap.

### T032 · App sync status screen
[#49](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/49) · E04 · P1 · must · labels: `mobile`, `sync`, `must` · implements F28 · est. 1.5 d · **todo**

Depends on: T030

- [ ] The screen shows pending changes per entity type, photos waiting and their total size, last successful sync time, and bytes transferred in the last sync.
- [ ] **Errors** list: rejected items with a human-readable reason (mapped from the error `code`), plus **Retry** (re-queues with a new attempt) and **Discard local change** (with confirmation; restores the server version on the next pull).
- [ ] **Conflicts** list (from `sync_conflicts`) is read-only and reads: "An admin will resolve this. Your change is kept on the server." It shows the resolution once pulled.
- [ ] **Sync now** button with live progress.
- [ ] The unsynced badge on project home (T017) matches the counts here.

### T033 · App transect list and transect detail
[#50](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/50) · E05 · P1 · must · labels: `mobile`, `must` · implements F72 · est. 2 d · **todo**

Depends on: T017, T021, T031

- [ ] List: code, name, distance from the current location (last known fix, straight-line to the nearest vertex), last own visit date, own visit count, downloaded flag, active status. Search by name or code, sort by distance or code.
- [ ] Detail: a map (flutter_map) with the transect line and colour-coded sections, length, section list with habitat types, habitat summary, a protocol summary (season, time window, weather thresholds from `project_protocols`), own visit history, and a **Start visit** button.
- [ ] Start visit is disabled for inactive transects. It warns (without blocking) outside the season or time window.
- [ ] Everything works offline.

### T034 · SurveyVisit model, lifecycle and API
[#51](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/51) · E05 · P1 · must · labels: `backend`, `mobile`, `database`, `must`, `p2-compat` · implements F9 · est. 2.5 d · **todo**

Depends on: T021, T026

- [ ] `surveys/state.py` holds a transition table and `transition(visit, to, actor, reason=None)`, raising `InvalidTransition`. It is used by push, the REST endpoints and admin. There is no extra dependency (django-fsm is not used: its maintenance status is unclear and a dict is enough).
- [ ] REST endpoints (outline §14), using the same services as push:
  - `POST /api/v1/survey-visits`
  - `GET /api/v1/survey-visits/{id}`
  - `PATCH /api/v1/survey-visits/{id}`
  - `POST /api/v1/survey-visits/{id}/complete`

  There is **no** lock endpoint; locking is admin-only.
- [ ] `cancel_reason` is required exactly when `status = cancelled`. "Missing data" means no visit row at all (outline §7.3).
- [ ] Mirrored in Drift; the app uses the same Dart transition table (shared JSON spec in `docs/requirements/visit-states.json`, with a test on both sides that reads it).

### T035 · App start-visit form
[#52](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/52) · E05 · P1 · must · labels: `mobile`, `must` · implements F8 · est. 1.5 d · **todo**

Depends on: T016, T033, T034

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

### T036 · Track points: model, batch sync and walked distance
[#53](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/53) · E05 · P1 · must · labels: `backend`, `database`, `sync`, `must`, `p2-compat` · implements F10 · est. 1.5 d · **todo**

Depends on: T026, T034

- [ ] The `SurveyTrackPoint` model accepts `create_batch` pushes (T026) of up to 1000 points, idempotent per point id.
- [ ] On visit completion, the server computes `distance_walked_m` from points ordered by `recorded_at`, excluding points with `accuracy_m > protocol.gps_accuracy_warning_m × 2`. It keeps the client value if the server has fewer than 2 usable points.
- [ ] The admin visit page shows the route as a read-only map: `ST_MakeLine(geometry ORDER BY recorded_at)`.
- [ ] Points are **never** thinned or simplified on the server (raw data kept for Phase 2).

### T037 · App GPS tracking with an Android foreground service
[#54](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/54) · E05 · P1 · must · labels: `mobile`, `must` · implements F10, F87 · est. 3 d · **todo**

Depends on: T035, T036

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

### T038 · Battery-saving mode and GPS gap detection
[#55](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/55) · E05 · P1 · must · labels: `mobile`, `must` · implements F87 · est. 1 d · **todo**

Depends on: T037

- [ ] A toggle on the active visit switches to `gpsIntervalBatterySaverS` and `LocationAccuracy.medium`, and sets `battery_saver_used = true` on the visit.
- [ ] It switches automatically below 20 % battery (`battery_plus`), with a snackbar.
- [ ] A banner shows "No GPS fix for N s" when no point arrives within `gps_gap_s`.
- [ ] Gaps are visible later on the visit summary (T040).

### T039 · App active visit screen
[#56](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/56) · E05 · P1 · must · labels: `mobile`, `must` · implements F11 · est. 2.5 d · **todo**

Depends on: T037

- [ ] The map shows the transect line, sections (current one highlighted), the current position with an accuracy circle, and the walked route.
- [ ] A header shows elapsed time excluding pauses, distance walked, current section code and number of observations.
- [ ] A large **Add butterfly** button (opens T045), plus **Add plant** (T052) and **Add habitat** (T054).
- [ ] **Pause/Resume:** while paused, no track points are stored and `paused_seconds` accumulates. Observations are still allowed during a pause but warned about.
- [ ] **Finish** goes to T040.
- [ ] An optional keep-screen-on toggle (`wakelock_plus`).
- [ ] Works fully offline.

### T040 · Finish visit: summary, warnings and end weather
[#57](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/57) · E05 · P1 · must · labels: `mobile`, `must` · implements F11 · est. 2 d · **todo**

Depends on: T039, T055

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

### T041 · True-zero confirmation and cancelled-visit reasons
[#58](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/58) · E05 · P1 · must · labels: `mobile`, `backend`, `must` · implements F12, F9 · est. 1 d · **todo**

Depends on: T040

- [ ] Finishing a visit with zero transect observations requires ticking: *"No butterfly was seen during the complete standardised visit."* This sets `zero_observation_confirmed = true`.
- [ ] Server rule V06 (T055):
  - a completed visit with zero `source = transect` observations must have `zero_observation_confirmed = true`
  - a visit with observations must have it `false`

  Violations are rejected.
- [ ] Cancel flow offers four reasons: `not_conducted` (planned but not walked; can be recorded without starting), `aborted_weather`, `aborted_other` and `invalid_protocol`, plus a note.
- [ ] Exports (T064) show the visit outcome as one of `completed_with_records`, `true_zero`, `cancelled:<reason>`.
- [ ] Unit tests on both sides.

### T042 · Visit lock enforced in the API
[#59](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/59) · E05 · P1 · must · labels: `backend`, `sync`, `must` · implements F13 · est. 1 d · **todo**

Depends on: T026, T034

- [ ] Push and REST reject (`code = "visit_locked"`) any create, update or delete of a locked visit, and of any observation, track point, plant resource, habitat feature or photo belonging to a locked visit.
- [ ] Django admin: `has_change_permission` returns `False` for a locked visit and its children, with a "Locked by X on Y: reason" banner. The only way back is the Unlock action (T043).
- [ ] App: on pull, a locked visit and its records become read-only, with a lock icon. Local pending edits on it end up `rejected`, with a clear message on the sync screen.
- [ ] Tests for each child entity type.

### T043 · Admin visit review, lock and unlock with mandatory reason
[#60](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/60) · E05 · P1 · must · labels: `admin`, `must` · implements F66 · est. 1.5 d · **todo**

Depends on: T018, T042

- [ ] `SurveyVisitAdmin` list: transect, observer, start, duration, distance, observation count, status, flags. Filters: project, transect, status, observer, date, flag.
- [ ] Inlines: observations (read-only summary with links) and a route map.
- [ ] Actions: **Mark reviewed**, **Lock**, **Unlock**. Lock and unlock use an intermediate form with a required reason (at least 10 characters) and set `locked_at`, `locked_by` and `lock_reason` (cleared on unlock).
- [ ] The history row carries the reason as `history_change_reason`.
- [ ] Invalid transitions (for example locking a draft) show an error per visit without failing the whole action.

### T044 · ButterflyObservation model and API
[#61](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/61) · E06 · P1 · must · labels: `backend`, `database`, `sync`, `must`, `p2-compat` · implements F14, F15, F17 · est. 2.5 d · **todo**

Depends on: T019, T026, T034

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

### T045 · App quick butterfly entry
[#62](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/62) · E06 · P1 · must · labels: `mobile`, `must` · implements F14 · est. 2.5 d · **todo**

Depends on: T039, T044

- [ ] A bottom sheet opens from **Add butterfly** with: recent species (last 8 used in this project), favourites (star toggle), search, count stepper (+/−, long-press to type) and **Save**.
- [ ] Search matches scientific, Serbian and English names, is diacritics-insensitive (`searchText`, T019), matches as you type, and returns in under 100 ms for 300 taxa.
- [ ] A repeat species takes **≤ 3 taps** (open, tap species, save); measured by T073.
- [ ] Position comes from the latest fix (accuracy shown, with a warning above `gpsAccuracyWarningM`). Time is "now".
- [ ] Section = current section (T039). Confidence defaults to `confirmed_in_field`.
- [ ] An **Undo** snackbar for 10 s soft-deletes the last record.
- [ ] Local table `taxon_usage` stores favourites and recent use.

### T046 · App extended entry
[#63](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/63) · E06 · P1 · should · labels: `mobile`, `should` · implements F15 · est. 1.5 d · **todo**

Depends on: T045

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

### T047 · Incidental and other-source observations
[#64](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/64) · E06 · P1 · should · labels: `mobile`, `backend`, `should` · implements F17 · est. 1 d · **todo**

Depends on: T045

- [ ] The **Free observation** tile (project home) and a map long-press open the same entry sheet with a **source** picker: `incidental`, `larval_search`, `host_plant_search`.
- [ ] No visit is needed (`survey_visit_id = null`). Position comes from GPS, or from the long-pressed or dragged map position, with accuracy set to `null` when placed manually.
- [ ] These records are excluded from per-km and per-hour indicators (T061, T062) but included in species lists and exports.

### T048 · Automatic section assignment
[#65](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/65) · E06 · P1 · should · labels: `backend`, `should` · implements F19 · est. 1 d · **todo**

Depends on: T044

- [ ] The app sends its current-section guess (T039). If the client sends `null`, the server assigns the nearest section of the visit's transect within `max_distance_from_transect_m`.
- [ ] A client-sent section is kept unless it belongs to a different transect, which is rejected.
- [ ] Observations farther than the threshold get no section and the `far_from_transect` flag (T056).
- [ ] Admin action **Reassign sections** recomputes for selected observations (saved per row, so history applies).
- [ ] Tests with the seeded demo transects.

### T049 · Photo model and upload API with SHA-256 deduplication
[#66](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/66) · E06 · P1 · must · labels: `backend`, `database`, `sync`, `must` · implements F27, F16 · est. 2.5 d · **todo**

Depends on: T003, T044

- [ ] Photo metadata arrives by push (`create`).
- [ ] `POST /api/v1/attachments/init` with `{photo_id, sha256, file_size, mime_type}`:
  - returns `{status: "exists"}` if an uploaded object with that SHA-256 already exists; the photo is linked to it immediately
  - otherwise returns `{status: "upload_required", upload_url}`
- [ ] `PUT /api/v1/attachments/{id}/content` (raw body, `Content-Type: image/jpeg`) streams to a temp file, verifies SHA-256 and size, and stores to `photos/<aa>/<bb>/<sha256>.jpg`. Mismatches return 422. Re-PUT is allowed until complete.
- [ ] `POST /api/v1/attachments/{id}/complete` sets `uploaded_at` and creates a 400 px thumbnail at `thumbs/<sha256>.jpg` (Pillow, EXIF orientation applied). It is idempotent.
- [ ] `GET /api/v1/photos/{id}/content` and `/thumbnail` are allowed for the owner or admins and streamed from storage. The phone never talks to MinIO directly.
- [ ] Max size 15 MB (nginx `client_max_body_size 20m`). Allowed types: JPEG, PNG.
- [ ] MVP criterion 9: re-uploading the same file twice creates one stored object (tested).

### T050 · App photo capture, compression and upload
[#67](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/67) · E06 · P1 · must · labels: `mobile`, `must` · implements F16, F27 · est. 2.5 d · **todo**

Depends on: T030, T045, T049
Notes: photo button moves into T046's extended section once that exists

- [ ] Capture with `image_picker` (camera) or pick from the gallery. Several photos per observation, one marked primary.
- [ ] Compress to max 2048 px on the long edge, JPEG quality 85 (`flutter_image_compress`), with EXIF orientation applied. The original camera file is deleted after compression.
- [ ] Saved to `<app documents>/photos/<photoId>.jpg`. SHA-256 is computed in an isolate. The metadata row and queue item are created atomically.
- [ ] The sync runner (T030) runs after push: for each photo with `pendingUpload`, init, then PUT, then complete, with resume on failure (re-init is safe).
- [ ] An optional "Upload photos on Wi-Fi only" setting.
- [ ] Thumbnails appear in the observation detail. Deleting a photo is a soft delete that syncs.
- [ ] Local photo storage use is shown on the sync screen (T032).

### T051 · PlantResourceObservation model and API
[#68](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/68) · E07 · P1 · should · labels: `backend`, `database`, `sync`, `should` · implements F20 · est. 1.5 d · **todo**

Depends on: T020, T044, T049

- [ ] Model, push and pull registration, and REST (outline §14):
  - `POST /api/v1/plant-resources`
  - `PATCH /api/v1/plant-resources/{id}`
- [ ] Geometry must be `POINT` or `POLYGON` (CHECK), and be valid (`ST_IsValid`, rule V08).
- [ ] `patch_area_m2` is computed by the server for polygons when the client leaves it empty (`ST_Area(geometry::geography)`).
- [ ] Adds `ButterflyObservation.host_plant_record` and `nectar_plant_record` (nullable FKs), and `Photo.plant_resource` with a CHECK that a photo has exactly one parent.
- [ ] `plant_taxon` may be null for unidentified plants. Then `notes` is required (serializer rule).

### T052 · App plant entry with point and polygon drawing
[#69](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/69) · E07 · P1 · should · labels: `mobile`, `should` · implements F20 · est. 2.5 d · **todo**

Depends on: T050, T051

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

### T053 · HabitatFeature model and API
[#70](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/70) · E07 · P1 · should · labels: `backend`, `database`, `sync`, `should`, `p2-compat` · implements F21 · est. 1.5 d · **todo**

Depends on: T020, T026

- [ ] Model, push and pull registration, and REST (outline §14):
  - `POST /api/v1/habitat-features`
  - `PATCH /api/v1/habitat-features/{id}`
- [ ] Geometry is `POINT`, `LINESTRING` or `POLYGON`, and must be valid.
- [ ] Percentages are 0–100.
- [ ] `habitat_type` is required, and `management_type` is optional (FK to codelists, T020).

### T054 · App habitat feature entry
[#71](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/71) · E07 · P1 · should · labels: `mobile`, `should` · implements F21 · est. 1.5 d · **todo**

Depends on: T052, T053

- [ ] Habitat type and management pickers (from codelists), vegetation height (cm), cover sliders (shrub, tree, bare ground; 0–100 in steps of 5), flower abundance, grazing, mowing, disturbance and notes.
- [ ] Point, line and polygon capture via `GeometryCaptureWidget` (T052).
- [ ] Reachable from the active visit and from "Plants & habitat" on project home.

### T055 · Input validation rules (shared by app and server)
[#72](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/72) · E08 · P1 · must · labels: `backend`, `mobile`, `must` · implements F30 · est. 2 d · **todo**

Depends on: T016, T034, T044

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

### T056 · Automatic quality flags
[#73](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/73) · E08 · P1 · should · labels: `backend`, `should` · implements F31 · est. 1.5 d · **todo**

Depends on: T036, T048, T055

- [ ] **Flags** (codes stored in `quality_flags`):
  - `outside_project_area`: observation not within `project.area` (skipped when the area is null)
  - `far_from_transect`: a transect observation farther than `max_distance_from_transect_m` from its transect line
  - `high_count`: `count > high_count_threshold`
  - `gps_gap` (on the visit): any gap between consecutive track points over `gps_gap_s`, outside pauses
- [ ] Flags are computed in the push service after save, for the affected records only. Recompute is available as an admin action and as `manage.py recompute_flags --project`.
- [ ] Admin list filter "Has flag: …" on observations and visits uses the array-contains lookup.
- [ ] Changing a protocol threshold and recomputing changes the flags (tested).

### T057 · Admin validation queue
[#74](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/74) · E08 · P1 · should · labels: `admin`, `should` · implements F32 · est. 2 d · **todo**

Depends on: T014, T049, T058

- [ ] Proxy model `ValidationQueueItem(ButterflyObservation)` with its own admin, listed under **Validation**. Default queryset: `validation_status = pending`, or any flag, and not deleted.
- [ ] `list_display`: primary photo thumbnail (`<img>` from `/api/v1/photos/{id}/thumbnail`, admin session auth), taxon, count, life stage, observed at, recorder, confidence, flags, project.
- [ ] Filters: project, family, confidence, flag, date. Search: taxon names.
- [ ] Bulk actions: **Confirm**, **Mark unconfirmed**, **Mark undeterminable**.
- [ ] **Change taxon** is an intermediate form with taxon autocomplete and a required comment. It sets `validated_taxon`; `taxon` keeps what the recorder entered.
- [ ] Each action sets `validation_status`, `validated_by`, `validated_at` and `validation_comment`, writes a `ValidationEvent` (T058) and a history reason `"validation: <decision>"`.
- [ ] The change view shows all photos at full size (inline read-only gallery) and a small read-only map.
- [ ] Records of locked visits are view-only (T042).

### T058 · Validation history
[#75](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/75) · E08 · P1 · should · labels: `backend`, `database`, `should` · implements F33 · est. 1 d · **todo**

Depends on: T044

- [ ] The `ValidationEvent` model is written only by validation services (T057).
- [ ] A read-only inline on the observation admin, newest first.
- [ ] Included in exports as `validation_history.csv` (T064).

### T059 · App map screen with layers and filters
[#76](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/76) · E09 · P1 · must · labels: `mobile`, `must` · implements F34 · est. 2.5 d · **todo**

Depends on: T036, T044
Notes: plant/habitat layers added when T051/T053 are done

- [ ] **Layers** (toggle sheet): transects, sections, own observations (clustered with `flutter_map_marker_cluster`), plants, habitats, a selected visit's route, and the basemap.
- [ ] **Filters:** visit, species, date range, life stage, behaviour, habitat type. The validation-status filter is dropped because the app doesn't store it.
- [ ] Tapping a feature shows a popup with key fields and an "Open" link to its detail or edit screen.
- [ ] 5,000 observation markers render and pan smoothly on the test phone (timed in T074).
- [ ] The online basemap uses OSM tiles with a correct `User-Agent` (`rs.<you>.butterfly`) and the attribution shown. Viewed tiles are cached (flutter_map tile caching). There is **no bulk prefetch** (OSM tile usage policy forbids it).

### T060 · Offline basemap from MBTiles
[#77](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/77) · E09 · P1 · could · labels: `mobile`, `backend`, `could` · implements F29 · est. 2 d · **todo**

Depends on: T031, T059

- [ ] `docs/setup/basemap.md` explains producing an MBTiles file for the project area in QGIS (*Processing → Generate XYZ tiles (MBTiles)*, zoom 12–18). The source must allow offline use, for example your own styling of an OSM extract from Geofabrik, or an open orthophoto with a compatible licence. **Not** by scraping tile servers.
- [ ] `Project.basemap` is a FileField in MinIO, uploaded in admin. The offline package (T031) downloads it when present.
- [ ] The app renders it with an MBTiles tile provider for flutter_map (package choice: VERIFY, e.g. `flutter_map_mbtiles`) and falls back to cached online tiles.
- [ ] The file size is shown before download. Typical: 20–80 MB for a few km².

### T061 · Indicators: server SQL views and admin report
[#78](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/78) · E09 · P1 · should · labels: `backend`, `admin`, `database`, `should` · implements F35 · est. 1.5 d · **todo**

Depends on: T041, T044, T058

- [ ] **View `report_transect_indicators`** (per transect × year): visits completed, true-zero visits, total duration (h), total distance (km), species count, individuals, observations, confirmed and to-review counts, individuals per km, individuals per hour, and target visits vs actual.
- [ ] **View `report_species_phenology`** (per project × taxon × ISO week): individuals, observations, first and last date.
- [ ] **View `report_behaviour_counts`** (per project × behaviour value): count. Reproductive records = behaviour ∩ {courtship, mating, oviposition} or life stage ∈ {egg, larva, pupa}.
- [ ] Only `source = transect` observations of non-cancelled visits count towards per-km and per-hour figures. Effective taxon = `COALESCE(validated_taxon_id, taxon_id)`.
- [ ] Unmanaged models over the views, with read-only admin changelists, filters (project, year, transect) and CSV export (T065).
- [ ] A test seeds known data and checks every number.

### T062 · App statistics screen
[#79](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/79) · E09 · P1 · should · labels: `mobile`, `should` · implements F35 · est. 1.5 d · **todo**

Depends on: T041, T044

- [ ] Per transect and period, from local data: visits, true zeros, species, individuals, individuals per km, individuals per hour, and the top 10 species.
- [ ] A weekly phenology bar chart for a chosen species (`fl_chart`).
- [ ] A note on screen: "Your records only. Project-wide figures are in the admin reports."
- [ ] Uses the same definitions as T061; a Dart unit test uses the same fixture numbers as T061's test.

### T063 · EnvironmentalSnapshot model with manual source
[#80](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/80) · E09 · P1 · must · labels: `backend`, `database`, `must`, `p2-compat` · implements F74 · est. 1 d · **todo**

Depends on: T034, T044

- [ ] When a visit reaches `completed`, the server creates two snapshots (start and end) with `source_type = manual`.
  - Wind Beaufort is converted to m/s using the midpoint of the Beaufort range.
  - The original Beaufort value is kept in `raw_payload_json`.
- [ ] Re-completing (after an edit) replaces the manual snapshots of that visit, never duplicating them.
- [ ] Included in exports as `environmental_snapshots.csv`.
- [ ] Read-only inline on the visit admin.

### T064 · Export service and admin-only export API
[#81](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/81) · E09 · P1 · must · labels: `backend`, `must` · implements F36 · est. 2.5 d · **todo**

Depends on: T044, T063
Notes: plant, habitat and validation datasets added when T051/T053/T058 are done

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

### T065 · Admin export actions
[#82](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/82) · E09 · P1 · should · labels: `admin`, `should` · implements F67 · est. 1 d · **todo**

Depends on: T064

- [ ] Actions **Export selected as CSV** and **Export selected as GeoJSON** on visits, observations, plant resources, habitat features, transects, validation events and the report views.
- [ ] An **Export project bundle (ZIP)** button on the project change page (small `change_form` template override with an object-tools link).
- [ ] Output is identical to the API for the same filter (test compares bytes).

### T066 · GeoPackage export
[#83](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/83) · E09 · P1 · could · labels: `backend`, `could` · implements F37 · est. 1 d · **todo**

Depends on: T064, T067

- [ ] `format=gpkg` on the bundle endpoint and the admin project button produce a `.gpkg` with layers built from the `geo` views (T067): transects, sections, observations, plant resources (split into point and polygon layers), habitat features (split by type), plus non-spatial tables (visits, snapshots, validation history).
- [ ] Created with `ogr2ogr -f GPKG out.gpkg PG:"<dsn>" -sql "<query>" -nln <layer>` per layer (GDAL is already in the image).
- [ ] Opens in QGIS with correct CRS and attribute types (checked manually; screenshot in docs).

### T067 · `geo` views for the five collections
[#84](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/84) · E10 · P1 · must · labels: `database`, `ogc`, `must` · implements F40, F45 · est. 2 d · **todo**

Depends on: T004, T021, T044
Notes: plant/habitat views added when T051/T053 are done

- [ ] The views `geo.transects`, `geo.transect_sections`, `geo.butterfly_observations`, `geo.plant_resources` and `geo.habitat_features` are created by migration (`CreateView` from T004).
- [ ] Arrays become comma-separated text (`behaviour`, `quality_flags`), because array attributes are poorly supported in OGC API Features clients and QGIS.
- [ ] Taxon names and codelist labels are joined in (no foreign-key lookups needed by clients). Observations expose both `taxon_*` (as recorded) and `effective_*` (validated if set).
- [ ] `pygeoapi_ro` can `SELECT` all five views, and cannot read any `public` table (test).
- [ ] A test selects one row from every view after migrations (catches view breakage when models change).

### T068 · pygeoapi collections, filtering and paging
[#85](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/85) · E10 · P1 · must · labels: `ogc`, `infra`, `must` · implements F39, F40, F41 · est. 1.5 d · **todo**

Depends on: T007, T067

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

### T069 · Token-protected pygeoapi access for admins
[#86](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/86) · E10 · P1 · must · labels: `ogc`, `security`, `infra`, `must` · implements F68 · est. 1.5 d · **todo**

Depends on: T011, T013, T068

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

### T070 · QGIS interoperability and OGC conformance test
[#87](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/87) · E10 · P1 · must · labels: `ogc`, `evaluation`, `must` · implements F43 · est. 1.5 d · **todo**

Depends on: T069, T071

- [ ] **QGIS** (version recorded): add an OGC API – Features connection with the token, load all 5 collections, check attribute types and geometry, and use the Temporal Controller on observations. Screenshots go in `evaluation/interop/`.
- [ ] **Python notebook:** reads each collection with `geopandas.read_file(url)` (or requests plus `GeoDataFrame.from_features`) with the token, and pages through more than 1000 features of simulated data.
- [ ] **R script:** reads observations with `sf` or `httr2` and plots a phenology chart.
- [ ] **OGC CITE:** run the executable test suite for OGC API – Features Part 1 (`ets-ogcapi-features10`, Docker image from OGC, VERIFY name and tag) against pygeoapi. Run it directly on the internal port in a `test` compose profile, because the test harness may not send auth headers. Save the HTML report, and explain any failures.
- [ ] Results table (client, operation, result, notes) in `evaluation/interop/results.md`.

### T071 · Simulated field-day generator
[#88](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/88) · E11 · P1 · must · labels: `backend`, `evaluation`, `must`, `p2-compat` · implements F80 · est. 2.5 d · **todo**

Depends on: T024, T026, T036, T044, T049
Notes: plants/habitats generated when T051/T053 are done

- [ ] `manage.py simulate_season --project <id> --start 2026-05-01 --end 2026-08-31 --visits-per-transect 8 --seed 42 [--direct]`:
  - **Weather per day:** a shared Python module `simweather` (in `simulator/simweather/`, also used by T079 in Phase 2) produces a daily story of temperature, cloud, wind and rain. Visits fall mostly on suitable days. About 10 % are cancelled, with reasons.
  - **Tracks:** walk each transect at 0.8–1.2 m/s, one point per protocol interval, Gaussian GPS noise with σ equal to a sampled accuracy of 3–8 m, and occasional gaps of 60–120 s.
  - **Observations:** species are drawn from the seeded list with per-habitat weights and a Gaussian flight-period curve per species (parameters derived deterministically from the taxon id). Counts follow a Poisson distribution. Confidence mix: 80 % `confirmed_in_field`, 15 % `probable`, 5 % `photo_required` with a placeholder photo.
  - **Plants and habitats:** a few plant resources (points and polygons) and habitat features per transect.
  - **Injected anomalies** to test flags and dedup: high counts, records far from the transect, GPS gaps, true-zero visits, and **duplicate batch submissions**.
- [ ] Default mode pushes through `/api/v1/sync/push` with the demo researcher's token (end-to-end). `--direct` writes via services for speed.
- [ ] The same seed gives identical data (test compares exports).
- [ ] Also exports `database/seeds/transects.gpx` for T072.

### T072 · GPS replay in the app
[#89](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/89) · E11 · P1 · must · labels: `mobile`, `evaluation`, `must` · implements F80 · est. 1.5 d · **todo**

Depends on: T037

- [ ] In the dev flavour only, Settings → "Location source: Device GPS | Replay GPX" with a file picker or bundled transect GPX, and speed 1×, 5× or 20×.
- [ ] `ReplaySource` implements `LocationSource` (T037), emitting positions with timestamps, accuracy and `provider = simulated`.
- [ ] An `integration_test` drives a full visit on the emulator with replay: start, 10 observations, a plant polygon, finish, sync. It asserts the server state through the API.
- [ ] Documents Android emulator GPX playback (Extended controls → Location) as an alternative.

### T073 · Evaluation instrumentation in the app
[#90](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/90) · E11 · P1 · must · labels: `mobile`, `evaluation`, `must` · implements F61 · est. 1.5 d · **todo**

Depends on: T035, T045

- [ ] An **Evaluation mode** toggle in settings (off by default). When on, events are logged to a local table:
  - opening the visit form and starting a visit (time to start)
  - opening the observation sheet and saving (entry time)
  - taps inside the observation sheet (via a `Listener` wrapper)
  - validation errors shown
  - sync start and end, with bytes and outcome
- [ ] **Export events as CSV** via the share sheet (`share_plus`), with a session id and device info header.
- [ ] Logging adds less than 5 ms per event (no UI jank).

### T074 · Performance, sync robustness and battery tests
[#91](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/91) · E11 · P1 · must · labels: `evaluation`, `backend`, `mobile`, `must` · implements F61 · est. 2 d · **todo**

Depends on: T030, T059, T071, T072

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

### T075 · Usability kit and Part 1 evaluation run
[#92](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/92) · E11 · P1 · must · labels: `evaluation`, `docs`, `must` · implements F61 · est. 2 d · **todo**

Depends on: T070, T073, T074

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

### T076 · Standards study: SensorThings API
[#93](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/93) · E12 · P2 · must · labels: `research`, `docs`, `must` · implements F89 · est. 1 d · **todo**

Depends on: —

- [ ] `docs/standards/sensorthings.md` covers:
  - the STA 1.1 entity model (Thing, Location, HistoricalLocation, Sensor, ObservedProperty, Datastream, Observation, FeatureOfInterest)
  - the mapping to this project, with the example from outline §9.2 adapted to simulated stations
  - FROST-Server (version, persistence, plugins)
  - how pygeoapi bridges STA (SensorThings Features provider, SensorThingsEDR provider)
  - MQTT (described, not implemented; F51 removed)
  - what is simulated and why
- [ ] It includes a diagram of entity relations and data flow (simulator → FROST → Django snapshots → exports).
- [ ] References the OGC standard document and FROST docs with versions.

### T077 · FROST-Server deployment
[#94](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/94) · E12 · P2 · must · labels: `infra`, `ogc`, `must` · implements F47 · est. 1.5 d · **todo**

Depends on: T002, T069, T076

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

### T078 · Sensor station links and registration in FROST from Django admin
[#95](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/95) · E12 · P2 · must · labels: `backend`, `admin`, `database`, `ogc`, `must` · implements F48, F49 · est. 2 d · **todo**

Depends on: T021, T077

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

### T079 · Sensor data simulator
[#96](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/96) · E12 · P2 · must · labels: `backend`, `infra`, `must` · implements F69 · est. 2.5 d · **todo**

Depends on: T071, T078

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

### T080 · Station map layer and OGC collections
[#97](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/97) · E12 · P2 · should · labels: `ogc`, `mobile`, `should` · implements F49 · est. 1.5 d · **todo**

Depends on: T068, T078, T079

- [ ] View `geo.sensor_stations` (id, project, code, name, habitat type, simulated, geometry) and pygeoapi collection **`sensor-stations`** (PostgreSQL provider), giving the outline §9.1 collection.
- [ ] A second collection, **`sta-datastreams`**, uses pygeoapi's **SensorThings** Features provider directly on FROST (`data: http://frost:8080/FROST-Server/v1.1/`, `entity: Datastreams`, `expand: Thing/Locations,Observations($orderby=phenomenonTime desc;$top=1)`). This shows pygeoapi as an STA bridge.
- [ ] App map layer "Sensor stations" (from pulled `sensor_station_links`). The popup shows the latest values online via `GET /api/v1/stations/{id}/latest`, where Django queries FROST. When offline it shows "Latest values need a connection".
- [ ] Both collections open in QGIS.

### T081 · Environmental snapshots from SensorThings
[#98](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/98) · E12 · P2 · must · labels: `backend`, `ogc`, `must`, `p2-compat` · implements F50 · est. 2 d · **todo**

Depends on: T063, T079

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

### T082 · Standards study: OGC API – EDR
[#99](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/99) · E13 · P2 · must · labels: `research`, `docs`, `must` · implements F89 · est. 1 d · **todo**

Depends on: —

- [ ] `docs/standards/edr.md` covers:
  - query types (position, area, cube, trajectory, corridor, radius, items, locations, instances)
  - response formats (CoverageJSON, GeoJSON, CSV)
  - pygeoapi providers and their supported queries
  - how EDR differs from SensorThings (data retrieval vs sensor management)
  - the butterfly use cases: weather at visit time and place, seasonal series per site
  - which use cases are possible with available providers and which are not
- [ ] A short table: use case, EDR query, provider, status.

### T083 · EDR collections in pygeoapi
[#100](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/100) · E13 · P2 · must · labels: `ogc`, `infra`, `must` · implements F52 · est. 2 d · **todo**

Depends on: T068, T079, T082

- [ ] Collection **`weather-stations`**:
  - provider `SensorThingsEDR`, `data: http://frost:8080/FROST-Server/v1.1/`
  - plus the matching `SensorThings` feature provider required for `items` (per pygeoapi docs)
  - working queries: `/locations/{id}?datetime=…&parameter-name=…`, `/area?coords=POLYGON(…)&datetime=…`, `/cube?bbox=…&datetime=…`
- [ ] **Grid export:** the simulator (T079) gains `export-grid --resolution 250m --from --to --out /data/weather_grid.nc`. It writes a NetCDF over the project area, hourly, with variables `tas` (°C), `hurs` (%), `wind_speed` (m/s) and `rsds` (W/m²), interpolated from stations with inverse-distance weighting, and with CF-convention attributes.
- [ ] Collection **`weather-grid`**: provider `xarray-edr` on that NetCDF (`x_field: lon`, `y_field: lat`, `time_field: time`). Working queries: `/position?coords=POINT(lon lat)&datetime=…` and `/cube?bbox=…`.
- [ ] Both are behind `/ogc/` auth (T069). A smoke script runs each query type and checks for a 200 with CoverageJSON.

### T084 · Weather for a visit via EDR
[#101](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/101) · E13 · P2 · must · labels: `backend`, `ogc`, `must` · implements F53 · est. 1.5 d · **todo**

Depends on: T081, T083

- [ ] The service calls pygeoapi internally (`http://pygeoapi/collections/weather-grid/position?coords=POINT(x y)&datetime=start/end&parameter-name=tas,hurs,wind_speed,rsds&f=json`), parses the CoverageJSON, and stores `visit_mean`, `start` and `end` snapshots with `source_type = edr`, `source_uri` = the query URL, and `is_simulated = true`.
- [ ] Triggered like T081 (on commit plus a backfill command `fetch_edr_snapshots --missing`).
- [ ] Export plus a notebook cell comparing manual vs STA vs EDR per visit (temperature and wind) for the thesis.

### T085 · Weather auto-fill in the app
[#102](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/102) · E13 · P2 · should · labels: `mobile`, `backend`, `should`, `p2-compat` · implements F55 · est. 1.5 d · **todo**

Depends on: T035, T084

- [ ] `GET /api/v1/weather/current?lat=&lon=&time=` is available to researchers. Django calls the EDR grid (position) and returns:
  - temperature
  - wind in m/s and converted to Beaufort
  - humidity
  - a cloud-cover estimate (1 − rsds/clear-sky)
  - `source: "edr (simulated)"`
- [ ] In the start-visit and finish forms, an **Auto-fill weather** button (the T035 slot) fills the fields and marks them "auto". Any edit clears the mark. The button is hidden when offline.
- [ ] Adds `survey_visit.weather_source` (`manual` | `edr_autofill` | `edr_autofill_edited`): a nullable server column plus a Drift migration step.
- [ ] A clear "Simulated data" badge appears while auto-filled values are shown.

### T086 · Standards study: OGC API – Moving Features
[#103](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/103) · E14 · P2 · must · labels: `research`, `docs`, `must` · implements F89 · est. 1 d · **todo**

Depends on: —

- [ ] `docs/standards/moving-features.md` covers:
  - the MF-JSON encoding
  - OGC API – MF Part 1 resources: collections, items (MovingFeature), `tgsequence` (temporal geometry), `tproperties` (temporal properties)
  - temporal geometry types and interpolation
  - MobilityDB/MEOS types (`tgeompoint`, `tgeogpoint`, `ttext`) and how they map to MF-JSON
  - pygeoapi status (roadmap only), the AIST fork, and other implementations found
  - the GPS-accuracy caveat and how a focal follow is recorded (observer GPS vs tapped estimates)
- [ ] Records the exact standard document version (VERIFY the current OGC API – MF Part 1 document number and status).

### T087 · MobilityDB research and design spike
[#104](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/104) · E14 · P2 · must · labels: `research`, `database`, `must` · implements F70 · est. 2 d (time-boxed) · **todo**

Depends on: T071, T086

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

### T088 · Enable MobilityDB and trajectory storage
[#105](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/105) · E14 · P2 · must · labels: `database`, `infra`, `must` · implements F57 · est. 2 d · **todo**

Depends on: T087, T089

- [ ] The DB service sets `shared_preload_libraries = 'postgis-3'` and `max_locks_per_transaction = 128` via `command:` arguments, if MobilityDB requires them (VERIFY in the image docs).
- [ ] Django migration: `CREATE EXTENSION IF NOT EXISTS mobilitydb CASCADE;`.
- [ ] Creates `mobility` schema **only if ADR option A** needs it. Otherwise the tables live in `public`.
- [ ] Tables are rebuilt by SQL functions called after pushes (`on_commit`) and by `manage.py rebuild_trajectories`:
  - `focal_follow_trajectory`: one row per session, built from `focal_follow_point`
  - `visit_route_trajectory`: one row per visit, built from `survey_track_point`. This shows Phase 1 data reused in Phase 2 with no schema change.
- [ ] Backups and restore tested with MobilityDB data (same version on both sides).

### T089 · Focal-follow data model and sync
[#106](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/106) · E14 · P2 · must · labels: `backend`, `database`, `sync`, `must` · implements F58 · est. 2 d · **todo**

Depends on: T026, T044, T087

- [ ] Models below. New push/pull entity types: `focal_follow_session`, `focal_follow_point` (with `create_batch`) and `trajectory_event`.
- [ ] A session links to the `ButterflyObservation` with `source = focal_follow` created at start (same taxon), and optionally to the visit during which it happened.
- [ ] Locking (T042) also covers sessions attached to locked visits.
- [ ] Admin: a session list with a map of points and an events inline.

### T090 · App focal-follow session
[#107](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/107) · E14 · P2 · must · labels: `mobile`, `must` · implements F58 · est. 2.5 d · **todo**

Depends on: T037, T045, T089

- [ ] **Start:** "Follow an individual" from the active visit or project home. Pick the species (quick picker from T045) and an optional label (for example "F1"). This creates the session and its `focal_follow` observation.
- [ ] **Position modes:**
  - **Observer GPS**: 1–2 s interval via `LocationSource`
  - **Tap estimate**: tap the map where the butterfly is now; each tap records a point with the current time
  - **Mixed**: both at once
- [ ] An event button row: land, feed, rest (start/stop), territorial, oviposit (links a plant), road crossing, lost sight (ends the session).
- [ ] **Stop** shows a summary: duration, path length, number of events, and a mini-map of the path.
- [ ] A banner shows GPS accuracy, with the warning "Phone GPS is too coarse for small movements; prefer tap estimates" when accuracy is over 5 m (outline §9.3).
- [ ] Works offline. Points are batched like track points.

### T091 · Behaviour events on trajectories
[#108](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/108) · E14 · P2 · should · labels: `backend`, `database`, `should` · implements F59 · est. 1.5 d · **todo**

Depends on: T053, T088, T089

- [ ] **`habitat_change`:** intersect the trajectory with habitat-feature polygons and create an event at each entry into a different habitat type (MobilityDB `atGeometry`/`eintersects`, VERIFY names, or the PostGIS fallback over consecutive points).
- [ ] **Stops:** speed below 0.2 m/s for at least 10 s creates a `resting` event with `ended_at` (MobilityDB `speed()` plus `whenTrue`/`atValues`, VERIFY names).
- [ ] Derived events have `derived = true`. Rebuilding deletes and recreates only derived events.
- [ ] Events are exposed as temporal properties in the MF API (T093).

### T092 · Moving Features API: service and collections
[#109](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/109) · E14 · P2 · must · labels: `ogc`, `infra`, `must` · implements F56 · est. 2 d · **todo**

Depends on: T087, T088

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

### T093 · Moving Features API: temporal geometry and properties
[#110](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/110) · E14 · P2 · must · labels: `ogc`, `must` · implements F56, F59 · est. 1.5 d · **todo**

Depends on: T092
Notes: behaviour tproperty needs T091

- [ ] `items/{id}/tgsequence` returns a MF-JSON `MovingPoint` (coordinates, datetimes, interpolation `Linear`), generated with MobilityDB `asMFJSON(trip)` (VERIFY the function and output shape).
- [ ] `items/{id}/tproperties` lists `behaviour` (ttext, step interpolation, from events) and `speed` (tfloat, linear). `items/{id}/tproperties/{name}` returns values over time.
- [ ] `?datetime=` sub-setting on `tgsequence` uses MobilityDB `atTime` (VERIFY).
- [ ] Output validates against the MF-JSON schema (VERIFY the schema location) in a test.
- [ ] Conformance classes are declared honestly (partial where applicable).

### T094 · Trajectory display
[#111](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/111) · E14 · P2 · must · labels: `mobile`, `ogc`, `must` · implements F60 · est. 2 d · **todo**

Depends on: T090, T093

- [ ] **App:** a focal-follow detail screen with the path polyline coloured by speed, event markers, and a **time slider** moving a marker along the path (interpolated locally from points). The map layer "Focal follows" is added to T059.
- [ ] **QGIS:** view `geo.focal_follow_points` (point, time, session, method) as a pygeoapi Features collection, animated with the Temporal Controller. Screenshots for the thesis.
- [ ] **MF client:** load `/ogc-mf/` or `/api/v1/mf/` in an MF-API-capable client, for example STINUUM (used in the FOSS4G 2026 MF workshop; VERIFY setup), or a small Leaflet/MapLibre page in `evaluation/mf-viewer/` that reads `tgsequence`.
- [ ] Recorded results feed T095.

### T095 · Interoperability and conformance evaluation of SensorThings, EDR and Moving Features
[#112](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/112) · E15 · P2 · must · labels: `evaluation`, `ogc`, `must` · implements F61 · est. 2 d · **todo**

Depends on: T083, T094
Notes: pygeoapi STA bridge test needs T080

- [ ] **SensorThings:**
  - QGIS native SensorThings provider (VERIFY version)
  - a Python client (`requests` or an STA client library)
  - optional: OGC CITE `ets-sta10`, if available (VERIFY)
- [ ] **EDR:** a Python notebook reading CoverageJSON for each supported query, with a check for QGIS or another EDR client (VERIFY), and the EDR CITE suite if available.
- [ ] **Moving Features:** STINUUM or the custom viewer (T094), plus validation of MF-JSON output.
- [ ] Response times (p50/p95) for typical requests on the simulated season.
- [ ] Results table (standard, client, operation, result, time, notes) in `evaluation/interop/part2-results.md`.

### T096 · PostGIS vs MobilityDB comparison
[#113](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/113) · E15 · P2 · should · labels: `evaluation`, `database`, `should` · implements F61, F70 · est. 1.5 d · **todo**

Depends on: T087, T088, T091

- [ ] The same six queries (T087) on the simulated season: all observer routes, plus simulated focal follows (add a generator option to T071 if needed), in both implementations.
- [ ] Metrics: execution time (median of 10 runs, warm cache), SQL lines, correctness check (results equal within tolerance), storage size.
- [ ] A results table and a short discussion in `evaluation/results/postgis-vs-mobilitydb.md`.

### T097 · Standards comparison write-up
[#114](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/114) · E15 · P2 · must · labels: `research`, `docs`, `must` · implements F89 · est. 1 d · **todo**

Depends on: T095
Notes: + T096 if done

- [ ] `docs/standards/comparison.md` has a table per standard: purpose in this system, implementation used, effort (days from these tickets), maturity of tools, client support found, limitations, and recommendation.
- [ ] It states plainly that sensor data is simulated, along with the GPS-accuracy caveat for Moving Features.
