import 'package:flutter/material.dart';

/// One tile of the project home grid: an icon (with an optional count) and a
/// label.
class ProjectHomeTile extends StatelessWidget {
  const ProjectHomeTile({
    super.key,
    required this.icon,
    required this.label,
    this.badge = 0,
    this.onTap,
  });
  final IconData icon;
  final String label;

  /// Number shown on the icon; hidden when 0.
  final int badge;

  /// Opens the tile's screen; null keeps the "coming later" snackbar.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            onTap ??
            () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text('$label is coming in a later version')),
              ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: Icon(icon, size: 36, color: scheme.primary),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
