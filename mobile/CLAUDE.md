# mobile/CLAUDE.md

Flutter app, Android only. Offline-first: screens read the local Drift database, and sync moves
data to and from the server. Rules for the whole repo are in the root [CLAUDE.md](../CLAUDE.md);
Drift column rules are in [docs/CONVENTIONS.md](../docs/CONVENTIONS.md) A.6.

## Claude writes, the developer reviews

The developer is learning Flutter. Claude may implement mobile tickets, but the code is for the
developer to read and change:

- Write simple, readable Dart that matches the surrounding code. Comment the non-obvious parts
  (a `///` doc comment on each class and public method, as in the existing files).
- Prefer plain, explicit code over clever abstractions or new helper layers.
- Stop after implementing and hand over for review: summarise what each file does and where to
  start reading. Wait for the developer's edits before committing; they may rework the code.
- Explain a Flutter/Riverpod/Dart concept when the developer asks.

## Commands (run in `mobile/`)

```bash
flutter pub get
dart run build_runner build                        # Drift codegen (the old --delete-conflicting-outputs flag is gone)
dart run drift_dev make-migrations                 # after any Drift schema change
flutter test                                       # tests in test/: visit_status_test (D-058) and the validation rules (T055: test/validation, sync_error_message_test); add no others (D-021)
dart format .
flutter analyze                                    # must be clean
flutter run                                        # on the phone over USB
flutter build apk --debug
```

The phone reaches the stack through nginx `:8080`: over USB run `adb reverse tcp:8080 tcp:8080` and
pick the **USB** preset, or use the **Tailscale** preset (`lib/core/config/server_preset.dart`). The
server URL is chosen in Settings.

## Layout

