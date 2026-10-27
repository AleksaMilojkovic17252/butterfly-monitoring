import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/auth/domain/user_profile.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/protocol_window.dart';
import 'package:mobile/features/transects/ui/protocol_summary.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/beaufort.dart';
import 'package:mobile/features/visits/domain/visit_start_values.dart';
import 'package:mobile/features/visits/domain/weather_check.dart';

/// The start-visit form (T035, outline §11.2 F): observers, start weather,
/// notes and the protocol confirmation, then **Save draft** or **Start**.
/// Opens the caller's draft of the transect when there is one.
class StartVisitScreen extends ConsumerWidget {
  const StartVisitScreen({
    super.key,
    required this.projectId,
    required this.transectId,
  });
  final String projectId;
  final String transectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Everything comes from Drift or memory, so the form opens without the
    // network (T035: under 1 s).
    final transect = ref.watch(transectProvider(transectId));
    final protocol = ref.watch(projectProtocolProvider(projectId));
    final draft = ref.watch(transectDraftProvider(transectId));
    final profile = ref.watch(authControllerProvider).profile;

    // `hasValue` stays true while a provider reloads or reports an error
    // after its first value, so the form (and what was typed) stays up.
    final Widget body;
    if (!transect.hasValue || !protocol.hasValue || !draft.hasValue) {
      final error = transect.error ?? protocol.error ?? draft.error;
      body = error != null
          ? Center(child: Text('$error'))
          : const Center(child: CircularProgressIndicator());
    } else if (profile == null) {
      body = const _Message('You are logged out. Log in to start a visit.');
    } else if (transect.value == null || protocol.value == null) {
      body = const _Message(
        'The transect or the project protocol is not on this phone. '
        'Download the project first.',
      );
    } else {
      return _StartVisitForm(
        transect: transect.value!,
        protocol: protocol.value!,
        observer: profile,
        draft: draft.value,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Start visit')),
      body: body,
    );
  }
}

/// The form itself, once the transect, protocol and any draft are loaded.
/// Its fields start from [draft] when there is one. Only the [draft] the form
/// opened with is used: a later pull may change the row, but the form keeps
/// carrying on from what it showed (see `VisitRepository._update`).
class _StartVisitForm extends ConsumerStatefulWidget {
  const _StartVisitForm({
    required this.transect,
    required this.protocol,
    required this.observer,
    required this.draft,
  });
  final Transect transect;
  final ProjectProtocol protocol;
  final UserProfile observer;
  final SurveyVisit? draft;

  @override
  ConsumerState<_StartVisitForm> createState() => _StartVisitFormState();
}

class _StartVisitFormState extends ConsumerState<_StartVisitForm> {
  final _observerNames = TextEditingController();
  final _temperature = TextEditingController();
  final _notes = TextEditingController();

  /// The draft as the form opened it, or null for a new visit.
  SurveyVisit? _openedDraft;
  int _observerCount = 1;
  int? _wind;
  int? _cloud;
  String _precipitation = 'none';
  bool _protocolConfirmed = false;

