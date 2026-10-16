import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/sync/sync_status.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _formatSyncTime(DateTime? time) {
    if (time == null) return 'Never synced';
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Last sync ${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_email.text, _password.text);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final lastSync = ref.watch(lastSyncProvider);

    return Scaffold(
      backgroundColor: AppColors.forest,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Server settings',
                      color: Colors.white,
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => context.push('/settings'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 12),
                  Text(
                    'Butterfly Monitoring',
                    style: text.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 38),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Log in',
                              style: text.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (String? value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty) return 'Enter your email';
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(v)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscure
                                      ? 'Show password'
                                      : 'Hide password',
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your password';
                                }
                                return null;
                              },
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: scheme.errorContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: scheme.onErrorContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: scheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: _busy
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text('Log in'),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sync,
                                  size: 18,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatSyncTime(lastSync),
                                  style: text.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
