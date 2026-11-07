"""`last_observed_at` on `geo.observation_hexgrid` (T070, D-113), so pygeoapi can set `time_field`.

The newest `observed_at` among the records counted in the hexagon. A hexagon is computed, not
stored, so it has no creation time; this is the one time that belongs to it.
Views only: nothing is stored. The SQL is written out in full (0007's is only used for the reverse).
"""

# ruff: noqa: E501  (the SQL below holds one generated long line)
from importlib import import_module

from django.db import migrations

from apps.core.migration_ops import CreateView

_OLD = import_module(
    "apps.observations.migrations.0007_geo_observation_hexgrid"
).OBSERVATION_HEXGRID_SQL

_NEW = """
WITH project_extent AS (
  SELECT observation.project_id, ST_Extent(observation.geometry)::geometry AS box
  FROM public.butterfly_observation observation
  WHERE observation.deleted_at IS NULL
  GROUP BY observation.project_id
),
project_zone AS (
  SELECT project.id AS project_id, project.name AS project_name,
         ((CASE WHEN ST_Y(ST_Centroid(coalesce(project.area, project_extent.box))) >= 0 THEN 32600 ELSE 32700 END) + (floor((ST_X(ST_Centroid(coalesce(project.area, project_extent.box))) + 180) / 6)::int % 60) + 1) AS srid
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
  CROSS JOIN LATERAL ST_HexagonGrid(100, bounds.box) cell
)
SELECT hexagon.project_id::text || ':' || hexagon.i || ':' || hexagon.j AS id,
       hexagon.project_id, hexagon.project_name, 100 AS hex_size_m,
       count(*) AS observations,
       sum(observation.count)::int AS individuals,
       count(DISTINCT coalesce(observation.validated_taxon_id, observation.taxon_id)) AS species,
       count(*) FILTER (WHERE 'nectaring' = ANY(observation.behaviour)) AS nectaring_records,
       count(*) FILTER (
         WHERE observation.behaviour && ARRAY['courtship', 'mating', 'oviposition']::varchar[]
            OR observation.life_stage IN ('egg', 'larva', 'pupa')
       ) AS reproductive_records,
       max(observation.observed_at) AS last_observed_at,
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
    dependencies = [("observations", "0007_geo_observation_hexgrid")]

    operations = [
        migrations.RunSQL(
            "DROP VIEW geo.observation_hexgrid",
            reverse_sql="CREATE VIEW geo.observation_hexgrid AS " + _OLD,
        ),
        CreateView("geo.observation_hexgrid", _NEW),
    ]
