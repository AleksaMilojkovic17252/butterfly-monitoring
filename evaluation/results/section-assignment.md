# Section assignment: nearest section against the linear-referencing interval

Does T048's nearest-section rule (D-084) give the same section as the `[start_m, end_m)` interval that
`ST_LineLocatePoint` gives (T103, D-105)? Query: [`section-assignment.sql`](section-assignment.sql).

## Data

Dev data, 2026-11-06 (not the simulated season: rerun after T071). 1 121 live transect records with a visit
(`source = 'transect'`), on 12 of the 17 transects of live projects (3 more transects belong to deleted projects and are
left out; transect codes repeat across projects, so Q4 is by transect id). Limit: the protocol's `max_distance_from_transect_m`. *Nearest* is the query of
`transects.services.nearest_section_id` run afresh. *Interval* is the live section with
`start_m <= distance_along_m < end_m` (the last section also takes `= end_m`), and only when
`offset_m <= limit`. *Stored* is `transect_section_id` as saved (possibly the phone's guess).

## Result

| | Records |
|---|---|
| Agree (same section) | 1 110 |
| Disagree (different sections) | 0 |
| Nearest only (interval empty) | 0 |
| Interval only (nearest empty) | 0 |
| Neither (all beyond the limit, `offset_m > limit`) | 11 |
| **Total** | **1 121** |

Stored against nearest: 1 098 the same (the 11 beyond-limit records are null on both sides), 23 different. The
23 are all records whose stored section is not the fresh nearest one (SH1 4, SH2 5, SH3 6, SH4 6, FG2 2); I did not
look into why (the phone's guess, or the simulated data). Nearest and the interval still agree on all of them.

Disagreements by distance to the nearest section boundary: none, so every bucket (≤ 1 m, ≤ 5 m, ≤ 10 m,
> 10 m) is 0 and the maximum is undefined.

Per transect: every transect with records agrees on all its in-limit records (SH1 227, SH2 259, SH3 257, SH4 257,
FG1 55 + 3, FG2 14 + 3, FG3 6, FG4 8, NI1 21). The records not in the agree column (FG2 5, NI1 2, NI2 4) are the
11 beyond the limit. Full table: query Q4.

## Transects whose sections do not tile the line

Two of the 17 transects of live projects:

| Transect | Length (UTM) | Sections | Problem |
|---|---|---|---|
| `NI12` | 2 991.9 m | 8 | A section starts 748 m before the end of the one before it (the line comes back on itself; see below). First `start_m` 0, last `end_m` = length. |
| `T21` | 930.5 m | 3 | A section starts 545.6 m before the previous one ends; the last `end_m` is 411.4 m, far short of the length. |

The other 15 tile within 0.5 m and span 0 to the length within 1 m (FG1: 7 sections of about 143 m, 0.0 to 1 000.9 m).
Neither `NI12` nor `T21` has a transect record, so they do not affect the counts above. The 113 km `T25` and the
transects `ZZB` and `ZZC` belong to deleted projects, so the `geo` views do not show them.

## Loop-backs

`ST_LineLocatePoint` returns the closest point on the line, which on a transect that comes back near itself can
be on the wrong pass. Then `distance_along_m` and the interval section are wrong, and the profile puts the record
in the wrong bin. Nearest-section has the same risk in a weaker form: it only looks at distance to a section, so
it picks the nearer pass, which is right when the point is nearer the pass the walker was on.

On a closed loop (the line ends where it starts) the shared start/end point can locate at 0 instead of the full length, so the last section's `end_m` can come out small and `start_m` / `end_m` can swap (LEAST / GREATEST hides the swap).

Test: non-adjacent sections (sequence numbers differing by more than 1) within twice the limit of each other,
which is where the buffers of the limit overlap. Found on `NI12` (12 pairs) and `T21` (1); the other 15 are clear. These are also the two
whose `start_m` / `end_m` run backwards, so the check agrees with the tiling check. Neither has a transect record, so no dev count is affected, but
a real transect that loops will need the section chosen by nearest-section (or by the phone) and not by position.

## Findings

- On the 1 121 dev records the two methods never disagree, so the dev data cannot tell them apart. That is a
  property of the data (well-drawn, tiling transects, records on the line), not a proof.
- The interval only works where the sections tile the line in order. Two dev transects do not.
- Nearest-section does not depend on tiling, and it is already in place; `offset_m` makes the same distance check.

## Rerun

Rerun on the simulated season after T071 (more records, with noise near section boundaries, which is where the
two methods could differ). Use `section-assignment.sql` unchanged.
