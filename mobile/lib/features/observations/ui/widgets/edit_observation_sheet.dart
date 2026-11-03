import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/observations/data/taxon_repository.dart';
import 'package:mobile/features/observations/domain/observation_details.dart';
import 'package:mobile/features/observations/domain/taxon_search.dart';
import 'package:mobile/features/observations/ui/widgets/count_stepper.dart';
import 'package:mobile/features/observations/ui/widgets/observation_details_form.dart';
import 'package:mobile/features/observations/domain/photo_parent.dart';
import 'package:mobile/features/observations/ui/widgets/record_photo_section.dart';
import 'package:mobile/features/observations/ui/widgets/photo_prompt_dialog.dart';
import 'package:mobile/features/observations/ui/widgets/taxon_picker.dart';
import 'package:mobile/features/visits/domain/local_time.dart';

/// Edits a saved observation (T046): its details, count and species. Position,
/// time, section and source stay as they were. Opened from the Edit button of
/// the observation detail with [show].
///
/// Photos are saved right away, as in the detail; Cancel does not undo them.
class EditObservationSheet extends ConsumerStatefulWidget {
  const EditObservationSheet({super.key, required this.observation});
  final ButterflyObservation observation;

  /// Opens the sheet and returns true when the changes were saved (or there
  /// were none to save), null when it was closed without saving.
  static Future<bool?> show(
    BuildContext context, {
    required ButterflyObservation observation,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EditObservationSheet(observation: observation),
    );
  }

  @override
  ConsumerState<EditObservationSheet> createState() =>
      _EditObservationSheetState();
}

class _EditObservationSheetState extends ConsumerState<EditObservationSheet> {
  /// The row as it was when the sheet opened. The changes are worked out
  /// against it, so live rebuilds of the detail do not touch it.
  late final ButterflyObservation _opened = widget.observation;

  late var _details = ObservationDetails.fromObservation(_opened);
  late int _count = _opened.count;

  /// The species picked in this sheet, or null while the stored one stays.
  Taxon? _picked;

  /// True while the species list replaces the form.
  bool _changingSpecies = false;

  bool _saving = false;

  /// True while a photo is being taken, shrunk and saved.
  bool _capturing = false;
  String? _error;

  String get _taxonId => _picked?.id ?? _opened.taxonId;

  /// The observation as the owner of its photos.
  PhotoParent get _parent => PhotoParent.observation(
    id: _opened.id,
    projectId: _opened.projectId,
    surveyVisitId: _opened.surveyVisitId,
  );

  /// Takes or picks a photo and adds it to the observation right away. A
  /// refusal (for example a locked visit) is shown in the sheet.
  Future<void> _addPhoto(ImageSource source) async {
    final photos = ref.read(photoRepositoryProvider);
    setState(() {
      _capturing = true;
      _error = null;
    });
    try {
      final draft = await photos.capture(source);
      if (draft == null) return;
      await photos.addToParent(_parent, draft);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not add the photo: $error');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  /// The confidence became `photo_required` and there is no photo: ask for one.
  Future<void> _askForPhoto() async {
    final source = await showPhotoPromptDialog(context);
    if (source != null) await _addPhoto(source);
  }

  /// Saves the changes and closes the sheet; a refusal stays in the sheet.
  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(observationRepositoryProvider)
          .updateObservation(
            opened: _opened,
            taxonId: _taxonId,
            count: _count,
            details: _details,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
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

  /// The photos slot of the form: a line about saving, then the detail's
  /// photo section (thumbnails, W01 and the buttons).
  Widget _photoSlot(bool photoRequired) {
    return Column(
      // Stretch, or the photo card shrinks to the width of its buttons.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Photos are saved right away',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        RecordPhotoSection(parent: _parent, photoRequired: photoRequired),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // By id, so a retired species still shows its name.
    final stored = ref.watch(taxaByIdsProvider(_opened.taxonId)).value;
    final taxon = _picked ?? stored?.firstOrNull;
    final photoCount = ref.watch(photosProvider(_opened.id)).value?.length ?? 0;
    final textTheme = Theme.of(context).textTheme;

    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: SizedBox(
          height: screenHeight * 0.9 - keyboardHeight,
          child: SafeArea(
            top: false,
            child: Column(
              // Stretch, so the header text starts at the left edge.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit observation', style: textTheme.titleLarge),
                      Text(
                        '${formatLocalDateTime(_opened.observedAt)} · '
                        '${_opened.lat.toStringAsFixed(5)}, '
                        '${_opened.lon.toStringAsFixed(5)}',
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _changingSpecies
                      ? TaxonPicker(
                          projectId: _opened.projectId,
                          selectedId: _taxonId,
                          onSelected: (picked) => setState(() {
                            _picked = picked;
                            _changingSpecies = false;
                          }),
                        )
                      : Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.swap_horiz),
                              title: const Text('Change species'),
                              onTap: () =>
                                  setState(() => _changingSpecies = true),
                            ),
                            Expanded(
                              child: ObservationDetailsForm(
                                details: _details,
                                onChanged: (details) =>
                                    setState(() => _details = details),
                                photos: _photoSlot(
                                  taxon?.photoRequired ?? false,
                                ),
                                hasPhoto: photoCount > 0,
                                onPhotoNeeded: _askForPhoto,
                                projectId: _opened.projectId,
                                visitId: _opened.surveyVisitId,
                              ),
                            ),
                          ],
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
                      if (_capturing)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: LinearProgressIndicator(),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              taxon == null ? '…' : taxonTitle(taxon),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium,
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
                          onPressed: _saving ? null : _save,
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