  /// True while a save runs, so the buttons cannot be pressed twice.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // TODO(T073): log the `visit_form_open` event (time from the tap to here).
    final draft = widget.draft;
    _openedDraft = draft;
    if (draft != null) {
      final values = VisitStartValues.fromVisit(draft);
      _observerCount = values.observerCount;
      _observerNames.text = values.observerNames;
      _temperature.text = values.temperatureC?.toString() ?? '';
      _wind = values.windBeaufort;
      _cloud = values.cloudCoverPct;
      _precipitation = values.precipitation;
      _notes.text = values.notes;
    }
  }

  @override
  void dispose() {
    _observerNames.dispose();
    _temperature.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// The typed temperature with one decimal, or null when empty or not a
  /// number. A comma counts as the decimal point.
  double? get _temperatureC {
    final value = double.tryParse(_temperature.text.replaceAll(',', '.'));
    if (value == null) return null;
    return (value * 10).round() / 10;
  }

  /// The failed weather thresholds, or null while temperature, wind or cloud
  /// is missing (the weather cannot be checked yet).
  List<String>? get _failedThresholds {
    final temperature = _temperatureC;
    final wind = _wind;
    final cloud = _cloud;
    if (temperature == null || wind == null || cloud == null) return null;
    return failedWeatherThresholds(
      protocol: widget.protocol,
      temperatureC: temperature,
      windBeaufort: wind,
      cloudCoverPct: cloud,
      precipitation: _precipitation,
    );
  }

  /// The form's current values, for the repository.
  VisitStartValues get _values {
    final failed = _failedThresholds;
    return VisitStartValues(
      observerCount: _observerCount,
      observerNames: _observerNames.text.trim(),
      temperatureC: _temperatureC,
      windBeaufort: _wind,
      cloudCoverPct: _cloud,
      precipitation: _precipitation,
      notes: _notes.text.trim(),
      // Null while the weather is incomplete.
      weatherSuitable: failed?.isEmpty,
    );
  }

  /// Saves without starting. Nothing is required.
  Future<void> _saveDraft() async {
    await _save(start: false);
  }

  /// Starts the visit after three checks: no other visit is in progress,
  /// everything Start needs is filled in, and unsuitable weather is confirmed
  /// with "Start anyway".
  Future<void> _start() async {
    // `build` watches both providers, so their values are current here.
    final inProgress = ref.read(visitInProgressProvider).value;
    if (inProgress != null) {
      final other = ref.read(transectProvider(inProgress.transectId)).value;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.directions_walk),
          title: const Text('A visit is already in progress'),
          content: Text(
            'Finish or cancel the visit in progress on '
            '${other?.code ?? 'another transect'} first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final missing = [
      if (_temperatureC == null) 'temperature',
      if (_wind == null) 'wind',
      if (_cloud == null) 'cloud cover',
      if (!_protocolConfirmed) 'protocol confirmation',
    ];
    if (missing.isNotEmpty) {
      _showMessage('To start, fill in: ${missing.join(', ')}.');
      return;
    }

    final failed = _failedThresholds!;
    if (failed.isNotEmpty) {
      final goOn = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: const Text('Weather outside the protocol'),
          content: Text(
            '${failed.join('\n')}\n\n'
            'The visit will be marked as not weather-suitable.',
          ),
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
      if (goOn != true || !mounted) return;
    }

    await _save(start: true);
  }

  /// Writes the visit through the repository, then goes back to the transect.
  Future<void> _save({required bool start}) async {
    setState(() => _saving = true);
    final repository = ref.read(visitRepositoryProvider);
    try {
      if (start) {
        await repository.start(
          draft: _openedDraft,
          protocol: widget.protocol,
          transectId: widget.transect.id,
          observerId: widget.observer.id,
          values: _values,
        );
      } else {
        await repository.saveDraft(
          draft: _openedDraft,
          protocol: widget.protocol,
          transectId: widget.transect.id,
          observerId: widget.observer.id,
          values: _values,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save the visit: $error');
      return;
    }
    if (!mounted) return;
    // TODO(T039): after Start, open the active visit screen instead.
    _showMessage(start ? 'Visit started' : 'Draft saved');
    context.pop();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Bottom sheet with the 13 Beaufort forces; large rows for one thumb.
  Future<void> _pickWind() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var force = 0; force <= 12; force++)
              ListTile(
                selected: force == _wind,
                leading: CircleAvatar(child: Text('$force')),
                title: Text(beaufortDescriptions[force]),
                subtitle: Text(beaufortHints[force]),
                onTap: () => Navigator.pop(context, force),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _wind = picked);
  }

  @override
  Widget build(BuildContext context) {
    // Watched (not only read in [_start]): Riverpod pauses a provider nobody
    // listens to, and its `.future` would never complete.
    final inProgress = ref.watch(visitInProgressProvider).value;
    if (inProgress != null) ref.watch(transectProvider(inProgress.transectId));
    final now = DateTime.now();
    final warnings = [
      seasonWarning(widget.protocol, now),
      timeWindowWarning(widget.protocol, now),
    ].nonNulls.toList();
    final draft = _openedDraft;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Start visit · ${widget.transect.code}')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          if (warnings.isNotEmpty)
            Card(
              color: scheme.tertiaryContainer,
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(warnings.join('\n')),
                subtitle: const Text('You can still start the visit.'),
              ),
            ),
          if (draft != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit_note),
                title: Text(
                  'Carrying on with your draft from '
                  '${_dateTime(draft.createdAt)}',
                ),
              ),
            ),
          const _SectionTitle('Observers'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(widget.observer.displayName),
                  subtitle: const Text('Observer'),
                ),
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: const Text('Number of observers'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: _observerCount > 1
                            ? () => setState(() => _observerCount--)
                            : null,
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$_observerCount',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        onPressed: _observerCount < _maxObservers
                            ? () => setState(() => _observerCount++)
                            : null,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    controller: _observerNames,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: "Other observers' names",
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _SectionTitle('Weather at the start'),
          // T085 (Phase 2) reserves a slot here for an "Auto-fill weather"
          // button. Manual values stay authoritative in Phase 1.
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
                    inputFormatters: [_temperatureFormatter],
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
                    _cloud == null ? 'Not set' : '$_cloud %',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                // A slider always has a position; until it is moved, the
                // value stays null and shows "Not set".
                Slider(
                  value: (_cloud ?? 0).toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 10,
                  label: '${_cloud ?? 0} %',
                  onChanged: (value) => setState(() => _cloud = value.round()),
                  // onChanged skips a value equal to the slider's position,
                  // so a tap on 0 % while "Not set" (shown at 0) would do
                  // nothing. onChangeEnd always fires.
                  onChangeEnd: (value) =>
                      setState(() => _cloud = value.round()),
                ),
                // A dropdown keeps the same height whatever is picked; chips
                // in a Wrap reflowed (and moved the form) when the selected
                // chip grew its check mark.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _precipitation,
                    decoration: const InputDecoration(
                      labelText: 'Precipitation',
                      prefixIcon: Icon(Icons.water_drop_outlined),
                    ),
                    items: [
                      for (final value in precipitationValues)
                        DropdownMenuItem(
                          value: value,
                          child: Text(precipitationLabel(value)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _precipitation = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          _Suitability(failed: _failedThresholds),
          const _SectionTitle('Notes'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _notes,
                minLines: 3,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ),
          ),
          const _SectionTitle('Protocol'),
          Card(
            child: Column(
              children: [
                ProtocolSummary(protocol: widget.protocol),
                CheckboxListTile(
                  value: _protocolConfirmed,
                  onChanged: (value) =>
                      setState(() => _protocolConfirmed = value ?? false),
                  title: const Text('I will walk this visit by the protocol'),
                ),
              ],
            ),
          ),
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
                  onPressed: _saving ? null : _saveDraft,
                  child: const Text('Save draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start'),
                  onPressed: _saving ? null : _start,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Most observers the stepper allows. The protocol has no limit; this keeps
/// a stuck finger from producing an implausible count.
const _maxObservers = 20;

/// Allows a temperature like "-3", "17" or "17,5": an optional minus, up to
/// two digits and one decimal. Any other edit is ignored.
final _temperatureFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) =>
      RegExp(r'^-?\d{0,2}([.,]\d?)?$').hasMatch(newValue.text)
      ? newValue
      : oldValue,
);

/// The live weather check: what is missing, suitable, or which thresholds
/// fail. [failed] is null while the weather is incomplete.
class _Suitability extends StatelessWidget {
  const _Suitability({required this.failed});
  final List<String>? failed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final failed = this.failed;
    if (failed == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.help_outline),
          title: Text('Fill in temperature, wind and cloud cover'),
          subtitle: Text('The weather is then checked against the protocol.'),
        ),
      );
    }
    if (failed.isEmpty) {
      return Card(
        color: scheme.primaryContainer,
        child: const ListTile(
          leading: Icon(Icons.check_circle_outline),
          title: Text('Weather is suitable'),
        ),
      );
    }
    return Card(
      color: scheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: const Text('Weather is outside the protocol'),
        subtitle: Text(failed.join('\n')),
      ),
    );
  }
}

/// A centred sentence instead of the form.
class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(text)),
    );
  }
}

/// Small heading above each card of the form.
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
