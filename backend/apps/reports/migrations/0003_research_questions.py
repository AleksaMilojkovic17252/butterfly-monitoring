"""Research-question views Q1, Q3 and Q4 (T101, D-110): habitat richness, specialists and their host
plants, reproductive microhabitat. Q6 is `geo.observation_hexgrid` in `observations/0007`.

The views are in `public`, with no grant to `pygeoapi_ro`, and never `security_invoker`. A column
change in a source table needs a hand-written migration that drops and recreates them. They read:

- Q1 `report_habitat_richness`: `survey_visit`, `survey_visit_validity`, `project_protocol`,
  `transect`, `transect_section`, `habitat_type`, `butterfly_observation`, `habitat_feature`.
- Q3 `report_specialist_host_plants`: the same visit tables, `transect`, `transect_section`,
  `butterfly_observation`, `plant_resource_observation`, `taxon_host_plant`, `plant_taxon`.
- Q4 `report_reproductive_microhabitat`: `habitat_feature`, `habitat_type`, `survey_visit`,
  `butterfly_observation`.

Metres are in UTM (the zone rule of `apps.core.geo.utm_srid`, written in SQL by `utm_zone_epsg_sql`, D-105). Years are in the
project's time zone (D-099). Valid visits come from `survey_visit_validity` (D-095). The effective
taxon is `coalesce(validated_taxon_id, taxon_id)`.
"""

import django.contrib.gis.db.models.fields
from django.db import migrations, models

from apps.core.migration_ops import CreateView

RADIUS_M = 50  # Q3: a host-plant patch counts when within this distance of the section


def utm_zone_epsg_sql(g):
    return (
        f"((CASE WHEN ST_Y(ST_Centroid({g})) >= 0 THEN 32600 ELSE 32700 END)"
        f" + (floor((ST_X(ST_Centroid({g})) + 180) / 6)::int % 60) + 1)"
    )


_IS_REPRODUCTIVE = (
    "(observation.behaviour && ARRAY['courtship', 'mating', 'oviposition']::varchar[]"
    " OR observation.life_stage IN ('egg', 'larva', 'pupa'))"
)

# Records outside a transect walk (D-099.4): live, and no visit or a visit that is neither deleted
# nor cancelled. Needs `LEFT JOIN survey_visit visit ON visit.id = observation.survey_visit_id`.
_RECORDS_RULE = (
    "observation.deleted_at IS NULL"
    " AND (observation.survey_visit_id IS NULL"
    " OR (visit.deleted_at IS NULL AND visit.status <> 'cancelled'))"
)

_LIVE_POLYGON = (
    "feature.deleted_at IS NULL"
    " AND ST_GeometryType(feature.geometry) IN ('ST_Polygon', 'ST_MultiPolygon')"
)

_VALID_VISITS = """
  SELECT visit.id, visit.project_id, visit.transect_id,
         extract(year FROM visit.started_at AT TIME ZONE protocol.time_zone)::int AS year
  FROM survey_visit visit
  JOIN survey_visit_validity validity ON validity.survey_visit_id = visit.id AND validity.is_valid
  JOIN project_protocol protocol ON protocol.project_id = visit.project_id
  WHERE visit.deleted_at IS NULL
"""

