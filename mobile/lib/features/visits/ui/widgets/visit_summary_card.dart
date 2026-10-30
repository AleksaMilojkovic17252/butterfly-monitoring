import 'package:flutter/material.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/visits/domain/visit_summary.dart';
import 'package:mobile/features/visits/domain/walking_time.dart';

/// The top of the Finish screen (T040): how long the walk took, how far, what
/// was seen and how many observations each section has.
class VisitSummaryCard extends StatelessWidget {
  const VisitSummaryCard({
    super.key,
    required this.walked,
    required this.distanceM,
    required this.summary,
    required this.sectionCounts,
  });

  /// Walking time without pauses.
  final Duration walked;

  /// Null when the distance is not known on this phone.
  final double? distanceM;
  final VisitSummary summary;

  /// Section code and its number of observations, in walking order. The last
  /// entry is "No section" when some observations have none.
  final List<(String, int)> sectionCounts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Walking time'),
            trailing: Text(formatWalkingTime(walked)),
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Distance'),
            trailing: Text(
              distanceM == null ? '–' : formatDistance(distanceM!),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Species'),
            trailing: Text('${summary.speciesCount}'),
          ),
          ListTile(
            leading: const Icon(Icons.numbers),
            title: const Text('Individuals'),
            subtitle: Text('${summary.observationCount} observations'),
            trailing: Text('${summary.individuals}'),
          ),
          if (sectionCounts.isNotEmpty) const Divider(),
          for (final (label, count) in sectionCounts)
            ListTile(dense: true, title: Text(label), trailing: Text('$count')),
        ],
      ),
    );
  }
}
