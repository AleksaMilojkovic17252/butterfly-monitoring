import 'package:flutter/material.dart';
import 'package:mobile/core/geo/polygon_math.dart';
import 'package:mobile/core/validation/proposal_values.dart';

/// What the researcher typed about a route proposal.
class ProposalDetails {
  const ProposalDetails({
    required this.name,
    required this.reason,
    required this.notes,
  });
  final String name;
  final String reason;
  final String notes;
}

/// The sheet that opens on Finish (T108): name, reason and notes of the
/// proposal, with the length and the number of usable GPS fixes of the line.
/// With fewer than two distinct usable fixes there is no line, so Save stays
/// disabled and the sheet says to keep walking.
///
/// [show] returns the details, or null when the sheet was closed.
class ProposalDetailsSheet extends StatefulWidget {
  const ProposalDetailsSheet({
    super.key,
    required this.lengthM,
    required this.fixCount,
    this.drawn = false,
  });

  /// Length of the line in metres.
  final double lengthM;

  /// How many distinct usable fixes the line has.
  final int fixCount;

  /// True for a line drawn on the map: the sheet says "points", not "GPS
  /// fixes".
  final bool drawn;

  /// Opens the sheet. `isScrollControlled` lets it rise above the keyboard.
  static Future<ProposalDetails?> show(
    BuildContext context, {
    required double lengthM,
    required int fixCount,
    bool drawn = false,
  }) {
    return showModalBottomSheet<ProposalDetails>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ProposalDetailsSheet(
        lengthM: lengthM,
        fixCount: fixCount,
        drawn: drawn,
      ),
    );
  }

  @override
  State<ProposalDetailsSheet> createState() => _ProposalDetailsSheetState();
}

class _ProposalDetailsSheetState extends State<ProposalDetailsSheet> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  String? _reason;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _hasLine => widget.fixCount >= 2;

  bool get _canSave =>
      _hasLine && _name.text.trim().isNotEmpty && _reason != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // SafeArea keeps the Save button above the system navigation bar.
    return SafeArea(
      child: Padding(
        // Keeps the form above the keyboard.
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Save route proposal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _hasLine
                    ? 'Length ${formatLength(widget.lengthM)} · '
                          '${widget.fixCount} GPS fixes'
                    : 'Too few GPS fixes to make a line. Keep walking.',
                style: TextStyle(color: _hasLine ? null : scheme.error),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(
                  labelText: 'Reason *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final entry in proposalReasons.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (value) => setState(() => _reason = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _canSave
                    ? () => Navigator.pop(
                        context,
                        ProposalDetails(
                          name: _name.text.trim(),
                          reason: _reason!,
                          notes: _notes.text.trim(),
                        ),
                      )
                    : null,
                child: const Text('Save proposal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
