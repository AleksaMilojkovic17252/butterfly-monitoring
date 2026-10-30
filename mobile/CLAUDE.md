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
| `lib/core/db/` | `AppDatabase`, one file per Drift table, `app_database.steps.dart` (generated). `butterfly_observations.dart` (T044) is the local observation table, filled by pull and written by the quick entry (T045); `taxon_usages.dart` (T045, local only) holds favourites and recent use; `search_text.dart` builds `taxon.searchText` (lower case, no diacritics); `photos.dart` (T050) is the local photo table: metadata, `localPath` of the file, `uploadStatus`, local-only `uploadError` |
| `lib/core/location/` | geolocator providers; `LocationSource` / `GeolocatorSource` (the foreground-service position stream, T037, with the accuracy as a parameter), the per-device GPS interval override (`gps_interval_override.dart`) and the battery saver's remembered visit id plus the `batteryProvider` (`battery_saver_visit.dart`, T038) |
| `lib/core/validation/` | Input rules (T055), plain Dart, the same rule IDs as `backend/apps/*/rules.py` and `docs/requirements/validation-rules.md`: `observation_rules.dart` (V01-V04, V06-V08, W01-W04), `visit_rules.dart` (V05-V07, V09, W06, W07), `weather_check.dart` (W06), `protocol_window.dart` (W07), `observation_values.dart` and `visit_values.dart` (V07 codelists; nothing in `core/validation` imports from `features/`), `rule_messages.dart` (ID to sentence). Repositories call them before a write and throw a `StateError` with the messages |
| `lib/core/sync/` | Sync API (`SyncApi`), queue rules and push results (`SyncRepository`), pull applier, runner (`SyncRunner`), project download (T031) and triggers (T030); `sync_state` store and status providers (T029); photo upload (T050, D-075): `PhotoApi` (init, PUT, complete) and `PhotoUploader`, which the runner calls after push |
| `lib/features/sync/` | Sync status screen (T032): read queries, providers, error messages, `SyncStatusScreen` at `/projects/:id/sync`; `FailedPhotoCard` lists photos the server refused (T050, D-075) |
| `lib/features/transects/` | Transect list and detail (T033): read-only `TransectRepository`, map (`TransectMap`), `ProtocolSummary` (T033); the season/time-window warnings are in `core/validation`; `confirmProtocolWindow` (`ui/protocol_window_dialog.dart`) is the warning dialog, shared by transect detail and the Start visit tile's draft sheet (T105) |
| `lib/features/visits/` | Visits (T034): the lifecycle table `visit_status.dart` (same as the server's, checked against `docs/requirements/visit-states.json`); `VisitRepository` (reads, plus draft/start writes through `SyncRepository.write`, T035); the start-visit form `StartVisitScreen` at `/projects/:id/transects/:transectId/start` with Beaufort labels (T035); GPS tracking (T037): `TrackingController` follows the visit in progress and buffers fixes into `TrackPointRepository`, `TrackingStatusCard` shows it, `prepareTracking` asks for the permissions before Start; battery saver (T038, D-071): `TrackingController.setBatterySaver`, the automatic switch below 20 % and the toggle in the active visit app bar, plus `GpsGapBanner` ("No GPS fix for N s"); the active visit screen `ActiveVisitScreen` at `/projects/:id/visits/:visitId` (T039): header, map with route and current section (`current_section.dart`), pause/resume (`VisitRepository.pause`/`resume`), keep-screen-on toggle; the Finish screen `FinishVisitScreen` at `.../visits/:visitId/finish` (T040, D-068): `FinishVisitForm` (summary card, `FinishWarnings`, end weather, reason, true-zero checkbox) calls `VisitRepository.finish`, or `cancel` after `CancelVisitSheet` (T041, D-069; the start form's "Not conducted…" uses the same sheet and `recordNotConducted`); pure domain files `visit_pauses.dart` (the `pauses` list), `route_coverage.dart`, `gps_gaps.dart`, `route_stats.dart`, `visit_summary.dart`, `finish_values.dart`, `visit_rule_error.dart`; `temperature_input.dart` and `WindPickerSheet` are shared with the start form; the project home's Start visit tile (T105, D-073): `openStartVisit` in `ui/start_visit_entry.dart` (visit in progress, else drafts, else the transect list by distance) and `StartVisitDraftSheet`, fed by `VisitRepository.projectDrafts`; the read-only visit detail (T106, D-074): `VisitDetailScreen` at `/projects/:id/transects/:transectId/visits/:visitId` (opened from My visits; header, summary, weather, `VisitRouteMap`, `VisitObservationList`), `visit_route_stats.dart` (`visitRouteStatsProvider`, cached `RouteStats` from the local points) and `local_time.dart` (`formatLocalDateTime`, `formatLocalTime`) |
| `lib/features/observations/` | Butterfly observations (T045): `TaxonRepository` (picker taxa, favourites, recent use) and `ObservationRepository` (`createQuick`, `undo`, `watchMissingPhotos`); `taxon_search.dart` (search, recent, favourites in memory); `QuickButterflySheet` opened from Add butterfly on the active visit screen, with `TaxonTile`, `CountStepper` and its dialog; photos (T050, D-075): `PhotoRepository` (the only code that touches photo files and the `photo` table: `capture` shrinks and hashes into a `DraftPhoto`, `addDrafts`, `addToObservation`, `makePrimary`, `delete`), the sheet's Photo/Gallery buttons and `DraftPhotoStrip`, and `ObservationPhotoSection` in the detail; the Finish screen's "Photos missing" tile (W01, never blocks) is in `FinishWarnings`; the read-only observation detail (T106, D-074): `ObservationDetailScreen` at `/projects/:id/observations/:observationId` (`ObservationRepository.watchObservation`, `observationProvider`) |
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
