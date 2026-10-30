import 'package:drift/drift.dart';
import 'package:mobile/core/db/sync_columns.dart';

/// Local copy of the server's `photo` table (T050): the metadata of one photo
/// and where its file is on this phone. The bytes are uploaded after push
/// (`PhotoUploader`); `uploadStatus` says whether that has happened.
///
/// Differences from the server:
/// - `localPath` is the real file on this phone
///   (`<app documents>/photos/<id>.jpg`). A row pulled from another phone has
///   a path with no file behind it;
/// - no `storage_key` and no `metadata_json`: the server owns them;
/// - `uploadError` exists only here.
class Photos extends Table with SyncColumns {
  TextColumn get id => text()();

  /// The observation this photo belongs to. No foreign key, so T051 can add a
  /// plant record as the other possible parent.
  TextColumn get observationId => text().nullable()();
  TextColumn get localPath => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSize => integer()();

  /// Lower case hex SHA-256 of the file; the server uses it to store equal
  /// files once.
  TextColumn get sha256 => text()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  DateTimeColumn get capturedAt => dateTime()();

  /// `pending` or `uploaded` (the server also has `failed`).
  TextColumn get uploadStatus =>
      text().withDefault(const Constant('pending'))();
  DateTimeColumn get uploadedAt => dateTime().nullable()();

  /// Local only. Set when the server refused the upload for good (a 4xx such
  /// as 422 "does not match the record"); the uploader then leaves the photo
  /// alone until the user taps Retry. It holds the server's error as the JSON
  /// text `[{code, detail, fields}]`, so `syncErrorMessage` can read it. Null
  /// while the photo waits, uploads, or failed only for a passing reason.
  TextColumn get uploadError => text().nullable()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  /// Same as the entity type, so the pull applier and `SyncRepository` find
  /// the table by it.
  @override
  String get tableName => 'photo';
}
