"""OGC view for butterfly observations (T067), read by pygeoapi_ro from schema geo.

`behaviour` and `quality_flags` become comma-separated text: array attributes are poorly supported
by OGC API Features clients and QGIS. `taxon_*` is the taxon as recorded, `effective_*` the
validated taxon when one is set. `geometry` is exposed unchanged so a bbox filter can use the
table's GiST index (D-078).
"""

from django.conf import settings
from django.db import migrations

from apps.core.migration_ops import CreateView

# recorded_by_name is exposed because pygeoapi is admin-only (T069); remove it if pygeoapi is ever
# made public.
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


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('catalogues', '0003_history_version_index'),
        ('core', '0001_schemas'),
        ('observations', '0003_export_help_text'),
        ('projects', '0006_historicalprojectprotocol_time_zone_and_more'),
        ('surveys', '0004_export_help_text'),
        ('transects', '0004_export_help_text'),
    ]

    operations = [
        CreateView("geo.butterfly_observations", _OBSERVATIONS),
    ]
