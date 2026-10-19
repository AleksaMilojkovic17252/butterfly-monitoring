import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';

/// Id of the project the user opened last. The app starts on its home
/// screen instead of the project list.
class LastProjectNotifier extends Notifier<String?> {
  static const _key = 'last_project_id';

  @override
  String? build() => ref.read(sharedPreferencesProvider).getString(_key);

  Future<void> select(String id) async {
    await ref.read(sharedPreferencesProvider).setString(_key, id);
    state = id;
  }

  Future<void> clear() async {
    await ref.read(sharedPreferencesProvider).remove(_key);
    state = null;
  }
}

final lastProjectProvider = NotifierProvider<LastProjectNotifier, String?>(
  LastProjectNotifier.new,
);
