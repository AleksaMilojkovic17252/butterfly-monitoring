import 'package:flutter/material.dart';
import 'package:mobile/features/observations/ui/widgets/count_dialog.dart';

/// A count with large − and + buttons, for one thumb. A long press on the
/// number opens a dialog to type it. The count never goes below 1.
class CountStepper extends StatelessWidget {
  const CountStepper({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  /// Asks for the count in a dialog and passes a valid answer to [onChanged].
  Future<void> _type(BuildContext context) async {
    final typed = await showDialog<int>(
      context: context,
      builder: (context) => CountDialog(initial: value),
    );
    if (typed != null) onChanged(typed);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: 'One less',
          iconSize: 32,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        GestureDetector(
          onLongPress: () => _type(context),
          child: Semantics(
            hint: 'Long press to type a number',
            child: SizedBox(
              width: 72,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'One more',
          iconSize: 32,
          onPressed: value < maxButterflyCount
              ? () => onChanged(value + 1)
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
