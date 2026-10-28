# Field protocol

Baseline for T001. Values marked **(proposed)** are defaults taken from common Pollard-walk
practice and the ticket text. They are **to confirm with the biologist**. Every threshold below is a
per-project setting (`ProjectProtocol`, T016); nothing is hard-coded in the app or the server.

The rule IDs used below (V01–V08 reject a save, W01–W07 warn) are defined in
[validation-rules.md](validation-rules.md).

## 1. Method: Pollard walk

- Repeated walks of a fixed transect, divided into numbered sections (outline §7.1).
- The observer walks at a steady pace and counts every butterfly inside the **recording box**:
  - 2.5 m to each side of the observer (5 m wide in total)
  - 5 m ahead
  - 5 m above
- Butterflies outside the box are not part of the standardised count. They may be recorded as
  `source = incidental` (T047, should-have).
- Time spent on photographing or identifying is a **pause** (paused seconds are excluded from
  `duration_seconds`). The walked distance comes from the GPS route (T036).
- `survey_method` is `pollard_walk` (default) or `other`.

## 2. Season and time windows

| Setting | Default | Source |
|---|---|---|
| Season start / end | **1 April – 30 September** (proposed). No default in the model: the admin must enter both dates | T016 `season_start`, `season_end` |
| Daily window | **10:00 – 17:00 local time** (the project's `time_zone`) | T016 `day_start_time`, `day_end_time` |
| Target visits per season | 8 | T016 `target_visits_per_season` |

A visit started outside either window is saved with warning **W07**; it is not rejected.

## 3. Weather thresholds

A visit is *weather-suitable* when **all** of these hold at the start (and end, if recorded):

- temperature ≥ 13 °C **and** cloud cover ≤ 40 %, **or** temperature ≥ 17 °C with any cloud cover
- wind ≤ 5 Beaufort
- no precipitation (`precipitation = none`)

| Setting | Default |
|---|---|
| `min_temperature_c` | 13.0 |
| `sunny_temperature_c` | 17.0 |
| `max_cloud_cover_pct_if_cool` | 40 |
| `max_wind_beaufort` | 5 |
| `allow_precipitation` | false |

Weather outside the thresholds produces warning **W06** and `weather_suitable = false`. The visit can
still be completed; it is then only *valid* if a justification is given (§6).
Weather is entered by hand in Phase 1. Wind is in Beaufort, converted to m/s for the environmental
snapshot (T063).

## 4. Records and counts

- **One record per taxon per sighting event**, with a `count` field (≥ 1).
- A **group record** is allowed: several individuals of one taxon seen together are one record with
  `count > 1`. If the group has both sexes, `sex = mixed`.
- Each individual is *not* a separate record. An aggregate over the whole visit is *not* allowed: the
  position and time belong to one sighting event.
- Identification uncertainty is recorded in `identification_confidence`, not by leaving the taxon
  empty. Genus-only records point to a taxon of rank `genus`.
- Species-range checks are out of scope (no distribution data).

## 5. Distance from the transect

- A transect observation farther than **20 m** from its transect line gets the flag
  `far_from_transect` (T056, `max_distance_from_transect_m`). It is never rejected.
- Observations outside the project's study area get `outside_project_area`.

## 6. Valid visit

A visit counts as **valid** for analysis when all of these hold:

1. status is `completed` (or later: `synced`, `reviewed`, `locked`);
2. weather is within the thresholds of §3, **or** a justification (`weather_missing_reason`, or the
   admin's review note) is recorded;
3. the GPS route covers **≥ 80 %** of the transect length (`min_coverage_pct`).

Everything else is stored but is not valid: `cancelled` visits, and completed visits that fail 2 or 3.
Coverage is shown in the app and computed in indicators (T061); it is not a rejection rule.

**Coverage** (T040, D-068): the transect is sampled every 10 m along its line, starting at 0 m, plus its end point. A sample is
covered when a **usable** track point lies within `max_distance_from_transect_m` of it (point to point, not point to route segment).
A point is usable by the accuracy rule of D-060: no accuracy, or an accuracy of at most 2 × `gps_accuracy_warning_m`. Coverage is the
covered samples divided by all samples, in percent with one decimal. With fewer than 2 usable points there is no coverage (`null`).
The phone works it out at Finish, from the points it recorded; the server does the same in T100.

## 7. True zero, cancelled and missing

| Situation | Representation | Outcome in exports (`SurveyVisit.outcome`) |
|---|---|---|
| Walked the whole standardised visit, saw nothing | `completed`, `zero_observation_confirmed = true`, no transect observations (V06) | `true_zero` |
| Walked, saw butterflies | `completed`, `zero_observation_confirmed = false` | `completed_with_records` |
| Planned but not walked | `cancelled`, `cancel_reason = not_conducted` | `cancelled:not_conducted` |
| Stopped early because of weather / other reason | `cancelled`, `aborted_weather` / `aborted_other` | `cancelled:aborted_weather` / `cancelled:aborted_other` |
| Walked but the protocol was not followed | `cancelled`, `invalid_protocol` | `cancelled:invalid_protocol` |
| Missing data | No visit row at all. Detected only against `target_visits_per_season` | – |

A draft or a visit in progress has no outcome yet (an empty value; the export writes its missing-value code).
The reason must fit the visit (V09): `not_conducted` only for a visit that was never started, the other three
only for one that was. A not-conducted visit has no `started_at`, so its date is `created_at`. The
observations of an aborted visit are kept, but the visit is not a valid visit (§6).

## 8. GPS route

- Default interval 5 s; battery-saver interval 15 s (`gps_interval_s`, `gps_interval_battery_saver_s`).
- Fix accuracy worse than 25 m raises warning W02 (`gps_accuracy_warning_m`).
- A gap longer than 60 s between fixes (outside pauses) sets the visit flag `gps_gap` (`gps_gap_s`). The pauses are recorded in
  `survey_visit.pauses` (a list of `{started_at, ended_at}`, T040, D-068), so "outside pauses" can be checked: for two consecutive
  points, the time between them minus its overlap with the pauses. The Finish screen lists such gaps; T056 sets the flag.
- Points are stored raw and never thinned.

## 9. Simulated field day (paper walk-through)

Outline §29. Walk-through agreed with the developer on 2026-10-14. The friction points marked
*predicted* are the assistant's estimates; they should be confirmed or struck out after the first
real or role-played walk with a transect and the biologist.

### Flow

0. **Before the field (admin, office).** An admin draws the transect and its sections in Django
   admin and adds the researcher to the project. Researchers never create transects in the field.
1. **Pick the transect and start the visit.** The researcher opens the project, picks a transect
   (already on the phone from the offline package) and starts a visit. Start form: observer count,
   start temperature, wind (Beaufort), cloud cover, precipitation. GPS tracking starts.
2. **Walk and record butterflies.** For each sighting inside the recording box:
   1. choose *butterfly* (plants are not recorded during the walk, see step 4)
   2. fill in the form: taxon, count, confidence; optional sex, life stage, behaviour, notes.
      Position and time come from the GPS and the clock
   3. take a photo if the taxon requires one (`photo_required`, rule W01) or the observer is unsure;
      otherwise the photo is optional. Save
3. **Repeat step 2** until the end of the transect. The observer can pause (netting, identifying,
   resting); paused time is not counted in the duration.
4. **Finish the visit.** End weather, notes; if no butterfly was recorded, the true-zero confirmation
   (V06). The visit becomes `completed` and syncs when there is a connection.
5. **Record plants after the walk.** Plants are not part of the standardised count, and the
   researcher remembers which plants were passed. For each plant: type (host, nectar, ...), taxon,
   abundance, phenology, a point or a patch polygon, and an optional photo. The records belong to the same
   visit. A butterfly can be linked to a host or nectar plant here (W03, W04).
6. **Review (admin, office).** Sync, validate pending records, lock the visit.

### Slow, unclear or ambiguous steps (predicted)

1. **Weather at the start.** Estimating Beaufort and cloud percentage is subjective; a pick list
   may be quicker than numeric entry.
2. **Pauses.** When the clock stops is not defined. The app needs an explicit Pause button, and the
   rule for a short identification stop must be agreed.
3. **Photos.** Stopping to photograph a butterfly that may fly off is slow. It applies only to
   taxa flagged `photo_required` and to uncertain identifications, so the app must show that
   requirement before the observer starts the form. A missing photo gives `validation_status = pending`.
4. **Taxon choice.** Searching a list of a few hundred taxa in sun is slow. A recent/favourites
   list is needed.
5. **Groups.** Ten individuals flying up together are one record with `count = 10`. The observer
   needs a rule for what counts as the same event, so a second sighting of the same species 30 m
   later is a new record and not a higher count on the first.
6. **Unidentified butterflies.** The path from "not sure" to a saved record (`genus_only`,
   `unknown`) has to take few taps.
7. **Section assignment.** A manual section pick adds a step per sighting; assigning it from GPS
   (T048) removes it.
8. **Plants after the walk.** The position of a plant is no longer the observer's position, so it
   must be placed on the map by hand. Linking a butterfly to a host plant needs the plant record to
   exist first, so links are made in step 5, not in the field.
9. **Plant geometry.** Drawing a patch polygon is slow; a point plus an abundance class is faster.
10. **Photo to record.** Photo before or after saving; a photo taken while the GPS is poor.
11. **Finishing with zero sightings.** The confirmation text must be unambiguous (T041).
12. **Flat table.** One visit needs a join of visit, observation, taxon and weather. Weather appears
    twice (start, end), so the flat table has to repeat columns or choose one.
