import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/ui/widgets/visit_detail_view.dart';
import 'package:mobile/features/visits/ui/widgets/visit_message_screen.dart';

/// The read-only detail of a finished, synced or cancelled visit (T106),
/// opened from My visits at
/// `/projects/:id/transects/:transectId/visits/:visitId`. It reads Drift only
/// and follows changes from a pull.
class VisitDetailScreen extends ConsumerWidget {
  const VisitDetailScreen({super.key, required this.visitId});
  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(visitProvider(visitId));
    if (!visit.hasValue) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: visit.hasError
              ? Text('${visit.error}')
              : const CircularProgressIndicator(),
        ),
      );
    }
    final v = visit.value;
    if (v == null) {
      return const VisitMessageScreen('This visit is not on this phone.');
    }
    return VisitDetailView(visit: v);
  }
}
