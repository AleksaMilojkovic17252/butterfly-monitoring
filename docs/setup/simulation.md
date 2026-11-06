# Simulated season (T071)

`simulate_season` fills a project with one deterministic season of survey data and sends it
through the real sync pipeline. It feeds the indicators, exports, OGC and QGIS checks, the
benchmarks and the evaluation. Dev stack only (`DEBUG` must be on). Design: D-109.

> **Plausible, not realistic.** The weather and the butterfly ecology are made up (seasonal curves,
> random walks and Poisson counts, not fitted to any station or survey). The thesis evaluates the
> **system**, not butterfly ecology. Do not draw ecological conclusions from this data.

## Run

```fish
set DC docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml
$DC up -d django    # picks up the ./simulator mount
$DC exec -u (id -u) -e HOME=/tmp django python manage.py simulate_season --project <uuid> --seed 42
```

Options: `--start` / `--end` (default 2026-05-01 / 2026-08-31), `--visits-per-transect` (8),
`--seed` (42), `--user <email>` (default: the project's only researcher member), `--direct`.
Run it as the developer (`-u (id -u)`): it also writes `database/seeds/transects.gpx`.

## What is generated

- **Visits:** every transect gets N visits, one per equal window of the period, on mostly suitable
  days (85 %). About 10 % are cancelled: half `not_conducted` (no start, no points), half
  `aborted_weather` (a partial walk, a few observations).
- **Weather:** `simulator/simweather` makes a daily story (temperature, cloud, wind, rain); the visit's
  start and end values come from it, and `weather_suitable` from the protocol rule.
- **Tracks:** 0.8-1.2 m/s, one fix per protocol interval, Gaussian noise with sigma equal to a 3-8 m
  accuracy, `provider = simulated`.
- **Observations:** taxa from the project's list, per-habitat weights and a Gaussian flight period
  from the taxon id, Poisson counts; 80 % confirmed, 15 % probable, 5 % `photo_required` with a
  placeholder photo (one JPEG, so later uploads show the SHA-256 dedup path).
- **Plants and habitats:** 3-4 plant records and 2-3 habitat features on the first completed visit of
  each transect.
- **Anomalies** (listed in the summary): high counts (about 1 %), records 40-150 m from the line
  (about 2 %), one or two about 400 m away (also outside the project area), GPS gaps of 61-120 s
  (about 10 % of walked visits), true-zero visits (about 5 %), and duplicate batches (the same
  request sent twice, about 5 % of visits).

## Rerun

Ids are uuid5 of project, seed and a key, and all times are simulated, so **the same seed on the
same project changes nothing**: every mutation comes back `duplicate`. **A different seed** adds
another set of visits (on the same transects and dates, so use it on a spare project). The ids do not
include `--start`, `--end` or `--visits-per-transect`, so rerunning a seed with other values of those
stops with an error (the stored visits differ from the plan) instead of dropping the data as duplicates.

## Push and direct

Default: an in-process API client with the researcher's JWT posts one visit per `/api/v1/sync/push`
request and uploads photos through the three attachment endpoints. `--direct` calls
`sync.services.push` with up to 1000 mutations per call: faster, no HTTP. Both send the same data
(the exports are identical).

## GPX for the replay

`database/seeds/transects.gpx` has one `<trk>` per transect (named by its code), walked at 1 m/s
without noise, with a timestamp every protocol interval. T072 replays it in the app.
