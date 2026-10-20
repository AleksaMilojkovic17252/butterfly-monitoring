from django.db import migrations

from apps.core.migration_ops import HistoryVersionIndex


class Migration(migrations.Migration):

    dependencies = [
        ("projects", "0004_historicalproject_taxon_list_version_and_more"),
    ]

    operations = [
        HistoryVersionIndex("historical_project"),
        HistoryVersionIndex("historical_project_protocol"),
    ]
