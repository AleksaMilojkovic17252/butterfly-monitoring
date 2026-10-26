import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:mobile/core/http/transfer_counter.dart';
import 'package:mobile/core/sync/pull_applier.dart';
import 'package:mobile/core/sync/sync_api.dart';
import 'package:mobile/core/sync/sync_repository.dart';
import 'package:mobile/core/sync/sync_state_repository.dart';
import 'package:mobile/core/sync/sync_status.dart';
import 'package:mobile/features/projects/data/project_repository.dart';

/// Which half of a sync run is in progress.
enum SyncPhase { pushing, pulling }

/// What one finished sync run did.
/// [ok] is true when there was no error and nothing sendable
/// was left in the queue.
class SyncResult {
  SyncResult({
    required this.ok,
    required this.pushed,
    required this.pulled,
    required this.bytes,
    required this.finishedAt,
    this.error,
    this.cancelled = false,
  });
  final bool ok;

  /// Queue items sent to the server.
  final int pushed;

  /// Rows received from the server.
  final int pulled;

  /// Bytes transferred in the whole run, from the transfer counter.
  final int bytes;

  /// What went wrong; null when nothing did.
  final String? error;
  final DateTime finishedAt;

  /// The user cancelled a download; not an error.
  final bool cancelled;
}

/// What the UI watches:
/// whether a run is in progress,
/// and the result of the previous run (null before the first one).
class SyncRunState {
  SyncRunState({
    required this.running,
    this.last,
    this.downloadingProjectId,
    this.phase,
    this.received = 0,
    this.sent = 0,
  });
  final bool running;
  final SyncResult? last;

  /// The project being downloaded, null otherwise.
  final String? downloadingProjectId;

  /// Rows received so far in that download.
  final int received;

  /// Phase of the run in progress; null when idle or downloading.
  final SyncPhase? phase;

  /// Queue items sent so far in this run.
  final int sent;
}

/// Runs the sync: pushes the queue, then pulls every downloaded project. Also
/// downloads one project on request ([download]). Only one run or download
/// goes at a time. The state tells the UI whether one is in progress and how
/// the last one ended.
class SyncRunner extends Notifier<SyncRunState> {
  /// The run in progress, shared with anyone who calls [run] meanwhile.
  Future<SyncResult>? _current;

  /// Whether [_current] ignores the retry delays.
  var _currentIsManual = false;

  /// Stops the download in progress; null when none is running.
  CancelToken? _cancelToken;

  @override
  SyncRunState build() {
    return SyncRunState(running: false);
  }

  /// Starts a sync, or joins the one already running and returns its result.
  /// It never throws: a failure comes back as a [SyncResult] with `ok` false.
  /// [manual] means a person asked, so retry delays are ignored. A manual call
  /// that finds an automatic run going waits for it and then runs again, so the
  /// request is not lost to a run that respected the delays.
  Future<SyncResult> run({bool manual = false}) {
    final running = _current;
    if (running != null) {
      if (manual && !_currentIsManual) {
        return running.then((_) => run(manual: true));
      }
      return running;
    }
    _currentIsManual = manual;
    final started = _run(manual).whenComplete(() => _current = null);
    _current = started;
    return started;
  }

