"""Builds the season (T071): one `VisitBundle` per visit, each a list of push-format mutations.

The generator is the same in both modes (D-109); only `send.py` differs. Every random stream is a
`random.Random` seeded with a string (`<seed>:<transect code>:<visit>:<purpose>`), the entity and
mutation ids are uuid5 of the project, seed and a key, and every time comes from the simulated
clock, so a seed and a project always give the same data and a rerun is all `duplicate`.
"""

import random
import uuid
from collections import Counter
from dataclasses import dataclass, field
from datetime import UTC, date, datetime, time, timedelta
from decimal import Decimal
from zoneinfo import ZoneInfo

import simweather

from apps.surveys.rules import weather_suitable

from . import ecology
from . import planted as planted_effects
from .walk import walk_visit

NAMESPACE = uuid.UUID("8a1f6d3e-71c4-4d57-9d1e-0b71f1c0a071")
DEVICE_ID = "simulator-t071"

SUITABLE_PICK_RATE = 0.85
CANCEL_RATE = 0.10  # half not_conducted, half aborted_weather
GAP_RATE = 0.10
TRUE_ZERO_RATE = 0.05
DUPLICATE_RATE = 0.05
HIGH_COUNT_RATE = 0.01
FAR_RATE = 0.02
OUTSIDE_VISITS = 2

BEHAVIOURS = [
    "flying",
    "flying",
    "resting",
    "basking",
    "nectaring",
    "nectaring",
    "feeding_on_fruit",
]


@dataclass
class Context:
    project: object
    protocol: object
    seed: int
    taxa: list  # (taxon id, params)
    plant_taxa: list
    weather: dict  # date -> DailyWeather
    placeholder: object
    researcher_id: str
    suitable_days: set = field(default_factory=set)
    planted: object | None = None  # PlantedEffects with --planted-effects (T101)

    @property
    def device_id(self):
        return DEVICE_ID + (planted_effects.DEVICE_ID_SUFFIX if self.planted else "")

    @property
    def tz(self):
        return ZoneInfo(self.protocol.time_zone)


@dataclass
class SectionInfo:
    lo: float
    hi: float
    habitat_code: str
    habitat_type_id: str | None
    management_type_id: str | None


@dataclass
class Slot:
    transect: object
    index: int
    day: date
    kind: str  # completed | not_conducted | aborted_weather

    @property
    def key(self):
        return f"{self.transect.code}:{self.index}"


@dataclass
class VisitBundle:
    key: str
    status: str
    mutations: list
    photo_ids: list
    duplicate: bool
    stats: Counter
    anomalies: list


def uid(ctx, kind, key):
    return uuid.uuid5(NAMESPACE, f"t071:{ctx.project.id}:{ctx.seed}:{kind}:{key}")


def iso(moment):
    return moment.astimezone(UTC).isoformat().replace("+00:00", "Z")


def stream(ctx, *parts):
    return random.Random(":".join([str(ctx.seed), *map(str, parts)]))


def mutation(ctx, entity_type, operation, entity_id, payload, at, key):
    return {
        "mutation_id": str(uid(ctx, "mutation", key)),
        "entity_type": entity_type,
        "entity_id": str(entity_id),
        "operation": operation,
        "base_version": None,
        "payload": payload,
        "client_created_at": iso(at),
    }


def make_suitable_days(ctx):
    """Days on which the protocol is met at about 11:00 local time."""
    for day, weather in ctx.weather.items():
        rng = random.Random(f"{ctx.seed}:suitable:{day}")
        temp, cloud, wind, rain = simweather.at_hour(weather, 11.0, rng)
        if weather_suitable(ctx.protocol, Decimal(f"{temp:.1f}"), wind, cloud, rain):
            ctx.suitable_days.add(day)


def schedule(ctx, transects, visits_per_transect, start, end):
    """Slots for every transect; the weather decides the day, the rng the outcome."""
    days = [start + timedelta(days=i) for i in range((end - start).days + 1)]
    slots = []
    for transect in transects:
        rng = stream(ctx, transect.code, "schedule")
        for index in range(visits_per_transect):
            window = days[
                index * len(days) // visits_per_transect : (index + 1)
                * len(days)
                // visits_per_transect
            ]
            if not window:
                continue
            roll = rng.random()
            kind = (
                "not_conducted"
                if roll < CANCEL_RATE / 2
                else "aborted_weather"
                if roll < CANCEL_RATE
                else "completed"
            )
            suitable = [d for d in window if d in ctx.suitable_days]
            unsuitable = [d for d in window if d not in ctx.suitable_days]
            if kind == "aborted_weather":
                pool = unsuitable or window
            elif rng.random() < SUITABLE_PICK_RATE:
                pool = suitable or window
            else:
                pool = window
            slots.append(Slot(transect, index, rng.choice(pool), kind))
    return slots


