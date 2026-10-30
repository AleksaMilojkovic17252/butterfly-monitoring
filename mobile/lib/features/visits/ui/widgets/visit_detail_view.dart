import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/ui/widgets/detail_section_title.dart';
import 'package:mobile/features/visits/domain/visit_route_stats.dart';
import 'package:mobile/features/visits/domain/visit_summary.dart';
import 'package:mobile/features/visits/domain/walking_time.dart';
import 'package:mobile/features/visits/ui/widgets/visit_detail_header.dart';
import 'package:mobile/features/visits/ui/widgets/visit_observation_list.dart';
import 'package:mobile/features/visits/ui/widgets/visit_route_map.dart';
import 'package:mobile/features/visits/ui/widgets/visit_summary_card.dart';
import 'package:mobile/features/visits/ui/widgets/visit_weather_card.dart';

/// The page of one visit that is on this phone, shown by `VisitDetailScreen`
/// (T106): header, summary, weather, map and the observations. Read-only.
class VisitDetailView extends ConsumerWidget {
  const VisitDetailView({super.key, required this.visit});
  final SurveyVisit visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transect = ref.watch(transectProvider(visit.transectId)).value;
    final observations =
        ref.watch(visitObservationsProvider(visit.id)).value ?? [];
    // Null when the route is not on this phone.
    final stats = ref.watch(visitRouteStatsProvider(visit.id));
    // A visit that never started ("not conducted") has nothing to summarise.
    final started = visit.startedAt != null;
    final coverage = stats?.coveragePct;
    // The time stored when the visit was finished or cancelled; a visit
    // without it (older rows) is worked out from its times.
    final storedSeconds = visit.durationSeconds;

    return Scaffold(
      appBar: AppBar(
        title: Text(transect == null ? 'Visit' : '${transect.code} · visit'),
      ),
      // The app bar covers the top; SafeArea keeps the list above the system
      // navigation buttons.
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            VisitDetailHeader(visit: visit, transect: transect),
            if (started) ...[
              const DetailSectionTitle('Summary'),
              VisitSummaryCard(
                walked: storedSeconds == null
                    ? walkingTime(visit, visit.endedAt ?? DateTime.now())
                    : Duration(seconds: storedSeconds),
                distanceM: stats?.distanceM ?? visit.distanceWalkedM,
                summary: VisitSummary.fromObservations(observations),
                // The list below already groups the observations by section.
                sectionCounts: const [],
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.route),
                  title: const Text('Route coverage'),
                  // Null when the route has too few usable points.
                  trailing: Text(
                    coverage == null ? '–' : '${coverage.floor()} %',
                  ),
                ),
              ),
            ],
            const DetailSectionTitle('Weather'),
            VisitWeatherCard(visit: visit),
            if (started) ...[
              const DetailSectionTitle('Map'),
              VisitRouteMap(visit: visit),
            ],
            const DetailSectionTitle('Observations'),
            VisitObservationList(visit: visit, observations: observations),
          ],
        ),
      ),
    );
  }
}
