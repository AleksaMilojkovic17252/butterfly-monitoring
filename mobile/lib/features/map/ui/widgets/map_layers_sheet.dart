import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/map/domain/map_filter.dart';
import 'package:mobile/features/map/domain/map_layers.dart';
import 'package:mobile/features/visits/data/track_point_repository.dart';

/// The Layers sheet of the project map (T059): a switch per layer. The visit
/// route needs a visit chosen under Filters, and the route itself on this
/// phone (track points are not pulled, D-060).
class MapLayersSheet extends ConsumerWidget {
  const MapLayersSheet({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(mapLayersProvider);
    final visitId = ref.watch(
      effectiveMapFilterProvider(projectId).select((f) => f.visitId),
    );
    final routePoints = visitId == null
        ? null
        : ref.watch(visitRouteProvider(visitId)).value;

    String? routeNote;
    if (visitId == null) {
      routeNote = 'Choose a visit under Filters';
    } else if (routePoints == null) {
      routeNote = 'Checking the route…';
    } else if (routePoints.length < 2) {
      routeNote = 'Route not on this phone';
    }

    return SafeArea(
      // Scrolls when the layers do not fit (a small screen, a large font, or one
      // more layer later), instead of overflowing.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final layer in MapLayer.values)
              SwitchListTile(
                title: Text(layer.label),
                subtitle: layer == MapLayer.visitRoute && routeNote != null
                    ? Text(routeNote)
                    : null,
                // Without a visit the route switch is disabled and shows off, so
                // it does not look on when nothing can be drawn.
                value:
                    on.contains(layer) &&
                    (layer != MapLayer.visitRoute || visitId != null),
                onChanged: layer == MapLayer.visitRoute && visitId == null
                    ? null
                    : (value) => ref
                          .read(mapLayersProvider.notifier)
                          .toggle(layer, value),
              ),
          ],
        ),
      ),
    );
  }
}
