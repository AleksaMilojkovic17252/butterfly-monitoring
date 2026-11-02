import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Asks for a photo when the confidence is `photo_required` and the
/// observation has none (T046): "This record needs a photo" with Take photo,
/// From gallery and Later. Returns the chosen source, or null for Later (or a
/// tap outside). Later never blocks a save, as for W01 (D-075).
Future<ImageSource?> showPhotoPromptDialog(BuildContext context) {
  return showDialog<ImageSource>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('This record needs a photo'),
      content: const Text(
        'The confidence is "Photo required". Add a photo now, or later from '
        'the observation.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ImageSource.gallery),
          child: const Text('From gallery'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ImageSource.camera),
          child: const Text('Take photo'),
        ),
      ],
    ),
  );
}
