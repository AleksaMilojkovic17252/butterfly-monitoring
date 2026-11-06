import 'package:flutter/material.dart';
import 'package:mobile/features/statistics/domain/transect_indicators.dart';

/// The figures of one transect and year as label and value rows (T062). A
/// per-km or per-hour figure that cannot be computed shows "–".
class IndicatorTable extends StatelessWidget {
  const IndicatorTable({super.key, required this.indicators});
  final TransectIndicators indicators;

  @override
  Widget build(BuildContext context) {
    final i = indicators;
    final rows = <(String, String)>[
      ('Visits', '${i.visits}'),
      ('True-zero visits', '${i.trueZeroVisits}'),
      ('Species', '${i.speciesCount}'),
      ('Individuals', '${i.individuals}'),
      ('Hours walked', i.hours.toStringAsFixed(2)),
      ('Km walked', i.km.toStringAsFixed(2)),
      ('Individuals per km', i.perKm?.toStringAsFixed(2) ?? '–'),
      ('Individuals per hour', i.perHour?.toStringAsFixed(2) ?? '–'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label),
                    Text(value, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
