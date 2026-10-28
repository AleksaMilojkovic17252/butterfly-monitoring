import 'package:flutter/material.dart';

/// Shown on the active visit screen while the visit is paused.
class PausedBanner extends StatelessWidget {
  const PausedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(Icons.pause_circle, color: scheme.onTertiaryContainer),
        title: Text(
          'Paused. No route is recorded and the time stands still.',
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
      ),
    );
  }
}
