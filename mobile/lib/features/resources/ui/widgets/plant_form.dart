import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/validation/plant_rules.dart';
import 'package:mobile/core/validation/plant_values.dart';
import 'package:mobile/features/resources/data/plant_repository.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';
import 'package:mobile/features/resources/domain/plant_input.dart';
import 'package:mobile/features/resources/domain/plant_links.dart';
import 'package:mobile/features/resources/domain/plant_taxon_search.dart';
import 'package:mobile/features/resources/ui/geometry_capture_screen.dart';
import 'package:mobile/features/resources/ui/widgets/plant_taxon_picker_sheet.dart';
import 'package:mobile/features/resources/ui/widgets/tri_state_field.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';

/// The plant form (T052), in the ticket's order: species, relation, abundance,
/// phenology, flowering, eggs, larvae, feeding damage, photos, location and
/// notes. The parent owns the values: [input] is what is shown and [onChanged]
/// gets the new values after every change; the parent also decides when Save
/// is possible.
///
/// [photos] is the parent's own photo widget (a new record holds drafts, a
/// saved one saves right away). With [linkRole] the relation is preset and only
/// the values that fit the role are offered. With [readOnly] (a locked visit)
/// nothing can be changed, but the photos stay viewable.
class PlantForm extends ConsumerStatefulWidget {
  const PlantForm({
    super.key,
    required this.projectId,
    required this.input,
    required this.onChanged,
    required this.photos,
    this.linkRole,
    this.readOnly = false,
    this.editing = false,
    this.locating = false,
    this.locationMessage,
  });
  final String projectId;
  final PlantInput input;
  final ValueChanged<PlantInput> onChanged;
  final Widget photos;
  final PlantLinkRole? linkRole;
  final bool readOnly;

  /// True for a record that is already saved. Its species counts as answered.
  final bool editing;

  /// True while the screen waits for the phone's position.
  final bool locating;

  /// Why the position could not be found, shown on the location tile.
  final String? locationMessage;

  @override
  ConsumerState<PlantForm> createState() => _PlantFormState();
}

class _PlantFormState extends ConsumerState<PlantForm> {
  late final _notes = TextEditingController(text: widget.input.notes);

  /// False until the user has picked a plant or "Unidentified plant", so a
  /// new form does not open with an error on the notes.
  late bool _speciesAnswered =
      widget.editing || widget.input.plantTaxonId != null;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  PlantInput get _input => widget.input;

  /// Opens the species sheet and stores the choice.
  Future<void> _pickSpecies() async {
    final pick = await PlantTaxonPickerSheet.show(
      context,
      projectId: widget.projectId,
      selectedId: _input.plantTaxonId,
    );
    if (pick == null || !mounted) return;
    setState(() => _speciesAnswered = true);
    widget.onChanged(_input.withTaxon(pick.id));
  }

  /// Opens the full-screen capture and stores the shape it returns.
  Future<void> _pickLocation() async {
    final transects =
        ref.read(projectTransectsProvider(widget.projectId)).value ?? [];
    final shape = await showGeometryCapture(
      context,
      projectId: widget.projectId,
      modes: const {GeometryMode.point, GeometryMode.polygon},
      initial: _input.geometry,
      referenceLines: [for (final t in transects) parseLineString(t.geometry)],
    );
    if (shape == null || !mounted) return;
    widget.onChanged(_input.withGeometry(shape));
  }

