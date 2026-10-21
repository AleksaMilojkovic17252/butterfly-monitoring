import 'package:drift/drift.dart';

/// Local copy of the server's `habitat_type` code list. A read-only reference
/// table written only by pull, so it has no `syncStatus` column (D-042).
class HabitatTypes extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get nameEn => text()();
  TextColumn get nameSr => text()();
  TextColumn get description => text()();
  IntColumn get sortOrder => integer()();
  BoolColumn get active => boolean()();
  TextColumn get eunisCode => text()();

  @override
  Set<Column> get primaryKey => {id};

  IntColumn get serverVersion => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  String get tableName => "habitat_type";
}
