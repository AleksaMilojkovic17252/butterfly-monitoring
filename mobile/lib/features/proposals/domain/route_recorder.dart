import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:mobile/core/location/location_source.dart';
import 'package:mobile/features/proposals/data/route_recording_repository.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';

/// What the route recorder is doing, for the record screen and the GPS
/// sharing in the capture widget. [recordingId] is null when no recording is
/// open.
class RouteRecorderState {
  const RouteRecorderState({
    this.recordingId,
    this.recording = false,
    this.paused = false,
    this.lastPosition,
    this.fixReceivedAt,
    this.problem,
  });

  /// The recording in progress on this phone, from the database.
  final String? recordingId;

  /// True while the GPS stream is running.
  final bool recording;

  /// True while the recording is paused: GPS is off and nothing is stored.
  final bool paused;

  /// The newest fix, for the map and the "± N m" status. Kept during a pause,
  /// cleared when GPS starts again, until the first new fix.
  final Position? lastPosition;

  /// Time on this phone's clock when the newest fix arrived.
  final DateTime? fixReceivedAt;

  /// Why no fixes come in (location off, permission refused, GPS error);
  /// null when all is well. The next fix clears it.
  final String? problem;

  RouteRecorderState copyWith({
    bool? recording,
    bool? paused,
    Position? lastPosition,
    DateTime? fixReceivedAt,
    String? problem,
    bool clearProblem = false,
  }) {
    return RouteRecorderState(
      recordingId: recordingId,
      recording: recording ?? this.recording,
      paused: paused ?? this.paused,
      lastPosition: lastPosition ?? this.lastPosition,
      fixReceivedAt: fixReceivedAt ?? this.fixReceivedAt,
      problem: clearProblem ? null : problem ?? this.problem,
    );
  }
}

/// Records the GPS fixes of the route recording in progress (T108), the same
/// way `TrackingController` records a visit's route.
///
/// It follows [openRecordingProvider]: the database row is the truth. When a
/// row exists and is not paused, GPS runs; when the row is paused or gone, GPS
/// stops. An app that was killed during a recording picks the row up again at
/// the next start, and the sequence numbers continue. `App` watches this
/// provider to keep it alive.
///
/// One GPS stream (D-087): geolocator keeps one position stream per app, so a
/// recording and a visit's tracker must never run together. `start` refuses
/// while a visit is in progress, and this class does not subscribe if one is.
///
/// Fixes are buffered and written every [_flushPoints] fixes or every
/// [_flushEvery], and when GPS stops. A buffered fix is lost if the app is
/// killed.
class RouteRecorder extends Notifier<RouteRecorderState> {
  static const _flushPoints = 10;
  static const _flushEvery = Duration(seconds: 30);

  /// Used when the project protocol is not on the phone: the server's default
  /// `gps_interval_s`.
  static const _defaultIntervalS = 5;

  /// The recording the controller last acted on, and whether it was paused.
  /// A new emission for the same recording changes nothing unless it was
  /// paused or resumed.
  String? _handledId;
  bool _handledPaused = false;

  StreamSubscription<Position>? _subscription;
  Timer? _flushTimer;
  final _buffer = <NewRecordingPoint>[];

  /// The recording the buffered fixes belong to.
  String? _bufferId;
  int _nextSequenceNumber = 1;

  /// Time of the newest stored or buffered fix. A fix that is not newer (the
  /// cached position some phones deliver first) is dropped.
  DateTime? _lastFixAt;

  /// Starts and stops run one after another, in the order they were asked.
  Future<void> _changes = Future.value();

  /// Buffer writes run one after another, so they never overlap.
  Future<void> _writes = Future.value();

  @override
  RouteRecorderState build() {
    ref.listen(openRecordingProvider, (_, next) {
      // Still loading: do nothing yet. A real answer (a row or null) follows.
      if (next.isLoading) return;
      final recording = next.value;
      _change(() async {
        final paused = recording?.pausedAt != null;
        final same = recording?.id == _handledId;
        if (same && paused == _handledPaused) return;
        _handledId = recording?.id;
        _handledPaused = paused;
        await _stopGps();
        if (recording == null) {
          state = const RouteRecorderState();
        } else if (paused) {
          _showPaused(recording);
        } else {
          await _start(recording);
        }
      });
    }, fireImmediately: true);

    // The provider lives as long as the app, so this runs only when the app
    // goes away; the buffer cannot be written then.
    ref.onDispose(() {
      _subscription?.cancel();
      _flushTimer?.cancel();
    });
    return const RouteRecorderState();
  }

  /// Writes the buffered fixes now. For the Finish flow, which builds the line
  /// from the stored fixes.
  Future<void> flush() => _flush();

