import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/visit_values.dart';
import 'package:mobile/features/visits/domain/local_time.dart';
import 'package:mobile/features/visits/domain/visit_status.dart';

/// The top card of the visit detail (T106): transect, date, start and end,
/// observers and status. [transect] is null while it loads.
class VisitDetailHeader extends StatelessWidget {
  const VisitDetailHeader({
    super.key,
    required this.visit,
    required this.transect,
  });
  final SurveyVisit visit;
  final Transect? transect;

  @override
  Widget build(BuildContext context) {
    final startedAt = visit.startedAt;
    final endedAt = visit.endedAt;
    final t = transect;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.route_outlined),
            title: Text(t == null ? 'Transect' : '${t.code} · ${t.name}'),
          ),
          ListTile(
            leading: const Icon(Icons.event_outlined),
            // A visit that never started is dated by when it was created.
            title: Text(formatLocalDateTime(startedAt ?? visit.createdAt)),
            subtitle: Text(
              startedAt == null
                  ? 'Never started'
                  : 'Until ${endedAt == null ? '–' : formatLocalTime(endedAt)}',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: Text('Observers: ${visit.observerCount}'),
            subtitle: visit.observerNames.isEmpty
                ? null
                : Text(visit.observerNames),
          ),
          ListTile(
            // A locked visit is read-only (T042).
            leading: Icon(
              visitIsLocked(visit.status)
                  ? Icons.lock_outline
                  : Icons.info_outline,
            ),
            title: Text(visitStatusLabel(visit.status)),
            subtitle: visit.status == 'cancelled'
                ? Text(cancelReasonLabel(visit.cancelReason))
                : null,
          ),
        ],
      ),
    );
  }
}
