import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/validation/observation_values.dart';
import 'package:mobile/features/map/domain/map_filter.dart';
import 'package:mobile/features/map/domain/map_layers.dart';
import 'package:mobile/features/map/domain/map_taxa.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/local_time.dart';

/// The Filters sheet of the project map (T059). A change applies at once. The
/// filters narrow the observations layer only; the visit filter also picks the
/// route that is drawn.
class MapFilterSheet extends ConsumerWidget {
  const MapFilterSheet({super.key, required this.projectId});
  final String projectId;

  /// Local date as "12.10.2026.".
  static String _day(DateTime d) => '${d.day}.${d.month}.${d.year}.';

  Future<void> _pickDates(BuildContext context, WidgetRef ref) async {
    final filter = ref.read(effectiveMapFilterProvider(projectId));
    final from = filter.from;
    final to = filter.to;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: from != null && to != null
          ? DateTimeRange(start: from, end: to)
          : null,
    );
    if (picked == null) return;
    ref
        .read(mapFilterProvider.notifier)
        .set(filter.copyWith(from: () => picked.start, to: () => picked.end));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(effectiveMapFilterProvider(projectId));
    final notifier = ref.read(mapFilterProvider.notifier);
    final observations =
        ref.watch(projectObservationsProvider(projectId)).value ?? const [];
    final shown = ref.watch(filteredObservationsProvider(projectId));
    final visits = ref.watch(projectVisitsProvider(projectId)).value ?? [];
    final transects = ref.watch(projectTransectsProvider(projectId)).value;
    final sections = ref.watch(projectSectionsProvider(projectId)).value ?? [];

    // Only the species seen here, by scientific name.
    final sortedTaxa = ref.watch(projectTaxaProvider(projectId));

    final codeById = {for (final t in transects ?? []) t.id: t.code};
    // Habitat types of the project's sections, by name.
    final habitats = <String, String>{};
    for (final s in sections) {
      final id = s.section.habitatTypeId;
      final name = s.habitatName;
      if (id != null && name != null) habitats[id] = name;
    }
    final from = filter.from;
    final to = filter.to;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters apply to observations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${shown.length} of ${observations.length}'),
                  ],
                ),
              ),
              TextButton(
                onPressed: filter.activeCount == 0 ? null : notifier.clear,
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FilterDropdown(
            label: 'Visit',
            icon: Icons.directions_walk,
            value: filter.visitId,
            options: {
              for (final v in visits)
                v.id:
                    '${codeById[v.transectId] ?? '?'} · '
                    '${formatLocalDateTime(v.startedAt ?? v.createdAt)}',
            },
            onChanged: (value) {
              notifier.set(filter.copyWith(visitId: () => value));
              // Choosing a visit shows its route, even if the layer was off.
              if (value != null) {
                ref
                    .read(mapLayersProvider.notifier)
                    .toggle(MapLayer.visitRoute, true);
              }
            },
          ),
          _FilterDropdown(
            label: 'Species',
            icon: Icons.bug_report_outlined,
            value: filter.taxonId,
            options: {for (final t in sortedTaxa) t.id: t.scientificName},
            onChanged: (value) =>
                notifier.set(filter.copyWith(taxonId: () => value)),
          ),
          // Looks like the dropdowns (an outlined field with a label), so it
          // reads as a filter; tapping it opens the date range picker.
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _pickDates(context, ref),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Dates',
                  prefixIcon: const Icon(Icons.date_range),
                  // A clear button once a range is set.
                  suffixIcon: from == null && to == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear dates',
                          onPressed: () => notifier.set(
                            filter.copyWith(from: () => null, to: () => null),
                          ),
                        ),
                ),
                child: Text(
                  from == null && to == null
                      ? 'Any'
                      : '${from == null ? '…' : _day(from)} – '
                            '${to == null ? '…' : _day(to)}',
                ),
              ),
            ),
          ),
          _FilterDropdown(
            label: 'Life stage',
            icon: Icons.egg_outlined,
            value: filter.lifeStage,
            options: {
              for (final v in lifeStageValues) v: observationValueLabel(v),
            },
            onChanged: (value) =>
                notifier.set(filter.copyWith(lifeStage: () => value)),
          ),
          _FilterDropdown(
            label: 'Behaviour',
            icon: Icons.air,
            value: filter.behaviour,
            options: {
              for (final v in behaviourValues) v: observationValueLabel(v),
            },
            onChanged: (value) =>
                notifier.set(filter.copyWith(behaviour: () => value)),
          ),
          if (habitats.isNotEmpty)
            _FilterDropdown(
              label: 'Habitat type',
              icon: Icons.park_outlined,
              value: filter.habitatTypeId,
              options: habitats,
              onChanged: (value) =>
                  notifier.set(filter.copyWith(habitatTypeId: () => value)),
            ),
        ],
      ),
    );
  }
}

/// A dropdown of [options] (value to label) with an "Any" entry that clears it.
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final String? value;

  /// Value to the label shown for it.
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // A value that is not in the items asserts. A pull can remove a species or
    // a visit that is selected, so show "Any" for it.
    final selected = options.containsKey(value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String?>(
        // The key makes Clear all show "Any": the field keeps its own value
        // and only reads `initialValue` when it is created.
        key: ValueKey(selected),
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('Any')),
          for (final entry in options.entries)
            DropdownMenuItem<String?>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
