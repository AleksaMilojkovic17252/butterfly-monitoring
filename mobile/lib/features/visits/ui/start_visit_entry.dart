import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/ui/protocol_window_dialog.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/ui/widgets/start_visit_draft_sheet.dart';

/// What the Start visit tile of a project does (T105). It reads Drift only, so
/// it works offline:
/// 1. a visit is in progress: open its active visit screen;
/// 2. else the user has drafts in the project: show them in a sheet;
/// 3. else: open the transect list with the nearest transect on top.
///
/// The start form itself is only reached through transect detail's checks, or
/// through [confirmProtocolWindow] from the sheet.
Future<void> openStartVisit(
  BuildContext context,
  WidgetRef ref,
  String projectId,
) async {
  // A second tap while the first is still reading Drift or showing the sheet
  // would open the screen or the sheet twice.
  if (_opening) return;
  _opening = true;
  try {
    // One-off reads of the repositories' streams (`.first`), not of the
    // providers: Riverpod pauses a provider nobody listens to, so its
    // `.future` would never complete here. Both repositories are read now,
    // while `ref` is surely alive, not later in the sheet's callback.
    final userId = ref.read(authControllerProvider).profile?.id;
    final visits = ref.read(visitRepositoryProvider);
    final transects = ref.read(transectRepositoryProvider);
    final inProgress = userId == null
        ? null
        : await visits.watchInProgress(userId).first;
    if (!context.mounted) return;

    // Only one visit is walked at a time, so a visit in progress opens even
    // when it belongs to another project; its own project goes in the path.
    if (inProgress != null) {
      context.push('/projects/${inProgress.projectId}/visits/${inProgress.id}');
      return;
    }

    final drafts = userId == null
        ? <({SurveyVisit visit, Transect transect})>[]
        : await visits.projectDrafts(projectId, userId);
    if (!context.mounted) return;
    if (drafts.isEmpty) {
      _openTransectList(context, projectId);
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => StartVisitDraftSheet(
        drafts: drafts,
        onDraft: (transect) async {
          final protocol = await transects.watchProtocol(projectId).first;
          if (!context.mounted) return;
          if (!await confirmProtocolWindow(context, protocol) ||
              !context.mounted) {
            return;
          }
          // `go` builds the whole stack (list, transect detail, form), so
          // Back from the form lands on transect detail, as it does after a
          // start from there.
          context.go('/projects/$projectId/transects/${transect.id}/start');
        },
        onChooseTransect: () => _openTransectList(context, projectId),
      ),
    );
  } finally {
    _opening = false;
  }
}

/// True while [openStartVisit] runs.
bool _opening = false;

/// The transect list, sorted by distance so the nearest transect is on top.
void _openTransectList(BuildContext context, String projectId) {
  context.push('/projects/$projectId/transects?sort=distance');
}
