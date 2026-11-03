import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:mobile/core/geo/polygon_math.dart';

/// The kind of shape the capture draws (T052). A plant record takes a point or
/// a polygon; a habitat feature (T054) also takes a line.
enum GeometryMode { point, line, polygon }

/// A finished shape from `GeometryCaptureWidget`: its kind and its points
/// (latitude and longitude). A polygon holds its corners without repeating the
/// first one; [toGeoJson] closes the ring.
class CapturedGeometry {
  const CapturedGeometry({required this.mode, required this.points});

  /// A single point.
  CapturedGeometry.point(LatLng point)
    : mode = GeometryMode.point,
      points = [point];

  /// Reads GeoJSON text of a Point, LineString or Polygon. Null when the text
  /// is not one of those (see `parseGeometry`).
  static CapturedGeometry? fromGeoJson(String geoJson) {
    final parsed = parseGeometry(geoJson);
    if (parsed == null) return null;
    final mode = switch (parsed.type) {
      'Point' => GeometryMode.point,
      'LineString' => GeometryMode.line,
      _ => GeometryMode.polygon,
    };
    return CapturedGeometry(mode: mode, points: parsed.points);
  }

  final GeometryMode mode;
  final List<LatLng> points;

  /// The GeoJSON object for a sync payload. Coordinates are `[lon, lat]`,
  /// rounded to 7 decimals (about 1 cm), which also makes two captures of the
  /// same place compare equal as text.
  Map<String, Object?> toGeoJson() {
    List<double> position(LatLng p) => [
      _round7(p.longitude),
      _round7(p.latitude),
    ];
    switch (mode) {
      case GeometryMode.point:
        return {'type': 'Point', 'coordinates': position(points.first)};
      case GeometryMode.line:
        return {
          'type': 'LineString',
          'coordinates': [for (final p in points) position(p)],
        };
      case GeometryMode.polygon:
        return {
          'type': 'Polygon',
          'coordinates': [
            [for (final p in points) position(p), position(points.first)],
          ],
        };
    }
  }

  /// [toGeoJson] as the text the local table stores.
  String get geoJsonText => jsonEncode(toGeoJson());

  /// The point itself, the centre of a polygon, or the middle of a line's
  /// points: where the map puts a marker and where lists measure from.
  LatLng get centroid => switch (mode) {
    GeometryMode.point => points.first,
    _ => polygonCentroid(points),
  };

  /// Area in square metres; 0 unless this is a polygon.
  double get areaM2 => mode == GeometryMode.polygon ? polygonAreaM2(points) : 0;

  /// Length in metres; 0 unless this is a line.
  double get lengthM => mode == GeometryMode.line ? lineLengthM(points) : 0;

  /// One line for a form tile: "Point 44.12345, 20.54321", "Polygon, 5
  /// corners, 124 m²" or "Line, 4 points, 48 m".
  String get summary => switch (mode) {
    GeometryMode.point =>
      'Point ${points.first.latitude.toStringAsFixed(5)}, '
          '${points.first.longitude.toStringAsFixed(5)}',
    GeometryMode.line =>
      'Line, ${points.length} points, ${formatLength(lengthM)}',
    GeometryMode.polygon =>
      'Polygon, ${points.length} corners, ${formatArea(areaM2)}',
  };

  static double _round7(double value) => double.parse(value.toStringAsFixed(7));
}
