import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/transects/ui/widgets/transect_map.dart';
import 'package:mobile/features/visits/data/track_point_repository.dart';

/// The map of the visit detail (T106): the transect and its sections, and the
/// walked route when its track points are on this phone. Track points are not
/// pulled (D-060), so on another phone it says "Route not on this phone".
class VisitRouteMap extends ConsumerWidget {
  const VisitRouteMap({super.key, required this.visit});
  final SurveyVisit visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transect = ref.watch(transectProvider(visit.transectId)).value;
    final sections =
        ref.watch(transectSectionsProvider(visit.transectId)).value ?? [];
    final points = ref.watch(visitRouteProvider(visit.id)).value ?? [];
    // flutter_map cannot draw a line with fewer than 2 points (it asserts).
    final hasRoute = points.length >= 2;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 260,
            child: TransectMap(
              line: transect == null ? [] : parseLineString(transect.geometry),
              sections: [
                for (final s in sections) parseLineString(s.section.geometry),
              ],
              overlays: [
                if (hasRoute)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [for (final p in points) LatLng(p.lat, p.lon)],
                        strokeWidth: 3,
                        color: Colors.black87,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (!hasRoute)
            const ListTile(
              leading: Icon(Icons.gps_off),
              title: Text('Route not on this phone'),
            ),
        ],
      ),
    );
  }
}
