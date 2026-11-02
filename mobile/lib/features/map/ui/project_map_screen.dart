import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/map/domain/map_filter.dart';
import 'package:mobile/features/map/ui/widgets/map_filter_sheet.dart';
import 'package:mobile/features/map/ui/widgets/map_layers_sheet.dart';
import 'package:mobile/features/map/ui/widgets/project_map_view.dart';

/// The project map (T059) at `/projects/:id/map`: everything the researcher
/// has on this phone on one map, with a Layers and a Filters sheet. It reads
/// Drift only, so it works offline (the basemap needs a connection or cached
/// tiles).
class ProjectMapScreen extends ConsumerWidget {
  const ProjectMapScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilters = ref.watch(
      effectiveMapFilterProvider(projectId).select((f) => f.activeCount),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined),
            tooltip: 'Layers',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => MapLayersSheet(projectId: projectId),
            ),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: activeFilters > 0,
              label: Text('$activeFilters'),
              child: const Icon(Icons.filter_alt_outlined),
            ),
            tooltip: 'Filters',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (_) => MapFilterSheet(projectId: projectId),
            ),
          ),
        ],
      ),
      body: ProjectMapView(projectId: projectId),
    );
  }
}
