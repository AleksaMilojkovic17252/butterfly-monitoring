import 'package:flutter/material.dart';
import 'package:mobile/core/validation/visit_values.dart';

/// Bottom sheet that asks why a visit is cancelled (T041): a choice of
/// reasons and an optional note. Used by the Finish screen (the three reasons
/// of a started visit) and by the start form ("not conducted").
class CancelVisitSheet extends StatefulWidget {
  const CancelVisitSheet({
    super.key,
    required this.reasons,
    required this.initialNote,
  });

  /// The reasons to offer, in the order shown. With one reason it is
  /// preselected.
  final List<String> reasons;

  /// The visit's notes so far; the note field starts with them.
  final String initialNote;

  /// Opens the sheet and returns the reason and the note, or null when the
  /// observer goes back (the button, a tap outside or the system back).
  static Future<({String reason, String note})?> show(
    BuildContext context, {
    required List<String> reasons,
    required String initialNote,
  }) {
    return showModalBottomSheet<({String reason, String note})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) =>
          CancelVisitSheet(reasons: reasons, initialNote: initialNote),
    );
  }

  @override
  State<CancelVisitSheet> createState() => _CancelVisitSheetState();
}

class _CancelVisitSheetState extends State<CancelVisitSheet> {
  late final TextEditingController _note;
  String? _reason;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.initialNote);
    if (widget.reasons.length == 1) _reason = widget.reasons.single;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// "Not conducted" is recorded, the others cancel a visit that was started.
  bool get _onlyNotConducted =>
      widget.reasons.length == 1 && widget.reasons.single == 'not_conducted';

  @override
  Widget build(BuildContext context) {
    final reason = _reason;
    return SafeArea(
      child: SingleChildScrollView(
        // Lifts the sheet above the keyboard.
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _onlyNotConducted ? 'Not conducted' : 'Cancel this visit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            RadioGroup<String>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: [
                  for (final value in widget.reasons)
                    RadioListTile<String>(
                      value: value,
                      title: Text(cancelReasonLabel(value)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    // Disabled until a reason is picked.
                    onPressed: reason == null
                        ? null
                        : () => Navigator.pop(context, (
                            reason: reason,
                            note: _note.text.trim(),
                          )),
                    child: Text(
                      _onlyNotConducted
                          ? 'Record as not conducted'
                          : 'Cancel visit',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
