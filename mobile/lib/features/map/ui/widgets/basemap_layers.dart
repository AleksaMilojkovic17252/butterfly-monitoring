import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';

/// The tile layers every map starts with (T060, D-102): the online OpenStreetMap
/// tiles at the bottom and, when the project has an offline basemap, its
/// MBTiles file on top. Spread the list into a `FlutterMap`'s `children`.
///
/// Where the file has a tile it covers the OSM one. Outside the file's area or
/// zoom range its provider answers with a transparent tile, so the OSM tiles
/// below show through: from flutter_map's cache when the area was seen online,
/// otherwise a plain background.
///
/// [mbtiles] comes from `mbtilesProvider(projectId)`; null (no file, or still
/// opening) draws OSM only.
List<Widget> basemapLayers(MbTilesTileProvider? mbtiles) {
  // The zoom range the file says it has (metadata `minzoom` / `maxzoom`). The
  // package parsed it when it opened the file; a file without the rows gets
  // the widest range.
  final metadata = mbtiles?.mbtiles.getMetadata();
  final minZoom = metadata?.minZoom ?? 0;
  final maxZoom = metadata?.maxZoom ?? 18;
  return [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      // OSM's tile policy asks every app to identify itself.
      userAgentPackageName: 'rs.amilojkovic.butterfly',
    ),
    if (mbtiles != null)
      TileLayer(
        tileProvider: mbtiles,
        // Not drawn (and not read) below the file's lowest zoom: OSM shows.
        minZoom: minZoom,
        // Zoomed in past the file's highest level its tiles are stretched
        // instead of going blank, so the map gets blurry, not empty.
        maxNativeZoom: maxZoom.floor(),
      ),
  ];
}
