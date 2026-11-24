import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/location/location_provider.dart';

/// The phone's position for the blue "you are here" dot on the project map.
///
/// Starts with the last known position, so the dot shows at once, then a fix
/// about every 2 s. Use it only away from a tracked visit or a route
/// recording: geolocator keeps one position stream for the whole app, so
/// while those run the map shows their newest fix instead and never watches
/// this (D-087, as for [walkPositionsProvider]).
///
/// `autoDispose`: the GPS is released as soon as the map is closed. A missing
/// permission or a switched-off location arrives as a [LocationException] in
/// the stream's error.
final mapPositionsProvider = StreamProvider.autoDispose<Position>((ref) async* {
  final geo = ref.watch(locationProvider);
  final failure = await checkLocationAllowed(geo);
  if (failure != null) throw LocationException(failure);

  final last = await geo.getLastKnownPosition();
  if (last != null) yield last;

  yield* geo.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: const Duration(seconds: 15),
      distanceFilter: 0,
    ),
  );
});
