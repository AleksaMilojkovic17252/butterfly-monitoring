# Answers to the 15 key questions (outline §27)

One line each. **To confirm** marks an answer that needs the biologist or the supervisor.

1. **Exact field protocol?** Pollard walk on fixed transects with a 2.5 m / 5 m / 5 m recording box, configurable per project; see [protocol.md](protocol.md). *To confirm: season and time window.*
2. **Mandatory fields?** Listed per entity in [fields.md](fields.md); for an observation: visit (if transect), time, taxon, count, point, confidence, recorder. Every observation also needs a photo (D-024).
3. **Each individual or aggregate?** One record per taxon per sighting event with a `count`; no per-individual rows and no per-visit totals.
4. **Group findings?** One record with `count > 1`; `sex = mixed` allowed when both sexes are in the group.
5. **Allowed distance from the transect?** 20 m; beyond it the flag `far_from_transect` is set. Records are never rejected for it (`max_distance_from_transect_m`).
6. **Valid visit?** Completed, weather within thresholds or justified, and ≥ 80 % route coverage.
7. **True zero?** A completed visit with no transect observations and an explicit confirmation (`zero_observation_confirmed`); "not walked" is `cancelled/not_conducted`; missing data is the absence of a visit row.
8. **Species list?** Butterflies of Serbia, versioned (`TaxonListVersion`, `Taxon`), based on a GBIF backbone export reviewed by the biologist (T019, T024). *To confirm: the list and the source.*
9. **Who may change a determination?** Only admins, through validation (T057); each decision is stored in `ValidationEvent`. Researchers cannot edit validation fields.
10. **Sensitive species locations?** Not handled in Phase 1: exports and OGC access are admin-only, so locations are not public. No coordinate obscuring. *To confirm: whether any species need it before data is shared.*
11. **Plants: points, polygons or both?** Both: `PlantResourceObservation` takes a point or a polygon; habitat features also allow lines.
12. **Which weather data by hand?** Temperature, wind (Beaufort), cloud cover (%) at start and end, and precipitation class; plus a suitable/unsuitable judgement.
13. **Which sensors exist?** None yet; Phase 2 uses a simulator (T079). *To confirm with the supervisor whether real stations are available.*
14. **Is Moving Features needed for the defence?** It is a Phase 2 target (study T086, then T087–T094), not part of Phase 1. *To confirm with the supervisor.*
15. **Original contribution?** The offline-first mobile GIS that joins butterfly observations, field effort, plants, habitat and environmental data through OGC APIs, with an interoperability and usability evaluation (outline §28).
