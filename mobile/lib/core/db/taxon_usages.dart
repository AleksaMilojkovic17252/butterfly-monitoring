import 'package:drift/drift.dart';

/// Which taxa the observer starred and used lately in a project (T045). Local
/// only: favourites are per device and not synced, so there are no
/// `SyncColumns` and no foreign keys.
@DataClassName('TaxonUsage')
class TaxonUsages extends Table {
  TextColumn get projectId => text()();
  TextColumn get taxonId => text()();
  BoolColumn get isFavourite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  IntColumn get useCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {projectId, taxonId};

  @override
  String get tableName => "taxon_usage";
}
