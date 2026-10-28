import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';

/// Reads the taxon list for the species picker and keeps the local
/// favourites and recent use (T045). Favourites are per device and never
/// synced, so this writes `taxon_usage` directly.
class TaxonRepository {
  TaxonRepository(this._db);
  final AppDatabase _db;

  /// Live list of the taxa an observer may pick: current (not retired), not
  /// deleted, ordered by scientific name.
  Stream<List<Taxon>> watchPickerTaxa() {
    final query = _db.select(_db.taxa)
      ..where(
        (t) =>
            t.active.equals(true) &
            t.retiredInId.isNull() &
            t.deletedAt.isNull(),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.scientificName)]);
    return query.watch();
  }

  /// Live favourites and recent use of the project's taxa.
  Stream<List<TaxonUsage>> watchUsage(String projectId) {
    final query = _db.select(_db.taxonUsages)
      ..where((u) => u.projectId.equals(projectId));
    return query.watch();
  }

  /// Stars the taxon in the project, or removes the star.
  Future<void> toggleFavourite(String projectId, String taxonId) {
    return _db.transaction(() async {
      final current = await _usageRow(projectId, taxonId);
      await _db
          .into(_db.taxonUsages)
          .insertOnConflictUpdate(
            TaxonUsagesCompanion.insert(
              projectId: projectId,
              taxonId: taxonId,
              isFavourite: Value(!(current?.isFavourite ?? false)),
              lastUsedAt: Value(current?.lastUsedAt),
              useCount: Value(current?.useCount ?? 0),
            ),
          );
    });
  }

  /// Notes that the taxon was just recorded in the project: it moves to the
  /// top of the Recent list. Joins a running transaction.
  Future<void> recordUse(String projectId, String taxonId) {
    return _db.transaction(() async {
      final current = await _usageRow(projectId, taxonId);
      await _db
          .into(_db.taxonUsages)
          .insertOnConflictUpdate(
            TaxonUsagesCompanion.insert(
              projectId: projectId,
              taxonId: taxonId,
              isFavourite: Value(current?.isFavourite ?? false),
              lastUsedAt: Value(DateTime.now().toUtc()),
              useCount: Value((current?.useCount ?? 0) + 1),
            ),
          );
    });
  }

  Future<TaxonUsage?> _usageRow(String projectId, String taxonId) {
    final query = _db.select(_db.taxonUsages)
      ..where((u) => u.projectId.equals(projectId) & u.taxonId.equals(taxonId));
    return query.getSingleOrNull();
  }
}

final taxonRepositoryProvider = Provider<TaxonRepository>(
  (ref) => TaxonRepository(ref.watch(appDatabaseProvider)),
);

/// The taxa the species picker offers.
final pickerTaxaProvider = StreamProvider<List<Taxon>>(
  (ref) => ref.watch(taxonRepositoryProvider).watchPickerTaxa(),
);

/// Favourites and recent use in one project (the argument is its id).
final taxonUsageProvider = StreamProvider.family<List<TaxonUsage>, String>(
  (ref, projectId) => ref.watch(taxonRepositoryProvider).watchUsage(projectId),
);
