import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/ui/widgets/quick_butterfly_sheet.dart';

/// What the Add observation button of a finished visit does (T110): open the
/// entry screen, then offer Undo. It reads Drift only, so it works offline.
Future<void> openAfterVisitObservation(
  BuildContext context,
  WidgetRef ref,
  SurveyVisit visit,
) async {
  // Taken now: the Undo button may be pressed after this screen is gone.
  final repository = ref.read(observationRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  final saved = await QuickButterflySheet.showAfterVisit(context, visit: visit);
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
