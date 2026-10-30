import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/visit_values.dart';
import 'package:mobile/features/visits/domain/beaufort.dart';

/// The weather of a visit (T106): at the start and at the end, whether it was
/// suitable, the true-zero flag and the notes. A missing value shows "–".
class VisitWeatherCard extends StatelessWidget {
  const VisitWeatherCard({super.key, required this.visit});
  final SurveyVisit visit;

  /// "18 °C", or "–" when there is no value.
  String _temperature(double? celsius) =>
      celsius == null ? '–' : '${celsius.toStringAsFixed(1)} °C';

  /// "3 · Gentle breeze", or "–".
  String _wind(int? force) => force == null ? '–' : beaufortLabel(force);

  /// "40 %", or "–".
  String _cloud(int? percent) => percent == null ? '–' : '$percent %';

  /// Yes, no, or not checked for a flag that can be null.
  String _suitable(bool? suitable) => switch (suitable) {
    true => 'Yes',
    false => 'No',
    null => 'Not checked',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: const Text('At the start'),
            subtitle: Text(
              'Temperature ${_temperature(visit.temperatureStartC)}\n'
              'Wind ${_wind(visit.windBeaufortStart)}\n'
              'Cloud cover ${_cloud(visit.cloudCoverStartPct)}\n'
              'Precipitation ${precipitationLabel(visit.precipitation)}',
            ),
          ),
          ListTile(
            dense: true,
            title: const Text('At the end'),
            subtitle: Text(
              'Temperature ${_temperature(visit.temperatureEndC)}\n'
              'Wind ${_wind(visit.windBeaufortEnd)}\n'
              'Cloud cover ${_cloud(visit.cloudCoverEndPct)}',
            ),
          ),
          if (visit.weatherMissingReason.isNotEmpty)
            ListTile(
              dense: true,
              title: const Text('Weather not recorded because'),
              subtitle: Text(visit.weatherMissingReason),
            ),
          ListTile(
            dense: true,
            title: const Text('Weather suitable'),
            trailing: Text(_suitable(visit.weatherSuitable)),
          ),
          if (visit.zeroObservationConfirmed)
            const ListTile(
              dense: true,
              leading: Icon(Icons.check_circle_outline),
              title: Text('True zero confirmed'),
            ),
          if (visit.notes.isNotEmpty)
            ListTile(
              dense: true,
              title: const Text('Notes'),
              subtitle: Text(visit.notes),
            ),
        ],
      ),
    );
  }
}
