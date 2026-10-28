import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/transects/domain/visit_stats.dart';
import 'package:mobile/features/transects/ui/widgets/inactive_tag.dart';

/// One transect in the transect list. Opens the transect detail.
class TransectTile extends ConsumerWidget {
  const TransectTile({
    super.key,
    required this.projectId,
    required this.transect,
    required this.distanceM,
    required this.downloaded,
  });
  final String projectId;
  final Transect transect;
  final double? distanceM;

  /// Whether the project's offline package is complete on this phone.
  final bool downloaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final stats = ref.watch(transectVisitStatsProvider(transect.id)).value;
    final visits = _visitsLabel(stats);

    return Card(
      child: ListTile(
        leading: Tooltip(
          message: downloaded ? 'Downloaded' : 'Download not finished',
          child: Icon(
            downloaded ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: downloaded ? scheme.primary : scheme.outline,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                '${transect.code} · ${transect.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!transect.active) ...[
              const SizedBox(width: 8),
              const InactiveTag(),
            ],
          ],
        ),
        subtitle: Text(visits),
        trailing: Text(distanceM == null ? '—' : formatDistance(distanceM!)),
        onTap: () =>
            context.push('/projects/$projectId/transects/${transect.id}'),
      ),
    );
  }
}

/// "No visits yet", "1 visit · last 26.10.2026." or "3 visits · last …". The
/// date is left out when the latest visit has none yet.
String _visitsLabel(TransectVisitStats? stats) {
  if (stats == null || stats.count == 0) return 'No visits yet';
  final count = stats.count == 1 ? '1 visit' : '${stats.count} visits';
  final last = stats.lastVisitAt;
  return last == null ? count : '$count · last ${_date(last)}';
}

/// Local date, "26.10.2026."
String _date(DateTime d) {
  final local = d.toLocal();
  return '${local.day}.${local.month}.${local.year}.';
}
