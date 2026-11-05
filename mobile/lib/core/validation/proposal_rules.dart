import 'package:latlong2/latlong.dart';
import 'package:mobile/core/validation/proposal_values.dart';

// Input rules of a route proposal (T108): V02, V07 and V08 block a save. The
// rules are in docs/requirements/validation-rules.md; the server repeats them
// in `backend/apps/transects/rules.py` and is the one that decides.

/// The hard errors of a proposal as field to rule IDs (the server's field
/// names); an empty map means valid.
///
/// [points] is the line, in walking order. V08 asks for at least two
/// different positions, all in range. A line that crosses itself is valid:
/// PostGIS accepts it, and a walked route can cross itself.
Map<String, List<String>> validateProposal({
  required String name,
  required String? reason,
  required List<LatLng> points,
}) {
  final errors = <String, List<String>>{};
  void add(String field, String ruleId) {
    errors.putIfAbsent(field, () => []).add(ruleId);
  }

  // V02
  if (name.trim().isEmpty) add('name', 'V02');
  if (reason == null || reason.isEmpty) add('reason', 'V02');
  if (points.isEmpty) add('geometry', 'V02');

  // V07
  if (reason != null &&
      reason.isNotEmpty &&
      !proposalReasons.containsKey(reason)) {
    add('reason', 'V07');
  }

  // V08. A missing line is V02's.
  if (points.isNotEmpty) {
    final inRange = points.every(
      (p) =>
          p.latitude.isFinite &&
          p.longitude.isFinite &&
          p.latitude >= -90 &&
          p.latitude <= 90 &&
          p.longitude >= -180 &&
          p.longitude <= 180,
    );
    if (!inRange || distinctPointCount(points) < 2) add('geometry', 'V08');
  }
  return errors;
}

/// How many different positions [points] holds. PostGIS calls a line whose
/// points are all the same invalid.
int distinctPointCount(List<LatLng> points) =>
    {for (final p in points) (p.latitude, p.longitude)}.length;
