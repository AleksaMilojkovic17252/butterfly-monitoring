# Fields per entity

**M** = mandatory (NOT NULL without a usable default, or required by a rule), **O** = optional,
**S** = set by the server (read-only for clients), **D** = has a default.

Every synced entity (marked ⟳) also has the `SyncableModel` columns (CONVENTIONS A.5.6):
`id` (uuid, client-generated), `server_version` (S), `created_at`, `updated_at`, `deleted_at` (O),
`created_by_id`, `updated_by_id`. They are not repeated below.

Sources: outline §8 and the models in the tickets named in each heading.

## User (`app_user`, T011)
`id` M · `email` M unique · `name` M · `organization` O · `password`, `is_active`, `is_staff`,
`is_superuser`, `last_login`, `date_joined` (Django) · `updated_at` S · group `researcher` | `admin`.

## Project ⟳ (T015, T016, T019)
`name` M · `description` O · `owner` M · `start_date` M · `end_date` O · `default_crs` D 4326 ·
`active` D true · `area` O (MultiPolygon) · `taxon_list_version` M (defaults to current).

## ProjectMembership (T015)
`project` M · `user` M · `added_by` O · `created_at` S. Unique `(project, user)`.

## ProjectProtocol ⟳ (T016)
All fields have defaults except `project` M, `season_start` M and `season_end` M.
`protocol_version` D "1.0" · `survey_method` D pollard_walk · `time_zone` D Europe/Belgrade (IANA name, T055) ·
`day_start_time` D 10:00 ·
`day_end_time` D 17:00 · `min_temperature_c` D 13.0 · `sunny_temperature_c` D 17.0 ·
`max_cloud_cover_pct_if_cool` D 40 · `max_wind_beaufort` D 5 · `allow_precipitation` D false ·
`target_visits_per_season` D 8 · `max_distance_from_transect_m` D 20 · `observation_time_tolerance_min` D 5 ·
`gps_interval_s` D 5 · `gps_interval_battery_saver_s` D 15 · `gps_accuracy_warning_m` D 25 ·
`gps_gap_s` D 60 · `high_count_threshold` D 50 · `min_coverage_pct` D 80.

## TaxonListVersion ⟳ (T019)
`version_label` M unique · `source` M · `published_at` M · `is_current` D false · `notes` O.

## Taxon ⟳ (T019)
`scientific_name` M · `author` O · `rank` D species · `genus` O · `family` O · `vernacular_name_sr` O ·
`vernacular_name_en` O · `accepted_name` O · `taxon_source` D gbif · `taxon_source_id` O ·
`introduced_in` M · `retired_in` O · `active` D true · `photo_required` D false ·
`identification_notes` O.

## PlantTaxon ⟳ (T020)
`scientific_name` M unique · `family` O · `vernacular_name` O · `vernacular_name_en` O ·
`taxon_source` D gbif · `taxon_source_id` O · `active` D true.

## HabitatType, ManagementType ⟳ (T020)
`code` M unique · `name_en` M · `name_sr` M · `description` O · `sort_order` D 100 · `active` D true ·
HabitatType also `eunis_code` O.

## Transect ⟳ (T021)
`project` M · `code` M (unique per project) · `name` M · `description` O · `target_length_m` O ·
`habitat_summary` O · `active` D true · `geometry` M LineString.

## TransectSection ⟳ (T021)
`transect` M · `section_code` M · `sequence_number` M (≥ 1) · `habitat_type` O · `management_type` O ·
`notes` O · `geometry` M LineString (within 5 m of the transect).

## SurveyVisit ⟳ (T034)
Mandatory: `project`, `transect`, `observer`, `protocol_version`.
Defaults: `survey_method` pollard_walk · `paused_seconds` 0 · `observer_count` 1 · `precipitation` none ·
`zero_observation_confirmed` false · `status` draft · `battery_saver_used` false · `created_offline` true.
Optional until the visit progresses: `started_at` (M from `in_progress`), `ended_at` and
`duration_seconds` (M from `completed`), `distance_walked_m` (S on completion), `observer_names`,
`temperature_start_c`/`_end_c`, `wind_beaufort_start`/`_end`, `cloud_cover_start_pct`/`_end_pct`
(start and end weather M from `completed`, or `weather_missing_reason`, V05), `weather_suitable`,
`weather_missing_reason`, `notes`, `device_id`.
`cancel_reason`: M when `status = cancelled`, empty otherwise.
Server-owned: `locked_at`, `locked_by`, `lock_reason`, `quality_flags`.

