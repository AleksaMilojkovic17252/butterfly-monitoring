import 'package:flutter/material.dart';

/// A yes/no/unknown answer (T052): eggs, larvae and feeding damage on a plant.
/// Unknown is null, because not looking is different from looking and seeing
/// nothing.
class TriStateField extends StatelessWidget {
  const TriStateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;

  /// True for Yes, false for No, null for Unknown.
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        SegmentedButton<bool?>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: null, label: Text('Unknown')),
            ButtonSegment(value: true, label: Text('Yes')),
            ButtonSegment(value: false, label: Text('No')),
          ],
          selected: {value},
          onSelectionChanged: (selected) => onChanged(selected.first),
        ),
      ],
    );
  }
}
