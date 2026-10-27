import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/sync/sync_runner.dart';
import 'package:mobile/core/sync/sync_state_repository.dart';
import 'package:mobile/features/sync/data/sync_status_repository.dart';

/// Queue items of the project per entity type, in any status. The sum is the
/// badge on the project home tile.
final pendingByTypeProvider = StreamProvider.family<Map<String, int>, String>(
  (ref, projectId) =>
      ref.watch(syncStatusRepositoryProvider).watchPendingByType(projectId),
);

/// The project's rejected queue items, in queue order.
final rejectedItemsProvider =
    StreamProvider.family<List<SyncQueueItem>, String>(
      (ref, projectId) =>
          ref.watch(syncStatusRepositoryProvider).watchRejected(projectId),
    );

/// Ids of the project's locked visits (T042).
final lockedVisitIdsProvider = StreamProvider.family<Set<String>, String>(
  (ref, projectId) =>
      ref.watch(syncStatusRepositoryProvider).watchLockedVisitIds(projectId),
);

/// The project's conflicts: open ones first, then newest first.
final conflictsProvider = StreamProvider.family<List<SyncConflict>, String>(
  (ref, projectId) =>
      ref.watch(syncStatusRepositoryProvider).watchConflicts(projectId),
);

/// Bytes transferred by the last sync run; null if none yet.
final lastSyncBytesProvider = FutureProvider<int?>((ref) {
  // Recompute after every sync run.
  ref.watch(syncRunnerProvider.select((s) => s.last));
  return ref.read(syncStateRepositoryProvider).lastSyncBytes();
});

/// Photos waiting to upload and their size. Always zero until photos exist.
final pendingPhotosProvider = Provider<({int count, int bytes})>((ref) {
  // TODO(T050): count photos waiting to upload.
  return (count: 0, bytes: 0);
});
