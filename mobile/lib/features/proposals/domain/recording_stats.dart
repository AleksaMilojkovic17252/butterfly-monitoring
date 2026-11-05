import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/location/usable_fix.dart';

/// The fixes that make the proposal's line (T108), in recorded order. All
/// fixes are stored; here the unusable ones (D-060, see [isUsableAccuracy])
/// are left out, and so is a fix at the same position as the one before it,
/// since PostGIS calls a line of equal points invalid.
List<RouteRecordingPoint> usableLineFixes(
  List<RouteRecordingPoint> points,
  double gpsAccuracyWarningM,
) {
  final line = <RouteRecordingPoint>[];
  for (final point in points) {
    if (!isUsableAccuracy(point.accuracyM, gpsAccuracyWarningM)) continue;
    if (line.isNotEmpty &&
        line.last.lat == point.lat &&
        line.last.lon == point.lon) {
      continue;
    }
    line.add(point);
  }
  return line;
}

/// Length in metres of the line through [points], which must be in recorded
/// order: the sum of the distances between the usable fixes, as `routeLengthM`
/// does for a visit (D-060). Fewer than two usable fixes give 0.
double recordingLengthM(
  List<RouteRecordingPoint> points,
  double gpsAccuracyWarningM,
) {
  const distance = Distance();
  final line = usableLineFixes(points, gpsAccuracyWarningM);
  var total = 0.0;
  for (var i = 1; i < line.length; i++) {
    total += distance.as(
      LengthUnit.Meter,
      LatLng(line[i - 1].lat, line[i - 1].lon),
      LatLng(line[i].lat, line[i].lon),
    );
  }
  return total;
}

/// How long [recording] has been walked at [now]: the time since `startedAt`
/// without the stored `pausedSeconds` and without the pause that is running
/// now. Format it with `formatWalkingTime`.
Duration recordingTime(RouteRecording recording, DateTime now) {
  var walked =
      now.difference(recording.startedAt) -
      Duration(seconds: recording.pausedSeconds);
  final pausedAt = recording.pausedAt;
  if (pausedAt != null) walked -= now.difference(pausedAt);
  return walked.isNegative ? Duration.zero : walked;
}
