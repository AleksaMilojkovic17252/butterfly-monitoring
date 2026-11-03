// The allowed values of the plant record choice fields (V07). They must stay
// the same as the `TextChoices` in `backend/apps/resources/models.py`.

const resourceTypeValues = [
  'larval_host',
  'nectar_source',
  'oviposition_plant',
  'resting_plant',
  'unknown_association',
];

/// Individuals or flowering stems in the patch. The three fields below may
/// also be blank (`''`, not recorded).
const abundanceClassValues = ['1', '2-10', '11-100', '101-1000', '>1000'];

const phenologyStageValues = [
  'vegetative',
  'budding',
  'flowering',
  'fruiting',
  'senescent',
];

const floweringIntensityValues = ['none', 'low', 'medium', 'high'];

/// How the screens show a plant codelist value. Most are the value with
/// spaces and a capital ("larval_host" is "Larval host"); the server's own
/// labels differ for a few, and these are the same.
String plantValueLabel(String value) {
  switch (value) {
    case 'larval_host':
      return 'Larval host plant';
    case '>1000':
      return 'More than 1000';
    case '':
      return 'Not recorded';
  }
  final words = value.replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}
