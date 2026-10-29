import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/location/battery_saver_visit.dart';
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
    this.recordingSince,
    this.paused = false,
    this.batterySaver = false,
    this.batterySaverAuto = false,
    this.lastFixAt,
    this.fixReceivedAt,
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

  /// UTC time the GPS stream last started. The "No GPS fix" banner (T038)
  /// counts from here until the first fix arrives.
  final DateTime? recordingSince;

  /// True while the visit is paused (T039): GPS is off and nothing is
  /// recorded.
  final bool paused;

  /// True while the visit is recorded in battery-saver mode (T038): a longer
  /// interval and lower accuracy.
  final bool batterySaver;

  /// True when the battery saver was switched on by the low battery (T038)
  /// and the screen has not told the user yet. The screen shows a snackbar
  /// and calls `acknowledgeBatterySaverAuto`.
  final bool batterySaverAuto;

  /// UTC time of the newest fix, stored or still in the buffer.
  final DateTime? lastFixAt;

  /// UTC time on this phone's clock when the newest fix arrived. The "No GPS
  /// fix" banner (T038) counts from it, since [lastFixAt] is the fix's own
  /// time, which can be old.
  final DateTime? fixReceivedAt;

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
    DateTime? recordingSince,
    bool? paused,
    bool? batterySaver,
    bool? batterySaverAuto,
    DateTime? lastFixAt,
    DateTime? fixReceivedAt,
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
      recordingSince: recordingSince ?? this.recordingSince,
      paused: paused ?? this.paused,
      batterySaver: batterySaver ?? this.batterySaver,
      batterySaverAuto: batterySaverAuto ?? this.batterySaverAuto,
      lastFixAt: lastFixAt ?? this.lastFixAt,
      fixReceivedAt: fixReceivedAt ?? this.fixReceivedAt,
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
/// Battery saver (T038): while it is on, GPS runs at the protocol's
/// `gpsIntervalBatterySaverS` with medium accuracy. The observer turns it on
/// with [setBatterySaver], and it turns on by itself when the battery falls
/// below [_lowBatteryPercent] (checked every [_batteryCheckEvery]). The visit
/// id is kept in `batterySaverVisitProvider`, so the mode survives a restart
/// of the app.
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

  /// Used in battery-saver mode when the protocol is not on the phone: the
  /// server's default `gps_interval_battery_saver_s`.
  static const _defaultBatterySaverIntervalS = 15;

  /// Below this battery level (percent) the battery saver turns on by itself.
  static const _lowBatteryPercent = 20;
  static const _batteryCheckEvery = Duration(seconds: 60);

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
  Timer? _batteryTimer;
  final _buffer = <NewTrackPoint>[];
  int _nextSequenceNumber = 1;

  /// Time of the newest stored or buffered fix. A fix that is not newer (the
  /// cached position some phones deliver first) is dropped, so points stay in
  /// time order.
  DateTime? _lastFixAt;

  /// The visit the low battery already switched to battery saver in this run
  /// of the app. If the observer turns the mode off again, it stays off.
  String? _autoSwitchedVisitId;

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
      _batteryTimer?.cancel();
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

  /// Turns battery-saver mode on or off for the visit being tracked (T038).
  /// Does nothing without a visit or after [stop]. Turning it on also queues
  /// `battery_saver_used = true` on the visit. When GPS is running it is
  /// restarted with the new interval and accuracy, without a "Tracking
  /// interrupted" message; the dot on the map disappears until the next fix,
  /// as after a pause. When the visit is paused or GPS is not running, only
  /// the mode is stored, and the next start uses it.
  Future<void> setBatterySaver(bool on) {
    _change(() => _setBatterySaver(on));
    return _changes;
  }

  /// Hides the battery-saver snackbar flag once the screen has shown it.
  void acknowledgeBatterySaverAuto() {
    state = state.copyWith(batterySaverAuto: false);
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

  /// The work of [setBatterySaver]; runs inside the [_change] chain. With
  /// [auto] the low battery asked for it, and the screen is told.
  Future<void> _setBatterySaver(bool on, {bool auto = false}) async {
    final visit = ref.read(deviceVisitInProgressProvider).value;
    if (visit == null || visit.id != _handledVisitId || _stopped) return;
    if (auto) {
      // The check ran a moment ago; GPS may have stopped (a pause) or the
      // mode may have changed since. Then there is nothing to switch.
      if (_subscription == null || state.batterySaver) return;
      if (_autoSwitchedVisitId == visit.id) return;
      _autoSwitchedVisitId = visit.id;
    }

    // First, so a visit that cannot take the write leaves the mode as it was.
    if (on) {
      await ref.read(visitRepositoryProvider).markBatterySaverUsed(visit.id);
    }
    await ref
        .read(batterySaverVisitProvider.notifier)
        .save(on ? visit.id : null);
    // At once, so the toggle changes before GPS has restarted.
    state = state.copyWith(batterySaver: on);

    if (_subscription != null) {
      await _stopTracking();
      await _start(visit);
    } else {
      state = state.copyWith(batterySaver: on);
    }
    if (auto) state = state.copyWith(batterySaverAuto: true);
  }

  /// Switches to battery saver when the battery is below
  /// [_lowBatteryPercent], once per visit in this run of the app. A phone
  /// that cannot tell its level skips the check.
  Future<void> _checkBattery(SurveyVisit visit) async {
    if (state.batterySaver || _autoSwitchedVisitId == visit.id) return;
    final int level;
    try {
      level = await ref.read(batteryProvider).batteryLevel;
    } catch (_) {
      return;
    }
    // The mode or the visit may have changed while the level was read.
    if (level >= _lowBatteryPercent) return;
    if (state.batterySaver || _autoSwitchedVisitId == visit.id) return;
    if (state.visitId != visit.id) return;
    _change(() => _setBatterySaver(true, auto: true));
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
    final saver = ref.read(batterySaverVisitProvider) == visit.id;
    // The per-device override does not apply in battery-saver mode.
    final intervalS = saver
        ? protocol?.gpsIntervalBatterySaverS ?? _defaultBatterySaverIntervalS
        : ref.read(gpsIntervalOverrideProvider) ??
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
      batterySaver: saver,
      // Kept until the screen has shown it, also across a restart.
      batterySaverAuto: sameVisit && state.batterySaverAuto,
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
          accuracy: saver ? LocationAccuracy.medium : LocationAccuracy.high,
          title: 'Visit in progress: $code',
          text: saver
              ? 'Battery saver: recording the route every $intervalS s'
              : 'Recording the route every $intervalS s',
        )
        .listen(_onFix, onError: _onFixError, onDone: _onFixesEnded);
    _flushTimer = Timer.periodic(_flushEvery, (_) => _flush());
    _batteryTimer = Timer.periodic(
      _batteryCheckEvery,
      (_) => _checkBattery(visit),
    );
    _checkBattery(visit);
    state = state.copyWith(
      recording: true,
      recordingSince: DateTime.now().toUtc(),
    );
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
      batterySaver: ref.read(batterySaverVisitProvider) == visit.id,
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
      fixReceivedAt: DateTime.now().toUtc(),
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
    _batteryTimer?.cancel();
    _batteryTimer = null;
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
