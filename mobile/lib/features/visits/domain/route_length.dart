import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';

/// Length in metres of the route through [points], which must be in recorded
/// order (T039). Uses the same rule as the server's `distance_walked_m`
/// (D-060): a point whose accuracy is worse than twice
/// [gpsAccuracyWarningM] is left out, and a point without an accuracy is
/// kept. Fewer than two usable points give 0.
double routeLengthM(List<SurveyTrackPoint> points, double gpsAccuracyWarningM) {
  const distance = Distance();
  final maxAccuracyM = 2 * gpsAccuracyWarningM;
  var total = 0.0;
  LatLng? previous;
  for (final point in points) {
    final accuracy = point.accuracyM;
    if (accuracy != null && accuracy > maxAccuracyM) continue;
    final here = LatLng(point.lat, point.lon);
    if (previous != null) {
      total += distance.as(LengthUnit.Meter, previous, here);
    }
    previous = here;
  }
  return total;
}
