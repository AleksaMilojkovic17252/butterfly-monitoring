import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/data/statistics_data.dart';
import 'package:mobile/features/statistics/domain/transect_indicators.dart';

/// The top species of a transect and year (T062): name, individuals and
/// records, most individuals first. Shows a line of text when it is empty.
class TopSpeciesList extends StatelessWidget {
  const TopSpeciesList({super.key, required this.top, required this.data});
  final List<SpeciesTotal> top;
  final StatisticsData data;

  @override
  Widget build(BuildContext context) {
    if (top.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No butterflies recorded'),
      );
    }
    return Card(
      child: Column(
        children: [
          for (var n = 0; n < top.length; n++)
            ListTile(
              dense: true,
              leading: Text('${n + 1}.'),
              title: Text(data.displayName(top[n].taxonId)),
              subtitle: Text(
                '${top[n].individuals} individuals · '
                '${top[n].records} ${top[n].records == 1 ? 'record' : 'records'}',
              ),
            ),
        ],
      ),
    );
  }
}
