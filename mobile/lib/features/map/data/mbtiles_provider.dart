import 'package:flutter/foundation.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/map/data/basemap_store.dart';

/// The MBTiles tile provider of a project's offline basemap (T060), or null
/// when this phone has no file for it (or the file cannot be opened). Maps
/// watch it by project id and draw it with `basemapLayers`.
///
/// It opens the file read-only and closes it when the last map using it is
/// gone. The sync runner invalidates it after a new basemap is downloaded, so
/// open maps pick up the new file.
final mbtilesProvider = FutureProvider.autoDispose
    .family<MbTilesTileProvider?, String>((ref, projectId) async {
      final file = await ref.read(basemapStoreProvider).fileFor(projectId);
      if (file == null) return null;
      try {
        // `silenceTileNotFound: true` gives a transparent tile where the file
        // has none, so the online tiles below show through. The package's
        // default throws for a missing tile in debug builds.
        final provider = MbTilesTileProvider.fromPath(
          path: file.path,
          silenceTileNotFound: true,
        );
        ref.onDispose(provider.dispose);
        return provider;
      } catch (e) {
        // A damaged file or one without the `metadata` rows the package
        // needs: draw the online tiles only.
        debugPrint('Could not open the basemap of $projectId: $e');
        return null;
      }
    });
