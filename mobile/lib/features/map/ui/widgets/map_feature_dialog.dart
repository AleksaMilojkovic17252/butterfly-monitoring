import 'dart:io';

import 'package:flutter/material.dart';

/// The popup of a feature tapped on the project map (T059): a dialog in the
/// middle of the screen with a title, a few "label: value" lines, a Close
/// button and an Open button for the feature's own screen. An observation with
/// a photo on this phone shows it at the top. The content scrolls if it does
/// not fit, so a small screen or a large font cannot overflow it.
class MapFeatureDialog extends StatelessWidget {
  const MapFeatureDialog({
    super.key,
    required this.title,
    required this.lines,
    required this.onOpen,
    this.photoPath,
  });
  final String title;

  /// (label, value) pairs, shown in this order.
  final List<(String, String)> lines;
  final VoidCallback onOpen;

  /// The file of a photo to show above the title, or null.
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photoPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(photoPath!),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    // Decoded at about the size it is shown at.
                    cacheWidth: 900,
                    // A photo pulled from another phone has no file here
                    // (T107 will fetch those): show nothing.
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
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
