import 'dart:convert';

import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/observation_values.dart';

// Input rules of a butterfly observation (T055): V01-V04, V06-V08 block a
// save, W01-W04 only warn. The rules are in
// docs/requirements/validation-rules.md; the server repeats them in
// `backend/apps/observations/rules.py` and is the one that decides.

/// The values of an observation that the rules read.
class ObservationInput {
  const ObservationInput({
    required this.observedAt,
    required this.count,
    required this.lat,
    required this.lon,
    this.accuracyM,
    this.source = 'transect',
    this.sex = 'unknown',
    this.lifeStage = 'adult',
    this.confidence = 'confirmed_in_field',
    this.behaviour = const [],
  });

  /// The values of a stored observation row. `behaviour` is JSON text; text
  /// that is not a list of strings gives an empty list.
  factory ObservationInput.fromObservation(ButterflyObservation row) =>
      ObservationInput(
        observedAt: row.observedAt,
        count: row.count,
        lat: row.lat,
        lon: row.lon,
        accuracyM: row.locationAccuracyM,
        source: row.source,
        sex: row.sex,
        lifeStage: row.lifeStage,
        confidence: row.identificationConfidence,
        behaviour: _behaviourList(row.behaviour),
      );

  final DateTime? observedAt;
  final int count;
  final double? lat;
  final double? lon;
  final double? accuracyM;
  final String source;
  final String sex;
  final String lifeStage;
  final String confidence;
  final List<String> behaviour;
}

List<String> _behaviourList(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is List<dynamic> && decoded.every((item) => item is String)) {
      return decoded.cast<String>();
    }
  } on FormatException {
    // Falls through to the empty list.
  }
  return [];
}

/// What the rules need to know besides the observation: its visit, the
/// protocol and the taxon.
class ObservationRuleContext {
  const ObservationRuleContext({
    required this.visitStatus,
    required this.visitStartedAt,
    required this.visitEndedAt,
    required this.visitZeroConfirmed,
    required this.toleranceMin,
    required this.accuracyWarningM,
    required this.taxonPhotoRequired,
    required this.photoCount,
  });

  /// Null when the observation has no visit.
  final String? visitStatus;
  final DateTime? visitStartedAt;
  final DateTime? visitEndedAt;
  final bool visitZeroConfirmed;

  /// `observation_time_tolerance_min` of the protocol.
  final int toleranceMin;

  /// `gps_accuracy_warning_m` of the protocol.
  final double accuracyWarningM;
  final bool taxonPhotoRequired;
  final int photoCount;
}

/// Visit statuses a transect observation may be recorded on (V03).
const _observationVisitStatuses = [
  'in_progress',
  'completed',
  'synced',
  'reviewed',
];

/// The hard errors of [input] as field to rule IDs (the server's field
/// names); an empty map means valid.
Map<String, List<String>> validateObservation(
  ObservationInput input,
  ObservationRuleContext context,
) {
  final errors = <String, List<String>>{};
  _v01Count(input, errors);
  _v02Required(input, errors);
  _v03VisitStatus(input, context, errors);
  _v04ObservedAt(input, context, errors);
  _v06Observation(input, context, errors);
  _v07Choices(input, errors);
  _v08Geometry(input, errors);
  return errors;
}

/// The warnings that apply to [input], as rule IDs (W01-W04). They never
/// block a save.
List<String> observationWarnings(
  ObservationInput input,
  ObservationRuleContext context,
) {
  return [
    if (photoMissing(context.taxonPhotoRequired, context.photoCount)) 'W01',
    if (isPoorAccuracy(input.accuracyM, context.accuracyWarningM)) 'W02',
    if (_w03Oviposition(input)) 'W03',
    if (_w04Larva(input)) 'W04',
  ];
}

/// W01: the taxon needs a photo and the observation has none, so it waits for
/// validation.
bool photoMissing(bool photoRequired, int photoCount) =>
    photoRequired && photoCount == 0;

/// W02: the fix is less accurate than the protocol's warning value. No
/// accuracy means no warning.
bool isPoorAccuracy(double? accuracyM, double warningM) =>
    accuracyM != null && accuracyM > warningM;

void _add(Map<String, List<String>> errors, String field, String ruleId) {
  errors.putIfAbsent(field, () => []).add(ruleId);
}

void _v01Count(ObservationInput input, Map<String, List<String>> errors) {
  // V01
  if (input.count < 1) _add(errors, 'count', 'V01');
}

void _v02Required(ObservationInput input, Map<String, List<String>> errors) {
  // V02
  if (input.observedAt == null) _add(errors, 'observed_at', 'V02');
  if (input.lat == null || input.lon == null) _add(errors, 'geometry', 'V02');
}

void _v03VisitStatus(
  ObservationInput input,
  ObservationRuleContext context,
  Map<String, List<String>> errors,
) {
  // V03
  if (input.source != 'transect') return;
  if (!_observationVisitStatuses.contains(context.visitStatus)) {
    _add(errors, 'survey_visit', 'V03');
  }
}

void _v04ObservedAt(
  ObservationInput input,
  ObservationRuleContext context,
  Map<String, List<String>> errors,
) {
  // V04
  final observedAt = input.observedAt;
  if (observedAt == null || context.visitStatus == null) return;
  final tolerance = Duration(minutes: context.toleranceMin);
  final startedAt = context.visitStartedAt;
  final endedAt = context.visitEndedAt;
  if (startedAt != null && observedAt.isBefore(startedAt.subtract(tolerance))) {
    _add(errors, 'observed_at', 'V04');
  } else if (endedAt != null && observedAt.isAfter(endedAt.add(tolerance))) {
    _add(errors, 'observed_at', 'V04');
  }
}

void _v06Observation(
  ObservationInput input,
  ObservationRuleContext context,
  Map<String, List<String>> errors,
) {
  // V06: no transect observation on a visit confirmed as a true zero.
  if (input.source == 'transect' && context.visitZeroConfirmed) {
    _add(errors, 'survey_visit', 'V06');
  }
}

void _v07Choices(ObservationInput input, Map<String, List<String>> errors) {
  // V07
  final single = {
    'sex': (input.sex, sexValues),
    'life_stage': (input.lifeStage, lifeStageValues),
    'source': (input.source, sourceValues),
    'identification_confidence': (input.confidence, confidenceValues),
  };
  for (final entry in single.entries) {
    final (value, allowed) = entry.value;
    if (!allowed.contains(value)) _add(errors, entry.key, 'V07');
  }
  if (input.behaviour.any((item) => !behaviourValues.contains(item))) {
    _add(errors, 'behaviour', 'V07');
  }
}

void _v08Geometry(ObservationInput input, Map<String, List<String>> errors) {
  // V08. A missing position is V02's.
  final lat = input.lat;
  final lon = input.lon;
  if (lat == null || lon == null) return;
  final valid =
      lat.isFinite &&
      lon.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lon >= -180 &&
      lon <= 180;
  if (!valid) _add(errors, 'geometry', 'V08');
}

bool _w03Oviposition(ObservationInput input) {
  // W03. TODO(T051): only when the observation has no host-plant link; there
  // is no link yet, so it always fires.
  return input.behaviour.contains('oviposition');
}

bool _w04Larva(ObservationInput input) {
  // W04. TODO(T051): only when the observation has no host-plant link; there
  // is no link yet, so it always fires.
  return input.lifeStage == 'larva';
}