def outside_keys(ctx, slots):
    completed = [slot.key for slot in slots if slot.kind == "completed"]
    return set(stream(ctx, "outside").sample(completed, min(OUTSIDE_VISITS, len(completed))))


def section_infos(walker, sections):
    infos = []
    for section in sections:
        lo, hi = walker.section_span(section.geometry)
        habitat = section.habitat_type
        infos.append(
            SectionInfo(
                lo,
                hi,
                habitat.code if habitat else "unknown",
                str(section.habitat_type_id) if section.habitat_type_id else None,
                str(section.management_type_id) if section.management_type_id else None,
            )
        )
    return infos


def build_season(ctx, slots, transect_data, outside):
    """`transect_data`: transect id -> (LineWalker, [SectionInfo]). Returns the bundles."""
    first_completed = set()
    bundles = []
    for slot in slots:
        walker, infos = transect_data[slot.transect.id]
        is_first = slot.kind == "completed" and slot.transect.id not in first_completed
        if slot.kind == "completed":
            first_completed.add(slot.transect.id)
        bundles.append(build_visit(ctx, slot, walker, infos, is_first, slot.key in outside))
    return bundles


def _local(ctx, day, hour_float):
    hours = int(hour_float)
    return datetime.combine(day, time(hours, int((hour_float - hours) * 60)), tzinfo=ctx.tz)


