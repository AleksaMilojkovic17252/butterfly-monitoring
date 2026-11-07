import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/evaluation/eval_logger.dart';
import 'package:mobile/core/location/location_message.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:mobile/core/validation/observation_values.dart';
import 'package:mobile/core/validation/rule_messages.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/observations/domain/draft_photo.dart';
import 'package:mobile/features/observations/domain/observation_details.dart';
import 'package:mobile/features/observations/domain/taxon_search.dart';
import 'package:mobile/features/observations/ui/widgets/count_stepper.dart';
import 'package:mobile/features/observations/ui/widgets/draft_photo_strip.dart';
import 'package:mobile/features/observations/ui/widgets/observation_details_form.dart';
import 'package:mobile/features/observations/ui/widgets/photo_prompt_dialog.dart';
import 'package:mobile/features/observations/ui/widgets/position_line.dart';
import 'package:mobile/features/observations/ui/widgets/taxon_picker.dart';
import 'package:mobile/features/resources/domain/captured_geometry.dart';
import 'package:mobile/features/resources/ui/geometry_capture_screen.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/visits/data/track_point_repository.dart';
import 'package:mobile/features/visits/domain/current_section.dart';
import 'package:mobile/features/visits/domain/local_time.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';
import 'package:uuid/uuid.dart';

/// What the sheet hands back after a save: the new observation's id (for
/// Undo) and the text for the "Saved" message.
typedef SavedObservation = ({String id, String label});

/// The quick butterfly entry (T045): pick a species, set the count, Save.
/// Position, time and section fill in by themselves. The Details button swaps
/// the species list for the optional details (T046): sex, behaviour, photos
/// and so on. Opened from Add butterfly on the active visit screen with [show].
///
/// With no [visit] it is the Free observation entry (T047), opened with
/// [showFree] as a full screen with an app bar instead of a sheet: a source
/// picker and a location row replace the position line, and the record has no
/// visit and no section.
///
/// With [afterVisit] it adds a butterfly to a finished visit (T110), opened
/// with [showAfterVisit] as a full screen: the time is picked inside the
/// visit's window and the position is placed on the map (no GPS is read).
class QuickButterflySheet extends ConsumerStatefulWidget {
  const QuickButterflySheet({
    super.key,
    required this.projectId,
    this.visit,
    this.accuracyWarningM,
    this.placedAt,
    this.afterVisit = false,
  });
  final String projectId;

  /// The visit the butterfly is seen on, or null for a free observation.
  final SurveyVisit? visit;

  /// Accuracy in metres above which the position gets a warning. Used only
  /// with a [visit].
  final double? accuracyWarningM;

  /// A point placed on the map before the sheet opened (the map long press).
  /// Free observation only.
  final LatLng? placedAt;

  /// True when [visit] is finished and the butterfly is added afterwards.
  final bool afterVisit;

  /// Opens the sheet and returns what was saved, or null when it was closed
  /// without saving.
  static Future<SavedObservation?> show(
    BuildContext context, {
    required SurveyVisit visit,
    required double accuracyWarningM,
  }) {
    return showModalBottomSheet<SavedObservation>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => QuickButterflySheet(
        projectId: visit.projectId,
        visit: visit,
        accuracyWarningM: accuracyWarningM,
      ),
    );
  }

  /// Opens the free observation (T047) as a full screen and returns what was
  /// saved, or null. [placedAt] starts it with that point placed on the map.
  static Future<SavedObservation?> showFree(
    BuildContext context, {
    required String projectId,
    LatLng? placedAt,
  }) {
    return Navigator.of(context).push<SavedObservation>(
      MaterialPageRoute(
        builder: (context) =>
            QuickButterflySheet(projectId: projectId, placedAt: placedAt),
      ),
    );
  }

  /// Opens the entry for a finished [visit] (T110) as a full screen and
  /// returns what was saved, or null.
  static Future<SavedObservation?> showAfterVisit(
    BuildContext context, {
    required SurveyVisit visit,
  }) {
    return Navigator.of(context).push<SavedObservation>(
      MaterialPageRoute(
        builder: (context) => QuickButterflySheet(
          projectId: visit.projectId,
          visit: visit,
          afterVisit: true,
        ),
      ),
    );
  }

  @override
  ConsumerState<QuickButterflySheet> createState() =>
      _QuickButterflySheetState();
}

