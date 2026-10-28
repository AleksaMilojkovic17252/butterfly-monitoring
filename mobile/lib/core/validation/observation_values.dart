// The allowed values of the observation choice fields (V07). They must stay
// the same as the `TextChoices` in `backend/apps/observations/models.py`.
// Visit statuses and cancel reasons are in
// `features/visits/domain/visit_status.dart`, precipitation in `beaufort.dart`.

const sexValues = ['male', 'female', 'mixed', 'unknown', 'not_applicable'];

const lifeStageValues = ['egg', 'larva', 'pupa', 'adult', 'unknown'];

const behaviourValues = [
  'flying',
  'resting',
  'basking',
  'nectaring',
  'courtship',
  'mating',
  'territorial',
  'oviposition',
  'mud_puddling',
  'feeding_on_fruit',
  'feeding_on_sap',
  'larval_feeding',
  'other',
  'unknown',
];

const sourceValues = [
  'transect',
  'incidental',
  'focal_follow',
  'larval_search',
  'host_plant_search',
];

const confidenceValues = [
  'confirmed_in_field',
  'probable',
  'photo_required',
  'genus_only',
  'species_group',
  'unknown',
  'expert_review_required',
];
