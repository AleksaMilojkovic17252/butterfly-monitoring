import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/visits/domain/visit_pauses.dart';

/// A stretch of the walk without a GPS point, from [from] to [to] (UTC).
/// [outsidePauses] is how much of it was not a pause.
class GpsGap {
  const GpsGap({
    required this.from,
    required this.to,
    required this.outsidePauses,
  });
  final DateTime from;
  final DateTime to;
  final Duration outsidePauses;
}

/// The GPS gaps of a visit (T040, protocol §8): for each pair of consecutive
/// [points] (all of them, in recorded order) the time between them minus the
/// part that lies inside a pause. It is a gap when what is left is more than
/// [gpsGapS] seconds. A pause stops GPS on purpose, so it is not a gap; T056's
/// `gps_gap` flag works the same way on the server.
List<GpsGap> gpsGaps(
  List<SurveyTrackPoint> points,
  List<VisitPause> pauses,
  int gpsGapS,
) {
  final gaps = <GpsGap>[];
  for (var i = 0; i + 1 < points.length; i++) {
    final gap = _gapBetween(
      points[i].recordedAt.toUtc(),
      points[i + 1].recordedAt.toUtc(),
      pauses,
      gpsGapS,
    );
    if (gap != null) gaps.add(gap);
  }
  return gaps;
}

/// The stretch from the last point to [end] (the moment the visit ends), or
/// null when it is not a gap. [lastPointAt] is null when there is no point.
/// [pauses] should include a pause that is still running, ended at [end], so
/// finishing a paused visit does not count the pause as lost GPS.
GpsGap? trailingGpsGap(
  DateTime? lastPointAt,
  List<VisitPause> pauses,
  DateTime end,
  int gpsGapS,
) {
  if (lastPointAt == null) return null;
  return _gapBetween(lastPointAt.toUtc(), end.toUtc(), pauses, gpsGapS);
}

/// The gap from [from] to [to], or null when what is left after the pauses
/// is not more than [gpsGapS] seconds.
GpsGap? _gapBetween(
  DateTime from,
  DateTime to,
  List<VisitPause> pauses,
  int gpsGapS,
) {
  if (!to.isAfter(from)) return null;
  var outside = to.difference(from);
  for (final pause in pauses) {
    outside -= _overlap(from, to, pause);
  }
  if (outside.inSeconds <= gpsGapS) return null;
  return GpsGap(from: from, to: to, outsidePauses: outside);
}

/// How much of [from]–[to] lies inside [pause].
Duration _overlap(DateTime from, DateTime to, VisitPause pause) {
  final start = pause.startedAt.isAfter(from) ? pause.startedAt : from;
  final end = pause.endedAt.isBefore(to) ? pause.endedAt : to;
  return end.isAfter(start) ? end.difference(start) : Duration.zero;
}
