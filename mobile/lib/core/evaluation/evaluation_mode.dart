import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';
import 'package:uuid/uuid.dart';

/// Whether Evaluation mode is on, and the id of the current session (T073).
/// [sessionId] is null while the mode has never been switched on.
class EvaluationMode {
  const EvaluationMode({required this.enabled, this.sessionId});
  final bool enabled;
  final String? sessionId;
}

/// Keeps the Evaluation mode switch and the session id in SharedPreferences.
/// The session id is made the first time the mode is switched on and again on
/// [newSession]; switching off and on keeps it, so one test person's events
/// share one id.
class EvaluationModeNotifier extends Notifier<EvaluationMode> {
  static const _enabledKey = 'evaluation_mode';
  static const _sessionKey = 'evaluation_session_id';

  @override
  EvaluationMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return EvaluationMode(
      enabled: prefs.getBool(_enabledKey) ?? false,
      sessionId: prefs.getString(_sessionKey),
    );
  }

  /// Switches the mode on or off. Switching on continues the current session,
  /// and starts one only when there is none yet.
  Future<void> setEnabled(bool value) async {
    if (value) {
      if (state.sessionId == null) {
        await newSession(enabled: true);
      } else {
        await ref.read(sharedPreferencesProvider).setBool(_enabledKey, true);
        state = EvaluationMode(enabled: true, sessionId: state.sessionId);
      }
      return;
    }
    await ref.read(sharedPreferencesProvider).setBool(_enabledKey, false);
    state = EvaluationMode(enabled: false, sessionId: state.sessionId);
  }

  /// Starts a new session id; the mode is on afterwards.
  Future<void> newSession({bool enabled = true}) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final id = const Uuid().v4();
    await prefs.setBool(_enabledKey, enabled);
    await prefs.setString(_sessionKey, id);
    state = EvaluationMode(enabled: enabled, sessionId: id);
  }
}

final evaluationModeProvider =
    NotifierProvider<EvaluationModeNotifier, EvaluationMode>(
      EvaluationModeNotifier.new,
    );
