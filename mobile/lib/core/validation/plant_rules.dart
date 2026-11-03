import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/geo/polygon_math.dart';
import 'package:mobile/core/validation/plant_values.dart';

// Input rules of a plant record (T052): V02, V07 and V08 block a save. The
// rules are in docs/requirements/validation-rules.md; the server repeats them
// in `backend/apps/resources/rules.py` and is the one that decides. There is
// no V03 or V04 for a plant record.

/// The values of a plant record that the rules read.
class PlantRuleInput {
  const PlantRuleInput({
    required this.observedAt,
    required this.resourceType,
    required this.geometryType,
    required this.points,
    this.abundanceClass = '',
    this.phenologyStage = '',
    this.floweringIntensity = '',
  });

  /// The values of a stored plant row. A geometry that cannot be read gives
  /// no points, which the rules report as a missing geometry (V02).
  factory PlantRuleInput.fromRow(PlantResourceObservation row) {
    final parsed = parseGeometry(row.geometryGeojson);
    return PlantRuleInput(
      observedAt: row.observedAt,
      resourceType: row.resourceType,
      geometryType: parsed?.type,
      points: parsed?.points ?? const [],
      abundanceClass: row.abundanceClass,
      phenologyStage: row.phenologyStage,
      floweringIntensity: row.floweringIntensity,
    );
  }

  final DateTime? observedAt;
  final String resourceType;

  /// `Point` or `Polygon` (anything else is V08); null when nothing is drawn.
  final String? geometryType;

  /// A point has one entry. A polygon has its corners, without the repeat of
  /// the first one at the end.
  final List<LatLng> points;
  final String abundanceClass;
  final String phenologyStage;
  final String floweringIntensity;
}

/// The hard errors of [input] as field to rule IDs (the server's field
/// names); an empty map means valid.
Map<String, List<String>> validatePlantResource(PlantRuleInput input) {
  final errors = <String, List<String>>{};
  _v02Required(input, errors);
  _v07Choices(input, errors);
  _v08Geometry(input, errors);
  return errors;
}

void _add(Map<String, List<String>> errors, String field, String ruleId) {
  errors.putIfAbsent(field, () => []).add(ruleId);
}

void _v02Required(PlantRuleInput input, Map<String, List<String>> errors) {
  // V02
  if (input.observedAt == null) _add(errors, 'observed_at', 'V02');
  if (input.geometryType == null || input.points.isEmpty) {
    _add(errors, 'geometry', 'V02');
  }
}

void _v07Choices(PlantRuleInput input, Map<String, List<String>> errors) {
  // V07. The three optional choices also allow '' (not recorded).
  if (!resourceTypeValues.contains(input.resourceType)) {
    _add(errors, 'resource_type', 'V07');
  }
  final optional = {
    'abundance_class': (input.abundanceClass, abundanceClassValues),
    'phenology_stage': (input.phenologyStage, phenologyStageValues),
    'flowering_intensity': (input.floweringIntensity, floweringIntensityValues),
  };
  for (final entry in optional.entries) {
    final (value, allowed) = entry.value;
    if (value != '' && !allowed.contains(value)) {
      _add(errors, entry.key, 'V07');
    }
  }
}

void _v08Geometry(PlantRuleInput input, Map<String, List<String>> errors) {
  // V08. A missing geometry is V02's.
  final type = input.geometryType;
  if (type == null || input.points.isEmpty) return;
  final inRange = input.points.every(
    (p) =>
        p.latitude.isFinite &&
        p.longitude.isFinite &&
        p.latitude >= -90 &&
        p.latitude <= 90 &&
        p.longitude >= -180 &&
        p.longitude <= 180,
  );
  final valid = switch (type) {
    'Point' => input.points.length == 1 && inRange,
    'Polygon' =>
      input.points.length >= 3 &&
          inRange &&
          !polygonSelfIntersects(input.points),
    _ => false,
  };
  if (!valid) _add(errors, 'geometry', 'V08');
}

/// The message when a plant with no species has no notes (the serializer's
/// rule on the server, not a V rule).
const plantNotesRequiredMessage =
    'Notes are required when the plant is not identified';

/// True when a plant has no species and no notes: the record cannot be saved.
bool plantNotesMissing(String? plantTaxonId, String notes) =>
    plantTaxonId == null && notes.trim().isEmpty;
