# Research-question views on the simulated season (T101)

**The data is simulated.** The generator planted the effects listed below (`simulate_season --planted-effects`), so this shows
that the views (D-110) recover what was put in: it validates the queries, not the biology. The views were also checked by hand on a
small paper case (`tmp/t101/smoke.py`, 49 checks, not committed; D-021).

Project `T101 planted effects` (a copy of the Fruška Gora demo project: 4 transects, 32 visits planned, seed 42, 2026-05-01 to 2026-08-31):
571 observations, 26 habitat polygons, 34 plant records, 29 completed visits, 818 pushed mutations (a rerun is all `duplicate`).
Only **valid visits** count in Q1 and Q3 (`survey_visit_validity`, D-095); the effective taxon is `coalesce(validated_taxon_id, taxon_id)`.

## Planted effects

```
Planted effects (T101; the data is simulated, so this checks the queries):
  Q3 specialists (19, one host-plant genus): Aglais io, Aglais urticae, Apatura iris, Araschnia levana, Argynnis paphia, Brenthis daphne, Cupido minimus, Issoria lathonia, Lycaena alciphron, Lycaena phlaeas, Lycaena virgaureae, Lysandra coridon, Melitaea cinxia, Polyommatus daphnis, Polyommatus thersites, Thecla betulae, Vanessa atalanta, Zerynthia cerisy, Zerynthia polyxena
  Q3 host plants: Anthyllis vulneraria, Aristolochia clematitis, Coronilla varia, Hippocrepis comosa, Onobrychis viciifolia, Plantago lanceolata, Prunus spinosa, Rubus fruticosus, Rumex acetosa, Rumex acetosella, Salix caprea, Urtica dioica, Viola spp.
  Q3 host sections of FG1: 5, 6 of 7 (2 patches each); specialists are x4 there
  Q3 host sections of FG2: 1, 4, 8 of 8 (2 patches each); specialists are x4 there
  Q3 host sections of FG3: 1, 3 of 5 (2 patches each); specialists are x4 there
  Q3 host sections of FG4: 1, 2, 6 of 6 (2 patches each); specialists are x4 there
  Q4 reproductive habitat: wet-meadow; P(reproductive) 0.35 there, 0.03 elsewhere; planted area share a = 0.208; expected record share r = 0.754 and D = 0.842 (assumes equal record density per metre of transect)
  Q1 encoded habitat ranking (sum of base x habitat weight): wet-meadow 10.70, mesic-grassland 10.37, dry-grassland 9.71, forest-edge 9.68, ruderal 9.49, shrubland 8.88
```

## Q1 · habitat richness (`report_habitat_richness`, 2026)

| habitat | sections | km | valid visits | effort km | species | transect records | individuals | per km |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| dry-grassland | 4 | 0.572 | 8 | 4.576 | 39 | 98 | 368 | 80.43 |
| mesic-grassland | 6 | 0.751 | 8 | 6.007 | 48 | 146 | 298 | 49.61 |
| wet-meadow | 5 | 0.834 | 4 | 3.337 | 24 | 34 | 163 | 48.84 |
| ruderal | 3 | 0.393 | 16 | 3.146 | 30 | 70 | 76 | 24.16 |
| shrubland | 5 | 0.853 | 20 | 6.154 | 46 | 119 | 139 | 22.59 |
| forest-edge | 3 | 0.600 | 8 | 4.798 | 40 | 82 | 86 | 17.92 |
| unknown | 0 | 0 | 0 | 0 | 12 | 13 | 15 | (none) |

There are no incidental records in this season (the generator makes only transect records), so the incidental half of the view is checked on the paper case only.

**Recovered? Not clearly.** The generator's encoded ranking is wet-meadow 10.70, mesic-grassland 10.37, dry-grassland 9.71, forest-edge 9.68,
ruderal 9.49, shrubland 8.88. The view's individuals per km rank dry, mesic, wet, ruderal, shrubland, forest. After removing the 4 injected high counts (more than 50) the order is
mesic 27.0, ruderal 24.2, dry 24.0, shrubland 22.6, forest-edge 17.9, wet 10.5. So the order agrees only in part, and wet-meadow comes last instead of first.
Two reasons, both about the data and not about the view: the planted differences are small (the encoded score only spans 8.9 to 10.7, about 20 %, a spread much smaller than the noise of one season
of 4 to 20 valid visits per habitat), and the specialists' x4 boost in random host sections adds habitat-independent variation (the wet meadow also has only 4 valid visits). The check that the view is arithmetically right is the paper case (per km 50.00 and 30.00 exactly as worked out). A stronger planted habitat effect, or more visits, is needed to
show the ranking; that would be a change to the generator and was not made here.

