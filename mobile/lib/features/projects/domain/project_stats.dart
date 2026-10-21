import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/sync/sync_repository.dart';

/// State of a project's offline package on this phone.
enum OfflinePackageStatus {
  notDownloaded('Not downloaded'),
  ready('Ready'),
  updateAvailable('Update available');

  const OfflinePackageStatus(this.label);
  final String label;
}

// The numbers below are placeholders: the tables they count do not exist yet.
// Screens already watch these providers, so filling them in later needs no UI
// change.

/// Transects of the project stored on this phone.
// TODO(T031): count local transect rows once pull stores them.
final downloadedTransectCountProvider = FutureProvider.family<int, String>(
  (ref, projectId) async => 0,
);

/// Local changes in the project not yet pushed.
final projectPendingChangesProvider = StreamProvider.family<int, String>(
  (ref, projectId) => ref
      .watch(syncRepositoryProvider)
      .watchUnsyncedCount(projectId: projectId),
);

/// Whether the project's offline package is downloaded and current.
// TODO(T031): compare the local and server reference_version.
final offlinePackageStatusProvider =
    FutureProvider.family<OfflinePackageStatus, String>(
      (ref, projectId) async => OfflinePackageStatus.notDownloaded,
    );
