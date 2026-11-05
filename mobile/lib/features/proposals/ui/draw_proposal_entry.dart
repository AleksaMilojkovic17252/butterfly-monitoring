import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/geo/polygon_math.dart';
import 'package:mobile/core/validation/proposal_rules.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/proposals/data/proposal_repository.dart';
import 'package:mobile/features/proposals/ui/widgets/proposal_details_sheet.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';
import 'package:mobile/features/resources/ui/geometry_capture_screen.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';

/// What "Draw on map" does (T108): the researcher taps the proposed route on
/// the map (the project's transects are shown as a guide), fills in the
/// details, and the proposal is queued for the next sync. For a route that
/// cannot be walked: private land, a cliff. No GPS is used, so it works during
/// a visit or a recording and offline (with cached map tiles). Pass
/// [replacesTransectId] to propose a replacement for that transect.
Future<void> openDrawProposal(
  BuildContext context,
  WidgetRef ref,
  String projectId, {
  String? replacesTransectId,
}) async {
  final userId = ref.read(authControllerProvider).profile?.id;
  if (userId == null) return;
  final transects =
      ref.read(projectTransectsProvider(projectId)).value ?? const [];

  final shape = await showGeometryCapture(
    context,
    modes: {GeometryMode.line},
    referenceLines: [for (final t in transects) parseLineString(t.geometry)],
  );
  if (shape == null || !context.mounted) return;

  final details = await ProposalDetailsSheet.show(
    context,
    lengthM: lineLengthM(shape.points),
    fixCount: distinctPointCount(shape.points),
    drawn: true,
  );
  if (details == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref
        .read(proposalRepositoryProvider)
        .createFromDrawing(
          projectId: projectId,
          replacesTransectId: replacesTransectId,
          points: shape.points,
          name: details.name,
          reason: details.reason,
          notes: details.notes,
          userId: userId,
        );
  } on StateError catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
    return;
  }
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Route proposal saved. It will be sent at the next sync.'),
    ),
  );
  if (context.mounted) context.go('/projects/$projectId/transects');
}
