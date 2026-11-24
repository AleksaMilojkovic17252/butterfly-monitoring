import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the transect maps (transect detail, active visit, visit detail)
/// draw the project's offline MBTiles basemap over OpenStreetMap. The button
/// in the corner of `TransectMap` switches it.
///
/// One value for every transect map, so a choice made on the transect detail
/// still holds on the active visit. It is on when the app starts and lasts
/// while the app runs (not `autoDispose`, not saved). The project map has its
/// own basemap switches in its Layers sheet (`mapLayersProvider`).
class OfflineTilesNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  /// Turns the offline tiles on when they are off, and off when they are on.
  void toggle() => state = !state;
}

final offlineTilesProvider = NotifierProvider<OfflineTilesNotifier, bool>(
  OfflineTilesNotifier.new,
);
