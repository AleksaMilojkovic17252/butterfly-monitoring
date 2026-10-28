import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/visits/domain/route_length.dart';

/// How much of the transect the walked route covers, in percent with one
/// decimal (T040, protocol §6), or null when it cannot be worked out.
///
/// The transect is sampled every 10 m along [transectLine], starting at 0 m,
/// plus its end point. A sample is covered when a usable track point (see
/// [isUsablePoint]) lies within [maxDistanceM] of it. The distance is point
/// to point, not point to route segment; the server does the same (T100).
/// An empty line, or fewer than two usable points, gives null.
double? routeCoveragePct(
  List<LatLng> transectLine,
  List<SurveyTrackPoint> points, {
  required double maxDistanceM,
  required double gpsAccuracyWarningM,
}) {
  final usable = [
    for (final point in points)
      if (isUsablePoint(point, gpsAccuracyWarningM))
        LatLng(point.lat, point.lon),
  ];
  final samples = transectSamples(transectLine);
  if (usable.length < 2 || samples.isEmpty) return null;

  const distance = Distance();
  var covered = 0;
  for (final sample in samples) {
    final near = usable.any(
      (point) => distance.as(LengthUnit.Meter, sample, point) <= maxDistanceM,
    );
    if (near) covered++;
  }
  return (covered / samples.length * 1000).round() / 10;
}

/// The points at 0, 10, 20 ... m along [line], and its end point. A line of
/// one vertex gives that vertex; an empty line gives none. Inside a segment
/// the position is a straight interpolation of latitude and longitude, which
/// is exact enough over 10 m.
List<LatLng> transectSamples(List<LatLng> line, {double stepM = 10}) {
  if (line.isEmpty) return [];
  const distance = Distance();
  final samples = <LatLng>[line.first];
  // Metres from the start of the line to the next sample.
  var nextAt = stepM;
  // Metres from the start of the line to the start of this segment.
  var segmentStart = 0.0;
  for (var i = 0; i + 1 < line.length; i++) {
    final a = line[i];
    final b = line[i + 1];
    final length = distance.as(LengthUnit.Meter, a, b);
    while (nextAt <= segmentStart + length && length > 0) {
      final t = (nextAt - segmentStart) / length;
      samples.add(
        LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        ),
      );
      nextAt += stepM;
    }
    segmentStart += length;
  }
  // The end point, unless a sample already sits on it (a line whose length
  // is a multiple of 10 m).
  if (line.length > 1 &&
      distance.as(LengthUnit.Meter, samples.last, line.last) > 0.01) {
    samples.add(line.last);
  }
  return samples;
}
