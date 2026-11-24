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
/// opening) draws OSM only. [osm] and [offline] switch each layer off (the
/// project map's Layers sheet); the other maps keep both on.
List<Widget> basemapLayers(
  MbTilesTileProvider? mbtiles, {
  bool osm = true,
  bool offline = true,
}) {
  // The zoom range the file says it has (metadata `minzoom` / `maxzoom`). The
  // package parsed it when it opened the file; a file without the rows gets
  // the widest range.
  final metadata = mbtiles?.mbtiles.getMetadata();
  final minZoom = metadata?.minZoom ?? 0;
  final maxZoom = metadata?.maxZoom ?? 18;
  return [
    if (osm)
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        // OSM's tile policy asks every app to identify itself.
        userAgentPackageName: 'rs.amilojkovic.butterfly',
      ),
    if (offline && mbtiles != null)
      TileLayer(
        // A new provider over the same open file. Built with `mbtiles:` (not
        // `fromPath`) it does not own the file, so when the TileLayer disposes
        // it (the layer switched off, the map closed) the file stays open for
        // the next time and for other maps; `mbtilesProvider` closes it.
        tileProvider: MbTilesTileProvider(
          mbtiles: mbtiles.mbtiles,
          silenceTileNotFound: true,
        ),
        // Not drawn (and not read) below the file's lowest zoom: OSM shows.
        minZoom: minZoom,
        // Zoomed in past the file's highest level its tiles are stretched
        // instead of going blank, so the map gets blurry, not empty.
        maxNativeZoom: maxZoom.floor(),
      ),
  ];
}
