import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/visit_values.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/transects/domain/section_with_habitat.dart';
import 'package:mobile/features/transects/domain/visit_stats.dart';
import 'package:mobile/features/transects/ui/protocol_window_dialog.dart';
import 'package:mobile/features/transects/ui/widgets/detail_section_title.dart';
import 'package:mobile/features/transects/ui/widgets/habitat_summary.dart';
import 'package:mobile/features/transects/ui/widgets/protocol_summary.dart';
import 'package:mobile/features/transects/ui/widgets/transect_map.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/local_time.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';
import 'package:mobile/features/visits/ui/widgets/tracking_status_card.dart';

/// The detail page of a transect that is on this phone, shown by
/// `TransectDetailScreen` once the transect is loaded.
class TransectDetailView extends ConsumerWidget {
  const TransectDetailView({
    super.key,
    required this.projectId,
    required this.transect,
  });
  final String projectId;
  final Transect transect;

  /// Warns (without blocking) outside the season or daily time window, then
  /// opens the start-visit form (T035).
  Future<void> _startVisit(
    BuildContext context,
    ProjectProtocol? protocol,
  ) async {
    if (!await confirmProtocolWindow(context, protocol) || !context.mounted) {
      return;
    }
    await context.push('/projects/$projectId/transects/${transect.id}/start');
  }

  /// Opens a row of My visits (T106): a draft goes on in the start form, a
  /// visit in progress in the active visit screen, any other visit in its
  /// read-only detail. The detail is not under the active visit route, so
  /// back returns here.
  void _openVisit(
    BuildContext context,
    ProjectProtocol? protocol,
    VisitSummary visit,
  ) {
    switch (visit.status) {
      case 'draft':
        _startVisit(context, protocol);
      case 'in_progress':
        context.push('/projects/$projectId/visits/${visit.id}');
      default:
        context.push(
          '/projects/$projectId/transects/${transect.id}/visits/${visit.id}',
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(transectSectionsProvider(transect.id)).value;
    final protocol = ref.watch(projectProtocolProvider(projectId)).value;
    final visits = ref.watch(transectVisitsProvider(transect.id)).value ?? [];
    final draft = ref.watch(transectDraftProvider(transect.id)).value;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('${transect.code} · ${transect.name}')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const TrackingStatusCard(),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 260,
              child: TransectMap(
                line: parseLineString(transect.geometry),
                sections: [
                  for (final s in sections ?? <SectionWithHabitat>[])
                    parseLineString(s.section.geometry),
                ],
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.straighten),
                  title: Text('Length ${formatDistance(transect.lengthM)}'),
                  subtitle: Text('${sections?.length ?? 0} sections'),
                  trailing: transect.active
                      ? null
                      : Text('Inactive', style: TextStyle(color: scheme.error)),
                ),
                if (transect.description.isNotEmpty)
                  ListTile(title: Text(transect.description)),
              ],
            ),
          ),
          const DetailSectionTitle('Sections'),
          Card(
            child: Column(
              children: [
                if (sections == null || sections.isEmpty)
                  const ListTile(title: Text('No sections on this phone')),
                for (final (i, s) in (sections ?? []).indexed)
                  ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 8,
                      backgroundColor: sectionColor(i),
                    ),
                    title: Text(s.section.sectionCode),
                    subtitle: Text(
                      [
                        s.habitatName ?? 'No habitat type',
                        if (s.section.notes.isNotEmpty) s.section.notes,
                      ].join(' · '),
                    ),
                  ),
              ],
            ),
          ),
          const DetailSectionTitle('Habitat'),
          Card(child: HabitatSummary(transect, sections ?? [])),
          const DetailSectionTitle('Protocol'),
          Card(
            child: protocol == null
                ? const ListTile(title: Text('No protocol on this phone'))
                : ProtocolSummary(protocol: protocol),
          ),
          const DetailSectionTitle('My visits'),
          Card(
            child: Column(
              children: [
                if (visits.isEmpty)
                  const ListTile(title: Text('No visits yet')),
                for (final v in visits)
                  ListTile(
                    dense: true,
                    // A locked visit is read-only (T042).
                    leading: Icon(
                      visitIsLocked(v.status)
                          ? Icons.lock_outline
                          : Icons.event_outlined,
                    ),
                    title: Text(formatLocalDateTime(v.date)),
                    subtitle: Text(
                      v.status == 'cancelled'
                          ? 'Cancelled · ${cancelReasonLabel(v.cancelReason)}'
                          : visitStatusLabel(v.status),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openVisit(context, protocol, v),
                  ),
              ],
            ),
          ),
        ],
      ),
      // Always visible at the bottom, above the system navigation buttons.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!transect.active)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'This transect is inactive and cannot be walked.',
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  // A saved draft is opened again by the form (T035).
                  label: Text(draft == null ? 'Start visit' : 'Continue draft'),
                  // Null disables the button.
                  onPressed: transect.active
                      ? () => _startVisit(context, protocol)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
