import 'package:drift/drift.dart';

/// Local copy of the server's `plant_taxon` table: plants for host and nectar
/// records. A read-only reference table written only by pull, so it has no
/// `syncStatus` column (D-042).
@DataClassName("PlantTaxon")
class PlantTaxa extends Table {
  TextColumn get id => text()();
  TextColumn get scientificName => text()();
  TextColumn get family => text()();
  TextColumn get vernacularName => text()();
  TextColumn get vernacularNameEn => text()();
  TextColumn get taxonSource => text()();
  TextColumn get taxonSourceId => text()();
  BoolColumn get active => boolean()();
  @override
  Set<Column> get primaryKey => {id};

  IntColumn get serverVersion => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  String get tableName => "plant_taxon";
}
