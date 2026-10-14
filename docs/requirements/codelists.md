# Codelists

Fixed enums used in `CHECK` constraints (CONVENTIONS A.5). Changing one means a migration plus an app
release, so they are settled here. Source: ticket models in `TICKET_DETAILS.md`; values with no outline
equivalent are marked **(proposed)**. Editable codelists (habitat type, management type) are data, not
enums, and are seeded in T024.

## Observation

**Sex** (`sex`; default `unknown`): `male`, `female`, `mixed`, `unknown`, `not_applicable`.
`mixed` is for group records.

**Life stage** (`life_stage`; default `adult`): `egg`, `larva`, `pupa`, `adult`, `unknown`.

**Behaviour** (`behaviour`, multi-select array): `flying`, `resting`, `basking`, `nectaring`,
`courtship`, `mating`, `territorial`, `oviposition`, `mud_puddling`, `feeding_on_fruit`,
`feeding_on_sap`, `larval_feeding`, `other`, `unknown`.

**Identification confidence** (`identification_confidence`; default `confirmed_in_field`):
`confirmed_in_field`, `probable`, `photo_required`, `genus_only`, `species_group`, `unknown`,
`expert_review_required`.

**Source** (`source`; default `transect`): `transect`, `incidental`, `focal_follow` (Phase 2),
`larval_search`, `host_plant_search`.

**Validation status** (`validation_status`; server-owned): `not_required`, `pending`, `confirmed`,
`unconfirmed`, `undeterminable`.

**Validation decision** (`ValidationEvent.decision`): `confirmed`, `changed_taxon`, `unconfirmed`,
`undeterminable`, `reset`.

## Plants and habitat

**Resource type** (`resource_type`): `larval_host`, `nectar_source`, `oviposition_plant`,
`resting_plant`, `unknown_association`.

**Abundance class** (`abundance_class`, individuals or flowering stems in the patch; blank allowed):
`1`, `2-10`, `11-100`, `101-1000`, `>1000` **(proposed)**.

**Phenology stage** (`phenology_stage`; blank allowed): `vegetative`, `budding`, `flowering`,
`fruiting`, `senescent` **(proposed)**.

**Intensity** (used by `flowering_intensity`, `flower_abundance_class` and `grazing_intensity`; blank
allowed): `none`, `low`, `medium`, `high` **(proposed)**.

**Mowing status** (`mowing_status`; blank allowed): `unmown`, `recently_mown`, `mown_this_season`,
`unknown` **(proposed)**.

**Disturbance** (`disturbance_type`; blank allowed): `none`, `trampling`, `vehicle_tracks`, `fire`,
`erosion`, `dumping`, `other` **(proposed)**.

## Visit

**Visit status** (`status`; default `draft`): `draft`, `in_progress`, `completed`, `synced`,
`reviewed`, `locked`, `cancelled`. Transitions: see T034.

**Cancel reason** (`cancel_reason`; required exactly when `status = cancelled`): `not_conducted`,
`aborted_weather`, `aborted_other`, `invalid_protocol`.

**Precipitation** (`precipitation`; default `none`): `none`, `drizzle`, `light_rain`, `rain`.
Only `none` is within the protocol thresholds.

**Survey method** (`survey_method`): `pollard_walk`, `other`.

**Location provider** (`SurveyTrackPoint.provider`): `gps`, `fused`, `network`, `simulated`.

## Catalogues

**Taxon rank**: `family`, `genus`, `species_group`, `species`, `subspecies`.
**Taxon source**: `gbif`, `manual`.

## Sync and photos

**Mutation status**: `applied`, `merged`, `conflict`, `rejected`.
**Conflict status**: `open`, `resolved_server`, `resolved_client`.
**Upload status** (`Photo.upload_status`): `pending`, `uploaded`. Photo MIME types: `image/jpeg`, `image/png`.

## Environmental snapshots

**Source type**: `manual`, `sensorthings`, `edr`, `other_api`.
**Snapshot moment**: `start`, `end`, `visit_mean`, `at_observation`.

## Quality flags (stored in `quality_flags`)

`outside_project_area`, `far_from_transect`, `high_count` (observation); `gps_gap` (visit). Not an
enum in the database; documented here so the app and server agree.
