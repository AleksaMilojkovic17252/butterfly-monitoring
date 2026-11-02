import 'package:flutter/material.dart';
import 'package:mobile/core/validation/observation_rules.dart';
import 'package:mobile/core/validation/observation_values.dart';
import 'package:mobile/core/validation/rule_messages.dart';
import 'package:mobile/features/observations/domain/flight_direction.dart';
import 'package:mobile/features/observations/domain/observation_details.dart';
import 'package:mobile/features/observations/ui/widgets/flight_direction_dial.dart';

/// The Details form of the entry and edit sheets (T046): sex, life stage,
/// behaviour, confidence, microhabitat, flight direction, notes and photos,
/// with the W03/W04 prompts. The parent owns the values: [details] is what is
/// shown and [onChanged] gets the new values after every change.
///
/// [photos] is the sheet's own photo widget (the entry sheet holds drafts, the
/// edit sheet saves right away). Choosing the confidence `photo_required` while
/// [hasPhoto] is false calls [onPhotoNeeded] once; it never blocks a save.
class ObservationDetailsForm extends StatefulWidget {
  const ObservationDetailsForm({
    super.key,
    required this.details,
    required this.onChanged,
    required this.photos,
    required this.hasPhoto,
    required this.onPhotoNeeded,
    this.showFacing = false,
  });
  final ObservationDetails details;
  final ValueChanged<ObservationDetails> onChanged;
  final Widget photos;
  final bool hasPhoto;
  final VoidCallback onPhotoNeeded;

  /// The flight direction dial shows the way the user faces (the entry sheet,
  /// where the user is at the observation). Off when editing later.
  final bool showFacing;

  @override
  State<ObservationDetailsForm> createState() => _ObservationDetailsFormState();
}

class _ObservationDetailsFormState extends State<ObservationDetailsForm> {
  late final _microhabitat = TextEditingController(
    text: widget.details.microhabitat,
  );
  late final _notes = TextEditingController(text: widget.details.notes);

  @override
  void dispose() {
    _microhabitat.dispose();
    _notes.dispose();
    super.dispose();
  }

  ObservationDetails get _details => widget.details;

  /// Switches [value] in the behaviour list.
  void _toggleBehaviour(String value, bool selected) {
    final list = [..._details.behaviour];
    if (selected) {
      list.add(value);
    } else {
      list.remove(value);
    }
    widget.onChanged(_details.copyWith(behaviour: list));
  }

  /// Opens the dial and stores what it returns. Cancel returns null and keeps
  /// the direction; Clear returns `(degrees: null)`.
  Future<void> _pickDirection() async {
    final result = await showFlightDirectionDialog(
      context,
      _details.flightDirectionDeg,
      showFacing: widget.showFacing,
    );
    if (result == null) return;
    widget.onChanged(_details.withDirection(result.degrees));
  }

  /// A dropdown over a codelist, with the labels of `observationValueLabel`.
  /// A stored [value] that is not in [values] (the server added a choice that
  /// this app version does not know) is added to the list, because the dropdown
  /// asserts that exactly one item matches its value.
  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    final items = values.contains(value) ? values : [...values, value];
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final v in items)
          DropdownMenuItem(value: v, child: Text(observationValueLabel(v))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  /// The W03/W04 line and the "Link to host plant" button, disabled until
  /// plant entry exists.
  Widget _hostPlantPrompt(String ruleId) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_florist_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text('${ruleMessage(ruleId)}.')),
            ],
          ),
          const SizedBox(height: 8),
          // TODO(T052): enable this button: pick a plant record of this visit
          // or create one.
          const OutlinedButton(
            onPressed: null,
            child: Text('Link to host plant'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Available once plant entry is added'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final direction = _details.flightDirectionDeg;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _dropdown(
          label: 'Sex',
          value: _details.sex,
          values: sexValues,
          onChanged: (v) => widget.onChanged(_details.copyWith(sex: v)),
        ),
        const SizedBox(height: 16),
        _dropdown(
          label: 'Life stage',
          value: _details.lifeStage,
          values: lifeStageValues,
          onChanged: (v) => widget.onChanged(_details.copyWith(lifeStage: v)),
        ),
        if (w04Applies(_details.lifeStage)) _hostPlantPrompt('W04'),
        const SizedBox(height: 16),
        Text('Behaviour', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final value in behaviourValues)
              FilterChip(
                label: Text(observationValueLabel(value)),
                selected: _details.behaviour.contains(value),
                // The checkmark would change the chip's width and reflow the
                // group when a chip is selected.
                showCheckmark: false,
                onSelected: (selected) => _toggleBehaviour(value, selected),
              ),
          ],
        ),
        if (w03Applies(_details.behaviour)) _hostPlantPrompt('W03'),
        const SizedBox(height: 16),
        _dropdown(
          label: 'Identification confidence',
          value: _details.confidence,
          values: confidenceValues,
          onChanged: (v) {
            final changed = v != _details.confidence;
            widget.onChanged(_details.copyWith(confidence: v));
            // Only when it changes to this value, not on every rebuild.
            if (changed && v == 'photo_required' && !widget.hasPhoto) {
              widget.onPhotoNeeded();
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _microhabitat,
          maxLength: 100, // the server's max_length
          decoration: const InputDecoration(labelText: 'Microhabitat'),
          onChanged: (v) =>
              widget.onChanged(_details.copyWith(microhabitat: v)),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.explore_outlined),
          title: const Text('Flight direction'),
          subtitle: Text(
            direction == null ? 'Not set' : flightDirectionLabel(direction),
          ),
          onTap: _pickDirection,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notes,
          minLines: 3,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(labelText: 'Notes'),
          onChanged: (v) => widget.onChanged(_details.copyWith(notes: v)),
        ),
        const SizedBox(height: 16),
        Text('Photos', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        widget.photos,
      ],
    );
  }
}