## SurveyTrackPoint ⟳ (T036; not audited)
`survey_visit` M · `recorded_at` M · `geometry` M Point · `sequence_number` M (unique per visit) ·
`provider` D gps · `accuracy_m` O · `altitude_m` O · `speed_m_s` O · `heading_deg` O (0–<360).

## ButterflyObservation ⟳ (T044)
Mandatory: `project`, `observed_at`, `taxon`, `count` (≥ 1), `geometry` (Point), `recorded_by`,
`identification_confidence` (D confirmed_in_field). `survey_visit` M when `source = transect`.
Optional: `transect_section` (set by T048 or by hand), `location_accuracy_m`, `sex` (D unknown),
`life_stage` (D adult), `behaviour` (list), `microhabitat`, `flight_direction_deg` (0–359), `notes`,
`host_plant_record`, `nectar_plant_record` (T051). `source` D transect.
Server-owned: `validation_status`, `validated_taxon`, `validated_by`, `validated_at`,
`validation_comment`, `quality_flags`. `photo_count` is computed, not stored.

## Photo ⟳ (T049, T051)
Mandatory: `mime_type`, `file_size`, `sha256`, `captured_at`, and exactly one parent
(`observation` or `plant_resource`). Optional: `local_path`, `width`, `height`, `is_primary`,
`metadata_json`. Server-owned: `storage_key`, `uploaded_at`, `upload_status`.

## PlantResourceObservation ⟳ (T051)
Mandatory: `project`, `resource_type`, `observed_at`, `geometry` (Point or Polygon).
Optional: `survey_visit`, `plant_taxon` (if empty, `notes` is M), `abundance_class`,
`patch_area_m2` (S for polygons if empty), `phenology_stage`, `flowering_intensity`, `eggs_present`,
`larvae_present`, `feeding_damage_present`, `notes`.

## HabitatFeature ⟳ (T053)
Mandatory: `project`, `habitat_type`, `observed_at`, `geometry` (Point, LineString or Polygon).
Optional: `survey_visit`, `management_type`, `vegetation_height_cm`, `shrub_cover_pct`,
`tree_cover_pct`, `bare_ground_pct` (0–100), `flower_abundance_class`, `grazing_intensity`,
`mowing_status`, `disturbance_type`, `notes`.

## EnvironmentalSnapshot (T063)
Mandatory: `source_type`, `moment`, `phenomenon_time_start`, and `survey_visit` or `observation`.
Optional: `source_uri`, `phenomenon_time_end`, `temperature_c`, `relative_humidity_pct`,
`wind_speed_m_s`, `wind_direction_deg`, `cloud_cover_pct`, `precipitation_mm`,
`solar_radiation_w_m2`, `raw_payload_json`. `is_simulated` D false · `retrieved_at` S.

## ValidationEvent (T058)
Mandatory: `observation`, `decision`, `previous_status`, `new_status`, `decided_by`;
`new_taxon` M when `decision = changed_taxon`. Optional: `previous_taxon`, `comment`.
`decided_at` S.

## SyncMutation, SyncConflict (T026, T027)
**SyncMutation** (all S): `mutation_id`, `user`, `device_id`, `entity_type`, `entity_id`, `operation`,
`base_version`, `status`, `result`, `received_at`, `client_created_at`.
**SyncConflict** ⟳ (all S except the resolution fields): `owner`, `mutation`, `project`, `entity_type`,
`entity_id`, `operation`, `base_version`, `server_version_at_conflict`, `client_payload`,
`server_snapshot`, `base_snapshot`, `conflicting_fields`, `status`; resolution (admin): `resolved_by`,
`resolved_at`, `resolution_note`.

## Phase 2 entities (listed for the ER diagram only)
`SensorStationLink` (T078), `FocalFollowSession`, `FocalFollowPoint`, `FocalFollowTrajectory`,
`TrajectoryEvent` (T089, T091). Fields are defined in their tickets.
