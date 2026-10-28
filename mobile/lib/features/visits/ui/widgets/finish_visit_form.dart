import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_runner.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/data/taxon_repository.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/visits/data/track_point_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/beaufort.dart';
import 'package:mobile/features/visits/domain/finish_values.dart';
import 'package:mobile/features/visits/domain/route_stats.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';
import 'package:mobile/features/visits/domain/visit_pauses.dart';
import 'package:mobile/features/visits/domain/visit_rule_error.dart';
import 'package:mobile/features/visits/domain/visit_summary.dart';
import 'package:mobile/features/visits/domain/walking_time.dart';
import 'package:mobile/features/visits/ui/temperature_input.dart';
import 'package:mobile/features/visits/ui/widgets/finish_warnings.dart';
import 'package:mobile/features/visits/ui/widgets/form_section_title.dart';
import 'package:mobile/features/visits/ui/widgets/visit_message_screen.dart';
import 'package:mobile/features/visits/ui/widgets/visit_summary_card.dart';
import 'package:mobile/features/visits/ui/widgets/wind_picker_sheet.dart';

/// The text of the true-zero confirmation (T041).
const _zeroSentence =
    'No butterfly was seen during the complete standardised visit.';

/// The Finish screen itself, once the visit is loaded (shown by
/// `FinishVisitScreen`). Summary, warnings, end weather, the reason when the
/// weather is missing, and the true-zero confirmation when the visit has no
/// butterfly. **Finish and save** completes the visit.
class FinishVisitForm extends ConsumerStatefulWidget {
  const FinishVisitForm({
    super.key,
    required this.visit,
    required this.recordedHere,
  });
  final SurveyVisit visit;

  /// True when this phone recorded the route, so its points are here.
  final bool recordedHere;

  @override
  ConsumerState<FinishVisitForm> createState() => _FinishVisitFormState();
}

class _FinishVisitFormState extends ConsumerState<FinishVisitForm> {
  final _temperature = TextEditingController();
  final _reason = TextEditingController();
  int? _wind;

  /// Starts at 0 %, where the slider sits, as on the start form (D-063).
  int _cloud = 0;
  bool _zeroConfirmed = false;

  /// True while a save runs, so the buttons cannot be pressed twice.
  bool _saving = false;

  /// The route stats and what they were worked out from. Coverage compares
  /// every sample with every point, so they are not redone on each keystroke.
  RouteStats? _stats;
  List<SurveyTrackPoint>? _statsPoints;
  Transect? _statsTransect;
  ProjectProtocol? _statsProtocol;
  String? _statsPauses;

