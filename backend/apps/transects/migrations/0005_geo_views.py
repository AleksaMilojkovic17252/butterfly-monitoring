"""OGC views for transects and their sections (T067), read by pygeoapi_ro from schema geo.

Soft-deleted rows are hidden, and so are rows whose transect or project is soft-deleted (D-078).
`geometry` is exposed unchanged so a bbox filter can use the table's GiST index.
"""

from django.db import migrations

from apps.core.migration_ops import CreateView

_TRANSECTS = """
SELECT t.id, t.project_id, p.name AS project_name, t.code, t.name, t.description,
       t.target_length_m, round(ST_Length(t.geometry::geography)::numeric, 1) AS length_m,
       t.habitat_summary, t.active,
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
       round(ST_Length(s.geometry::geography)::numeric, 1) AS length_m, s.notes, s.geometry
FROM public.transect_section s
JOIN public.transect t ON t.id = s.transect_id
JOIN public.project p ON p.id = t.project_id
LEFT JOIN public.habitat_type h ON h.id = s.habitat_type_id
LEFT JOIN public.management_type m ON m.id = s.management_type_id
WHERE s.deleted_at IS NULL AND t.deleted_at IS NULL AND p.deleted_at IS NULL
"""


class Migration(migrations.Migration):

    dependencies = [
        ('catalogues', '0003_history_version_index'),
        ('core', '0001_schemas'),
        ('projects', '0006_historicalprojectprotocol_time_zone_and_more'),
        ('transects', '0004_export_help_text'),
    ]

    operations = [
        CreateView("geo.transects", _TRANSECTS),
        CreateView("geo.transect_sections", _SECTIONS),
    ]
