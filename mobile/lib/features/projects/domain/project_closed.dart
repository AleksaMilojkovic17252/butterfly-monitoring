import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/projects/data/project_repository.dart';

/// The line shown wherever a closed project blocks new work (T099).
const projectClosedMessage = 'This project is closed';

/// Whether an admin has closed the project (T099, D-104). A closed project
/// takes no new or changed data: no visits, observations, plant records,
/// habitat features, route proposals or photos, and no edits or deletes. A
/// visit in progress can only be cancelled on this phone.
///
/// False while the project is still loading or when it is not on this phone,
/// so a screen never waits on it. The server refuses new work anyway.
final projectClosedProvider = Provider.family<bool, String>(
  (ref, projectId) =>
      ref.watch(projectProvider(projectId)).value?.closedAt != null,
);