/// Which of the three entries the sheet is: on the active visit, a free
/// observation (no visit, T047) or a butterfly added to a finished visit
/// (T110). Worked out once from [QuickButterflySheet.visit] and
/// [QuickButterflySheet.afterVisit].
enum _SheetMode { live, free, afterVisit }

class _QuickButterflySheetState extends ConsumerState<QuickButterflySheet> {
  Taxon? _selected;

  /// The optional details; the defaults are what a quick entry leaves.
  var _details = const ObservationDetails();

  /// True while the Details form replaces the species list.
  bool _detailsOpen = false;

  /// Starts at 1 each time the sheet opens.
  int _count = 1;

  /// The source of a free observation.
  String _source = freeObservationSources.first;

  /// The point placed on the map for a free observation; null means "read the
  /// GPS when saving".
  late LatLng? _placed = widget.placedAt;

  /// When the butterfly was seen, after-visit mode only. Starts at the end of
  /// the visit.
  late DateTime _observedAt = widget.visit?.endedAt ?? DateTime.now().toUtc();

  /// True while Save waits for a GPS fix and writes the observation.
  bool _saving = false;
  String? _error;

  /// Photos taken in this sheet, not saved yet (T050). The first is primary.
  var _drafts = <DraftPhoto>[];

  /// True while a photo is being taken, shrunk and hashed.
  bool _capturing = false;

  /// Set once the observation and its photos are written, so [dispose] keeps
  /// the files.
  bool _saved = false;

  /// Read in [initState]: `ref` is not safe to use inside [dispose], and a
  /// lazy `late final` would first run there when no photo was taken.
  late final PhotoRepository _photos;

  /// Identifies this opening of the sheet in the evaluation events (T073).
  final String _sheetId = const Uuid().v4();

  /// Runs from the sheet opening; its time at Save is the entry time (T073).
  final Stopwatch _openFor = Stopwatch();

  /// Taps inside the sheet so far (T073).
  int _taps = 0;

  /// Where each pointer in progress went down, by pointer id, so two fingers
  /// are told apart.
  final Map<int, Offset> _downAt = {};

  /// The last error message logged, so pressing Save again on the same
  /// failure does not log it again (T073).
  String? _lastLoggedError;

  @override
  void initState() {
    super.initState();
    _photos = ref.read(photoRepositoryProvider);
    _openFor.start();
    ref
        .read(evalLoggerProvider)
        .log(
          evalObsOpen,
          entityId: widget.visit?.id,
          payload: {'sheet': _sheetId, 'mode': _mode.name},
        );
    // A free observation asks for the GPS fix as soon as the sheet opens, so it
    // is usually there by the time the user has picked a species.
    if (_mode == _SheetMode.free && _placed == null) _startFix();
  }

  /// The GPS fix of a free observation, asked for when the sheet opens. Null
  /// until it arrives.
  Position? _fix;

  /// The request for [_fix]; Save waits for it when it is still running.
  Future<Position>? _fixRequest;

  /// A fix older than this is not used by Save: the user may have walked on.
  static const _maxFixAge = Duration(seconds: 30);

  /// Asks for a fix in the background and keeps it in [_fix]. A failure is not
  /// shown here: Save asks again and shows the reason then. The old fix is
  /// dropped, so call it inside `setState` once the sheet is on screen.
  void _startFix() {
    _fix = null;
    final request = ref.read(currentPositionProvider)();
    _fixRequest = request;
    request.then(
      (position) {
        if (mounted && identical(_fixRequest, request)) {
          setState(() => _fix = position);
        }
      },
      onError: (_) {
        if (mounted && identical(_fixRequest, request)) {
          setState(() => _fixRequest = null);
        }
      },
    );
  }

