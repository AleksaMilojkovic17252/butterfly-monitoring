import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/location/gps_interval_override.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:mobile/core/location/location_source.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/visits/data/track_point_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';

/// A stretch of a visit with no route: the app was killed while tracking and
/// started again. [from] is the last stored point (or the visit start), [to]
/// the first fix after the restart. Both UTC.
class TrackingInterruption {
  const TrackingInterruption({required this.from, required this.to});
  final DateTime from;
  final DateTime to;
}

/// What the GPS tracker is doing, for the tracking card and the active visit
/// screen (T039). [visitId] is null when there is no visit to track.
class TrackingState {
  const TrackingState({
    this.visitId,
    this.transectCode = '',
    this.intervalS,
    this.recording = false,
    this.paused = false,
    this.lastFixAt,
    this.lastPosition,
    this.interruption,
    this.problem,
    this.saveProblem,
  });

  final String? visitId;
  final String transectCode;

  /// Seconds between fixes; null until tracking has started.
  final int? intervalS;

  /// True while the GPS stream is running.
  final bool recording;

  /// True while the visit is paused (T039): GPS is off and nothing is
  /// recorded.
  final bool paused;

  /// UTC time of the newest fix, stored or still in the buffer.
  final DateTime? lastFixAt;

  /// The newest fix (position and accuracy), for the map and the current
  /// section (T039). Kept during a pause, so the map shows where it began;
  /// cleared when GPS starts again, until the first new fix.
  final Position? lastPosition;

  /// Shown once after tracking resumed, until the user closes it.
  final TrackingInterruption? interruption;

  /// Why no fixes come in (location off, permission refused, GPS error);
  /// null when all is well. The next fix clears it.
  final String? problem;

  /// Points that could not be saved, so part of the route is lost. Unlike
  /// [problem] it stays for the rest of the visit, also across a pause or a
  /// retry.
  final String? saveProblem;

  /// A copy with the given fields changed. A nullable field is cleared with
  /// its `clear...` flag, since passing null means "keep".
  TrackingState copyWith({
    bool? recording,
    bool? paused,
    DateTime? lastFixAt,
    Position? lastPosition,
    TrackingInterruption? interruption,
    bool clearInterruption = false,
    String? problem,
    bool clearProblem = false,
    String? saveProblem,
  }) {
    return TrackingState(
      visitId: visitId,
      transectCode: transectCode,
      intervalS: intervalS,
      recording: recording ?? this.recording,
      paused: paused ?? this.paused,
      lastFixAt: lastFixAt ?? this.lastFixAt,
      lastPosition: lastPosition ?? this.lastPosition,
      interruption: clearInterruption
          ? null
          : interruption ?? this.interruption,
      problem: clearProblem ? null : problem ?? this.problem,
      saveProblem: saveProblem ?? this.saveProblem,
    );
  }
}

/// Records the route of the visit in progress (T037).
///
/// It follows [deviceVisitInProgressProvider], the visit in progress that was
/// started on this phone: when one appears (Start, or the app starting with
/// one), tracking starts; when there is none any more (finished, cancelled,
/// data removed), it stops. Logging out or an expired session does not stop
/// it: the walk goes on. `App` watches this provider to keep it alive.
///
/// A paused visit (`pausedAt` set, T039) is not tracked: pausing stops GPS,
/// and resuming starts it again. An app start with a paused visit leaves GPS
/// off until Resume.
///
/// Fixes are buffered and written to Drift every [_flushPoints] points or
/// every [_flushEvery], whichever comes first. A buffered fix is lost if the
/// app is killed; the next start resumes and shows the gap.
class TrackingController extends Notifier<TrackingState> {
  static const _flushPoints = 10;
  static const _flushEvery = Duration(seconds: 30);

  /// Used when the project protocol is not on the phone: the server's
  /// default `gps_interval_s`.
  static const _defaultIntervalS = 5;

  /// When this controller was created, i.e. when the app started. A visit
  /// that started before it began in an earlier run of the app, so picking
  /// it up now is a resume after an interruption.
  final _createdAt = DateTime.now().toUtc();

  /// The visit the provider last reported and this controller acted on, even
  /// if it then stopped ([stop]) or could not start (no permission). A new
  /// emission for the same visit changes nothing, unless it was paused or
  /// resumed ([_handledPaused]).
  String? _handledVisitId;

  /// Whether [_handledVisitId] was paused when the controller last acted.
  bool _handledPaused = false;

  /// Set by [stop]: the visit stays stopped, even if it is resumed later.
  bool _stopped = false;

  /// The visit being tracked; null when stopped.
  SurveyVisit? _visit;
  StreamSubscription<Position>? _subscription;
  Timer? _flushTimer;
  final _buffer = <NewTrackPoint>[];
  int _nextSequenceNumber = 1;

