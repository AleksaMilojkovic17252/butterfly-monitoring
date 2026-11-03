import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/resources/data/plant_repository.dart';
import 'package:mobile/features/resources/ui/widgets/plant_record_tile.dart';

/// The Plants & habitat screen at `/projects/:id/plants` (T052): Add plant, a
/// disabled Add habitat, and the user's own plant records of the project, newest
/// first. A row opens its edit form. Habitat features join the list with T054.
class PlantsHabitatScreen extends ConsumerWidget {
  const PlantsHabitatScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(plantRecordsProvider(projectId));
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
                        context.push('/projects/$projectId/plants/new'),
                    icon: const Icon(Icons.local_florist_outlined),
                    label: const Text('Add plant'),
                  ),
                ),
                const SizedBox(width: 12),
                // Enabled by T054, when habitat features can be recorded.
                const Expanded(
                  child: FilledButton.tonal(
                    onPressed: null,
                    child: Text('Add habitat'),
                  ),
                ),
              ],
            ),
          ),
          switch (records) {
            AsyncData(:final value) when value.isEmpty => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No plant records yet.'),
            ),
            AsyncData(:final value) => Column(
              children: [
                for (final record in value)
                  PlantRecordTile(
                    record: record,
                    onTap: () => context.push(
                      '/projects/$projectId/plants/${record.id}',
                    ),
                  ),
              ],
            ),
            AsyncError(:final error) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load the plant records: $error'),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}