def build_visit(ctx, slot, walker, infos, with_extras, outside_far):
    code, key = slot.transect.code, slot.key
    flags = stream(ctx, code, slot.index, "flags")
    # Fixed order of draws, so the flags do not depend on the visit kind.
    want_gap, want_zero, want_dup = (
        flags.random() < GAP_RATE,
        flags.random() < TRUE_ZERO_RATE,
        flags.random() < DUPLICATE_RATE,
    )
    stats, anomalies = Counter(), []
    visit_id = uid(ctx, "visit", key)
    project, protocol = ctx.project, ctx.protocol
    weather = ctx.weather[slot.day]
    interval = protocol.gps_interval_s
    base = {
        "id": str(visit_id),
        "project": str(project.id),
        "transect": str(slot.transect.id),
        "observer": ctx.researcher_id,
        "protocol_version": protocol.protocol_version,
        "survey_method": "pollard_walk",
        "observer_count": 1,
        "paused_seconds": 0,
        "pauses": [],
        "device_id": ctx.device_id,
        "created_offline": True,
        "battery_saver_used": False,
    }
    stats[f"visit_{slot.kind}"] += 1

    if slot.kind == "not_conducted":
        created = _local(ctx, slot.day, 9.0)
        payload = {
            **base,
            "created_at": iso(created),
            "status": "cancelled",
            "started_at": None,
            "ended_at": None,
            "cancel_reason": "not_conducted",
        }
        mutations = [
            mutation(ctx, "survey_visit", "create", visit_id, payload, created, f"{key}:visit")
        ]
        return VisitBundle(key, "cancelled", mutations, [], want_dup, stats, anomalies)

    rng_weather = stream(ctx, code, slot.index, "weather")
    start_hour = stream(ctx, code, slot.index, "start").uniform(10.0, 15.0)
    started = _local(ctx, slot.day, start_hour).astimezone(UTC)
    fraction = 1.0
    if slot.kind == "aborted_weather":
        fraction = stream(ctx, code, slot.index, "fraction").uniform(0.2, 0.6)
    walk = walk_visit(walker, stream(ctx, code, slot.index, "walk"), interval, fraction, want_gap)
    ended = started + timedelta(seconds=walk.duration_s + 60)
    end_hour = start_hour + (walk.duration_s + 60) / 3600
    t0, c0, w0, rain = simweather.at_hour(weather, start_hour, rng_weather)
    t1, c1, w1, _ = simweather.at_hour(weather, end_hour, rng_weather)
    suitable = all(
        weather_suitable(protocol, Decimal(f"{t:.1f}"), w, c, rain)
        for t, c, w in ((t0, c0, w0), (t1, c1, w1))
    )
    if walk.gap_s:
        stats["gps_gap"] += 1
        anomalies.append(f"{key} gps_gap {walk.gap_s} s")

    observations = _observations(
        ctx,
        slot,
        walker,
        infos,
        walk,
        started,
        weather,
        (t0 + t1) / 2,
        (c0 + c1) / 2,
        suppress=want_zero and slot.kind == "completed",
        outside_far=outside_far,
        stats=stats,
        anomalies=anomalies,
    )
    status = "completed" if slot.kind == "completed" else "cancelled"
    zero = slot.kind == "completed" and not observations
    if zero:
        stats["zero_visits"] += 1
        if want_zero:
            stats["true_zero"] += 1
            anomalies.append(f"{key} true zero")
    payload = {
        **base,
        "created_at": iso(started - timedelta(minutes=3)),
        "status": status,
        "cancel_reason": "aborted_weather" if status == "cancelled" else "",
        "started_at": iso(started),
        "ended_at": iso(ended),
        "duration_seconds": walk.duration_s + 60,
        "distance_walked_m": f"{walk.walked_m:.1f}",
        "temperature_start_c": f"{t0:.1f}",
        "temperature_end_c": f"{t1:.1f}",
        "wind_beaufort_start": w0,
        "wind_beaufort_end": w1,
        "cloud_cover_start_pct": c0,
        "cloud_cover_end_pct": c1,
        "precipitation": rain,
        "weather_suitable": suitable,
        "zero_observation_confirmed": zero,
    }
    mutations = [
        mutation(ctx, "survey_visit", "create", visit_id, payload, started, f"{key}:visit")
    ]

    rows = [
        {
            "id": str(uid(ctx, "track_point", f"{key}:{fix.sequence}")),
            "recorded_at": iso(started + timedelta(seconds=fix.seconds)),
            "geometry": {"type": "Point", "coordinates": [fix.lon, fix.lat]},
            "accuracy_m": f"{fix.accuracy_m:.1f}",
            "altitude_m": f"{fix.altitude_m:.1f}",
            "speed_m_s": f"{fix.speed_m_s:.2f}",
            "heading_deg": f"{fix.heading_deg:.1f}",
            "provider": "simulated",
            "sequence_number": fix.sequence,
            "created_at": iso(started + timedelta(seconds=fix.seconds)),
        }
        for fix in walk.fixes
    ]
    for number, chunk_start in enumerate(range(0, len(rows), 1000)):
        mutations.append(
            mutation(
                ctx,
                "survey_track_point",
                "create_batch",
                visit_id,
                {"rows": rows[chunk_start : chunk_start + 1000]},
                ended,
                f"{key}:track:{number}",
            )
        )
    stats["track_points"] += len(rows)

    photo_ids = []
    for number, record in enumerate(observations):
        observation_id = uid(ctx, "observation", f"{key}:{number}")
        mutations.append(_observation_mutation(ctx, key, number, observation_id, visit_id, record))
        stats["observations"] += 1
        stats[f"confidence_{record['confidence']}"] += 1
        if record["confidence"] == "photo_required":
            photo_id = uid(ctx, "photo", f"{key}:{number}")
            photo_ids.append(photo_id)
            stats["photos"] += 1
            mutations.append(_photo_mutation(ctx, key, number, photo_id, observation_id, record))

    if with_extras:
        extras = _plants_and_habitats(ctx, slot, walker, infos, walk, started, visit_id)
        mutations.extend(extras["mutations"])
        stats["plants"] += extras["plants"]
        stats["habitats"] += extras["habitats"]
    return VisitBundle(key, status, mutations, photo_ids, want_dup, stats, anomalies)


