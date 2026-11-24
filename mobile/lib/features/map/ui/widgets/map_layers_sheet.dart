import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/map/data/mbtiles_provider.dart';
import 'package:mobile/features/map/domain/map_filter.dart';
import 'package:mobile/features/map/domain/map_layers.dart';
import 'package:mobile/features/visits/data/track_point_repository.dart';

/// The Layers sheet of the project map (T059): a switch per layer. The visit
/// route needs a visit chosen under Filters, and the route itself on this
/// phone (track points are not pulled, D-060). A point layer has a small
/// circle in its map colour, as the legend (T112). The offline basemap switch
/// is disabled when this phone has no MBTiles file for the project.
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
    final hasOffline = ref.watch(mbtilesProvider(projectId)).value != null;

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
              _layerSwitch(ref, layer, on, visitId, routeNote, hasOffline),
          ],
        ),
      ),
    );
  }

  /// The switch of one [layer]. The visit route without a visit and the
  /// offline basemap without a file are disabled and show off, so they do not
  /// look on when nothing can be drawn.
  Widget _layerSwitch(
    WidgetRef ref,
    MapLayer layer,
    Set<MapLayer> on,
    String? visitId,
    String? routeNote,
    bool hasOffline,
  ) {
    final available = switch (layer) {
      MapLayer.visitRoute => visitId != null,
      MapLayer.offlineBasemap => hasOffline,
      _ => true,
    };
    final subtitle = switch (layer) {
      MapLayer.visitRoute => routeNote,
      MapLayer.offlineBasemap when !hasOffline =>
        'No offline basemap on this phone',
      _ => null,
    };
    return SwitchListTile(
      secondary: _legendDot(layer),
      title: Text(layer.label),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: on.contains(layer) && available,
      onChanged: available
          ? (value) => ref.read(mapLayersProvider.notifier).toggle(layer, value)
          : null,
    );
  }

  /// The coloured circle in front of a point layer's switch, the colour its
  /// markers have on the map. Other layers have none, but an empty box of the
  /// same size keeps the titles in line.
  Widget _legendDot(MapLayer layer) {
    final color = switch (layer) {
      MapLayer.observations => Colors.deepOrange,
      MapLayer.otherObservations => Colors.purple,
      MapLayer.plants => Colors.green,
      MapLayer.habitats => Colors.brown,
      _ => null,
    };
    if (color == null) return const SizedBox(width: 16, height: 16);
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