  /// Time of the newest stored or buffered fix. A fix that is not newer (the
  /// cached position some phones deliver first) is dropped, so points stay in
  /// time order.
  DateTime? _lastFixAt;

  /// Start of the interruption on a resume, until the first fix arrives.
  DateTime? _interruptedFrom;

  /// Starts and stops run one after another, in the order they were asked.
  Future<void> _changes = Future.value();

  /// Buffer writes run one after another, so they never overlap.
  Future<void> _writes = Future.value();

  @override
  TrackingState build() {
    ref.listen(deviceVisitInProgressProvider, (_, next) {
      final visit = next.value;
      _change(() async {
        final paused = visit?.pausedAt != null;
        final sameVisit = visit?.id == _handledVisitId;
        if (sameVisit && (paused == _handledPaused || _stopped)) return;
        _handledVisitId = visit?.id;
        _handledPaused = paused;
        _stopped = false;
        await _stopTracking();
        // An interruption still waiting for its first fix stays open across
        // a pause, so Resume closes it; another visit starts afresh.
        if (!sameVisit) _interruptedFrom = null;
        if (visit == null) {
          state = const TrackingState();
        } else if (paused) {
          await _showPaused(visit);
        } else {
          // Picked up for the first time: maybe a resume after the app was
          // killed. After a pause it is not, so no "Tracking interrupted".
          await _start(visit, resume: !sameVisit);
        }
      });
    }, fireImmediately: true);

    // The provider lives as long as the app, so this runs only when the app
    // goes away; the buffer cannot be written then.
    ref.onDispose(() {
      _subscription?.cancel();
      _flushTimer?.cancel();
    });
    return const TrackingState();
  }

  /// Stops tracking and writes the buffer. For the finish flow (T040), which
  /// needs every point stored before it ends the visit. Tracking does not
  /// start again for the same visit, even while it is still in progress.
  Future<void> stop() {
    _change(() async {
      _stopped = true;
      await _stopTracking();
      _interruptedFrom = null;
      state = const TrackingState();
    });
    return _changes;
  }

  /// Undoes [stop] when the visit could not be finished (T040): tracking
  /// starts again for the visit if it is still in progress on this phone,
  /// without the "Tracking interrupted" message. A paused visit stays off
  /// until Resume. Does nothing when the visit is gone or no longer in
  /// progress (finished, cancelled or locked by a pull).
  Future<void> restart() {
    _change(() async {
      final visit = ref.read(deviceVisitInProgressProvider).value;
      if (visit == null || visit.id != _handledVisitId || !_stopped) return;
      _stopped = false;
      if (visit.pausedAt != null) {
        await _showPaused(visit);
      } else {
        await _start(visit);
      }
    });
    return _changes;
  }

  /// Tries again after GPS stopped or never started (location off, permission
  /// refused). Asks for the permission again. Does nothing while paused.
  void retry() {
    final visit = ref.read(deviceVisitInProgressProvider).value;
    _change(() async {
      if (visit == null || visit.id != _handledVisitId) return;
      if (_stopped || visit.pausedAt != null) return;
      await _stopTracking();
      await _start(visit, askPermission: true);
    });
  }

  /// Hides the "Tracking interrupted" message.
  void dismissInterruption() {
    state = state.copyWith(clearInterruption: true);
  }

  /// Adds [action] to the [_changes] chain. An error is shown as a problem
  /// and does not stop later changes.
  void _change(Future<void> Function() action) {
    _changes = _changes.then((_) async {
      try {
        await action();
      } catch (error) {
        state = state.copyWith(problem: 'Route recording failed: $error');
      }
    });
  }

