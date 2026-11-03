# Input validation rules

Written for T055 from outline §13.1. Each rule has an ID. The server (Django) and the app (Dart) both
implement it and name the ID in a comment, and each rule has a test on each side.

- **Hard rules (V01–V08)** reject on the server and block the save in the app.
- **Warnings (W01–W04, W06, W07)** never reject. The record is saved, and the app shows the warning.
- **The server is authoritative.** The app repeats the rules only to answer straight away, offline.
- **Error shape.** A hard rule comes back as
  `{"code": "validation_error", "detail": "Validation failed.", "fields": {"<field>": ["V04"]}}`. The
  message is the rule ID. The app maps IDs to sentences (`lib/core/validation/rule_messages.dart`).
- **W05** (species outside its known range) is out of scope: there is no distribution data.

Server code: `backend/apps/observations/rules.py`, `backend/apps/surveys/rules.py` and, for plant records
(T051) and habitat features (T053), `backend/apps/resources/rules.py`. The hard rules are called from
`save_observation`, `save_visit`, `save_plant_resource` and `save_habitat_feature`, so REST, push and admin are all covered. The warning
functions (`observation_warnings`, `visit_warnings`) are not called by the services: warnings are not stored
on the server, except W01, which sets `validation_status` on create (`photo_missing`). App code:
`mobile/lib/core/validation/`.

## Rules

| ID | Level | Entity | Rule | Field(s) reported | Server function | App function | Where the app shows it |
|---|---|---|---|---|---|---|---|
| V01 | hard | observation | `count` ≥ 1 | `count` | `observations.rules._v01_count` | `observation_rules.dart` `_v01Count` | quick entry sheet (error text) |
| V02 | hard | observation, plant record, habitat feature | `observed_at` and `geometry` are both present | `observed_at`, `geometry` | `observations.rules._v02_required`, `resources.rules._v02_required` | `_v02Required` (plant records: `plant_rules.dart`, T052) | quick entry sheet |
| V03 | hard | observation | a `source = transect` observation is on a visit in `in_progress`, `completed`, `synced` or `reviewed`, or on a `cancelled` visit that was started (`started_at` is set); never `draft`, `locked`, or a `cancelled` visit that was never started | `survey_visit` | `observations.rules._v03_visit_status` | `_v03VisitStatus` | quick entry sheet; sync screen for a rejected item |
| V04 | hard | observation | `observed_at` is in `[started_at − tol, ended_at + tol]` of its visit; with no `ended_at` only the lower bound applies; `tol` = `observation_time_tolerance_min` | `observed_at` | `observations.rules._v04_observed_at` | `_v04ObservedAt` | quick entry sheet |
| V05 | hard | visit | in status `completed`, `synced`, `reviewed` or `locked`: start and end temperature, wind and cloud are all set, or `weather_missing_reason` is not blank | each missing weather field | `surveys.rules._v05_weather` | `visit_rules.dart` `_v05Weather` | visit write (finish form from T040) |
| V06 | hard | visit and observation | true-zero consistency, see below | visit: `zero_observation_confirmed`; observation: `survey_visit` | `surveys.rules._v06_visit`, `observations.rules._v06_observation` | `_v06Visit`, `_v06Observation` | quick entry sheet; finish (T040/T041) |
| V07 | hard | observation, visit, plant record, habitat feature | the value is in the codelist | the field | `observations.rules._v07_choices`, `surveys.rules._v07_choices`, `resources.rules._v07_choices` | `_v07Choices` (plant records: `plant_rules.dart`, T052) | any write |
| V08 | hard | observation, plant record, habitat feature | `geometry` is a non-empty, valid Point with longitude −180..180 and latitude −90..90; for a plant record a Point or a Polygon, for a habitat feature a Point, a LineString or a Polygon, two-dimensional, all of it inside those limits | `geometry` | `observations.rules._v08_geometry`, `resources.rules._v08_geometry` | `_v08Geometry` (plant records: `plant_rules.dart`, T052; the ring test is `polygonSelfIntersects`) | quick entry sheet |
| V09 | hard | visit | in status `cancelled`: `cancel_reason = not_conducted` exactly when `started_at` is empty | `cancel_reason` | `surveys.rules._v09_cancel_reason` | `visit_rules.dart` `_v09CancelReason` | cancel sheet (Finish screen), "Not conducted…" on the start form |
| W01 | warning | observation | the taxon has `photo_required` and the observation has no photo: `validation_status = pending` | – | `observations.rules.photo_missing` | `photoMissing` | line above Save in the quick entry sheet |
| W02 | warning | observation | `location_accuracy_m` > `gps_accuracy_warning_m` | – | `observations.rules._w02_poor_accuracy` | `isPoorAccuracy` | position line in the quick entry sheet |
| W03 | warning | observation | `oviposition` in `behaviour` and no host-plant link | – | `observations.rules._w03_oviposition` | `w03Applies` | prompt in the Details form of the entry and edit sheets (T046); gone once a host plant is linked (T052) |
| W04 | warning | observation | `life_stage = larva` and no host-plant link | – | `observations.rules._w04_larva` | `w04Applies` | prompt in the Details form of the entry and edit sheets (T046); gone once a host plant is linked (T052) |
| W06 | warning | visit | weather outside the protocol thresholds (protocol.md §3), at the start, and at the end if the end weather is recorded | – | `surveys.rules._w06_weather` | `failedWeatherThresholds` (`weather_check.dart`) | start-visit form, finish form |
| W07 | warning | visit | `started_at` is outside the season or outside the daily time window | – | `surveys.rules._w07_outside_window` | `seasonWarning`, `timeWindowWarning` (`protocol_window.dart`) | start-visit form, transect detail |

