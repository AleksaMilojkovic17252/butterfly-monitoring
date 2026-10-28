import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/projects/data/project_repository.dart';
import 'package:mobile/features/projects/ui/widgets/missing_project_view.dart';
import 'package:mobile/features/projects/ui/widgets/project_home_view.dart';

/// The hub for field work in one project (outline §11.2 C). There is no
/// validation tile: validation happens in Django admin only.
class ProjectHomeScreen extends ConsumerWidget {
  const ProjectHomeScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider(projectId));
    return switch (project) {
      AsyncData(value: final p?) => ProjectHomeView(project: p),
      AsyncData() => const MissingProjectView(),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}