  /// One whole run: recover interrupted items, push the queue in batches, pull
  /// each local project page by page, then save the bookkeeping. A network
  /// error on push or pull ends the run with `ok` false; the `finally` always
  /// turns `running` off.
  Future<SyncResult> _run(bool manual) async {
    final syncRepository = ref.read(syncRepositoryProvider);
    final syncApi = ref.read(syncApiProvider);
    final syncState = ref.read(syncStateRepositoryProvider);
    final projectRepository = ref.read(projectRepositoryProvider);
    final transferCounter = ref.read(transferCounterProvider);
    state = SyncRunState(
      running: true,
      last: state.last,
      phase: SyncPhase.pushing,
    );
    var result = SyncResult(
      ok: false,
      pushed: 0,
      pulled: 0,
      bytes: 0,
      finishedAt: DateTime.now(),
      error: 'sync did not finish',
    );
    var pushed = 0;
    var pulled = 0;
    String? error;

    try {
      transferCounter.reset();
      await syncRepository.recoverInFlight();
      final deviceId = await syncState.deviceId();
      final sentIds = <String>{};
      while (true) {
        final batch = await syncRepository.nextBatch(ignoreBackoff: manual);
        // An item sent earlier in this run came back (a missing result put it
        // back in the queue): stop instead of looping forever.
        if (batch.isEmpty ||
            batch.any((item) => sentIds.contains(item.mutationId))) {
          break;
        }
        // Send the items as the queue holds them now: an edit may have been
        // merged into one since nextBatch read it.
        final sending = await syncRepository.markSending(batch);
        if (sending.isEmpty) continue;
        final List<PushResult> pushResults;
        try {
          pushResults = await syncApi.push(deviceId, sending);
        } catch (e) {
          // Not only a network error: a reply the app cannot read must also
          // back off, or the batch stays inFlight and is retried at once.
          await syncRepository.markNetworkFailure(sending, e);
          error = e.toString();
          break;
        }
        pushed += sending.length;
        sentIds.addAll(sending.map((item) => item.mutationId));
        state = SyncRunState(
          running: true,
          last: state.last,
          phase: SyncPhase.pushing,
          sent: pushed,
        );
        await syncRepository.applyPushResults(sending, pushResults);
      }
      // TODO(T050): upload photos here, after push and before pull.
      if (error == null) {
        try {
          await projectRepository.refreshFromServer();
        } on DioException catch (e) {
          error = e.toString();
        }
      }
      if (error == null) {
        final projects = await projectRepository.localProjects();
        state = SyncRunState(
          running: true,
          last: state.last,
          phase: SyncPhase.pulling,
          sent: pushed,
        );
        for (final project in projects) {
          // Only a downloaded project is kept up to date (T031).
          if (!await syncState.isDownloaded(project.id)) continue;
          try {
            await _pullProject(
              project.id,
              onPage: (rows) {
                pulled += rows;
                state = SyncRunState(
                  running: true,
                  last: state.last,
                  phase: SyncPhase.pulling,
                  sent: pushed,
                  received: pulled,
                );
              },
            );
          } on DioException catch (e) {
            // Not shared with this user any more: go on with the next project.
            if (e.response?.statusCode == 404) continue;
            error = e.toString();
            break;
          } on StateError catch (e) {
            error = e.message;
            break;
          }
        }
      }
      final leftover = await syncRepository.nextBatch(
        ignoreBackoff: true,
        max: 1,
      );
      final ok = (error == null) && leftover.isEmpty;
      if (!ok && error == null) {
        error = 'some changes were not sent';
      }
      result = SyncResult(
        ok: ok,
        pushed: pushed,
        pulled: pulled,
        bytes: transferCounter.bytes,
        finishedAt: DateTime.now(),
        error: error,
      );
      await syncState.setLastSyncBytes(result.bytes);
      if (result.ok) {
        await syncState.setLastSuccessfulSyncAt(result.finishedAt);
        await ref.read(lastSyncProvider.notifier).markSynced(result.finishedAt);
      }
      if (kDebugMode) {
        final log = Logger();
        log.d(
          'sync ok=${result.ok} pushed=${result.pushed} pulled=${result.pulled} bytes=${result.bytes}',
        );
      }
    } catch (e) {
      result = SyncResult(
        ok: false,
        pushed: pushed,
        pulled: pulled,
        bytes: transferCounter.bytes,
        finishedAt: DateTime.now(),
        error: e.toString(),
      );
    } finally {
      state = SyncRunState(running: false, last: result);
    }
    return result;
  }

