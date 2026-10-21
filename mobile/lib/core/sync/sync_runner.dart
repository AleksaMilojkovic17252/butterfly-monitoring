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
}

/// What the UI watches:
/// whether a run is in progress,
/// and the result of the previous run (null before the first one).
class SyncRunState {
  SyncRunState({required this.running, this.last});
  final bool running;
  final SyncResult? last;
}

/// Runs the sync: pushes the queue, then pulls every local project. Only one
/// run goes at a time. The state tells the UI whether a run is in progress and
/// how the last one ended.
class SyncRunner extends Notifier<SyncRunState> {
  /// The run in progress, shared with anyone who calls [run] meanwhile.
  Future<SyncResult>? _current;

  /// Whether [_current] ignores the retry delays.
  var _currentIsManual = false;
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
    final pullApplier = ref.read(pullApplierProvider);
    final syncState = ref.read(syncStateRepositoryProvider);
    final projectRepository = ref.read(projectRepositoryProvider);
    final transferCounter = ref.read(transferCounterProvider);
    state = SyncRunState(running: true, last: state.last);
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
        for (final project in projects) {
          var cursor = await syncState.lastPullCursor(project.id) ?? 0;
          while (true) {
            final PullPage page;
            try {
              page = await syncApi.pull(project.id, cursor);
            } on DioException catch (e) {
              if (e.response?.statusCode == 404) {
                break;
              } else {
                error = e.toString();
                break;
              }
            }
            await pullApplier.applyPage(project.id, page);
            pulled += page.changes.values.fold<int>(
              0,
              ((sum, rows) => sum + rows.length),
            );
            if (!page.hasMore) break;
            if (page.nextCursor <= cursor) {
              // A page that says "more" but does not move the cursor would be
              // requested for ever.
              error = 'pull of ${project.id} did not advance';
              break;
            }
            cursor = page.nextCursor;
          }
          if (error != null) break;
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
}

final syncRunnerProvider = NotifierProvider<SyncRunner, SyncRunState>(
  SyncRunner.new,
);