# ---- Q1 ------------------------------------------------------------------------------------------
# Transect side: records of valid visits take the habitat of their section (null section or null
# habitat: unknown). Incidental side: records of any other source take the habitat of the live
# polygon that contains them (the latest `observed_at`, then the smallest id), else unknown.
# Each side is aggregated on its own, so nothing is counted twice.
HABITAT_RICHNESS_SQL = f"""
WITH valid_visit AS ({_VALID_VISITS}),
live_section AS (
  SELECT section.id AS section_id, section.transect_id, section.habitat_type_id,
         coalesce(habitat_type.code, 'unknown') AS habitat_code,
         ST_Length(ST_Transform(section.geometry, {utm_zone_epsg_sql("transect.geometry")})) / 1000.0
           AS length_km
  FROM transect_section section
  JOIN transect ON transect.id = section.transect_id
  LEFT JOIN habitat_type ON habitat_type.id = section.habitat_type_id
  WHERE section.deleted_at IS NULL
),
visit_section AS (
  -- One row per valid visit x live section of the visit's transect.
  SELECT valid_visit.id AS visit_id, valid_visit.project_id, valid_visit.year,
         live_section.section_id, live_section.habitat_type_id, live_section.habitat_code,
         live_section.length_km
  FROM valid_visit
  JOIN live_section ON live_section.transect_id = valid_visit.transect_id
),
effort_by_habitat AS (
  SELECT project_id, habitat_type_id, habitat_code, year,
         count(DISTINCT visit_id) AS valid_visits, sum(length_km) AS effort_km
  FROM visit_section GROUP BY project_id, habitat_type_id, habitat_code, year
),
sections_by_habitat AS (
  SELECT project_id, habitat_type_id, habitat_code, year,
         count(*) AS sections, sum(length_km) AS section_km
  FROM (SELECT DISTINCT project_id, habitat_type_id, habitat_code, year, section_id, length_km
        FROM visit_section) distinct_sections
  GROUP BY project_id, habitat_type_id, habitat_code, year
),
habitat_records AS (
  SELECT valid_visit.project_id, valid_visit.year, section.habitat_type_id,
         coalesce(habitat_type.code, 'unknown') AS habitat_code,
         'transect' AS side, observation.count,
         coalesce(observation.validated_taxon_id, observation.taxon_id) AS taxon_id
  FROM valid_visit
  JOIN butterfly_observation observation
    ON observation.survey_visit_id = valid_visit.id AND observation.deleted_at IS NULL
   AND observation.source = 'transect'
  LEFT JOIN transect_section section ON section.id = observation.transect_section_id
  LEFT JOIN habitat_type ON habitat_type.id = section.habitat_type_id
  UNION ALL
  SELECT observation.project_id,
         extract(year FROM observation.observed_at AT TIME ZONE protocol.time_zone)::int,
         containing_polygon.habitat_type_id, coalesce(habitat_type.code, 'unknown'),
         'incidental', observation.count,
         coalesce(observation.validated_taxon_id, observation.taxon_id)
  FROM butterfly_observation observation
  JOIN project_protocol protocol ON protocol.project_id = observation.project_id
  LEFT JOIN survey_visit visit ON visit.id = observation.survey_visit_id
  LEFT JOIN LATERAL (
    SELECT feature.habitat_type_id
    FROM habitat_feature feature
    WHERE feature.project_id = observation.project_id AND feature.deleted_at IS NULL
      AND ST_GeometryType(feature.geometry) IN ('ST_Polygon', 'ST_MultiPolygon')
      AND ST_Intersects(feature.geometry, observation.geometry)
    ORDER BY feature.observed_at DESC, feature.id
    LIMIT 1
  ) containing_polygon ON true
  LEFT JOIN habitat_type ON habitat_type.id = containing_polygon.habitat_type_id
  WHERE observation.source <> 'transect' AND {_RECORDS_RULE}
),
records_by_habitat AS (
  SELECT project_id, habitat_type_id, habitat_code, year,
         count(DISTINCT taxon_id) AS species,
         count(DISTINCT taxon_id) FILTER (WHERE side = 'transect') AS transect_species,
         coalesce(sum(count) FILTER (WHERE side = 'transect'), 0)::int AS transect_individuals,
         count(*) FILTER (WHERE side = 'transect') AS transect_records,
         coalesce(sum(count) FILTER (WHERE side = 'incidental'), 0)::int AS incidental_individuals,
         count(*) FILTER (WHERE side = 'incidental') AS incidental_records
  FROM habitat_records GROUP BY project_id, habitat_type_id, habitat_code, year
),
habitat_year AS (
  -- Every project x habitat x year that has effort or records.
  SELECT project_id, habitat_type_id, habitat_code, year FROM effort_by_habitat
  UNION SELECT project_id, habitat_type_id, habitat_code, year FROM sections_by_habitat
  UNION SELECT project_id, habitat_type_id, habitat_code, year FROM records_by_habitat
)
SELECT habitat_year.project_id::text || ':' || habitat_year.habitat_code || ':'
         || habitat_year.year AS row_id,
       habitat_year.project_id, habitat_year.habitat_type_id, habitat_year.habitat_code,
       habitat_year.year,
       coalesce(sections_by_habitat.sections, 0) AS sections,
       round(coalesce(sections_by_habitat.section_km, 0)::numeric, 3) AS section_km,
       coalesce(effort_by_habitat.valid_visits, 0) AS valid_visits,
       round(coalesce(effort_by_habitat.effort_km, 0)::numeric, 3) AS effort_km,
       coalesce(records_by_habitat.species, 0) AS species,
       coalesce(records_by_habitat.transect_species, 0) AS transect_species,
       coalesce(records_by_habitat.transect_records, 0) AS transect_records,
       coalesce(records_by_habitat.transect_individuals, 0) AS transect_individuals,
       coalesce(records_by_habitat.incidental_records, 0) AS incidental_records,
       coalesce(records_by_habitat.incidental_individuals, 0) AS incidental_individuals,
       coalesce(records_by_habitat.transect_individuals, 0)
         + coalesce(records_by_habitat.incidental_individuals, 0) AS individuals,
       round(records_by_habitat.transect_individuals
             / nullif(effort_by_habitat.effort_km, 0)::numeric, 2) AS individuals_per_km
FROM habitat_year
LEFT JOIN effort_by_habitat USING (project_id, habitat_code, year)
LEFT JOIN sections_by_habitat USING (project_id, habitat_code, year)
LEFT JOIN records_by_habitat USING (project_id, habitat_code, year)
"""

