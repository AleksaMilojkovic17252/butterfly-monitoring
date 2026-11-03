import 'dart:convert';
import 'dart:math';

import 'package:latlong2/latlong.dart';

// Plain geometry helpers for the plant form and the geometry capture (T052):
// area, centroid, length, the self-intersection test and a GeoJSON reader.
// Pure Dart, no widgets, nothing from `features/`.
//
// Longitude and latitude are turned into metres with one flat projection per
// call, centred on the mean of the points. That is accurate to about 0.1 % for
// a patch of up to a few hundred metres, which is plenty for a figure shown
// while drawing (the server computes the real area with PostGIS). The
// projection is affine (a stretch of the two axes), so "do these edges cross"
// has the same answer in metres as on lon/lat, which is the plane PostGIS's
// `ST_IsValid` works in.

/// Two points closer than this many metres are the same point.
const _samePointM = 1e-6;

/// A cross product (in square metres) smaller than this counts as zero, that
/// is "on the same line". Far below the 1 cm that coordinates are rounded to.
const _collinearEps = 1e-9;

/// A polygon smaller than this many square metres is no polygon.
const _minAreaM2 = 0.01;

/// A point in metres east and north of the projection's centre.
class _Xy {
  const _Xy(this.x, this.y);
  final double x;
  final double y;
}

/// The flat projection of one list of points.
class _Projection {
  _Projection(List<LatLng> points) {
    var latSum = 0.0;
    var lonSum = 0.0;
    for (final p in points) {
      latSum += p.latitude;
      lonSum += p.longitude;
    }
    final n = points.isEmpty ? 1 : points.length;
    lat0 = latSum / n;
    lon0 = lonSum / n;
    final phi = lat0 * pi / 180;
    // Metres in one degree on the WGS 84 ellipsoid at this latitude.
    metresPerDegLat =
        111132.92 -
        559.82 * cos(2 * phi) +
        1.175 * cos(4 * phi) -
        0.0023 * cos(6 * phi);
    metresPerDegLon =
        111412.84 * cos(phi) - 93.5 * cos(3 * phi) + 0.118 * cos(5 * phi);
  }

  late final double lat0;
  late final double lon0;
  late final double metresPerDegLat;
  late final double metresPerDegLon;

  _Xy toXy(LatLng p) => _Xy(
    (p.longitude - lon0) * metresPerDegLon,
    (p.latitude - lat0) * metresPerDegLat,
  );

  LatLng toLatLng(double x, double y) =>
      LatLng(lat0 + y / metresPerDegLat, lon0 + x / metresPerDegLon);
}

List<_Xy> _project(List<LatLng> points) {
  final projection = _Projection(points);
  return [for (final p in points) projection.toXy(p)];
}

/// Twice the signed area of the ring in square metres (positive when the ring
/// runs counter-clockwise). The ring may or may not repeat its first point.
double _signedArea2(List<_Xy> ring) {
  var sum = 0.0;
  for (var i = 0; i < ring.length; i++) {
    final a = ring[i];
    final b = ring[(i + 1) % ring.length];
    sum += a.x * b.y - b.x * a.y;
  }
  return sum;
}

/// Area of the polygon in square metres. Fewer than 3 points give 0.
double polygonAreaM2(List<LatLng> points) {
  if (points.length < 3) return 0;
  return _signedArea2(_project(points)).abs() / 2;
}

/// Centre of the polygon (area-weighted). It falls back to the mean of the
/// points when the area is zero, for example three points on a line. An empty
/// list gives (0, 0).
LatLng polygonCentroid(List<LatLng> points) {
  if (points.isEmpty) return const LatLng(0, 0);
  final projection = _Projection(points);
  final xy = [for (final p in points) projection.toXy(p)];
  final area2 = _signedArea2(xy);
  if (points.length < 3 || area2.abs() < 1e-9) {
    // The projection is centred on the mean, so the mean is (0, 0).
    return projection.toLatLng(0, 0);
  }
  var cx = 0.0;
  var cy = 0.0;
  for (var i = 0; i < xy.length; i++) {
    final a = xy[i];
    final b = xy[(i + 1) % xy.length];
    final cross = a.x * b.y - b.x * a.y;
    cx += (a.x + b.x) * cross;
    cy += (a.y + b.y) * cross;
  }
  return projection.toLatLng(cx / (3 * area2), cy / (3 * area2));
}

