import 'package:drift/drift.dart';

/// Local copy of the server's `taxon` table: a butterfly taxon as it stood in
/// one list release. A read-only reference table written only by pull, so it
/// has no `syncStatus` column (D-042). `rank` is the server's text value.
@DataClassName('Taxon')
class Taxa extends Table {
  TextColumn get id => text()();
  TextColumn get author => text()();
  TextColumn get rank => text()();
  TextColumn get genus => text()();
  TextColumn get family => text()();
  TextColumn get vernacularNameSr => text()();
  TextColumn get vernacularNameEn => text()();
  TextColumn get taxonSource => text()();
  TextColumn get taxonSourceId => text()();
  BoolColumn get active => boolean()();
  BoolColumn get photoRequired => boolean()();
  TextColumn get identificationNotes => text().nullable()();
  TextColumn get acceptedNameId => text().nullable()();
  TextColumn get introducedInId => text()();
  TextColumn get retiredInId => text().nullable()();
  TextColumn get scientificName => text()();
  @override
  Set<Column> get primaryKey => {id};

  IntColumn get serverVersion => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  String get tableName => "taxon";
}