  /// A dropdown over a codelist. [optional] adds "Not recorded" (`''`). A
  /// stored [value] that is not in [values] (the server added a choice this
  /// version does not know) is added, because the dropdown asserts that exactly
  /// one item matches its value.
  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
    bool optional = true,
    String? hint,
  }) {
    final items = [
      if (optional) '',
      ...values,
      if (value.isNotEmpty && !values.contains(value)) value,
    ];
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty && !optional ? null : value,
      isExpanded: true,
      hint: hint == null ? null : Text(hint),
      decoration: InputDecoration(labelText: label),
      items: [
        for (final v in items)
          DropdownMenuItem(value: v, child: Text(plantValueLabel(v))),
      ],
      onChanged: widget.readOnly
          ? null
          : (v) {
              if (v != null) onChanged(v);
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final taxonId = _input.plantTaxonId;
    final plant = taxonId == null
        ? null
        : ref.watch(plantTaxaByIdsProvider(taxonId)).value?.firstOrNull;
    final role = widget.linkRole;
    final relationValues = role == null
        ? resourceTypeValues
        : resourceTypesFor(role);
    final notesMissing =
        _speciesAnswered &&
        plantNotesMissing(_input.plantTaxonId, _input.notes);
    final shape = _input.geometry;

    // Everything but the photos is switched off when the form is read-only.
    Widget editable(Widget child) =>
        IgnorePointer(ignoring: widget.readOnly, child: child);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        editable(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.local_florist_outlined),
            title: Text(
              taxonId == null
                  ? (_speciesAnswered ? 'Unidentified plant' : 'Pick the plant')
                  : plant == null
                  ? 'Plant'
                  : plantTitle(plant),
            ),
            subtitle: plant == null
                ? null
                : Text(
                    plant.scientificName,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickSpecies,
          ),
        ),
        const SizedBox(height: 8),
        editable(
          _dropdown(
            label: 'Relation to butterflies',
            value: _input.resourceType,
            values: relationValues,
            optional: false,
            hint: 'Choose',
            onChanged: (v) =>
                widget.onChanged(_input.copyWith(resourceType: v)),
          ),
        ),
        const SizedBox(height: 16),
        editable(
          _dropdown(
            label: 'Abundance',
            value: _input.abundanceClass,
            values: abundanceClassValues,
            onChanged: (v) =>
                widget.onChanged(_input.copyWith(abundanceClass: v)),
          ),
        ),
        const SizedBox(height: 16),
        editable(
          _dropdown(
            label: 'Phenology',
            value: _input.phenologyStage,
            values: phenologyStageValues,
            onChanged: (v) =>
                widget.onChanged(_input.copyWith(phenologyStage: v)),
          ),
        ),
        const SizedBox(height: 16),
        editable(
          _dropdown(
            label: 'Flowering',
            value: _input.floweringIntensity,
            values: floweringIntensityValues,
            onChanged: (v) =>
                widget.onChanged(_input.copyWith(floweringIntensity: v)),
          ),
        ),
        const SizedBox(height: 16),
        editable(
          TriStateField(
            label: 'Eggs',
            value: _input.eggsPresent,
            onChanged: (v) => widget.onChanged(
              _input.withSigns(
                eggs: v,
                larvae: _input.larvaePresent,
                feedingDamage: _input.feedingDamagePresent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        editable(
          TriStateField(
            label: 'Larvae',
            value: _input.larvaePresent,
            onChanged: (v) => widget.onChanged(
              _input.withSigns(
                eggs: _input.eggsPresent,
                larvae: v,
                feedingDamage: _input.feedingDamagePresent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        editable(
          TriStateField(
            label: 'Feeding damage',
            value: _input.feedingDamagePresent,
            onChanged: (v) => widget.onChanged(
              _input.withSigns(
                eggs: _input.eggsPresent,
                larvae: _input.larvaePresent,
                feedingDamage: v,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Photos', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        widget.photos,
        const SizedBox(height: 8),
        editable(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              shape?.mode == GeometryMode.polygon
                  ? Icons.pentagon_outlined
                  : Icons.place_outlined,
            ),
            title: const Text('Location'),
            subtitle: Text(
              shape?.summary ??
                  (widget.locating
                      ? 'Getting your position…'
                      : widget.locationMessage == null
                      ? 'Not set'
                      : 'Not set. ${widget.locationMessage}'),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickLocation,
          ),
        ),
        const SizedBox(height: 8),
        editable(
          TextField(
            controller: _notes,
            minLines: 3,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              labelText: 'Notes',
              errorText: notesMissing ? plantNotesRequiredMessage : null,
            ),
            onChanged: (v) => widget.onChanged(_input.copyWith(notes: v)),
          ),
        ),
      ],
    );
  }
}