def _observations(
    ctx,
    slot,
    walker,
    infos,
    walk,
    started,
    weather,
    temp,
    cloud,
    suppress,
    outside_far,
    stats,
    anomalies,
):
    if suppress:
        return []
    key = slot.key
    rng = stream(ctx, slot.transect.code, slot.index, "obs")
    day_of_year = slot.day.timetuple().tm_yday
    records = []
    planted = ctx.planted
    for section_index, info in enumerate(infos):
        hi = min(info.hi, walk.walked_m)
        if info.lo >= walk.walked_m:
            continue
        for taxon_id, params in ctx.taxa:
            if planted:
                params = planted.params(taxon_id, params)
            lam = ecology.expected_count(
                params,
                day_of_year,
                ecology.habitat_weight(taxon_id, info.habitat_code),
                temp,
                cloud,
            )
            if planted:
                lam *= planted.boost(taxon_id, slot.transect.code, section_index)
            if lam < 1e-4:
                continue
            count = ecology.poisson(rng, lam)
            if count > 0:
                distance = rng.uniform(info.lo, max(info.lo, hi))
                records.append(
                    {
                        "taxon": taxon_id,
                        "count": min(count, ecology.MAX_ORDINARY_COUNT),
                        "distance": distance,
                    }
                )
    records.sort(key=lambda record: (record["distance"], str(record["taxon"])))
    outside_index = rng.randrange(len(records)) if records and outside_far else None
    for number, record in enumerate(records):
        roll = rng.random()
        offset = rng.uniform(0, 5) * rng.choice([-1, 1])
        if number == outside_index:
            offset = rng.uniform(380, 450) * rng.choice([-1, 1])
            stats["far_outside"] += 1
            anomalies.append(f"{key} observation {number} about {abs(offset):.0f} m away")
        elif roll < HIGH_COUNT_RATE:
            record["count"] = rng.randint(51, 150)
            stats["high_count"] += 1
            anomalies.append(f"{key} observation {number} count {record['count']}")
        elif roll < HIGH_COUNT_RATE + FAR_RATE:
            offset = rng.uniform(40, 150) * rng.choice([-1, 1])
            stats["far"] += 1
            anomalies.append(f"{key} observation {number} {abs(offset):.0f} m from the line")
        confidence_roll = rng.random()
        record["confidence"] = (
            "confirmed_in_field"
            if confidence_roll < 0.80
            else "probable"
            if confidence_roll < 0.95
            else "photo_required"
        )
        record["offset"] = offset
        record["behaviour"] = list(dict.fromkeys(rng.sample(BEHAVIOURS, rng.randint(1, 2))))
        record["sex"] = rng.choice(["male", "female", "unknown"])
        record["at"] = started + timedelta(seconds=int(record["distance"] / walk.speed_m_s))
        lon, lat = walker.offset_lonlat(record["distance"], record["offset"])
        record["lon"], record["lat"] = round(lon, 7), round(lat, 7)
        record["accuracy"] = walk.accuracy_m
    if planted:
        _plant_reproductive(ctx, slot, infos, records)
    return records


def _plant_reproductive(ctx, slot, infos, records):
    """Reproductive behaviour is likelier in the sections of the chosen habitat type (Q4)."""
    rng = stream(ctx, slot.transect.code, slot.index, "planted", "repro")
    for record in records:
        info = next((i for i in infos if i.lo <= record["distance"] <= i.hi), None)
        code = info.habitat_code if info else "unknown"
        if rng.random() < ctx.planted.reproductive_probability(code):
            record["behaviour"] = [rng.choice(planted_effects.REPRODUCTIVE_BEHAVIOURS)]


def _observation_mutation(ctx, key, number, observation_id, visit_id, record):
    payload = {
        "id": str(observation_id),
        "project": str(ctx.project.id),
        "survey_visit": str(visit_id),
        "transect_section": None,  # the server assigns the nearest section (T048)
        "observed_at": iso(record["at"]),
        "taxon": str(record["taxon"]),
        "count": record["count"],
        "location_accuracy_m": f"{record['accuracy']:.1f}",
        "identification_confidence": record["confidence"],
        "recorded_by": ctx.researcher_id,
        "sex": record["sex"],
        "life_stage": "adult",
        "behaviour": record["behaviour"],
        "source": "transect",
        "geometry": {"type": "Point", "coordinates": [record["lon"], record["lat"]]},
        "created_at": iso(record["at"]),
    }
    return mutation(
        ctx,
        "butterfly_observation",
        "create",
        observation_id,
        payload,
        record["at"],
        f"{key}:obs:{number}",
    )


