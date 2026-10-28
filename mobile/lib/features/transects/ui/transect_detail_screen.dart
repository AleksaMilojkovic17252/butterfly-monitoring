import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/ui/widgets/transect_detail_view.dart';

/// One transect (outline §11.2 E): map with coloured sections, length,
/// sections with habitat types, habitat summary, protocol summary, own visit
/// history and the Start visit button.
class TransectDetailScreen extends ConsumerWidget {
  const TransectDetailScreen({
    super.key,
    required this.projectId,
    required this.transectId,
  });
  final String projectId;
  final String transectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transect = ref.watch(transectProvider(transectId));
    return switch (transect) {
      AsyncData(value: final t?) => TransectDetailView(
        projectId: projectId,
        transect: t,
      ),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This transect is not on this phone.')),
      ),
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
