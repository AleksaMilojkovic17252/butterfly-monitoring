import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/visits/data/track_point_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/route_stats.dart';
import 'package:mobile/features/visits/domain/visit_pauses.dart';

/// The distance and coverage of a visit's route, worked out from the track
/// points on this phone (T106). Null while something is loading, and when
/// the phone has fewer than 2 points (the points of a visit walked on another
/// phone are not pulled, D-060).
///
/// The coverage is slow to compute. Riverpod keeps the result, so it is worked
/// out again only when the visit, its points, the transect or the protocol
/// change, and not every time the screen rebuilds.
final visitRouteStatsProvider = Provider.autoDispose
    .family<RouteStats?, String>((ref, visitId) {
      final visit = ref.watch(visitProvider(visitId)).value;
      final points = ref.watch(visitRouteProvider(visitId)).value;
      if (visit == null || points == null || points.length < 2) return null;
      final transect = ref.watch(transectProvider(visit.transectId)).value;
      final protocol = ref
          .watch(projectProtocolProvider(visit.projectId))
          .value;
      if (transect == null || protocol == null) return null;
      return RouteStats.compute(
        points: points,
        transectLine: parseLineString(transect.geometry),
        protocol: protocol,
        pauses: parsePauses(visit.pauses),
      );
    });