  /// Starts tracking [visit].
  ///
  /// With [resume] (the first time the visit is picked up), a visit that
  /// began before this run of the app gets the "Tracking interrupted"
  /// message. The location permission is asked for only with [askPermission]
  /// (the Try again button): Start has just asked (`prepareTracking`), and
  /// asking again right after a refusal would show the same dialog twice.
  Future<void> _start(
    SurveyVisit visit, {
    bool resume = false,
    bool askPermission = false,
  }) async {
    final transects = ref.read(transectRepositoryProvider);
    final transect = await transects.watchTransect(visit.transectId).first;
    final protocol = await transects.watchProtocol(visit.projectId).first;
    final intervalS =
        ref.read(gpsIntervalOverrideProvider) ??
        protocol?.gpsIntervalS ??
        _defaultIntervalS;
    final code = transect?.code ?? '';
    final sameVisit = state.visitId == visit.id;
    // No `lastPosition`: after a pause or a retry the observer may have
    // moved, so the old fix must not count as the current position (or
    // section) until a new one arrives.
    state = TrackingState(
      visitId: visit.id,
      transectCode: code,
      intervalS: intervalS,
      // Kept across a retry or a pause, until the user closes it.
      interruption: sameVisit ? state.interruption : null,
      // Lost points stay lost: kept for the rest of the visit.
      saveProblem: sameVisit ? state.saveProblem : null,
    );

    final failure = await checkLocationAllowed(
      ref.read(locationProvider),
      ask: askPermission,
    );
    if (failure != null) {
      state = state.copyWith(problem: _failureText(failure));
      return;
    }

    final points = ref.read(trackPointRepositoryProvider);
    _visit = visit;
    _nextSequenceNumber = await points.nextSequenceNumber(visit.id);
    _lastFixAt = await points.lastRecordedAt(visit.id);
    final startedAt = visit.startedAt?.toUtc();
    if (resume && startedAt != null && startedAt.isBefore(_createdAt)) {
      _interruptedFrom = _lastFixAt ?? startedAt;
    }

    _subscription = ref
        .read(locationSourceProvider)
        .positions(
          intervalS: intervalS,
          title: 'Visit in progress: $code',
          text: 'Recording the route every $intervalS s',
        )
        .listen(_onFix, onError: _onFixError, onDone: _onFixesEnded);
    _flushTimer = Timer.periodic(_flushEvery, (_) => _flush());
    state = state.copyWith(recording: true);
  }

  /// Shows [visit] as paused (T039). GPS is already stopped. The newest
  /// position (shown grey), an open "Tracking interrupted" and a save problem
  /// stay when the same visit was being tracked.
  Future<void> _showPaused(SurveyVisit visit) async {
    if (state.visitId == visit.id) {
      state = state.copyWith(
        recording: false,
        paused: true,
        clearProblem: true,
      );
      return;
    }
    final transect = await ref
        .read(transectRepositoryProvider)
        .watchTransect(visit.transectId)
        .first;
    state = TrackingState(
      visitId: visit.id,
      transectCode: transect?.code ?? '',
      paused: true,
    );
  }

  /// Puts a fix in the buffer under the next sequence number.
  void _onFix(Position position) {
    final at = position.timestamp.toUtc();
    final last = _lastFixAt;
    if (last != null && !at.isAfter(last)) return;
    _lastFixAt = at;

    _buffer.add(
      NewTrackPoint(position: position, sequenceNumber: _nextSequenceNumber),
    );
    _nextSequenceNumber++;

    // The first fix after a resume closes the interruption.
    final from = _interruptedFrom;
    _interruptedFrom = null;
    state = state.copyWith(
      lastFixAt: at,
      lastPosition: position,
      interruption: from == null
          ? null
          : TrackingInterruption(from: from, to: at),
      clearProblem: true,
    );

    if (_buffer.length >= _flushPoints) _flush();
  }

  /// The stream reports a problem (e.g. location switched off during the
  /// walk). The subscription stays, so tracking goes on when fixes return.
  void _onFixError(Object error) {
    state = state.copyWith(
      problem: switch (error) {
        LocationServiceDisabledException() => _failureText(
          LocationFailure.serviceOff,
        ),
        PermissionDeniedException() => _failureText(LocationFailure.denied),
        _ => 'GPS error: $error',
      },
    );
  }

  /// The stream ended without being cancelled: no more fixes will come.
  void _onFixesEnded() {
    _subscription = null;
    state = state.copyWith(
      recording: false,
      problem: 'GPS stopped. The route is not being recorded.',
    );
  }

  /// Writes the buffered fixes to Drift (and the sync queue) and empties the
  /// buffer. A failed write is shown as [TrackingState.saveProblem]; those
  /// points are lost.
  Future<void> _flush() {
    final visit = _visit;
    if (visit == null || _buffer.isEmpty) return _writes;
    final points = List.of(_buffer);
    _buffer.clear();
    _writes = _writes.then((_) async {
      try {
        await ref.read(trackPointRepositoryProvider).addPoints(visit, points);
      } catch (error) {
        state = state.copyWith(
          saveProblem: 'Some route points could not be saved: $error',
        );
      }
    });
    return _writes;
  }

  /// Ends the subscription (which stops geolocator's foreground service and
  /// its notification) and writes what is left in the buffer.
  Future<void> _stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _flush();
    _visit = null;
    _lastFixAt = null;
  }

  static String _failureText(LocationFailure failure) {
    return switch (failure) {
      LocationFailure.serviceOff =>
        'Location is switched off. The route is not being recorded.',
      LocationFailure.denied =>
        'Location permission was refused. The route is not being recorded.',
      LocationFailure.deniedForever =>
        'Location is blocked for this app. Allow it in the phone settings.',
      LocationFailure.unavailable => 'No location available.',
    };
  }
}

final trackingControllerProvider =
    NotifierProvider<TrackingController, TrackingState>(TrackingController.new);
