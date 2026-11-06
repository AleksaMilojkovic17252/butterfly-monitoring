import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/location/location_message.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:mobile/core/validation/plant_rules.dart';
import 'package:mobile/features/projects/domain/project_closed.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/observations/domain/draft_photo.dart';
import 'package:mobile/features/observations/domain/photo_parent.dart';
import 'package:mobile/features/observations/ui/widgets/draft_photo_strip.dart';
import 'package:mobile/features/observations/ui/widgets/record_photo_section.dart';
import 'package:mobile/features/resources/data/plant_repository.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';
import 'package:mobile/features/resources/domain/plant_input.dart';
import 'package:mobile/features/resources/domain/plant_links.dart';
import 'package:mobile/features/resources/domain/recorded_by.dart';
import 'package:mobile/features/resources/ui/widgets/plant_form.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';

/// The plant form as a full screen (T052): a scrolling [PlantForm] with Save
/// fixed at the bottom. It pops the id of the saved record, so a caller can
/// show "Saved" or link the record.
///
/// - New record: [plantId] is null. [visitId] is the visit it is recorded on
///   (null from the project's tile). With [linkRole] it is made from a butterfly
///   observation's link: the relation is preset and restricted.
/// - Edit: [plantId] is the record. A locked visit makes it read-only, and
///   so does a closed project (T099).
///
/// Opened by the router at `/projects/:id/plants/new` and `.../plants/:plantId`,
/// and with `Navigator.push` from the link picker, which sits in a bottom sheet
/// (a pageless route, so `context.push` would not work there).
class PlantEntryScreen extends ConsumerWidget {
  const PlantEntryScreen({
    super.key,
    required this.projectId,
    this.visitId,
    this.plantId,
    this.linkRole,
  });
  final String projectId;
  final String? visitId;
  final String? plantId;
  final PlantLinkRole? linkRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = plantId;
    if (id == null) {
      return _PlantEntryView(
        projectId: projectId,
        visitId: visitId,
        linkRole: linkRole,
      );
    }
    final record = ref.watch(plantRecordProvider(id));
    return switch (record) {
      AsyncData(:final value) when value != null => _PlantEntryView(
        projectId: projectId,
        opened: value,
      ),
      AsyncData() => Scaffold(
        appBar: AppBar(title: const Text('Plant record')),
        body: const Center(
          child: Text('This plant record is not on this phone.'),
        ),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(title: const Text('Plant record')),
        body: Center(child: Text('Could not load it: $error')),
      ),
      _ => Scaffold(
        appBar: AppBar(title: const Text('Plant record')),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

/// The state of the screen. It keeps the values the user is editing, so the
/// stream that feeds [PlantEntryScreen] can update without losing them. For an
/// edit, [opened] is the row as it was when the form opened.
class _PlantEntryView extends ConsumerStatefulWidget {
  const _PlantEntryView({
    required this.projectId,
    this.visitId,
    this.opened,
    this.linkRole,
  });
  final String projectId;
  final String? visitId;
  final PlantResourceObservation? opened;
  final PlantLinkRole? linkRole;

  @override
  ConsumerState<_PlantEntryView> createState() => _PlantEntryViewState();
}

class _PlantEntryViewState extends ConsumerState<_PlantEntryView> {
  /// The row as the form opened (an edit); never replaced, so the changes are
  /// worked out against what the user saw (D-082).
  late final PlantResourceObservation? _opened = widget.opened;
  late PlantInput _input;

  bool _saving = false;
  String? _error;

  /// True while the position for a new record is being found.
  bool _locating = false;
  String? _locationMessage;

  /// Photos taken in this screen for a new record, not saved yet (T050). The
  /// first is primary.
  var _drafts = <DraftPhoto>[];
  bool _capturing = false;

  /// Set once the record and its photos are written, so [dispose] keeps the
  /// files.
  bool _saved = false;

  /// Read in [initState]: `ref` is not safe to use inside [dispose].
  late final PhotoRepository _photos;

  @override
  void initState() {
    super.initState();
    _photos = ref.read(photoRepositoryProvider);
    final opened = _opened;
    if (opened != null) {
      _input = PlantInput.fromRow(opened);
    } else {
      final role = widget.linkRole;
      _input = PlantInput(
        resourceType: role == null ? '' : presetResourceType(role),
      );
      _fillPoint();
    }
  }

  /// A new record that is left without saving throws its draft photos away.
  @override
  void dispose() {
    if (!_saved) _photos.discardDrafts(_drafts);
    super.dispose();
  }

  /// The oldest tracker fix [_fillPoint] still trusts. The tracker's own
  /// interval is 5 s (15 s in battery saver), so a fix older than this means
  /// GPS has stalled, and the observer may have walked on.
  static const _maxFixAge = Duration(seconds: 30);

  /// Puts the phone's position in as a point when the form opens: the visit
  /// tracker's newest fix while it records and the fix is recent, otherwise a
  /// fresh reading. It never overwrites a shape the user drew in the meantime.
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
        _input = _input.withGeometry(CapturedGeometry.point(fix));
      }
    });
  }

  // --- Photos of a new record ---------------------------------------------------

  Future<void> _addPhoto(ImageSource source) async {
    setState(() {
      _capturing = true;
      _error = null;
    });
    try {
      final draft = await _photos.capture(source);
      if (draft == null) return;
      // The screen was closed while the photo was processed.
      if (!mounted) {
        await _photos.discardDrafts([draft]);
        return;
      }
      setState(() => _drafts = [..._drafts, draft]);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not add the photo: $error');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _removePhoto(DraftPhoto draft) {
    setState(
      () => _drafts = [
        for (final d in _drafts)
          if (d.id != draft.id) d,
      ],
    );
    _photos.discardDrafts([draft]);
  }

  /// The photos part of the form. A new record holds drafts until Save; a saved
  /// one adds and removes photos right away.
  Widget _photoSlot({bool readOnly = false}) {
    final opened = _opened;
    if (opened != null) {
      return RecordPhotoSection(
        parent: PhotoParent.plant(
          id: opened.id,
          projectId: opened.projectId,
          surveyVisitId: opened.surveyVisitId,
        ),
        photoRequired: false,
        readOnly: readOnly,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_drafts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DraftPhotoStrip(
              drafts: _drafts,
              onRemove: _saving ? (_) {} : _removePhoto,
            ),
          ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _saving || _capturing
                  ? null
                  : () => _addPhoto(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Photo'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _saving || _capturing
                  ? null
                  : () => _addPhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
            if (_capturing) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // --- Save and delete ---------------------------------------------------------

  /// Everything the rules need is there: a relation, a shape, and notes for an
  /// unidentified plant.
  bool get _canSave =>
      _input.resourceType.isNotEmpty &&
      _input.geometry != null &&
      !plantNotesMissing(_input.plantTaxonId, _input.notes) &&
      !_saving &&
      !_capturing;

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
      final repository = ref.read(plantRepositoryProvider);
      final opened = _opened;
      final String id;
      if (opened == null) {
        id = await repository.create(
          projectId: widget.projectId,
          visitId: widget.visitId,
          createdById: userId,
          input: _input,
          drafts: _drafts,
        );
        _saved = true;
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

  /// Asks, then deletes the record. A record that butterfly observations still
  /// link to is refused with a message.
  Future<void> _delete() async {
    final opened = _opened;
    if (opened == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this plant record?'),
        content: const Text('Its photos are deleted too.'),
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
    // Taken before the delete: the live query then reports the record gone,
    // which replaces this form with a message and disposes this state.
    final navigator = Navigator.of(context);
    try {
      await ref.read(plantRepositoryProvider).delete(opened);
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
    // Another member's record is read-only (T112). A new record, or one made
    // on this phone before the creator was known, is always editable.
    final profile = ref.watch(authControllerProvider).profile;
    final creatorId = opened?.createdById;
    final canEdit =
        opened == null ||
        creatorId == null ||
        creatorId == profile?.id ||
        (profile?.isAdmin ?? false);
    final readOnly = locked || closedRecord || !canEdit;

    final role = widget.linkRole;
    final title = opened != null
        ? 'Plant record'
        : role == null
        ? 'Add plant'
        : 'Add ${plantLinkLabel(role).toLowerCase()}';

    return PopScope(
      // Closing while Save runs would leave the user guessing.
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
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
                          'This visit is locked, so the record cannot be changed.',
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: PlantForm(
                  projectId: widget.projectId,
                  input: _input,
                  onChanged: (input) => setState(() => _input = input),
                  photos: _photoSlot(readOnly: closedRecord || !canEdit),
                  linkRole: role,
                  readOnly: readOnly,
                  editing: opened != null,
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
