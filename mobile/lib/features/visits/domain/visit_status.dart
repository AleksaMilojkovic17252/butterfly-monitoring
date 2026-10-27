/// The visit lifecycle (T034, outline 7.2), the same table as the server's
/// `apps/surveys/state.py`. Both are checked against
/// `docs/requirements/visit-states.json` by a test (`test/visit_status_test.dart`
/// here). Statuses are the server's strings, not a Dart enum, because
/// `in_progress` is not a Dart enum name (as in D-054).
library;

/// Every visit status, in lifecycle order.
const visitStatuses = [
  'draft',
  'in_progress',
  'completed',
  'synced',
  'reviewed',
  'locked',
  'cancelled',
];

/// Why a visit was cancelled. Required exactly when the status is `cancelled`.
const cancelReasons = [
  'not_conducted',
  'aborted_weather',
  'aborted_other',
  'invalid_protocol',
];

/// Who may make a move: the visit's creator in the app, the server on its
/// own (completed to synced after a push), or an admin on the server.
enum VisitActor { app, server, admin }

/// One allowed move of a visit from [from] to [to], made by [by].
class VisitTransition {
  const VisitTransition(this.from, this.to, this.by);
  final String from;
  final String to;
  final VisitActor by;
}

/// Every allowed move. The app itself makes only the [VisitActor.app] ones.
const visitTransitions = [
  VisitTransition('draft', 'in_progress', VisitActor.app),
  VisitTransition('draft', 'cancelled', VisitActor.app),
  VisitTransition('in_progress', 'cancelled', VisitActor.app),
  VisitTransition('in_progress', 'completed', VisitActor.app),
  VisitTransition('completed', 'synced', VisitActor.server),
  VisitTransition('completed', 'reviewed', VisitActor.admin),
  VisitTransition('synced', 'reviewed', VisitActor.admin),
  VisitTransition('completed', 'locked', VisitActor.admin),
  VisitTransition('synced', 'locked', VisitActor.admin),
  VisitTransition('reviewed', 'locked', VisitActor.admin),
  VisitTransition('locked', 'reviewed', VisitActor.admin), // unlock (T043)
];

/// True when the app may move a visit from [fromStatus] to [toStatus]. The
/// start, finish and cancel buttons (T035, T040, T041) ask this first; the
/// server checks the same move again on push.
bool appMayMove(String fromStatus, String toStatus) {
  return visitTransitions.any(
    (transition) =>
        transition.from == fromStatus &&
        transition.to == toStatus &&
        transition.by == VisitActor.app,
  );
}

/// True when an admin has locked the visit (T042). A locked visit and its
/// records are read-only on the phone until an admin unlocks it; the server
/// refuses any change with `visit_locked`.
bool visitIsLocked(String status) => status == 'locked';

/// The status as the screens show it.
String visitStatusLabel(String status) {
  return switch (status) {
    'draft' => 'Draft',
    'in_progress' => 'In progress',
    'completed' => 'Completed',
    'synced' => 'Synced',
    'reviewed' => 'Reviewed',
    'locked' => 'Locked',
    'cancelled' => 'Cancelled',
    _ => status,
  };
}
