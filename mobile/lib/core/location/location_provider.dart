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

final currentPositionProvider = Provider<Future<Position> Function()>((ref) {
  final geo = ref.watch(locationProvider);

  return () async {
    if (!await geo.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceOff);
    }

    var permission = await geo.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await geo.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationFailure.denied);
    }

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
    }
  };
});
