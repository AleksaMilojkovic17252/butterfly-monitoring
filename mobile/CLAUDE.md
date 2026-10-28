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
flutter test                                       # the existing tests in test/ (incl. visit_status_test, D-058); add none (D-021)
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
| `lib/core/config/` | Server URL presets and notifier, `SharedPreferences` provider |
| `lib/core/http/` | dio instance and the JWT auth interceptor |
| `lib/core/db/` | `AppDatabase`, one file per Drift table, `app_database.steps.dart` (generated) |
| `lib/core/location/` | geolocator providers; `LocationSource` / `GeolocatorSource` (the foreground-service position stream, T037) and the per-device GPS interval override (`gps_interval_override.dart`) |
| `lib/core/sync/` | Sync API (`SyncApi`), queue rules and push results (`SyncRepository`), pull applier, runner (`SyncRunner`), project download (T031) and triggers (T030); `sync_state` store and status providers (T029) |
| `lib/features/sync/` | Sync status screen (T032): read queries, providers, error messages, `SyncStatusScreen` at `/projects/:id/sync` |
| `lib/features/transects/` | Transect list and detail (T033): read-only `TransectRepository`, map (`TransectMap`), `ProtocolSummary` and the season/time-window warnings (reused by T035) |
| `lib/features/visits/` | Visits (T034): the lifecycle table `visit_status.dart` (same as the server's, checked against `docs/requirements/visit-states.json`); `VisitRepository` (reads, plus draft/start writes through `SyncRepository.write`, T035); the start-visit form `StartVisitScreen` at `/projects/:id/transects/:transectId/start` with the weather check `weather_check.dart` and Beaufort labels (T035); GPS tracking (T037): `TrackingController` follows the visit in progress and buffers fixes into `TrackPointRepository`, `TrackingStatusCard` shows it, `prepareTracking` asks for the permissions before Start; the active visit screen `ActiveVisitScreen` at `/projects/:id/visits/:visitId` (T039): header, map with route and current section (`current_section.dart`), pause/resume (`VisitRepository.pause`/`resume`), keep-screen-on toggle |
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
