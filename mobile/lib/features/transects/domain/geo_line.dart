import 'dart:convert';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Reads a GeoJSON LineString (as stored in the `geometry` column of the
/// transect and section tables) into map points. GeoJSON stores
/// `[longitude, latitude]`, so the order is swapped here. Any other geometry
/// type, or text that is not a GeoJSON object, gives an empty list, so one
/// bad row cannot break a whole screen.
List<LatLng> parseLineString(String geoJSON) {
  final Object? json;
  try {
    json = jsonDecode(geoJSON);
  } on FormatException {
    return [];
  }
  if (json is! Map<String, dynamic> || json['type'] != 'LineString') return [];
  final coordinates = json['coordinates'];
  if (coordinates is! List<dynamic>) return [];
  return [
    for (final c in coordinates.cast<List<dynamic>>())
      LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
  ];
}

/// Straight-line distance in metres from [from] to the nearest vertex of
/// [line], or null for an empty line. Vertices only, not the segments between
/// them: close enough for "which transect am I next to" (T033).
double? distanceToNearestVertexM(LatLng from, List<LatLng> line) {
  const distance = Distance();
  double? nearest;
  for (final point in line) {
    final d = distance.as(LengthUnit.Meter, from, point);
    if (nearest == null || d < nearest) nearest = d;
  }
  return nearest;
}

/// Shortest distance in metres from [from] to [line], measured to the
/// segments between the vertices, or null for an empty line.
///
/// The points are first put on a flat plane in metres around [from]
/// (equirectangular projection: x east, y north, [from] at 0, 0). Over the
/// length of a transect that is accurate to well under a metre (T039).
double? distanceToLineM(LatLng from, List<LatLng> line) {
  if (line.isEmpty) return null;
  const earthRadiusM = 6371008.8;
  final cosLat = math.cos(from.latitudeInRad);

  // x and y of [p] in metres.
  (double, double) project(LatLng p) => (
    (p.longitudeInRad - from.longitudeInRad) * cosLat * earthRadiusM,
    (p.latitudeInRad - from.latitudeInRad) * earthRadiusM,
  );

  if (line.length == 1) {
    final (x, y) = project(line.first);
    return math.sqrt(x * x + y * y);
  }
  double? nearest;
  for (var i = 0; i + 1 < line.length; i++) {
    final (ax, ay) = project(line[i]);
    final (bx, by) = project(line[i + 1]);
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;
    // Where the point of the segment closest to [from] lies: 0 at the first
    // vertex, 1 at the second.
    final t = lengthSquared == 0
        ? 0.0
        : (-(ax * dx + ay * dy) / lengthSquared).clamp(0.0, 1.0);
    final x = ax + t * dx;
    final y = ay + t * dy;
    final d = math.sqrt(x * x + y * y);
    if (nearest == null || d < nearest) nearest = d;
  }
  return nearest;
}

/// "850 m" below a kilometre, "1.2 km" above.
String formatDistance(double metres) {
  if (metres < 1000) return '${metres.round()} m';
  return '${(metres / 1000).toStringAsFixed(1)} km';
}
