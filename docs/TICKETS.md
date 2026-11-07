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
- **2a · Accounts and projects:** T011, T013, T014, T012, T015, T016, T018, T098, T017
- **2b · Catalogues and transects:** T019, T020, T021, T022, T024
- **3 · Sync core:** T025, T026, T029, T030, T027, T028, T031, T032
- **4 · Field visit and observations:** T033, T034, T035, T036, T037, T042, T039, T044, T045, T055, T040, T041, T043, T038
- **5 · Photos, environment, export, OGC:** T049, T105, T106, T050, T063, T064, T067, T068, T069, T059
- **5b · Should/Could fill (moved before stage 6 on 2026-10-30: Must work is ahead of schedule):** T046, T107, T048, T109, T051, T052, T053, T054, T058, T057, T056, T104, T100, T047, T110, T108, T061, T101, T102, T062, T065, T023, T060, T066, T099, T103, T111, T112, T113
- **6 · Simulation and evaluation:** T071, T072, T070, T073, T074, T075, T114
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
| T004 | [#21](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/21) | Database schema strategy: `geo` schema and read-only role | P1 | must | T003 | 1 d | done |
| T005 | [#22](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/22) | Syncable base model and server-version trigger | P1 | must | T004 | 1.5 d | done |
| T006 | [#23](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/23) | Flutter app foundation | P1 | must | — | 2 d | done |
| T007 | [#24](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/24) | Walking skeleton: one observation from phone to QGIS | P1 | must | T002, T003, T004, T005, T006 | 3 d | done |
| T008 | [#25](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/25) | CI pipeline (GitHub Actions) | P1 | must | T003, T006 | 1 d | dropped |
| T009 | [#26](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/26) | Phone-to-laptop connectivity: Tailscale and USB | P1 | must | T002, T006 | 1 d | done |
| T010 | [#27](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/27) | Backup and restore scripts | P1 | must | T002 | 1 d | done |
| T011 | [#28](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/28) | Custom user model and JWT auth endpoints | P1 | must | T003 | 1.5 d | done |
| T012 | [#29](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/29) | App login, secure token storage, refresh and logout | P1 | must | T006, T011 | 2 d | done |
| T013 | [#30](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/30) | Two roles: groups, permissions and access rules | P1 | must | T011 | 1.5 d | done |
| T014 | [#31](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/31) | Django admin foundation | P1 | must | T013 | 1 d | done |
| T015 | [#32](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/32) | Project and membership models, API and admin | P1 | must | T005, T013, T014 | 2 d | done |
| T016 | [#33](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/33) | Project protocol settings and study area | P1 | must | T001, T015 | 1.5 d | done |
| T017 | [#34](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/34) | App project list and project home | P1 | must | T012, T015 | 1.5 d | done |
| T018 | [#35](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/35) | Audit log with django-simple-history | P1 | must | T015 | 1.5 d | done |
| T019 | [#36](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/36) | Taxon catalogue, versioned | P1 | must | T005, T015 | 2 d | done |
| T020 | [#37](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/37) | Plant taxa and editable codelists | P1 | must | T005 | 1.5 d | done |
| T021 | [#38](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/38) | Transect and section models and API | P1 | must | T015, T020 | 2 d | done |
| T022 | [#39](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/39) | Map-based transect and section editor in admin | P1 | must | T014, T021 | 2 d | done |
| T023 | [#40](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/40) | Catalogue admin tools | P1 | should | T019, T020 | 1.5 d | done |
| T024 | [#41](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/41) | Seed data: butterflies of Serbia, plant list, codelists, demo project | P1 | must | T019, T020, T021 | 2 d | done |
| T025 | [#42](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/42) | Pull API with server-version cursor | P1 | must | T005, T015, T019, T020, T021 | 2 d | done |
| T026 | [#43](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/43) | Push API with idempotent mutations | P1 | must | T025 | 2.5 d | done |
| T027 | [#44](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/44) | Conflict detection and SyncConflict model | P1 | must | T018, T026 | 2 d | done |
| T028 | [#45](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/45) | Django admin conflict resolution screen | P1 | must | T014, T027 | 1.5 d | done |
| T029 | [#46](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/46) | App sync queue | P1 | must | T006 | 1.5 d | done |
| T030 | [#47](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/47) | App sync runner: push, pull, retry and backoff | P1 | must | T025, T026, T029 | 2.5 d | done |
| T031 | [#48](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/48) | App offline package download and status | P1 | must | T030 | 1.5 d | done |
| T032 | [#49](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/49) | App sync status screen | P1 | must | T030 | 1.5 d | done |
| T033 | [#50](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/50) | App transect list and transect detail | P1 | must | T017, T021, T031 | 2 d | done |
| T034 | [#51](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/51) | SurveyVisit model, lifecycle and API | P1 | must | T021, T026 | 2.5 d | done |
| T035 | [#52](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/52) | App start-visit form | P1 | must | T016, T033, T034 | 1.5 d | done |
| T036 | [#53](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/53) | Track points: model, batch sync and walked distance | P1 | must | T026, T034 | 1.5 d | done |
| T037 | [#54](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/54) | App GPS tracking with an Android foreground service | P1 | must | T035, T036 | 3 d | done |
| T038 | [#55](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/55) | Battery-saving mode and GPS gap detection | P1 | must | T037 | 1 d | done |
| T039 | [#56](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/56) | App active visit screen | P1 | must | T037 | 2.5 d | done |
| T040 | [#57](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/57) | Finish visit: summary, warnings and end weather | P1 | must | T039, T055 | 2 d | done |
| T041 | [#58](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/58) | True-zero confirmation and cancelled-visit reasons | P1 | must | T040 | 1 d | done |
| T042 | [#59](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/59) | Visit lock enforced in the API | P1 | must | T026, T034 | 1 d | done |
| T043 | [#60](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/60) | Admin visit review, lock and unlock with mandatory reason | P1 | must | T018, T042 | 1.5 d | done |
| T044 | [#61](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/61) | ButterflyObservation model and API | P1 | must | T019, T026, T034 | 2.5 d | done |
| T045 | [#62](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/62) | App quick butterfly entry | P1 | must | T039, T044 | 2.5 d | done |
| T046 | [#63](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/63) | App extended entry | P1 | should | T045 | 1.5 d | done |
| T047 | [#64](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/64) | Incidental and other-source observations | P1 | should | T045 | 1 d | done |
| T048 | [#65](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/65) | Automatic section assignment | P1 | should | T044 | 1 d | done |
| T049 | [#66](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/66) | Photo model and upload API with SHA-256 deduplication | P1 | must | T003, T044 | 2.5 d | done |
| T050 | [#67](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/67) | App photo capture, compression and upload | P1 | must | T030, T045, T049, T106 | 2.5 d | done |
| T051 | [#68](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/68) | PlantResourceObservation model and API | P1 | should | T020, T044, T049 | 1.5 d | done |
| T052 | [#69](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/69) | App plant entry with point and polygon drawing | P1 | should | T050, T051 | 2.5 d | done |
| T053 | [#70](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/70) | HabitatFeature model and API | P1 | should | T020, T026 | 1.5 d | done |
| T054 | [#71](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/71) | App habitat feature entry | P1 | should | T052, T053 | 1.5 d | done |
| T055 | [#72](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/72) | Input validation rules (shared by app and server) | P1 | must | T016, T034, T044 | 2 d | done |
| T056 | [#73](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/73) | Automatic quality flags | P1 | should | T036, T048, T055 | 1.5 d | done |
| T057 | [#74](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/74) | Admin validation queue | P1 | should | T014, T049, T058 | 2 d | done |
| T058 | [#75](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/75) | Validation history | P1 | should | T044 | 1 d | done |
| T059 | [#76](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/76) | App map screen with layers and filters | P1 | must | T036, T044 | 2.5 d | done |
| T060 | [#77](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/77) | Offline basemap from MBTiles | P1 | could | T031, T059 | 2 d | done |
| T061 | [#78](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/78) | Indicators: server SQL views and admin report | P1 | should | T041, T044, T058 | 1.5 d | done |
| T062 | [#79](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/79) | App statistics screen | P1 | should | T041, T044 | 1.5 d | done |
| T063 | [#80](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/80) | EnvironmentalSnapshot model with manual source | P1 | must | T034, T044 | 1 d | done |
| T064 | [#81](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/81) | Export service and admin-only export API | P1 | must | T044, T063 | 2.5 d | done |
| T065 | [#82](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/82) | Admin export actions | P1 | should | T064 | 1 d | done |
| T066 | [#83](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/83) | GeoPackage export | P1 | could | T064, T067 | 1 d | done |
| T067 | [#84](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/84) | `geo` views for the five collections | P1 | must | T004, T021, T044 | 2 d | done |
| T068 | [#85](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/85) | pygeoapi collections, filtering and paging | P1 | must | T007, T067 | 1.5 d | done |
| T069 | [#86](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/86) | Token-protected pygeoapi access for admins | P1 | must | T011, T013, T068 | 1.5 d | done |
| T070 | [#87](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/87) | QGIS interoperability and OGC conformance test | P1 | must | T069, T071 | 1.5 d | todo |
| T071 | [#88](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/88) | Simulated field-day generator | P1 | must | T024, T026, T036, T044, T049 | 2.5 d | done |
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
| T096 | [#113](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/113) | PostGIS vs MobilityDB comparison | P2 | must | T087, T088 | 1.5 d | todo |
| T097 | [#114](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/114) | Standards comparison write-up | P2 | must | T095 | 1 d | todo |
| T098 | [#115](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/115) | Study area editor: edit and remove single polygons, with in-map help | P1 | must | T016 | 0.5 d | done |
| T099 | [#116](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/116) | Close a project: no new visits after it is closed | P1 | should | T015, T034, T035 | 1 d | done |
| T100 | [#117](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/117) | Server-side route coverage and the valid-visit rule | P1 | should | T036, T040, T056 | 1 d | done |
| T101 | [#118](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/118) | Research-question analysis views (Q1, Q3, Q4, Q6) | P1 | should | T044, T048, T051, T053, T061, T071 | 2.5 d | done |
| T102 | [#119](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/119) | Spatial index benchmark on the simulated season | P1 | should | T048, T056, T071 | 1 d | done |
| T103 | [#120](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/120) | Linear referencing: positions along the transect | P1 | could | T044, T048, T067 | 1 d | done |
| T104 | [#121](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/121) | App reads the protocol's time zone (rule W07) | P1 | should | T055, T035 | 1 d | done |
| T105 | [#122](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/122) | Project home: the Start visit tile, and tiles not built yet | P1 | must | T017, T033, T035, T039 | 0.5 d | done |
| T106 | [#123](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/123) | App visit detail and observation detail | P1 | must | T033, T040, T041, T045 | 1.5 d | done |
| T107 | [#124](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/124) | App shows photos that are not on this phone | P1 | should | T050, T106 | 0.5 d | done |
| T108 | [#125](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/125) | Route proposals from the field | P1 | should | T022, T026, T037 | 2 d | done |
| T109 | [#126](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/126) | Admin group gets a new model's permissions on the same migrate | P1 | should | T013 | 0.5 d | done |
| T110 | [#127](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/127) | App adds an observation to a finished visit | P1 | should | T045, T046, T106 | 1.5 d | done |
| T111 | [#128](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/128) | Admin adds and edits plant records on a map | P1 | could | T051, T052 | 2 d | done |
| T112 | [#129](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/129) | Project members see each other's plants, habitat features and observations | P1 | could | T051, T052, T053, T054, T059, T062 | 6 d | done |
| T113 | [#130](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/130) | Admin adds a butterfly observation to a visit, with photos | P1 | could | T043, T110, T111 | 3 d | done |
| T114 | [#131](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/131) | Spatial index benchmark with a larger plant and habitat table | P1 | could | T071, T075, T102 | 1 d | todo |

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
[#21](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/21) · E01 · P1 · must · labels: `database`, `must`, `p2-compat` · implements F45 · est. 1 d · **done**

Note: the "test connects as pygeoapi_ro" check was done by hand with `SET ROLE` (D-021).

Depends on: T003

- [ ] Migration `core/0001_schemas` creates the `geo` schema owned by `django_app` and grants `USAGE ON SCHEMA geo TO pygeoapi_ro`.
- [ ] `ALTER DEFAULT PRIVILEGES FOR ROLE django_app IN SCHEMA geo GRANT SELECT ON TABLES TO pygeoapi_ro;` makes every future view readable automatically.
- [ ] `pygeoapi_ro` has **no** privileges on `public` tables. A test connects as `pygeoapi_ro` and gets `permission denied` on `SELECT * FROM public.app_user`.
- [ ] `core/migration_ops.py` provides `CreateView(name, sql)`, a `RunSQL` wrapper with reverse `DROP VIEW`, used by T067.
- [ ] `docs/architecture/database.md` explains the layout (A.5 item 1) and why the outline's `app`/`audit`/`sensorthings`/`mobility` schemas are not used in Phase 1.

### T005 · Syncable base model and server-version trigger
[#22](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/22) · E01 · P1 · must · labels: `backend`, `database`, `sync`, `must` · implements F25, F45 · est. 1.5 d · **done**

Depends on: T004

Note: the "(tested)" checks for version bumps and two-connection ordering were done by hand with a temporary table (D-021); see D-029.

- [ ] `core.models.SyncableModel` (abstract) exists with the fields below. `SyncableQuerySet.alive()` excludes soft-deleted rows.
- [ ] Migration `core/0002_sync_version` creates the sequence and trigger function. `AttachSyncTrigger(table)` is a reusable migration operation used by every model ticket.
- [ ] Insert and update both bump `server_version`, including `QuerySet.update()` and admin saves (tested).
- [ ] Two concurrent transactions writing to synced tables commit their versions in order (test with two connections: the second blocks until the first commits).
- [ ] Hard delete is disabled for synced models in services and admin. `soft_delete()` sets `deleted_at` instead.

### T006 · Flutter app foundation
[#23](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/23) · E01 · P1 · must · labels: `mobile`, `must` · implements F23, F72 · est. 2 d · **done**

Deferred: confirm that `butterfly.sqlite` is created on the phone. Nothing opens `AppDatabase` yet, so check it when the first ticket reads or writes a table (T007).

Depends on: —

- [ ] `mobile/` is Android-only (`flutter create --platforms=android`). Package id: `rs.<you>.butterfly` (choose).
- [ ] Folders: `lib/core/` (config, http, db, location), `lib/features/<feature>/` (data, domain, ui), `lib/app.dart`.
- [ ] Riverpod for state, go_router for navigation, dio for HTTP. Logging uses `logger` in debug only.
- [ ] `AppDatabase` (Drift) opens `butterfly.sqlite` with `schemaVersion = 1` and a migration strategy using `drift_dev make-migrations` (schema snapshots committed under `mobile/drift_schemas/`).
- [ ] Settings screen: server URL with presets **Tailscale** (`https://<laptop>.<tailnet>.ts.net`) and **USB** (`http://localhost:8080`), plus a "Test connection" button calling `/api/v1/health/`.
- [ ] `build.yaml` sets `store_date_time_values_as_text: true`.
- [ ] `flutter analyze` is clean, and one widget test runs.

### T007 · Walking skeleton: one observation from phone to QGIS
[#24](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/24) · E01 · P1 · must · labels: `backend`, `mobile`, `ogc`, `must` · implements F78 · est. 3 d · **done**

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
[#26](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/26) · E01 · P1 · must · labels: `infra`, `mobile`, `must` · implements F44 · est. 1 d · **done**


Note: the criteria were checked by hand on the developer's laptop and phone (D-021, D-030). The Android cleartext config was written by the developer.
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
[#27](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/27) · E01 · P1 · must · labels: `infra`, `must` · implements F46 · est. 1 d · **done**

Note (T049): the photo-in-admin check is now possible: run the restore test in `docs/setup/backup.md` again and open the photo at `/admin/observations/photo/`.
Note: the "photo opens in admin" check waited for T049 (no photo model yet); the object was checked in the MinIO bucket instead. The sandbox could not run the wipe, so the developer ran backup and restore by hand.

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
[#28](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/28) · E02 · P1 · must · labels: `backend`, `security`, `must` · implements F1 · est. 1.5 d · **done**

Note: skipped the "tests cover…" criterion (D-021); checked by hand with curl. `accounts.User` already existed from T003 (D-026), so T011 added the endpoints, throttling, token blacklist and the case-insensitive email index. `/auth/me` returns empty `groups` until T013 and empty `project_ids` until T015 (D-032). No sign-up endpoint (D-033).

Depends on: T003

- [ ] `accounts.User` uses `email` as the login, a UUID primary key and the fields `name` and `organization`. It is created in the **first** migration of the project.
- [ ] `POST /api/v1/auth/login` with `{email, password}` returns `{access, refresh, user}`.
- [ ] `POST /api/v1/auth/refresh` rotates the refresh token and blacklists the old one.
- [ ] `POST /api/v1/auth/logout` with `{refresh}` blacklists it and returns 205.
- [ ] `GET /api/v1/auth/me` returns `{id, email, name, organization, groups: ["researcher"|"admin"], project_ids: [...]}`.
- [ ] Inactive users cannot log in. Five failed logins per email within 15 minutes return 429 (cache-based counter).
- [ ] Tests cover login, refresh rotation, logout blacklist, and an inactive user.

### T012 · App login, secure token storage, refresh and logout
[#29](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/29) · E02 · P1 · must · labels: `mobile`, `security`, `must` · implements F1 · est. 2 d · **done**

Note: the two widget-test files (`mobile/test/auth_test.dart`, `widget_test.dart`) cover form validation and the interceptor refresh because the ticket asks for them. "N changes not yet synced" and "sync first" use placeholder providers in `core/sync/sync_status.dart` (count 0, sync-now false) until T030 supplies the real ones, so that dialog cannot appear yet.

Depends on: T006, T011

- [ ] The login screen has email and password fields, shows errors, and shows the **last successful sync time** (outline §11.2 A).
- [ ] Tokens and the `/auth/me` profile are stored in `flutter_secure_storage` (Android Keystore-backed).
- [ ] A dio interceptor refreshes the access token on 401 exactly once, with concurrent requests waiting on the same refresh. If refresh fails, it goes to the login screen without deleting local data.
- [ ] **Offline start:** if a refresh token and cached profile exist, the app opens without network. Login is only required when no session exists.
- [ ] On logout, if local unsynced changes exist, the app warns "N changes not yet synced" and offers sync first. Logout never deletes the local database. A separate "Remove all local data" option in settings has a confirmation step.
- [ ] Widget tests cover the login form validation and the interceptor refresh.

### T013 · Two roles: groups, permissions and access rules
[#30](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/30) · E02 · P1 · must · labels: `backend`, `admin`, `security`, `must` · implements F2, F62 · est. 1.5 d · **done**

Depends on: T011

Note: skipped the "(tested)" parts (D-021); checked by hand. Admin-as-researcher scoping (own records) is a queryset filter in later endpoint tickets. See D-034.

- [ ] A data migration creates groups `researcher` (no model permissions; app only) and `admin` (all permissions of this project's apps). A later migration helper `sync_admin_group_permissions()` re-grants after new models are added. It runs in a `post_migrate` signal. (Since T109, D-085, it acts on the last app's signal, so a new model is granted on the same `migrate`.)
- [ ] Adding a user to `admin` sets `is_staff=True`, and removing them sets it back to `False` (`m2m_changed` signal). Researchers cannot log into `/admin/` (tested).
- [ ] DRF permission classes:
  - `IsAdminGroup`
  - `IsProjectMember` (object or `project_id` in payload)
  - `IsOwnerOrAdmin` (record `created_by == request.user`)
- [ ] Admin-only endpoints (exports, auth verify for pygeoapi) return 403 for researchers (tested).
- [ ] An admin who uses the app behaves exactly like a researcher there (sees own records), plus can see all projects.

### T014 · Django admin foundation
[#31](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/31) · E02 · P1 · must · labels: `admin`, `must` · implements F62 · est. 1 d · **done**

Deferred (`SyncableAdmin` checked in T015, `MapAdmin` checked in T016; only the T022 transect editor is left to try): `MapAdmin` and `SyncableAdmin` were only checked from the shell (no model uses them yet). Open a
change form in the browser when the first model with a map admin lands: T016 (`Project.area`, check that the
map centres on the area) and T022 (transect editor). Also try "Soft delete selected" and the "Deleted" filter
on the first `SyncableAdmin` model (T015).

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
[#32](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/32) · E02 · P1 · must · labels: `backend`, `admin`, `database`, `must` · implements F3 · est. 2 d · **done**

Deferred: "Projects are synced (pull) to members" waits for T025, which has no endpoint yet. Use `projects_for(user)` there.

Note: no test criteria to skip. Also added: "Restore selected" action on `SyncableAdmin`, `Project.clean()` for the end-date error, theme-safe admin CSS (D-037).  `apps.projects.services.projects_for(user)` is the scope the pull must use. `transect_count` is a constant 0 until T021 (TODO there). A minimal `accounts.User` admin was added because the membership inline needs it for user autocomplete.

Depends on: T005, T013, T014

- [ ] `Project` and `ProjectMembership` models with admin: a project change form with a `ProjectMembership` inline (user autocomplete).
- [ ] `GET /api/v1/projects` returns the caller's projects (all projects for admins), with `transect_count` and `period`.
- [ ] `GET /api/v1/projects/{id}` returns 404 for non-members (not 403, so project existence isn't leaked).
- [ ] Removing a membership hides the project from that user's next pull. Local data on their phone is not deleted (documented).
- [ ] Projects are synced (pull, T025) to members.

### T016 · Project protocol settings and study area
[#33](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/33) · E02 · P1 · must · labels: `backend`, `admin`, `database`, `must` · implements F71, F73 · est. 1.5 d · **done**

Deferred: the protocol summary on the app's transect detail screen (T033) and the "changing a threshold changes the next flag" check (T056); the pull (T025) reuses the project serializer that now carries `area` and `protocol`.

Depends on: T001, T015

- [ ] A `ProjectProtocol` one-to-one model, edited as an inline on the project admin. Defaults come from T001. Creating a project auto-creates its protocol (signal).
- [ ] `Project.area` (MultiPolygon, optional) is drawn in the admin map widget or uploaded as GeoJSON/KML via an admin action.
- [ ] Both are included in pull, and the app shows a protocol summary on the transect detail screen (T033).
- [ ] Changing a threshold changes the next flag computation (tested with T056).

### T017 · App project list and project home
[#34](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/34) · E02 · P1 · must · labels: `mobile`, `must` · implements F3, F72 · est. 1.5 d · **done**

Depends on: T012, T015
Notes: badges fill in once T029 and T031 land

- [ ] The project list (outline §11.2 B) shows each project's name, period, number of downloaded transects, number of unsynced changes and offline package status (`not downloaded` / `ready` / `update available`).
- [ ] Project home tiles (outline §11.2 C, minus the validation tab): **Start visit**, **Transects**, **Free observation**, **Plants & habitat**, **Map**, **Unsynced data** (with badge), **Statistics**.
- [ ] The last selected project is remembered.
- [ ] Everything works offline once the package is downloaded.

Deferred: the downloaded-transect count, the unsynced count and the offline package status are placeholder providers in `features/projects/domain/project_stats.dart` (0, 0, `not downloaded`). T030 fills the unsynced count and T031 the transect count and package status. Until the pull exists, the project list is refreshed from `GET /api/v1/projects` (D-042).

Update (T031): the transect count and the offline package status are now real (`project_stats.dart`); the unsynced count already was (T030). The card has the Download / Update button (D-055).

Update (T032): the **Unsynced data** tile now opens the sync status screen (`/projects/:id/sync`); its badge and the screen's total use the same provider (D-056).

### T018 · Audit log with django-simple-history
[#35](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/35) · E02 · P1 · must · labels: `backend`, `admin`, `must` · implements F4 · est. 1.5 d · **done**

Depends on: T015

- [ ] `HistoricalRecords(table_name="historical_<table>")` is on Project, ProjectMembership, ProjectProtocol, Transect, TransectSection, Taxon, PlantTaxon, HabitatType, ManagementType, SurveyVisit, ButterflyObservation, Photo, PlantResourceObservation, HabitatFeature, SyncConflict. Each later model ticket adds its own line, and this ticket adds it to the models that exist now.
- [ ] `simple_history.middleware.HistoryRequestMiddleware` is installed. Changes made through DRF (JWT) record `history_user` (tested: DRF sets the user on the underlying request; VERIFY with the installed version).
- [ ] A service helper `save_with_reason(obj, user, reason)` sets `obj._change_reason`.
- [ ] Admin classes inherit `SimpleHistoryAdmin`. **Revert is disabled** (`history_revert` off via `has_change_permission` on the history view, or by overriding `history_form_view`) because reverting would bypass sync versioning.
- [ ] Test: changing an observation's taxon produces a history row with old and new taxon, user, timestamp and reason.

Note: skipped the two test criteria (D-021: the taxon-change test and the `.update(` grep); the same history row (old/new value, user, time, reason) was shown by hand on a Project field. HistoricalRecords was already on Project, ProjectMembership and ProjectProtocol (T015/T016); later model tickets add their own. Admins extend `core.admin.HistoryAdmin` (revert refused), reasons go through `core.history.save_with_reason` (used by T043/T057), history rows carry the fresh `server_version` (D-040). Added at the user's request: an optional change-reason dialog when saving an edit in any `HistoryAdmin` (D-040).

### T019 · Taxon catalogue, versioned
[#36](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/36) · E03 · P1 · must · labels: `backend`, `database`, `must` · implements F18 · est. 2 d · **done**

Deferred: "Taxa reach the phone by pull" waits for T025 (`catalogues.services.taxa_for(user)` is the scope to use) and its "or referenced by the user's own observations" part waits for T044. The "(tested)" part of the read-only name was checked by hand (D-021). See D-043.

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
[#37](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/37) · E03 · P1 · must · labels: `backend`, `database`, `must` · implements F22, F64 · est. 1.5 d · **done**

Deferred: the pull of all three (T025, scopes are `catalogues.services.*_for`) and the picker filtering in the app wait for T025/T031. The 'deactivating keeps existing records' check in the API and app waits for the first referencing models (T021, T051, T053); the admin keeps the row and its history (checked by hand, D-021). See D-044.

Depends on: T005

- [ ] `PlantTaxon`, `HabitatType` and `ManagementType` models with admin.
- [ ] All three are pulled to the phone (active rows, plus inactive rows referenced by the user's records).
- [ ] Deactivating a value hides it from pickers but keeps it on existing records (tested in app and API).

### T021 · Transect and section models and API
[#38](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/38) · E03 · P1 · must · labels: `backend`, `database`, `must`, `p2-compat` · implements F6 · est. 2 d · **done**

Deferred: `GET /api/v1/transects/{id}/visits` moves to T034, since its body is the visit serializer; until then `visit_count` is 0 and `last_visit_at` is null (`TODO(T034)` in `transects.services.with_stats`). "Synced to project members" waits for the pull (T025): `transects.services.transects_for(user)` and `sections_for(user)` are the scopes to use. The Drift tables in the ticket text belong to the pull/app tickets (T025/T031/T033). The admin is plain forms; the map editor is T022. See D-045.

Note: no test criteria to skip. The 5 m rule checks that the whole section lies in a 5 m buffer of the line, not `ST_DWithin` (closest point only). The API half of T020's "deactivating keeps existing records" was checked here: a section keeps its deactivated habitat type in `/transects/{id}`. VERIFY: Django 5.2 `Length()` on a 4326 geometry field already returns metres (same value as `ST_Length(geometry::geography)`); the code uses an explicit `GeodesicLength` func. Added at the user's request: transect and section geometry use `core.widgets.LineMapWidget`, with a "?" help popup on how to draw and finish a line. The section form also shows the chosen transect as a dashed line that new points snap to.

Depends on: T015, T020

- [ ] `Transect` and `TransectSection` models. `(project, code)` is unique, and so are `(transect, sequence_number)` and `(transect, section_code)`.
- [ ] `GET /api/v1/projects/{id}/transects` and `GET /api/v1/transects/{id}` are read-only. Responses include computed `length_m` (geodesic), `section_count`, and the caller's `visit_count` and `last_visit_at`.
- [ ] `GET /api/v1/transects/{id}/visits` returns the caller's visits (admins: all visits).
- [ ] Validation: a section geometry must lie within 5 m of its transect line (`ST_DWithin` on geography). An admin form error is shown otherwise.
- [ ] Both models are synced to project members.

### T022 · Map-based transect and section editor in admin
[#39](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/39) · E03 · P1 · must · labels: `admin`, `must` · implements F63 · est. 2 d · **done**

Note: no test criteria to skip. Sections are cut in UTM, not planar degrees, and the section unique constraints became partial (live rows only, `transects/0002`), so replaced sections can be soft-deleted. Added at the user's request: the transect drawn dashed on every section map, solid crimson section lines, a fixed help popup, and a "Remove" box per inline section. The inline has no "Add another" (D-046).

Depends on: T014, T021

- [ ] `TransectAdmin(MapAdmin, SimpleHistoryAdmin)` uses a map widget for the line and a sections inline (`StackedInline`, small map per section, collapsed by default).
- [ ] An **Import line** admin view on a transect accepts a GPX, KML or GeoJSON upload. It reads the first LineString or track using `django.contrib.gis.gdal.DataSource` and reprojects it to 4326.
- [ ] Action **Generate N equal sections** (intermediate form asking N and a code prefix) creates sections with `ST_LineSubstring` and sequence numbers 1..N. It refuses if sections already exist, unless "replace" is ticked; replaced sections are soft-deleted.
- [ ] A warning appears in the change view when the sum of section lengths differs from the transect length by more than 2 %.
- [ ] The list shows code, name, project, active, length and section count, filtered by project.

### T023 · Catalogue admin tools
[#40](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/40) · E03 · P1 · should · labels: `admin`, `should` · implements F64 · est. 1.5 d · **done**

Note: no test criteria to skip. "Publish new taxon list version" is a button on the release changelist, not an action on a selected row, because it creates the release. There are two synonymise actions: T019's "Rename / synonymise…" (creates the accepted taxon) and the new "Synonymise into existing…" (links to an existing one). See D-048.

Depends on: T019, T020

- [ ] Taxon, PlantTaxon, HabitatType and ManagementType admins have search, filters (family, active, source) and `list_editable` for `active`, `photo_required` and `sort_order`.
- [ ] CSV import and export for all four, using **django-import-export**. It's justified: it saves writing and testing a custom importer, and its dry-run diff preview is useful. Pin the version and VERIFY Django 5.2 support.
- [ ] Action **Publish new taxon list version**: creates a `TaxonListVersion`, marks it current, and lets admins choose which projects switch to it.
- [ ] Action **Synonymise into…** (intermediate form): creates or links the accepted taxon and retires the selected one in the new version, following the T019 versioning rule.

### T024 · Seed data: butterflies of Serbia, plant list, codelists, demo project
[#41](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/41) · E03 · P1 · must · labels: `backend`, `must` · implements F79 · est. 2 d · **done**

Note: seeds are in `database/seeds/` and the client is `requests`, as the ticket says. The GBIF backbone has no node for *Papilionoidea*, so the importer uses its six families (D-047); backbone status `DOUBTFUL` names are imported and marked. The seed commands are dev-only (`compose.dev.yaml` mounts the seeds folder). The transect lines are illustrations, not surveyed routes.

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
[#42](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/42) · E04 · P1 · must · labels: `backend`, `sync`, `must` · implements F25, F7 · est. 2 d · **done**

Note: the interleaved-writes "Test" was checked by hand (a smoke script, plus an uncommitted write on a second database connection while pulling), not as an automated test (D-021).

Deferred: the "user data" and `sync_conflict` scope bullets wait for their tables. Own records (`created_by = user`) are added to `apps/sync/registry.py` by T034, T036, T044 and T049; the caller's own conflicts (`sync_conflict` scope) were delivered by T027. The automated interleaved-writes test is skipped (D-021).

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
[#43](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/43) · E04 · P1 · must · labels: `backend`, `sync`, `database`, `must` · implements F25, F13 · est. 2.5 d · **done**

Note: reject datetimes without a UTC offset in push input (DRF would read them in the server zone); API timestamps are UTC since D-039.

Note: shown by hand with tmp/t026/smoke.py and temporary handlers, since no type the phone writes exists yet (D-050). The 5 s / 500-mutation target is measured in T074.

Deferred: the 500-mutation < 5 s measurement to T074 (about 3 s in the smoke run). Conflict merge replaces the `stale_version` rejection in T027 (D-050).

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
[#44](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/44) · E04 · P1 · must · labels: `backend`, `sync`, `database`, `must` · implements F26 · est. 2 d · **done**

Note (from T026, D-050): a `create` of an existing id is rejected `stale_version` today, even when it is the phone's own resend (stored mutation pruned or re-queued under a new `mutation_id`). Handle a create of the user's own existing row as an update against the current version, or a no-op. Done: a create resend is merged against the row's creation version (D-052).

Note: the "Tests cover" cases are shown by hand with `tmp/t027/smoke.py` and temporary `transect` handlers, since no type the phone writes exists yet (D-021, D-052). The ticket's `count` case maps to `name`, and "admin validated the taxon" to an admin change of `description`.

Deferred: the Drift `SyncConflicts` mirror (ticket section c) to T030, whose criteria already read `sync_conflict` rows from the pull.

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
[#45](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/45) · E04 · P1 · must · labels: `admin`, `sync`, `must` · implements F26 · est. 1.5 d · **done**

Note: shown by hand with `tmp/t028/smoke.py` (resolution logic, with temporary `transect` push handlers) and `tmp/t028/seed_demo.py` (two open conflicts for the browser demo), since no type the phone writes exists yet (D-021, D-053). Accept client therefore only shows the "cannot be changed by the app" error in the browser until a pushable type exists (T044). Nothing skipped: the ticket has no test or CI criteria. The locked-visit refusal keys on T042's `visit_locked` error code (the ticket's "T043" is the unlock action); it is shown with a temporary handler that raises it.

Depends on: T014, T027

- [ ] `SyncConflictAdmin` list: entity type, entity link, owner, project, conflicting fields, created, status. Filters: status, entity type, project, owner.
- [ ] The change view is read-only with a **side-by-side diff table** (field | base | server | client), with conflicting rows highlighted. It is a small template override: `admin/sync/syncconflict/change_form.html`.
- [ ] Action/button **Accept server**: marks `resolved_server` and *touches* the entity (a save with reason `"conflict resolved: server"`), so it gets a new `server_version` and the phone pulls the server state.
- [ ] Action/button **Accept client**: applies `client_payload` through the entity's service with conflict checks bypassed, history reason `"conflict resolved: client"`, then marks `resolved_client`.
- [ ] Both require a note (intermediate form) and are recorded in history.
- [ ] Accepting client on a locked visit is refused with a message to unlock first (T043).

### T029 · App sync queue
[#46](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/46) · E04 · P1 · must · labels: `mobile`, `sync`, `database`, `must` · implements F24, F23 · est. 1.5 d · **done**

Note: send every timestamp as UTC with an offset (`DateTime.now().toUtc().toIso8601String()` ends in `Z`); convert to local time only for display.

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
[#47](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/47) · E04 · P1 · must · labels: `mobile`, `sync`, `must` · implements F24, F25 · est. 2.5 d · **done**

Note: the integration-test criterion is shown by a temporary smoke test (`tmp/t030/`, 14 cases, in-memory database and a fake server), not a committed test (D-021, D-054). The conflict release is shown there too, because no type the phone writes exists before T034.

Deferred: photo upload between push and pull (T050); the visit-finished trigger (T040); pulling only downloaded projects, today every local project is pulled (T031); a permanent 4xx on push is retried for ever, for a later ticket (D-054).

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
[#48](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/48) · E04 · P1 · must · labels: `mobile`, `backend`, `must` · implements F7 · est. 1.5 d · **done**

Depends on: T030

- [ ] The **Download project** button runs a pull from cursor 0 for that project, with a progress indicator (records received) and the ability to cancel and resume (cursor persisted).
- [ ] `GET /api/v1/projects/{id}/offline-package` (outline §14) exists as a thin alias returning the first pull page plus `{reference_version}`. `GET /api/v1/projects/{id}/offline-package/status` returns `{reference_version}`, the max `server_version` across reference tables.
- [ ] Project list status: `not downloaded` / `ready` / `update available` (when the server `reference_version` is newer than the local one).
- [ ] After download in airplane mode, every screen needed for a visit works (manual test script in `docs/testing/offline-checklist.md`).
- [ ] If T060 is done, the package also downloads the project's MBTiles basemap.

Note: the offline checklist (`docs/testing/offline-checklist.md`) is written in full. Steps 1-4 (offline start, project list, project home, Settings) are run in T031. The other steps run when their screen lands, and that ticket fills in the result: step 5 (transect list and detail) T033, step 6 (start-visit form, taxon list) T035, step 7 (active visit, GPS track) T037/T039, step 8 (quick butterfly entry) T045, step 9 (finish visit, true-zero and cancel reasons) T040/T041, step 10 (airplane mode off, sync pushes everything) T034+. T060 is `todo`, so the MBTiles criterion does not apply yet; T060 adds it to the download.

Manual run (2026-10-26, phone over USB): Download with progress and the right transect count; Cancel then Download continued from the saved cursor; after a server edit the card showed `Outdated` and Update brought it back to `Ready` (the automatic pull was switched off for that check, then restored); checklist steps 1-4 passed in airplane mode; a second project the user belongs to was not pulled by Sync now and stayed `Not loaded` with 0 transects. Backend checked with curl (`tmp/t031/curl.md`). Labels on the card: `Not loaded`, `Ready`, `Outdated`.

Deferred: checklist steps 5-10 run in T033, T035, T037/T039, T045, T040/T041 and T034+ (see the note above); the MBTiles criterion is delivered by T060 (D-102); review points on the status error mapping and on projects pulled before T031 are in D-055.

### T032 · App sync status screen
[#49](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/49) · E04 · P1 · must · labels: `mobile`, `sync`, `must` · implements F28 · est. 1.5 d · **done**

Depends on: T030

- [ ] The screen shows pending changes per entity type, photos waiting and their total size, last successful sync time, and bytes transferred in the last sync.
- [ ] **Errors** list: rejected items with a human-readable reason (mapped from the error `code`), plus **Retry** (re-queues with a new attempt) and **Discard local change** (with confirmation; restores the server version on the next pull).
- [ ] **Conflicts** list (from `sync_conflicts`) is read-only and reads: "An admin will resolve this. Your change is kept on the server." It shows the resolution once pulled.
- [ ] **Sync now** button with live progress.
- [ ] The unsynced badge on project home (T017) matches the counts here.

Deferred: "photos waiting and their total size" shows 0 and 0 B until photos exist (`pendingPhotosProvider`, `TODO(T050)`). Names for visit and observation types in the lists are `TODO(T034)`. A re-pull from cursor 0 (the v6 step, Discard) can release the wrong held queue item when an entity has an old resolved conflict and a newer open one; the fix needs `mutation_id` in the conflict pull (D-056, known risks). See D-056.

### T033 · App transect list and transect detail
[#50](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/50) · E05 · P1 · must · labels: `mobile`, `must` · implements F72 · est. 2 d · **done**

Depends on: T017, T021, T031

- [ ] List: code, name, distance from the current location (last known fix, straight-line to the nearest vertex), last own visit date, own visit count, downloaded flag, active status. Search by name or code, sort by distance or code.
- [ ] Detail: a map (flutter_map) with the transect line and colour-coded sections, length, section list with habitat types, habitat summary, a protocol summary (season, time window, weather thresholds from `project_protocols`), own visit history, and a **Start visit** button.
- [ ] Start visit is disabled for inactive transects. It warns (without blocking) outside the season or time window.
- [ ] Everything works offline.

Manual run (2026-10-26, phone over USB): list with distances, search and both sorts; detail with map, coloured sections, habitat and protocol summary; Start visit warned outside the season and time window, and was disabled after FG4 was set inactive in the dev database (set back afterwards); list and detail worked with the server unreachable (offline checklist step 5). Review fixes: shared location permission check, `autoDispose` last position, guarded GeoJSON parsing.

Deferred: the own visit count, last visit date and visit history show no visits until the phone has a `survey_visit` table (`TODO(T034)` in `visit_stats.dart`). After the season and time-window checks, Start visit shows a snackbar until the start-visit form exists (`TODO(T035)`). See D-057.

### T034 · SurveyVisit model, lifecycle and API
[#51](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/51) · E05 · P1 · must · labels: `backend`, `mobile`, `database`, `must`, `p2-compat` · implements F9 · est. 2.5 d · **done**

Picks up from T033: the app's own-visit count, last visit and visit history read placeholder providers in `features/transects/domain/visit_stats.dart` (`TODO(T034)`); fill them from the Drift `survey_visit` mirror.

Picks up from T021: `GET /api/v1/transects/{id}/visits` (the caller's visits, admins all) and the real `visit_count` / `last_visit_at` in `transects.services.with_stats` (`TODO(T034)`).

Notes: the "test on both sides" is written (developer's choice, an exception to D-021): `backend/apps/surveys/tests.py` and `mobile/test/visit_status_test.dart`. VERIFY of the cancel-reason CHECK done with `sqlmigrate`. Lock check (T042), lock/unlock UI (T043), field rules per status (T055) and the app's visit writes (T035) stay with their tickets. See D-058.

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
[#52](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/52) · E05 · P1 · must · labels: `mobile`, `must` · implements F8 · est. 1.5 d · **done**

Manual run (2026-10-27, phone over USB, FG2): season and time-window warnings in the form; Start with empty fields listed what was
missing; a partial draft saved, came back on "Continue draft" and synced as `draft`; wind 6 Bft, 12.5 °C, 50 % cloud and drizzle listed
all three failing thresholds live; "Start anyway" gave `in_progress` with `started_at` and `weather_suitable = false` on the server
(history: `draft`, then `in_progress`, both `sync push`); FG3's Start was refused while FG2 was in progress. The form opened in 200–260 ms
(debug build, tap to first frame, temporary `Stopwatch`). Repository writes checked with a temporary smoke test (`tmp/t035/`, 8 cases, not committed). Code review fixes: 0 % cloud could not be picked, drafts and the visit in progress filtered by observer, the in-progress check also in `VisitRepository.start`, changes worked out against the draft as opened, the form kept while providers reload, a logged-out message, observer count capped at 20; 0 % checked again on the phone. Precipitation is a dropdown, not the chips the criterion names (developer's choice: the chips reflowed and moved the form when one was selected).

Deferred: starting GPS tracking is T037 (`TODO(T037)` in `VisitRepository.start`); after Start the app returns to the transect
detail until the active visit screen exists (`TODO(T039)`); the `visit_form_open` event is T073 (`TODO(T073)`). See D-059.

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
[#53](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/53) · E05 · P1 · must · labels: `backend`, `database`, `sync`, `must`, `p2-compat` · implements F10 · est. 1.5 d · **done**

Checked by hand (2026-10-27): `tmp/t036/smoke.py`, 55 checks in the container. These covered 1000-row batches (0.27 s), idempotent resends, bad
rows rejecting the batch with the row named, ownership, the distance with the outlier left out, the client value kept with fewer than 2
usable points, the visit finished offline before its points arrive, and REST complete, and the admin page (map, point count, scripts). Also checked: the Drift v7 → v8
migration test, and a throwaway `discard` test (`tmp/t036/`, not committed). Decisions with the developer: the phone's
`distance_walked_m` is accepted and replaced by the server's when it can compute one; track points are not pulled; the Drift table
and the `discard` fix are part of this ticket. See D-060.

Deferred: the visit-lock check on batches is T042.

Depends on: T026, T034

- [ ] The `SurveyTrackPoint` model accepts `create_batch` pushes (T026) of up to 1000 points, idempotent per point id.
- [ ] On visit completion, the server computes `distance_walked_m` from points ordered by `recorded_at`, excluding points with `accuracy_m > protocol.gps_accuracy_warning_m × 2`. It keeps the client value if the server has fewer than 2 usable points.
- [ ] The admin visit page shows the route as a read-only map: `ST_MakeLine(geometry ORDER BY recorded_at)`.
- [ ] Points are **never** thinned or simplified on the server (raw data kept for Phase 2).

### T037 · App GPS tracking with an Android foreground service
[#54](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/54) · E05 · P1 · must · labels: `mobile`, `must` · implements F10, F87 · est. 3 d · **done**

Checked by hand (2026-10-27) on a Samsung Galaxy S24 (SM-S921B, Android 17, One UI), driven over adb. Start asked for notifications,
then showed the battery dialog and Android's exemption dialog (granted). A second Start showed neither. The ongoing notification read
"Visit in progress: FG2 / Recording the route every 5 s", and the geolocator service ran as a foreground service of type `location`.
At 5 s the card's count rose by 6 every 30 s. **VERIFY (background location):** with the screen off, the battery shown as unplugged
and deep Doze forced for 5 minutes, 61 points arrived, the longest gap was 8.3 s and none exceeded 30 s, without
`ACCESS_BACKGROUND_LOCATION`. **VERIFY (geolocator API):** `AndroidSettings` / `ForegroundNotificationConfig` as named in the
criterion (geolocator_android 5.1.1); `enableWakeLock` also needs `WAKE_LOCK` in the manifest (without it the stream silently never
starts). Process death (`am force-stop`, relaunch about 2 min later) showed "Tracking interrupted 20:20–20:22", and sequence numbers went
on 89 → 90. On the server, `count(*) = max(sequence_number)` (104 points), provider `fused`, and the distance was recomputed after the last
batch. Completing or cancelling the visit on the server and then syncing stopped tracking and removed the notification. The phone run found
three bugs, all fixed: the missing `WAKE_LOCK`, a provider `ref` used after an `await`, and a sync run reported as failed because of
track points queued during the run. The `/code-review` findings were fixed except two (see D-061).
permission_handler 13.0.2 needs compileSdk 37, so the Android build moved to AGP 9.2.1 and Gradle 9.4.1 (CONVENTIONS A.4).

Deferred: the 60-minute run (about 720 points) is measured in T074, as the criterion says. Pause handling (`pausedAt`) is T039, and the
"No GPS fix" banner for a gap within one app run is T038.

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
[#55](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/55) · E05 · P1 · must · labels: `mobile`, `must` · implements F87 · est. 1 d · **done**

Checked by hand (2026-10-29) on a Samsung Galaxy S24 (SM-S921B): the toggle (notification "Battery saver: recording the route every 15 s", `every 15 s (battery saver)` on the tracking card, fewer points), `battery_saver_used = true` on the server after a sync, the "No GPS fix for N s" banner (also hidden while paused), the mode surviving `am force-stop`, and the gaps on the Finish screen (criterion 4, built by T040) all worked in the developer's run of `tmp/t038/UI_TESTS.md`. The automatic switch could not be tried with `adb shell dumpsys battery set level 15`: battery_plus reads `BATTERY_PROPERTY_CAPACITY`, which that command does not change, so the phone still reported its real level (about 40 %). With the threshold raised to 101 % for one run it worked: the switch, the snackbar "Battery below 20 %: battery saver is on" (shown when the screen opened) and the notification changed, turning it off by hand stayed off for two minutes (two checks), and the app log had no exceptions. The real 20 % comparison was not tried on a low battery. The `/code-review` findings that were bugs were fixed (see D-071).

From T039 (D-063): a pause stops GPS, so it leaves a gap in the track points. Only the total `paused_seconds` is stored, not when the pauses were, so the points alone cannot tell a pause from a GPS gap. Decide here how to tell them apart (for example, store the pause intervals).

The banner must stay quiet while the visit is paused (`TrackingState.paused`, T039).

From T040 (D-068): the pauses are recorded in `survey_visit.pauses` (a list of `{started_at, ended_at}`, UTC), so a pause can be told from a GPS gap. The Finish screen already lists the gaps (`features/visits/domain/gps_gaps.dart`); T038 can reuse it for the visit summary.

Depends on: T037

- [ ] A toggle on the active visit switches to `gpsIntervalBatterySaverS` and `LocationAccuracy.medium`, and sets `battery_saver_used = true` on the visit.
- [ ] It switches automatically below 20 % battery (`battery_plus`), with a snackbar.
- [ ] A banner shows "No GPS fix for N s" when no point arrives within `gps_gap_s`.
- [ ] Gaps are visible later on the visit summary (T040).

### T039 · App active visit screen
[#56](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/56) · E05 · P1 · must · labels: `mobile`, `must` · implements F11 · est. 2.5 d · **done**

Deferred: **Add butterfly** (T045), **Add plant** (T052), **Add habitat** (T054) and **Finish** (T040) are on the screen but show
"coming in a later version" (`TODO(T045)` and so on in `widgets/active_visit_view.dart`); the observation count is 0 until T044 (`TODO(T044)` on
`visitObservationCountProvider`). `wakelock_plus` is pinned at 1.8.0: 1.8.1 needs `dbus ^0.8`, which conflicts with `geolocator_linux`. See D-063.

Depends on: T037

- [ ] The map shows the transect line, sections (current one highlighted), the current position with an accuracy circle, and the walked route.
- [ ] A header shows elapsed time excluding pauses, distance walked, current section code and number of observations.
- [ ] A large **Add butterfly** button (opens T045), plus **Add plant** (T052) and **Add habitat** (T054).
- [ ] **Pause/Resume:** while paused, no track points are stored and `paused_seconds` accumulates. Observations are still allowed during a pause but warned about.
- [ ] **Finish** goes to T040.
- [ ] An optional keep-screen-on toggle (`wakelock_plus`).
- [ ] Works fully offline.

### T040 · Finish visit: summary, warnings and end weather
[#57](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/57) · E05 · P1 · must · labels: `mobile`, `must` · implements F11 · est. 2 d · **done**

From T042 (D-062): when the visit is finished, the phone also sends how many track points it recorded (e.g. a
`track_point_count` on `survey_visit`, server-owned except for this one write; needs a Django migration and a Drift column). A visit
finished offline can reach the server before all its track batches (one push carries at most 100 items), and T043 uses the count to
keep an admin from locking a visit whose route is still uploading: a locked visit refuses late track batches (T042).

From T039 (D-063): a pause stops GPS, so it leaves a gap in the track points. Only the total `paused_seconds` is stored, not when the pauses were, so the points alone cannot tell a pause from a GPS gap. Decide here how to tell them apart (for example, store the pause intervals).

From T039 (D-063): finishing a paused visit must close the pause first (`VisitRepository.resume` adds the open pause to
`paused_seconds`) before `duration_seconds` is worked out. `routeLengthM` (`features/visits/domain/route_length.dart`) gives the
phone's `distance_walked_m` with the server's accuracy rule.

From T100 (added 2026-10-27): the server computes the same coverage, so pin the definition. Sample the transect at 0, 10, 20 … m
plus its end point. A sample is covered when a usable route **point** lies within `maxDistanceFromTransectM`. Usable means the accuracy
rule of D-060 (`accuracyM` null or ≤ 2 × `gpsAccuracyWarningM`). With fewer than 2 usable points there is no coverage.

Skipped criteria: none (no criterion asks only for tests or CI). **Cancel visit** is a placeholder (snackbar, `TODO(T041)`) until T041. Pauses are stored as a list (`pauses`) and the phone sends `track_point_count`, both new `survey_visit` fields; the true-zero checkbox is built here. See D-068.

Deferred: **Cancel visit opens T041's cancel flow** (last criterion): the button is on the Finish screen and shows a "coming in a later version" snackbar (`TODO(T041)` in `finish_visit_form.dart`) until T041. Offline checklist step 9 (T040 part, airplane mode) is for the developer to fill in (`docs/testing/offline-checklist.md`).

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
[#58](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/58) · E05 · P1 · must · labels: `mobile`, `backend`, `must` · implements F12, F9 · est. 1 d · **done**

From T040 (D-068): the true-zero checkbox and its V06 check on Finish were built in T040 (`finish_visit_form.dart`). T041 keeps the cancel reasons, the export outcome and its tests, and replaces the Cancel visit placeholder on the Finish screen (`TODO(T041)`).

Depends on: T040

Skipped: unit tests (D-021). V06's "completed with no observations needs the tick" is enforced by the app only (validation-rules.md, D-067). The export criterion is `SurveyVisit.outcome`; T064 puts it in the exports. See D-069.

- [ ] Finishing a visit with zero transect observations requires ticking: *"No butterfly was seen during the complete standardised visit."* This sets `zero_observation_confirmed = true`.
- [ ] Server rule V06 (T055):
  - a completed visit with zero `source = transect` observations must have `zero_observation_confirmed = true`
  - a visit with observations must have it `false`

  Violations are rejected.
- [ ] Cancel flow offers four reasons: `not_conducted` (planned but not walked; can be recorded without starting), `aborted_weather`, `aborted_other` and `invalid_protocol`, plus a note.
- [ ] Exports (T064) show the visit outcome as one of `completed_with_records`, `true_zero`, `cancelled:<reason>`.
- [ ] Unit tests on both sides.

### T042 · Visit lock enforced in the API
[#59](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/59) · E05 · P1 · must · labels: `backend`, `sync`, `must` · implements F13 · est. 1 d · **done**

Picks up from T034: `SurveyVisitAdmin` is fully read-only (only the "Mark as reviewed" action). Editing unlocked visits in admin ("unlock, edit and re-lock") starts here: make the fields editable except `status`, `distance_walked_m`, `locked_*` and `quality_flags`, and save through `surveys.services.save_visit`. See D-058.

Depends on: T026, T034

- [ ] Push and REST reject (`code = "visit_locked"`) any create, update or delete of a locked visit, and of any observation, track point, plant resource, habitat feature or photo belonging to a locked visit.
- [ ] Django admin: `has_change_permission` returns `False` for a locked visit and its children, with a "Locked by X on Y: reason" banner. The only way back is the Unlock action (T043).
- [ ] App: on pull, a locked visit and its records become read-only, with a lock icon. Local pending edits on it end up `rejected`, with a clear message on the sync screen.
- [ ] Tests for each child entity type.

### T043 · Admin visit review, lock and unlock with mandatory reason
[#60](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/60) · E05 · P1 · must · labels: `admin`, `must` · implements F66 · est. 1.5 d · **done**

From T042 (D-062): **Lock** warns or refuses (decide in the plan) while the server has fewer track points for the visit than
the count the phone sent on finish (T040). Otherwise a lock can land between the visit and its last track batches, and the phone's
remaining points are rejected with `visit_locked`. A visit without a count (finished before T040, or through REST) is not blocked.

From T040 (D-068): the field is `track_point_count` on `survey_visit` (null for a visit finished before T040 or through REST).

Depends on: T018, T042

- [ ] `SurveyVisitAdmin` list: transect, observer, start, duration, distance, observation count, status, flags. Filters: project, transect, status, observer, date, flag.
- [ ] Inlines: observations (read-only summary with links) and a route map.
- [ ] Actions: **Mark reviewed**, **Lock**, **Unlock**. Lock and unlock use an intermediate form with a required reason (at least 10 characters) and set `locked_at`, `locked_by` and `lock_reason` (cleared on unlock).
- [ ] The history row carries the reason as `history_change_reason`.
- [ ] Invalid transitions (for example locking a draft) show an error per visit without failing the whole action.

Note: every criterion shown by hand with `tmp/t043/smoke.py` (drives the admin list and the reason pages with the Django test client: lock and unlock with a reason and the history row, a short reason, a draft and a synced visit together, the track point rule with and without the override, the flag filter, the observation count, the inline, saving an unlocked visit with the inline present, the locked page). Nothing skipped as test/CI only. "Lock warns or refuses" is settled as refuse with an override (D-070). The flag filter stays hidden until T056 sets a flag. See D-070.

### T044 · ButterflyObservation model and API
[#61](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/61) · E06 · P1 · must · labels: `backend`, `database`, `sync`, `must`, `p2-compat` · implements F14, F15, F17 · est. 2.5 d · **done**

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

Note: `validation_status` on create only (decision 2026-10-28); pygeoapi skeleton collection removed here (see D-065).

### T045 · App quick butterfly entry
[#62](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/62) · E06 · P1 · must · labels: `mobile`, `must` · implements F14 · est. 2.5 d · **done**

Depends on: T039, T044

- [ ] A bottom sheet opens from **Add butterfly** with: recent species (last 8 used in this project), favourites (star toggle), search, count stepper (+/−, long-press to type) and **Save**.
- [ ] Search matches scientific, Serbian and English names, is diacritics-insensitive (`searchText`, T019), matches as you type, and returns in under 100 ms for 300 taxa.
- [ ] A repeat species takes **≤ 3 taps** (open, tap species, save); measured by T073.
- [ ] Position comes from the latest fix (accuracy shown, with a warning above `gpsAccuracyWarningM`). Time is "now".
- [ ] Section = current section (T039). Confidence defaults to `confirmed_in_field`.
- [ ] An **Undo** snackbar for 10 s soft-deletes the last record.
- [ ] Local table `taxon_usage` stores favourites and recent use.

Note: search takes at most 0.46 ms for 300 taxa (debug build, on the phone). Checklist step 8 passed with the server unreachable, 2026-10-28; not repeated in airplane mode. The section path was checked with a fresh fix on a phone away from the transect (section empty); a section stored from a live fix is the same lookup as the header's. "Measured by T073" is T073's. No criterion was skipped as test/CI only. See D-066.

### T046 · App extended entry
[#63](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/63) · E06 · P1 · should · labels: `mobile`, `should` · implements F15 · est. 1.5 d · **done**

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

From T106 (added 2026-10-30): "editing an existing observation" starts from the **Edit** button on T106's observation detail. This
ticket enables that button (hidden until then, and on locked visits).

Note: checked on the phone on 2026-11-02 (quick path, Details on create, prompts, edit, sync with merged and conflict cases, locked visit, offline, wind-picker focus, the dial's facing line). Not checked: adding a photo in the entry or edit sheet, a lock pulled while the edit sheet is open, another user's rows without Edit, and the facing arrow following a turning phone. No criterion was skipped as test/CI only. See D-082.
Deferred (agreed 2026-11-02): the working "Link to host plant" (picking or creating a plant record) moves to T052; T046 shows the prompts with the button disabled. Added with the developer's agreement: Edit also changes count and species.

### T047 · Incidental and other-source observations
[#64](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/64) · E06 · P1 · should · labels: `mobile`, `backend`, `should` · implements F17 · est. 1 d · **done**

Depends on: T045

- [ ] The **Free observation** tile (project home) and a map long-press open the same entry sheet with a **source** picker: `incidental`, `larval_search`, `host_plant_search`.
- [ ] No visit is needed (`survey_visit_id = null`). Position comes from GPS, or from the long-pressed or dragged map position, with accuracy set to `null` when placed manually.
- [ ] These records are excluded from per-km and per-hour indicators (T061, T062) but included in species lists and exports.

From T106 (added 2026-10-30): free observations have no visit, so T106's visit detail does not list them. They are reached from the
map popup (T059) and open T106's observation detail.

From T108 (added 2026-10-30): the route-recording screen of T108 reuses this entry sheet (source `incidental`), so butterflies seen
while proposing a route are kept but are not a standardised count.

Deferred: part of criterion 3 waits for T061 and T062, because the indicators are not built yet. Those tickets must count `source = transect` only
for per-km and per-hour figures. Exports and OGC were shown including free records.

### T048 · Automatic section assignment
[#65](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/65) · E06 · P1 · should · labels: `backend`, `should` · implements F19 · est. 1 d · **done**

Depends on: T044
Deferred: the `far_from_transect` flag of the third criterion goes to T056 (agreed 2026-11-02); T048 only leaves the section empty.
Notes: shown by hand on the demo transect NI1 (14 smoke cases, `tmp/t048/smoke.py`): push create with a null section gets the nearest one, the phone's guess is kept, a section of another transect is rejected, a far point gets no section, a resent create changes nothing, REST PATCH with null assigns, an admin's clearing stays, and **Reassign sections** fixes, clears and skips as expected with `reassign sections` history rows. "Tests with the seeded demo transects" is skipped as test-only (D-021) and run by hand on the demo transects instead. The `far_from_transect` flag is deferred to T056 (agreed 2026-11-02): T048 only leaves the section empty; see D-084. Beyond the criteria, the Transect filter was removed from the Transect section list in the admin (it listed every transect; the search box still finds them).

- [ ] The app sends its current-section guess (T039). If the client sends `null`, the server assigns the nearest section of the visit's transect within `max_distance_from_transect_m`.
- [ ] A client-sent section is kept unless it belongs to a different transect, which is rejected.
- [ ] Observations farther than the threshold get no section and the `far_from_transect` flag (T056).
- [ ] Admin action **Reassign sections** recomputes for selected observations (saved per row, so history applies).
- [ ] Tests with the seeded demo transects.

### T049 · Photo model and upload API with SHA-256 deduplication
[#66](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/66) · E06 · P1 · must · labels: `backend`, `database`, `sync`, `must` · implements F27, F16 · est. 2.5 d · **done**

Note: beyond the criteria, the push also has `update` and `delete` for photos, there is a read-only Photo admin, and Django uses its own MinIO user (`scripts/minio-setup.sh`); see D-072.
Note: criterion 9 ("tested") is shown by the hand-run smoke script (`tmp/t049/smoke.py`, not committed) and curl through `:8080`, not an automated test (D-021).

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

Depends on: T030, T045, T049, T106
Notes: photo button moves into T046's extended section once that exists

From T106 (added 2026-10-30): "the observation detail" below is T106's screen; this ticket fills its photo area (T106 is now a
dependency). Photos whose file is not on this phone (taken on another phone, or before a reinstall) are T107.

- [ ] Capture with `image_picker` (camera) or pick from the gallery. Several photos per observation, one marked primary.
- [ ] Compress to max 2048 px on the long edge, JPEG quality 85 (`flutter_image_compress`), with EXIF orientation applied. The original camera file is deleted after compression.
- [ ] Saved to `<app documents>/photos/<photoId>.jpg`. SHA-256 is computed in an isolate. The metadata row and queue item are created atomically.
- [ ] The sync runner (T030) runs after push: for each photo with `pendingUpload`, init, then PUT, then complete, with resume on failure (re-init is safe).
- [ ] An optional "Upload photos on Wi-Fi only" setting.
- [ ] Thumbnails appear in the observation detail. Deleting a photo is a soft delete that syncs.
- [ ] Local photo storage use is shown on the sync screen (T032).

### T051 · PlantResourceObservation model and API
[#68](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/68) · E07 · P1 · should · labels: `backend`, `database`, `sync`, `should` · implements F20 · est. 1.5 d · **done**

Depends on: T020, T044, T049
From T064: add the `plant_resources` export dataset (`apps/exports/datasets.py`, remove it from `DEFERRED`).
From T068: add the `plant-resources` collection to `pygeoapi/config/pygeoapi-config.yml` (same pattern, `time_field: observed_at`, `title_field: plant_scientific_name`) and to `scripts/ogc-smoke.sh`. Run `migrate` before restarting pygeoapi: it does not start if a configured view is missing.
From T067: add `geo.plant_resources` with `CreateView` in a `resources` migration (columns in TICKET_DETAILS T067; also hide rows of soft-deleted projects, D-078; the table keeps GeoDjango's GiST index on `geometry` and the view exposes that column unchanged), and its pygeoapi collection if T068 is done.

- [ ] Model, push and pull registration, and REST (outline §14):
  - `POST /api/v1/plant-resources`
  - `PATCH /api/v1/plant-resources/{id}`
- [ ] Geometry must be `POINT` or `POLYGON` (CHECK), and be valid (`ST_IsValid`, rule V08).
- [ ] `patch_area_m2` is computed by the server for polygons when the client leaves it empty (`ST_Area(geometry::geography)`).
- [ ] Adds `ButterflyObservation.host_plant_record` and `nectar_plant_record` (nullable FKs), and `Photo.plant_resource` with a CHECK that a photo has exactly one parent.
- [ ] `plant_taxon` may be null for unidentified plants. Then `notes` is required (serializer rule).

Additions beyond the criteria (agreed 2026-11-02): push `delete`, a read-only admin page for plant records with their photos inline, and `host_plant_record_id` and `nectar_plant_record_id` in the `butterfly_observations` export.
Deferred: the Drift part of the ticket text and the phone's side of the T046 note (store the link, fire W03/W04 only without one) go to T052, as for earlier backend tickets. The only Dart edits are comments (`TODO(T051)` is now `TODO(T052)`).
Notes: shown by hand with `tmp/t051/smoke.py` (not committed, D-021; 144 checks over the 22 cases) and `scripts/ogc-smoke.sh`: push create of a point and a polygon with the area computed, a resent create (`merged`, same version, area kept), a LineString, a bow-tie, longitude 500 and a 40° polygon refused, raw SQL inserts refused by the CHECKs, the notes rule on create and PATCH, REST POST and PATCH (201, 200, 400, 403, 404), area recomputed or emptied when the shape changes, a stale update merged, a locked visit refusing update, delete, REST PATCH and a new record, push delete with a tombstone, observation links (own, other project, deleted, repeated after the delete, the role of the plant record), a plant photo (upload, thumbnail, other researcher 404, exactly-one-parent, one primary), W03/W04 with and without a link, exports (CSV, GeoJSON, JSON, bundle, researcher 403), the admin pages, `geo.plant_resources` as `pygeoapi_ro` and the `plant-resources` collection in JSON and HTML (an unidentified plant has a null title and both work). See D-086.

### T052 · App plant entry with point and polygon drawing
[#69](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/69) · E07 · P1 · should · labels: `mobile`, `should` · implements F20 · est. 2.5 d · **done**

Depends on: T050, T051
Deferred (agreed 2026-11-03): the outdoor walking test of Polygon (walk) (the 2 m spacing off a visit, the tracker-fix path during a visit, the wakelock, and 'closing walk mode must not stop tracking'): it rained, so it was not tried on the phone. The code is in place and the polygon maths was checked against PostGIS; test it on the next dry field day. Not exercised either: the pull-side lock rule for plant items (the server refused the push first) and deleting a plant record's primary photo.
From T051 (added 2026-11-02): the server side is done (D-086), the phone part is here:
- Store `host_plant_record` and `nectar_plant_record` in `_butterflyObservation` (they are already in the Drift table and sent by the server), and make `w03Applies` and `w04Applies` check the link (`TODO(T052)` in `observation_rules.dart`).
- The Drift table must be named `plant_resource_observation`: the entity type is the table name, and the pull's tombstone SQL uses the type as the table name.
- **Plant rows pulled before the table exists are skipped and the cursor moves past them** (`_applyType` ignores a type it has no store for), so the Drift migration must reset the pull cursor, or otherwise pull them again.
- Do not push a phone-computed `patch_area_m2`: leave it null or out, and the server computes it (a pushed number must have at most one decimal and nine whole digits).
- Add the photo's `plant_resource` to the Drift table and to `_photo` (the pull already carries it, and `observation` is null for such a photo). Until then a pulled plant photo is stored with no parent, and code that does `observationId!` (`photo_repository.dart`, around the upload and the live-photo lookup) would fail on it: make those paths handle a plant parent, or skip such a row.
- The server now checks the role of a link (D-086): a host link takes a `larval_host`, `oviposition_plant` or `unknown_association` record, a nectar link a `nectar_source` or `unknown_association` one, and a `resting_plant` fits neither. The link picker should offer only those, so a wrong one is not found out by a rejected push.
From T059 (added 2026-11-02): add a "Plants" layer to the project map (`lib/features/map/`, D-081) and an "Open" in its popup that goes to the plant's edit form.

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

From T046: enable "Link to host plant" in `ObservationDetailsForm` (`TODO(T052)`): pick a plant record of this visit or create one.

Added 2026-10-30 (the tile's screen was not specified; est. + 0.25 d): the **Plants & habitat** tile opens a screen with **Add plant**,
**Add habitat** (enabled by T054) and the user's own plant records of this project, newest first: species (or "Unidentified"),
role, date, and the visit date when linked. A row opens its edit form. This ticket enables the tile (T105 leaves it disabled until then).

Agreed 2026-11-03 (beyond the text): during a visit Polygon (walk) uses the tracker's fixes (about 6 m apart at 5 s) with a hint on screen, because geolocator shares one position stream; away from a visit it keeps a corner every 2 m. The edit form has **Delete**, refused while a live observation links the record. The Details form has **host and nectar** links with one picker. `created_by` was added to the plant pull (one serializer line, no migration). The read-only admin page of a plant record got a **map** of its point or polygon (asked for 2026-11-03: `location_map` in `resources/admin.py` and `core/static/core/readonly_map.js`, OpenLayers as Django's widgets load it; the page stays read-only, D-086). Line mode is only checked with a temporary change (T054 rechecks it on the phone). Crossing test compared with PostGIS `ST_IsValid` on 13 rings in two coordinate systems (26 of 26 agree).  **Deferred with the developer's agreement (2026-11-03): the outdoor walking test (step 17)** - Polygon (walk) was not tried outdoors (rain), so the 2 m spacing away from a visit, the tracker-fix path during a visit, the wakelock and 'closing walk mode must not stop tracking' are not verified on the phone; the code is in place (`walkPositionsProvider`, `GeometryCaptureWidget`). Test it on the next dry field day. See D-087.

### T053 · HabitatFeature model and API
[#70](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/70) · E07 · P1 · should · labels: `backend`, `database`, `sync`, `should`, `p2-compat` · implements F21 · est. 1.5 d · **done**

Depends on: T020, T026
From T064: add the `habitat_features` export dataset (`apps/exports/datasets.py`, remove it from `DEFERRED`, and add it to `BUNDLE_DATASETS` so the project ZIP includes it).
From T068: add the `habitat-features` collection to `pygeoapi/config/pygeoapi-config.yml` (same pattern, `title_field: habitat_type_name_en`) and to `scripts/ogc-smoke.sh`. Run `migrate` before restarting pygeoapi: it does not start if a configured view is missing.
From T067: add `geo.habitat_features` with `CreateView` in a `resources` migration (columns in TICKET_DETAILS T067; also hide rows of soft-deleted projects, D-078; the table keeps GeoDjango's GiST index on `geometry` and the view exposes that column unchanged), and its pygeoapi collection if T068 is done.

- [ ] Model, push and pull registration, and REST (outline §14):
  - `POST /api/v1/habitat-features`
  - `PATCH /api/v1/habitat-features/{id}`
- [ ] Geometry is `POINT`, `LINESTRING` or `POLYGON`, and must be valid.
- [ ] Percentages are 0–100.
- [ ] `habitat_type` is required, and `management_type` is optional (FK to codelists, T020).

Additions beyond the criteria (agreed 2026-11-03): push `delete`, and a read-only admin page with a map. REST stays POST and PATCH only; habitat features have no photos. After review: `survey_visit_id` in `geo.habitat_features` (`resources/0005_habitat_view_visit`) and one V07 helper shared with plant records.
Notes: shown by hand with `tmp/t053/smoke.py` (not committed, D-021; 181 checks) and `scripts/ogc-smoke.sh` (30 PASS). The `pygeoapi_ro` read of the view and the refused `public.habitat_feature` were checked with psql. The T051 smoke script gives the same answers as before except "the pull row has no created_by", which T052 made stale (D-087). The maps were not looked at in a browser: only the map div, its GeoJSON type and the scripts were checked in the page HTML. See D-088.

### T054 · App habitat feature entry
[#71](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/71) · E07 · P1 · should · labels: `mobile`, `should` · implements F21 · est. 1.5 d · **done**
Deferred: Polygon (walk) outdoors is still not tested (T052's deferral; `GeometryCaptureWidget` is unchanged). Other members' habitat features are not visible (T112). Locked-visit pull rejection (trap 3) and discard (trap 4) were checked with a throwaway test, not on the phone (D-089).

Depends on: T052, T053
From T059 (added 2026-11-02): add a "Habitats" layer to the project map (`lib/features/map/`, D-081) and an "Open" in its popup that goes to the habitat feature's edit form.

- [ ] Habitat type and management pickers (from codelists), vegetation height (cm), cover sliders (shrub, tree, bare ground; 0–100 in steps of 5), flower abundance, grazing, mowing, disturbance and notes.
- [ ] Point, line and polygon capture via `GeometryCaptureWidget` (T052).
- [ ] Reachable from the active visit and from "Plants & habitat" on project home.

Added 2026-10-30: habitat features join the list on T052's Plants & habitat screen (habitat type, date), with a filter chip
All / Plants / Habitat, and this ticket enables its **Add habitat** button.

From T052 (added 2026-11-03): reuse `GeometryCaptureWidget` and `showGeometryCapture` (`features/resources/`), with `{point, line, polygon}`; line mode was only checked with a temporary change in T052, so recheck it on the phone. The Plants & habitat list (`PlantsHabitatScreen`) shows plant records only: join the habitat features into it (the All / Plants / Habitat chip), and enable its disabled **Add habitat** button. `PhotoParent` has no habitat variant yet; add one if habitat features get photos.

From T053 (added 2026-11-03, D-088): the server side is done. (1) The Drift table must be named `habitat_feature`, the sync entity type. (2) Habitat rows the server sends before the table exists are skipped and the pull cursor moves past them, so the Drift migration must reset the pull cursor (delete the `cursor:%` rows, as T112 describes `from12To13` doing). (3) Push `delete` exists, so a synced record can be removed with a tombstone. (4) Add the type to `sync_error_message.dart` where plants are named. (5) A habitat feature has no photos on the server, so the app has no habitat photo parent. (6) The pull row carries `created_by` (ids, as the plant row does), so the phone can show only its user's rows.

Agreed 2026-11-03 (beyond the text): the edit form has **Delete** (push `delete` exists, D-088), with a confirmation; an unsent create just disappears. The three cover fields start as "Not recorded" with a **Record** button, then show a slider (0-100, step 5) and **Clear**, because 0 % and "not recorded" are different answers and a scroll must never save a false value (D-089). Only the user's own features show (`created_by`); other members' come with T112. The phone test is guided one step at a time. **Not tested outdoors:** Polygon (walk), still deferred from T052; `GeometryCaptureWidget` is unchanged here. Asked for during testing (outside the criteria): the active visit's snackbars name what was saved ("Saved habitat: <type>", "Saved plant: <name>"), with a `titleOf` method on `HabitatRepository` and `PlantRepository`.

### T055 · Input validation rules (shared by app and server)
[#72](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/72) · E08 · P1 · must · labels: `backend`, `mobile`, `must` · implements F30 · est. 2 d · **done**

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

Note: the tests are written (developer's choice, an exception to D-021): 37 on the server (`manage.py test apps.observations apps.surveys`) and 50 in the app (`flutter test`). The API smoke script `tmp/t055/smoke.py` (not committed) pushed and POSTed bad payloads for V01-V08 and W01 and got the rule IDs back in `fields`; a good payload was still applied. The developer's phone run on 2026-10-28 passed: start form (W06/W07) after the file move, quick entry, W01 (the line, then `validation_status = pending`), V03 on the sync screen (readable text, Discard), and W02 once (a poor fix could not be repeated). W03/W04 have tests only, no UI (T051, T046). V06 is enforced on the server in one direction only, and W07 on the server reads the new `ProjectProtocol.time_zone`. W05 is out of scope. No criterion was skipped as test/CI only. See D-067.

### T056 · Automatic quality flags
[#73](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/73) · E08 · P1 · should · labels: `backend`, `should` · implements F31 · est. 1.5 d · **done**

From T039 (D-063): a pause stops GPS, so it leaves a gap in the track points. Only the total `paused_seconds` is stored, not when the pauses were, so the points alone cannot tell a pause from a GPS gap. `gps_gap` "outside pauses" needs the pause intervals, which nothing records yet (T038 decides).

From T040 (D-068): "outside pauses" reads `survey_visit.pauses` (a list of `{started_at, ended_at}`, UTC): for two consecutive points, the time between them minus its overlap with the pauses. The phone does the same in `gps_gaps.dart`.

Depends on: T036, T048, T055

- [ ] **Flags** (codes stored in `quality_flags`):
  - `outside_project_area`: observation not within `project.area` (skipped when the area is null)
  - `far_from_transect`: a transect observation farther than `max_distance_from_transect_m` from its transect line
  - `high_count`: `count > high_count_threshold`
  - `gps_gap` (on the visit): any gap between consecutive track points over `gps_gap_s`, outside pauses
- [ ] Flags are computed in the push service after save, for the affected records only. Recompute is available as an admin action and as `manage.py recompute_flags --project`.
- [ ] Admin list filter "Has flag: …" on observations and visits uses the array-contains lookup.
- [ ] Changing a protocol threshold and recomputing changes the flags (tested).

Note from T057: the validation queue's `FlagFilter` (`apps/validation/admin.py`) lists the three codes `outside_project_area`, `far_from_transect` and `high_count`; the "Has flag" filter here can share them.

Note (T056): the "(tested)" criterion is shown by `tmp/t056/smoke.py` (not committed) and by hand, with no automated test (D-021): it changes `high_count_threshold`, `gps_gap_s` and `max_distance_from_transect_m`, recomputes, sees the flags change, restores them and sees them return. The flags are set just before the save, not after it, so one push is one history row (D-093).

### T057 · Admin validation queue
[#74](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/74) · E08 · P1 · should · labels: `admin`, `should` · implements F32 · est. 2 d · **done**

Depends on: T014, T049, T058

- [ ] Proxy model `ValidationQueueItem(ButterflyObservation)` with its own admin, listed under **Validation**. Default queryset: `validation_status = pending`, or any flag, and not deleted.
- [ ] `list_display`: primary photo thumbnail (`<img>` from `/api/v1/photos/{id}/thumbnail`, admin session auth), taxon, count, life stage, observed at, recorder, confidence, flags, project.
- [ ] Filters: project, family, confidence, flag, date. Search: taxon names.
- [ ] Bulk actions: **Confirm**, **Mark unconfirmed**, **Mark undeterminable**.
- [ ] **Change taxon** is an intermediate form with taxon autocomplete and a required comment. It sets `validated_taxon`; `taxon` keeps what the recorder entered.
- [ ] Each action sets `validation_status`, `validated_by`, `validated_at` and `validation_comment`, writes a `ValidationEvent` (T058) and a history reason `"validation: <decision>"`.
- [ ] The change view shows all photos at full size (inline read-only gallery) and a small read-only map.
- [ ] Records of locked visits are view-only (T042).

From T046: the app can now change confidence and species after the create, but `validation_status` is set on create only (D-065). Re-evaluate it here.
From T058: call `validation.services.record_decision` before changing the observation (it reads the previous status and taxon from it), and keep the Validation section read-only for `ValidationEvent` (D-090). Do the event and the observation's change in one `transaction.atomic()`, with the observation loaded by `select_for_update()`, so a failed save leaves no event and the previous values are the stored ones.

Notes (D-091): checked by hand with `tmp/t057/smoke.py` (110 checks; a push at an older `base_version` after a decision comes back `merged`, the decision survives). Also added: stale decisions are refused under the lock and a project the user cannot see is refused (`decide`). No test or CI criteria were skipped, the ticket has none. The queue is narrower than the ticket's wording: a decided record leaves it, because a flag never clears and the queue could not otherwise empty. Beyond the criteria, at the developer's request: a **Send back to queue** action on the observation list, and decision buttons (Confirm, Mark unconfirmed, Mark undeterminable, Change taxon) on the record's page. D-065's and D-082's note that the status is not recomputed is closed here: a real change of taxon or confidence on an undecided record re-evaluates it.

### T058 · Validation history
[#75](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/75) · E08 · P1 · should · labels: `backend`, `database`, `should` · implements F33 · est. 1 d · **done**

Depends on: T044

- [ ] The `ValidationEvent` model is written only by validation services (T057).
- [ ] A read-only inline on the observation admin, newest first.
- [ ] Included in exports as `validation_history.csv` (T064): add the dataset in `apps/exports/datasets.py`, remove it from `DEFERRED` and add it to `BUNDLE_DATASETS`, so the project ZIP includes it.

Note: `record_decision` has no caller until T057 builds the actions, so the check was a smoke script (D-021, `tmp/t058/smoke.py`, not committed). No test or CI criteria were skipped, the ticket has none. See D-090.

### T059 · App map screen with layers and filters
[#76](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/76) · E09 · P1 · must · labels: `mobile`, `must` · implements F34 · est. 2.5 d · **done**

Depends on: T036, T044
Notes: plant/habitat layers added when T051/T053 are done
Deferred: the plants and habitats layers (T052 and T054 add them, see their `From T059` notes); the 5,000-marker timing is a rough check here (markers rebuilt in about 92 ms in a profile build) and is formally timed in T074. Decisions: D-081.

- [ ] **Layers** (toggle sheet): transects, sections, own observations (clustered with `flutter_map_marker_cluster`), plants, habitats, a selected visit's route, and the basemap.
- [ ] **Filters:** visit, species, date range, life stage, behaviour, habitat type. The validation-status filter is dropped because the app doesn't store it.
- [ ] Tapping a feature shows a popup with key fields and an "Open" link to its detail or edit screen.

From T106 (added 2026-10-30): "Open" on an observation goes to T106's observation detail; on a plant or habitat feature it goes to
its edit form (T052, T054); on a visit route it goes to T106's visit detail.
- [ ] 5,000 observation markers render and pan smoothly on the test phone (timed in T074).
- [ ] The online basemap uses OSM tiles with a correct `User-Agent` (`rs.<you>.butterfly`) and the attribution shown. Viewed tiles are cached (flutter_map tile caching). There is **no bulk prefetch** (OSM tile usage policy forbids it).

### T060 · Offline basemap from MBTiles
[#77](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/77) · E09 · P1 · could · labels: `mobile`, `backend`, `could` · implements F29 · est. 2 d · **done**

Depends on: T031, T059

- [ ] `docs/setup/basemap.md` explains producing an MBTiles file for the project area in QGIS (*Processing → Generate XYZ tiles (MBTiles)*, zoom 12–18). The source must allow offline use, for example your own styling of an OSM extract from Geofabrik, or an open orthophoto with a compatible licence. **Not** by scraping tile servers.
- [ ] `Project.basemap` is a FileField in MinIO, uploaded in admin. The offline package (T031) downloads it when present.
- [ ] The app renders it with an MBTiles tile provider for flutter_map (package choice: VERIFY, e.g. `flutter_map_mbtiles`) and falls back to cached online tiles.
- [ ] The file size is shown before download. Typical: 20–80 MB for a few km².

Manual run (2026-11-06, phone over USB, debug build): with a 0.5 MB test file the project map, transect detail and plant location capture drew the tiles in airplane mode; past the file's top zoom its last level is stretched. A 59 MB file: the card showed `Update (57 MB)`, then `Basemap 15.4 / 56.6 MB` with Cancel, then Ready, and the file on the phone matched the server size. A cancel (66 MB file) kept the old file and the card stayed Outdated; Update then fetched the new one. "Remove all local data" deleted `basemaps/`. Backend checked with curl: status, download (`Content-Length`, sha256), 404 for a non-member and for no basemap, no basemap fields in the pull, nginx 403 (not 413) for a 50 MB admin POST. The package behaviour is in D-102.

Deferred: the active visit map, route recording and the Download label of a never-loaded project were not run on the phone (the maps share `TransectMap` and `ProposalMap` with the screens that were); no tests (D-021).


### T061 · Indicators: server SQL views and admin report
[#78](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/78) · E09 · P1 · should · labels: `backend`, `admin`, `database`, `should` · implements F35 · est. 1.5 d · **done**

From T100 (added 2026-10-27): if T100 is done, `report_transect_indicators` also has `valid_visits`, using T100's valid-visit rule
(protocol §6, rules 1–3). If T100 is done after this ticket, T100 adds the column.

From T047 (added 2026-11-05): the criterion already limits per-km and per-hour figures to transect records. Species lists include free
records (`source` other than `transect`, no visit).
Note (T100, done 2026-11-05): the rule is the view `public.survey_visit_validity` (`is_valid`, `reasons`); join it on `survey_visit_id` for `valid_visits`.
`report_transect_indicators.valid_visits` is built here, not in T100.

Note (T061, 2026-11-05): the test criterion is skipped (D-021); it was checked with `tmp/t061/smoke.py` (37 checks, rolled-back fixture). The CSV export is a small
action of its own on the three report admins (D-099), so T065 does not need to add it for them. Year and ISO week use the project's time zone; see D-099.

Depends on: T041, T044, T058

- [ ] **View `report_transect_indicators`** (per transect × year): visits completed, true-zero visits, total duration (h), total distance (km), species count, individuals, observations, confirmed and to-review counts, individuals per km, individuals per hour, and target visits vs actual.
- [ ] **View `report_species_phenology`** (per project × taxon × ISO week): individuals, observations, first and last date.
- [ ] **View `report_behaviour_counts`** (per project × behaviour value): count. Reproductive records = behaviour ∩ {courtship, mating, oviposition} or life stage ∈ {egg, larva, pupa}.
- [ ] Only `source = transect` observations of non-cancelled visits count towards per-km and per-hour figures. Effective taxon = `COALESCE(validated_taxon_id, taxon_id)`.
- [ ] Unmanaged models over the views, with read-only admin changelists, filters (project, year, transect) and CSV export (T065).
- [ ] A test seeds known data and checks every number.

### T062 · App statistics screen
[#79](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/79) · E09 · P1 · should · labels: `mobile`, `should` · implements F35 · est. 1.5 d · **done**

Note (T061, 2026-11-05): use the T061 definitions (D-099): finished visits only, `source = transect` for individuals, species, per-km and per-hour, year and week in the
project's time zone, ISO weeks for phenology. T061's fixture and expected numbers (project in Europe/Belgrade, target 8):
V1 (T1, completed 2026-06-01 09:00Z, 3600 s, 1000 m): O1 taxon A ×3 confirmed; O2 taxon B validated as C ×2 pending; O3 taxon A ×1 deleted.
V2 (T1, completed 2026-06-08, 1800 s, 500 m, zero confirmed). V3 (T1, cancelled) with O4 taxon A ×4. V4 (T1, in progress). V5 (T2, completed 2025-12-31 23:30Z, 600 s, 0 m).
F: free record, no visit, taxon D ×1, 2026-06-03 10:00Z.
T1 / 2026: visits 2, true zeros 1, hours 1.50, km 1.50, species 2 (A, C), individuals 5, observations 2, confirmed 1, to review 1, per km 3.33, per hour 3.33.
T2: year 2026 (not 2025), km 0.00, per km empty, per hour 0.00, individuals 0.
Phenology, 2026 ISO week 23: A 3 individuals / 1 record, C 2 / 1, D 1 / 1 (free record counts); none for B. Behaviour 2026: mating 1, flying 1, reproductive 2.

Depends on: T041, T044

- [ ] Per transect and period, from local data: visits, true zeros, species, individuals, individuals per km, individuals per hour, and the top 10 species.
- [ ] A weekly phenology bar chart for a chosen species (`fl_chart`).
- [ ] A note on screen: "Your records only. Project-wide figures are in the admin reports."
- [ ] Uses the same definitions as T061; a Dart unit test uses the same fixture numbers as T061's test.

From T047 (added 2026-11-05): per-km and per-hour figures count `source = transect` only; species lists include free records.

### T063 · EnvironmentalSnapshot model with manual source
[#80](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/80) · E09 · P1 · must · labels: `backend`, `database`, `must`, `p2-compat` · implements F74 · est. 1 d · **done**

Depends on: T034, T044
Deferred: `environmental_snapshots.csv` export → T064 (the export service is not built yet; T064 already lists it). T064 adds the `environmental_snapshots` dataset, so this is met there.
Found during T063 (2026-10-30): the new model's permissions did not reach the `admin` group until a second `migrate`, so the demo admin did not see the inline. Fixed in T109, not here.

- [ ] When a visit reaches `completed`, the server creates two snapshots (start and end) with `source_type = manual`.
  - Wind Beaufort is converted to m/s using the midpoint of the Beaufort range.
  - The original Beaufort value is kept in `raw_payload_json`.
- [ ] Re-completing (after an edit) replaces the manual snapshots of that visit, never duplicating them.
- [ ] Included in exports as `environmental_snapshots.csv`.
- [ ] Read-only inline on the visit admin.

### T064 · Export service and admin-only export API
[#81](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/81) · E09 · P1 · must · labels: `backend`, `must` · implements F36 · est. 2.5 d · **done**

Depends on: T044, T063
From T041: the visit outcome is `SurveyVisit.outcome` (D-069).
Notes: plant, habitat and validation datasets added when T051/T053/T058 are done
Deferred: `plant_resources`, `habitat_features`, `validation_history` → T051 / T053 / T058 (no models yet). The API answers 404 "Not available until T0xx" and `metadata.json` lists them under `not_included`. Add each to `apps/exports/datasets.py` (and drop it from `DEFERRED`) when its ticket is done.
Skipped (D-021): the automated round-trip test and the "403 (tested)" test. Checked by hand instead (`tmp/t064/MANUAL_CHECKLIST.md`, curl as researcher). R (`readr`) is not installed: not checked.
Checked by hand (2026-10-30): Swagger (parameters, downloads, 400, researcher 403), QGIS (GeoJSON and CSV layers, EPSG:4326, counts), LibreOffice (BOM and plain, Serbian letters), pandas round trip (both bundles), `metadata.json`. Not tested: Excel, and a fresh phone visit (checklist item 0); the Serbian letters were checked with a file from the CSV writer, and snapshots on the Niš project's rows.
Found while checking: the demo data has one observation stored at lon 0.0002, lat 0.0004 and five at Niš coordinates in the Fruška Gora project (test data, not an export problem).

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
[#82](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/82) · E09 · P1 · should · labels: `admin`, `should` · implements F67 · est. 1 d · **done**

Depends on: T064

Note (T061, 2026-11-05): the three report admins already have their own "Export selected as CSV" action (`apps/reports/admin.py`, D-099). Switch it to the shared export service here, or leave it and say so.

- [x] Actions **Export selected as CSV** and **Export selected as GeoJSON** on visits, observations, plant resources, habitat features, transects, validation events and the report views.
- [x] An **Export project bundle (ZIP)** button on the project change page (small `change_form` template override with an object-tools link).
- [x] Output is identical to the API for the same filter (test compares bytes). Skipped as an automated test (D-021); checked by hand with `tmp/t065/compare.py`: CSV and GeoJSON of the six datasets are byte-identical to the API for the same project, and the bundle matches (CSVs byte for byte, `metadata.json` apart from `exported_at`). Output in `tmp/t065/compare-output.txt`.

### T066 · GeoPackage export
[#83](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/83) · E09 · P1 · could · labels: `backend`, `could` · implements F37 · est. 1 d · **done**

Deferred: the QGIS screenshot (`docs/setup/img/t066-qgis.png`); the developer checked the layers, CRS and attributes in QGIS by hand.

Depends on: T064, T067

- [x] `format=gpkg` on the bundle endpoint and the admin project button produce a `.gpkg` with layers built from the `geo` views (T067): transects, sections, observations, plant resources (split into point and polygon layers), habitat features (split by type), plus non-spatial tables (visits, snapshots, validation history). Checked by hand with `tmp/t066/check.py` and `check2.py` (D-103): API and admin button give a `.gpkg`; layer counts equal the bundle `metadata.json` row counts.
- [x] Created with `ogr2ogr -f GPKG out.gpkg PG:"<dsn>" -sql "<query>" -nln <layer>` per layer (GDAL is already in the image).
- [x] Opens in QGIS with correct CRS and attribute types (checked manually; screenshot in docs). Checked by hand in QGIS (all layers and attributes present); screenshot deferred.

### T067 · `geo` views for the five collections
[#84](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/84) · E10 · P1 · must · labels: `database`, `ogc`, `must` · implements F40, F45 · est. 2 d · **done**

Depends on: T004, T021, T044
Notes: plant/habitat views added when T051/T053 are done
Note: `geo.plant_resources` and `geo.habitat_features` are added by T051/T053 (the ticket's own note). The two "test" criteria are shown by hand with `SET ROLE` (D-021). See D-078.
Deferred: `geo.plant_resources` (to T051) and `geo.habitat_features` (to T053), because their tables do not exist yet.

- [ ] The views `geo.transects`, `geo.transect_sections`, `geo.butterfly_observations`, `geo.plant_resources` and `geo.habitat_features` are created by migration (`CreateView` from T004).
- [ ] Arrays become comma-separated text (`behaviour`, `quality_flags`), because array attributes are poorly supported in OGC API Features clients and QGIS.
- [ ] Taxon names and codelist labels are joined in (no foreign-key lookups needed by clients). Observations expose both `taxon_*` (as recorded) and `effective_*` (validated if set).
- [ ] `pygeoapi_ro` can `SELECT` all five views, and cannot read any `public` table (test).
- [ ] A test selects one row from every view after migrations (catches view breakage when models change).

### T068 · pygeoapi collections, filtering and paging
[#85](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/85) · E10 · P1 · must · labels: `ogc`, `infra`, `must` · implements F39, F40, F41 · est. 1.5 d · **done**

Depends on: T007, T067

Note: skeleton collection already removed in T044.
From T067: only `transects`, `transect-sections` and `butterfly-observations` have views until T051/T053. Configure those three: pygeoapi does not start if a configured view is missing.
Note: only three collections, because the plant and habitat views do not exist yet (T051/T053). OpenAPI regeneration is the image's entrypoint, so no code. Skeleton collection already removed in T044. VERIFY: time_field on a view and CQL2 filter= both work on pygeoapi 0.24.0; see D-079. The T044 smoke observation near 0°N 0°E was soft-deleted by hand from the dev database at the developer's request.
Deferred: the `plant-resources` and `habitat-features` collections, to T051 and T053.

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
[#86](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/86) · E10 · P1 · must · labels: `ogc`, `security`, `infra`, `must` · implements F68 · est. 1.5 d · **done**

Depends on: T011, T013, T068
From T068: `infrastructure/nginx/default.conf` has an exact `location = /ogc` block as well as `location /ogc/`: both need the auth_request, or the landing page stays open. Keep `proxy_pass http://pygeoapi;` with no URI: the container listens on 5000 under SCRIPT_NAME=/ogc, so the ticket's `http://pygeoapi:80/` is wrong here. `scripts/ogc-smoke.sh` sends no credentials, so give it an auth header.

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

Note (2026-11-02): built and run by hand; see D-080 and `docs/setup/ogc-access.md`. Nothing skipped but automated tests (D-021), shown by hand instead. nginx `auth_request` on `/ogc`, `OgcVerifyView`, personal tokens in Django admin, Basic with the login throttle, smoke script with `OGC_AUTH`. The nginx block differs from the ticket's (D-080). The demo users' passwords are not `demo-password` here, so the matrix ran with throwaway users `t069-*@test.x` (admin and researcher groups, non-superuser admin created the tokens in Django admin). Results: no credentials 401 with one `WWW-Authenticate: Basic realm="ogc"`; researcher JWT and Basic 403; admin JWT, token, Basic 200; garbage token, wrong password, `Foo bar` 401; deactivated user and deleted token 401 within 61 s and 26 s; `Accept: application/geo+json` 200; POST and DELETE 400 from pygeoapi; HEAD 200; `/api/v1/auth/verify/` 404 from outside; cache: 3 requests, 1 Django call; Basic lockout after 6 wrong passwords answers 401, with its own counter (the app login stays open); `scripts/ogc-smoke.sh` passes. `ogrinfo` works with `GDAL_HTTP_HEADER_FILE`, not `GDAL_HTTP_HEADERS`. QGIS 4.2.3 API Header checked by the developer: connects, and a wrong token falls back to a Basic login prompt. Not checked: a real browser prompt (developer), R (not installed).

### T070 · QGIS interoperability and OGC conformance test
[#87](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/87) · E10 · P1 · must · labels: `ogc`, `evaluation`, `must` · implements F43 · est. 1.5 d · **todo**

Depends on: T069, T071
From T068: `datetime=` on `transects` and `transect-sections` answers 500 (no time_field; provider behaviour), and unknown query parameters are ignored rather than rejected: expect CITE to comment on both, and explain them in the results. A `datetime` window outside a collection's temporal extent answers 400, not an empty result (D-079). Page with `sortby=id`: without it there is no ORDER BY, so OFFSET paging is not guaranteed stable.

- [ ] **QGIS** (version recorded): add an OGC API – Features connection with the token, load all 5 collections, check attribute types and geometry, and use the Temporal Controller on observations. Screenshots go in `evaluation/interop/`.
- [ ] **Python notebook:** reads each collection with `geopandas.read_file(url)` (or requests plus `GeoDataFrame.from_features`) with the token, and pages through more than 1000 features of simulated data.
- [ ] **R script:** reads observations with `sf` or `httr2` and plots a phenology chart.
- [ ] **OGC CITE:** run the executable test suite for OGC API – Features Part 1 (`ets-ogcapi-features10`, Docker image from OGC, VERIFY name and tag) against pygeoapi. Run it directly on the internal port in a `test` compose profile, because the test harness may not send auth headers. Save the HTML report, and explain any failures.
- [ ] Results table (client, operation, result, notes) in `evaluation/interop/results.md`.

### T071 · Simulated field-day generator
[#88](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/88) · E11 · P1 · must · labels: `backend`, `evaluation`, `must`, `p2-compat` · implements F80 · est. 2.5 d · **done**

Depends on: T024, T026, T036, T044, T049
Notes: plants/habitats generated when T051/T053 are done

- [x] `manage.py simulate_season --project <id> --start 2026-05-01 --end 2026-08-31 --visits-per-transect 8 --seed 42 [--direct]`:
  - **Weather per day:** a shared Python module `simweather` (in `simulator/simweather/`, also used by T079 in Phase 2) produces a daily story of temperature, cloud, wind and rain. Visits fall mostly on suitable days. About 10 % are cancelled, with reasons.
  - **Tracks:** walk each transect at 0.8–1.2 m/s, one point per protocol interval, Gaussian GPS noise with σ equal to a sampled accuracy of 3–8 m, and occasional gaps of 60–120 s.
  - **Observations:** species are drawn from the seeded list with per-habitat weights and a Gaussian flight-period curve per species (parameters derived deterministically from the taxon id). Counts follow a Poisson distribution. Confidence mix: 80 % `confirmed_in_field`, 15 % `probable`, 5 % `photo_required` with a placeholder photo.
  - **Plants and habitats:** a few plant resources (points and polygons) and habitat features per transect.
  - **Injected anomalies** to test flags and dedup: high counts, records far from the transect, GPS gaps, true-zero visits, and **duplicate batch submissions**.
- [x] Default mode pushes through `/api/v1/sync/push` with the demo researcher's token (end-to-end). `--direct` writes via services for speed.
- [x] The same seed gives identical data (test compares exports).
- [x] Also exports `database/seeds/transects.gpx` for T072.

Note (2026-11-06): built as D-109; checked by hand with `tmp/t071/` (`clone_project.py`, `compare_exports.py`, `check_walk.py`, `count_flags.py`, `counts.py`, `dc.sh`). "Test compares exports" is skipped under D-021 and replaced by the by-hand comparison: the demo project (push mode) and a copy (`--direct`) gave identical exports for visits, observations, track points, plants and habitats. A rerun is all `duplicate`. No new dependency; one compose mount (`./simulator:/simulator:ro`). Follow-up for the developer to decide (D-105 item 7): rerun `evaluation/results/section-assignment.sql` on the simulated season.

### T072 · GPS replay in the app
[#89](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/89) · E11 · P1 · must · labels: `mobile`, `evaluation`, `must` · implements F80 · est. 1.5 d · **todo**

Depends on: T037
Notes: from T100 (2026-11-05): once replay works, run a replayed visit and compare the app's coverage with the server's `route_coverage_pct` (within 1 percentage
point), and add the result to `evaluation/results/coverage-check.md`. T100 compared stored dev tracks only.

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
[#113](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/113) · E15 · P2 · must · labels: `evaluation`, `database`, `must` · implements F61, F70 · est. 1.5 d · **todo**

Changed 2026-10-27: `should` → `must`, and T091 is no longer a dependency, so T096 stays under cut line B (Keep 25 d / Drop 12.5 d).
It is the main database result of Part 2. Under cut line B it runs on visit routes only. Query 3 needs habitat polygons (T053): if T053 was cut,
it uses section habitat types instead (section lines buffered by 2.5 m, the Pollard recording box).

Depends on: T087, T088
Notes: + focal follows if T091 is done

- [ ] The same six queries (T087) on the simulated season: all observer routes (`visit_route_trajectory`, T088), plus simulated focal follows if T091 is done (add a generator option to T071 if needed), in both implementations.
- [ ] Metrics: execution time (median of 10 runs, warm cache), SQL lines, correctness check (results equal within tolerance), storage size.
- [ ] The same method as the Phase 1 index benchmark (T102): scratch database restored from a backup, data at scale 1 and 10, median of 10 warm runs, and the plan node from `EXPLAIN (ANALYZE, BUFFERS)`.
- [ ] A results table and a short discussion in `evaluation/results/postgis-vs-mobilitydb.md`.

### T097 · Standards comparison write-up
[#114](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/114) · E15 · P2 · must · labels: `research`, `docs`, `must` · implements F89 · est. 1 d · **todo**

Depends on: T095
Notes: + T096 if done

- [ ] `docs/standards/comparison.md` has a table per standard: purpose in this system, implementation used, effort (days from these tickets), maturity of tools, client support found, limitations, and recommendation.
- [ ] It states plainly that sensor data is simulated, along with the GPS-accuracy caveat for Moving Features.

### T098 · Study area editor: edit and remove single polygons, with in-map help
[#115](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/115) · E02 · added 2026-10-19 as a follow-up to T016 · P1 · must · labels: `admin`, `must` · est. 0.5 d · **done**

Depends on: T016

Why: in the T016 admin map, a saved `Project.area` loads as one MultiPolygon feature, so a single polygon cannot be
selected or removed; the only choices are "Delete all Features" and redrawing, or editing in QGIS and re-importing.
Shift + click, which Django's widget documents as vertex delete, added a vertex when tried by hand (2026-10-19).

- [ ] The area map in `ProjectAdmin` loads each polygon of the MultiPolygon as its own feature and saves them back as one MultiPolygon (empty map saves `area = NULL`).
- [ ] Clicking a polygon selects it (highlighted); a **Delete selected polygon** control (and the Delete key) removes only that polygon.
- [ ] Reshaping works: drag vertices and edges, add a vertex on an edge, and **remove a single vertex** with a gesture that actually works (VERIFY Django's shift + click; rebind if needed).
- [ ] Drawing an extra polygon and "Delete all" still work.
- [ ] A **?** icon next to the map shows a short help popup on hover (and on click/focus for keyboard and touch) explaining: draw a polygon (click vertices, double-click to finish), draw freehand (hold Shift and drag), reshape, add and remove a vertex, select and delete one polygon, delete all, and the "Import study area" action for file uploads. Text is translatable (`gettext`).
- [ ] The widget is a reusable class in `apps/core` (subclass of Django's map widget plus a small JS file), so T022 can use it for transect and section geometry.
- [ ] No new dependency: uses the OpenLayers build Django already ships.

Out of scope: merging or splitting polygons, snapping, topology checks. Complex edits stay in QGIS plus re-import.

### T099 · Close a project: no new visits after it is closed
[#116](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/116) · E02 · added 2026-10-27 as a follow-up to T042 · P1 · should · labels: `backend`, `admin`, `mobile`, `should` · est. 1 d · **done**

Depends on: T015, T034, T035

Why: nothing stops a researcher from starting a visit in last year's project. Outside the season is only a warning (T035, W07 in
T055) and the visit lock (T042) covers single reviewed visits, not projects. An admin needs to close a finished project so it takes
no new visits, without deleting it or removing its members.

- [x] `Project.closed_at` (nullable `timestamptz`) and `closed_by`, server-owned, audited (history reason = the admin's reason), included in the projects API and the project pull. Django migration and Drift column. Checked: `0008_historicalproject_closed_at_and_more`, `GET /projects` and the pull show both fields, history keeps the reason (D-104). Drift schema 17.
- [x] Django admin: **Close project** and **Reopen project** actions with an intermediate form and a required reason (at least 10 characters); the project list shows "Closed" and has a filter for it. Checked with a 5-character and a longer reason, the Closed column and filter.
- [x] Push `create` and `POST /api/v1/survey-visits` of a new visit in a closed project are rejected with code `project_closed`. Decide in the plan, recommended yes: a visit whose `started_at` is before `closed_at` is still accepted, so a walk started offline before the close is not lost when it syncs later (this trusts the phone's clock). Checked by push with `client_created_at` before and after the close. The grace time is the mutation's `client_created_at`, so a draft saved before the close still syncs.
- [x] ~~Visits that already exist are not affected~~: they can still be finished, edited and synced (track points, observations), following the visit lock (T042). **Replaced at the developer's request:** a closed project accepts no new or changed data, existing visits included; a visit in progress is cancelled on the phone (D-104 points 2, 3 and 8).
- [x] App: the project list and project home show the project as closed; **Start visit** (tile, transect detail, start form) is disabled with "This project is closed"; a visit in progress can still be finished. **Changed at the developer's request:** the disabled controls show no text, and a visit in progress is cancelled on the phone instead of finished. **Not yet run on a phone.**
- [x] The sync screen names `project_closed` (`syncErrorMessage`). `syncErrorMessage` has a `project_closed` case.

VERIFY (phone, T099): close a project, sync, then check the greyed-out Start visit, Free observation, route and replacement items, read-only plant, habitat and observation screens, and Cancel visit on a visit that was in progress.

Note (T099, 2026-11-06): widened at the developer's request. A closed project accepts no new and no changed data from the app or REST (D-104): not just new visits but also free observations, plants, habitats, proposals, photos and every edit or delete, existing visits included. Changes the phone made before the close still sync. Django admin work (validation, review, lock) is unaffected. This replaces criterion 4 ("visits that already exist are not affected").

Out of scope: closing automatically at the season end (an admin closes it); exports and pygeoapi are unaffected. Reopen is the only way
back; closing deletes nothing and keeps all members.

### T100 · Server-side route coverage and the valid-visit rule
[#117](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/117) · E08 · added 2026-10-27 · P1 · should · labels: `backend`, `database`, `should` · implements protocol §6, F31 · est. 1 d · **done**

Depends on: T036, T040, T056

Why: protocol §6 makes coverage ≥ `min_coverage_pct` part of a valid visit and says T061 computes it, but T061's criteria don't, and v4
cut the server-side coverage flag (T056: "shown in app only"). Without it, T061 and T101 cannot filter on valid visits. Comparing the
app's and the server's values is also Q7 evidence. The issue has the full SQL.

- [ ] `SurveyVisit.route_coverage_pct` (`numeric(5,1)`, null): server-owned, read-only in the API, neither pushed nor pulled (no Drift change).
- [ ] Computed where `distance_walked_m` is (D-060): when the visit ends up `completed`/`synced` **and after every track batch for a finished visit** (a visit finished offline arrives before its points), plus `recompute_flags` and the admin recompute action (T056).
- [ ] Same definition as T040 (note under T040): samples at 0, 10, 20 … m plus the end point, in the transect's UTM zone (`utm_srid`, D-046). A sample is covered when a usable route **point** (D-060 accuracy rule, live points) is within `max_distance_from_transect_m`. Fewer than 2 usable points → `null`. Written into `docs/requirements/protocol.md` §6.
- [ ] Flag `low_coverage` when below `min_coverage_pct`. This reverses the v4 cut on the server side (DECISIONS.md entry). It is never a rejection.
- [ ] The valid-visit rule (§6 rules 1–3) is one SQL expression or view that T061 and T101 reuse. `report_transect_indicators` gets `valid_visits` (here if T061 is done, else in T061).
- [ ] The admin visit page shows the coverage and draws the uncovered parts of the transect (`ST_Difference(transect, ST_Buffer(route_points, d))` in UTM).
- [ ] Checked once against the app with a replayed track (T072): within 1 percentage point. Result recorded in the evaluation notes.

Note (T100, 2026-11-05): the replay comparison is deferred to T072 (a note there); T100 compared stored dev tracks instead
(`evaluation/results/coverage-check.md`, 13 visits, largest difference 1.0 percentage point). `report_transect_indicators.valid_visits` is built in T061 (a note
there); T100 provides the view `public.survey_visit_validity`. The weather justification is `weather_missing_reason` only (D-095).

Out of scope: effort (a route that doubles back counts once) and time (pauses don't matter).

### T101 · Research-question analysis views (Q1, Q3, Q4, Q6)
[#118](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/118) · E09 · added 2026-10-27 · P1 · should · labels: `backend`, `database`, `should` · implements outline §4 · est. 2.5 d · **done**

Depends on: T044, T048, T051, T053, T061, T071
Notes: valid-visit filter from T100 if done: join the view `public.survey_visit_validity` (T100) on `survey_visit_id` and keep `is_valid`

Why: the outline's goal is that two or three research questions (§4) can be demonstrated. No ticket computes any of them. One SQL view
per question, built like the T061 views, answers it with a PostGIS join. On simulated data the generator plants known effects, and the
results chapter shows the views recover them; it says nothing about real butterflies. The issue has the SQL sketches.

- [x] **Q1 `report_habitat_richness`** (project × habitat type × year): sections, section km, valid visits, species, individuals, individuals per km. Incidental records take their habitat from the `habitat_feature` polygon they fall in, else `unknown`.
- [x] **Q3 `report_specialist_host_plants`** (section × year): specialist individuals, host-plant patches within `host_plant_radius_m` and their summed abundance midpoints. Index-friendly `ST_DWithin` (`&&` prefilter).
- [x] **Q4 `report_reproductive_microhabitat`** (project × habitat type): reproductive records in polygons of that type, polygon area, the share of records against the share of area, and Jacobs' index `D = (r − p) / (r + p − 2rp)`. Reproductive uses the T061 definition.
- [x] **Q6 `geo.observation_hexgrid`** (project × hexagon, `ST_HexagonGrid`, default 100 m, in UTM): observations, individuals, species, nectaring and reproductive records. Empty hexagons are left out. Published in pygeoapi (T068).
- [x] Q1 and Q3 are the core. Q4 and Q6 are dropped if the supervisor picks only two questions.
- [x] Server-only `taxon_host_plant (taxon, plant_taxon, source)` from a curated CSV in `database/seeds` (the species the demo project and the generator use, with a source per row). Not synced. Specialist = all host plants in one genus, derived from this table (`Taxon` unchanged) unless the supervisor prefers a literature flag.
- [x] `simulate_season` option (e.g. `--planted-effects`): host-plant patches near some sections, specialists biased towards them, reproductive records biased towards one habitat type, and the effect sizes written to the output.
- [x] Q1 and Q3 count valid visits only (T100, else completed non-cancelled visits, noted). Effective taxon = `COALESCE(validated_taxon_id, taxon_id)`.
- [x] Unmanaged models, read-only admin changelists with project/year filters, and CSV export (T065 if done).
- [x] Each view is checked by hand on a tiny seeded case worked out on paper. Results on the simulated season, next to the planted effects, go in `evaluation/results/research-questions.md`.
- [x] `EXPLAIN` of each spatial join shows a GiST index scan. Plans are recorded for T102.

Out of scope: statistics (GLMs) in the system; analysis in R uses the export. GPS error (5–15 m) blurs point in polygon for small polygons: document it.

Notes (T101, D-110): all four questions built; the automated-test part of "checked by hand on a tiny seeded case" was skipped (D-021) and done by hand in `tmp/t101/smoke.py` (49 checks, not committed).
The supervisor has not yet picked which questions go in the thesis. Q1's encoded habitat ranking is not clearly recovered on one season (`evaluation/results/research-questions.md`).

### T102 · Spatial index benchmark on the simulated season
[#119](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/119) · E11 · added 2026-10-27 · P1 · should · labels: `evaluation`, `database`, `should` · implements F61 (P1 part) · est. 1 d · **done**

Depends on: T048, T056, T071
Notes: + T100 and T101 queries if done
From T067: add the OGC bbox queries to the fixed SQL files: `SELECT * FROM geo.<view> WHERE ST_Intersects(ST_MakeEnvelope(<bbox>, 4326), geometry)` for each `geo` view that exists, which is the filter pygeoapi 0.24 generates. Include `geo.transects`: on the dev data the planner used its `project_id` index rather than GiST, so check which index it picks at scale.

Why: the code already casts geometry to `geography` (`surveys/services.py`, `transects/services.py`), and a geography cast in a filter or
in KNN cannot use the GiST index on `geometry`. Nothing measures whether the spatial queries use their indexes. T096 reuses this method in Phase 2.

- [x] Runs on a scratch database restored from a backup (T010), never on the dev data.
- [x] Simulated season at scale 1 and scale 10, using the generator's existing flags if they can do it.
- [x] Fixed SQL files in `evaluation/benchmarks/spatial/`: section assignment (T048), `far_from_transect` and `outside_project_area` (T056), walked distance and coverage (T036, T100), T101 Q3/Q4 if done, and KNN nearest host plant.
- [x] Configurations: **A** no index (`SET LOCAL enable_indexscan/enable_bitmapscan = off`, or `DROP INDEX` inside `BEGIN … ROLLBACK`), **B** GeoDjango's GiST, **C** B plus a fix (`gist ((geometry::geography))` expression index, `&&` prefilter, or UTM).
- [x] Metrics: median of 10 warm runs, plan node from `EXPLAIN (ANALYZE, BUFFERS)`, index size.
- [x] Results and discussion in `evaluation/results/spatial-indexes.md`.
- [x] Where C clearly wins, fix the real code (new migration) and add a DECISIONS.md rule.
- [x] Note the size of the GiST indexes on `historical_*` tables and decide whether to keep them.

Out of scope: general claims. It is one laptop and one generator run, and a Seq Scan winning at Phase 1 volumes is a valid finding.

Note (T102, D-111): scale 10 = `--visits-per-transect 80` (agreed 2026-11-07); scratch databases `butterfly_bench_s1` and `butterfly_bench_s10` restored from a T010 backup; no criteria skipped (the ticket asks for no tests). One variant won and is applied: the Q3 view without its `&&` prefilter (about 4×, same rows) as `reports/0004_q3_drop_bbox_prefilter` (D-111); every other variant lost or tied. The migration is applied on the scratch database only, not on the dev database. The historical-index drop is a recommended follow-up (a new ticket for the developer).

### T103 · Linear referencing: positions along the transect
[#120](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/120) · E06 · added 2026-10-27 · P1 · could · labels: `backend`, `database`, `could` · implements F19 (extends) · est. 1 d · **done**

Depends on: T044, T048, T067

Why: transect data is one-dimensional ("200 m from the start"). PostGIS linear referencing gives each transect record its distance along
the transect and its offset from it. This gives an abundance profile along the route and numbers for T048's section-boundary limitation.

- [x] `geo.transect_sections` gains `start_m` and `end_m` (UTM, `ST_LineLocatePoint` × length; sections tile the line, D-046).
- [x] `geo.butterfly_observations` gains `distance_along_m` and `offset_m` for transect records (null otherwise).
- [x] View `report_transect_profile` (transect × year × `bin_m` bin, default 50 m): observations, individuals, species.
- [x] On the simulated season, count the records where nearest section (T048) and `[start_m, end_m)` disagree, and their distance to a boundary. Recorded in `evaluation/results/section-assignment.md`.
- [x] A DECISIONS.md entry on which method T048 keeps (keep the `offset_m ≤ max_distance_from_transect_m` check either way).

Out of scope: storing the values (views only, no sync or Drift change). On a transect that loops back on itself, `ST_LineLocatePoint` can pick the wrong pass: document it.

Note (2026-11-06, agreed with the developer): the section-assignment comparison ran on the dev data (1 121 records), not the simulated season; rerun `evaluation/results/section-assignment.sql` after T071. `report_transect_profile` also got a read-only admin page like the T061 reports (not in the ticket text). T048 keeps nearest-section (D-105). None skipped (the ticket asks for no tests).

### T104 · App reads the protocol's time zone (rule W07)
[#121](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/121) · E08 · added 2026-10-28 · P1 · should · labels: `mobile`, `should` · implements F30 (extends T055) · est. 1 d · **done**

Depends on: T055, T035

Why: the season dates and the daily window are local times at the study site. T055 gave the protocol a `time_zone` and the server reads it (D-067); the app still uses the phone's zone for W07. Reading the protocol's zone makes both sides agree when the phone's zone is wrong or the project is in another country.

- [ ] Drift `ProjectProtocols` gains `timeZone` (schema bump, snapshot, migration step); the pull applier reads `time_zone`.
- [ ] Existing protocols reach the phones: server migration `projects/0006` did not change any row's `server_version`. Save each protocol on the server (trigger bumps it), or reset the protocol pull cursor in the app's migration.
- [ ] `seasonWarning` and `timeWindowWarning` convert the instant to the protocol's zone before comparing (both ends still inside).
- [ ] The protocol summary and the start-visit form show the zone.
- [ ] Tests (exception to D-021): a W07 case where the phone's zone and the protocol's zone disagree, with a fixed zone.
- [ ] `validation-rules.md` (W07 note) and D-067 updated.

Needs a new dependency, the `timezone` package (Dart has no IANA database in the core library): ask the developer when the ticket is built. An unknown zone name falls back to the phone's zone.

Note (2026-11-04, agreed with the developer): `timezone` 0.11.2 approved (exact pin, full database). Season dates moved to UTC midnight in the app (pull, migration `from14To15`, rules), which the ticket text did not mention (D-094). The admin's Time zone field became a searchable list. All criteria met; none skipped.

### T105 · Project home: the Start visit tile, and tiles not built yet
[#122](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/122) · E02 · added 2026-10-30 as a follow-up to T017 · P1 · must · labels: `mobile`, `must` · est. 0.5 d · **done**

Depends on: T017, T033, T035, T039

Why: T017 asked for the tile grid, but no ticket gives the **Start visit** tile a target, so tapping it does nothing. A visit can
only be started through Transects → transect detail → Start visit. Free observation, Plants & habitat, Map and Statistics also do
nothing on tap until T047, T052, T059 and T062 land, and three of those are Should, so they may stay that way in the Phase 1 build.

- [x] **Start visit** tile, reading Drift only (works offline):
  - a visit of this project is `in_progress` → open its active visit screen (T039)
  - else the user has drafts in this project → a bottom sheet with one row per draft ("Continue draft · transect code · date",
    opening the start form) and **Choose a transect**
  - else (or Choose a transect) → the transect list (T033) sorted by distance when a fix is known, so the nearest is on top
- [x] The start form still opens only from transect detail, so the inactive-transect, season and time-window checks stay in one place.
- [x] Tiles whose screen does not exist yet are drawn disabled (greyed, no ripple) with a short "Coming later" line, instead of doing
  nothing on tap. The ticket that builds each screen enables its tile (T047, T052, T059, T062).

Out of scope: closed projects (T099 disables the tile).

Note (2026-10-30, agreed with the developer): a visit in progress in a *different* project also opens from the tile, since only one
visit is walked at a time. This goes beyond "a visit of this project" above. See D-073.

### T106 · App visit detail and observation detail
[#123](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/123) · E05 · added 2026-10-30 · P1 · must · labels: `mobile`, `must` · est. 1.5 d · **done**

Depends on: T033, T040, T041, T045

Why: after a walk a researcher cannot look at what they recorded. The **My visits** rows on transect detail (T033) cannot be tapped,
nothing lists a visit's observations, and no screen shows one observation. T050 puts thumbnails "in the observation detail", T059's
map popup has an "Open" link and T046 edits "an existing observation", but no ticket builds that screen.

- [ ] Tapping a row in **My visits**: `draft` opens the start form (T035), `in_progress` the active visit screen (T039), any other
  status the new **visit detail**. Its route is not nested under the active visit route, so Back returns to transect detail.
- [ ] **Visit detail** (read-only):
  - transect, date, start and end in local time, observers, status (lock icon when locked, the reason when cancelled)
  - walking time without pauses, distance and route coverage, reusing the T040 summary code
  - start and end weather, the weather-suitable flag, the true-zero flag, notes
  - a map with the transect, the sections and the walked route when the track points are on this phone. Track points are not
    pulled (D-060), so on another phone the map shows the transect and "Route not on this phone".
  - the visit's observations grouped by section (species, count, time); a row opens observation detail
- [ ] **Observation detail** (read-only, its own route): species (scientific and local name), count, time, position and accuracy,
  section, source, confidence, and the extended fields when set (sex, life stage, behaviour, notes). A photo area that T050 fills.
  An **Edit** button that T046 enables (hidden until then, and on locked visits, T042).
- [ ] Both screens read Drift only, work offline, and follow changes from a pull (`StreamProvider`). Soft-deleted rows are not shown.

Out of scope: editing (T046), photos (T050), a project-wide list of all observations (the map, T059, covers it; free observations
have no visit and are reached from the map popup).

### T107 · App shows photos that are not on this phone
[#124](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/124) · E06 · added 2026-10-30 as a follow-up to T050 · P1 · should · labels: `mobile`, `should` · est. 0.5 d · **done**

Depends on: T050, T106
Notes: the second-phone case was simulated by moving a photo's file off this phone (no second device; "Remove data" was avoided because of D-060). Shown by hand on the phone, 14 steps. Beyond the ticket text, at the developer's request: every photo opens the viewer (own file or the server's full image, with star and delete in its app bar), and the map popup shows the thumbnail too (D-083).

Why: pull brings the photo rows of the user's observations, but not the files, which live only on the phone that took them. After a
reinstall or on a second phone, observation detail would show empty photos. The server already serves
`GET /api/v1/photos/{id}/thumbnail` and `/content` to the owner (T049, D-072).

- [ ] A photo row with no local file shows the server thumbnail when online. It is fetched through dio with the JWT (a path
  relative to the server, D-013) and cached as `<app documents>/photo_cache/<photoId>_thumb.jpg`.
- [ ] Tapping it opens the full image (`/content`), downloaded on demand and not kept.
- [ ] Offline, or when the server has no uploaded file yet (404): a placeholder, "Photo is on the server" or "Not uploaded yet".
- [ ] The cache is deleted on logout, and its size is included in the photo storage figure on the sync screen (T050).
- [ ] No new dependency (dio and `Image.file`).

Out of scope: downloading every photo ahead of time; seeing other phones' photos offline.

### T108 · Route proposals from the field
[#125](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/125) · E03 · added 2026-10-30 · P1 · should · labels: `backend`, `mobile`, `admin`, `sync`, `should` · est. 2 d · **done**

Note: decided beyond the text above (2026-11-05): built in two sessions (backend and admin, then the app) with one commit at the end; the proposer is `created_by`, not a separate column; the phone only creates proposals (no edit or withdraw, push `update`/`delete` exist on the server); the proposal's length is the server's (`length_m`), the app shows its own estimate until the pull brings it; added at the developer's request: **Draw on map** (a line tapped on the map, for routes that cannot be walked; drawn only, the admin cannot tell it from a walked one). See D-098.

Depends on: T022, T026, T037
Notes: the Free observation button on the recording screen needs T047; without it the screen has no button. T047 is built: the button calls
`openFreeObservation` (`features/observations/ui/free_observation_entry.dart`), with `incidental` as the default source

Why: transects are drawn in Django admin, often without anyone having walked them. In the field a route can turn out to cross
private land, a cliff or impassable vegetation. Today the researcher can only cancel the visit (`invalid_protocol`) and tell the
admin. A transect created on the phone during a walk would not fit the method: a Pollard walk repeats a fixed route, a visit needs
a transect with sections (T048, coverage in T040 and T100, indicators in T061), and transects are reference data written only by
pull. So the researcher records a **proposal**, and an admin turns it into a transect; standardised visits start on it afterwards.

- [ ] **Model** `TransectProposal` (`transect_proposal`, syncable, audited): project, proposer (set by the server from the
  request), name, reason (`private_property`, `unsafe`, `impassable`, `better_route`, `other`), optional `replaces_transect` (same
  project), notes, `geometry` (LineString 4326, valid, at least 2 points, rule V08), `recorded_from` and `recorded_to`, and
  `length_m` computed by the server. Server-owned: `status` (`pending` | `accepted` | `rejected`), `review_note`, `reviewed_by`,
  `reviewed_at`, `created_transect`. Push `create`, plus `update` and `delete` (soft) while `pending`; pull of the user's own
  proposals. Django migration and Drift table.
- [ ] **App, recording:** **Propose a route** on the transect list, and **Propose a replacement** on transect detail (fills in
  `replaces_transect`). A recording screen with a map (the project's transects for reference, the recorded line), length, time,
  Pause/Resume and Finish. Fixes come from `LocationSource` (foreground service, T037), use the accuracy rule of D-060, and are kept
  in a local-only Drift table, so a killed app resumes the recording. Not available while a visit is in progress (one GPS stream).
- [ ] **App, saving:** Finish asks for the name, reason and notes, builds the line from the usable fixes and queues the create.
  **Discard** deletes the recording. If T047 is done, the recording screen has a **Free observation** button (source `incidental`).
- [ ] **App, status:** a **My proposals** list on the transect list shows each proposal with its status, the review note, and the
  new transect's code once accepted.
- [ ] **Admin:** a proposal list (filters: project, status, reason) and a change view with the line on a map, the replaced
  transect dashed beside it. Action **Create transect** (one proposal, intermediate form: code, name, "deactivate the replaced
  transect"): creates a `Transect` with the proposal's line and `active = false`, sets `accepted` and `created_transect`, and
  links to the new transect, where the admin cuts sections (T022) and then activates it. Action **Reject** with a required
  reason (at least 10 characters).
- [ ] Accepting changes no existing visit. A replaced transect is deactivated, never redrawn, so its past visits keep their line.
- [ ] `docs/requirements/protocol.md` §9 step 0 says how routes are proposed (after the biologist confirms the method), and a
  DECISIONS.md entry records why a proposal is not a visit.

If time is short (0.5 d instead): an admin action **Create transect from this visit's route** on the visit admin, for a visit the
researcher walked on the real route and cancelled as `invalid_protocol` with a note. No app work.

Out of scope: section drawing on the phone; proposals in exports and the OGC views; editing the line of a pending proposal on the
phone (discard and record again).

### T109 · Admin group gets a new model's permissions on the same migrate
[#126](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/126) · E02 · added 2026-10-30 as a follow-up to T013, found in T063 · P1 · should · labels: `backend`, `admin`, `security`, `should` · est. 0.5 d · **done**

Note: checked by hand (D-021); no test or CI criteria were skipped, the ticket has none. Before the fix, after deleting 16 permission rows (`sync`, `environment`), one `migrate` left `want=136 have=120 missing=16` and a second one `missing=0`. After the fix one `migrate` gives `missing=0 extra=0`, a second `migrate` (nothing to apply) gives the same counts and the same hash of the group's rows, and `migrate` on an empty throwaway database gives `want=132 have=132 missing=0 extra=0` (the dev database has 4 stale `core.skeletonping` rows more). With `django.contrib.auth` listed after `apps.accounts`, a fresh `migrate` gives `missing=0`; with the explicit `create_permissions` call disabled it gives `missing=4`. See D-085.

Depends on: T013
Notes: placed just before T051, the first fill-list ticket that adds a model

Why: `sync_admin_group_permissions()` (T013) runs from a `post_migrate` receiver that acts only when the sender is `apps.accounts`.
Django creates each app's permissions in that app's own `post_migrate`, and `accounts` comes before apps such as `environment`, so on
the migrate that adds a model in a later app the grant runs before its permissions exist and misses them. A second `migrate` picks
them up. Until then a staff user in the `admin` group (not a superuser) gets 403 on the model, or does not see an inline for it,
with no error anywhere. Seen with T063: `admin@demo` did not see the Environmental snapshots inline while the superuser did.

- [ ] After one `migrate` that adds a model (new database, or an existing one), the `admin` group holds every permission of the
  project's apps, including the new model's. Shown by hand: add or reset a model's permissions, run `migrate` once, and read
  `Group.objects.get(name="admin").permissions` against `Permission.objects.filter(content_type__app_label__in=<project apps>)`.
- [ ] A fresh database (`migrate` from empty) also ends with the group complete after the first run.
- [ ] A later `migrate` with nothing to apply changes nothing.
- [ ] The comment on `sync_admin_group_permissions` and the "admin group holds all model permissions" line in CONVENTIONS.md still
  describe what happens. A DECISIONS.md entry records the chosen hook (for example, run after the last project app's `post_migrate`).

Out of scope: a custom permission framework (CLAUDE.md); changing which permissions the group holds; tests (D-021).

### T110 · App adds an observation to a finished visit
[#127](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/127) · E06 · added 2026-11-02 as a follow-up to T045 and T106 · P1 · should · labels: `mobile`, `should` · est. 1.5 d · **done**

Depends on: T045, T046, T106
Notes: settled 2026-11-05, see D-097. (1) Zero flag: a visit finished as a true zero gets `zero_observation_confirmed = false` in the same transaction, after a confirm dialog; Undo does not put it back.
(2) Route coverage, distance and walking time do not change; species and individual counts do. (3) No quality flag; "added after the visit" is enough.
(4) Admin add is not built here: draft `tmp/ticket-drafts/T113-admin-add-observation.md`.

Why: Add butterfly exists only on the active visit screen, and `ObservationRepository._checkVisit` refuses any visit that is not `in_progress`
("The visit is no longer in progress."). A researcher who finishes a visit and then remembers a butterfly, or finishes too early, cannot add it.
The visit never goes back to `in_progress` (visit-states.json), Django admin has no add for observations (D-065, "No add"), and T047's free
observation has no visit, so it would drop out of the visit's counts and the per-km and per-hour indicators (T061, T062). The server already
accepts the record: rule V03 lists `in_progress`, `completed`, `synced` and `reviewed` as statuses an observation may be recorded on
(`apps/observations/rules.py:17`), and V04 only requires `observed_at` between the visit's start and end, within a tolerance. So this is an
app-only change.

- [ ] **Entry:** the visit detail (T106) has an **Add observation** button for the user's own visit in status `completed`, `synced` or
  `reviewed`. It is hidden for `locked` (unlock first, T043), `cancelled` and `draft`, and for other users' visits. It opens the same sheet as
  Add butterfly (`QuickButterflySheet`, with Details and photos), plus a **time** and a **position** field (next two points).
- [ ] **Time:** the user picks when it was seen, defaulting to the visit's end time. The picker refuses a time outside the visit's start and
  end (V04) and says so. Times are UTC in the database and local only in the UI.
- [ ] **Position and section:** the user taps the position on a map of the visit's transect and route. `accuracy_m` is `null` (placed by hand,
  as in T047). The section is the one nearest to that point, found as the active visit does (`current_section.dart`). Nothing is taken from the
  current GPS fix, since the user may be anywhere.
- [ ] **Write:** one transaction through `SyncRepository.write`, with rules V01-V04 and V06-V08 checked before the write and the W rules as in the
  quick entry. `_checkVisit` allows the finished statuses for this path only; the active screen keeps requiring `in_progress`, and a locked
  visit is still refused.
- [ ] **Shown:** the new observation appears at once in the visit's list (T106), the map (T059) and the observation detail, can be edited until
  the visit is locked (T046), and syncs. Shown by hand: finish a visit, add one, Sync now, and read the row on the server (`psql`) with the same
  visit, the picked time and `source = transect`.
- [ ] **Recognisable:** an observation added after the visit ended can be told apart. Its `created_at` (the time of writing, already stored) is
  after the visit's `ended_at`; the visit detail list shows "added after the visit" on it.
- [ ] No new dependency; no Drift or Django migration unless an open question below says otherwise.

Open questions (to settle before building):
1. **Visit's zero flag.** A visit finished as "no butterflies" has `zero_observation_confirmed = true`, and rule V06 rejects that flag when the
   visit has transect observations, so the visit's next update would fail. Clear the flag in the same write, or refuse and tell the user?
2. **Counts the researcher sees.** Route coverage, the summary and the indicators are worked out from the points and the visit window; does
   a late observation change any figure that was shown on the Finish screen? (It should not change coverage.)
3. **Quality flag.** Should a late entry get an automatic flag (T056), or is the `created_at` difference enough?
4. **Admin.** Should the Django admin also be able to add an observation to a visit? It is out of scope here; say if it should be its own ticket.

Out of scope: reopening a visit (`completed` back to `in_progress`); free observations without a visit (T047); a locked visit; changing the
time, position or section of an existing observation (T046 left them out); Django admin add; tests (D-021).

### T111 · Admin adds and edits plant records on a map
[#128](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/128) · E07 · added 2026-11-03 as a follow-up to T051 and T052 · P1 · could · labels: `backend`, `admin`, `could` · implements F20 (admin side) · est. 2 d · **done**
Deferred: the phone checks (a)-(f) of "Effect on phones" were not run by Claude (no phone here); the developer runs them by hand.

Depends on: T051, T052
Note (T112): hand check (e) no longer holds for other members of the project: a record added for a researcher now also reaches the phones of the project's other members.
Notes: All decisions settled (1-5 below).

Why: The plant record page in Django admin is read-only (T051, D-086; T052 added a read-only map). An admin who sees a wrong species, a wrong relation or a misplaced point cannot correct it, while a butterfly observation of an unlocked visit can be corrected (T044, T042). A patch drawn badly in the field is easier to fix on a large map at a desk, and the researcher's phone is not always at hand. An admin should also be able to record a plant without a phone (from a paper form or a photo).

This follows D-003 (admin-only operations live in Django admin). It differs from butterfly observations, which have no add in admin (D-065): whether they should get one is T110's open question 4, not this ticket.

Decisions (2026-11-03):
1. **A change of relation is refused when it breaks a link.** If live butterfly observations link to the record and the new `resource_type` no longer fits the role (D-086, `PLANT_LINK_ROLES`), the save is refused. The form error names up to five observations (date and species), then "and N more", and says to change them first. **Admin only:** phone, push and REST keep D-086's "no re-check", and a later ticket can change that.
2. **A soft delete is refused while a live observation links the record,** as the phone does (D-087). Also admin only: `push_delete` does not check this.
3. **A record is added only for a member of the chosen project** (`created_by`), so it reaches that member's phone on the next pull.
4. **On add, a visit is checked on the server.** It must be in the chosen project and created by the chosen researcher (the rule the phone's pull uses). A form error refuses anything else; no script filters the list.
5. **`observed_at` is editable,** as for butterfly observations.

- [x] **Editable fields:** `plant_taxon` (empty for an unidentified plant), `resource_type`, `observed_at`, `abundance_class`, `phenology_stage`, `flowering_intensity`, `eggs_present`, `larvae_present`, `feeding_damage_present`, `notes`, `geometry`. Read-only on an existing record: `id`, `project`, `survey_visit` (D-086), `created_by`, `patch_area_m2`, `deleted_at` and the sync fields.
- [x] **Add:** the page has an Add button. The form asks for the project, the researcher (`created_by`), an optional visit (`raw_id_fields`, as the observation admin does), `observed_at` (default now), the relation, the plant (or notes) and the shape. `patch_area_m2` is not on the form. The id is the model default (`uuid4`). The history reason is "admin add" (the reason dialog only shows on a change). A locked visit refuses a new record on it.
- [x] **Map:** `geometry` uses Django's generic map widget (`MapAdmin`) with the Line button hidden by CSS (`.type-LineString`), since V08 refuses a line. An existing shape can be reshaped or moved straight away. To change type, the admin clicks **Delete all Features**, picks Point or Polygon and draws: the widget hides the type buttons while a shape exists. A help line says so. A read-only note gives what is stored now ("Polygon, 4064.1 m²").
- [x] **Exact coordinates:** an optional form field takes GeoJSON in longitude and latitude (WGS 84). When filled, it replaces the map's shape. Django's `display_raw` box is not used: it holds Web Mercator metres, and typed `[20.45, 44.81]` was saved near 0°, 0° with no error.
- [x] **An untouched map changes nothing:** when `geometry` is not in `form.changed_data`, the stored value is kept exactly. The widget's round trip through Web Mercator moves a coordinate slightly (`20.457312` came back as `20.457311999999998`), and `has_changed` hides that.
- [x] **One save path:** a new `resources.services.admin_save_plant_resource` (like `observations.services.admin_save_observation`) for add and change. It refuses a locked visit (form error) and applies V02, V07, V08, decision 1 and "an unidentified plant needs notes". That last rule is in the serializer today, which an admin form does not pass through, so it moves to a function that both call. The rule that empties the area on a shape change moves out of `apply_plant_resource_changes` in the same way: `save_plant_resource` only fills an empty area. The change reason comes from `HistoryAdmin`'s dialog, default "admin edit".
- [x] **Soft delete and Restore:** the two actions are switched on for this page, and this page overrides them. Each record is handled on its own and a refused one is named in the message (as Reassign sections does, T048). Both refuse a locked visit, and Soft delete applies decision 2. The shared `SyncableAdmin` actions check neither.
- [x] **Read-only pages:** a record of a locked visit (T042) or a soft-deleted record opens read-only, with T052's read-only map. `location_map` is only on these pages.
- [x] **Rule messages:** a refused save shows a sentence on the field, through `core.admin.add_validation_errors` and an explain function for plant rules (the observation admin's `_explain_rule` reads `ButterflyObservation`, and its V08 text only speaks of a point).
- [ ] **Effect on phones, shown by hand:** (a) change the species in admin, Sync now, the phone shows the new name; (b) an unsynced phone edit of **another** field: `merged`; (c) an unsynced phone edit of the **same** field: `conflict` (D-049), on the Sync screen and in admin's Sync conflicts; (d) a point changed to a polygon gets its area from the server and the phone pulls it; (e) a record added for a researcher appears on their phone after a sync, and not on another user's (T112 changes this last part); (f) a soft delete removes the record from the phone and Restore brings it back.
- [x] **Permissions, checked by hand:** a non-superuser admin sees Add and can save. The Admin group already holds the add and change permissions (T109, D-085), so no grant is needed.
- [x] The photos inline stays read-only. No new dependency and no migration. Docs: `backend/CLAUDE.md` (the "read-only admin" wording) and a decision entry that refines D-086 and D-087.

Technical notes: Copy the pattern of `backend/apps/observations/admin.py` (`ButterflyObservationAdminForm`, `save_model`, `has_change_permission`) and `observations/services.py` (`check_admin_edit`, `admin_save_observation`). `SyncableAdmin.sync_readonly_fields` includes `created_by`, so `get_readonly_fields` must let it through on add. `build_new_plant_resource` reads a serializer payload and takes the caller as creator, so the admin path builds on the form's instance. `save_with_reason` sets `updated_by` to the admin and leaves `created_by` alone, so the researcher still owns the record and can edit it from the phone (`sync/services.py`, created_by or admin). A map zooms to the project only on a change page; the add page opens on `MapAdmin`'s default.

If time is short (1 d instead): Edit only: no Add button and no GeoJSON field. Soft delete and Restore stay off.

Out of scope: Editing photos in admin (make primary, delete); An admin page for habitat features (T053 does not list one, so that gap stays until it is asked for); Unlocking a visit (T043). Changes to the phone (a pulled change already shows, D-087); The same link checks on phone, push and REST. Tests (D-021).

### T112 · Project members see each other's plants, habitat features and observations
[#129](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/129) · E07 · added 2026-11-03 as a follow-up to T051 and T052 · P1 · could · labels: `backend`, `mobile`, `sync`, `could` · implements F20, F21, F35 (changes the researcher role in PROJECT_OUTLINE) · est. 6 d (was 3 d; widened 2026-11-06) · **done**

Deferred: Polygon (walk) outdoors and sensitive-species hiding are untested/unchanged as before; not tested on the phone: an admin editing another member's record, and a second phone at the same time. Track points and observation photos are still not shared (out of scope).
Depends on: T051, T052, T053, T054, T059, T062
Settled by the plan (2026-11-06, D-107): (1) three name columns: `created_by_name` on plant and habitat rows and `recorded_by_name` on observations (visits get none); (2) others' plant photos are pulled only once uploaded; (3) others' observations on a visit that is not on the phone are hidden on the map; (4) "Linked to N" counts only the creator's own observations; (5) "Recorded by" is "You" / the name / "Another researcher"; (6) others' observations are purple. Changed at the phone test: the note "Your records only…" (decision 8) is removed altogether, because the switch makes it redundant. Also changed at the phone test: decision 6's "finished visits only" is dropped, every visit of the project (draft, in progress, cancelled too) is pulled, because data collected on a transect belongs to the project (D-107).
Notes: Decisions 1-5 settled 2026-11-03; 6-8 added 2026-11-06 at the developer's request (widened to observations, visits and statistics). Decision 1 now covers butterfly observations too.

Why: Plants and habitat features describe a place, not one person's sighting. A researcher who walks a transect, or picks a host plant to link to a butterfly, benefits from what the project already knows, including what other members recorded. Today each researcher sees only their own: `pull_plant_resources` sends rows with `created_by = user` (D-086), `plant_resources_for` also decides what a butterfly may link to, and the phone filters by `createdById` (D-087). This ticket shares those two record types inside a project, read-only for everyone but the creator and admins. (Widened 2026-11-06: butterfly observations and finished visits are shared read-only too, so the map shows other members' sightings and the statistics screen can show whole-project figures; see decisions 6-8.)

Decisions (2026-11-03):
1. **Everything in a project is shared.** No hiding of a record's location.
2. **The creator's name travels with the record.** A read-only `created_by_name` field on the sync serializer and one Drift column. `ProjectMembership` is not synced (D-036), so a member list would need a new endpoint and would miss a former member's records. A renamed user shows the old name until the record next changes.
3. **The phone also checks membership,** because logout keeps local rows: the providers return nothing unless the project is in `UserProfile.projectIds` (from `/auth/me`).
4. **A plant record's photos follow it,** read-only.
5. **A creator can delete or retype a record that another member links to.** Before decision 6 their phone could not see that member's observations; it now can, but a link is still a server-side fact the creator's phone may not have pulled yet, so its "Linked to N" check does not cover them reliably, and a server refusal would surface offline work as a rejected change. D-086 already lets links survive a soft delete, and the linked row on the observation detail already copes with a missing record.
6. **Other members' butterfly observations and their finished visits are pulled read-only** (no track points, no photos, no edit). Needed for the map and for whole-project statistics offline. Visits are limited to `completed`, `synced`, `reviewed` and `locked`; drafts and visits in progress stay private. Overrides the old "observations and visits do not change".
7. **The map shows other members' observations as a different-coloured circle** from the user's own markers. Tap opens a read-only popup with the species, count, time and "Recorded by" name; no Open to the editable detail.
8. **Statistics get a scope switch, "My records" / "Whole project".** The same pure functions (D-100) run on all pulled rows, so the figures follow T061's definitions. The note "Your records only. Project-wide figures are in the admin reports." shows only under "My records". The phone still has no validation data, so taxon is as recorded (D-100 decision 6). Phenology follows the scope too.

- [ ] **Pull:** `pull_plant_resources` and the habitat pull send every row of the project to every member, tombstones included (D-049). The observation pull sends every member's live observations of the project and the visit pull every member's finished visits, tombstones included, without track points or photos (decision 6). Push scope is unchanged: a member can only write their own rows. Existing REST/sync write checks for observations and visits stay own-only.
- [ ] **Old rows arrive:** the Drift migration deletes the `cursor:%` rows, as `from12To13` did. Without it, a phone's cursor is already past other members' existing rows and they never arrive.
- [ ] **See and link:** `plant_resources_for` (and the habitat equivalent) returns every live record of the user's projects. A link must still stay in the observation's project (D-086).
- [ ] **Write scope stays own:** a new scope (own rows, all rows for an admin) replaces `plant_resources_for` in `_plant_or_404` (REST PATCH) and in `build_new_photo`, and the habitat REST uses the same split. Widening without this would let any member PATCH another member's record or add a photo to it, since those two only test visibility. Another member's PATCH stays a 404. The push check (`created_by` or admin) already holds.
- [ ] **Photos:** `pull_photos` also sends the photos of the project's plant records. The content and thumbnail views read through a new scope that includes them. `photos_for` stays as it is for the upload steps, so nobody can finish another member's upload.
- [ ] **Map:** other members' observations are circles in a colour different from the user's own markers, with a legend entry and a layer toggle in the Layers sheet, and a read-only popup naming the recorder (decision 7). The Filters sheet (species, dates) applies to them; the visit filter does not.
- [ ] **Statistics scope:** a "My records / Whole project" switch on the statistics screen runs the existing functions on all pulled rows (decision 8). Shown by hand: with two researchers, whole-project figures equal the admin's Reports → Transect indicators for the same transect and year (allowing for validated taxa); "My records" is unchanged from T062.
- [ ] **Phone lists:** the Plants & habitat list, the species picker's Recent, the link picker and the map show the project's records (`watchProjectPlants` and `watchLinkablePlants` lose the `createdById` filter). Each tile shows who recorded it.
- [ ] **Read-only for others:** another member's record opens with a "Recorded by" line naming the creator, and with no Save, Delete or photo add, using `PlantForm`'s `readOnly`. Admins and the creator keep editing. A butterfly may still link to it. The same applies to habitat features (T054). Other members' observations have no editable detail; the visit and observation detail screens, Sync status and "My visits" keep listing the user's own rows only (filter by `observerId` / `recordedById`).
- [ ] **A visit that is not on this phone:** a shared record's `survey_visit` can point at another member's visit, which is not pulled. Nothing on the phone may fail on it (`visitProvider` gives null; foreign keys are not enforced on the phone).
- [ ] **Shown by hand with two researchers:** A records a plant with a photo; B syncs and sees both (list, map, link picker), links a butterfly, and cannot edit or delete it; a direct PATCH by B is a 404; A edits it and B pulls the change; A deletes it and B's phone drops it, with B's butterfly keeping its row; a third user not in the project sees nothing on the same phone; a phone that synced before the update gets A's older records.
- [ ] **Docs:** a new decision entry amends D-086, D-087 and D-100 (statistics scope). PROJECT_OUTLINE's researcher role ("sees own data") and `mobile/CLAUDE.md`/`backend/CLAUDE.md` follow. T111's hand check (e) no longer holds for other members of the project. Drift snapshot and migration committed.

Technical notes: The pull for observations and visits is the biggest change: today both are filtered by the user (the `_NOT_SYNCED` validation fields stay unsent). Every phone query that assumes all local rows are the user's own (map, My visits, counts, `projectVisitsProvider`, `projectObservationsProvider`, the Unsynced badge, the per-visit observation count) must filter by owner or the others' rows leak into the user's own lists and the T062 own-scope figures; `watchProjectVisits` already filters by `observerId`, observations need the same. Sensitive-species locations are visible to all members by decision 1; if that changes, hide by taxon flag in a later ticket. This comes after T053 and T054, so it changes finished code rather than building habitat features two ways. `created_by_name` must join `SERVER_OWNED_FIELDS` (`sync/services.py`) so it never counts as a merge difference, and the pull needs `select_related("created_by")` to avoid one query per row. `_plantResource` in `core/sync/pull_applier.dart` stores the new column. `plant_resources_for` also feeds the exports dataset (`exports/datasets.py`); exports are admin-only (D-077), so nothing changes there. B linking offline to a record A has since deleted gets the existing "This plant record was not found" rejection on the Sync screen.

If time is short: drop the observations, visits, map and statistics parts (decisions 6-8) and do the 1.5 d plants-and-habitat version first, with plants and habitat without photos, and "Another researcher" in place of a name, which drops the new field and column. The cursor reset still needs a Drift schema step.

Out of scope: Sharing visits that are not finished, track points and observation photos; editing another member's observation; validation data on the phone; Export access for members (it changes D-077; its own ticket if wanted); Hiding a sensitive record from other members. Editing another member's record; Tests (D-021).

### T113 · Admin adds a butterfly observation to a visit, with photos
[#130](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/130) · E06 · added 2026-11-06 as a follow-up to T110 and T111 · P1 · could · labels: `backend`, `admin`, `could` · implements F20 (admin side) · est. 3 d · **done**

Depends on: T043, T110, T111

Why: The butterfly observation page in Django admin has no Add (D-065). T110 lets a researcher add a late observation from the phone, but an admin who works from a paper form or a photo, or for a researcher whose phone is not at hand, cannot. Admin should be able to add an observation to an unlocked visit, under the same rules as the phone and the sync push. It should also be able to attach photos to the observation it adds (and to an existing one), since a paper form or a field photo is often the evidence for the record. The same photo upload is added to plant records, whose admin page (T111) shows photos read-only; habitat features have no photos (T053), so they are not part of this.

- [x] **Add:** the observation admin has an Add button. The form asks for the visit (`raw_id_fields`), the species, count, `observed_at`, the point on a map, section (optional, filled from the point when empty) and the optional details. `recorded_by` is chosen from the members of the visit's project.
- [x] **Unlocked visit only:** a locked, cancelled or draft visit is refused with a form error.
- [x] **Same rules:** the save goes through `save_observation` (V01-V04, V06-V08, as for push), with rule messages on the fields.
- [x] **Zero flag (D-097):** if the visit has `zero_observation_confirmed = true`, the form says so and asks for a tick to clear it; saving clears it in the same save (V06 would refuse otherwise).
- [x] **History:** the change reason is "admin add".
- [x] **Photos (butterfly observations and plant records):** the photos inline on both pages gets an "add photo" row (file field, optional captured-at) and a "make primary" tick. The server computes the SHA-256, size and type from the uploaded bytes and calls the same `store_content` and `complete_upload` as the phone's upload (T049), so the type, magic-byte, size and pixel checks stay in one place; a bad file is a form error. The first photo of a record becomes primary. A photo can be soft-deleted from the inline, never hard-deleted. History reason "admin add photo". On the add page the photos are saved with the new observation. A locked visit refuses every photo change, and the inline is read-only on such a page. Photos for a plant record added in admin work the same way.
- [x] **Effect on phones, shown by hand:** the observation reaches the recording member's phone after a sync and shows in the visit detail, and a photo added in admin shows on the record after the same sync (a soft-deleted photo disappears).
- [x] No new dependency; no migration. A decision entry refines D-065. Docs: `backend/CLAUDE.md`.

Note (2026-11-06): built as D-108; `tmp/t113/verify.py` passed. The recorder must be the visit's researcher (narrower than "a member"); the edit path's check moved to `_post_clean`. The phone check (Effect on phones) was done by the developer.

Out of scope: Habitat feature photos and an admin page for habitat features. Editing the image (rotate, crop) and bulk upload. Unlocking a visit (T043). Tests (D-021).

### T114 · Spatial index benchmark with a larger plant and habitat table
[#131](https://github.com/AleksaMilojkovic17252/butterfly-monitoring/issues/131) · E11 · added 2026-11-07 as a follow-up to T102 · P1 · could · labels: `evaluation`, `database`, `could` · implements F61 (P1 part) · est. 1 d · **todo**

Depends on: T071, T075, T102
Notes: scheduled after the simulation and the Part 1 evaluation run (T075) are finished, so it does not change the data they use. The issue (#131) is created on GitHub by the developer.

Why: T102 (D-111) found no benefit from a `geography` expression index or a `&&` prefilter, but the generator makes the same 14 plant records, 11 habitat features and 26 sections at every scale, so the nearest-host-plant KNN (query 08), Q3 (06) and the habitat side of Q4 (07) were barely stressed. D-111 rule 2 also says that a geography filter as the **first** filter on a large table was never measured. This ticket measures both with the T102 runner.

- [ ] A larger plant and habitat table in a scratch database restored from a backup (T010), never the dev data: for example 100 and 1 000 times the plant records and habitat polygons, by a generator option or a SQL load kept with the benchmark. State which, and that the data is synthetic.
- [ ] The T102 queries 06, 07 and 08 rerun on it with `evaluation/benchmarks/spatial/run.sh`, configs A, B and C (the `gist ((geometry::geography))` index, a `&&` prefilter), median of 10 warm runs and the plan node from `EXPLAIN (ANALYZE, BUFFERS)`.
- [ ] One new query file with a `geography` filter as the first filter on a large table (for example plant records within a radius of a point, no project id first), with its C variants.
- [ ] Results and discussion in `evaluation/results/spatial-indexes-large.md`, compared with `spatial-indexes.md`.
- [ ] Where C clearly wins (at least 2× at the larger size and not slower at the smaller), fix the real code (new migration or service change) and update D-111 (rule 2 especially); otherwise state the size below which no change is needed.

Out of scope: more transects or visits (T102 covered those); general claims (one laptop, synthetic data); tests (D-021).
