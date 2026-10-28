# Offline checklist

A manual script for T031: after a project is downloaded, every screen a visit needs must work
in airplane mode. Each ticket that adds one of these screens runs its step and fills in the
result column. No automated test covers this (D-021).

## Setup

1. Stack up, demo data seeded (`docs/setup/seed-data.md`).
2. Phone on USB (`adb reverse tcp:8080 tcp:8080`, **USB** preset) or on Tailscale.
3. Log in as the demo researcher.
4. On the project list, tap **Download** on the demo project. Wait until the card shows
   **Ready** and the transect count.
5. Switch **airplane mode on** (Wi-Fi off too), force-stop the app and open it again.

## Steps

| # | Step | Expected result | Screen added by | Result / date |
|---|---|---|---|---|
| 1 | Open the app | It opens without a login screen (offline start) | T012 | Passed, 2026-10-26 |
| 2 | Look at the project list | The demo project shows its transect count and **Ready** | T017, T031 | Passed, 2026-10-26 |
| 3 | Open the project | Project home opens with all its tiles | T017 | Passed, 2026-10-26 |
| 4 | Open Settings | Settings opens (server URL, sync tile) | T006 | Passed, 2026-10-26 |
| 5 | Open the transect list, then one transect | The list has the downloaded transects; the detail shows the protocol summary | T033 | Passed with the server unreachable (`adb reverse` removed, app force-stopped and reopened), 2026-10-26; not yet repeated in airplane mode |
| 6 | Start a visit | The form opens with the weather fields; the taxon list is loaded | T035 | not built yet |
| 7 | Run an active visit | The GPS track records and the visit stays open | T037, T039 | Active visit screen passed with the server unreachable (`adb reverse` removed, app force-stopped and reopened): header, paused banner, map from cached tiles, keep-screen-on toggle, 2026-10-28; GPS recording was run in T037; not yet repeated in airplane mode |
| 8 | Add a butterfly | The quick entry works with the taxon picker | T045 | Passed with the server unreachable (`adb reverse` removed, app force-stopped and reopened): search, save, the row and queue item stay on the phone; with the server back the next sync pushed it, 2026-10-28; not yet repeated in airplane mode |
| 9 | Finish a visit | The summary shows; the true-zero and cancel reasons are offered | T040, T041 | built; the airplane-mode run (finish, cancel with butterflies, not conducted) is for the developer to fill in |
| 10 | Airplane mode off | The next sync pushes everything and the unsynced count goes to 0 | T030, T034+ | not built yet |
