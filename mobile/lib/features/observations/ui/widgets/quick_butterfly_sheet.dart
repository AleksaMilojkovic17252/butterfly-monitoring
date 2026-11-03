import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/location/location_message.dart';
import 'package:mobile/core/location/location_provider.dart';
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
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/visits/domain/current_section.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';

/// What the sheet hands back after a save: the new observation's id (for
/// Undo) and the text for the "Saved" message.
typedef SavedObservation = ({String id, String label});

/// The quick butterfly entry (T045): pick a species, set the count, Save.
/// Position, time and section fill in by themselves. The Details button swaps
/// the species list for the optional details (T046): sex, behaviour, photos
/// and so on. Opened from Add butterfly on the active visit screen with [show].
class QuickButterflySheet extends ConsumerStatefulWidget {
  const QuickButterflySheet({
    super.key,
    required this.visit,
    required this.accuracyWarningM,
  });
  final SurveyVisit visit;

  /// Accuracy in metres above which the position gets a warning.
  final double accuracyWarningM;

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
      builder: (context) =>
          QuickButterflySheet(visit: visit, accuracyWarningM: accuracyWarningM),
    );
  }

  @override
  ConsumerState<QuickButterflySheet> createState() =>
      _QuickButterflySheetState();
}

class _QuickButterflySheetState extends ConsumerState<QuickButterflySheet> {
  Taxon? _selected;

  /// The optional details; the defaults are what a quick entry leaves.
  var _details = const ObservationDetails();

  /// True while the Details form replaces the species list.
  bool _detailsOpen = false;

  /// Starts at 1 each time the sheet opens.
  int _count = 1;

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

  @override
  void initState() {
    super.initState();
    _photos = ref.read(photoRepositoryProvider);
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
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not add the photo: $error');
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

  /// The newest fix when GPS is running for this visit, otherwise null. A
  /// paused visit has a fix too, but an old one.
  Position? _liveFix(TrackingState tracking) {
    final live =
        tracking.visitId == widget.visit.id &&
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
      setState(() => _error = 'You are signed out.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final visit = widget.visit;
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
      final id = await ref
          .read(observationRepositoryProvider)
          .createQuick(
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
      _saved = true;
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

  /// Shows [message] in the sheet and lets the observer try again.
  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingControllerProvider);
    final fix = _liveFix(tracking);
    final section = ref.watch(currentSectionProvider(widget.visit.id));

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return PopScope(
      // Closing while Save waits for a fix would save it unseen.
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: SizedBox(
          height: screenHeight * 0.9 - keyboardHeight,
          // Keeps Save clear of the system navigation bar.
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: PositionLine(
                    fix: fix,
                    accuracyWarningM: widget.accuracyWarningM,
                    sectionCode: fix == null ? null : section?.sectionCode,
                  ),
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
                                projectId: widget.visit.projectId,
                                visitId: widget.visit.id,
                                showFacing: true,
                              ),
                            ),
                          ],
                        )
                      : TaxonPicker(
                          projectId: widget.visit.projectId,
                          selectedId: _selected?.id,
                          onSelected: (taxon) =>
                              setState(() => _selected = taxon),
                        ),
                ),
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
                      if ((_selected?.photoRequired ?? false) &&
                          _drafts.isEmpty)
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
                            _detailsOpen
                                ? Icons.expand_more
                                : Icons.expand_less,
                          ),
                          label: Text(
                            _detailsOpen ? 'Hide details' : 'Details',
                          ),
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
                            onChanged: (count) =>
                                setState(() => _count = count),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _selected == null || _saving
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
            ),
          ),
        ),
      ),
    );
  }
}
