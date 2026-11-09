# Performance and sync robustness (T074)

**One laptop, one phone, a debug build of the app, simulated data.** The server figures are for django on gunicorn behind nginx on
the developer's laptop; the phone figures are for a debug build and are upper bounds (T059's profile-build marker rebuild was about 92 ms).
Decision: D-115. **The scripts and the debug-only app tooling used for these measurements were deleted after the run, so they cannot be repeated from the repository;** the method is described below.

## Setup

- Date: 2026-11-09 for the server and the phone runs.
- Laptop: Intel Core i5-1235U (12 threads), 32 GB RAM, Docker Compose.
- Server mode: **gunicorn 26.2.0, 2 workers, DEBUG off**, nginx 1.28 on `:8080` (`infrastructure/compose.yaml` alone). Host scripts talk to `http://localhost:8080`, so every figure includes nginx and the loopback.
- PostgreSQL 17.5, PostGIS 3.5.2 (GEOS 3.9.0, PROJ 7.2.1), default configuration, the dev database (about 4,200 observations before the T074 data).
- Bench projects (dev database, deleted after the run): "T074 benchmark" (receives the pushes), "T074 season" (441 observations, 32 visits, 5,789 track points), "T074 map 5k" (5,389 observations, 440 visits, 82,852 track points). 
- Phone: Samsung SM-S921B, Android 17, **debug build**, connected to the laptop over USB (`adb reverse tcp:8080 tcp:8080`, the USB preset), Wi-Fi on. The phone steps were driven over adb (taps and swipes through `uiautomator`), not by hand.

## Server

Raw rows were written to a CSV that is no longer kept; the tables below are its content. Push: each timing is one request with n `butterfly_observation`
creates to a fresh visit (the visit itself is pushed before, untimed), 5 runs per size, all `applied`; the payload follows the simulator's.

| Name | Mutations | Runs | p50 ms | p95 ms | min ms | max ms | Mutations/s (p50) |
|---|--:|--:|--:|--:|--:|--:|--:|
| `push_100` | 100 | 5 | 3076.3 | 3142.1 | 2962.5 | 3117.4 | 33 |
| `push_500` | 500 | 5 | 14366.5 | 16467.1 | 12951.0 | 16298.0 | 35 |
| `push_1000` | 1000 | 5 | 27264.0 | 27543.7 | 26944.9 | 27435.0 | 37 |
| `resend_1000` | 1000 | 1 | 864.7 | 864.7 | 864.7 | 864.7 | 1156 |

The resend of the last 1000-batch came back **all `duplicate`** (no row changed).

**T026 check (500 mutations in under 5 s): not met.** The p50 of the 500-observation push is 14366.5 ms (limit 5000 ms), about 29 ms per observation, linear in n (100: 3.1 s, 1000: 27.3 s).
T026's own smoke run (about 3 s, see TICKETS.md) used temporary handlers, not the real observation handler, so it is not comparable. Where the time goes (the real handler's validation, section assignment, flags, history and stored result) was not profiled in T074.
Whether this needs a follow-up ticket is the developer's decision.

Pull (the "T074 season" project, cursor 0). The pull scope of that project holds 844 rows in total, so the `limit 1000` page is not full and the full pull is one page.

| Name | Rows returned | Runs | p50 ms | p95 ms | min ms | max ms | Rows/s |
|---|--:|--:|--:|--:|--:|--:|--:|
| `pull_limit_100` | 100 | 5 | 106.2 | 237.2 | 97.8 | 184.7 | 942 |
| `pull_limit_500` | 500 | 5 | 420.7 | 428.6 | 400.4 | 426.5 | 1189 |
| `pull_limit_1000` | 844 | 5 | 761.0 | 781.3 | 725.0 | 774.1 | 1109 |
| `pull_full_1000` | 844 | 1 | 899.3 | 899.3 | 899.3 | 899.3 | 938 |

Latency of read endpoints (the "T074 season" project, one warm client, 3 warm-up and 30 timed requests; `auth_login` 10 timed) and OGC items (personal token, through nginx `auth_request`; `ogc_observations_*` read the whole database, not one project):

