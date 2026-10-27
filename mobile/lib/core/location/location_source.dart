import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/location/location_provider.dart';

/// Where the GPS tracker (T037) gets its fixes. [GeolocatorSource] is the
/// phone's GPS; T072 adds a replay of a GPX file for demos and tests.
abstract class LocationSource {
  /// Fixes every [intervalS] seconds until the subscription is cancelled.
  /// While it runs, Android shows a notification with [title] and [text].
  Stream<Position> positions({
    required int intervalS,
    required String title,
    required String text,
  });
}

/// The phone's GPS through geolocator. The stream runs in geolocator's
/// Android foreground service, so fixes keep coming with the screen off.
/// The service lives as long as the subscription and the Flutter engine:
/// swiping the app away stops it, and the tracker resumes on the next start.
class GeolocatorSource implements LocationSource {
  GeolocatorSource(this._geo);
  final GeolocatorPlatform _geo;

  @override
  Stream<Position> positions({
    required int intervalS,
    required String title,
    required String text,
  }) {
    return _geo.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: Duration(seconds: intervalS),
        // Every fix, also when standing still: the interval decides.
        distanceFilter: 0,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: title,
          notificationText: text,
          notificationChannelName: 'Visit tracking',
          // The user cannot swipe the notification away.
          setOngoing: true,
          // Keeps the CPU awake with the screen off, so fixes are handled.
          enableWakeLock: true,
        ),
      ),
    );
  }
}

final locationSourceProvider = Provider<LocationSource>(
  (ref) => GeolocatorSource(ref.watch(locationProvider)),
);