/// Length of the line through [points] in metres.
double lineLengthM(List<LatLng> points) {
  if (points.length < 2) return 0;
  final xy = _project(points);
  var total = 0.0;
  for (var i = 1; i < xy.length; i++) {
    total += sqrt(
      pow(xy[i].x - xy[i - 1].x, 2) + pow(xy[i].y - xy[i - 1].y, 2),
    );
  }
  return total;
}

/// An area for the screen: "124 m²", or "1.2 ha" from 10,000 m².
String formatArea(double areaM2) {
  if (areaM2 >= 10000) return '${(areaM2 / 10000).toStringAsFixed(1)} ha';
  return '${areaM2.round()} m²';
}

/// A length for the screen: "48 m", or "1.2 km" from 1,000 m.
String formatLength(double metres) {
  if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
  return '${metres.round()} m';
}

// --- Self-intersection ------------------------------------------------------

/// -1, 0 or 1: which side of the line a-b the point c is on (0 = on the line).
int _side(_Xy a, _Xy b, _Xy c) {
  final cross = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
  if (cross.abs() < _collinearEps) return 0;
  return cross > 0 ? 1 : -1;
}

/// The point [p], known to be on the line a-b, lies between a and b.
bool _onSegment(_Xy a, _Xy b, _Xy p) {
  const slack = 1e-9;
  return p.x >= min(a.x, b.x) - slack &&
      p.x <= max(a.x, b.x) + slack &&
      p.y >= min(a.y, b.y) - slack &&
      p.y <= max(a.y, b.y) + slack;
}

/// Segments a-b and c-d share at least one point (touching counts).
bool _segmentsMeet(_Xy a, _Xy b, _Xy c, _Xy d) {
  final s1 = _side(a, b, c);
  final s2 = _side(a, b, d);
  final s3 = _side(c, d, a);
  final s4 = _side(c, d, b);
  if (s1 != s2 && s3 != s4) return true;
  if (s1 == 0 && _onSegment(a, b, c)) return true;
  if (s2 == 0 && _onSegment(a, b, d)) return true;
  if (s3 == 0 && _onSegment(c, d, a)) return true;
  if (s4 == 0 && _onSegment(c, d, b)) return true;
  return false;
}

/// Edges u-v and v-w, which share the point v, run back over each other (a
/// spike): they are on one line and both go the same way away from v.
bool _foldsBack(_Xy u, _Xy v, _Xy w) {
  if (_side(u, v, w) != 0) return false;
  final dot = (u.x - v.x) * (w.x - v.x) + (u.y - v.y) * (w.y - v.y);
  return dot > 0;
}

/// [points] without a repeat of the same point right after itself.
List<_Xy> _withoutRepeats(List<_Xy> points) {
  final result = <_Xy>[];
  for (final p in points) {
    if (result.isNotEmpty) {
      final last = result.last;
      if (sqrt(pow(p.x - last.x, 2) + pow(p.y - last.y, 2)) < _samePointM) {
        continue;
      }
    }
    result.add(p);
  }
  return result;
}

/// True when the edges of the path [path] cross, touch or run over each other
/// where they should not. [closed] adds the edge from the last point back to
/// the first.
bool _edgesProblem(List<_Xy> path, {required bool closed}) {
  final n = path.length;
  final edgeCount = closed ? n : n - 1;
  for (var i = 0; i < edgeCount; i++) {
    final a = path[i];
    final b = path[(i + 1) % n];
    for (var j = i + 1; j < edgeCount; j++) {
      final c = path[j];
      final d = path[(j + 1) % n];
      final adjacent = j == i + 1 || (closed && i == 0 && j == edgeCount - 1);
      if (!adjacent) {
        if (_segmentsMeet(a, b, c, d)) return true;
      } else if (j == i + 1) {
        if (_foldsBack(a, b, d)) return true;
      } else {
        // The closing edge meets the first edge at path[0].
        if (_foldsBack(b, a, c)) return true;
      }
    }
  }
  return false;
}

