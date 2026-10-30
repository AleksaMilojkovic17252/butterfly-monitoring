/// A photo that has been taken, compressed and hashed but has no database row
/// yet (T050). The quick butterfly sheet holds drafts until Save writes them
/// with the observation; closing the sheet discards them.
class DraftPhoto {
  const DraftPhoto({
    required this.id,
    required this.path,
    required this.size,
    required this.sha256,
    required this.width,
    required this.height,
    required this.capturedAt,
  });

  /// The photo's UUID, which is also its file name.
  final String id;

  /// The compressed JPEG in `<app documents>/photos/`.
  final String path;

  /// Size of the file in bytes.
  final int size;

  /// Lower case hex SHA-256 of the file.
  final String sha256;
  final int width;
  final int height;

  /// UTC. For a photo from the gallery this is when it was picked.
  final DateTime capturedAt;
}
