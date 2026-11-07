import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:mobile/core/location/location_source_setting.dart';
import 'package:mobile/core/location/replay_source.dart';

/// Where the GPS tracker (T037) gets its fixes. [GeolocatorSource] is the
/// phone's GPS; [ReplaySource] (T072) plays a GPX track for demos and tests.
abstract class LocationSource {
  /// Fixes every [intervalS] seconds until the subscription is cancelled,
  /// with the given [accuracy] (battery saver, T038, asks for less).
  /// While it runs, Android shows a notification with [title] and [text].
  /// [trackName] is the GPX track a replay plays (a transect code); the
  /// device GPS ignores it.
  Stream<Position> positions({
    required int intervalS,
    required LocationAccuracy accuracy,
    required String title,
    required String text,
    String? trackName,
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
    required LocationAccuracy accuracy,
    required String title,
    required String text,
    String? trackName,
  }) {
    return _geo.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: accuracy,
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

/// The source the tracker uses. The replay setting counts in debug builds
/// only (D-030: there are no product flavours); a release build always uses
/// the phone's GPS.
final locationSourceProvider = Provider<LocationSource>((ref) {
  final choice = ref.watch(locationSourceSettingProvider);
  if (kDebugMode && choice.kind == LocationSourceKind.replay) {
    return ReplaySource(speed: choice.speed);
  }
  return GeolocatorSource(ref.watch(locationProvider));
});
