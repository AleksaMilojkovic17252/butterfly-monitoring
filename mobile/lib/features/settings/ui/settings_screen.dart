import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/server_preset.dart';
import 'package:mobile/core/config/server_url_notifier.dart';
import 'package:mobile/core/http/dio_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
