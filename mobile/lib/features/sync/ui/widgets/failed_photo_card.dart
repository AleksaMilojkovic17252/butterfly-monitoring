import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/sync/domain/sync_error_message.dart';

/// One photo the server refused to take (T050), with the reason and the two
/// ways out: try again, or delete the photo.
class FailedPhotoCard extends StatelessWidget {
  const FailedPhotoCard({
    super.key,
    required this.photo,
    required this.busy,
    required this.onRetry,
    required this.onDelete,
  });
  final Photo photo;

  /// A sync is running: the buttons wait.
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Image.file(
                      File(photo.localPath),
                      fit: BoxFit.cover,
                      cacheWidth: 200,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photo could not be uploaded',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(syncErrorMessage(photo.uploadError)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy ? null : onDelete,
                  child: const Text('Delete photo'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: busy ? null : onRetry,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
