import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/protocol_window.dart';
import 'package:mobile/core/validation/visit_values.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/transects/domain/section_with_habitat.dart';
import 'package:mobile/features/transects/domain/visit_stats.dart';
import 'package:mobile/features/transects/ui/widgets/detail_section_title.dart';
import 'package:mobile/features/transects/ui/widgets/habitat_summary.dart';
import 'package:mobile/features/transects/ui/widgets/protocol_summary.dart';
import 'package:mobile/features/transects/ui/widgets/transect_map.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
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
    final now = DateTime.now();
    final warnings = protocol == null
        ? <String>[]
        : [
            seasonWarning(protocol, now),
            timeWindowWarning(protocol, now),
          ].nonNulls.toList();

    if (warnings.isNotEmpty) {
      final goOn = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: const Text('Outside the protocol window'),
          content: Text(warnings.join('\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              child: const Text('Start anyway'),
            ),
          ],
        ),
      );
      if (goOn != true || !context.mounted) return;
    }

    await context.push('/projects/$projectId/transects/${transect.id}/start');
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
                    title: Text(_dateTime(v.date)),
                    subtitle: Text(
                      v.status == 'cancelled'
                          ? 'Cancelled · ${cancelReasonLabel(v.cancelReason)}'
                          : visitStatusLabel(v.status),
                    ),
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

/// Local date and time, "26.10.2026. 10:05"
String _dateTime(DateTime d) {
  final l = d.toLocal();
  final mm = l.minute.toString().padLeft(2, '0');
  return '${l.day}.${l.month}.${l.year}. ${l.hour}:$mm';
}
