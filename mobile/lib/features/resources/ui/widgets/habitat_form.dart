import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/habitat_rules.dart';
import 'package:mobile/core/validation/habitat_values.dart';
import 'package:mobile/features/resources/data/habitat_repository.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';
import 'package:mobile/features/resources/domain/habitat_input.dart';
import 'package:mobile/features/resources/domain/habitat_names.dart';
import 'package:mobile/features/resources/ui/geometry_capture_screen.dart';
import 'package:mobile/features/resources/ui/widgets/cover_field.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';

/// The habitat form (T054), in the ticket's order: habitat type, management,
/// vegetation height, the three covers, flower abundance, grazing, mowing,
/// disturbance, location and notes. The parent owns the values: [input] is
/// what is shown and [onChanged] gets the new values after every change; the
/// parent also decides when Save is possible.
///
/// The two type pickers read their lists from the database, so the form shows a
/// spinner until both have loaded. A dropdown asserts that exactly one item
/// matches its value, so the saved type is always among the items, even when it
/// has been deactivated or is not on this phone.
///
/// With [readOnly] (a locked visit) nothing can be changed.
class HabitatForm extends ConsumerStatefulWidget {
  const HabitatForm({
    super.key,
    required this.projectId,
    required this.input,
    required this.onChanged,
    this.readOnly = false,
    this.locating = false,
    this.locationMessage,
  });
  final String projectId;
  final HabitatInput input;
  final ValueChanged<HabitatInput> onChanged;
  final bool readOnly;

  /// True while the screen waits for the phone's position.
  final bool locating;

  /// Why the position could not be found, shown on the location tile.
  final String? locationMessage;

  @override
  ConsumerState<HabitatForm> createState() => _HabitatFormState();
}

class _HabitatFormState extends ConsumerState<HabitatForm> {
  late final _notes = TextEditingController(text: widget.input.notes);
  late final _height = TextEditingController(
    text: widget.input.vegetationHeightCm?.toString() ?? '',
  );

  @override
  void dispose() {
    _notes.dispose();
    _height.dispose();
    super.dispose();
  }

  HabitatInput get _input => widget.input;

  /// Opens the full-screen capture and stores the shape it returns.
  Future<void> _pickLocation() async {
    final transects =
        ref.read(projectTransectsProvider(widget.projectId)).value ?? [];
    final shape = await showGeometryCapture(
      context,
      projectId: widget.projectId,
      modes: const {
        GeometryMode.point,
        GeometryMode.line,
        GeometryMode.polygon,
      },
      initial: _input.geometry,
      referenceLines: [for (final t in transects) parseLineString(t.geometry)],
    );
    if (shape == null || !mounted) return;
    widget.onChanged(_input.copyWith(geometry: () => shape));
  }

