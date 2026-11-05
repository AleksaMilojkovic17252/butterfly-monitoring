"""The indicator views of T061 (D-099): transect indicators, species phenology, behaviour counts.

The views are in `public`, with no grant to `pygeoapi_ro`, and never `security_invoker`. They read
columns of `survey_visit`, `butterfly_observation`, `project_protocol`, `transect` and
`survey_visit_validity`: changing one of those needs a hand-written migration that drops and
recreates the views.
"""

from django.db import migrations, models

from apps.core.migration_ops import CreateView

# Year and ISO week are in the project's time zone (D-094): a visit at 23:30 UTC on 31 December is
# on 1 January at the study site.

TRANSECT_INDICATORS_SQL = """
WITH v AS (
  SELECT sv.id, sv.project_id, sv.transect_id,
         extract(year FROM sv.started_at AT TIME ZONE pp.time_zone)::int AS year,
         coalesce(sv.duration_seconds, 0) AS duration_s,
         coalesce(sv.distance_walked_m, 0) AS distance_m,
         sv.zero_observation_confirmed,
         coalesce(vv.is_valid, false) AS is_valid
  FROM survey_visit sv
  JOIN project_protocol pp ON pp.project_id = sv.project_id
  LEFT JOIN survey_visit_validity vv ON vv.survey_visit_id = sv.id
  WHERE sv.deleted_at IS NULL AND sv.status IN ('completed', 'synced', 'reviewed', 'locked')
),
per_visit AS (
  -- One row per visit, so duration and distance are not counted once per observation.
  SELECT v.id, v.project_id, v.transect_id, v.year, v.duration_s, v.distance_m,
         v.zero_observation_confirmed, v.is_valid,
         coalesce(sum(o.count), 0) AS individuals,
         count(o.id) AS observations,
         count(o.id) FILTER (WHERE o.validation_status = 'confirmed') AS confirmed_obs,
         count(o.id) FILTER (WHERE o.validation_status = 'pending') AS to_review_obs
  FROM v
  LEFT JOIN butterfly_observation o
         ON o.survey_visit_id = v.id AND o.deleted_at IS NULL AND o.source = 'transect'
  GROUP BY v.id, v.project_id, v.transect_id, v.year, v.duration_s, v.distance_m,
           v.zero_observation_confirmed, v.is_valid
),
species AS (
  SELECT v.transect_id, v.year,
         count(DISTINCT coalesce(o.validated_taxon_id, o.taxon_id)) AS species_count
  FROM v
  JOIN butterfly_observation o
         ON o.survey_visit_id = v.id AND o.deleted_at IS NULL AND o.source = 'transect'
  GROUP BY v.transect_id, v.year
)
SELECT pv.transect_id::text || ':' || pv.year AS row_id,
       pv.project_id, pv.transect_id, t.code AS transect_code, pv.year,
       count(*) AS visits_completed,
       count(*) FILTER (WHERE pv.zero_observation_confirmed) AS true_zero_visits,
       count(*) FILTER (WHERE pv.is_valid) AS valid_visits,
       round(sum(pv.duration_s) / 3600.0, 2) AS total_hours,
       round(sum(pv.distance_m) / 1000.0, 2) AS total_km,
       coalesce(max(s.species_count), 0) AS species_count,
       sum(pv.individuals) AS individuals,
       sum(pv.observations) AS observations,
       sum(pv.confirmed_obs) AS confirmed_obs,
       sum(pv.to_review_obs) AS to_review_obs,
       max(pp.target_visits_per_season) AS target_visits,
       round(sum(pv.individuals) / nullif(sum(pv.distance_m) / 1000.0, 0), 2) AS individuals_per_km,
       round(sum(pv.individuals) / nullif(sum(pv.duration_s) / 3600.0, 0), 2)
         AS individuals_per_hour
FROM per_visit pv
JOIN transect t ON t.id = pv.transect_id
JOIN project_protocol pp ON pp.project_id = pv.project_id
LEFT JOIN species s ON s.transect_id = pv.transect_id AND s.year = pv.year
GROUP BY pv.project_id, pv.transect_id, t.code, pv.year
"""

# Records of any source, free records (no visit, D-096) included; deleted records and those of a
# cancelled or deleted visit are left out.
_RECORDS = """
SELECT o.id, o.project_id, coalesce(o.validated_taxon_id, o.taxon_id) AS taxon_id, o.count,
       o.behaviour, o.life_stage, o.observed_at AT TIME ZONE pp.time_zone AS local_time
FROM butterfly_observation o
JOIN project_protocol pp ON pp.project_id = o.project_id
LEFT JOIN survey_visit sv ON sv.id = o.survey_visit_id
WHERE o.deleted_at IS NULL
  AND (o.survey_visit_id IS NULL OR (sv.deleted_at IS NULL AND sv.status <> 'cancelled'))
"""

SPECIES_PHENOLOGY_SQL = f"""
WITH rec AS ({_RECORDS})
SELECT rec.project_id::text || ':' || rec.taxon_id::text || ':'
         || extract(isoyear FROM rec.local_time)::int || '-' || extract(week FROM rec.local_time)::int
         AS row_id,
       rec.project_id, rec.taxon_id,
       extract(isoyear FROM rec.local_time)::int AS year,
       extract(week FROM rec.local_time)::int AS iso_week,
       sum(rec.count) AS individuals,
       count(*) AS observations,
       min(rec.local_time::date) AS first_date,
       max(rec.local_time::date) AS last_date
FROM rec
GROUP BY rec.project_id, rec.taxon_id,
         extract(isoyear FROM rec.local_time), extract(week FROM rec.local_time)
"""

