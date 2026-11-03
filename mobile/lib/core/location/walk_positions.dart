import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/location/location_provider.dart';

/// Fixes every second for "Polygon (walk)" (T052): the user walks the edge of
/// a patch and the capture keeps a vertex about every 2 m.
///
/// Use it only away from a tracked visit. geolocator keeps one position
/// stream for the whole app: while the visit's tracker records, asking for a
/// new stream returns the tracker's own 5 s stream and ignores these settings
/// (D-087). During a visit the capture listens to the tracker's last fix
/// instead (`TrackingController.lastPosition`) and never watches this.
///
/// No foreground notification, so the screen must stay on while walking (the
/// capture holds a wakelock). `autoDispose`: the GPS is released as soon as
/// nothing watches the stream. A missing permission or a switched-off
/// location arrives as a [LocationException] in the stream's error.
final walkPositionsProvider = StreamProvider.autoDispose<Position>((
  ref,
) async* {
  final geo = ref.watch(locationProvider);
  final failure = await checkLocationAllowed(geo);
  if (failure != null) throw LocationException(failure);
  yield* geo.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.best,
      intervalDuration: const Duration(seconds: 1),
      // Every fix; the capture decides which ones to keep.
      distanceFilter: 0,
    ),
  );
});
