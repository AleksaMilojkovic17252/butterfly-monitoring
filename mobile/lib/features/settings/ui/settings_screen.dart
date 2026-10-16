import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/config/server_preset.dart';
import 'package:mobile/core/config/server_url_notifier.dart';
import 'package:mobile/core/http/dio_provider.dart';
import 'package:mobile/core/sync/sync_status.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';

enum _LogoutChoice { syncFirst, anyway }

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(serverUrlProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(serverUrlProvider.notifier)
        .save(_controller.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Server URL saved' : 'Enter a valid http(s) URL'),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    final base = ref
        .read(serverUrlProvider.notifier)
        .normalizeServerUrl(_controller.text);
    if (base == null) {
      setState(() {
        _testOk = false;
        _testResult = 'Enter a valid http(s) URL';
      });
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });

    String message;
    bool ok = false;
    try {
      final response = await ref.read(dioProvider).get('$base/api/v1/health/');
      ok = true;
      message = 'Connected (${response.statusCode})';
    } on DioException catch (e) {
      message = switch (e.type) {
        DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
          'Timed out. Is the server reachable?',
        DioExceptionType.connectionError => "Can't reach the server",
        DioExceptionType.badResponse =>
          'Server answered ${e.response?.statusCode}',
        _ => 'Request failed',
      };
    } catch (_) {
      message = 'Invalid URL';
    }

    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = ok;
      _testResult = message;
    });
  }

  Future<void> _logout() async {
    final pending = ref.read(pendingChangesProvider).value ?? 0;
    if (pending > 0) {
      final choice = await showDialog<_LogoutChoice>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.sync_problem_outlined),
          title: const Text('Unsynced changes'),
          content: Text(
            '$pending changes not yet synced. They stay on this phone, but '
            'sync first so they reach the server.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _LogoutChoice.anyway),
              child: const Text('Log out anyway'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _LogoutChoice.syncFirst),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              child: const Text('Sync first'),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      if (choice == _LogoutChoice.syncFirst) {
        final ok = await ref.read(syncNowProvider)();
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync did not finish. Still logged in.'),
            ),
          );
          return;
        }
      }
    }
    await ref.read(authControllerProvider.notifier).logout();
  }

  Future<void> _removeLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.delete_forever_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Remove all local data?'),
        content: const Text(
          'Every visit, route and observation stored on this phone is deleted, '
          'including changes that were never synced. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).removeAllLocalData();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).profile;
    final offline = ref.watch(authControllerProvider) is OfflineSession;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (profile != null) ...[
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(profile.displayName),
                      subtitle: Text(
                        offline ? '${profile.email} · offline' : profile.email,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Log out'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _removeLocalData,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .error,
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove data'),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                ],
                TextFormField(
                  decoration: const InputDecoration(label: Text('URL')),
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  onChanged: (_) {
                    setState(() {
                      _testResult = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a server URL';
                    }
                    return null;
                  },
                  controller: _controller,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final preset in ServerPreset.values)
                      ActionChip(
                        label: Text(preset.label),
                        onPressed: () {
                          setState(() {
                            _testResult = null;
                          });
                          _controller.text = preset.url;
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _testing ? null : _testConnection,
                      child: Text(_testing ? 'Testing…' : 'Test Connection'),
                    ),
                    ElevatedButton(
                      onPressed: _saveItem,
                      child: const Text('Save'),
                    ),
                  ],
                ),
                if (_testResult != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _testResult!,
                    style: TextStyle(
                      color: _testOk
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.push('/skeleton'),
                    child: const Text('Skeleton pings (debug)'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