/// True when the polygon with the corners [points] is not a valid ring: edges
/// that cross, a corner touching another edge, an edge folded back over the
/// last one, fewer than 3 different points, or an area under 0.01 m². The ring
/// may or may not repeat its first point at the end. This is the question PostGIS
/// answers with `ST_IsValid`, so the phone refuses what the server would.
bool polygonSelfIntersects(List<LatLng> points) {
  if (points.length < 3) return true;
  var ring = _withoutRepeats(_project(points));
  // A closing point equal to the first one is not a corner.
  if (ring.length > 1) {
    final first = ring.first;
    final last = ring.last;
    if (sqrt(pow(first.x - last.x, 2) + pow(first.y - last.y, 2)) <
        _samePointM) {
      ring = ring.sublist(0, ring.length - 1);
    }
  }
  if (ring.length < 3) return true;
  if (_signedArea2(ring).abs() / 2 < _minAreaM2) return true;
  return _edgesProblem(ring, closed: true);
}

/// True when the unfinished outline through [points] already crosses itself or
/// folds back. Used to warn while the user is still adding corners; the closing
/// edge is not part of it.
bool chainSelfIntersects(List<LatLng> points) {
  if (points.length < 3) return false;
  return _edgesProblem(_withoutRepeats(_project(points)), closed: false);
}

// --- GeoJSON ----------------------------------------------------------------

/// A geometry read from GeoJSON text: its type and its points as latitude and
/// longitude. A polygon has only its outer ring, without the repeated first
/// point at the end.
class ParsedGeometry {
  const ParsedGeometry(this.type, this.points);

  /// `Point`, `LineString` or `Polygon`.
  final String type;
  final List<LatLng> points;
}

/// Reads GeoJSON text of a Point, LineString or Polygon. Any other type, or
/// text that is not a usable GeoJSON object, gives null, so one bad row cannot
/// break a whole screen (as `parseLineString` does).
ParsedGeometry? parseGeometry(String geoJson) {
  try {
    final json = jsonDecode(geoJson);
    if (json is! Map<String, dynamic>) return null;
    final type = json['type'];
    final coordinates = json['coordinates'];
    switch (type) {
      case 'Point':
        final point = _readPosition(coordinates);
        return point == null ? null : ParsedGeometry('Point', [point]);
      case 'LineString':
        final points = _readPositions(coordinates);
        return points == null ? null : ParsedGeometry('LineString', points);
      case 'Polygon':
        if (coordinates is! List<dynamic> || coordinates.isEmpty) return null;
        final ring = _readPositions(coordinates.first);
        if (ring == null) return null;
        if (ring.length > 1 &&
            ring.first.latitude == ring.last.latitude &&
            ring.first.longitude == ring.last.longitude) {
          ring.removeLast();
        }
        return ParsedGeometry('Polygon', ring);
    }
  } on FormatException {
    return null;
  }
  return null;
}

LatLng? _readPosition(Object? position) {
  if (position is! List<dynamic> || position.length < 2) return null;
  final lon = position[0];
  final lat = position[1];
  if (lon is! num || lat is! num) return null;
  if (!lon.isFinite || !lat.isFinite) return null;
  return LatLng(lat.toDouble(), lon.toDouble());
}

List<LatLng>? _readPositions(Object? positions) {
  if (positions is! List<dynamic>) return null;
  final result = <LatLng>[];
  for (final position in positions) {
    final point = _readPosition(position);
    if (point == null) return null;
    result.add(point);
  }
  return result;
}
