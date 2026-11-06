import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/ui/widgets/quick_butterfly_sheet.dart';
import 'package:mobile/features/projects/data/project_repository.dart';
import 'package:mobile/features/projects/domain/project_closed.dart';

/// What the Free observation tile and the map long press do (T047): open the
/// entry sheet for a butterfly seen outside a visit, then offer Undo. A long
/// press passes [placedAt], the point it was on. It reads Drift only, so it
/// works offline.
Future<void> openFreeObservation(
  BuildContext context,
  WidgetRef ref,
  String projectId, {
  LatLng? placedAt,
}) async {
  // Taken now: the Undo button may be pressed after this screen is gone.
  final repository = ref.read(observationRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  // A closed project takes no free observations (T099). Checked here, not only
  // on the tile, because the map long press and the route recording screen
  // start this flow too.
  if (await ref.read(projectRepositoryProvider).isClosed(projectId)) {
    messenger.showSnackBar(const SnackBar(content: Text(projectClosedMessage)));
    return;
  }
  if (!context.mounted) return;
  final saved = await QuickButterflySheet.showFree(
    context,
    projectId: projectId,
    placedAt: placedAt,
  );
  if (saved == null) return;
  // Stays 10 s, then goes by itself (`persist` defaults to true with an action).
  messenger.showSnackBar(
    SnackBar(
      content: Text('Saved: ${saved.label}'),
      duration: const Duration(seconds: 10),
      persist: false,
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => repository.undo(saved.id),
      ),
    ),
  );
}
