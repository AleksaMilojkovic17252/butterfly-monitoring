import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/rule_messages.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/observations/domain/photo_parent.dart';
import 'package:mobile/features/observations/domain/photo_preview.dart';
import 'package:mobile/features/observations/ui/widgets/photo_preview_image.dart';
import 'package:mobile/features/observations/ui/widgets/photo_viewer.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';

/// The photos part of an observation's detail or a plant record's form (T050,
/// T052): thumbnails with a star on
/// the primary one, the W01 warning, and the buttons to add a photo. Tapping any
/// photo opens a full-screen viewer (T107) with Make primary and Delete in its
/// app bar; on a locked visit the viewer has no actions. Adding and changing
/// photos is allowed until the visit is locked; the buttons disappear when it
/// is.
class RecordPhotoSection extends ConsumerStatefulWidget {
  const RecordPhotoSection({
    super.key,
    required this.parent,
    required this.photoRequired,
    this.readOnly = false,
  });

  /// The observation or plant record the photos belong to.
  final PhotoParent parent;

  /// The species has `photo_required` (rule W01). Always false for a plant.
  final bool photoRequired;

  /// No adding or changing photos, as on a locked visit. A plant record made
  /// off a visit in a closed project is read-only (T099).
  final bool readOnly;

  @override
  ConsumerState<RecordPhotoSection> createState() => _RecordPhotoSectionState();
}

class _RecordPhotoSectionState extends ConsumerState<RecordPhotoSection> {
  /// True while a photo is being taken and saved.
  bool _busy = false;

  /// Takes or picks a photo and adds it to the record. A refusal (for
  /// example a locked visit) is shown in a snackbar.
  Future<void> _add(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final photos = ref.read(photoRepositoryProvider);
    setState(() => _busy = true);
    try {
      final draft = await photos.capture(source);
      if (draft == null) return;
      await photos.addToParent(widget.parent, draft);
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not add the photo: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens the viewer for [photo] and does what the user chose in it.
  Future<void> _tapPhoto(Photo photo, bool locked) async {
    final choice = await showPhotoViewer(context, photo, canEdit: !locked);
    if (!mounted) return;
    // A thumbnail that could not be fetched (offline, 404) tries again: the
    // connection or the upload may have come since.
    final key = photo.previewKey;
    if (ref.read(photoPreviewProvider(key)).value?.placeholder != null) {
      ref.invalidate(photoPreviewProvider(key));
    }
    await _applyChoice(photo, choice);
  }

  /// Does what the user chose for [photo]: Make primary, or Delete after a
  /// confirmation.
  Future<void> _applyChoice(Photo photo, String? choice) async {
    if (!mounted || choice == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final photos = ref.read(photoRepositoryProvider);
    try {
      if (choice == 'primary') {
        await photos.makePrimary(photo);
      } else if (choice == 'delete' && await _confirmDelete()) {
        await photos.delete(photo);
      }
    } on StateError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<bool> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this photo?'),
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
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final parent = widget.parent;
    final photos = ref.watch(photosProvider(parent.id)).value ?? [];

    // Watched, so the buttons go away if a pull locks the visit. A record
    // without a visit is never locked.
    final visitId = parent.surveyVisitId;
    final visit = visitId == null
        ? null
        : ref.watch(visitProvider(visitId)).value;
    final locked =
        widget.readOnly || (visit != null && visitIsLocked(visit.status));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photos.isEmpty && !widget.photoRequired)
              const Text('No photos'),
            if (photos.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final photo in photos)
                    _PhotoTile(
                      photo: photo,
                      onTap: () => _tapPhoto(photo, locked),
                    ),
                ],
              ),
            // W01 only warns; the record waits for validation.
            if (photos.isEmpty && widget.photoRequired)
              Row(
                children: [
                  const Icon(Icons.photo_camera_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${ruleMessage('W01')}.')),
                ],
              ),
            if (!locked) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _add(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _add(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('From gallery'),
                  ),
                  if (_busy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One thumbnail with its upload state underneath. A photo whose file is not
/// on this phone (taken on another one) shows the thumbnail fetched from the
/// server, or a sentence (T107).
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onTap});
  final Photo photo;
  final VoidCallback onTap;

  static const _size = 96.0;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: _size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _size,
              height: _size,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoPreviewImage(
                    photo: photo,
                    width: _size,
                    height: _size,
                    cacheWidth: 300,
                    borderRadius: 8,
                  ),
                  if (photo.isPrimary)
                    const Positioned(
                      left: 4,
                      top: 4,
                      child: Icon(Icons.star, size: 20, color: Colors.amber),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            if (photo.uploadStatus != 'uploaded' && photo.uploadError != null)
              Text(
                'upload failed',
                style: textStyle?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            else
              Text(
                photo.uploadStatus == 'uploaded'
                    ? 'uploaded'
                    : 'waiting to upload',
                style: textStyle,
              ),
          ],
        ),
      ),
    );
  }
}
