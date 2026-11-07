"""OGC view `geo.observation_hexgrid` (T101 Q6, D-110): observations per hexagon, per project.

Hexagons of `HEX_SIZE_M` (the **edge length**, as `ST_HexagonGrid` takes it) in the project's UTM
zone, so the cells are the same in metres everywhere. `ST_HexagonGrid` aligns its cells to the origin
of the reference system, so cell (`i`, `j`) is the same whatever the bounds are; the bounds only
decide which cells are generated (the extent of the project's live records). Empty cells drop out of
the inner join. Records outside the study area still count.

The zone is the one of the project's study area, or of its records when there is no area (the rule of
`apps.core.geo.utm_srid`, written inline because a `geo` view must not depend on an object in
`public`, D-004). A point exactly on a shared edge counts in both cells (rare).

Records: live, and with no visit or a visit that is neither deleted nor cancelled (D-099.4).
The hexagons are joined to `butterfly_observation` directly (not through a CTE) so that the GiST
index on its geometry is used (`&&` on the transformed hexagon, then the exact test in UTM).
"""

from django.db import migrations

from apps.core.migration_ops import CreateView

HEX_SIZE_M = 100


def utm_zone_epsg_sql(g):
    return (
        f"((CASE WHEN ST_Y(ST_Centroid({g})) >= 0 THEN 32600 ELSE 32700 END)"
        f" + (floor((ST_X(ST_Centroid({g})) + 180) / 6)::int % 60) + 1)"
    )


OBSERVATION_HEXGRID_SQL = f"""
WITH project_extent AS (
  SELECT observation.project_id, ST_Extent(observation.geometry)::geometry AS box
  FROM public.butterfly_observation observation
  WHERE observation.deleted_at IS NULL
  GROUP BY observation.project_id
),
project_zone AS (
  SELECT project.id AS project_id, project.name AS project_name,
         {utm_zone_epsg_sql("coalesce(project.area, project_extent.box)")} AS srid
  FROM public.project project
  JOIN project_extent ON project_extent.project_id = project.id
  WHERE project.deleted_at IS NULL
),
project_bounds AS (
  SELECT zone.project_id, zone.project_name, zone.srid,
         ST_SetSRID(ST_Extent(ST_Transform(observation.geometry, zone.srid))::geometry, zone.srid)
           AS box
  FROM project_zone zone
  JOIN public.butterfly_observation observation
    ON observation.project_id = zone.project_id AND observation.deleted_at IS NULL
  GROUP BY zone.project_id, zone.project_name, zone.srid
),
hexagon AS (
  SELECT bounds.project_id, bounds.project_name, bounds.srid, cell.i, cell.j, cell.geom
  FROM project_bounds bounds
  CROSS JOIN LATERAL ST_HexagonGrid({HEX_SIZE_M}, bounds.box) cell
)
SELECT hexagon.project_id::text || ':' || hexagon.i || ':' || hexagon.j AS id,
       hexagon.project_id, hexagon.project_name, {HEX_SIZE_M} AS hex_size_m,
       count(*) AS observations,
       sum(observation.count)::int AS individuals,
       count(DISTINCT coalesce(observation.validated_taxon_id, observation.taxon_id)) AS species,
       count(*) FILTER (WHERE 'nectaring' = ANY(observation.behaviour)) AS nectaring_records,
       count(*) FILTER (
         WHERE observation.behaviour && ARRAY['courtship', 'mating', 'oviposition']::varchar[]
            OR observation.life_stage IN ('egg', 'larva', 'pupa')
       ) AS reproductive_records,
       ST_Transform(hexagon.geom, 4326) AS geometry
FROM hexagon
JOIN public.butterfly_observation observation
  ON observation.project_id = hexagon.project_id
 AND observation.deleted_at IS NULL
 AND observation.geometry && ST_Transform(hexagon.geom, 4326)
 AND ST_Intersects(hexagon.geom, ST_Transform(observation.geometry, hexagon.srid))
LEFT JOIN public.survey_visit visit ON visit.id = observation.survey_visit_id
WHERE observation.survey_visit_id IS NULL
   OR (visit.deleted_at IS NULL AND visit.status <> 'cancelled')
GROUP BY hexagon.project_id, hexagon.project_name, hexagon.i, hexagon.j, hexagon.geom
"""


class Migration(migrations.Migration):
    dependencies = [
        ("observations", "0006_geo_observations_linear_ref"),
        ("projects", "0008_historicalproject_closed_at_and_more"),
        ("surveys", "0006_survey_visit_validity"),
    ]

    operations = [
        CreateView("geo.observation_hexgrid", OBSERVATION_HEXGRID_SQL),
    ]
