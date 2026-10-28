import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The remembered project is no longer on this phone (for example after
/// "Remove data").
class MissingProjectView extends StatelessWidget {
  const MissingProjectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This project is not on this phone.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('All projects'),
            ),
          ],
        ),
      ),
    );
  }
}
