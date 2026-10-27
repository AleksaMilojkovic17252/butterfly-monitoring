import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';

/// The caller's own visits of one transect, as the transect list shows them.
class TransectVisitStats {
  const TransectVisitStats({required this.count, this.lastVisitAt});
  final int count;

  /// Start of the latest visit (UTC), or null without visits.
  final DateTime? lastVisitAt;
}

/// One of the caller's visits, as the transect detail lists them.
class VisitSummary {
  const VisitSummary({required this.startedAt, required this.status});

  /// UTC; shown in local time.
  final DateTime startedAt;
  final String status;
}

/// Own visit count and last visit of a transect, from the local
/// `survey_visit` table. Drafts and cancelled visits do not count
/// ([VisitRepository.countedStatuses]), the same rule as the server's
/// `visit_count`.
final transectVisitStatsProvider =
    StreamProvider.family<TransectVisitStats, String>((ref, transectId) {
      final visits = ref
          .watch(visitRepositoryProvider)
          .watchCountedVisits(transectId);
      return visits.map((countedVisits) {
        DateTime? lastVisitAt;
        for (final visit in countedVisits) {
          final startedAt = visit.startedAt;
          if (startedAt != null &&
              (lastVisitAt == null || startedAt.isAfter(lastVisitAt))) {
            lastVisitAt = startedAt;
          }
        }
        return TransectVisitStats(
          count: countedVisits.length,
          lastVisitAt: lastVisitAt,
        );
      });
    });

/// Own visits of a transect that have started, newest first.
final transectVisitsProvider =
    StreamProvider.family<List<VisitSummary>, String>((ref, transectId) {
      final visits = ref
          .watch(visitRepositoryProvider)
          .watchStartedVisits(transectId);
      return visits.map(
        (startedVisits) => [
          for (final visit in startedVisits)
            VisitSummary(startedAt: visit.startedAt!, status: visit.status),
        ],
      );
    });
