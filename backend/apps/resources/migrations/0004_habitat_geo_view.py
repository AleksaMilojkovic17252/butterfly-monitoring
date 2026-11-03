"""OGC view for habitat features (T067, T053), read by pygeoapi_ro from schema geo.

The habitat type is joined for its code and English name; the management type may be empty. A
record keeps its codelist value when the value is soft-deleted, so the codelists are not filtered
on `deleted_at`. `geometry` is exposed unchanged so a bbox filter can use the table's GiST index
(D-078).
"""

from django.db import migrations

from apps.core.migration_ops import CreateView

_HABITAT_FEATURES = """
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


class Migration(migrations.Migration):

    dependencies = [
        ('catalogues', '0003_history_version_index'),
        ('core', '0001_schemas'),
        ('projects', '0006_historicalprojectprotocol_time_zone_and_more'),
        ('resources', '0003_habitat_feature'),
    ]

    operations = [
        CreateView("geo.habitat_features", _HABITAT_FEATURES),
    ]
