import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Most butterflies one entry may hold.
const maxButterflyCount = 9999;

/// The dialog of `CountStepper`: a number field that takes 1 to
/// [maxButterflyCount].
/// It owns its controller, so the controller is disposed with the dialog.
class CountDialog extends StatefulWidget {
  const CountDialog({super.key, required this.initial});
  final int initial;

  @override
  State<CountDialog> createState() => _CountDialogState();
}

class _CountDialogState extends State<CountDialog> {
  late final _controller = TextEditingController(text: '${widget.initial}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The typed number, or null when it is empty or out of range.
  int? get _typed {
    final number = int.tryParse(_controller.text);
    if (number == null || number < 1 || number > maxButterflyCount) return null;
    return number;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How many?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          helperText: '1 to $maxButterflyCount',
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          final typed = _typed;
          if (typed != null) Navigator.pop(context, typed);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _typed == null
              ? null
              : () => Navigator.pop(context, _typed),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