  @override
  void dispose() {
    _temperature.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickWind() async {
    final picked = await WindPickerSheet.show(context, selected: _wind);
    if (picked != null) setState(() => _wind = picked);
  }

  /// The values to store. The true-zero confirmation only counts when the
  /// visit has no butterfly (V06 refuses it otherwise).
  FinishValues _values(int observationCount) => FinishValues(
    temperatureEndC: parseTemperature(_temperature.text),
    windBeaufortEnd: _wind,
    cloudCoverEndPct: _cloud,
    weatherMissingReason: _reason.text.trim(),
    zeroObservationConfirmed: observationCount == 0 && _zeroConfirmed,
  );

  /// Cancelling is T041's.
  void _cancelVisit() {
    // TODO(T041): open the cancel flow.
    _showMessage('Cancelling a visit is coming in a later version');
  }

  /// The route stats for [points], worked out again only when the points,
  /// the transect, the protocol or the pauses changed.
  RouteStats _routeStats(
    List<SurveyTrackPoint> points,
    Transect transect,
    ProjectProtocol protocol,
  ) {
    final stats = _stats;
    if (stats != null &&
        identical(points, _statsPoints) &&
        transect == _statsTransect &&
        protocol == _statsProtocol &&
        widget.visit.pauses == _statsPauses) {
      return stats;
    }
    _statsPoints = points;
    _statsTransect = transect;
    _statsProtocol = protocol;
    _statsPauses = widget.visit.pauses;
    return _stats = RouteStats.compute(
      points: points,
      transectLine: parseLineString(transect.geometry),
      protocol: protocol,
      pauses: parsePauses(widget.visit.pauses),
    );
  }

  /// The observer's words for a rule the visit failed.
  String _ruleMessage(VisitRuleError error) {
    final messages = [
      if (error.has('V05'))
        'To finish, fill in the end weather or give a reason.',
      if (error.has('V06')) 'Tick the true-zero confirmation.',
    ];
    return messages.isEmpty ? '$error' : messages.join(' ');
  }

  /// Checks the rules first, for a clear message and without touching the
  /// tracker, then stops the tracker, completes the visit, starts a sync and
  /// goes to the transect.
  ///
  /// The tracker is stopped so the point count and the distance include every
  /// point. If the save is refused after that (the visit was locked or
  /// cancelled by a pull in those seconds), the tracker starts again, which
  /// does nothing for a visit that is no longer in progress.
  Future<void> _finishAndSave(int observationCount) async {
    final visit = widget.visit;
    final values = _values(observationCount);
    final repository = ref.read(visitRepositoryProvider);
    final tracking = ref.read(trackingControllerProvider.notifier);

    setState(() => _saving = true);
    try {
      await repository.checkCanFinish(visit.id, values);
    } on VisitRuleError catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(_ruleMessage(error));
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save the visit: $error');
      return;
    }

    try {
      if (widget.recordedHere) await tracking.stop();
      await repository.finish(visit.id, values);
    } catch (error) {
      if (widget.recordedHere) await tracking.restart();
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save the visit: $error');
      return;
    }
    if (ref.read(authControllerProvider).profile != null) {
      unawaited(ref.read(syncRunnerProvider.notifier).run());
    }
    if (!mounted) return;
    // Taken before navigating: this screen is gone afterwards.
    final messenger = ScaffoldMessenger.of(context);
    context.go('/projects/${visit.projectId}/transects/${visit.transectId}');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Visit saved')));
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    // Everything is watched (not only read when Finish is pressed): Riverpod
    // pauses a provider nobody listens to, and its value would go stale.
    final protocol = ref.watch(projectProtocolProvider(visit.projectId));
    final transect = ref.watch(transectProvider(visit.transectId));
    final sections = ref.watch(transectSectionsProvider(visit.transectId));
    final route = ref.watch(visitRouteProvider(visit.id));
    final observations = ref.watch(visitObservationsProvider(visit.id));
    final taxonIds = observations.value == null
        ? ''
        : ({
            for (final row in observations.value!) row.taxonId,
          }.toList()..sort()).join(',');
    final taxa = ref.watch(taxaByIdsProvider(taxonIds));

    // Taxon names are only for the warning lines, so they do not hold the
    // screen back (a new taxon would otherwise flash a spinner).
    final loading = [protocol, transect, sections, route, observations];
    if (loading.any((value) => !value.hasValue)) {
      final error = loading.where((value) => value.hasError).firstOrNull;
      return Scaffold(
        appBar: AppBar(title: const Text('Finish visit')),
        body: Center(
          child: error != null
              ? Text('${error.error}')
              : const CircularProgressIndicator(),
        ),
      );
    }
    final protocolRow = protocol.value;
    final transectRow = transect.value;
    if (protocolRow == null || transectRow == null) {
      return const VisitMessageScreen(
        "The transect or the project's protocol is not on this phone. "
        'Sync first.',
      );
    }

    final now = DateTime.now();
    final points = route.requireValue;
    final summary = VisitSummary.fromObservations(observations.requireValue);
    final taxonNames = {
      for (final taxon in taxa.value ?? const <Taxon>[])
        taxon.id: taxon.scientificName,
    };
    final pausedAt = visit.pausedAt;
    final stats = widget.recordedHere
        ? _routeStats(points, transectRow, protocolRow)
        : null;
    final temperature = parseTemperature(_temperature.text);

    // Section codes in walking order, then the observations without one.
    final sectionCounts = <(String, int)>[
      for (final entry in sections.requireValue)
        (
          'Section ${entry.section.sectionCode}',
          summary.perSection[entry.section.id] ?? 0,
        ),
    ];
    final withoutSection = summary.perSection[null] ?? 0;
    if (withoutSection > 0) sectionCounts.add(('No section', withoutSection));

    return Scaffold(
      appBar: AppBar(title: Text('Finish visit · ${transectRow.code}')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const FormSectionTitle('Summary'),
          VisitSummaryCard(
            walked: walkingTime(visit, now),
            distanceM: stats?.distanceM ?? visit.distanceWalkedM,
            summary: summary,
            sectionCounts: sectionCounts,
          ),
          FinishWarnings(
            visit: visit,
            protocol: protocolRow,
            routeStats: stats,
            lastPointAt: points.isEmpty ? null : points.last.recordedAt,
            pauses: [
              ...parsePauses(visit.pauses),
              // The running pause, so a paused visit does not count as lost GPS.
              if (pausedAt != null)
                VisitPause(startedAt: pausedAt.toUtc(), endedAt: now.toUtc()),
            ],
            observations: observations.requireValue,
            taxonNames: taxonNames,
            temperatureEndC: temperature,
            windBeaufortEnd: _wind,
            cloudCoverEndPct: _cloud,
            weatherMissingReason: _reason.text,
            now: now,
          ),
          const FormSectionTitle('Weather at the end'),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _temperature,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [temperatureFormatter],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Temperature',
                      suffixText: '°C',
                      prefixIcon: Icon(Icons.thermostat_outlined),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.air),
                  title: const Text('Wind'),
                  subtitle: Text(
                    _wind == null ? 'Not set' : beaufortLabel(_wind!),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickWind,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Cloud cover'),
                  trailing: Text(
                    '$_cloud %',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Slider(
                  value: _cloud.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 10,
                  label: '$_cloud %',
                  onChanged: (value) => setState(() => _cloud = value.round()),
                ),
              ],
            ),
          ),
          const FormSectionTitle('If the weather is missing'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _reason,
                maxLength: 200,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'If you could not record the weather, say why',
                ),
              ),
            ),
          ),
          if (summary.observationCount == 0) ...[
            const FormSectionTitle('No butterflies'),
            Card(
              child: CheckboxListTile(
                value: _zeroConfirmed,
                onChanged: (value) =>
                    setState(() => _zeroConfirmed = value ?? false),
                title: const Text(_zeroSentence),
              ),
            ),
          ],
        ],
      ),
      // Buttons at the bottom, in reach of the thumb.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  onPressed: _saving ? null : _cancelVisit,
                  child: const Text('Cancel visit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Finish and save'),
                  onPressed: _saving
                      ? null
                      : () => _finishAndSave(summary.observationCount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
