import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/ui/widgets/observation_detail_view.dart';

/// The read-only detail of one observation (T106), opened from a visit's
/// observation list at `/projects/:id/observations/:observationId`. It reads
/// Drift only and follows changes from a pull.
class ObservationDetailScreen extends ConsumerWidget {
  const ObservationDetailScreen({super.key, required this.observationId});
  final String observationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observation = ref.watch(observationProvider(observationId));
    if (!observation.hasValue) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: observation.hasError
              ? Text('${observation.error}')
              : const CircularProgressIndicator(),
        ),
      );
    }
    final o = observation.value;
    if (o == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Observation')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This observation is not on this phone.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return ObservationDetailView(observation: o);
  }
}
