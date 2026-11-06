import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/phenology.dart';

/// A bar chart of individuals per ISO week (T062). The x axis runs from
/// [firstWeek] to [lastWeek]; weeks without records get no bar. Touching a bar
/// shows the week, the individuals and the records.
class PhenologyChart extends StatelessWidget {
  const PhenologyChart({
    super.key,
    required this.weeks,
    required this.firstWeek,
    required this.lastWeek,
  });

  final List<WeekCount> weeks;
  final int firstWeek;
  final int lastWeek;

  @override
  Widget build(BuildContext context) {
    final byWeek = {for (final w in weeks) w.week: w};
    final color = Theme.of(context).colorScheme.primary;
    final maxValue = weeks.fold<int>(
      0,
      (m, w) => w.individuals > m ? w.individuals : m,
    );
    // Label every 2nd week up to 30 weeks, else every 4th.
    final step = (lastWeek - firstWeek) > 30 ? 4 : 2;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxValue < 4 ? 4 : maxValue * 1.15,
          barGroups: [
            for (var week = firstWeek; week <= lastWeek; week++)
              BarChartGroupData(
                x: week,
                barRods: [
                  BarChartRodData(
                    toY: (byWeek[week]?.individuals ?? 0).toDouble(),
                    color: color,
                    width: 6,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
          ],
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              axisNameWidget: const Text('Individuals'),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  if (value != value.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text('${value.toInt()}'),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text('ISO week'),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final week = value.toInt();
                  if ((week - firstWeek) % step != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(meta: meta, child: Text('$week'));
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final w = byWeek[group.x];
                if (w == null) return null;
                return BarTooltipItem(
                  'Week ${w.week}: ${w.individuals} individuals, '
                  '${w.records} ${w.records == 1 ? 'record' : 'records'}',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
