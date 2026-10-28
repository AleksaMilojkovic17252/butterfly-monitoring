import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/ui/widgets/finish_visit_form.dart';
import 'package:mobile/features/visits/ui/widgets/visit_message_screen.dart';

/// The Finish screen (T040, outline §11.2 J), opened from Finish on the
/// active visit screen at `/projects/:id/visits/:visitId/finish`: a summary
/// of the walk, warnings, the end weather and Finish and save. Going back
/// changes nothing; the visit and its tracking go on.
class FinishVisitScreen extends ConsumerWidget {
  const FinishVisitScreen({super.key, required this.visitId});
  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(visitProvider(visitId));
    // The visit in progress that was started on this phone: if it is this
    // visit, this phone recorded the route.
    final onThisPhone = ref.watch(deviceVisitInProgressProvider);
    if (!visit.hasValue || !onThisPhone.hasValue) {
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
      return const VisitMessageScreen('This visit is no longer in progress.');
    }
    return FinishVisitForm(
      visit: v,
      recordedHere: onThisPhone.value?.id == v.id,
    );
  }
}