## Q3 · specialists and host plants (`report_specialist_host_plants`, 26 sections, 2026)

Sections split by whether the generator planted them as host sections (10 of 26):

| | sections | valid visits | specialist individuals | per visit | host patches | summed midpoints |
|---|---:|---:|---:|---:|---:|---:|
| planted host sections | 10 | 68 | 238 | **3.50** | 24 | 6777.0 |
| other sections | 16 | 116 | 64 | **0.55** | 6 | 1323.0 |

**Recovered: yes, in direction and size.** Specialists are 6.4 times as common per visit in the host sections as elsewhere, against the planted x4 on the expected count. The ratio is larger than 4
because 10 sections are a small sample and the sections differ in habitat (the habitat weight multiplies the expected count too); the direction is not in doubt. Each host section has 2 planted patches (24 patches in 10 sections is 2.4 per
section: the extra ones are the generator's ordinary random larval-host records that happen to be a specialist's host plant, and patches planted in an adjacent host section). `host_patches > 0` is not limited to the planted sections: 6 other sections also have
1 patch each, and **all 6 are next to a planted host section**, so the patch is within the 50 m radius of both. That is what a distance-based count should do, and it is a limit of reading it as "this section has host plants".

## Q4 · reproductive microhabitat (`report_reproductive_microhabitat`)

| habitat | polygons | area m² | reproductive records | record share r | area share p | Jacobs D |
|---|---:|---:|---:|---:|---:|---:|
| **wet-meadow** (planted) | 5 | 19006.6 | 14 | 0.560 | 0.211 | **0.654** |
| dry-grassland | 4 | 12263.6 | 3 | 0.120 | 0.136 | -0.071 |
| mesic-grassland | 6 | 17433.4 | 3 | 0.120 | 0.193 | -0.274 |
| forest-edge | 3 | 13127.2 | 2 | 0.080 | 0.145 | -0.324 |
| shrubland | 5 | 19209.5 | 3 | 0.120 | 0.213 | -0.329 |
| ruderal | 3 | 9246.1 | 0 | 0.000 | 0.102 | -1.000 |

**Recovered: yes, the right habitat comes out on top and is the only one with a positive D.** The generator expected D = 0.842 (r = 0.754, area share a = 0.208); the view gives 0.654 (r = 0.560, p = 0.211). The planted
area share matches (0.208 against 0.211). The record share is lower than expected: 14 of 25 reproductive records in polygons. The expected value assumes equal record density per metre and that every record falls in its
section's polygon; in fact the polygon covers only the middle 80 % of a section, the records are drawn along the whole span, and other records are reproductive by chance everywhere (3 % of them). Only 25 reproductive records
fall in a polygon, so one record moves r by 4 points. The record counts are small: GPS error of 5 to 15 m (here 0 to 5 m from the line, polygons 15 m to each side) is not tested by this data and would blur
point in polygon for small real polygons (documented limit).

## Q6 · observation hexagons (`geo.observation_hexgrid`, 100 m edge)

The project has **40 hexagons** with at least one record (571 observations, mean 14.3 per cell, none empty by construction). The busiest:

| cell | observations | individuals | species | nectaring | reproductive |
|---|---:|---:|---:|---:|---:|
| 2722:28871 | 44 | 172 | 26 | 17 | 2 |
| 2731:28874 | 41 | 177 | 26 | 13 | 1 |
| 2729:28874 | 33 | 37 | 21 | 16 | 0 |
| 2720:28877 | 30 | 30 | 22 | 9 | 0 |
| 2727:28874 | 30 | 34 | 24 | 13 | 2 |

Q6 plants no effect of its own: the busiest cells follow the transects (records are 0 to 5 m from the line), the two cells with 172 and 177 individuals (far more individuals than records) probably hold the injected high counts; this was not checked cell by cell. The view counts every record of
the cells, so 571 = the sum, and the paper case checks each cell against a point-by-point `ST_HexagonGrid` lookup. The view takes about 11 ms for one project here (`EXPLAIN ANALYZE`); on the whole dev database it took 3.2 s while one demo
project carried stray records 200 km away (the lattice covers the extent of a project's records, about 220 000 cells), and 77 ms after those 5 records were soft-deleted (D-110).

## Limits

- Simulated data: the results are circular by design.
- The views use the planted project's valid visits only for Q1 and Q3; Q4 and Q6 use every live record of a visit that is not cancelled or deleted (D-110).
- No statistics: the views are inputs for analysis in R through the export.
- Plans for the spatial joins: `research-questions-plans.md`.
