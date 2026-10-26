import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/transects/domain/section_with_habitat.dart';

/// Transects, their sections and the project protocol on this phone. Read
/// only: these are reference tables that only the pull writes (CONVENTIONS
/// A.6), so the screens work offline once the project is downloaded.
class TransectRepository {
  TransectRepository(this._db);
  final AppDatabase _db;

  /// Live list of the project's transects, sorted by code.
  Stream<List<Transect>> watchTransects(String projectId) {
    final query = _db.select(_db.transects)
      ..where((t) => t.projectId.equals(projectId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.code)]);
    return query.watch();
  }

  /// One transect, or null when it is not on this phone.
  Stream<Transect?> watchTransect(String id) {
    final query = _db.select(_db.transects)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    return query.watchSingleOrNull();
  }

  /// Sections of a transect in walking order, each with its habitat type.
  /// A left join, so a section without a habitat type is still listed.
  Stream<List<SectionWithHabitat>> watchSections(String transectId) {
    final sections = _db.transectSections;
    final habitats = _db.habitatTypes;
    final query =
        _db.select(sections).join([
            leftOuterJoin(
              habitats,
              habitats.id.equalsExp(sections.habitatTypeId),
            ),
          ])
          ..where(
            sections.transectId.equals(transectId) &
                sections.deletedAt.isNull(),
          )
          ..orderBy([OrderingTerm.asc(sections.sequenceNumber)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          SectionWithHabitat(
            row.readTable(sections),
            row.readTableOrNull(habitats),
          ),
      ],
    );
  }

  /// The project's protocol, or null before the project is downloaded.
  Stream<ProjectProtocol?> watchProtocol(String projectId) {
    final query = _db.select(_db.projectProtocols)
      ..where((p) => p.projectId.equals(projectId) & p.deletedAt.isNull())
      ..limit(1);
    return query.watchSingleOrNull();
  }
}

final transectRepositoryProvider = Provider<TransectRepository>(
  (ref) => TransectRepository(ref.watch(appDatabaseProvider)),
);

final projectTransectsProvider = StreamProvider.family<List<Transect>, String>(
  (ref, projectId) =>
      ref.watch(transectRepositoryProvider).watchTransects(projectId),
);

final transectProvider = StreamProvider.family<Transect?, String>(
  (ref, id) => ref.watch(transectRepositoryProvider).watchTransect(id),
);

final transectSectionsProvider =
    StreamProvider.family<List<SectionWithHabitat>, String>(
      (ref, transectId) =>
          ref.watch(transectRepositoryProvider).watchSections(transectId),
    );

final projectProtocolProvider = StreamProvider.family<ProjectProtocol?, String>(
  (ref, projectId) =>
      ref.watch(transectRepositoryProvider).watchProtocol(projectId),
);
