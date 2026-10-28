import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/visits/domain/gps_gaps.dart';
import 'package:mobile/features/visits/domain/route_coverage.dart';
import 'package:mobile/features/visits/domain/route_length.dart';
import 'package:mobile/features/visits/domain/visit_pauses.dart';

/// What the Finish screen works out from the stored track points (T040):
/// the distance, the coverage and the GPS gaps between points. These are the
/// slow parts (the coverage compares every sample with every point), so the
/// screen computes them once per route and not on every keystroke.
class RouteStats {
  const RouteStats({
    required this.distanceM,
    required this.coveragePct,
    required this.gaps,
  });

  /// Works out the stats of [points] (recorded order) on [transectLine].
  factory RouteStats.compute({
    required List<SurveyTrackPoint> points,
    required List<LatLng> transectLine,
    required ProjectProtocol protocol,
    required List<VisitPause> pauses,
  }) {
    return RouteStats(
      distanceM: routeLengthM(points, protocol.gpsAccuracyWarningM),
      coveragePct: routeCoveragePct(
        transectLine,
        points,
        maxDistanceM: protocol.maxDistanceFromTransectM,
        gpsAccuracyWarningM: protocol.gpsAccuracyWarningM,
      ),
      gaps: gpsGaps(points, pauses, protocol.gpsGapS),
    );
  }

  final double distanceM;

  /// Null when there are too few usable points.
  final double? coveragePct;

  /// Gaps between consecutive points. The stretch after the last point is
  /// not here: it changes with the clock (see `trailingGpsGap`).
  final List<GpsGap> gaps;
}
