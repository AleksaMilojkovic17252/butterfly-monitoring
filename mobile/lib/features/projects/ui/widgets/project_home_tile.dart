import 'package:flutter/material.dart';

/// One tile of the project home grid: an icon (with an optional count) and a
/// label. A tile without [onTap] is drawn disabled, with "Coming later" or
/// the [disabledText] it was given (an empty one shows no line).
class ProjectHomeTile extends StatelessWidget {
  const ProjectHomeTile({
    super.key,
    required this.icon,
    required this.label,
    this.badge = 0,
    this.onTap,
    this.disabledText = 'Coming later',
  });
  final IconData icon;
  final String label;

  /// Number shown on the icon; hidden when 0.
  final int badge;

  /// Opens the tile's screen. Null means the screen is not built yet: the
  /// tile is greyed out, has no ripple and says "Coming later" (T105).
  final VoidCallback? onTap;

  /// The line shown under a disabled tile. A closed project's tiles pass ''
  /// (greyed out, no line, T099).
  final String disabledText;

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
        if (disabled && disabledText.isNotEmpty)
          Text(
            disabledText,
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
              label: disabledText.isEmpty ? label : '$label, $disabledText',
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
