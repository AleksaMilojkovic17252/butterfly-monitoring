"""Q3 `report_specialist_host_plants` without its `&&` bounding-box prefilter (T102, D-111).

On the simulated season the prefilter made the planner scan the GiST index of
`plant_resource_observation` under a nested loop, 4-5 times slower than the plain exact test
(55 against 14 ms at scale 10; `evaluation/results/spatial-indexes.md`). The exact `ST_DWithin` on
geography stays, so the rows are the same. The view's columns are unchanged, so the unmanaged
model needs no state change. Nothing depends on the view and it has no grant (D-110), so it is
dropped and recreated.
"""

from importlib import import_module

from django.db import migrations

_PREFILTER = """   AND plant_record.geometry && ST_Expand(section_year.geometry,
         {RADIUS_M} * 1.2 / (111320 * cos(radians(ST_Y(ST_Centroid(section_year.geometry))))))
"""
_VIEW = "public.report_specialist_host_plants"


def _sql():
    """The 0003 definition (before) and the same without the prefilter (after)."""
    before = import_module(
        "apps.reports.migrations.0003_research_questions"
    ).SPECIALIST_HOST_PLANTS_SQL
    prefilter = _PREFILTER.replace("{RADIUS_M}", "50")
    if before.count(prefilter) != 1:
        raise RuntimeError("The Q3 prefilter was not found in 0003 exactly once")
    return before, before.replace(prefilter, "")


def _replace(sql):
    return f"DROP VIEW {_VIEW}; CREATE VIEW {_VIEW} AS {sql}"


class Migration(migrations.Migration):
    dependencies = [("reports", "0003_research_questions")]

    operations = [
        migrations.RunSQL(sql=_replace(_sql()[1]), reverse_sql=_replace(_sql()[0])),
    ]
