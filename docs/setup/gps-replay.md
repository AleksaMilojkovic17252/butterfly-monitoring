# GPS replay (T072)

Run a whole visit indoors (demos, evaluation sessions, the coverage check of T100) by feeding the
tracker a GPX track instead of real GPS. Design: D-112.

## Turn it on

1. Use a **debug build** (`flutter run`, or `flutter build apk --debug` and `adb install -r`). The
   setting does not exist in a release build, and a release build ignores a stored one (D-030: there
   are no product flavours, so "dev only" means debug).
2. Settings → **Location source** → **Replay GPX**, then **Replay speed** 1×, 5× or 20×.
3. Start a visit. The change applies from the next start, as the GPS interval does.

## What it does

- Plays the track of the visit's transect (the GPX `<name>` equals the transect code, `FG1`…`FG4`);
  if there is none, the first track.
- The GPX times only set the pace: the wait between points is the GPX gap divided by the speed. The
  simulator's points are 5 s apart, so 1× is one point per 5 s, 5× per second, 20× every 0.25 s. The
  tracker's GPS interval is ignored.
- Every position gets the phone's clock **now** (the GPX dates are in May and would fall outside the
  visit's time window). Accuracy is 5 m, speed and heading come from consecutive points.
- Points are stored with `provider = simulated`, also on the server.
- After the last point it keeps repeating the last point, so the "No GPS fix" banner does not appear
  while you finish the visit.
- Every new stream starts at the first point: pausing and resuming, the battery saver switching, or
  restarting the app all restart the replay from the beginning. This is a known limitation.
- There is **no foreground service and no notification**. Keep the app open and the screen on: Dart
  timers can stall with the screen off.
- Location permission is still asked for, as for real GPS.

## The GPX file

The app plays `mobile/assets/replay/transects.gpx`, a copy of `database/seeds/transects.gpx` (written
by `simulate_season`, T071). If the generator is run again and the file changes, copy it again by hand:

```fish
cp database/seeds/transects.gpx mobile/assets/replay/transects.gpx
```

## Alternative: Android emulator GPX playback

The emulator can play a GPX file itself, so the app stays on **Device GPS** and gets normal fixes
(stored as `fused`, not `simulated`). Checked against the strings of emulator 37.2.12; the menu names
may differ a little in other versions.

1. Start the emulator, open the **Extended controls** (the `…` button on the side bar).
2. **Location** → the **Routes** tab → **Load GPX/KML** → pick `database/seeds/transects.gpx`.
3. Choose the route (one per transect), set the playback speed, press **Play route**.
4. In the app start a visit on the matching transect.

The emulator plays the points at their own pace and does not repeat the last one.
