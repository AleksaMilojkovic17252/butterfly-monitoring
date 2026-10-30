import 'package:flutter/material.dart';

/// One tile of the project home grid: an icon (with an optional count) and a
/// label. A tile without [onTap] is drawn disabled, with "Coming later".
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

  /// Opens the tile's screen. Null means the screen is not built yet: the
  /// tile is greyed out, has no ripple and says "Coming later" (T105).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final disabled = onTap == null;
    final fadedColor = scheme.onSurface.withValues(alpha: 0.38);

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Badge(
          isLabelVisible: badge > 0,
          label: Text('$badge'),
          child: Icon(
            icon,
            size: 36,
            color: disabled ? fadedColor : scheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: disabled ? TextStyle(color: fadedColor) : null,
        ),
        if (disabled)
          Text(
            'Coming later',
            style: textTheme.labelSmall?.copyWith(color: fadedColor),
          ),
      ],
    );

    return Card(
      child: disabled
          // Read out as one disabled button, so TalkBack says why it does
          // nothing.
          ? Semantics(
              button: true,
              enabled: false,
              label: '$label, coming later',
              excludeSemantics: true,
              child: content,
            )
          : InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: content,
            ),
    );
  }
}
