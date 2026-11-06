"""The abundance profile along the transect (T103, D-105): `public.report_transect_profile`.

One row per transect x year x 50 m bin, zero bins included. The view reads
`geo.butterfly_observations` (`distance_along_m`, so there is one definition of the position):
a later change to that view must drop and recreate this view too. No grant to `pygeoapi_ro`.

`BIN_M` is also the column `bin_m`. Length and positions are planar, in the transect's UTM zone
(D-046; the zone rule of `apps.core.geo.utm_srid`). Years are in the project's time zone, as in
`report_transect_indicators` (D-099).
"""

from django.db import migrations, models

from apps.core.migration_ops import CreateView

BIN_M = 50

TRANSECT_PROFILE_SQL = f"""
WITH visits AS (
  SELECT sv.id, sv.project_id, sv.transect_id,
         extract(year FROM sv.started_at AT TIME ZONE pp.time_zone)::int AS year
  FROM survey_visit sv
  JOIN project_protocol pp ON pp.project_id = sv.project_id
  WHERE sv.deleted_at IS NULL AND sv.status IN ('completed', 'synced', 'reviewed', 'locked')
),
dims AS (
  SELECT d.project_id, d.transect_id, d.year, t.code AS transect_code,
         len.m AS length_m, greatest(ceil(len.m / {BIN_M})::int, 1) AS n_bins
  FROM (SELECT DISTINCT project_id, transect_id, year FROM visits) d
  JOIN transect t ON t.id = d.transect_id
  CROSS JOIN LATERAL (SELECT ST_Length(ST_Transform(t.geometry,
      (CASE WHEN ST_Y(ST_Centroid(t.geometry)) >= 0 THEN 32600 ELSE 32700 END)
      + (floor((ST_X(ST_Centroid(t.geometry)) + 180) / 6)::int % 60) + 1))::numeric AS m) len
),
bins AS (
  SELECT dims.*, k FROM dims CROSS JOIN LATERAL generate_series(0, dims.n_bins - 1) k
),
recs AS MATERIALIZED (
  -- MATERIALIZED: the planner guesses one row for this join and would otherwise run the whole
  -- observations view once per transect-year (3 s instead of 0.04 s on the dev data).
  -- The clamp puts a record exactly at the end of the line into the last bin.
  SELECT visits.transect_id, visits.year, bo.count, bo.effective_scientific_name,
         least(floor(bo.distance_along_m / {BIN_M})::int, dims.n_bins - 1) AS k
  FROM geo.butterfly_observations bo
  JOIN visits ON visits.id = bo.survey_visit_id
  JOIN dims ON dims.transect_id = visits.transect_id AND dims.year = visits.year
  WHERE bo.distance_along_m IS NOT NULL
)
SELECT b.transect_id::text || ':' || b.year || ':' || (b.k * {BIN_M}) AS row_id,
       b.project_id, b.transect_id, b.transect_code, b.year,
       {BIN_M} AS bin_m, b.k * {BIN_M} AS bin_start_m,
       least((b.k + 1) * {BIN_M}, round(b.length_m, 1)) AS bin_end_m,
       count(r.k) AS observations,
       coalesce(sum(r.count), 0)::int AS individuals,
       count(DISTINCT r.effective_scientific_name) AS species
FROM bins b
LEFT JOIN recs r ON r.transect_id = b.transect_id AND r.year = b.year AND r.k = b.k
GROUP BY b.project_id, b.transect_id, b.transect_code, b.year, b.k, b.length_m
"""


class Migration(migrations.Migration):

    dependencies = [
        ('reports', '0001_initial'),
        ('observations', '0006_geo_observations_linear_ref'),
        ('transects', '0007_geo_sections_linear_ref'),
    ]

    operations = [
        migrations.CreateModel(
            name='TransectProfile',
            fields=[
                ('row_id', models.CharField(help_text='Transect id, year and bin start, joined with colons', max_length=120, primary_key=True, serialize=False)),
                ('transect_code', models.CharField(help_text='Short transect code', max_length=20)),
                ('year', models.IntegerField(help_text="Calendar year of the visits, in the project's time zone")),
                ('bin_m', models.IntegerField(help_text='Bin width, metres along the transect')),
                ('bin_start_m', models.IntegerField(help_text='Metres along the transect where the bin starts')),
                ('bin_end_m', models.DecimalField(decimal_places=1, help_text='Metres along the transect where the bin ends (the last bin stops at the end)', max_digits=8)),
                ('observations', models.IntegerField(help_text='Transect observation records in the bin')),
                ('individuals', models.IntegerField(help_text='Individuals counted in the bin')),
                ('species', models.IntegerField(help_text='Distinct species recorded in the bin')),
            ],
            options={
                'verbose_name': 'transect profile',
                'verbose_name_plural': 'transect profile',
                'db_table': 'report_transect_profile',
                'managed': False,
            },
        ),
        CreateView("public.report_transect_profile", TRANSECT_PROFILE_SQL),
    ]
