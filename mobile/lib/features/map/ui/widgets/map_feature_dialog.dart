import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/ui/widgets/photo_preview_image.dart';

/// The popup of a feature tapped on the project map (T059): a dialog in the
/// middle of the screen with a title, a few "label: value" lines, a Close
/// button and an Open button for the feature's own screen. An observation with
/// a photo shows it at the top: the file on this phone, or the thumbnail from
/// the server (T107). The content scrolls if it does
/// not fit, so a small screen or a large font cannot overflow it.
class MapFeatureDialog extends StatelessWidget {
  const MapFeatureDialog({
    super.key,
    required this.title,
    required this.lines,
    required this.onOpen,
    this.photo,
  });
  final String title;

  /// (label, value) pairs, shown in this order.
  final List<(String, String)> lines;
  final VoidCallback onOpen;

  /// A photo to show above the title, or null.
  final Photo? photo;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PhotoPreviewImage(
                  photo: photo!,
                  width: double.infinity,
                  height: 180,
                  // Decoded at about the size it is shown at.
                  cacheWidth: 900,
                  borderRadius: 12,
                ),
              ),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final (label, value) in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$label: ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: value),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: onOpen, child: const Text('Open')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
