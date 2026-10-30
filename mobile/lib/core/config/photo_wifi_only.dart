import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';

/// Whether photos are uploaded only on Wi-Fi, chosen in Settings (T050).
/// Default off. The sync runner reads it at the start of the upload step, so a
/// change applies from the next sync.
class PhotoWifiOnlyNotifier extends Notifier<bool> {
  static const _key = 'photo_wifi_only';

  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(_key) ?? false;
  }

  /// Saves the choice.
  Future<void> save(bool value) async {
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
    state = value;
  }
}

final photoWifiOnlyProvider = NotifierProvider<PhotoWifiOnlyNotifier, bool>(
  PhotoWifiOnlyNotifier.new,
);
