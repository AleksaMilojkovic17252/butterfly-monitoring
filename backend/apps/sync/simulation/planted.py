"""Planted effects for `simulate_season --planted-effects` (T101, D-110).

Without the flag nothing here runs, so the plain season stays byte for byte the same. With it, the
generator plants known effects that the research-question views (Q1, Q3, Q4) should recover:

- **Q3**: specialists (a species whose host plants are all in one plant genus, from
  `taxon_host_plant`) are `HOST_BOOST` times commoner in "host sections", and each host section has
  larval host-plant patches within 50 m of the line.
- **Q4**: reproductive behaviour is much likelier in the sections of one habitat type, and the
  habitat polygons are drawn per typed section so that records fall in their section's polygon.
- **Q1**: the generator's own habitat preferences (`ecology.habitat_weight`) are the ranking that
  richness per habitat type should follow; it is only written out.

Every new random draw uses its own `stream(..., "planted", ...)`, never a stream of the plain
season.
"""

from dataclasses import dataclass, field

from . import ecology

DEVICE_ID_SUFFIX = "-planted"  # a planted run is never mistaken for a plain run of the same seed

SPECIALIST_BASE_FLOOR = 0.3  # most hashed bases are tiny: a specialist needs enough records
HOST_SECTION_RATE = 0.33
HOST_BOOST = 4.0
PATCHES_PER_HOST_SECTION = 2
PATCH_ABUNDANCE_CLASSES = ["11-100", "101-1000"]
P_REPRO_HI = 0.35  # a record is reproductive: in a section of the chosen habitat type
P_REPRO_LO = 0.03  # ... in any other section
REPRODUCTIVE_BEHAVIOURS = ["courtship", "mating", "oviposition"]
POLYGON_SHARE = 0.8  # the habitat polygon of a section covers the middle 80 % of its span
POLYGON_HALF_WIDTH_M = 15.0


@dataclass
class PlantedEffects:
    specialists: dict  # taxon id -> scientific name
    host_plants: list  # (plant taxon id, scientific name), in a fixed order
    host_sections: dict  # transect code -> indexes of its host sections
    repro_code: str  # habitat code with the reproductive bias
    polygon_m: dict = field(default_factory=dict)  # habitat code -> polygon length, metres

    def params(self, taxon_id, params):
        """A specialist gets a higher base abundance."""
        if taxon_id not in self.specialists:
            return params
        peak, sigma, base = params
        return peak, sigma, max(base, SPECIALIST_BASE_FLOOR)

    def boost(self, taxon_id, transect_code, section_index):
        if taxon_id in self.specialists and section_index in self.host_sections[transect_code]:
            return HOST_BOOST
        return 1.0

    def reproductive_probability(self, habitat_code):
        return P_REPRO_HI if habitat_code == self.repro_code else P_REPRO_LO


def specialists_from_rows(rows):
    """`rows`: (taxon id, taxon name, plant id, plant name). Specialist = one plant genus."""
    plants_of, names = {}, {}
    for taxon_id, taxon_name, plant_id, plant_name in rows:
        names[taxon_id] = taxon_name
        plants_of.setdefault(taxon_id, {})[plant_id] = plant_name
    specialists = {
        taxon_id: names[taxon_id]
        for taxon_id, plants in plants_of.items()
        if len({name.split(" ")[0] for name in plants.values()}) == 1
    }
    host_plants = sorted(
        {(pid, pname) for tid in specialists for pid, pname in plants_of[tid].items()},
        key=lambda pair: pair[1],
    )
    return specialists, host_plants


def build(stream, specialists, host_plants, infos_by_code):
    """`stream(*parts)` is the generator's seeded `random.Random`; `infos_by_code` maps a transect
    code to its `[SectionInfo]`. Returns None when no section has a habitat type."""
    host_sections = {}
    for code, infos in sorted(infos_by_code.items()):
        rng = stream(code, "planted", "sections")
        chosen = {i for i in range(len(infos)) if rng.random() < HOST_SECTION_RATE}
        host_sections[code] = chosen or {0}
    typed = sorted(
        {i.habitat_code for infos in infos_by_code.values() for i in infos if i.habitat_type_id}
    )
    if not typed:
        return None
    polygon_m = {}
    for infos in infos_by_code.values():
        for info in infos:
            if info.habitat_type_id:
                length = (info.hi - info.lo) * POLYGON_SHARE
                polygon_m[info.habitat_code] = polygon_m.get(info.habitat_code, 0.0) + length
    repro_code = stream("planted", "repro").choice(typed)
    return PlantedEffects(specialists, host_plants, host_sections, repro_code, polygon_m)


def describe(planted, taxa, infos_by_code):
    """Lines for the summary: the planted effect sizes and what the views should show."""
    lines = ["Planted effects (T101; the data is simulated, so this checks the queries):"]
    lines.append(
        f"  Q3 specialists ({len(planted.specialists)}, one host-plant genus): "
        + ", ".join(sorted(planted.specialists.values()))
    )
    lines.append("  Q3 host plants: " + ", ".join(name for _, name in planted.host_plants))
    for code, chosen in sorted(planted.host_sections.items()):
        sections = ", ".join(str(i + 1) for i in sorted(chosen))
        lines.append(
            f"  Q3 host sections of {code}: {sections} of {len(infos_by_code[code])} "
            f"({PATCHES_PER_HOST_SECTION} patches each); "
            f"specialists are x{HOST_BOOST:g} there"
        )
    total = sum(planted.polygon_m.values())
    a = planted.polygon_m[planted.repro_code] / total
    r = P_REPRO_HI * a / (P_REPRO_HI * a + P_REPRO_LO * (1 - a))
    d = (r - a) / (r + a - 2 * r * a)
    lines.append(
        f"  Q4 reproductive habitat: {planted.repro_code}; P(reproductive) {P_REPRO_HI} there, "
        f"{P_REPRO_LO} elsewhere; planted area share a = {a:.3f}; expected record share "
        f"r = {r:.3f} and D = {d:.3f} (assumes equal record density per metre of transect)"
    )
    codes = sorted(
        {i.habitat_code for infos in infos_by_code.values() for i in infos if i.habitat_type_id}
    )
    score = {
        code: sum(
            planted.params(taxon_id, params)[2] * ecology.habitat_weight(taxon_id, code)
            for taxon_id, params in taxa
        )
        for code in codes
    }
    ranking = ", ".join(f"{c} {score[c]:.2f}" for c in sorted(score, key=score.get, reverse=True))
    lines.append(f"  Q1 encoded habitat ranking (sum of base x habitat weight): {ranking}")
    return lines