| Request | Group | p50 ms | p95 ms | min ms | max ms |
|---|---|--:|--:|--:|--:|
| `projects` | endpoint | 37.9 | 46.3 | 33.3 | 46.4 |
| `projects_detail` | endpoint | 23.6 | 26.8 | 18.9 | 27.5 |
| `project_transects` | endpoint | 34.0 | 38.0 | 28.6 | 38.3 |
| `transect_visits` | endpoint | 25.3 | 33.7 | 22.4 | 36.8 |
| `offline_package` | endpoint | 700.4 | 730.2 | 637.6 | 731.4 |
| `sync_pull_1000` | endpoint | 704.2 | 727.0 | 596.3 | 732.4 |
| `auth_login` | endpoint | 240.0 | 250.5 | 233.2 | 249.6 |
| `ogc_observations_100` | ogc | 35.4 | 313.3 | 32.6 | 330.3 |
| `ogc_observations_100_bbox` | ogc | 50.7 | 61.7 | 48.8 | 68.1 |
| `ogc_observations_1000` | ogc | 380.8 | 422.7 | 367.7 | 422.9 |
| `ogc_transects` | ogc | 12.0 | 41.4 | 9.8 | 48.4 |
| `ogc_observation_hexgrid` | ogc | 1324.9 | 1366.8 | 1281.0 | 1372.1 |

Exports are admin-only and are not timed.

## App

The figures come from the T073 event export of the session (`tmp/t074/export.csv`, not committed). **Debug build**, so every figure is an upper bound.

