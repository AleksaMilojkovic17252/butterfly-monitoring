import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The layers of the project map (T059) that the Layers sheet switches.
/// Plants came with T052 and habitats with T054.
enum MapLayer {
  transects('Transects'),
  sections('Sections'),
  observations('Observations'),
  plants('Plants'),
  habitats('Habitats'),
  visitRoute('Visit route'),
  basemap('Basemap (OpenStreetMap)');

  const MapLayer(this.label);

  /// The name in the Layers sheet.
  final String label;
}

/// Which layers are on. All are on when the map opens, and the choice lasts
/// while the map is open (`autoDispose`, not saved).
class MapLayersNotifier extends Notifier<Set<MapLayer>> {
  @override
  Set<MapLayer> build() => {...MapLayer.values};

  /// Turns [layer] on or off.
  void toggle(MapLayer layer, bool on) {
    state = on ? {...state, layer} : ({...state}..remove(layer));
  }
}

final mapLayersProvider =
    NotifierProvider.autoDispose<MapLayersNotifier, Set<MapLayer>>(
      MapLayersNotifier.new,
    );
