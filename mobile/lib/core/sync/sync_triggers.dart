import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/sync/sync_runner.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';

/// Starts a sync when it is time for one: on login or app start, when the app
/// returns to the foreground, and every 15 minutes while it stays there. Each
/// trigger only fires while someone is logged in (an offline session counts).
/// `App` watches this provider to keep it alive.
final syncTriggersProvider = Provider<void>((ref) {
  var wasOffline = false;
  Timer? timer;

  /// Starts a run unless nobody is logged in. If one is already going, the
  /// runner joins it, so overlapping triggers do no harm.
  void syncIfLoggedIn() {
    if (ref.read(authControllerProvider).profile == null) {
      return;
    }
    unawaited(ref.read(syncRunnerProvider.notifier).run());
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => syncIfLoggedIn(),
    );
  }

  final connectivity = Connectivity().onConnectivityChanged.listen((results) {
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (wasOffline && !offline) {
      syncIfLoggedIn();
    }
    wasOffline = offline;
  });

  // The stream only reports changes, so read the state the app starts in.
  unawaited(
    Connectivity().checkConnectivity().then((results) {
      wasOffline = results.every((r) => r == ConnectivityResult.none);
    }),
  );

  final lifecycle = AppLifecycleListener(
    onResume: () {
      syncIfLoggedIn();
      startTimer();
    },
    onPause: () {
      timer?.cancel();
      timer = null;
    },
  );

  // The app starts in the foreground, so the timer starts now.
  startTimer();

  ref.listen(authControllerProvider, (previous, next) {
    if (previous?.profile == null && next.profile != null) {
      unawaited(ref.read(syncRunnerProvider.notifier).run());
    }
  }, fireImmediately: true);

  // TODO(T040): the finish-visit flow calls syncRunnerProvider.run().

  ref.onDispose(() {
    timer?.cancel();
    lifecycle.dispose();
    connectivity.cancel();
  });
});
