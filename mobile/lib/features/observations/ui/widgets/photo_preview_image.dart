import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/observations/domain/photo_preview.dart';

/// One photo as a picture (T107): the photo's own file, the thumbnail fetched
/// from the server, or a box with a sentence when there is neither. While the
/// answer is coming it shows a small spinner. Used by the observation photo
/// section and the map popup.
class PhotoPreviewImage extends ConsumerWidget {
  const PhotoPreviewImage({
    super.key,
    required this.photo,
    required this.width,
    required this.height,
    required this.cacheWidth,
    required this.borderRadius,
  });
  final Photo photo;
  final double width;
  final double height;

  /// The width the image is decoded at, about the size it is shown at.
  final int cacheWidth;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(photoPreviewProvider(photo.previewKey));
    final Widget child;
    if (preview.value == null) {
      // Still loading. (The provider never throws, so there is no error case.)
      child = _box(context, const CircularProgressIndicator(strokeWidth: 2));
    } else if (preview.value!.path != null) {
      final isOnPhone = preview.value!.isOnPhone;
      child = Image.file(
        File(preview.value!.path!),
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        // A file that cannot be read. A damaged cached thumbnail is deleted,
        // so the next time the photo is shown it is fetched again.
        errorBuilder: (context, error, stackTrace) {
          if (!isOnPhone) {
            ref.read(photoRepositoryProvider).deleteCachedThumbnail(photo.id);
          }
          return _box(context, _sentence(context, 'Photo is on the server'));
        },
      );
    } else {
      child = _box(context, _sentence(context, preview.value!.placeholder!));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }

  /// A grey box of the picture's size with [content] in the middle.
  Widget _box(BuildContext context, Widget content) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainer,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: content,
    );
  }

  Widget _sentence(BuildContext context, String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
