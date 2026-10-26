import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Own visit count and last visit of a transect.
// TODO(T034): read the local survey_visit table. Until then there are no
// visits on the phone.
final transectVisitStatsProvider =
    StreamProvider.family<TransectVisitStats, String>(
      (ref, transectId) => Stream.value(const TransectVisitStats(count: 0)),
    );

/// Own visits of a transect, newest first.
// TODO(T034): read the local survey_visit table.
final transectVisitsProvider =
    StreamProvider.family<List<VisitSummary>, String>(
      (ref, transectId) => Stream.value(const []),
    );
