import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:mobile/features/skeleton/data/skeleton_ping_repository.dart';
import 'package:mobile/features/skeleton/ui/widgets/ping_tile.dart';

// T044: delete with the skeleton.
final skeletonPingsProvider = StreamProvider<List<SkeletonPing>>(
  (ref) => ref.watch(skeletonPingRepositoryProvider).watchAll(),
);

class SkeletonScreen extends ConsumerStatefulWidget {
  const SkeletonScreen({super.key});

  @override
  ConsumerState<SkeletonScreen> createState() => _SkeletonScreenState();
}

class _SkeletonScreenState extends ConsumerState<SkeletonScreen> {
  final _noteController = TextEditingController();
  bool _dropping = false;
  bool _sending = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toast(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  Future<void> _dropPing() async {
    setState(() => _dropping = true);
    String? message;
    SnackBarAction? action;
    try {
      await ref
          .read(skeletonPingRepositoryProvider)
          .dropPing(_noteController.text);
      _noteController.clear();
      message = 'Ping saved';
    } on LocationException catch (e) {
      message = switch (e.failure) {
        LocationFailure.serviceOff => 'Turn on your location service',
        LocationFailure.denied => 'Location permission denied',
        LocationFailure.deniedForever => 'Enable location in app settings',
        LocationFailure.unavailable => 'No location available yet, try again',
      };
      if (e.failure == LocationFailure.deniedForever) {
        action = SnackBarAction(
          label: 'Settings',
          onPressed: () => ref.read(locationProvider).openAppSettings(),
        );
      }
    } catch (_) {
      message = 'Could not save the ping';
    }
    if (!mounted) return;
    setState(() => _dropping = false);
    _toast(message, action: action);
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    String message;
    try {
      final result = await ref
          .read(skeletonPingRepositoryProvider)
          .sendPending();
      message = result.sent == 0 && result.failed == 0
          ? 'Nothing to send'
          : 'Sent ${result.sent}, failed ${result.failed}';
    } catch (_) {
      message = 'Send failed';
    }
    if (!mounted) return;
    setState(() => _sending = false);
    _toast(message);
  }

  @override
  Widget build(BuildContext context) {
    final pings = ref.watch(skeletonPingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Skeleton pings')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            TextField(
              controller: _noteController,
              maxLength: 200,
              decoration: const InputDecoration(label: Text('Note')),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _dropping ? null : _dropPing,
                    child: Text(_dropping ? 'Locating…' : 'Drop ping'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    child: Text(_sending ? 'Sending…' : 'Send'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: pings.when(
                data: (rows) => rows.isEmpty
                    ? const Center(child: Text('No pings yet'))
                    : ListView.builder(
                        itemCount: rows.length,
                        itemBuilder: (_, i) => PingTile(ping: rows[i]),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