| Path | What |
|---|---|
| `lib/main.dart`, `lib/app.dart` | Entry point, `ProviderScope`, `MaterialApp.router` |
| `lib/core/router.dart` | go_router routes (`routerProvider`) |
| `lib/core/config/` | Server URL presets and notifier, `SharedPreferences` provider, the "Upload photos on Wi-Fi only" setting (`photo_wifi_only.dart`, T050) |
| `lib/core/http/` | dio instance and the JWT auth interceptor |
| `lib/core/db/` | `AppDatabase`, one file per Drift table, `app_database.steps.dart` (generated). `butterfly_observations.dart` (T044) is the local observation table, filled by pull and written by the quick entry (T045); `taxon_usages.dart` (T045, local only) holds favourites and recent use; `search_text.dart` builds `taxon.searchText` (lower case, no diacritics); `photos.dart` (T050) is the local photo table: metadata, `localPath` of the file, `uploadStatus`, local-only `uploadError`, and (T052) `plantResourceId` for a plant record's photo; `plant_resource_observations.dart` (T052) is the plant record table, named `plant_resource_observation` like its entity type; `habitat_features.dart` (T054) is the habitat feature table, named `habitat_feature` (schema 14, `from13To14` also resets the pull cursors); schema 15 (T104) adds `project_protocol.time_zone` and stores season dates as UTC midnight (`from14To15` also resets the pull cursors); schema 16 (T108, D-098) adds `transect_proposals.dart` (synced, `transect_proposal`) and the local-only `route_recordings.dart` and `route_recording_points.dart` (`from15To16` also resets the pull cursors) |
| `lib/core/geo/` | `polygon_math.dart` (T052): `polygonAreaM2`, `polygonCentroid`, `lineLengthM`, `formatArea`, `polygonSelfIntersects` (agrees with PostGIS `ST_IsValid`, D-087), `chainSelfIntersects` and `parseGeometry`; pure Dart on `latlong2`, nothing from `features/` |
| `lib/core/location/` | geolocator providers; `LocationSource` / `GeolocatorSource` (the foreground-service position stream, T037, with the accuracy as a parameter), the per-device GPS interval override (`gps_interval_override.dart`) and the battery saver's remembered visit id plus the `batteryProvider` (`battery_saver_visit.dart`, T038); `compass_heading.dart` (T046): `compassHeadingProvider`, the phone's heading in whole degrees, used by the flight direction dial; `location_message.dart` (`locationMessage`, the sentence for a `LocationFailure`) and `usable_fix.dart` (T108: `isUsableAccuracy`, the D-060 rule on a number) and `walk_positions.dart` (T052, `walkPositionsProvider`: a 1 s stream for Polygon (walk) away from a tracked visit; during a visit the tracker's fixes are used instead, D-087) |
| `lib/core/validation/` | Input rules (T055), plain Dart, the same rule IDs as `backend/apps/*/rules.py` and `docs/requirements/validation-rules.md`: `observation_rules.dart` (V01-V04, V06-V08, W01-W04), `visit_rules.dart` (V05-V07, V09, W06, W07), `weather_check.dart` (W06), `protocol_window.dart` (W07; reads the protocol's time zone, T104, D-094), `observation_values.dart` and `visit_values.dart` (V07 codelists; nothing in `core/validation` imports from `features/`), `plant_rules.dart` and `plant_values.dart` (T052: V02, V07, V08 of a plant record, `plantNotesMissing`), `habitat_rules.dart` and `habitat_values.dart` (T054: V02, V07, V08 of a habitat feature with a Point, LineString or Polygon, `vegetationHeightProblem`), `proposal_rules.dart` and `proposal_values.dart` (T108: V02, V07, V08 of a route proposal; a self-crossing line is valid), `rule_messages.dart` (ID to sentence). Repositories call them before a write and throw a `StateError` with the messages |
| `lib/core/sync/` | Sync API (`SyncApi`), queue rules and push results (`SyncRepository`), pull applier, runner (`SyncRunner`), project download (T031) and triggers (T030); `sync_state` store and status providers (T029); photo upload (T050, D-075): `PhotoApi` (init, PUT, complete; and the thumbnail and content downloads, T107) and `PhotoUploader`, which the runner calls after push |
| `lib/features/sync/` | Sync status screen (T032): read queries, providers, error messages, `SyncStatusScreen` at `/projects/:id/sync`; `FailedPhotoCard` lists photos the server refused (T050, D-075) |
| `lib/features/transects/` | Transect list and detail (T033): read-only `TransectRepository`, map (`TransectMap`), `ProtocolSummary` (T033); the season/time-window warnings are in `core/validation`; `confirmProtocolWindow` (`ui/protocol_window_dialog.dart`) is the warning dialog, shared by transect detail and the Start visit tile's draft sheet (T105); route proposal entry points (T108): the list's app bar menu (Propose a route, Draw a route on map, My proposals), a "Route recording in progress" card, and Propose a replacement on the detail, all off while a visit runs |
| `lib/features/visits/` | Visits (T034): the lifecycle table `visit_status.dart` (same as the server's, checked against `docs/requirements/visit-states.json`); `VisitRepository` (reads, plus draft/start writes through `SyncRepository.write`, T035); the start-visit form `StartVisitScreen` at `/projects/:id/transects/:transectId/start` with Beaufort labels (T035); GPS tracking (T037): `TrackingController` follows the visit in progress and buffers fixes into `TrackPointRepository`, `TrackingStatusCard` shows it, `prepareTracking` asks for the permissions before Start; battery saver (T038, D-071): `TrackingController.setBatterySaver`, the automatic switch below 20 % and the toggle in the active visit app bar, plus `GpsGapBanner` ("No GPS fix for N s"); the active visit screen `ActiveVisitScreen` at `/projects/:id/visits/:visitId` (T039): header, map with route and current section (`current_section.dart`), pause/resume (`VisitRepository.pause`/`resume`), keep-screen-on toggle; the Finish screen `FinishVisitScreen` at `.../visits/:visitId/finish` (T040, D-068): `FinishVisitForm` (summary card, `FinishWarnings`, end weather, reason, true-zero checkbox) calls `VisitRepository.finish`, or `cancel` after `CancelVisitSheet` (T041, D-069; the start form's "Not conducted…" uses the same sheet and `recordNotConducted`); pure domain files `visit_pauses.dart` (the `pauses` list), `route_coverage.dart`, `gps_gaps.dart`, `route_stats.dart`, `visit_summary.dart`, `finish_values.dart`, `visit_rule_error.dart`; `temperature_input.dart` and `WindPickerSheet` are shared with the start form; the project home's Start visit tile (T105, D-073): `openStartVisit` in `ui/start_visit_entry.dart` (visit in progress, else drafts, else the transect list by distance) and `StartVisitDraftSheet`, fed by `VisitRepository.projectDrafts`; the read-only visit detail (T106, D-074): `VisitDetailScreen` at `/projects/:id/transects/:transectId/visits/:visitId` (opened from My visits; header, summary, weather, `VisitRouteMap`, `VisitObservationList`; T110: an Add observation button under the Observations title for the user's own completed, synced or reviewed visit, and "added after the visit" on rows created after `ended_at`), `visit_route_stats.dart` (`visitRouteStatsProvider`, cached `RouteStats` from the local points) and `local_time.dart` (`formatLocalDateTime`, `formatLocalTime`) |
| `lib/features/observations/` | Butterfly observations (T045): `TaxonRepository` (picker taxa, favourites, recent use) and `ObservationRepository` (`createQuick`, `createAfterVisit` (T110, D-097: a finished visit, a picked time, clears the true-zero flag in the same transaction), `createFree` (T047, D-096: no visit, no section, source `incidental`, `larval_search` or `host_plant_search`), `updateObservation` (T046), `undo`, `watchMissingPhotos`); `taxon_search.dart` (search, recent, favourites in memory); `QuickButterflySheet` opened from Add butterfly on the active visit screen (`show`), from a finished visit's Add observation button by `QuickButterflySheet.showAfterVisit` through `openAfterVisitObservation` (`ui/after_visit_entry.dart`, T110: a full screen with a time row and Place on map) or, with no visit, by `QuickButterflySheet.showFree` (a full screen, not a sheet) through `openFreeObservation` (`ui/free_observation_entry.dart`, T047: the Free observation tile and the map long press, with a source picker and Place on map), with `TaxonPicker` (search and lists), `TaxonTile`, `CountStepper` and its dialog; extended entry (T046): `ObservationDetails` and `flight_direction.dart` (domain), `ObservationDetailsForm` (the Details form, with the W03/W04 prompts), `FlightDirectionDial` (a `CustomPaint` dial opened in a dialog), `showPhotoPromptDialog` and `EditObservationSheet` (the Edit button of the detail); photos (T050, D-075): `PhotoRepository` (the only code that touches photo files and the `photo` table: `capture` shrinks and hashes into a `DraftPhoto`, `addDrafts`, `addToParent`, `makePrimary`, `delete`; a photo belongs to a `PhotoParent`, an observation or a plant record, T052), the sheet's Photo/Gallery buttons and `DraftPhotoStrip`, and `RecordPhotoSection` (observation detail and plant form); photos not on this phone (T107, D-083): `PhotoPreview` (domain), `PhotoRepository.preview`/`fullImage` (own file, else the thumbnail in `<documents>/photo_cache/`, else the server), `PhotoPreviewImage` (also in the map popup) and `showPhotoViewer` (every photo opens it: full screen, zoom, star and delete; own file or full image from the server); the Finish screen's "Photos missing" tile (W01, never blocks) is in `FinishWarnings`; the read-only observation detail (T106, D-074): `ObservationDetailScreen` at `/projects/:id/observations/:observationId` (`ObservationRepository.watchObservation`, `observationProvider`) |
| `lib/features/resources/` | Plant records (T052, D-087) and habitat features (T054, D-089); the backend app has the same name: `PlantRepository` (create, update against the opened row, delete refused while linked), domain `captured_geometry.dart` (`GeometryMode`, `CapturedGeometry`), `plant_input.dart`, `plant_links.dart` (host/nectar roles, same lists as the server), `plant_taxon_search.dart`; `GeometryCaptureWidget` (point, polygon by tap or walk, line; shared with T054) opened full screen by `showGeometryCapture`; `PlantEntryScreen` (new at `/projects/:id/plants/new?visit=`, edit at `/projects/:id/plants/:plantId`) with `PlantForm`; `PlantsHabitatScreen` at `/projects/:id/plants`; `PlantLinkTile` and `PlantLinkSheet` (the host and nectar links of a butterfly observation); habitat features (T054): `HabitatRepository` (create, update against the opened row, delete; providers `habitatFeaturesProvider`, `habitatTypesProvider` and `managementTypesProvider`, which read every codelist row), domain `habitat_input.dart` (one `copyWith` with `ValueGetter`s) and `habitat_names.dart`, `HabitatEntryScreen` (new at `/projects/:id/habitats/new?visit=`, edit at `.../habitats/:habitatId`) with `HabitatForm`, `CoverField` (Record / Clear, 0 % is not "not recorded") and `HabitatFeatureTile`; `PlantsHabitatScreen` has the All / Plants / Habitat chips |
| `lib/features/proposals/` | Route proposals (T108, D-098): `RouteRecordingRepository` (the only code that touches the local `route_recording` tables: start, pause, resume, addPoints, discard) and `ProposalRepository` (`createFromRecording` builds the line from the usable fixes and queues the create; `myProposalsProvider`); `RouteRecorder` (domain, kept alive from `app.dart`: follows the open recording, one GPS stream, resumes after a kill), `recording_stats.dart` (`usableLineFixes`, `recordingLengthM`, `recordingTime`); `RecordRouteScreen` at `/projects/:id/proposals/record?replaces=` (header, `ProposalMap`, Pause/Resume, Free observation, Finish into `ProposalDetailsSheet`, Discard) and `MyProposalsScreen` at `/projects/:id/proposals` with `ProposalTile`; Draw on map (`openDrawProposal` in `ui/draw_proposal_entry.dart`: line mode of `showGeometryCapture`, then `ProposalRepository.createFromDrawing`, no GPS) |
| `lib/features/map/` | Project map (T059, D-081): `ProjectMapScreen` at `/projects/:id/map` with a Layers and a Filters sheet; domain `map_filter.dart` (`MapFilter`, `mapFilterProvider`, `effectiveMapFilterProvider`, `filteredObservationsProvider`), `map_layers.dart` (`MapLayer`, `mapLayersProvider`), `map_taxa.dart` (`projectTaxaProvider`); `ProjectMapView` (clustered markers with a memo, line taps, a long press that starts a free observation (T047), and the Plants layer: green markers and patches, T052, and the Habitats layer: brown markers, lines and areas, T054; plants and habitats share one polygon layer and its hit notifier), `map_popups.dart` and `MapFeatureDialog` (the centered popup with Open and an observation's photo). Reads Drift only |
| `lib/features/<feature>/data` | Repositories: the only code that reads/writes Drift and calls the API |
| `lib/features/<feature>/domain` | Plain models and notifiers/controllers |
| `lib/features/<feature>/ui` | Screens (what the router opens) and non-widget UI helpers |
| `lib/features/<feature>/ui/widgets` | Every other widget, one public widget per file named after it (D-064) |
| `drift_schemas/` | Committed schema snapshots used by `make-migrations` |

## Riverpod

- Plain Riverpod 3 providers declared by hand, **no `riverpod_generator` / `@riverpod`**. Each
  provider is a top-level `final xProvider = ...` in the file of the thing it provides.
- `Provider` for services and repositories, `NotifierProvider` for small mutable state,
  `StreamProvider` (and `.family`) for live Drift queries, `FutureProvider` for one-off loads.
- Tests and the widget test override providers (e.g. `appDatabaseProvider`) rather than using
  globals.

## Drift

- One table per file in `lib/core/db/`, listed in `@DriftDatabase(tables: [...])` in
  `app_database.dart`. `build.yaml` sets `store_date_time_values_as_text: true` and the schema dir.
- **Changing a table:** edit the table, bump `schemaVersion`, run `build_runner build`, then
  `make-migrations`, then add the `fromNToM` step in `migration` (`stepByStep`). Commit the new
  `drift_schemas/` snapshot and the regenerated `app_database.steps.dart`.
- Same column names as the server (camelCase in Dart), `TextColumn id` holding the UUID, GeoJSON
  text geometry plus `lat`/`lon` for points, local `serverVersion`/`syncStatus`/`deletedAt` on
  synced tables. Queries filter out `deletedAt` rows.
- UI never writes synced tables directly; it goes through the feature's repository class.
  Reference tables (catalogues, transects, projects) are written only by pull.
- Times are UTC in the database; convert to local time only in the UI.
