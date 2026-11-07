import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/location/location_source.dart';

/// One point of a GPX track: where, and when the simulator put it there.
class GpxPoint {
  const GpxPoint({required this.lat, required this.lon, required this.time});
  final double lat;
  final double lon;
  final DateTime time;
}

/// One named track of a GPX file (`<trk>`), for example the transect `FG1`.
class GpxTrack {
  const GpxTrack({required this.name, required this.points});
  final String name;
  final List<GpxPoint> points;
}

/// Reads every `<trk>` of [gpx]. This is not a general GPX parser: the file is
/// our own output (`simulate_season`, T071), so the tags are assumed to look
/// like `<trkpt lat=".." lon=".."><time>..</time></trkpt>`.
List<GpxTrack> parseGpxTracks(String gpx) {
  final nameTag = RegExp(r'<name>(.*?)</name>');
  final pointTag = RegExp(
    r'<trkpt lat="([^"]+)" lon="([^"]+)">\s*<time>([^<]+)</time>',
  );
  final tracks = <GpxTrack>[];
  // The text before the first `<trk>` is the file header, so skip it.
  for (final part in gpx.split('<trk>').skip(1)) {
    final points = [
      for (final m in pointTag.allMatches(part))
        GpxPoint(
          lat: double.parse(m.group(1)!),
          lon: double.parse(m.group(2)!),
          time: DateTime.parse(m.group(3)!),
        ),
    ];
    tracks.add(
      GpxTrack(name: nameTag.firstMatch(part)?.group(1) ?? '', points: points),
    );
  }
  return tracks;
}

/// Plays a track of the bundled GPX file as if it were the phone's GPS (T072),
/// for demos and for running a whole visit indoors. Debug builds only.
///
/// - The GPX times only set the pace: the wait between two points is the GPX
///   gap divided by [speed] (1x is 5 s, 5x is 1 s, 20x is 0.25 s).
/// - Every position is stamped with the phone's clock now, so it lands inside
///   the visit's time window. [positions] ignores `intervalS`.
/// - The positions are marked as mocked, so they are stored as `simulated`.
/// - After the last point the source keeps repeating it ("standing at the
///   end"), so the GPS gap banner does not fire while the observer finishes.
/// - Every new stream starts again at the first point.
/// - There is no foreground service: keep the app open while it runs.
class ReplaySource implements LocationSource {
  ReplaySource({required this.speed});

  /// How many times faster than the GPX clock the points arrive: 1, 5 or 20.
  final int speed;

  /// The bundled copy of `database/seeds/transects.gpx` (see docs/setup/gps-replay.md).
  static const assetPath = 'assets/replay/transects.gpx';

  /// Seconds between points when the track has nothing to measure a gap from.
  static const _defaultGapS = 5;

  @override
  Stream<Position> positions({
    required int intervalS,
    required LocationAccuracy accuracy,
    required String title,
    required String text,
    String? trackName,
  }) async* {
    final tracks = parseGpxTracks(await rootBundle.loadString(assetPath));
    if (tracks.isEmpty || tracks.first.points.isEmpty) {
      // The tracker shows this as a location problem.
      throw StateError('No track points found in $assetPath');
    }
    // The visit's transect when the file has a track of that name, else the first.
    final track = tracks.firstWhere(
      (t) => t.name == trackName && t.points.isNotEmpty,
      orElse: () => tracks.first,
    );
    final points = track.points;

    yield _position(points, 0);
    for (var i = 1; i < points.length; i++) {
      await Future.delayed(_wait(_gapMs(points, i)));
      yield _position(points, i);
    }

    // End of the track: stand still on the last point at the last pace.
    final last = points.length - 1;
    final lastGap = last > 0 ? _gapMs(points, last) : _defaultGapS * 1000;
    while (true) {
      await Future.delayed(_wait(lastGap));
      yield _position(points, last, standing: true);
    }
  }

  /// Milliseconds between point [i] and the one before it in the GPX, or the
  /// default gap when the times do not increase.
  int _gapMs(List<GpxPoint> points, int i) {
    final gap = points[i].time.difference(points[i - 1].time).inMilliseconds;
    return gap > 0 ? gap : _defaultGapS * 1000;
  }

  /// The real wait for a GPX gap of [gapMs] milliseconds at the chosen speed.
  Duration _wait(int gapMs) => Duration(milliseconds: gapMs ~/ speed);

  /// The position for point [i]. Speed (metres per GPX second) and heading
  /// come from the step before it; the first point uses the step after it.
  /// A [standing] position repeats the last point with speed 0.
  Position _position(List<GpxPoint> points, int i, {bool standing = false}) {
    final point = points[i];
    var speedMS = 0.0;
    var heading = 0.0;
    if (points.length > 1) {
      final from = i > 0 ? points[i - 1] : point;
      final to = i > 0 ? point : points[1];
      final gapS = to.time.difference(from.time).inMilliseconds / 1000;
      if (!standing && gapS > 0) {
        final metres = Geolocator.distanceBetween(
          from.lat,
          from.lon,
          to.lat,
          to.lon,
        );
        speedMS = metres / gapS;
      }
      heading = Geolocator.bearingBetween(from.lat, from.lon, to.lat, to.lon);
      // bearingBetween gives -180..180; the server takes 0..360.
      if (heading < 0) heading += 360;
    }
    return Position(
      latitude: point.lat,
      longitude: point.lon,
      timestamp: DateTime.now().toUtc(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: heading,
      headingAccuracy: 0,
      speed: speedMS,
      speedAccuracy: 0,
      isMocked: true,
      hasAccuracy: true,
      hasAltitude: true,
      hasHeading: true,
      hasSpeed: true,
    );
  }
}
