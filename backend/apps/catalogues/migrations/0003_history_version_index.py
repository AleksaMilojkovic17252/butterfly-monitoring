from django.db import migrations

from apps.core.migration_ops import HistoryVersionIndex


class Migration(migrations.Migration):

    dependencies = [
        ("catalogues", "0002_plant_taxon_and_codelists"),
    ]

    operations = [
        HistoryVersionIndex("historical_taxon"),
        HistoryVersionIndex("historical_plant_taxon"),
        HistoryVersionIndex("historical_habitat_type"),
        HistoryVersionIndex("historical_management_type"),
    ]
