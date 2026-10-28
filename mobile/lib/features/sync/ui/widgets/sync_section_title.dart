import 'package:flutter/material.dart';

/// A section heading of the sync status screen. A Card has a 4 px margin of
/// its own, so the heading gets the same, and its text starts where the
/// cards do.
class SyncSectionTitle extends StatelessWidget {
  const SyncSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
