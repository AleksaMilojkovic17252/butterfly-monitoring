import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';
import 'package:mobile/features/visits/ui/widgets/active_visit_view.dart';
import 'package:mobile/features/visits/ui/widgets/visit_message_screen.dart';

/// The main field screen during a walk (T039, outline §11.2 G): walking
/// time, distance, current section and observation count on top, the map in
/// the middle, and the entry buttons, Pause and Finish at the bottom.
///
/// Everything comes from Drift and the GPS tracker, so it works offline.
/// Leaving the screen does not end the visit: tracking goes on, and the
/// tracking card on project home opens the screen again.
class ActiveVisitScreen extends ConsumerWidget {
  const ActiveVisitScreen({super.key, required this.visitId});
  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(visitProvider(visitId));
    // `hasValue` stays true while the provider reloads, so the screen stays.
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
    if (v.status != 'in_progress') {
      // Finished, cancelled or locked, e.g. by an admin and a pull.
      return VisitMessageScreen(
        'This visit is no longer in progress '
        '(${visitStatusLabel(v.status)}).',
      );
    }
    return ActiveVisitView(visit: v);
  }
}
