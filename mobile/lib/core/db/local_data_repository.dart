import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';

class LocalDataRepository {
  LocalDataRepository(this._db);
  final AppDatabase _db;

  /// Deletes every row in every local table.
  Future<void> clearAll() => _db.transaction(() async {
    for (final table in _db.allTables) {
      await _db.delete(table).go();
    }
  });
}

final localDataRepositoryProvider = Provider<LocalDataRepository>(
  (ref) => LocalDataRepository(ref.watch(appDatabaseProvider)),
);