BEHAVIOUR_COUNTS_SQL = f"""
WITH rec AS ({_RECORDS}),
rows AS (
  SELECT rec.id, rec.project_id, extract(year FROM rec.local_time)::int AS year, b.behaviour
  FROM rec
  CROSS JOIN LATERAL (SELECT DISTINCT unnest(rec.behaviour) AS behaviour) b
  UNION ALL
  -- The synthetic row: courtship, mating, oviposition, or an egg, larva or pupa.
  SELECT rec.id, rec.project_id, extract(year FROM rec.local_time)::int, 'reproductive'
  FROM rec
  WHERE rec.behaviour && ARRAY['courtship', 'mating', 'oviposition']::varchar[]
     OR rec.life_stage IN ('egg', 'larva', 'pupa')
)
SELECT rows.project_id::text || ':' || rows.year || ':' || rows.behaviour AS row_id,
       rows.project_id, rows.year, rows.behaviour, count(*) AS records
FROM rows
GROUP BY rows.project_id, rows.year, rows.behaviour
"""


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ("surveys", "0006_survey_visit_validity"),
        ("observations", "0005_plant_links"),
        ("projects", "0006_historicalprojectprotocol_time_zone_and_more"),
        ("transects", "0006_transect_proposal"),
        ("catalogues", "0003_history_version_index"),
    ]

    operations = [
        migrations.CreateModel(
            name='BehaviourCounts',
            fields=[
                ('row_id', models.CharField(help_text='Project, year and behaviour, joined', max_length=120, primary_key=True, serialize=False)),
                ('year', models.IntegerField(help_text="Calendar year, in the project's time zone")),
                ('behaviour', models.CharField(help_text="Behaviour value; 'reproductive' counts courtship, mating, oviposition and egg, larva or pupa records", max_length=40)),
                ('records', models.IntegerField(help_text='Observation records with this behaviour')),
            ],
            options={
                'verbose_name': 'behaviour counts',
                'verbose_name_plural': 'behaviour counts',
                'db_table': 'report_behaviour_counts',
                'managed': False,
            },
        ),
        migrations.CreateModel(
            name='SpeciesPhenology',
            fields=[
                ('row_id', models.CharField(help_text='Project, taxon and ISO year-week, joined with colons', max_length=120, primary_key=True, serialize=False)),
                ('year', models.IntegerField(help_text="ISO year of the week, in the project's time zone")),
                ('iso_week', models.IntegerField(help_text='ISO week number (1-53)')),
                ('individuals', models.IntegerField(help_text='Individuals counted in the week')),
                ('observations', models.IntegerField(help_text='Observation records in the week')),
                ('first_date', models.DateField(help_text='First day with a record in the week (local date)')),
                ('last_date', models.DateField(help_text='Last day with a record in the week (local date)')),
            ],
            options={
                'verbose_name': 'species phenology',
                'verbose_name_plural': 'species phenology',
                'db_table': 'report_species_phenology',
                'managed': False,
            },
        ),
        migrations.CreateModel(
            name='TransectIndicators',
            fields=[
                ('row_id', models.CharField(help_text='Transect id and year, joined with a colon', max_length=80, primary_key=True, serialize=False)),
                ('transect_code', models.CharField(help_text='Short transect code', max_length=20)),
                ('year', models.IntegerField(help_text="Calendar year of the visits, in the project's time zone")),
                ('visits_completed', models.IntegerField(help_text='Finished visits (completed or later)')),
                ('true_zero_visits', models.IntegerField(help_text='Finished visits confirmed to have seen no butterflies')),
                ('valid_visits', models.IntegerField(help_text='Finished visits that meet the valid-visit rule (weather, coverage)')),
                ('total_hours', models.DecimalField(decimal_places=2, help_text='Total walking time, hours', max_digits=8)),
                ('total_km', models.DecimalField(decimal_places=2, help_text='Total distance walked, kilometres', max_digits=8)),
                ('species_count', models.IntegerField(help_text='Distinct species on transect records')),
                ('individuals', models.IntegerField(help_text='Individuals counted on transect records')),
                ('observations', models.IntegerField(help_text='Transect observation records')),
                ('confirmed_obs', models.IntegerField(help_text='Transect records confirmed by a validator')),
                ('to_review_obs', models.IntegerField(help_text='Transect records still pending validation')),
                ('target_visits', models.IntegerField(help_text='Target visits per season (project protocol)')),
                ('individuals_per_km', models.DecimalField(decimal_places=2, help_text='Individuals per kilometre walked; empty when no distance was walked', max_digits=8, null=True)),
                ('individuals_per_hour', models.DecimalField(decimal_places=2, help_text='Individuals per hour walked; empty when no time was recorded', max_digits=8, null=True)),
            ],
            options={
                'verbose_name': 'transect indicators',
                'verbose_name_plural': 'transect indicators',
                'db_table': 'report_transect_indicators',
                'managed': False,
            },
        ),
        CreateView("public.report_transect_indicators", TRANSECT_INDICATORS_SQL),
        CreateView("public.report_species_phenology", SPECIES_PHENOLOGY_SQL),
        CreateView("public.report_behaviour_counts", BEHAVIOUR_COUNTS_SQL),
    ]
