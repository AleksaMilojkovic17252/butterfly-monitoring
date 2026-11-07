-- title: Q3 specialist host plants, C2: the view's SQL without its && prefilter
-- tables: butterfly_observation plant_resource_observation
-- source: rewrite of report_specialist_host_plants (backend/apps/reports/migrations/0003_research_questions.py)
-- The view's own definition (pg_get_viewdef at the time of T102) with the conjunct
-- plant_record.geometry && st_expand(section geometry, ...) removed; the exact geography ST_DWithin stays,
-- so the result is the same. Applied by reports/0004 (T102, D-111): since then config B equals this file. Tests whether the prefilter is what makes the planner pick the GiST index.
SELECT * FROM (
WITH specialist_species AS (
         SELECT host.taxon_id
           FROM (taxon_host_plant host
             JOIN plant_taxon plant ON ((plant.id = host.plant_taxon_id)))
          GROUP BY host.taxon_id
         HAVING (count(DISTINCT split_part((plant.scientific_name)::text, ' '::text, 1)) = 1)
        ), specialist_host_plant AS (
         SELECT DISTINCT host.plant_taxon_id
           FROM (taxon_host_plant host
             JOIN specialist_species ON ((specialist_species.taxon_id = host.taxon_id)))
        ), valid_visit AS (
         SELECT visit.id,
            visit.project_id,
            visit.transect_id,
            (EXTRACT(year FROM (visit.started_at AT TIME ZONE protocol.time_zone)))::integer AS year
           FROM ((survey_visit visit
             JOIN survey_visit_validity validity ON (((validity.survey_visit_id = visit.id) AND validity.is_valid)))
             JOIN project_protocol protocol ON ((protocol.project_id = visit.project_id)))
          WHERE (visit.deleted_at IS NULL)
        ), section_year AS (
         SELECT section.id AS section_id,
            section.transect_id,
            transect.project_id,
            transect.code AS transect_code,
            section.section_code,
            section.geometry,
            valid_visit.year,
            count(DISTINCT valid_visit.id) AS valid_visits
           FROM ((transect_section section
             JOIN transect ON ((transect.id = section.transect_id)))
             JOIN valid_visit ON ((valid_visit.transect_id = section.transect_id)))
          WHERE (section.deleted_at IS NULL)
          GROUP BY section.id, section.transect_id, transect.project_id, transect.code, section.section_code, section.geometry, valid_visit.year
        ), specialist_records AS (
         SELECT observation.transect_section_id AS section_id,
            valid_visit.year,
            (sum(observation.count))::integer AS individuals,
            count(DISTINCT COALESCE(observation.validated_taxon_id, observation.taxon_id)) AS species
           FROM (valid_visit
             JOIN butterfly_observation observation ON (((observation.survey_visit_id = valid_visit.id) AND (observation.deleted_at IS NULL) AND ((observation.source)::text = 'transect'::text) AND (observation.transect_section_id IS NOT NULL))))
          WHERE (COALESCE(observation.validated_taxon_id, observation.taxon_id) IN ( SELECT specialist_species.taxon_id
                   FROM specialist_species))
          GROUP BY observation.transect_section_id, valid_visit.year
        ), host_patch_counts AS (
         SELECT section_year_1.section_id,
            section_year_1.year,
            count(plant_record.id) AS patches,
            sum(
                CASE plant_record.abundance_class
                    WHEN '1'::text THEN (1)::numeric
                    WHEN '2-10'::text THEN (6)::numeric
                    WHEN '11-100'::text THEN 55.5
                    WHEN '101-1000'::text THEN 550.5
                    WHEN '>1000'::text THEN (1000)::numeric
                    ELSE NULL::numeric
                END) AS abundance
           FROM (((section_year section_year_1
             JOIN project_protocol protocol ON ((protocol.project_id = section_year_1.project_id)))
             JOIN plant_resource_observation plant_record ON (((plant_record.project_id = section_year_1.project_id) AND (plant_record.deleted_at IS NULL) AND ((plant_record.resource_type)::text = 'larval_host'::text) AND (plant_record.plant_taxon_id IN ( SELECT specialist_host_plant.plant_taxon_id
                   FROM specialist_host_plant)) AND ((EXTRACT(year FROM (plant_record.observed_at AT TIME ZONE protocol.time_zone)))::integer = section_year_1.year) AND st_dwithin((plant_record.geometry)::geography, (section_year_1.geometry)::geography, (50)::double precision))))
             LEFT JOIN survey_visit plant_visit ON ((plant_visit.id = plant_record.survey_visit_id)))
          WHERE ((plant_record.survey_visit_id IS NULL) OR ((plant_visit.deleted_at IS NULL) AND ((plant_visit.status)::text <> 'cancelled'::text)))
          GROUP BY section_year_1.section_id, section_year_1.year
        )
 SELECT (((section_year.section_id)::text || ':'::text) || section_year.year) AS row_id,
    section_year.project_id,
    section_year.transect_id,
    section_year.section_id,
    section_year.transect_code,
    section_year.section_code,
    section_year.year,
    50 AS radius_m,
    section_year.valid_visits,
    COALESCE(specialist_records.individuals, 0) AS specialist_species_individuals,
    COALESCE(specialist_records.species, (0)::bigint) AS specialist_species,
    round(((COALESCE(specialist_records.individuals, 0))::numeric / (section_year.valid_visits)::numeric), 2) AS specialist_species_per_visit,
    COALESCE(host_patch_counts.patches, (0)::bigint) AS host_patches,
    round(COALESCE(host_patch_counts.abundance, (0)::numeric), 1) AS host_abundance_mid
   FROM ((section_year
     LEFT JOIN specialist_records ON (((specialist_records.section_id = section_year.section_id) AND (specialist_records.year = section_year.year))))
     LEFT JOIN host_patch_counts ON (((host_patch_counts.section_id = section_year.section_id) AND (host_patch_counts.year = section_year.year))))
) q3 WHERE q3.project_id = :'project';