def _photo_mutation(ctx, key, number, photo_id, observation_id, record):
    placeholder = ctx.placeholder
    when = record["at"] + timedelta(seconds=20)
    payload = {
        "id": str(photo_id),
        "observation": str(observation_id),
        "plant_resource": None,
        "local_path": "simulated/placeholder.jpg",
        "mime_type": placeholder.mime_type,
        "file_size": placeholder.size,
        "sha256": placeholder.sha256,
        "width": placeholder.width,
        "height": placeholder.height,
        "captured_at": iso(when),
        "is_primary": True,
        "created_at": iso(when),
    }
    return mutation(ctx, "photo", "create", photo_id, payload, when, f"{key}:photo:{number}")


def _square(walker, cx, cy, side):
    half = side / 2
    ring = [
        (cx - half, cy - half),
        (cx + half, cy - half),
        (cx + half, cy + half),
        (cx - half, cy + half),
    ]
    ring = [[round(c, 7) for c in walker.to_lonlat(x, y)] for x, y in ring]
    return {"type": "Polygon", "coordinates": [[*ring, ring[0]]]}


def _plants_and_habitats(ctx, slot, walker, infos, walk, started, visit_id):
    key = slot.key
    rng = stream(ctx, slot.transect.code, slot.index, "extras")
    out, plants, habitats = [], 0, 0
    for number in range(rng.randint(3, 4)):
        distance = rng.uniform(0, walk.walked_m)
        offset = rng.uniform(3, 15) * rng.choice([-1, 1])
        x, y, ux, uy = walker.position(distance)
        cx, cy = x - uy * offset, y + ux * offset
        if rng.random() < 0.5:
            geometry = {
                "type": "Point",
                "coordinates": [round(c, 7) for c in walker.to_lonlat(cx, cy)],
            }
        else:
            geometry = _square(walker, cx, cy, rng.uniform(10, 30))
        when = started + timedelta(seconds=int(distance / walk.speed_m_s))
        plant_id = uid(ctx, "plant", f"{key}:{number}")
        payload = {
            "id": str(plant_id),
            "project": str(ctx.project.id),
            "survey_visit": str(visit_id),
            "plant_taxon": str(rng.choice(ctx.plant_taxa)),
            "resource_type": rng.choice(
                [
                    "larval_host",
                    "nectar_source",
                    "nectar_source",
                    "oviposition_plant",
                    "resting_plant",
                ]
            ),
            "observed_at": iso(when),
            "geometry": geometry,
            "abundance_class": rng.choice(["1", "2-10", "11-100"]),
            "phenology_stage": rng.choice(["budding", "flowering", "flowering", "fruiting"]),
            "flowering_intensity": rng.choice(["low", "medium", "high"]),
            "created_at": iso(when),
        }
        out.append(
            mutation(
                ctx,
                "plant_resource_observation",
                "create",
                plant_id,
                payload,
                when,
                f"{key}:plant:{number}",
            )
        )
        plants += 1
    # A habitat feature needs a habitat type: only sections that have one can host it.
    typed = [i for i in infos if i.habitat_type_id]
    habitat_count = 0 if ctx.planted else (rng.randint(2, 3) if typed else 0)
    if ctx.planted:
        # One polygon per typed section (Q4): records near the line fall in their section's polygon.
        margin = (1 - planted_effects.POLYGON_SHARE) / 2
        half = planted_effects.POLYGON_HALF_WIDTH_M
        for number, info in enumerate(typed):
            lo = info.lo + (info.hi - info.lo) * margin
            hi = min(info.hi - (info.hi - info.lo) * margin, walker.length)
            ring = [
                walker.offset_lonlat(lo, half),
                walker.offset_lonlat(hi, half),
                walker.offset_lonlat(hi, -half),
                walker.offset_lonlat(lo, -half),
            ]
            ring = [[round(lon, 7), round(lat, 7)] for lon, lat in ring]
            geometry = {"type": "Polygon", "coordinates": [[*ring, ring[0]]]}
            out.append(
                _habitat_mutation(
                    ctx,
                    key,
                    number,
                    info,
                    geometry,
                    rng,
                    min((lo + hi) / 2, walk.walked_m),
                    walk,
                    started,
                    visit_id,
                )
            )
            habitats += 1
    for number in range(habitat_count):
        distance = rng.uniform(0, walk.walked_m)
        info = next((i for i in typed if i.lo <= distance <= i.hi), typed[0])
        shape = rng.choice(["point", "line", "polygon"])
        x, y, ux, uy = walker.position(distance)
        length = rng.uniform(30, 100)
        if shape == "point":
            geometry = {
                "type": "Point",
                "coordinates": [round(c, 7) for c in walker.to_lonlat(x, y)],
            }
        elif shape == "line":
            coords = [
                walker.offset_lonlat(min(walker.length, distance + length * s / 3), 4.0)
                for s in range(4)
            ]
            geometry = {
                "type": "LineString",
                "coordinates": [[round(lon, 7), round(lat, 7)] for lon, lat in coords],
            }
        else:
            width = rng.uniform(15, 30)
            end_d = min(walker.length, distance + length)
            ring = [
                walker.offset_lonlat(distance, width / 2),
                walker.offset_lonlat(end_d, width / 2),
                walker.offset_lonlat(end_d, -width / 2),
                walker.offset_lonlat(distance, -width / 2),
            ]
            ring = [[round(lon, 7), round(lat, 7)] for lon, lat in ring]
            geometry = {"type": "Polygon", "coordinates": [[*ring, ring[0]]]}
        out.append(
            _habitat_mutation(
                ctx, key, number, info, geometry, rng, distance, walk, started, visit_id
            )
        )
        habitats += 1
    if ctx.planted:
        extra = _planted_patches(ctx, slot, walker, infos, walk, started, visit_id)
        out.extend(extra)
        plants += len(extra)
    return {"mutations": out, "plants": plants, "habitats": habitats}


