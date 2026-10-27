import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/transects/domain/protocol_window.dart';
import 'package:mobile/features/transects/domain/section_with_habitat.dart';
import 'package:mobile/features/transects/domain/visit_stats.dart';
import 'package:mobile/features/transects/ui/protocol_summary.dart';
import 'package:mobile/features/transects/ui/transect_map.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';

/// One transect (outline §11.2 E): map with coloured sections, length,
/// sections with habitat types, habitat summary, protocol summary, own visit
/// history and the Start visit button.
class TransectDetailScreen extends ConsumerWidget {
  const TransectDetailScreen({
    super.key,
    required this.projectId,
    required this.transectId,
  });
  final String projectId;
  final String transectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transect = ref.watch(transectProvider(transectId));
    return switch (transect) {
      AsyncData(value: final t?) => _Detail(projectId: projectId, transect: t),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This transect is not on this phone.')),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$error')),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

/// The detail page of a transect that is on this phone.
class _Detail extends ConsumerWidget {
  const _Detail({required this.projectId, required this.transect});
  final String projectId;
  final Transect transect;

  /// Warns (without blocking) outside the season or daily time window, then
  /// goes on to the start-visit form.
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

    // TODO(T035): open the start-visit form for this transect.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('The start-visit form is coming in a later version'),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(transectSectionsProvider(transect.id)).value;
    final protocol = ref.watch(projectProtocolProvider(projectId)).value;
    final visits = ref.watch(transectVisitsProvider(transect.id)).value ?? [];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('${transect.code} · ${transect.name}')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
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
          const _SectionTitle('Sections'),
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
          const _SectionTitle('Habitat'),
          Card(child: _HabitatSummary(transect, sections ?? [])),
          const _SectionTitle('Protocol'),
          Card(
            child: protocol == null
                ? const ListTile(title: Text('No protocol on this phone'))
                : ProtocolSummary(protocol: protocol),
          ),
          const _SectionTitle('My visits'),
          Card(
            child: Column(
              children: [
                if (visits.isEmpty)
                  const ListTile(title: Text('No visits yet')),
                for (final v in visits)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(_dateTime(v.startedAt)),
                    subtitle: Text(visitStatusLabel(v.status)),
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
                  label: const Text('Start visit'),
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

/// The transect's habitat description, plus the habitat types of its sections.
class _HabitatSummary extends StatelessWidget {
  const _HabitatSummary(this.transect, this.sections);
  final Transect transect;
  final List<SectionWithHabitat> sections;

  @override
  Widget build(BuildContext context) {
    // Each habitat type once, in walking order.
    final types = sections.map((s) => s.habitatName).nonNulls.toSet();
    return Column(
      children: [
        ListTile(
          title: Text(
            transect.habitatSummary.isEmpty
                ? 'No habitat description'
                : transect.habitatSummary,
          ),
        ),
        if (types.isNotEmpty)
          ListTile(
            dense: true,
            leading: const Icon(Icons.grass_outlined),
            title: Text(types.join(', ')),
          ),
      ],
    );
  }
}

/// Small heading above each card of the detail page.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

/// Local date and time, "26.10.2026. 10:05"
String _dateTime(DateTime d) {
  final l = d.toLocal();
  final mm = l.minute.toString().padLeft(2, '0');
  return '${l.day}.${l.month}.${l.year}. ${l.hour}:$mm';
}
