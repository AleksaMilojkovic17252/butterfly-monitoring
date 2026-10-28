import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';

/// True when [point] counts for the route (D-060): its accuracy is not worse
/// than twice [gpsAccuracyWarningM]. A point without an accuracy is kept. The
/// server uses the same rule for `distance_walked_m`, and T100 for the
/// coverage.
bool isUsablePoint(SurveyTrackPoint point, double gpsAccuracyWarningM) {
  final accuracy = point.accuracyM;
  return accuracy == null || accuracy <= 2 * gpsAccuracyWarningM;
}

/// Length in metres of the route through [points], which must be in recorded
/// order (T039). Uses the same rule as the server's `distance_walked_m`
/// (D-060): see [isUsablePoint]. Fewer than two usable points give 0.
double routeLengthM(List<SurveyTrackPoint> points, double gpsAccuracyWarningM) {
  const distance = Distance();
  var total = 0.0;
  LatLng? previous;
  for (final point in points) {
    if (!isUsablePoint(point, gpsAccuracyWarningM)) continue;
    final here = LatLng(point.lat, point.lon);
    if (previous != null) {
      total += distance.as(LengthUnit.Meter, previous, here);
    }
    previous = here;
  }
  return total;
}
