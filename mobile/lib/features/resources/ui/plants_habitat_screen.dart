import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/resources/data/habitat_repository.dart';
import 'package:mobile/features/resources/data/plant_repository.dart';
import 'package:mobile/features/resources/ui/widgets/habitat_feature_tile.dart';
import 'package:mobile/features/resources/ui/widgets/plant_record_tile.dart';

/// Which records the Plants & habitat list shows.
enum _Show { all, plants, habitat }

/// The Plants & habitat screen at `/projects/:id/plants` (T052, T054): Add
/// plant, Add habitat, and the user's own plant records and habitat features of
/// the project, newest first. The All / Plants / Habitat chips only filter what
/// is shown. A row opens its edit form.
class PlantsHabitatScreen extends ConsumerStatefulWidget {
  const PlantsHabitatScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<PlantsHabitatScreen> createState() =>
      _PlantsHabitatScreenState();
}

class _PlantsHabitatScreenState extends ConsumerState<PlantsHabitatScreen> {
  _Show _show = _Show.all;

  String get _projectId => widget.projectId;

  /// The text under the chips when nothing is listed.
  String get _emptyText => switch (_show) {
    _Show.all => 'No plant records or habitat features yet.',
    _Show.plants => 'No plant records yet.',
    _Show.habitat => 'No habitat features yet.',
  };

  @override
  Widget build(BuildContext context) {
    final plants = ref.watch(plantRecordsProvider(_projectId));
    final habitats = ref.watch(habitatFeaturesProvider(_projectId));

    return Scaffold(
      appBar: AppBar(title: const Text('Plants & habitat')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/projects/$_projectId/plants/new'),
                    icon: const Icon(Icons.local_florist_outlined),
                    label: const Text('Add plant'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () =>
                        context.push('/projects/$_projectId/habitats/new'),
                    icon: const Icon(Icons.terrain_outlined),
                    label: const Text('Add habitat'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                for (final (value, label) in [
                  (_Show.all, 'All'),
                  (_Show.plants, 'Plants'),
                  (_Show.habitat, 'Habitat'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _show == value,
                    onSelected: (_) => setState(() => _show = value),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (plants.hasError || habitats.hasError)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load the list: ${plants.error ?? habitats.error}',
              ),
            )
          else if (!plants.hasValue || !habitats.hasValue)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ..._rows(plants.requireValue, habitats.requireValue),
        ],
      ),
    );
  }

  /// The rows for the selected chip: both lists merged, newest first.
  List<Widget> _rows(
    List<PlantResourceObservation> plants,
    List<HabitatFeature> habitats,
  ) {
    // Each entry: when it was seen, when it was made, and its tile.
    final entries = <(DateTime, DateTime, Widget)>[
      if (_show != _Show.habitat)
        for (final plant in plants)
          (
            plant.observedAt,
            plant.createdAt,
            PlantRecordTile(
              record: plant,
              onTap: () =>
                  context.push('/projects/$_projectId/plants/${plant.id}'),
            ),
          ),
      if (_show != _Show.plants)
        for (final habitat in habitats)
          (
            habitat.observedAt,
            habitat.createdAt,
            HabitatFeatureTile(
              feature: habitat,
              onTap: () =>
                  context.push('/projects/$_projectId/habitats/${habitat.id}'),
            ),
          ),
    ];
    if (entries.isEmpty) {
      return [
        Padding(padding: const EdgeInsets.all(24), child: Text(_emptyText)),
      ];
    }
    // Same order as each query: observedAt, then createdAt, newest first.
    entries.sort((a, b) {
      final seen = b.$1.compareTo(a.$1);
      return seen != 0 ? seen : b.$2.compareTo(a.$2);
    });
    return [for (final entry in entries) entry.$3];
  }
}
