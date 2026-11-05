"""The valid-visit rule of protocol §6 (T100, D-095) as one view, reused by T061 and T101.

In `public`, not `geo`, and with no grant to `pygeoapi_ro`. The view reads columns of
`survey_visit` and `project_protocol`: changing one needs a hand-written migration that drops and
recreates it.
"""

from django.db import migrations

from apps.core.migration_ops import CreateView

# Raw string: the regex has `\S`.
SQL = r"""
SELECT v.id AS survey_visit_id, cardinality(r.reasons) = 0 AS is_valid, r.reasons
FROM survey_visit v
JOIN project_protocol p ON p.project_id = v.project_id
CROSS JOIN LATERAL (
  SELECT coalesce(bool_and(
           (v.precipitation = 'none' OR p.allow_precipitation)
           AND w.wind <= p.max_wind_beaufort
           AND (w.temp >= p.sunny_temperature_c
                OR (w.temp >= p.min_temperature_c AND w.cloud <= p.max_cloud_cover_pct_if_cool))
         ), false) AS within
  FROM (VALUES (v.temperature_start_c, v.wind_beaufort_start, v.cloud_cover_start_pct),
               (v.temperature_end_c, v.wind_beaufort_end, v.cloud_cover_end_pct)) AS w(temp, wind, cloud)
  WHERE w.temp IS NOT NULL AND w.wind IS NOT NULL AND w.cloud IS NOT NULL
) weather
CROSS JOIN LATERAL (
  SELECT array_remove(ARRAY[
    CASE WHEN v.status = 'cancelled' THEN 'cancelled'
         WHEN v.status NOT IN ('completed', 'synced', 'reviewed', 'locked') THEN 'not_finished' END,
    CASE WHEN NOT weather.within AND v.weather_missing_reason !~ '\S' THEN 'weather' END,
    CASE WHEN v.route_coverage_pct IS NULL THEN 'no_coverage'
         WHEN v.route_coverage_pct < p.min_coverage_pct THEN 'low_coverage' END
  ]::text[], NULL) AS reasons
) r
WHERE v.deleted_at IS NULL
"""


class Migration(migrations.Migration):
    dependencies = [
        ("surveys", "0005_historicalsurveyvisit_route_coverage_pct_and_more"),
        ("projects", "0006_historicalprojectprotocol_time_zone_and_more"),
    ]

    operations = [CreateView("public.survey_visit_validity", SQL)]
