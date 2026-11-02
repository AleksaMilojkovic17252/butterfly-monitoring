import 'dart:typed_data';

import 'package:mobile/core/db/app_database.dart';

/// What to show for a photo row (T107): the photo's own file, a thumbnail
/// fetched from the server earlier, or a sentence saying why there is no
/// picture. Made by `PhotoRepository.preview`.
class PhotoPreview {
  /// The photo's own file is on this phone.
  const PhotoPreview.onPhone(String this.path)
    : isOnPhone = true,
      placeholder = null;

  /// The server's thumbnail, kept in the photo cache folder.
  const PhotoPreview.cached(String this.path)
    : isOnPhone = false,
      placeholder = null;

  /// No picture: [placeholder] says why.
  const PhotoPreview.missing(String this.placeholder)
    : isOnPhone = false,
      path = null;

  /// The file to show, or null when [placeholder] is set.
  final String? path;

  /// The sentence to show instead of a picture, or null when [path] is set.
  final String? placeholder;

  /// True when the photo's own file is here. Only then the photo can be
  /// handled as before (Make primary / Delete sheet); a photo from another
  /// phone opens the full-screen viewer.
  final bool isOnPhone;
}

/// The full image of a photo from another phone, for the viewer (T107): the
/// [bytes], or the sentence in [unavailable] when they could not be fetched.
/// Exactly one of the two is set.
typedef FullImage = ({Uint8List? bytes, String? unavailable});

/// What decides how a photo is shown: its id, the path of its own file and
/// whether the server has the file. It is the key of the preview providers
/// instead of the whole `Photo` row, so a change that does not matter here
/// (Make primary, `updatedAt`, an upload error) does not load the picture
/// again. `pending` to `uploaded` does, which is wanted: a thumbnail that was
/// "Not uploaded yet" can now be fetched.
typedef PhotoPreviewKey = ({String id, String localPath, String uploadStatus});

extension PhotoPreviewKeyOf on Photo {
  /// The key of the preview providers for this row.
  PhotoPreviewKey get previewKey =>
      (id: id, localPath: localPath, uploadStatus: uploadStatus);
}
