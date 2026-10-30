import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:mobile/core/validation/rule_messages.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/observations/data/taxon_repository.dart';
import 'package:mobile/features/observations/domain/draft_photo.dart';
import 'package:mobile/features/observations/domain/taxon_search.dart';
import 'package:mobile/features/observations/ui/widgets/count_stepper.dart';
import 'package:mobile/features/observations/ui/widgets/draft_photo_strip.dart';
import 'package:mobile/features/observations/ui/widgets/position_line.dart';
import 'package:mobile/features/observations/ui/widgets/sheet_list_title.dart';
import 'package:mobile/features/observations/ui/widgets/taxon_tile.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/visits/domain/current_section.dart';
import 'package:mobile/features/visits/domain/tracking_controller.dart';

/// What the sheet hands back after a save: the new observation's id (for
/// Undo) and the text for the "Saved" message.
typedef SavedObservation = ({String id, String label});

/// The quick butterfly entry (T045): pick a species, set the count, Save.
/// Position, time, section and confidence fill in by themselves. Opened from
/// Add butterfly on the active visit screen with [show].
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
  final _search = TextEditingController();
  Taxon? _selected;

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
    _search.dispose();
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
          );
      _saved = true;
      if (!mounted) return;
      Navigator.pop(context, (id: id, label: '${taxonTitle(taxon)} × $_count'));
    } on LocationException catch (error) {
      _fail(_locationMessage(error.failure));
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
    final taxa = ref.watch(pickerTaxaProvider).value ?? [];
    final usage =
        ref.watch(taxonUsageProvider(widget.visit.projectId)).value ?? [];
    final tracking = ref.watch(trackingControllerProvider);
    final fix = _liveFix(tracking);
    final section = ref.watch(currentSectionProvider(widget.visit.id));
    final repository = ref.read(taxonRepositoryProvider);
    final favouriteIds = {
      for (final u in usage)
        if (u.isFavourite) u.taxonId,
    };

    final query = _search.text;
    final results = searchTaxa(taxa, query);

    Widget tile(Taxon taxon) => TaxonTile(
      taxon: taxon,
      selected: taxon.id == _selected?.id,
      favourite: favouriteIds.contains(taxon.id),
      onTap: () => setState(() => _selected = taxon),
      onToggleFavourite: () =>
          repository.toggleFavourite(widget.visit.projectId, taxon.id),
    );

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search a species',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(_search.clear),
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: query.trim().isEmpty
                        ? [
                            const SheetListTitle('Recent'),
                            ..._tilesOrHint(
                              recentTaxa(taxa, usage),
                              'Species you save show up here.',
                              tile,
                            ),
                            const SheetListTitle('Favourites'),
                            ..._tilesOrHint(
                              favouriteTaxa(taxa, usage),
                              'Tap a star to keep a species here.',
                              tile,
                            ),
                          ]
                        : _tilesOrHint(
                            results,
                            'No species matches "${query.trim()}".',
                            tile,
                          ),
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
                      // butterfly may have flown off. TODO(T046): show the
                      // W03/W04 prompts in the extended entry.
                      if ((_selected?.photoRequired ?? false) &&
                          _drafts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.photo_camera_outlined),
                              const SizedBox(width: 8),
                              Expanded(child: Text('${ruleMessage('W01')}.')),
                            ],
                          ),
                        ),
                      if (_drafts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: DraftPhotoStrip(
                            drafts: _drafts,
                            onRemove: _saving ? (_) {} : _removePhoto,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ],
                          ],
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

  /// A tile for each of [taxa], or the [hint] when there are none.
  List<Widget> _tilesOrHint(
    List<Taxon> taxa,
    String hint,
    Widget Function(Taxon) tile,
  ) {
    if (taxa.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(hint),
        ),
      ];
    }
    return [for (final taxon in taxa) tile(taxon)];
  }

  static String _locationMessage(LocationFailure failure) => switch (failure) {
    LocationFailure.serviceOff => 'Location is off. Turn it on in Android.',
    LocationFailure.denied => 'Location permission was not given.',
    LocationFailure.deniedForever =>
      'Location permission is blocked. Allow it in Android settings.',
    LocationFailure.unavailable => 'No GPS fix yet. Try again outside.',
  };
}