  /// Tries again after GPS stopped or never started (location off, permission
  /// refused). Asks for the permission again. Does nothing while paused.
  void retry() {
    _change(() async {
      final recording = ref.read(openRecordingProvider).value;
      if (recording == null || recording.id != _handledId) return;
      if (recording.pausedAt != null) return;
      await _stopGps();
      await _start(recording, askPermission: true);
    });
  }

  /// Adds [action] to the [_changes] chain. An error is shown as a problem and
  /// does not stop later changes.
  void _change(Future<void> Function() action) {
    _changes = _changes.then((_) async {
      try {
        await action();
      } catch (error) {
        state = state.copyWith(problem: 'Route recording failed: $error');
      }
    });
  }

  /// Starts GPS for [recording]. The permission is asked for only with
  /// [askPermission] (the Try again button): the record screen has just asked
  /// (`prepareTracking`).
  Future<void> _start(
    RouteRecording recording, {
    bool askPermission = false,
  }) async {
    // No `lastPosition`: after a pause the walker may have moved, so the old
    // fix must not count as the current position until a new one arrives.
    state = RouteRecorderState(recordingId: recording.id);

    // One GPS stream (D-087): never run next to the visit tracker.
    // Waits for the provider's first answer: its value is null while loading,
    // which would look like "no visit".
    final visit = await ref.read(deviceVisitInProgressProvider.future);
    if (visit != null) {
      state = state.copyWith(
        problem: 'A visit is in progress, so the route is not being recorded.',
      );
      return;
    }
    final failure = await checkLocationAllowed(
      ref.read(locationProvider),
      ask: askPermission,
    );
    if (failure != null) {
      state = state.copyWith(problem: _failureText(failure));
      return;
    }

    final protocol = await ref
        .read(transectRepositoryProvider)
        .watchProtocol(recording.projectId)
        .first;
    final intervalS = protocol?.gpsIntervalS ?? _defaultIntervalS;

    final points = ref.read(routeRecordingRepositoryProvider);
    _bufferId = recording.id;
    _nextSequenceNumber = await points.nextSequenceNumber(recording.id);
    _lastFixAt = await points.lastRecordedAt(recording.id);

    _subscription = ref
        .read(locationSourceProvider)
        .positions(
          intervalS: intervalS,
          accuracy: LocationAccuracy.high,
          title: 'Recording a route proposal',
          text: 'Recording the route every $intervalS s',
        )
        .listen(_onFix, onError: _onFixError, onDone: _onFixesEnded);
    _flushTimer = Timer.periodic(_flushEvery, (_) => _flush());
    state = state.copyWith(recording: true);
  }

  /// Shows the recording as paused. GPS is already stopped; the newest
  /// position stays when the same recording was running.
  void _showPaused(RouteRecording recording) {
    if (state.recordingId == recording.id) {
      state = state.copyWith(
        recording: false,
        paused: true,
        clearProblem: true,
      );
    } else {
      state = RouteRecorderState(recordingId: recording.id, paused: true);
    }
  }

  /// Puts a fix in the buffer under the next sequence number.
  void _onFix(Position position) {
    final at = position.timestamp.toUtc();
    final last = _lastFixAt;
    if (last != null && !at.isAfter(last)) return;
    _lastFixAt = at;

    _buffer.add(
      NewRecordingPoint(
        position: position,
        sequenceNumber: _nextSequenceNumber,
      ),
    );
    _nextSequenceNumber++;
    state = state.copyWith(
      fixReceivedAt: DateTime.now().toUtc(),
      lastPosition: position,
      clearProblem: true,
    );
    if (_buffer.length >= _flushPoints) _flush();
  }

  /// The stream reports a problem (e.g. location switched off during the
  /// walk). The subscription stays, so recording goes on when fixes return.
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

  /// Writes the buffered fixes to Drift and empties the buffer. A write for a
  /// recording that is gone does nothing (`addPoints`).
  Future<void> _flush() {
    final id = _bufferId;
    if (id == null || _buffer.isEmpty) return _writes;
    final fixes = List.of(_buffer);
    _buffer.clear();
    _writes = _writes.then((_) async {
      try {
        await ref.read(routeRecordingRepositoryProvider).addPoints(id, fixes);
      } catch (error) {
        state = state.copyWith(
          problem: 'Some route points could not be saved: $error',
        );
      }
    });
    return _writes;
  }

  /// Ends the subscription (which stops geolocator's foreground service and
  /// its notification) and writes what is left in the buffer.
  Future<void> _stopGps() async {
    await _subscription?.cancel();
    _subscription = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _flush();
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

final routeRecorderProvider =
    NotifierProvider<RouteRecorder, RouteRecorderState>(RouteRecorder.new);
