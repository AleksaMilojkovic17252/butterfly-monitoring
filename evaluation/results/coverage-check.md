# Route coverage: app against server (T100)

The phone's `routeCoveragePct` (T040, run in a throwaway Dart test on dev data, 2026-11-05) against the server's `route_coverage_pct`
(`surveys/coverage.py`) on the same 13 completed dev visits, chosen to span 0 % to 100 %. Points are all live points of the visit;
both sides apply the accuracy rule of D-060. Samples are the app's sample count (0, 10, 20 ... m plus the end point).

| Visit | Points | Usable | Samples | App % | Server % | Difference (pp) |
|---|---|---|---|---|---|---|
| `612f4e08` | 104 | 104 | 102 | 0.0 | 0.0 | 0.0 |
| `6e2bfecd` | 17 | 17 | 102 | 0.0 | 0.0 | 0.0 |
| `f4f1cd85` | 10 | 10 | 102 | 3.9 | 3.9 | 0.0 |
| `8931ebd8` | 18 | 18 | 102 | 3.9 | 3.9 | 0.0 |
| `64d18105` | 14 | 12 | 102 | 3.9 | 3.9 | 0.0 |
| `482cd915` | 4 | 4 | 102 | 4.9 | 3.9 | 1.0 |
| `615e8f24` | 5 | 5 | 102 | 4.9 | 4.9 | 0.0 |
| `5f5123f7` | 46 | 46 | 102 | 4.9 | 4.9 | 0.0 |
| `251783b2` | 306 | 306 | 102 | 4.9 | 4.9 | 0.0 |
| `5c6f7ecb` | 7 | 7 | 102 | 4.9 | 4.9 | 0.0 |
| `409dcc0d` | 27 | 27 | 102 | 28.4 | 28.4 | 0.0 |
| `fc2dbb58` | 111 | 111 | 101 | 100.0 | 100.0 | 0.0 |
| `86477d0f` | 120 | 120 | 101 | 100.0 | 100.0 | 0.0 |

Largest difference: 1.0 percentage points (target: no more than 1). One sample of 102 is 0.98 points, so the one visit that differs (`482cd915`, 4 usable points) is a single sample at the edge of the limit: the app measures geodesic point-to-point distance, the server planar distance in the UTM zone.

The comparison used stored dev tracks. The replay comparison through the phone (T072) is a note under T072 in `docs/TICKETS.md`.
