"""Add `survey_visit_id` to geo.habitat_features, as geo.plant_resources has it, so a GIS user can
join a habitat feature to its visit (T053 review). The column goes after `project_id`, so the view
is dropped and created again: CREATE OR REPLACE VIEW can only append columns. Reversing puts the
0004 view back. pygeoapi reads a view's columns at start, so restart it after this migration.
"""

from django.db import migrations

from apps.core.migration_ops import CreateView

_OLD_VIEW = """
SELECT f.id, f.project_id, f.observed_at,
       ht.code AS habitat_type_code, ht.name_en AS habitat_type_name_en,
       mt.code AS management_type_code,
       f.vegetation_height_cm, f.shrub_cover_pct, f.tree_cover_pct, f.bare_ground_pct,
       f.flower_abundance_class, f.grazing_intensity, f.mowing_status, f.disturbance_type,
       GeometryType(f.geometry) AS geometry_type, f.geometry
FROM public.habitat_feature f
JOIN public.project p ON p.id = f.project_id
JOIN public.habitat_type ht ON ht.id = f.habitat_type_id
LEFT JOIN public.management_type mt ON mt.id = f.management_type_id
WHERE f.deleted_at IS NULL AND p.deleted_at IS NULL
"""

_NEW_VIEW = """
SELECT f.id, f.project_id, f.survey_visit_id, f.observed_at,
       ht.code AS habitat_type_code, ht.name_en AS habitat_type_name_en,
       mt.code AS management_type_code,
       f.vegetation_height_cm, f.shrub_cover_pct, f.tree_cover_pct, f.bare_ground_pct,
       f.flower_abundance_class, f.grazing_intensity, f.mowing_status, f.disturbance_type,
       GeometryType(f.geometry) AS geometry_type, f.geometry
FROM public.habitat_feature f
JOIN public.project p ON p.id = f.project_id
JOIN public.habitat_type ht ON ht.id = f.habitat_type_id
LEFT JOIN public.management_type mt ON mt.id = f.management_type_id
WHERE f.deleted_at IS NULL AND p.deleted_at IS NULL
"""


class Migration(migrations.Migration):

    dependencies = [
        ('resources', '0004_habitat_geo_view'),
    ]

    operations = [
        migrations.RunSQL(
            sql="DROP VIEW geo.habitat_features",
            reverse_sql=f"CREATE VIEW geo.habitat_features AS {_OLD_VIEW}",
        ),
        CreateView("geo.habitat_features", _NEW_VIEW),
    ]
