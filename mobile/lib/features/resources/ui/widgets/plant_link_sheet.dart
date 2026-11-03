import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/ui/widgets/sheet_list_title.dart';
import 'package:mobile/features/resources/data/plant_repository.dart';
import 'package:mobile/features/resources/domain/plant_links.dart';
import 'package:mobile/features/resources/ui/plant_entry_screen.dart';
import 'package:mobile/features/resources/ui/widgets/plant_record_tile.dart';

/// The picker for a butterfly observation's host or nectar plant (T052): the
/// user's plant records whose relation fits [role] (the server refuses the
/// others, D-086), those of this visit first, and a button to make a new
/// record. It answers the id of the chosen record, or null when closed.
class PlantLinkSheet extends ConsumerWidget {
  const PlantLinkSheet({
    super.key,
    required this.role,
    required this.projectId,
    required this.visitId,
    required this.selectedId,
  });
  final PlantLinkRole role;
  final String projectId;

  /// The visit of the observation; its plant records are listed first.
  final String? visitId;
  final String? selectedId;

  /// Opens the sheet and returns the chosen record's id, or null.
  static Future<String?> show(
    BuildContext context, {
    required PlantLinkRole role,
    required String projectId,
    required String? visitId,
    required String? selectedId,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PlantLinkSheet(
        role: role,
        projectId: projectId,
        visitId: visitId,
        selectedId: selectedId,
      ),
    );
  }

  /// Opens the plant form for a new record made for [role]. The sheet is a
  /// pageless route, so this is `Navigator.push`, not `context.push` (a go_router
  /// call from here does not land where it should). The new record's id closes
  /// the sheet, so it becomes the link.
  Future<void> _newRecord(BuildContext context) async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => PlantEntryScreen(
          projectId: projectId,
          visitId: visitId,
          linkRole: role,
        ),
      ),
    );
    if (id != null && context.mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(linkablePlantsProvider(projectId)).value ?? [];
    final fitting = [
      for (final record in records)
        if (fitsRole(record.resourceType, role)) record,
    ];
    final ofThisVisit = [
      for (final record in fitting)
        if (visitId != null && record.surveyVisitId == visitId) record,
    ];
    final others = [
      for (final record in fitting)
        if (!ofThisVisit.contains(record)) record,
    ];

    Widget tile(PlantResourceObservation record) => PlantRecordTile(
      record: record,
      selected: record.id == selectedId,
      onTap: () => Navigator.pop(context, record.id),
    );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Link ${plantLinkLabel(role).toLowerCase()}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _newRecord(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New plant record'),
                ),
              ],
            ),
          ),
          Expanded(
            child: fitting.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No plant record fits yet. Make a new one.'),
                  )
                : ListView(
                    children: [
                      if (ofThisVisit.isNotEmpty) ...[
                        const SheetListTitle('This visit'),
                        for (final record in ofThisVisit) tile(record),
                      ],
                      if (others.isNotEmpty) ...[
                        SheetListTitle(
                          ofThisVisit.isEmpty ? 'Your plant records' : 'Others',
                        ),
                        for (final record in others) tile(record),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