  /// Pulls one project page by page from its saved cursor (0 if never pulled)
  /// until the server has no more. Each page is applied, and its cursor saved,
  /// before the next request, so an interrupted pull continues where it
  /// stopped. [onPage] gets the number of rows of each page. It throws instead
  /// of returning an error: a [DioException] as it came, and a [StateError] if
  /// a page says "more" but does not move the cursor.
  Future<void> _pullProject(
    String projectId, {
    CancelToken? cancelToken,
    void Function(int rows)? onPage,
  }) async {
    final syncApi = ref.read(syncApiProvider);
    final pullApplier = ref.read(pullApplierProvider);
    final syncState = ref.read(syncStateRepositoryProvider);
    var cursor = await syncState.lastPullCursor(projectId) ?? 0;
    while (true) {
      final page = await syncApi.pull(
        projectId,
        cursor,
        cancelToken: cancelToken,
      );
      await pullApplier.applyPage(projectId, page);
      onPage?.call(
        page.changes.values.fold<int>(0, (sum, rows) => sum + rows.length),
      );
      if (!page.hasMore) return;
      if (page.nextCursor <= cursor) {
        // A page that says "more" but does not move the cursor would be
        // requested for ever.
        throw StateError('pull of $projectId did not advance');
      }
      cursor = page.nextCursor;
    }
  }

  /// Downloads one project (T031): a pull from its saved cursor to the last
  /// page, then the project counts as downloaded. It never throws: a failure
  /// comes back as a [SyncResult] with `ok` false, and a cancel (see
  /// [cancelDownload]) with `cancelled` true.
  /// It waits for a run or download in progress and then goes; there is no
  /// await between that check and the start, so two downloads cannot overlap.
  /// While it goes, a manual [run] waits and then runs, and an automatic [run]
  /// joins it and is skipped until the next trigger. A download does not push
  /// and is not a sync run: it leaves the sync bookkeeping alone.
  Future<SyncResult> download(String projectId) async {
    while (_current != null) {
      await _current;
    }
    _currentIsManual = false;
    _cancelToken = CancelToken();
    final started = _download(projectId).whenComplete(() {
      _current = null;
      _cancelToken = null;
    });
    _current = started;
    return started;
  }

  Future<SyncResult> _download(String projectId) async {
    final syncState = ref.read(syncStateRepositoryProvider);
    var received = 0;
    var result = SyncResult(
      ok: false,
      pushed: 0,
      pulled: 0,
      bytes: 0,
      finishedAt: DateTime.now(),
      error: 'download did not finish',
    );
    state = SyncRunState(
      running: true,
      last: state.last,
      downloadingProjectId: projectId,
      received: 0,
    );
    try {
      await _pullProject(
        projectId,
        cancelToken: _cancelToken,
        onPage: (rows) {
          received += rows;
          state = SyncRunState(
            running: true,
            last: state.last,
            downloadingProjectId: projectId,
            received: received,
          );
        },
      );
      await syncState.setDownloaded(projectId);
      result = SyncResult(
        ok: true,
        pushed: 0,
        pulled: received,
        bytes: 0,
        finishedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      String? error;
      if (e.response?.statusCode == 404) {
        error = 'This project is no longer shared with you.';
      } else if (!CancelToken.isCancel(e)) {
        error = e.toString();
      }
      result = SyncResult(
        ok: false,
        pushed: 0,
        pulled: received,
        bytes: 0,
        finishedAt: DateTime.now(),
        error: error,
        cancelled: error == null,
      );
    } catch (e) {
      // A StateError from _pullProject, or anything else.
      result = SyncResult(
        ok: false,
        pushed: 0,
        pulled: received,
        bytes: 0,
        finishedAt: DateTime.now(),
        error: e.toString(),
      );
    } finally {
      state = SyncRunState(running: false, last: result);
    }
    return result;
  }

  /// Stops the download in progress. The saved cursor stays, so the next
  /// [download] of the project continues from there.
  void cancelDownload() {
    _cancelToken?.cancel();
  }
}

final syncRunnerProvider = NotifierProvider<SyncRunner, SyncRunState>(
  SyncRunner.new,
);
