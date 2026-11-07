"""`created_at` on the OGC transect views (T070, D-113), so pygeoapi can set `time_field`.

`geo.transects` and `geo.transect_sections` gain `created_at`, the row's own creation time. CITE
requires every collection to advertise `datetime`, and pygeoapi only does that for a collection with
a `time_field`. Views only: nothing is stored. The SQL is written out in full (the earlier SQL is
only used for the reverse).
"""

from importlib import import_module

from django.db import migrations

from apps.core.migration_ops import CreateView

# The reverse: the views as 0005 and 0007 left them.
_OLD_TRANSECTS = import_module("apps.transects.migrations.0005_geo_views")._TRANSECTS
_OLD_SECTIONS = import_module("apps.transects.migrations.0007_geo_sections_linear_ref")._SECTIONS

_TRANSECTS = """
SELECT t.id, t.project_id, p.name AS project_name, t.code, t.name, t.description,
       t.target_length_m, round(ST_Length(t.geometry::geography)::numeric, 1) AS length_m,
       t.habitat_summary, t.active, t.created_at,
       (SELECT count(*) FROM public.transect_section s
        WHERE s.transect_id = t.id AND s.deleted_at IS NULL) AS section_count,
       t.geometry
FROM public.transect t
JOIN public.project p ON p.id = t.project_id
WHERE t.deleted_at IS NULL AND p.deleted_at IS NULL
"""

_SECTIONS = """
SELECT s.id, s.transect_id, t.code AS transect_code, s.section_code, s.sequence_number,
       h.code AS habitat_type_code, h.name_en AS habitat_type_name_en,
       m.code AS management_type_code, m.name_en AS management_type_name_en,
       round(ST_Length(s.geometry::geography)::numeric, 1) AS length_m, s.notes, s.created_at,
       round((LEAST(loc.a, loc.b) * ST_Length(tu.g))::numeric, 1) AS start_m,
       round((GREATEST(loc.a, loc.b) * ST_Length(tu.g))::numeric, 1) AS end_m,
       s.geometry
FROM public.transect_section s
JOIN public.transect t ON t.id = s.transect_id
JOIN public.project p ON p.id = t.project_id
CROSS JOIN LATERAL (SELECT ST_Transform(t.geometry,
    (CASE WHEN ST_Y(ST_Centroid(t.geometry)) >= 0 THEN 32600 ELSE 32700 END)
    + (floor((ST_X(ST_Centroid(t.geometry)) + 180) / 6)::int % 60) + 1) AS g) tu
CROSS JOIN LATERAL (SELECT
    ST_LineLocatePoint(tu.g, ST_Transform(ST_StartPoint(s.geometry), ST_SRID(tu.g))) AS a,
    ST_LineLocatePoint(tu.g, ST_Transform(ST_EndPoint(s.geometry), ST_SRID(tu.g))) AS b) loc
LEFT JOIN public.habitat_type h ON h.id = s.habitat_type_id
LEFT JOIN public.management_type m ON m.id = s.management_type_id
WHERE s.deleted_at IS NULL AND t.deleted_at IS NULL AND p.deleted_at IS NULL
"""


class Migration(migrations.Migration):
    dependencies = [("transects", "0007_geo_sections_linear_ref")]

    operations = [
        migrations.RunSQL(
            "DROP VIEW geo.transects",
            reverse_sql="CREATE VIEW geo.transects AS " + _OLD_TRANSECTS,
        ),
        CreateView("geo.transects", _TRANSECTS),
        migrations.RunSQL(
            "DROP VIEW geo.transect_sections",
            reverse_sql="CREATE VIEW geo.transect_sections AS " + _OLD_SECTIONS,
        ),
        CreateView("geo.transect_sections", _SECTIONS),
    ]
