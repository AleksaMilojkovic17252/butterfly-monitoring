import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';

/// Bottom sheet of the Start visit tile when the user has drafts in the
/// project (T105): one row per draft, and "Choose a transect".
class StartVisitDraftSheet extends StatelessWidget {
  const StartVisitDraftSheet({
    super.key,
    required this.drafts,
    required this.onDraft,
    required this.onChooseTransect,
  });

  /// The drafts, newest first, each with its transect.
  final List<({SurveyVisit visit, Transect transect})> drafts;

  /// Called, after the sheet closes, with the transect of the tapped draft.
  final void Function(Transect transect) onDraft;

  /// Called, after the sheet closes, when "Choose a transect" is tapped.
  final VoidCallback onChooseTransect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Start visit',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final draft in drafts)
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: Text(
                  'Continue draft · ${draft.transect.code} · '
                  '${_date(draft.visit.createdAt)}',
                ),
                subtitle: Text(
                  draft.transect.active
                      ? draft.transect.name
                      : 'This transect is inactive',
                ),
                // A disabled row ignores taps: an inactive transect cannot be walked.
                enabled: draft.transect.active,
                onTap: () {
                  Navigator.pop(context);
                  onDraft(draft.transect);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.route_outlined),
              title: const Text('Choose a transect'),
              onTap: () {
                Navigator.pop(context);
                onChooseTransect();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Local date, "30.10.2026."
String _date(DateTime d) {
  final l = d.toLocal();
  return '${l.day}.${l.month}.${l.year}.';
}
