from django.db import migrations

from apps.core.migration_ops import HistoryVersionIndex


class Migration(migrations.Migration):

    dependencies = [
        ("transects", "0002_section_unique_live_only"),
    ]

    operations = [
        HistoryVersionIndex("historical_transect"),
        HistoryVersionIndex("historical_transect_section"),
    ]
