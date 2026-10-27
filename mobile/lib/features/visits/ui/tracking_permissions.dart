import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/shared_preferences_provider.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Set once the battery-optimisation question has been asked.
const _batteryPromptedKey = 'battery_optimisation_prompted';

/// Asks for what GPS tracking needs, before a visit starts (T037):
/// - location, if it has not been answered yet;
/// - notifications (Android 13+), so the "Visit in progress" notification is
///   shown in the notification shade and not only in the task manager;
/// - once per install: to leave the app out of battery optimisation, since
///   some phones stop a foreground service with the screen off.
///
/// Called before the visit is saved as started: tracking starts as soon as
/// it is, and Android 14 allows a location service to start only while the
/// app is in front, not under a system dialog. A refusal does not block the
/// start; the tracking card then says what is missing.
Future<void> prepareTracking(BuildContext context, WidgetRef ref) async {
  await checkLocationAllowed(ref.read(locationProvider));
  await Permission.notification.request();

  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs.getBool(_batteryPromptedKey) ?? false) return;
  if (await Permission.ignoreBatteryOptimizations.isGranted) {
    await prefs.setBool(_batteryPromptedKey, true);
    return;
  }
  if (!context.mounted) return;

  final allow = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.battery_alert_outlined),
      title: const Text('Keep recording with the screen off'),
      content: const Text(
        'Some phones stop GPS recording when the screen is off to save '
        'battery. Allow this app to run without battery restrictions so the '
        'whole route is recorded.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
  // Asked once, whatever the answer.
  await prefs.setBool(_batteryPromptedKey, true);
  if (allow == true) {
    // Opens Android's own "Let app always run in background?" dialog.
    await Permission.ignoreBatteryOptimizations.request();
  }
}
