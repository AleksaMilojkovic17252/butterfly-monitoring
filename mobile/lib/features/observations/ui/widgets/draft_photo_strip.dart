import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile/features/observations/domain/draft_photo.dart';

/// A row of small thumbnails of the photos taken in the quick butterfly sheet
/// and not saved yet (T050). Each has an ✕ that calls [onRemove]; the first one
/// has a star, because it becomes the primary photo.
class DraftPhotoStrip extends StatelessWidget {
  const DraftPhotoStrip({
    super.key,
    required this.drafts,
    required this.onRemove,
  });
  final List<DraftPhoto> drafts;
  final void Function(DraftPhoto draft) onRemove;

  static const _size = 72.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _size,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: drafts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final draft = drafts[index];
          return SizedBox(
            width: _size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(draft.path),
                    fit: BoxFit.cover,
                    // Decode a small copy: the file is up to 2048 px wide.
                    cacheWidth: 200,
                  ),
                ),
                if (index == 0)
                  const Positioned(
                    left: 4,
                    bottom: 4,
                    child: Icon(Icons.star, size: 18, color: Colors.amber),
                  ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () => onRemove(draft),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
