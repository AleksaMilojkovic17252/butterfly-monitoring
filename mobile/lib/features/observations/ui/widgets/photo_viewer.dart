import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/observations/domain/photo_preview.dart';

/// Opens the full-screen viewer for a photo (T107) and returns what the user
/// chose in its app bar: `'primary'`, `'delete'`, or null when it was just
/// closed. With [canEdit] false (the visit is locked) the app bar has no
/// actions.
///
/// A photo on this phone shows its own file. A photo from another phone shows
/// the full image from the server, fetched when the viewer opens and not kept.
Future<String?> showPhotoViewer(
  BuildContext context,
  Photo photo, {
  required bool canEdit,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: _PhotoViewer(photo: photo, canEdit: canEdit),
    ),
  );
}

/// The content of the dialog: an app bar and the picture.
class _PhotoViewer extends ConsumerWidget {
  const _PhotoViewer({required this.photo, required this.canEdit});
  final Photo photo;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
        // The actions show in every state (loading, image, no image), so a
        // photo that cannot be fetched can still be deleted or made primary.
        actions: [
          if (canEdit && !photo.isPrimary)
            IconButton(
              icon: const Icon(Icons.star_outline),
              tooltip: 'Make primary',
              onPressed: () => Navigator.pop(context, 'primary'),
            ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => Navigator.pop(context, 'delete'),
            ),
        ],
      ),
      body: _body(context, ref),
    );
  }

  /// The picture, or a spinner or a sentence in its place.
  Widget _body(BuildContext context, WidgetRef ref) {
    // The preview says where the photo is. It is already loaded by the tile
    // that opened the viewer, so this is normally immediate.
    final preview = ref.watch(photoPreviewProvider(photo.previewKey)).value;
    if (preview == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (preview.isOnPhone) {
      return _zoomable(FileImage(File(preview.path!)));
    }

    // Not on this phone: the full image from the server. Watched only here,
    // so a photo on this phone makes no request.
    final image = ref.watch(photoFullImageProvider(photo.previewKey)).value;
    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final bytes = image.bytes;
    if (bytes == null) return Center(child: Text(image.unavailable!));
    return _zoomable(MemoryImage(bytes));
  }

  /// Pinch to zoom: [_ZoomableImage] with the photo's size in pixels, which is
  /// null when the row has none.
  Widget _zoomable(ImageProvider picture) {
    final width = photo.width;
    final height = photo.height;
    final hasSize = width != null && height != null && width > 0 && height > 0;
    return _ZoomableImage(
      image: picture,
      pixelSize: hasSize ? Size(width.toDouble(), height.toDouble()) : null,
    );
  }
}

/// A picture that can be zoomed and moved like in the phone's gallery: it
/// starts fitted to the screen (all of it visible, centred), and zoomed in you
/// can move it only until its own edge meets the screen's edge, so the empty
/// bars around it never slide into view.
///
/// [InteractiveViewer] cannot do this alone. Its own limit is a rectangle: the
/// screen (the bars can be moved into view) or the picture (it is enlarged to
/// cover the screen and pinned to the top-left). So its limit is turned off
/// (`boundaryMargin` infinite) and [_keepInside] sets the position after every
/// change, including the end of a fling.
class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.image, required this.pixelSize});
  final ImageProvider image;

  /// The picture's size in pixels, or null when it is not known: the limit is
  /// then the whole screen.
  final Size? pixelSize;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final _controller = TransformationController();

  /// The space the viewer has, and the size the picture takes inside it at
  /// zoom 1 (fitted, centred). Both are set in `build`.
  Size _viewport = Size.zero;
  Size _picture = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_keepInside);
  }

  @override
  void dispose() {
    _controller.removeListener(_keepInside);
    _controller.dispose();
    super.dispose();
  }

  /// Moves the picture back inside its limits when a gesture or a fling pushed
  /// it out. Setting the value calls this again, which then changes nothing.
  void _keepInside() {
    final matrix = _controller.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();
    final x = _clampAxis(translation.x, scale, _viewport.width, _picture.width);
    final y = _clampAxis(
      translation.y,
      scale,
      _viewport.height,
      _picture.height,
    );
    // A tolerance, so rounding cannot make this set the value forever.
    if ((x - translation.x).abs() < 0.01 && (y - translation.y).abs() < 0.01) {
      return;
    }
    _controller.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(x, y, 0);
  }

  /// The position on one axis: the picture centred while it is still smaller
  /// than the screen, otherwise [translation] kept between the two places
  /// where the picture's edges meet the screen's edges.
  double _clampAxis(
    double translation,
    double scale,
    double viewport,
    double picture,
  ) {
    if (scale * picture <= viewport) return viewport / 2 * (1 - scale);
    final startEdgeAtScreenStart = -scale * (viewport - picture) / 2;
    final endEdgeAtScreenEnd = viewport - scale * (viewport + picture) / 2;
    return clampDouble(translation, endEdgeAtScreenEnd, startEdgeAtScreenStart);
  }

  /// The size of [pixels] fitted into [box] (the whole picture visible).
  Size _fit(Size pixels, Size box) {
    final scale = pixels.aspectRatio > box.aspectRatio
        ? box.width / pixels.width
        : box.height / pixels.height;
    return Size(pixels.width * scale, pixels.height * scale);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
        final pixels = widget.pixelSize;
        _picture = pixels == null ? _viewport : _fit(pixels, _viewport);
        return InteractiveViewer(
          transformationController: _controller,
          // No limit of its own: see the class comment.
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 1,
          maxScale: 5,
          child: SizedBox(
            width: _viewport.width,
            height: _viewport.height,
            child: Image(
              image: widget.image,
              fit: BoxFit.contain,
              // A file or body that is not an image shows a sentence.
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Text('Photo is on the server')),
            ),
          ),
        );
      },
    );
  }
}
