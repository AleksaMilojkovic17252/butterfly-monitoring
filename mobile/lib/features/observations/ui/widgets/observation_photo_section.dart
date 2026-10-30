import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/rule_messages.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';

/// The photos part of the observation detail (T050): thumbnails with a star on
/// the primary one, the W01 warning, and the buttons to add a photo. Tapping a
/// thumbnail offers Make primary and Delete. Adding and changing photos is
/// allowed until the visit is locked; the buttons disappear when it is.
class ObservationPhotoSection extends ConsumerStatefulWidget {
  const ObservationPhotoSection({
    super.key,
    required this.observation,
    required this.photoRequired,
  });
  final ButterflyObservation observation;

  /// The species has `photo_required` (rule W01).
  final bool photoRequired;

  @override
  ConsumerState<ObservationPhotoSection> createState() =>
      _ObservationPhotoSectionState();
}

class _ObservationPhotoSectionState
    extends ConsumerState<ObservationPhotoSection> {
  /// True while a photo is being taken and saved.
  bool _busy = false;

  /// Takes or picks a photo and adds it to the observation. A refusal (for
  /// example a locked visit) is shown in a snackbar.
  Future<void> _add(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final photos = ref.read(photoRepositoryProvider);
    setState(() => _busy = true);
    try {
      final draft = await photos.capture(source);
      if (draft == null) return;
      await photos.addToObservation(widget.observation, draft);
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

  /// The choices for one photo, in a bottom sheet.
  Future<void> _openPhoto(Photo photo) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!photo.isPrimary)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Make primary'),
                onTap: () => Navigator.pop(context, 'primary'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
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
    final o = widget.observation;
    final photos = ref.watch(photosProvider(o.id)).value ?? [];

    // Watched, so the buttons go away if a pull locks the visit. An
    // observation without a visit is never locked.
    final visitId = o.surveyVisitId;
    final visit = visitId == null
        ? null
        : ref.watch(visitProvider(visitId)).value;
    final locked = visit != null && visitIsLocked(visit.status);

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
                      onTap: locked ? null : () => _openPhoto(photo),
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
                spacing: 8,
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
/// on this phone (taken on another one) shows a placeholder; T107 will fetch
/// those from the server.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onTap});
  final Photo photo;
  final VoidCallback? onTap;

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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(photo.localPath),
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          'Photo not on this phone',
                          textAlign: TextAlign.center,
                          style: textStyle,
                        ),
                      ),
                    ),
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
