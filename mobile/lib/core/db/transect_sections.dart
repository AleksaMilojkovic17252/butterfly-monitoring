import 'package:drift/drift.dart';
import 'package:mobile/core/db/transects.dart';

/// Local copy of the server's `transect_section` table: one numbered stretch of
/// a transect. A read-only reference table written only by pull, so it has no
/// `syncStatus` column (D-042).
class TransectSections extends Table {
  TextColumn get id => text()();
  TextColumn get transectId => text().references(Transects, #id)();
  TextColumn get sectionCode => text()();
  IntColumn get sequenceNumber => integer()();
  TextColumn get notes => text()();
  TextColumn get habitatTypeId => text().nullable()();
  TextColumn get managementTypeId => text().nullable()();
  TextColumn get geometry => text()();

  @override
  Set<Column> get primaryKey => {id};

  IntColumn get serverVersion => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  String get tableName => "transect_section";
}
