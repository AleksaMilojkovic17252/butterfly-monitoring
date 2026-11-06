"""Linear referencing on the OGC sections view (T103, D-105).

`geo.transect_sections` gains `start_m` and `end_m`: where the section starts and ends, in metres
along the transect. Both are planar, in the transect's own UTM zone (D-046), the same zone rule as
`apps.core.geo.utm_srid` (centroid of the transect line), written inline because a `geo` view must
not depend on an object in `public` (D-004). A section drawn against the line's direction gets
LEAST / GREATEST so `start_m <= end_m`. Views only: nothing is stored.
"""

from django.db import migrations

from apps.core.migration_ops import CreateView

# Verbatim from 0005_geo_views, for the reverse.
_OLD_SECTIONS = """
SELECT s.id, s.transect_id, t.code AS transect_code, s.section_code, s.sequence_number,
       h.code AS habitat_type_code, h.name_en AS habitat_type_name_en,
       m.code AS management_type_code, m.name_en AS management_type_name_en,
       round(ST_Length(s.geometry::geography)::numeric, 1) AS length_m, s.notes, s.geometry
FROM public.transect_section s
JOIN public.transect t ON t.id = s.transect_id
JOIN public.project p ON p.id = t.project_id
LEFT JOIN public.habitat_type h ON h.id = s.habitat_type_id
LEFT JOIN public.management_type m ON m.id = s.management_type_id
WHERE s.deleted_at IS NULL AND t.deleted_at IS NULL AND p.deleted_at IS NULL
"""

_SECTIONS = """
SELECT s.id, s.transect_id, t.code AS transect_code, s.section_code, s.sequence_number,
       h.code AS habitat_type_code, h.name_en AS habitat_type_name_en,
       m.code AS management_type_code, m.name_en AS management_type_name_en,
       round(ST_Length(s.geometry::geography)::numeric, 1) AS length_m, s.notes,
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

    dependencies = [
        ("transects", "0006_transect_proposal"),
    ]

    operations = [
        migrations.RunSQL(
            "DROP VIEW geo.transect_sections",
            reverse_sql="CREATE VIEW geo.transect_sections AS " + _OLD_SECTIONS,
        ),
        CreateView("geo.transect_sections", _SECTIONS),
    ]