# ---- Q3 ------------------------------------------------------------------------------------------
# A specialist species is one whose host plants are all in a single plant genus. A patch counts for
# the host plants of any specialist species (not only those seen in that section), in the
# section's year.
_ABUNDANCE_CLASS_MIDPOINT = """CASE plant_record.abundance_class
           WHEN '1' THEN 1 WHEN '2-10' THEN 6 WHEN '11-100' THEN 55.5
           WHEN '101-1000' THEN 550.5 WHEN '>1000' THEN 1000 END"""

SPECIALIST_HOST_PLANTS_SQL = f"""
WITH specialist_species AS (
  SELECT host.taxon_id
  FROM taxon_host_plant host JOIN plant_taxon plant ON plant.id = host.plant_taxon_id
  GROUP BY host.taxon_id
  HAVING count(DISTINCT split_part(plant.scientific_name, ' ', 1)) = 1
),
specialist_host_plant AS (
  SELECT DISTINCT host.plant_taxon_id
  FROM taxon_host_plant host
  JOIN specialist_species ON specialist_species.taxon_id = host.taxon_id
),
valid_visit AS ({_VALID_VISITS}),
section_year AS (
  -- One row per live section and year in which its transect had a valid visit.
  SELECT section.id AS section_id, section.transect_id, transect.project_id,
         transect.code AS transect_code, section.section_code, section.geometry,
         valid_visit.year, count(DISTINCT valid_visit.id) AS valid_visits
  FROM transect_section section
  JOIN transect ON transect.id = section.transect_id
  JOIN valid_visit ON valid_visit.transect_id = section.transect_id
  WHERE section.deleted_at IS NULL
  GROUP BY section.id, section.transect_id, transect.project_id, transect.code,
           section.section_code, section.geometry, valid_visit.year
),
specialist_records AS (
  SELECT observation.transect_section_id AS section_id, valid_visit.year,
         sum(observation.count)::int AS individuals,
         count(DISTINCT coalesce(observation.validated_taxon_id, observation.taxon_id)) AS species
  FROM valid_visit
  JOIN butterfly_observation observation
    ON observation.survey_visit_id = valid_visit.id AND observation.deleted_at IS NULL
   AND observation.source = 'transect' AND observation.transect_section_id IS NOT NULL
  WHERE coalesce(observation.validated_taxon_id, observation.taxon_id)
        IN (SELECT taxon_id FROM specialist_species)
  GROUP BY observation.transect_section_id, valid_visit.year
),
host_patch_counts AS (
  -- The bounding-box test uses the GiST index; the geography test is exact, in metres.
  SELECT section_year.section_id, section_year.year, count(plant_record.id) AS patches,
         sum({_ABUNDANCE_CLASS_MIDPOINT}) AS abundance
  FROM section_year
  JOIN project_protocol protocol ON protocol.project_id = section_year.project_id
  JOIN plant_resource_observation plant_record
    ON plant_record.project_id = section_year.project_id AND plant_record.deleted_at IS NULL
   AND plant_record.resource_type = 'larval_host'
   AND plant_record.plant_taxon_id IN (SELECT plant_taxon_id FROM specialist_host_plant)
   AND extract(year FROM plant_record.observed_at AT TIME ZONE protocol.time_zone)::int
       = section_year.year
   AND plant_record.geometry && ST_Expand(section_year.geometry,
         {RADIUS_M} * 1.2 / (111320 * cos(radians(ST_Y(ST_Centroid(section_year.geometry))))))
   AND ST_DWithin(plant_record.geometry::geography, section_year.geometry::geography, {RADIUS_M})
  LEFT JOIN survey_visit plant_visit ON plant_visit.id = plant_record.survey_visit_id
  WHERE plant_record.survey_visit_id IS NULL
     OR (plant_visit.deleted_at IS NULL AND plant_visit.status <> 'cancelled')
  GROUP BY section_year.section_id, section_year.year
)
SELECT section_year.section_id::text || ':' || section_year.year AS row_id,
       section_year.project_id, section_year.transect_id, section_year.section_id,
       section_year.transect_code, section_year.section_code, section_year.year,
       {RADIUS_M} AS radius_m,
       section_year.valid_visits,
       coalesce(specialist_records.individuals, 0) AS specialist_species_individuals,
       coalesce(specialist_records.species, 0) AS specialist_species,
       round(coalesce(specialist_records.individuals, 0)::numeric / section_year.valid_visits, 2)
         AS specialist_species_per_visit,
       coalesce(host_patch_counts.patches, 0) AS host_patches,
       round(coalesce(host_patch_counts.abundance, 0)::numeric, 1) AS host_abundance_mid
FROM section_year
LEFT JOIN specialist_records
  ON specialist_records.section_id = section_year.section_id
 AND specialist_records.year = section_year.year
LEFT JOIN host_patch_counts
  ON host_patch_counts.section_id = section_year.section_id
 AND host_patch_counts.year = section_year.year
"""

