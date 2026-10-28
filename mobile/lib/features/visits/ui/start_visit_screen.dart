import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/ui/widgets/start_visit_form.dart';
import 'package:mobile/features/visits/ui/widgets/start_visit_message.dart';

/// The start-visit form (T035, outline §11.2 F): observers, start weather,
/// notes and the protocol confirmation, then **Save draft** or **Start**.
/// Opens the caller's draft of the transect when there is one.
class StartVisitScreen extends ConsumerWidget {
  const StartVisitScreen({
    super.key,
    required this.projectId,
    required this.transectId,
  });
  final String projectId;
  final String transectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Everything comes from Drift or memory, so the form opens without the
    // network (T035: under 1 s).
    final transect = ref.watch(transectProvider(transectId));
    final protocol = ref.watch(projectProtocolProvider(projectId));
    final draft = ref.watch(transectDraftProvider(transectId));
    final profile = ref.watch(authControllerProvider).profile;

    // `hasValue` stays true while a provider reloads or reports an error
    // after its first value, so the form (and what was typed) stays up.
    final Widget body;
    if (!transect.hasValue || !protocol.hasValue || !draft.hasValue) {
      final error = transect.error ?? protocol.error ?? draft.error;
      body = error != null
          ? Center(child: Text('$error'))
          : const Center(child: CircularProgressIndicator());
    } else if (profile == null) {
      body = const StartVisitMessage(
        'You are logged out. Log in to start a visit.',
      );
    } else if (transect.value == null || protocol.value == null) {
      body = const StartVisitMessage(
        'The transect or the project protocol is not on this phone. '
        'Download the project first.',
      );
    } else {
      return StartVisitForm(
        transect: transect.value!,
        protocol: protocol.value!,
        observer: profile,
        draft: draft.value,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Start visit')),
      body: body,
    );
  }
}
