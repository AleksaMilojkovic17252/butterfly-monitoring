"""Remove the T007 walking skeleton: the view first (it reads the table), then the table."""

from django.db import migrations

from apps.core.migration_ops import CreateView

_VIEW = "geo.skeleton_pings"
_VIEW_SELECT = "SELECT id, observed_at, note, geometry FROM public.skeleton_ping"


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0003_skeleton_ping'),
    ]

    operations = [
        # Reversing recreates the view; pygeoapi_ro gets its SELECT from the schema's default
        # privileges (0001_schemas), as it did for CreateView in 0003.
        migrations.RunSQL(
            sql=f"DROP VIEW IF EXISTS {_VIEW}",
            reverse_sql=CreateView(_VIEW, _VIEW_SELECT).sql,
        ),
        migrations.DeleteModel(name='SkeletonPing'),
    ]