def _habitat_mutation(ctx, key, number, info, geometry, rng, distance, walk, started, visit_id):
    when = started + timedelta(seconds=int(distance / walk.speed_m_s))
    feature_id = uid(ctx, "habitat", f"{key}:{number}")
    payload = {
        "id": str(feature_id),
        "project": str(ctx.project.id),
        "survey_visit": str(visit_id),
        "habitat_type": info.habitat_type_id,
        "management_type": info.management_type_id,
        "observed_at": iso(when),
        "geometry": geometry,
        "vegetation_height_cm": rng.randint(10, 80),
        "shrub_cover_pct": rng.randint(0, 40),
        "tree_cover_pct": rng.randint(0, 30),
        "bare_ground_pct": rng.randint(0, 20),
        "flower_abundance_class": rng.choice(["low", "medium", "high"]),
        "grazing_intensity": rng.choice(["none", "low", "medium"]),
        "mowing_status": rng.choice(["unmown", "recently_mown", "mown_this_season"]),
        "disturbance_type": "none",
        "created_at": iso(when),
    }
    return mutation(
        ctx, "habitat_feature", "create", feature_id, payload, when, f"{key}:habitat:{number}"
    )


def _planted_patches(ctx, slot, walker, infos, walk, started, visit_id):
    """Larval host-plant patches next to the host sections (Q3), all well inside 50 m."""
    key = slot.key
    rng = stream(ctx, slot.transect.code, slot.index, "planted", "patches")
    planted = ctx.planted
    out, counter = [], 0
    for section_index in sorted(planted.host_sections[slot.transect.code]):
        info = infos[section_index]
        for number in range(planted_effects.PATCHES_PER_HOST_SECTION):
            distance = rng.uniform(info.lo, max(info.lo, min(info.hi, walk.walked_m)))
            offset = rng.uniform(5, 20) * rng.choice([-1, 1])
            x, y, ux, uy = walker.position(distance)
            geometry = _square(walker, x - uy * offset, y + ux * offset, rng.uniform(10, 20))
            plant_id, _ = planted.host_plants[counter % len(planted.host_plants)]
            counter += 1
            when = started + timedelta(seconds=int(distance / walk.speed_m_s))
            record_id = uid(ctx, "plant", f"{key}:host:{section_index}:{number}")
            payload = {
                "id": str(record_id),
                "project": str(ctx.project.id),
                "survey_visit": str(visit_id),
                "plant_taxon": str(plant_id),
                "resource_type": "larval_host",
                "observed_at": iso(when),
                "geometry": geometry,
                "abundance_class": rng.choice(planted_effects.PATCH_ABUNDANCE_CLASSES),
                "phenology_stage": rng.choice(["budding", "flowering", "flowering", "fruiting"]),
                "flowering_intensity": rng.choice(["low", "medium", "high"]),
                "created_at": iso(when),
            }
            out.append(
                mutation(
                    ctx,
                    "plant_resource_observation",
                    "create",
                    record_id,
                    payload,
                    when,
                    f"{key}:plant:host:{section_index}:{number}",
                )
            )
    return out
