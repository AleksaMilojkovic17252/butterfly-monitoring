import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/geo/polygon_math.dart';
import 'package:mobile/core/validation/habitat_values.dart';

// Input rules of a habitat feature (T054): V02, V07 and V08 block a save. The
// rules are in docs/requirements/validation-rules.md; the server repeats them
// in `backend/apps/resources/rules.py` and is the one that decides. Percentages
// have no rule ID on the server either (D-088), and the cover slider cannot
// produce a bad one.

/// The values of a habitat feature that the rules read.
class HabitatRuleInput {
  const HabitatRuleInput({
    required this.observedAt,
    required this.geometryType,
    required this.points,
    this.flowerAbundanceClass = '',
    this.grazingIntensity = '',
    this.mowingStatus = '',
    this.disturbanceType = '',
  });

  /// The values of a stored habitat row. A geometry that cannot be read gives
  /// no points, which the rules report as a missing geometry (V02).
  factory HabitatRuleInput.fromRow(HabitatFeature row) {
    final parsed = parseGeometry(row.geometryGeojson);
    return HabitatRuleInput(
      observedAt: row.observedAt,
      geometryType: parsed?.type,
      points: parsed?.points ?? const [],
      flowerAbundanceClass: row.flowerAbundanceClass,
      grazingIntensity: row.grazingIntensity,
      mowingStatus: row.mowingStatus,
      disturbanceType: row.disturbanceType,
    );
  }

  final DateTime? observedAt;

  /// `Point`, `LineString` or `Polygon` (anything else is V08); null when
  /// nothing is drawn.
  final String? geometryType;

  /// A point has one entry. A polygon has its corners, without the repeat of
  /// the first one at the end.
  final List<LatLng> points;
  final String flowerAbundanceClass;
  final String grazingIntensity;
  final String mowingStatus;
  final String disturbanceType;
}

/// The hard errors of [input] as field to rule IDs (the server's field
/// names); an empty map means valid.
Map<String, List<String>> validateHabitatFeature(HabitatRuleInput input) {
  final errors = <String, List<String>>{};
  _v02Required(input, errors);
  _v07Choices(input, errors);
  _v08Geometry(input, errors);
  return errors;
}

void _add(Map<String, List<String>> errors, String field, String ruleId) {
  errors.putIfAbsent(field, () => []).add(ruleId);
}

void _v02Required(HabitatRuleInput input, Map<String, List<String>> errors) {
  // V02
  if (input.observedAt == null) _add(errors, 'observed_at', 'V02');
  if (input.geometryType == null || input.points.isEmpty) {
    _add(errors, 'geometry', 'V02');
  }
}

void _v07Choices(HabitatRuleInput input, Map<String, List<String>> errors) {
  // V07. All four choices are optional, so '' (not recorded) is allowed.
  final choices = {
    'flower_abundance_class': (
      input.flowerAbundanceClass,
      flowerAndGrazingValues,
    ),
    'grazing_intensity': (input.grazingIntensity, flowerAndGrazingValues),
    'mowing_status': (input.mowingStatus, mowingStatusValues),
    'disturbance_type': (input.disturbanceType, disturbanceValues),
  };
  for (final entry in choices.entries) {
    final (value, allowed) = entry.value;
    if (value != '' && !allowed.contains(value)) {
      _add(errors, entry.key, 'V07');
    }
  }
}

void _v08Geometry(HabitatRuleInput input, Map<String, List<String>> errors) {
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
    'LineString' => _distinctPoints(input.points) >= 2 && inRange,
    'Polygon' =>
      input.points.length >= 3 &&
          inRange &&
          !polygonSelfIntersects(input.points),
    _ => false,
  };
  if (!valid) _add(errors, 'geometry', 'V08');
}

/// How many different positions [points] holds. PostGIS calls a line whose
/// points are all the same invalid.
int _distinctPoints(List<LatLng> points) =>
    {for (final p in points) (p.latitude, p.longitude)}.length;

/// The largest vegetation height the server's `smallint` column holds.
const maxVegetationHeightCm = 32767;

/// A plain sentence when [heightCm] cannot be saved, else null. Null (not
/// measured) is fine.
String? vegetationHeightProblem(int? heightCm) {
  if (heightCm == null) return null;
  if (heightCm < 0) return 'The height cannot be negative';
  if (heightCm > maxVegetationHeightCm) {
    return 'The height cannot be more than $maxVegetationHeightCm cm';
  }
  return null;
}
