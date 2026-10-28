// The allowed values of the visit choice fields (V07), the same as the
// `TextChoices` in `backend/apps/surveys/models.py`. Statuses are the server's
// strings, not a Dart enum, because `in_progress` is not a Dart enum name (as
// in D-054). The allowed moves between statuses are in
// `features/visits/domain/visit_status.dart`; the observation lists are in
// `observation_values.dart`.

/// Every visit status, in lifecycle order.
const visitStatuses = [
  'draft',
  'in_progress',
  'completed',
  'synced',
  'reviewed',
  'locked',
  'cancelled',
];

/// Why a visit was cancelled. Required exactly when the status is `cancelled`.
const cancelReasons = [
  'not_conducted',
  'aborted_weather',
  'aborted_other',
  'invalid_protocol',
];

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
