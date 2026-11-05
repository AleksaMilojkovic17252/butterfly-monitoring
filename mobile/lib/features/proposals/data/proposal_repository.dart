import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/core/validation/proposal_rules.dart';
import 'package:mobile/core/validation/rule_messages.dart';
import 'package:mobile/features/auth/domain/auth_controller.dart';
import 'package:mobile/features/auth/domain/auth_state.dart';
import 'package:mobile/features/proposals/domain/recording_stats.dart';
import 'package:uuid/uuid.dart';

/// The caller's route proposals on this phone (T108). A new proposal is made
/// from a finished recording and queued for push through
/// [SyncRepository.write]; the row and its queue item are written in one
/// transaction. The phone only creates: the admin's review (status, note, the
/// new transect) comes back by pull, and there is no edit or withdraw.
class ProposalRepository {
  ProposalRepository(this._db, this._sync);
  final AppDatabase _db;
  final SyncRepository _sync;

  /// The server's entity type and the local table name. The pull's tombstone
  /// SQL uses the entity type as the table name, so it must not change.
  static const _entityType = 'transect_proposal';

  // --- Reads ---------------------------------------------------------------

  /// Live proposals of a project that [createdById] made, newest first.
  /// Filtered by user because logout keeps the local data, so another user's
  /// rows can still be here.
  Stream<List<TransectProposal>> watchProjectProposals(
    String projectId,
    String createdById,
  ) {
    final query = _db.select(_db.transectProposals)
      ..where(
        (p) =>
            p.projectId.equals(projectId) &
            p.createdById.equals(createdById) &
            p.deletedAt.isNull(),
      )
      ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]);
    return query.watch();
  }

  // --- Writes --------------------------------------------------------------

  /// Turns [recording] into a proposal, queues it for push and deletes the
  /// recording with its fixes. Returns the proposal's id.
  ///
  /// The line is made of the usable fixes ([usableLineFixes]; [warningM] is
  /// the protocol's GPS accuracy warning). `recorded_from` and `recorded_to`
  /// are the times of the first and last fix in the line.
  ///
  /// [throughSequence] is the number of the last fix the researcher saw on the
  /// Finish sheet: later fixes (the recorder keeps running while the sheet is
  /// open) are left out, so the saved line is the one that was shown.
  ///
  /// Throws a [StateError] when a rule of `core/validation` (V02, V07, V08)
  /// refuses the proposal; the message says why.
  Future<String> createFromRecording({
    required RouteRecording recording,
    required String name,
    required String reason,
    required String notes,
    required double warningM,
    required String userId,
    int? throughSequence,
  }) {
    return _db.transaction(() async {
      final stored =
          await (_db.select(_db.routeRecordingPoints)
                ..where((p) => p.recordingId.equals(recording.id))
                ..orderBy([(p) => OrderingTerm.asc(p.sequenceNumber)]))
              .get();
      final seen = [
        for (final fix in stored)
          if (throughSequence == null || fix.sequenceNumber <= throughSequence)
            fix,
      ];
      final fixes = usableLineFixes(seen, warningM);
      if (fixes.isEmpty) {
        // No line at all: the rules refuse it (V02), before any times are
        // needed.
        throw StateError(
          ruleErrorText(
            validateProposal(name: name.trim(), reason: reason, points: []),
          ),
        );
      }
      final id = await _create(
        projectId: recording.projectId,
        replacesTransectId: recording.replacesTransectId,
        name: name,
        reason: reason,
        notes: notes,
        points: [for (final fix in fixes) LatLng(fix.lat, fix.lon)],
        from: fixes.first.recordedAt,
        to: fixes.last.recordedAt,
        userId: userId,
      );

      // The recording is done: its fixes and the row go.
      await (_db.delete(
        _db.routeRecordingPoints,
      )..where((p) => p.recordingId.equals(recording.id))).go();
      await (_db.delete(
        _db.routeRecordings,
      )..where((r) => r.id.equals(recording.id))).go();
      return id;
    });
  }

  /// Saves a line the researcher drew on the map as a proposal and queues it
  /// for push. Returns the proposal's id. A drawn proposal is the same as a
  /// recorded one to the server and the admin; `recorded_from` and
  /// `recorded_to` are both the time of saving.
  ///
  /// Throws a [StateError] when a rule (V02, V07, V08) refuses it.
  Future<String> createFromDrawing({
    required String projectId,
    required String? replacesTransectId,
    required List<LatLng> points,
    required String name,
    required String reason,
    required String notes,
    required String userId,
  }) {
    final now = DateTime.now().toUtc();
    return _db.transaction(
      () => _create(
        projectId: projectId,
        replacesTransectId: replacesTransectId,
        name: name,
        reason: reason,
        notes: notes,
        points: points,
        from: now,
        to: now,
        userId: userId,
      ),
    );
  }

  /// Checks the rules and writes the proposal with its queue item. Runs inside
  /// the caller's transaction.
  Future<String> _create({
    required String projectId,
    required String? replacesTransectId,
    required String name,
    required String reason,
    required String notes,
    required List<LatLng> points,
    required DateTime from,
    required DateTime to,
    required String userId,
  }) async {
    final cleanName = name.trim();
    final errors = validateProposal(
      name: cleanName,
      reason: reason,
      points: points,
    );
    if (errors.isNotEmpty) throw StateError(ruleErrorText(errors));

    final id = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final geometry = {
      'type': 'LineString',
      'coordinates': [
        for (final p in points) [p.longitude, p.latitude],
      ],
    };
    await _sync.write(
      projectId: projectId,
      entityType: _entityType,
      entityId: id,
      operation: SyncOperation.create,
      payload: {
        'project': projectId,
        'name': cleanName,
        'reason': reason,
        'replaces_transect': replacesTransectId,
        'notes': notes.trim(),
        'geometry': geometry,
        'recorded_from': from.toUtc().toIso8601String(),
        'recorded_to': to.toUtc().toIso8601String(),
        'created_at': now.toIso8601String(),
      },
      writeRow: () => _db
          .into(_db.transectProposals)
          .insert(
            TransectProposalsCompanion.insert(
              id: id,
              projectId: projectId,
              name: cleanName,
              reason: reason,
              replacesTransectId: Value(replacesTransectId),
              notes: Value(notes.trim()),
              geometryGeojson: jsonEncode(geometry),
              recordedFrom: from.toUtc(),
              recordedTo: to.toUtc(),
              createdAt: now,
              createdById: Value(userId),
            ),
          ),
    );
    return id;
  }
}

final proposalRepositoryProvider = Provider<ProposalRepository>(
  (ref) => ProposalRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncRepositoryProvider),
  ),
);

/// The logged-in user's route proposals of a project, newest first, live
/// (T108). `autoDispose`: the query stops when the screen closes.
final myProposalsProvider = StreamProvider.autoDispose
    .family<List<TransectProposal>, String>((ref, projectId) {
      final userId = ref.watch(authControllerProvider).profile?.id;
      if (userId == null) return Stream.value(const []);
      return ref
          .watch(proposalRepositoryProvider)
          .watchProjectProposals(projectId, userId);
    });