| Measure | Result |
|---|---|
| Drift insert of 1000 observations (on a copy of the DB, through `ObservationRepository.createFree`) | 14.2 s in total, median 14.9 ms, p95 21.7 ms per insert |
| Map with 5,389 own observations ("T074 map 5k"), time from opening the map to the first frame that has markers | 460 ms, 272 ms, 250 ms (three opens; the first is the slowest) |
| Frame build time while panning and zooming for about 20 s (median build / median raster) | 4.7 / 1.4 ms, 4.6 / 1.8 ms, 4.4 / 1.9 ms (about 870 frames per run) |
| Frames with a total time above 16 ms | 35, 12 and 9 of about 870 (4.0 %, 1.4 %, 1.0 %); p95 of the total frame time 14.4, 11.5 and 11.0 ms |
| Photo upload throughput over Tailscale | **Not measured** (skipped at the developer's request) |

Local database size (`butterfly.sqlite`, no WAL at the time):

| Moment | File size | Observations | Visits | Plants | Habitats |
|---|--:|--:|--:|--:|--:|
| before pull | 3,366,912 B | 1,981 | 183 | 38 | 25 |
| after "T074 season" (441 observations, 32 visits) | 3,366,912 B | 2,422 | 215 | 52 | 36 |
| after "T074 map 5k" (5,389 observations, 440 visits) | 5,660,672 B | 7,811 | 655 | 66 | 47 |

- The pulled season did not change the file size: SQLite reused free pages left by earlier deleted data, so the size grows in steps, not per row. The map project grew it by 2.29 MB for 5,389 observations, 440 visits and the plant and habitat records (about 0.4 KB per observation with its share of the rest).
- Track points are not pulled (4,485 before and after); they exist only on the phone that walked.
- The map's "markers shown" time is the time to the first frame with the clustered markers, not until the last tile is drawn. Panning and zooming were scripted (swipes and double taps through adb), not done by hand.
- The 1000-insert figure includes the validation, the queue row and the transaction. The copy's database is opened on a background isolate, like the real one.

## Sync robustness

| Test | MVP criterion | Method | Expected | Result |
|---|---|---|---|---|
| Resend of the same batch | 9 | a script: 200 observations pushed, then the identical batch again | all `duplicate`, observation and `sync_mutation` counts unchanged | **PASS** (2026-11-09: 200 and 200 rows before and after) |
| Kill the app mid-visit | 7 | force-stop with 10 observations, reopen, finish, sync | 10 observations on phone and server; at most the track-point flush buffer lost | **PASS**: after the kill the phone had all 10 observations and the app showed "Tracking interrupted 16:45–16:45" and resumed the visit; after finishing and syncing, phone and server both had 10 observations and 192 track points, status `synced`, queue empty. The largest gap between track points was 12 s |
| Push response lost | 8 | Sync fault "Drop next push response", then sync again | error, queue kept; retry succeeds; server +5 exactly; queue empty | **PASS**: the app said "Sync did not finish. Changes stay on this phone." and kept its 9 queued items. The server had already applied the push (visit, 5 observations). The retry answered 200 and the server still had exactly 5 observations; after finishing the visit and a last sync the queue was empty and the counts matched (see the note on the first attempt below) |
| Push not sent | 8 | "Fail next push" | the same | **PASS**: with 5 more observations added (10 on the phone) the failed sync left the server at 5; the retry brought it to exactly 10, no duplicates |
| Airplane mode during a sync (manual) | 8 | manual, on the phone | sync resumes by itself; counts match, no duplicates | **Not run.** Over the USB route used here, airplane mode does not cut the traffic (`adb reverse` is not the radio), so it would test nothing; it needs the phone on Wi-Fi or Tailscale. Left for the developer |
| 50+ observations survive a restart | 4 | 55 observations, force-stop, reopen, sync | 55 on phone and server | **PASS**: 55 observations on the phone after the force-stop and reopen ("Tracking interrupted 17:02–17:03"); 55 on the server; after finishing and syncing both had 55 observations and 315 track points, queue empty |

Notes on the robustness runs:

- **The first drop attempt was not a valid test.** The phone's access token had expired (15 minutes idle), so the push that the fault dropped was answered `401 Unauthorized`: the server applied nothing, and dropping that answer meant the app's own refresh-and-retry never ran. The fault sits below the auth interceptor, so it takes the first request after arming whatever it is. The server log shows the `401` with no token refresh after it (at the 15:32 sync the normal sequence was `401`, `auth/refresh`, `200`). The run above is the second attempt, after a pull had refreshed the token; the log shows `200` for the dropped push and `200` for the retry.
- After the two kills the largest gaps between track points were 12 s and 11 s (a few points around the kill; none over 30 s). The app also syncs when it is reopened, so the queue was already empty when checked after the reopen in the 55-observation run; the 55 observations were in the phone's database either way.

## Battery

**Not measured in T074; deferred to a follow-up ticket.** The planned method: two 60-minute screen-off runs at a 5 s and a 15 s GPS interval with the same accuracy, measured with `adb shell dumpsys batterystats` and `dumpsys battery`.

## Checks deferred from earlier tickets

- **T026** (500-mutation push under 5 s): measured above, **not met** (14366.5 ms p50 on gunicorn).
- **T037** (60 minutes at 5 s with the screen off gives about 720 points, no gap over 30 s): **deferred again**, with the battery runs.
- **T059** (5,000 markers render and pan smoothly): **met on the debug build**: 5,389 markers, first frame with markers in 250–460 ms, p95 frame time 11–14 ms, 1–4 % of frames over 16 ms, while panning and zooming for about 20 s (three runs). A profile or release build would be faster.

## Limits

- One laptop and one phone, so the results are specific to them. The phone is a Samsung SM-S921B on Android 17; a different phone or battery gives different figures.
- Phone figures come from a debug build (Flutter's debug mode is slower than release): read them as upper bounds.
- The data is simulated; the push payloads are close to the phone's but have no photos or plant records.
- The server run is one session on a laptop that was also running the other containers of the stack; it was not repeated on another day.
- Exports (admin-only) were not timed. The photo upload throughput over Tailscale was not measured at all (skipped at the developer's request), so that criterion of T074 is open. The airplane-mode run is not done.
- The phone steps ran over USB (`adb reverse`), not over the radio: the sync and download timings in the export are loopback figures and say nothing about a field connection.
- Skipped under D-021: `pytest-benchmark`, integration-test timings, and an automated "scripted" fault test. The throwaway script and debug tooling used instead were deleted after the run (D-115).
