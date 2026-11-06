import 'package:flutter/material.dart';

/// Replaces the visit buttons of the active visit screen when an admin has
/// closed the project (T099, D-104). The server accepts nothing more for the
/// visit, so it cannot be finished; the only thing left is to cancel it on this
/// phone ([onCancel]).
class ClosedVisitBar extends StatelessWidget {
  const ClosedVisitBar({super.key, required this.onCancel});
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'This project is closed, so this visit cannot be finished.',
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCancel,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel visit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
