import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/location/location_message.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:mobile/core/validation/habitat_rules.dart';
import 'package:mobile/features/projects/domain/project_closed.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/resources/data/habitat_repository.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';
import 'package:mobile/features/resources/domain/habitat_input.dart';
import 'package:mobile/features/resources/domain/recorded_by.dart';
import 'package:mobile/features/resources/ui/widgets/habitat_form.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';

/// The habitat form as a full screen (T054): a scrolling [HabitatForm] with
/// Save fixed at the bottom. It pops the id of the saved feature, so a caller
/// can show "Saved".
///
/// - New feature: [habitatId] is null. [visitId] is the visit it is recorded on
///   (null from the project's tile).
/// - Edit: [habitatId] is the feature. A locked visit makes it read-only, and
///   so does a closed project (T099). Another member's feature is read-only
///   too, unless the user is an admin (T112).
///
/// Opened by the router at `/projects/:id/habitats/new` and
/// `.../habitats/:habitatId`.
class HabitatEntryScreen extends ConsumerWidget {
  const HabitatEntryScreen({
    super.key,
    required this.projectId,
    this.visitId,
    this.habitatId,
  });
  final String projectId;
  final String? visitId;
  final String? habitatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = habitatId;
    if (id == null) {
      return _HabitatEntryView(projectId: projectId, visitId: visitId);
    }
    final feature = ref.watch(habitatFeatureProvider(id));
    return switch (feature) {
      AsyncData(:final value) when value != null => _HabitatEntryView(
        projectId: projectId,
        opened: value,
      ),
      AsyncData() => Scaffold(
        appBar: AppBar(title: const Text('Habitat feature')),
        body: const Center(
          child: Text('This habitat feature is not on this phone.'),
        ),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(title: const Text('Habitat feature')),
        body: Center(child: Text('Could not load it: $error')),
      ),
      _ => Scaffold(
        appBar: AppBar(title: const Text('Habitat feature')),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

/// The state of the screen. It keeps the values the user is editing, so the
/// stream that feeds [HabitatEntryScreen] can update without losing them. For
/// an edit, [opened] is the row as it was when the form opened.
class _HabitatEntryView extends ConsumerStatefulWidget {
  const _HabitatEntryView({required this.projectId, this.visitId, this.opened});
  final String projectId;
  final String? visitId;
  final HabitatFeature? opened;

  @override
  ConsumerState<_HabitatEntryView> createState() => _HabitatEntryViewState();
}

class _HabitatEntryViewState extends ConsumerState<_HabitatEntryView> {
  /// The row as the form opened (an edit); never replaced, so the changes are
  /// worked out against what the user saw (D-082).
  late final HabitatFeature? _opened = widget.opened;
  late HabitatInput _input;

  bool _saving = false;
  String? _error;

  /// True while the position for a new feature is being found.
  bool _locating = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    final opened = _opened;
    if (opened != null) {
      _input = HabitatInput.fromRow(opened);
    } else {
      _input = const HabitatInput();
      _fillPoint();
    }
  }

  /// The oldest tracker fix [_fillPoint] still trusts. The tracker's own
  /// interval is 5 s (15 s in battery saver), so a fix older than this means
  /// GPS has stalled, and the observer may have walked on.
  static const _maxFixAge = Duration(seconds: 30);

  /// Puts the phone's position in as a point when the form opens: the visit
  /// tracker's newest fix while it records and the fix is recent, otherwise a
  /// fresh reading (D-087). It never overwrites a shape the user drew in the
  /// meantime.
  Future<void> _fillPoint() async {
    setState(() => _locating = true);
    LatLng? fix;
    String? problem;
    final tracking = ref.read(trackingControllerProvider);
    final newest = tracking.recording && !tracking.paused
        ? tracking.lastPosition
        : null;
    // A stale fix is not used: a fresh reading is asked for instead.
    final live =
        newest != null &&
            DateTime.now().toUtc().difference(newest.timestamp.toUtc()) <=
                _maxFixAge
        ? newest
        : null;
    if (live != null) {
      fix = LatLng(live.latitude, live.longitude);
    } else {
      try {
        final position = await ref.read(currentPositionProvider)();
        fix = LatLng(position.latitude, position.longitude);
      } on LocationException catch (error) {
        problem = locationMessage(error.failure);
      } catch (error) {
        problem = 'Could not get the position: $error';
      }
    }
    if (!mounted) return;
    setState(() {
      _locating = false;
      _locationMessage = problem;
      if (fix != null && _input.geometry == null) {
        final point = CapturedGeometry.point(fix);
        _input = _input.copyWith(geometry: () => point);
      }
    });
  }

  /// A habitat type, a shape, no height problem, and not already saving.
  bool get _canSave =>
      _input.habitatTypeId.isNotEmpty &&
      _input.geometry != null &&
      vegetationHeightProblem(_input.vegetationHeightCm) == null &&
      !_saving;

  Future<void> _save() async {
    final userId = ref.read(authControllerProvider).profile?.id;
    if (userId == null) {
      setState(() => _error = 'You are signed out.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(habitatRepositoryProvider);
      final opened = _opened;
      final String id;
      if (opened == null) {
        id = await repository.create(
          projectId: widget.projectId,
          visitId: widget.visitId,
          createdById: userId,
          input: _input,
        );
      } else {
        await repository.update(opened: opened, input: _input);
        id = opened.id;
      }
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } on StateError catch (error) {
      _fail(error.message);
    } catch (error) {
      _fail('Could not save: $error');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = message;
    });
  }

  /// Asks, then deletes the feature.
  Future<void> _delete() async {
    final opened = _opened;
    if (opened == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this habitat feature?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    // Taken before the delete: the live query then reports the feature gone,
    // which replaces this form with a message and disposes this state.
    final navigator = Navigator.of(context);
    try {
      await ref.read(habitatRepositoryProvider).delete(opened);
      navigator.pop();
    } on StateError catch (error) {
      _fail(error.message);
    } catch (error) {
      _fail('Could not delete: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final opened = _opened;
    // Watched, so the form turns read-only if a pull locks the visit.
    final visitId = opened?.surveyVisitId;
    final visit = visitId == null
        ? null
        : ref.watch(visitProvider(visitId)).value;
    final locked = visit != null && visitIsLocked(visit.status);
    // A closed project accepts no changed data (T099, D-104): the form is
    // read-only, with no Save or Delete.
    final closedRecord =
        opened != null && ref.watch(projectClosedProvider(widget.projectId));
    // Another member's feature is read-only (T112). A new feature, or one made
    // on this phone before the creator was known, is always editable.
    final profile = ref.watch(authControllerProvider).profile;
    final creatorId = opened?.createdById;
    final canEdit =
        opened == null ||
        creatorId == null ||
        creatorId == profile?.id ||
        (profile?.isAdmin ?? false);
    final readOnly = locked || closedRecord || !canEdit;

    return PopScope(
      // Closing while Save runs would leave the user guessing.
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(opened == null ? 'Add habitat' : 'Habitat feature'),
          actions: [
            if (opened != null && !readOnly)
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: _saving ? null : _delete,
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (opened != null && creatorId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recorded by ${recordedByText(creatorId: creatorId, creatorName: opened.createdByName, userId: profile?.id)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              if (locked)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This visit is locked, so the feature cannot be changed.',
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: HabitatForm(
                  projectId: widget.projectId,
                  input: _input,
                  onChanged: (input) => setState(() => _input = input),
                  readOnly: readOnly,
                  locating: _locating,
                  locationMessage: _locationMessage,
                ),
              ),
              if (!readOnly) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _canSave ? _save : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 56),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
