import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/core/sync/sync_runner.dart';
import 'package:mobile/features/projects/data/project_repository.dart';
import 'package:mobile/features/projects/domain/offline_package_status.dart';

/// Transects of the project stored on this phone. Live: it changes while a
/// download or sync stores rows.
final downloadedTransectCountProvider = StreamProvider.family<int, String>(
  (ref, projectId) =>
      ref.watch(projectRepositoryProvider).watchTransectCount(projectId),
);

/// Local changes in the project not yet pushed.
final projectPendingChangesProvider = StreamProvider.family<int, String>(
  (ref, projectId) => ref
      .watch(syncRepositoryProvider)
      .watchUnsyncedCount(projectId: projectId),
);

/// Whether the project's offline package is downloaded and current (the rule
/// is in [ProjectRepository.offlinePackageStatus]).
final offlinePackageStatusProvider =
    FutureProvider.family<OfflinePackageStatus, String>((ref, projectId) {
      // Recompute after every sync run and every download.
      ref.watch(syncRunnerProvider.select((s) => s.last));
      return ref
          .read(projectRepositoryProvider)
          .offlinePackageStatus(projectId);
    });
