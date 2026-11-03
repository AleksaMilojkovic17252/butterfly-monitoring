"""OGC view for plant records (T067, T051), read by pygeoapi_ro from schema geo.

`plant_scientific_name` is empty for an unidentified plant. `geometry_type` says POINT or
POLYGON, so a client can tell the two apart in one collection. `geometry` is exposed unchanged so
a bbox filter can use the table's GiST index (D-078).
"""

from django.db import migrations

from apps.core.migration_ops import CreateView

_PLANT_RESOURCES = """
SELECT r.id, r.project_id, r.survey_visit_id, r.observed_at,
       pt.scientific_name AS plant_scientific_name,
       r.resource_type, r.abundance_class, r.patch_area_m2, r.phenology_stage,
       r.flowering_intensity, r.eggs_present, r.larvae_present, r.feeding_damage_present,
       GeometryType(r.geometry) AS geometry_type, r.geometry
FROM public.plant_resource_observation r
JOIN public.project p ON p.id = r.project_id
LEFT JOIN public.plant_taxon pt ON pt.id = r.plant_taxon_id
WHERE r.deleted_at IS NULL AND p.deleted_at IS NULL
"""


class Migration(migrations.Migration):

    dependencies = [
        ('catalogues', '0003_history_version_index'),
        ('core', '0001_schemas'),
        ('projects', '0006_historicalprojectprotocol_time_zone_and_more'),
        ('resources', '0001_initial'),
    ]

    operations = [
        CreateView("geo.plant_resources", _PLANT_RESOURCES),
    ]