# ---- Q4 ------------------------------------------------------------------------------------------
# One UTM zone per project (the centroid of all its polygons). Area is the union per type, so
# overlapping polygons of one type count once; overlap between types counts in both. A record in two
# types' polygons counts for both. Jacobs D = (r - p) / (r + p - 2rp).
REPRODUCTIVE_MICROHABITAT_SQL = f"""
WITH habitat_polygon AS NOT MATERIALIZED (
  SELECT feature.id, feature.project_id, feature.habitat_type_id, feature.geometry
  FROM habitat_feature feature
  WHERE {_LIVE_POLYGON}
),
project_zone AS (
  SELECT project_id, {utm_zone_epsg_sql("ST_Collect(geometry)")} AS srid
  FROM habitat_polygon GROUP BY project_id
),
area_by_habitat_type AS (
  SELECT polygon.project_id, polygon.habitat_type_id, count(*) AS polygons,
         ST_Area(ST_Union(ST_MakeValid(ST_Transform(polygon.geometry, zone.srid)))) AS area_m2
  FROM habitat_polygon polygon
  JOIN project_zone zone ON zone.project_id = polygon.project_id
  GROUP BY polygon.project_id, polygon.habitat_type_id
),
reproductive_record AS NOT MATERIALIZED (
  SELECT observation.id, observation.project_id, observation.geometry
  FROM butterfly_observation observation
  LEFT JOIN survey_visit visit ON visit.id = observation.survey_visit_id
  WHERE {_RECORDS_RULE} AND {_IS_REPRODUCTIVE}
),
records_in_habitat_type AS (
  SELECT record.project_id, polygon.habitat_type_id, count(DISTINCT record.id) AS repro_records
  FROM reproductive_record record
  JOIN habitat_polygon polygon
    ON polygon.project_id = record.project_id AND ST_Intersects(polygon.geometry, record.geometry)
  GROUP BY record.project_id, polygon.habitat_type_id
),
records_in_any_polygon AS (
  SELECT record.project_id, count(DISTINCT record.id) AS repro_records
  FROM reproductive_record record
  JOIN habitat_polygon polygon
    ON polygon.project_id = record.project_id AND ST_Intersects(polygon.geometry, record.geometry)
  GROUP BY record.project_id
),
selection_share AS (
  SELECT area.project_id, area.habitat_type_id, area.polygons, area.area_m2,
         coalesce(in_type.repro_records, 0) AS repro_records,
         coalesce(in_any.repro_records, 0) AS project_repro_records,
         coalesce(in_type.repro_records, 0)::numeric / nullif(in_any.repro_records, 0)
           AS record_share,
         (area.area_m2 / nullif(sum(area.area_m2) OVER (PARTITION BY area.project_id), 0))::numeric
           AS area_share
  FROM area_by_habitat_type area
  LEFT JOIN records_in_habitat_type in_type
    ON in_type.project_id = area.project_id AND in_type.habitat_type_id = area.habitat_type_id
  LEFT JOIN records_in_any_polygon in_any ON in_any.project_id = area.project_id
)
SELECT share.project_id::text || ':' || habitat_type.code AS row_id,
       share.project_id, share.habitat_type_id, habitat_type.code AS habitat_code, share.polygons,
       round(share.area_m2::numeric, 1) AS area_m2,
       share.repro_records, share.project_repro_records,
       round(share.record_share, 3) AS record_share, round(share.area_share, 3) AS area_share,
       round((share.record_share - share.area_share)
             / nullif(share.record_share + share.area_share
                      - 2 * share.record_share * share.area_share, 0), 3) AS jacobs_d
FROM selection_share share
JOIN habitat_type ON habitat_type.id = share.habitat_type_id
"""