  /// A dropdown over a fixed list of values. `''` is "Not recorded". A stored
  /// [value] that is not in [values] (the server added a choice this version
  /// does not know) is added, because the dropdown asserts that exactly one
  /// item matches its value.
  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    final items = [
      '',
      ...values,
      if (value.isNotEmpty && !values.contains(value)) value,
    ];
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final v in items)
          DropdownMenuItem(value: v, child: Text(habitatValueLabel(v))),
      ],
      onChanged: widget.readOnly
          ? null
          : (v) {
              if (v != null) onChanged(v);
            },
    );
  }

  /// The habitat type picker: active types, plus the saved one whatever its
  /// state. A saved id that is not on this phone shows "Not on this phone".
  Widget _habitatTypeDropdown(List<HabitatType> all) {
    final selected = _input.habitatTypeId;
    final byId = {for (final t in all) t.id: t};
    final choices = [
      for (final t in all)
        if ((t.active && t.deletedAt == null) || t.id == selected) t,
    ];
    return DropdownButtonFormField<String>(
      initialValue: selected.isEmpty ? null : selected,
      isExpanded: true,
      hint: const Text('Choose'),
      decoration: const InputDecoration(labelText: 'Habitat type'),
      items: [
        for (final t in choices)
          DropdownMenuItem(value: t.id, child: Text(habitatTypeTitle(t))),
        if (selected.isNotEmpty && !byId.containsKey(selected))
          DropdownMenuItem(
            value: selected,
            child: const Text('Not on this phone'),
          ),
      ],
      onChanged: widget.readOnly
          ? null
          : (v) {
              if (v != null) {
                widget.onChanged(_input.copyWith(habitatTypeId: v));
              }
            },
    );
  }

  /// The management picker: "Not recorded" (stored as null), active types, and
  /// the saved one whatever its state.
  Widget _managementTypeDropdown(List<ManagementType> all) {
    final selected = _input.managementTypeId;
    final byId = {for (final t in all) t.id: t};
    final choices = [
      for (final t in all)
        if ((t.active && t.deletedAt == null) || t.id == selected) t,
    ];
    return DropdownButtonFormField<String>(
      initialValue: selected ?? '',
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Management'),
      items: [
        const DropdownMenuItem(value: '', child: Text('Not recorded')),
        for (final t in choices)
          DropdownMenuItem(value: t.id, child: Text(managementTypeTitle(t))),
        if (selected != null && !byId.containsKey(selected))
          DropdownMenuItem(
            value: selected,
            child: const Text('Not on this phone'),
          ),
      ],
      onChanged: widget.readOnly
          ? null
          : (v) {
              if (v == null) return;
              widget.onChanged(
                _input.copyWith(managementTypeId: () => v.isEmpty ? null : v),
              );
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitatTypes = ref.watch(habitatTypesProvider);
    final managementTypes = ref.watch(managementTypesProvider);
    final shape = _input.geometry;

    // The dropdowns are not built before both lists are there: they read their
    // initial value once, and the lists come from the database.
    final loadError = habitatTypes.error ?? managementTypes.error;
    final habitatList = habitatTypes.value;
    final managementList = managementTypes.value;
    if (loadError != null) {
      return Center(child: Text('Could not load the lists: $loadError'));
    }
    if (habitatList == null || managementList == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Everything is switched off when the form is read-only.
    Widget editable(Widget child) =>
        IgnorePointer(ignoring: widget.readOnly, child: child);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (habitatList.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('No habitat types on this phone. Sync first.'),
          )
        else
          editable(_habitatTypeDropdown(habitatList)),
        const SizedBox(height: 16),
        editable(_managementTypeDropdown(managementList)),
        const SizedBox(height: 16),
        editable(
          TextField(
            controller: _height,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: InputDecoration(
              labelText: 'Vegetation height (cm)',
              errorText: vegetationHeightProblem(_input.vegetationHeightCm),
            ),
            // Empty is "not measured" (null).
            onChanged: (text) => widget.onChanged(
              _input.copyWith(vegetationHeightCm: () => int.tryParse(text)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        editable(
          CoverField(
            label: 'Shrub cover',
            value: _input.shrubCoverPct,
            onChanged: (v) =>
                widget.onChanged(_input.copyWith(shrubCoverPct: () => v)),
          ),
        ),
        editable(
          CoverField(
            label: 'Tree cover',
            value: _input.treeCoverPct,
            onChanged: (v) =>
                widget.onChanged(_input.copyWith(treeCoverPct: () => v)),
          ),
        ),
        editable(
          CoverField(
            label: 'Bare ground',
            value: _input.bareGroundPct,
            onChanged: (v) =>
                widget.onChanged(_input.copyWith(bareGroundPct: () => v)),
          ),
        ),
        const SizedBox(height: 8),
        editable(
          _dropdown(
            label: 'Flower abundance',
            value: _input.flowerAbundanceClass,
            values: flowerAndGrazingValues,
            onChanged: (v) =>
                widget.onChanged(_input.copyWith(flowerAbundanceClass: v)),
          ),
        ),
        const SizedBox(height: 16),
        editable(
          _dropdown(
            label: 'Grazing',
            value: _input.grazingIntensity,
            values: flowerAndGrazingValues,
            onChanged: (v) =>
                widget.onChanged(_input.copyWith(grazingIntensity: v)),
          ),
        ),
        const SizedBox(height: 16),
        editable(
          _dropdown(
            label: 'Mowing',
            value: _input.mowingStatus,
            values: mowingStatusValues,
            onChanged: (v) =>
                widget.onChanged(_input.copyWith(mowingStatus: v)),
          ),
        ),
        const SizedBox(height: 16),
        editable(
          _dropdown(
            label: 'Disturbance',
            value: _input.disturbanceType,
            values: disturbanceValues,
            onChanged: (v) =>
                widget.onChanged(_input.copyWith(disturbanceType: v)),
          ),
        ),
        const SizedBox(height: 8),
        editable(
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(switch (shape?.mode) {
              GeometryMode.line => Icons.timeline,
              GeometryMode.polygon => Icons.pentagon_outlined,
              _ => Icons.place_outlined,
            }),
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
            decoration: const InputDecoration(labelText: 'Notes'),
            onChanged: (v) => widget.onChanged(_input.copyWith(notes: v)),
          ),
        ),
      ],
    );
  }
}
