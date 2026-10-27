// Labels for the wind and precipitation pickers of the start-visit form
// (T035). The stored values are the Beaufort number and the server's
// precipitation codes (codelists.md).

/// Short description of each Beaufort force, index = force (0–12).
const beaufortDescriptions = [
  'Calm',
  'Light air',
  'Light breeze',
  'Gentle breeze',
  'Moderate breeze',
  'Fresh breeze',
  'Strong breeze',
  'Near gale',
  'Gale',
  'Strong gale',
  'Storm',
  'Violent storm',
  'Hurricane',
];

/// What each force looks like in the field, index = force (0–12), so the
/// observer can pick one without a wind meter.
const beaufortHints = [
  'Smoke rises straight up',
  'Smoke drifts, leaves still',
  'Leaves rustle, wind felt on the face',
  'Leaves and twigs move constantly',
  'Small branches move, dust is raised',
  'Small trees sway',
  'Large branches move',
  'Whole trees move, hard to walk against',
  'Twigs break off trees',
  'Slight damage to buildings',
  'Trees uprooted',
  'Widespread damage',
  'Devastation',
];

/// "3 · Gentle breeze"
String beaufortLabel(int force) => '$force · ${beaufortDescriptions[force]}';

/// Every precipitation value, in the order the chips show them.
const precipitationValues = ['none', 'drizzle', 'light_rain', 'rain'];

/// The precipitation value as the form shows it.
String precipitationLabel(String value) {
  return switch (value) {
    'none' => 'None',
    'drizzle' => 'Drizzle',
    'light_rain' => 'Light rain',
    'rain' => 'Rain',
    _ => value,
  };
}