def unmanaged_model(name, table, fields, verbose):
    return migrations.CreateModel(
        name=name,
        fields=fields,
        options={
            "verbose_name": verbose,
            "verbose_name_plural": verbose,
            "db_table": table,
            "managed": False,
        },
    )


def integer_field(help_text):
    return models.IntegerField(help_text=help_text)


def decimal_field(help_text, places, digits=12, null=False):
    return models.DecimalField(
        decimal_places=places, help_text=help_text, max_digits=digits, null=null
    )


class Migration(migrations.Migration):

    dependencies = [
        ("reports", "0002_transect_profile"),
        ("catalogues", "0004_taxon_host_plant"),
        ("observations", "0007_geo_observation_hexgrid"),
        ("resources", "0005_habitat_view_visit"),
        ("surveys", "0006_survey_visit_validity"),
        ("transects", "0007_geo_sections_linear_ref"),
    ]

    operations = [
        unmanaged_model(
            "HabitatRichness",
            "report_habitat_richness",
            [
                ("row_id", models.CharField(help_text="Project, habitat type code and year, joined with colons", max_length=120, primary_key=True, serialize=False)),
                ("habitat_code", models.CharField(help_text="Habitat type code; 'unknown' when a record has no habitat", max_length=30)),
                ("year", integer_field("Calendar year, in the project's time zone")),
                ("sections", integer_field("Live transect sections of this habitat type on transects with a valid visit that year")),
                ("section_km", decimal_field("Total length of those sections, kilometres (UTM)", 3)),
                ("valid_visits", integer_field("Valid visits whose transect has a section of this habitat type")),
                ("effort_km", decimal_field("Walking effort in this habitat type: the section lengths summed over the valid visits, kilometres", 3)),
                ("species", integer_field("Distinct species over transect and incidental records")),
                ("transect_species", integer_field("Distinct species on transect records only")),
                ("transect_records", integer_field("Transect records of valid visits")),
                ("transect_individuals", integer_field("Individuals on transect records")),
                ("incidental_records", integer_field("Records of other sources, in a polygon of this habitat type")),
                ("incidental_individuals", integer_field("Individuals on those records")),
                ("individuals", integer_field("Individuals on transect and incidental records")),
                ("individuals_per_km", decimal_field("Transect individuals per kilometre of effort; empty when there is no effort (incidental records have no effort)", 2, null=True)),
            ],
            "habitat richness",
        ),
        CreateView("public.report_habitat_richness", HABITAT_RICHNESS_SQL),
        unmanaged_model(
            "SpecialistHostPlants",
            "report_specialist_host_plants",
            [
                ("row_id", models.CharField(help_text="Section id and year, joined with a colon", max_length=80, primary_key=True, serialize=False)),
                ("transect_code", models.CharField(help_text="Short transect code", max_length=20)),
                ("section_code", models.CharField(help_text="Section code, unique in the transect", max_length=20)),
                ("year", integer_field("Calendar year of the valid visits, in the project's time zone")),
                ("radius_m", integer_field("Distance within which a host-plant patch counts, metres")),
                ("valid_visits", integer_field("Valid visits of the transect that year")),
                ("specialist_species_individuals", integer_field("Individuals of specialist species on transect records of this section")),
                ("specialist_species", integer_field("Distinct specialist species on those records")),
                ("specialist_species_per_visit", decimal_field("Specialist individuals per valid visit", 2)),
                ("host_patches", integer_field("Larval host-plant patches (of any specialist's host plant) within the radius, same year")),
                ("host_abundance_mid", decimal_field("Sum of the abundance-class midpoints of those patches (>1000 counts as 1000; no class counts 0)", 1)),
            ],
            "specialists and host plants",
        ),
        CreateView("public.report_specialist_host_plants", SPECIALIST_HOST_PLANTS_SQL),
        unmanaged_model(
            "ReproductiveMicrohabitat",
            "report_reproductive_microhabitat",
            [
                ("row_id", models.CharField(help_text="Project and habitat type code, joined with a colon", max_length=120, primary_key=True, serialize=False)),
                ("habitat_code", models.CharField(help_text="Habitat type code", max_length=30)),
                ("polygons", integer_field("Live polygon features of this habitat type")),
                ("area_m2", decimal_field("Area of the union of those polygons, square metres (UTM)", 1, digits=14)),
                ("repro_records", integer_field("Reproductive records inside polygons of this type")),
                ("project_repro_records", integer_field("Reproductive records inside polygons of any type in the project")),
                ("record_share", decimal_field("Share of the project's reproductive records (in polygons) that are in this type (r)", 3, digits=8, null=True)),
                ("area_share", decimal_field("Share of the project's polygon area that is this type (p)", 3, digits=8, null=True)),
                ("jacobs_d", decimal_field("Jacobs' selection index (r - p) / (r + p - 2rp): +1 selected, -1 avoided; empty without reproductive records in polygons", 3, digits=8, null=True)),
            ],
            "reproductive microhabitat",
        ),
        CreateView("public.report_reproductive_microhabitat", REPRODUCTIVE_MICROHABITAT_SQL),
        # Q6 is created by observations/0007; this is only Django's unmanaged model over it.
        migrations.CreateModel(
            name="ObservationHexgrid",
            fields=[
                ("id", models.CharField(help_text="Project id and hexagon cell, joined", max_length=100, primary_key=True, serialize=False)),
                ("project_name", models.CharField(help_text="Project name", max_length=200)),
                ("hex_size_m", integer_field("Hexagon edge length, metres")),
                ("observations", integer_field("Observation records in the hexagon")),
                ("individuals", integer_field("Individuals counted in the hexagon")),
                ("species", integer_field("Distinct species recorded in the hexagon")),
                ("nectaring_records", integer_field("Records with the nectaring behaviour")),
                ("reproductive_records", integer_field("Reproductive records (T061 definition)")),
                ("geometry", django.contrib.gis.db.models.fields.PolygonField(help_text="The hexagon, WGS 84", srid=4326)),
            ],
            options={
                "verbose_name": "observation hexagon",
                "verbose_name_plural": "observation hexagons",
                "db_table": 'geo"."observation_hexgrid',
                "managed": False,
            },
        ),
    ]
