import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

enum LocationFailure { serviceOff, denied, deniedForever, unavailable }

final locationProvider = Provider<GeolocatorPlatform>(
  (_) => GeolocatorPlatform.instance,
);

class LocationException implements Exception {
  const LocationException(this.failure);
  final LocationFailure failure;
}

/// Checks that the location service is on and the app may use it, asking
/// for the permission when it has not been answered yet. Returns why location
/// cannot be used, or null when it can. Shared by both providers below.
Future<LocationFailure?> _checkLocationAllowed(GeolocatorPlatform geo) async {
  if (!await geo.isLocationServiceEnabled()) return LocationFailure.serviceOff;

  var permission = await geo.checkPermission();
  if (permission == LocationPermission.denied) {
    try {
      permission = await geo.requestPermission();
    } on PermissionRequestInProgressException {
      // The permission dialog is already open (another request asked first).
      return LocationFailure.denied;
    }
  }
  return switch (permission) {
    LocationPermission.deniedForever => LocationFailure.deniedForever,
    LocationPermission.denied => LocationFailure.denied,
    _ => null,
  };
}

final currentPositionProvider = Provider<Future<Position> Function()>((ref) {
  final geo = ref.watch(locationProvider);

  return () async {
    final failure = await _checkLocationAllowed(geo);
    if (failure != null) throw LocationException(failure);

    try {
      return await geo.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      final last = await geo.getLastKnownPosition();
      if (last == null) {
        throw const LocationException(LocationFailure.unavailable);
      }
      return last;
    } on LocationServiceDisabledException {
      // Location was switched off after the check above.
      throw const LocationException(LocationFailure.serviceOff);
    } on PermissionDeniedException {
      throw const LocationException(LocationFailure.denied);
    }
  };
});

/// The phone's last known position, or null when location is off, not
/// allowed, or there is no fix yet. Used for the distances in the transect
/// list (T033): it does not wait for a new GPS fix, only for the permission
/// answer the first time. `autoDispose`, so each visit to the list asks
/// again instead of keeping the first answer for the whole session.
/// Invalidate it after taking a fresh fix with [currentPositionProvider].
final lastKnownPositionProvider = FutureProvider.autoDispose<Position?>((
  ref,
) async {
  final geo = ref.watch(locationProvider);
  if (await _checkLocationAllowed(geo) != null) return null;
  return geo.getLastKnownPosition();
});