### Notes

- **V03.** A locked visit already answers `visit_locked` before this rule runs. `synced` and `reviewed`
  count as "completed" seen from the server: a phone that pushes after the visit moved on must still be
  accepted. The app's quick entry stays in-progress only (D-066). T041: a `cancelled` visit that was started
  also accepts them, because an aborted visit keeps its butterflies. A visit aborted offline reaches the
  server as one coalesced create with `status = cancelled`, ahead of its observation creates (D-051), so
  without this the observations would be rejected. A visit that was never started (`not_conducted`) takes none.
- **V04.** `observed_at` and the visit times are both the phone's clock, so no clock difference is involved.
- **V05.** Reported once per missing field, e.g. `{"temperature_end_c": ["V05"], "wind_beaufort_end": ["V05"]}`.
- **V06.** Two directions:
  - *Confirmed zero but has observations.* The server rejects a visit with `zero_observation_confirmed = true`
    that has live `source = transect` observations (field `zero_observation_confirmed`), and a new or
    changed transect observation on such a visit (field `survey_visit`). The server enforces this
    direction only.
  - *Completed with no observations needs the tick.* Only the app checks this (T040 built it on Finish, D-068);
    the admin sees it at review (T043). The server cannot check it: a visit that was never sent before it
    was finished reaches the server as one coalesced create with `status = completed` (D-051), ahead of its
    observations in the queue, so the server would see 0 observations and reject a good visit.
- **V09.** Reads `started_at`, not the previous status, so it holds for a coalesced create too (draft straight to
  `cancelled`, even for a started visit). Reported on `cancel_reason`. The app offers only the fitting reasons;
  the server is the one that decides. An admin edit that breaks it (clearing `started_at` of an aborted visit,
  setting it on a not-conducted one) is refused in the admin form, on *Started at*, with a sentence instead of the ID.
- **V07 codelists.** Observation: `sex`, `life_stage`, `behaviour` (every item), `source`,
  `identification_confidence`. Visit: `status`, `survey_method`, `precipitation`, `cancel_reason` (blank is
  allowed). The app keeps the same lists in `lib/core/validation/observation_values.dart`,
  `lib/core/validation/visit_values.dart`.
- **W01.** Applied on create only (D-065). Re-checking when a photo arrives belongs to T057.
  `photo_count` counts the observation's live photos, uploaded or not (T049), so it is 0 at the create.
- **W03, W04.** The server reads the link (`host_plant_record_id`, T051): they fire on `oviposition` and on
  `life_stage = larva` only when it is empty. A nectar link does not count. The app does the same since T052:
  `w03Applies` and `w04Applies` take the host plant id and are false once it is set.
- **Plant records (T051).** Only V02, V07 and V08 apply; there is no V03 or V04, because a plant record has no
  visit-status or time-window rule (the visit lock is its only visit rule). V07 lists `resource_type`, and
  `abundance_class`, `phenology_stage` and `flowering_intensity` (each may also be blank). V08 reads the
  geometry's extent, so a polygon at longitude 500 is `{"geometry": ["V08"]}`, not a database error. "Notes
  are required when the plant is not identified" is a serializer rule with a plain sentence, not a rule ID.
  The phone's copy of these rules is `core/validation/plant_rules.dart` (T052): V08 there also runs the ring test
  `polygonSelfIntersects`, which agrees with PostGIS's `ST_IsValid` (D-087), and `plantNotesMissing` is the notes rule.
- **Habitat features (T053).** Only V02, V07 and V08 apply, as for plant records. V07 lists `flower_abundance_class`,
  `grazing_intensity`, `mowing_status` and `disturbance_type` (each may also be blank). V08 takes a Point, a LineString or a
  Polygon; a Z coordinate, a MultiPolygon, a bow-tie, a line of one point or of two identical points, and a longitude of 500
  are all `{"geometry": ["V08"]}`. A percentage outside 0–100 is a plain field error on that field, not a rule ID (no rule
  covers it). The app's copy is `mobile/lib/core/validation/habitat_rules.dart` (T054: `validateHabitatFeature`, V08 for the
  three shapes with `polygonSelfIntersects`) with the values in `habitat_values.dart`, plus `vegetationHeightProblem` for the height (0 to
  32767, the server's smallint). The cover slider cannot produce a bad percentage.
- **W07.** The season is compared by local calendar date (both end days are inside), the daily window by
  local wall-clock minute (both ends are inside). "Local" is the time zone of the study site, which the
  protocol holds as `time_zone` (an IANA name, default `Europe/Belgrade`, set per project in the admin). The
  server reads it from the protocol. The app uses the phone's time zone for now, which is the site's zone
  while the researcher is at the site; reading the protocol's zone in the app needs a zone database
  (a `timezone` package) and is ticket T104. All stored times stay UTC; the zone only matters for these
  two wall-clock settings.
