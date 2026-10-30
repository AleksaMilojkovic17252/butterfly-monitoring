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
  const VisitSummary({
    required this.id,
    required this.date,
    required this.status,
    required this.cancelReason,
  });

  final String id;

  /// When the visit started, or when it was created for a visit that never
  /// started (not conducted, T041). UTC; shown in local time.
  final DateTime date;
  final String status;

  /// Empty unless the visit is cancelled.
  final String cancelReason;
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

/// Own visits of a transect that have started or were cancelled, newest
/// first.
final transectVisitsProvider =
    StreamProvider.family<List<VisitSummary>, String>((ref, transectId) {
      final visits = ref
          .watch(visitRepositoryProvider)
          .watchListedVisits(transectId);
      return visits.map(
        (listedVisits) => [
          for (final visit in listedVisits)
            VisitSummary(
              id: visit.id,
              date: visit.startedAt ?? visit.createdAt,
              status: visit.status,
              cancelReason: visit.cancelReason,
            ),
        ],
      );
    });
