import 'package:flutter/material.dart';

/// Small "Inactive" label: the transect is no longer walked.
class InactiveTag extends StatelessWidget {
  const InactiveTag({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Inactive',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: scheme.onErrorContainer),
      ),
    );
  }
}