  /// The fix for Save: the one asked for earlier when it is recent, waiting for
  /// it if it is still coming, or a new request when it is old or there is none
  /// (it failed earlier).
  Future<Position> _fixForSave() {
    final fix = _fix;
    if (fix != null && DateTime.now().difference(fix.timestamp) <= _maxFixAge) {
      return Future.value(fix);
    }
    if (fix == null && _fixRequest != null) return _fixRequest!;
    setState(_startFix);
    return _fixRequest!;
  }

  /// The sheet can be closed in several ways (swipe down, Back, tapping
  /// outside), and all of them end here, so this is where unsaved drafts are
  /// thrown away. A saved sheet keeps its files.
  @override
  void dispose() {
    if (!_saved) _photos.discardDrafts(_drafts);
    super.dispose();
  }

  /// Opens the camera or the gallery and adds the result to the drafts.
  /// Cancelling adds nothing.
  Future<void> _addPhoto(ImageSource source) async {
    setState(() {
      _capturing = true;
      _error = null;
    });
    try {
      final draft = await _photos.capture(source);
      if (draft == null) return;
      // The sheet was closed while the photo was processed: nobody will save it.
      if (!mounted) {
        await _photos.discardDrafts([draft]);
        return;
      }
      setState(() => _drafts = [..._drafts, draft]);
    } on StateError catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('Could not add the photo: $error');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  /// Takes a draft out of the list and deletes its file.
  void _removePhoto(DraftPhoto draft) {
    setState(
      () => _drafts = [
        for (final d in _drafts)
          if (d.id != draft.id) d,
      ],
    );
    _photos.discardDrafts([draft]);
  }

  /// The confidence became `photo_required` and there is no photo: ask for one.
  /// Later adds nothing and does not block the save.
  Future<void> _askForPhoto() async {
    final source = await showPhotoPromptDialog(context);
    if (source != null) await _addPhoto(source);
  }

  /// The Photo and Gallery buttons, the spinner and the drafts, for the form.
  Widget _photoSlot() {
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

  _SheetMode get _mode {
    if (widget.visit == null) return _SheetMode.free;
    return widget.afterVisit ? _SheetMode.afterVisit : _SheetMode.live;
  }

  /// True for the two full-screen modes (free and after the visit): they have
  /// an app bar and a location row, and the species search gets the room above
  /// the keyboard.
  bool get _fullScreen => _mode != _SheetMode.live;

  /// The newest fix when GPS is running for this visit, otherwise null. A
  /// paused visit has a fix too, but an old one.
  Position? _liveFix(TrackingState tracking) {
    final live =
        tracking.visitId == widget.visit?.id &&
        tracking.recording &&
        !tracking.paused;
    return live ? tracking.lastPosition : null;
  }

  /// Saves the observation and closes the sheet. Without a live fix it asks
  /// for one first, and stays open with the reason if there is none.
  Future<void> _save() async {
    final taxon = _selected;
    final recordedById = ref.read(authControllerProvider).profile?.id;
    if (taxon == null) return;
    if (recordedById == null) {
      _showError('You are signed out.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final visit = widget.visit;
      final repository = ref.read(observationRepositoryProvider);
      final String id;
      if (visit != null && _mode == _SheetMode.afterVisit) {
        var clearZero = false;
        if (visit.zeroObservationConfirmed) {
          clearZero = await _confirmClearZero();
          if (!clearZero) {
            if (mounted) setState(() => _saving = false);
            return;
          }
        }
        final placed = _placed!;
        final sections = await ref
            .read(transectRepositoryProvider)
            .watchSections(visit.transectId)
            .first;
        final protocol = await ref
            .read(transectRepositoryProvider)
            .watchProtocol(visit.projectId)
            .first;
        id = await repository.createAfterVisit(
          visit: visit,
          observedAt: _observedAt,
          taxonId: taxon.id,
          count: _count,
          lat: placed.latitude,
          lon: placed.longitude,
          sectionId: sectionAt(placed, sections, protocol)?.id,
          recordedById: recordedById,
          clearZeroConfirmation: clearZero,
          photos: _drafts,
          details: _details,
        );
      } else if (visit == null) {
        // A placed point has no accuracy. Without one, the GPS fix is used.
        final placed = _placed;
        final position = placed == null ? await _fixForSave() : null;
        id = await repository.createFree(
          projectId: widget.projectId,
          source: _source,
          taxonId: taxon.id,
          count: _count,
          lat: placed?.latitude ?? position!.latitude,
          lon: placed?.longitude ?? position!.longitude,
          accuracyM: position?.accuracy,
          recordedById: recordedById,
          photos: _drafts,
          details: _details,
        );
      } else {
        var position = _liveFix(ref.read(trackingControllerProvider));
        String? sectionId;
        if (position != null) {
          sectionId = ref.read(currentSectionProvider(visit.id))?.id;
        } else {
          position = await ref.read(currentPositionProvider)();
          // The section of the fresh fix, not of the old position that the
          // tracker still holds.
          sectionId = sectionAt(
            LatLng(position.latitude, position.longitude),
            ref.read(transectSectionsProvider(visit.transectId)).value ?? [],
            ref.read(projectProtocolProvider(visit.projectId)).value,
          )?.id;
        }
        id = await repository.createQuick(
          visit: visit,
          taxonId: taxon.id,
          count: _count,
          lat: position.latitude,
          lon: position.longitude,
          accuracyM: position.accuracy,
          sectionId: sectionId,
          recordedById: recordedById,
          photos: _drafts,
          details: _details,
        );
      }
      _saved = true;
      ref
          .read(evalLoggerProvider)
          .log(
            evalObsSaved,
            entityId: id,
            durationMs: _openFor.elapsedMilliseconds,
            payload: {
              'sheet': _sheetId,
              'mode': _mode.name,
              'taps': _taps,
              'taxon_id': taxon.id,
              'count': _count,
            },
          );
      if (!mounted) return;
      Navigator.pop(context, (id: id, label: '${taxonTitle(taxon)} × $_count'));
    } on LocationException catch (error) {
      _fail(locationMessage(error.failure));
    } on StateError catch (error) {
      _fail(error.message);
    } catch (error) {
      _fail('Could not save: $error');
    }
  }

  /// Asks before a late butterfly removes the true-zero confirmation of the
  /// visit. True when the researcher agrees.
  Future<bool> _confirmClearZero() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove true-zero confirmation?'),
        content: const Text(
          'This visit was finished with no butterflies. Adding one removes '
          'the true-zero confirmation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// Picks the time of day for [_observedAt]. The date is the local date of
  /// the visit's start (the next day when the visit ran past midnight). A time
  /// outside the visit is refused and the old one stays.
  Future<void> _pickTime() async {
    final visit = widget.visit!;
    final start = visit.startedAt!.toLocal();
    final end = visit.endedAt!.toLocal();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_observedAt.toLocal()),
    );
    if (picked == null || !mounted) return;
    // The picker has no seconds, so the start is compared by the minute: a
    // visit that began at 21:19:40 allows 21:19.
    final startMinute = DateTime(
      start.year,
      start.month,
      start.day,
      start.hour,
      start.minute,
    );
    var chosen = DateTime(
      start.year,
      start.month,
      start.day,
      picked.hour,
      picked.minute,
    );
    // Before the start on the start's date: a visit across midnight.
    if (chosen.isBefore(startMinute)) {
      chosen = chosen.add(const Duration(days: 1));
    }
    if (chosen.isAfter(end)) {
      _showError(
        'Pick a time between ${formatLocalTime(start)} and '
        '${formatLocalTime(end)}.',
      );
      return;
    }
    // The picker has no seconds, so a pick in the start minute is 21:19:00 for
    // a visit that began at 21:19:40. Move it to the start, so it never lies
    // before the visit and does not depend on the protocol's tolerance.
    if (chosen.isBefore(start)) chosen = start;
    setState(() {
      _observedAt = chosen.toUtc();
      _error = null;
    });
  }

  /// Shows [message] in the sheet and lets the observer try again.
  void _fail(String message) {
    if (!mounted) return;
    setState(() => _saving = false);
    _showError(message);
  }

  /// Shows [message] in the sheet and logs it as an `error` event (T073).
  /// The same message as the last logged one is shown again but not logged
  /// twice.
  void _showError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    if (message == _lastLoggedError) return;
    _lastLoggedError = message;
    ref
        .read(evalLoggerProvider)
        .log(
          evalError,
          payload: {
            'screen': 'observation_sheet',
            'sheet': _sheetId,
            'message': message,
          },
        );
  }

  /// A tap is a pointer that goes up within [kTouchSlop] of where it went
  /// down, so a scroll does not count (T073).
  void _onPointerUp(PointerUpEvent event) {
    final down = _downAt.remove(event.pointer);
    if (down == null || (event.position - down).distance >= kTouchSlop) return;
    _taps++;
    ref.read(evalLoggerProvider).log(evalTap, payload: {'sheet': _sheetId});
  }

  /// Opens the map capture to place (or move) the point of a free observation.
  /// The project's transects are drawn as a guide. Closing it without saving
  /// keeps the point as it was.
  Future<void> _pickLocation() async {
    // Read once from the repository, not through the provider's `.value`: a
    // provider nobody listens to has no value (see `openStartVisit`).
    final transects = ref.read(transectRepositoryProvider);
    final visit = widget.visit;
    final lines = <List<LatLng>>[];
    if (visit != null && _mode == _SheetMode.afterVisit) {
      // The visit's transect, its sections and the walked route (T110).
      final transect = await transects.watchTransect(visit.transectId).first;
      final sections = await transects.watchSections(visit.transectId).first;
      final route = await ref
          .read(trackPointRepositoryProvider)
          .watchRoute(visit.id)
          .first;
      if (transect != null) lines.add(parseLineString(transect.geometry));
      for (final s in sections) {
        lines.add(parseLineString(s.section.geometry));
      }
      if (route.length >= 2) {
        lines.add([for (final p in route) LatLng(p.lat, p.lon)]);
      }
    } else {
      final all = await transects.watchTransects(widget.projectId).first;
      lines.addAll([for (final t in all) parseLineString(t.geometry)]);
    }
    if (!mounted) return;
    final placed = _placed;
    final shape = await showGeometryCapture(
      context,
      projectId: widget.projectId,
      modes: const {GeometryMode.point},
      initial: placed == null ? null : CapturedGeometry.point(placed),
      referenceLines: lines,
    );
    if (shape == null || !mounted) return;
    // The placed point is the way out of a GPS error, so the error goes.
    setState(() {
      _placed = shape.points.first;
      _error = null;
    });
  }

  /// What the location row says while the phone's own position is used: the
  /// fix once it is there, with its accuracy.
  String _gpsText() {
    final fix = _fix;
    if (fix != null) {
      return 'My position: ${fix.latitude.toStringAsFixed(5)}, '
          '${fix.longitude.toStringAsFixed(5)} (±${fix.accuracy.round()} m)';
    }
    if (_fixRequest != null) return 'Finding my position…';
    return 'My position, found on save';
  }

  /// The top of a free observation: the source picker and where the butterfly
  /// was seen.
  Widget _freeHeader() {
    final placed = _placed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _source,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Source'),
          items: [
            for (final source in freeObservationSources)
              DropdownMenuItem(
                value: source,
                child: Text(observationValueLabel(source)),
              ),
          ],
          onChanged: _saving
              ? null
              : (value) => setState(() => _source = value ?? _source),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.place_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                placed == null
                    ? _gpsText()
                    : 'Placed on map: ${placed.latitude.toStringAsFixed(5)}, '
                          '${placed.longitude.toStringAsFixed(5)}',
              ),
            ),
            TextButton(
              onPressed: _saving ? null : _pickLocation,
              child: Text(placed == null ? 'Place on map' : 'Move'),
            ),
            if (placed != null)
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                        _placed = null;
                        _startFix();
                      }),
                child: const Text('My position'),
              ),
          ],
        ),
      ],
    );
  }

  /// The top of an observation added after the visit (T110): the time it was
  /// seen and the place on the map. Both are the researcher's choice.
  Widget _afterVisitHeader() {
    final placed = _placed;
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.schedule),
            const SizedBox(width: 8),
            Expanded(child: Text('Seen at ${formatLocalTime(_observedAt)}')),
            TextButton(
              onPressed: _saving ? null : _pickTime,
              child: const Text('Change'),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.place_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                placed == null
                    ? 'Tap Place on map'
                    : 'Placed on map: ${placed.latitude.toStringAsFixed(5)}, '
                          '${placed.longitude.toStringAsFixed(5)}',
              ),
            ),
            TextButton(
              onPressed: _saving ? null : _pickLocation,
              child: Text(placed == null ? 'Place on map' : 'Move'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    // The current section is keyed by visit id, so a free observation has none.
    // After the visit no live fix is used, so nothing is watched.
    final live = _mode == _SheetMode.live;
    final fix = live ? _liveFix(ref.watch(trackingControllerProvider)) : null;
    // `live` means there is a visit, so `visit!` is safe here.
    final section = live ? ref.watch(currentSectionProvider(visit!.id)) : null;

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Read here, above the Scaffold: it uses up the keyboard inset for its body.
    final keyboardOpen = keyboardHeight > 0;
    // Keeps Save clear of the system navigation bar.
    final content = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _downAt[event.pointer] = event.position,
      onPointerCancel: (event) => _downAt.remove(event.pointer),
      onPointerUp: _onPointerUp,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: switch (_mode) {
                _SheetMode.afterVisit => _afterVisitHeader(),
                _SheetMode.free => _freeHeader(),
                _SheetMode.live => PositionLine(
                  fix: fix,
                  accuracyWarningM: widget.accuracyWarningM ?? 0,
                  sectionCode: fix == null ? null : section?.sectionCode,
                ),
              },
            ),
            Expanded(
              child: _detailsOpen
                  ? Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _detailsOpen = false),
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Back to species'),
                          ),
                        ),
                        Expanded(
                          child: ObservationDetailsForm(
                            details: _details,
                            onChanged: (details) =>
                                setState(() => _details = details),
                            photos: _photoSlot(),
                            hasPhoto: _drafts.isNotEmpty,
                            onPhotoNeeded: _askForPhoto,
                            projectId: widget.projectId,
                            visitId: visit?.id,
                            // A placed point may not be where the user stands.
                            showFacing:
                                _mode != _SheetMode.afterVisit &&
                                _placed == null,
                          ),
                        ),
                      ],
                    )
                  : TaxonPicker(
                      projectId: widget.projectId,
                      selectedId: _selected?.id,
                      onSelected: (taxon) {
                        // Closes the keyboard, which brings back Save.
                        FocusScope.of(context).unfocus();
                        setState(() => _selected = taxon);
                      },
                    ),
            ),
            // On the free screen the species search gets the room above the
            // keyboard: the count and Save come back when it closes.
            if (!_fullScreen || !keyboardOpen) ...[
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
                    // W01 only warns: Save works without a photo, because the
                    // butterfly may have flown off. The photo buttons are in
                    // the Details form, so the line offers to open it.
                    if ((_selected?.photoRequired ?? false) && _drafts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.photo_camera_outlined),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${ruleMessage('W01')}.')),
                            if (!_detailsOpen)
                              TextButton(
                                onPressed: () =>
                                    setState(() => _detailsOpen = true),
                                child: const Text('Add photo'),
                              ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            setState(() => _detailsOpen = !_detailsOpen),
                        icon: Icon(
                          _detailsOpen ? Icons.expand_more : Icons.expand_less,
                        ),
                        label: Text(_detailsOpen ? 'Hide details' : 'Details'),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selected == null
                                ? 'Pick a species'
                                : taxonTitle(_selected!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        CountStepper(
                          value: _count,
                          onChanged: (count) => setState(() => _count = count),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            _selected == null ||
                                _saving ||
                                (_mode == _SheetMode.afterVisit &&
                                    _placed == null)
                            ? null
                            : _save,
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
    );
    return PopScope(
      // Closing while Save waits for a fix would save it unseen.
      canPop: !_saving,
      child: _fullScreen
          ? Scaffold(
              appBar: AppBar(
                title: Text(
                  _mode == _SheetMode.afterVisit
                      ? 'Add to visit'
                      : 'Free observation',
                ),
              ),
              body: content,
            )
          : Padding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: SizedBox(
                height: screenHeight * 0.9 - keyboardHeight,
                child: content,
              ),
            ),
    );
  }
}
