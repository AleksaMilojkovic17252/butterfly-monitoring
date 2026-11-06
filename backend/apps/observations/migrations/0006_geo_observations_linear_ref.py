"""Linear referencing on the OGC observations view (T103, D-105).

`geo.butterfly_observations` gains two columns for transect records (`source = 'transect'` with a
visit); every other record gets nulls:

- `distance_along_m`: metres along the visit's transect, planar in the transect's UTM zone
  (D-046; the zone rule of `apps.core.geo.utm_srid`, written inline because a `geo` view must not
  depend on an object in `public`, D-004).
- `offset_m`: metres from the transect line, **geodesic** (`::geography`). This is the same
  measure as T056's `far_from_transect` (protocol.md section 5), so `offset_m` greater than
  `max_distance_from_transect_m` exactly when the flag applies.

`public.report_transect_profile` (reports/0002) reads this view: a later change to the view
must drop and recreate that report view too.
"""

from django.conf import settings
from django.db import migrations

from apps.core.migration_ops import CreateView

# Verbatim from 0004_geo_views, for the reverse.
_OLD_OBSERVATIONS = """
SELECT o.id, o.project_id, p.name AS project_name, o.survey_visit_id,
       t.code AS transect_code, s.section_code, o.observed_at, o.source,
       tx.scientific_name AS taxon_scientific_name,
       tx.vernacular_name_en AS taxon_vernacular_name_en,
       tx.vernacular_name_sr AS taxon_vernacular_name_sr,
       COALESCE(vt.scientific_name, tx.scientific_name) AS effective_scientific_name,
       COALESCE(vt.family, tx.family) AS effective_family,
       o.count, o.sex, o.life_stage,
       array_to_string(o.behaviour, ',') AS behaviour,
       o.identification_confidence, o.validation_status, o.location_accuracy_m,
       array_to_string(o.quality_flags, ',') AS quality_flags,
       u.name AS recorded_by_name, tlv.version_label AS taxon_list_version, o.geometry
FROM public.butterfly_observation o
JOIN public.project p ON p.id = o.project_id
JOIN public.taxon tx ON tx.id = o.taxon_id
LEFT JOIN public.taxon vt ON vt.id = o.validated_taxon_id
LEFT JOIN public.taxon_list_version tlv ON tlv.id = p.taxon_list_version_id
LEFT JOIN public.survey_visit v ON v.id = o.survey_visit_id
LEFT JOIN public.transect t ON t.id = v.transect_id
LEFT JOIN public.transect_section s ON s.id = o.transect_section_id
JOIN public.app_user u ON u.id = o.recorded_by_id
WHERE o.deleted_at IS NULL AND p.deleted_at IS NULL
"""

_OBSERVATIONS = """
SELECT o.id, o.project_id, p.name AS project_name, o.survey_visit_id,
       t.code AS transect_code, s.section_code, o.observed_at, o.source,
       tx.scientific_name AS taxon_scientific_name,
       tx.vernacular_name_en AS taxon_vernacular_name_en,
       tx.vernacular_name_sr AS taxon_vernacular_name_sr,
       COALESCE(vt.scientific_name, tx.scientific_name) AS effective_scientific_name,
       COALESCE(vt.family, tx.family) AS effective_family,
       o.count, o.sex, o.life_stage,
       array_to_string(o.behaviour, ',') AS behaviour,
       o.identification_confidence, o.validation_status, o.location_accuracy_m,
       array_to_string(o.quality_flags, ',') AS quality_flags,
       u.name AS recorded_by_name, tlv.version_label AS taxon_list_version,
       lr.distance_along_m, lr.offset_m, o.geometry
FROM public.butterfly_observation o
JOIN public.project p ON p.id = o.project_id
JOIN public.taxon tx ON tx.id = o.taxon_id
LEFT JOIN public.taxon vt ON vt.id = o.validated_taxon_id
LEFT JOIN public.taxon_list_version tlv ON tlv.id = p.taxon_list_version_id
LEFT JOIN public.survey_visit v ON v.id = o.survey_visit_id
LEFT JOIN public.transect t ON t.id = v.transect_id
LEFT JOIN public.transect_section s ON s.id = o.transect_section_id
JOIN public.app_user u ON u.id = o.recorded_by_id
LEFT JOIN LATERAL (
  SELECT round((ST_LineLocatePoint(tu.g, ST_Transform(o.geometry, ST_SRID(tu.g)))
                * ST_Length(tu.g))::numeric, 1) AS distance_along_m,
         round(ST_Distance(t.geometry::geography, o.geometry::geography)::numeric, 1) AS offset_m
  FROM (SELECT ST_Transform(t.geometry,
          (CASE WHEN ST_Y(ST_Centroid(t.geometry)) >= 0 THEN 32600 ELSE 32700 END)
          + (floor((ST_X(ST_Centroid(t.geometry)) + 180) / 6)::int % 60) + 1) AS g) tu
  WHERE o.source = 'transect' AND t.id IS NOT NULL
) lr ON true
WHERE o.deleted_at IS NULL AND p.deleted_at IS NULL
"""


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("observations", "0005_plant_links"),
        ("transects", "0007_geo_sections_linear_ref"),
    ]

    operations = [
        migrations.RunSQL(
            "DROP VIEW geo.butterfly_observations",
            reverse_sql="CREATE VIEW geo.butterfly_observations AS " + _OLD_OBSERVATIONS,
        ),
        CreateView("geo.butterfly_observations", _OBSERVATIONS),
    ]
