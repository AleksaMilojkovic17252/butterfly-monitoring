# Field protocol

Baseline for T001. Values marked **(proposed)** are defaults taken from common Pollard-walk
practice and the ticket text. They are **to confirm with the biologist**. Every threshold below is a
per-project setting (`ProjectProtocol`, T016); nothing is hard-coded in the app or the server.

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
| Daily window | **10:00 – 17:00 local time** | T016 `day_start_time`, `day_end_time` |
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

## 7. True zero, cancelled and missing

| Situation | Representation |
|---|---|
| Walked the whole standardised visit, saw nothing | `completed`, `zero_observation_confirmed = true`, no transect observations (V06) |
| Planned but not walked | `cancelled`, `cancel_reason = not_conducted` |
| Stopped early because of weather / other reason | `cancelled`, `aborted_weather` / `aborted_other` |
| Walked but the protocol was not followed | `cancelled`, `invalid_protocol` |
| Missing data | No visit row at all. Detected only against `target_visits_per_season` |

## 8. GPS route

- Default interval 5 s; battery-saver interval 15 s (`gps_interval_s`, `gps_interval_battery_saver_s`).
- Fix accuracy worse than 25 m raises warning W02 (`gps_accuracy_warning_m`).
- A gap longer than 60 s between fixes (outside pauses) sets the visit flag `gps_gap` (`gps_gap_s`).
- Points are stored raw and never thinned.

## 9. Simulated field day (paper walk-through)

Outline §29. **This walk-through was drafted by the assistant from the outline and the ticket models;
it has not yet been done with real data.** The friction points below are predictions. Re-do the walk
with a real transect, and ideally the biologist, and amend this list. Nothing in T002–T007 depends
on it.

Steps: pick a transect → start the visit → record ten sightings → record one host plant → add a photo
→ finish the visit → put everything into one table.

### Slow, unclear or ambiguous steps

1. **Weather at the start.** The observer must enter temperature, wind (Beaufort) and cloud cover
   before walking. Estimating Beaufort and cloud percentage is subjective; a pick list (0–12 and
   okta-style cloud buckets) may be quicker than numeric entry.
2. **Pauses.** It is unclear when the clock stops (photographing, netting, identifying). The model
   has `paused_seconds`, but the app needs an explicit Pause button, and the rule for "short
   identification stop" must be agreed.
3. **Ten sightings in a row.** Each needs taxon, count, confidence at minimum. Searching a species list
   of a few hundred taxa with gloves, in sun, is the slowest step. Needs a recent/favourites list.
4. **Groups.** When ten individuals of one species fly up together, is that one record with
   `count = 10`, or do the individuals get counted as they leave? The protocol says one record per
   sighting event; the observer needs a rule of thumb for "same event".
5. **Same taxon seen again.** A second sighting of the same species 30 m later is a new event
   (new record). Observers may be tempted to increase the count of the earlier record instead.
6. **Unidentified butterflies.** The path from "not sure" to a saved record (`genus_only`,
   `photo_required`, `unknown`) has to take few taps, or the observer will skip the record.
7. **Section assignment.** Whether the observer picks the section or the app assigns it from GPS (T048)
   changes the form. Manual pick adds a step per sighting.
8. **Plant record linking.** Linking a butterfly to a host plant needs the plant to exist first.
   Order of entry (plant first, or butterfly first with a link later) is unclear.
9. **Plant geometry.** Point vs. polygon: drawing a patch polygon in the field is slow. A point plus an
   area class would be faster; the model supports both.
10. **Photo to record.** Taking the photo after saving the record vs. before; what happens to a photo
    taken while GPS is poor.
11. **Finishing with zero sightings.** The confirmation text must be unambiguous (T041).
12. **Single table.** Flattening one visit into one table needs a join of visit, observation, taxon
    and weather. Weather appears twice (start/end), so the flat table has to choose or repeat columns.
