import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/server_preset.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';

class ServerUrlNotifier extends Notifier<String> {
  static const _key = 'server_url';

  @override
  String build() {
    return ref.read(sharedPreferencesProvider).getString(_key) ??
        ServerPreset.usb.url;
  }

  String? normalizeServerUrl(String input) {
    final url = input.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(url);
    final valid =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        !url.contains('<');
    if (!valid) return null;
    return url;
  }

  Future<bool> save(String input) async {
    final url = normalizeServerUrl(input);
    if (url == null) return false;
    await ref.read(sharedPreferencesProvider).setString(_key, url);
    state = url;
    return true;
  }
}

final serverUrlProvider = NotifierProvider<ServerUrlNotifier, String>(
  ServerUrlNotifier.new,
);
