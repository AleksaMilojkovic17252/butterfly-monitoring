// The allowed values of the habitat feature choice fields (V07). They must stay
// the same as the `TextChoices` in `backend/apps/resources/models.py`.

/// Flower abundance and grazing intensity (the server's `Intensity`). Both
/// fields may also be blank (`''`, not recorded).
const flowerAndGrazingValues = ['none', 'low', 'medium', 'high'];

const mowingStatusValues = [
  'unmown',
  'recently_mown',
  'mown_this_season',
  'unknown',
];

const disturbanceValues = [
  'none',
  'trampling',
  'vehicle_tracks',
  'fire',
  'erosion',
  'dumping',
  'other',
];

/// How the screens show a habitat codelist value: `''` is "Not recorded",
/// otherwise the value with spaces and a capital ("recently_mown" is
/// "Recently mown"), which is the server's own label.
String habitatValueLabel(String value) {
  if (value == '') return 'Not recorded';
  final words = value.replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}
