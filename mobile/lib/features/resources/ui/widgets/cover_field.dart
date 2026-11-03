import 'package:flutter/material.dart';

/// A percentage answer from 0 to 100 in steps of 5 (T054): shrub, tree or bare
/// ground cover. "Not recorded" (null) and 0 % are different answers, so the
/// slider is hidden until the user taps **Record**, and a scroll can never save
/// a false value.
///
/// - [value] null: shows "Not recorded" and Record, which reports 0.
/// - [value] set: shows "N %", the slider and Clear, which reports null.
///
/// The stored number is shown as it is: a value from the server such as 37 is
/// not rounded until the user moves the slider.
class CoverField extends StatelessWidget {
  const CoverField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;

  /// Percent, or null when not recorded.
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            if (current == null) ...[
              Text('Not recorded', style: theme.textTheme.bodyMedium),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => onChanged(0),
                child: const Text('Record'),
              ),
            ] else ...[
              Text('$current %', style: theme.textTheme.bodyLarge),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => onChanged(null),
                child: const Text('Clear'),
              ),
            ],
          ],
        ),
        if (current != null)
          Slider(
            min: 0,
            max: 100,
            divisions: 20,
            value: current.clamp(0, 100).toDouble(),
            label: '$current %',
            onChanged: (v) => onChanged(v.round()),
          ),
      ],
    );
  }
}
