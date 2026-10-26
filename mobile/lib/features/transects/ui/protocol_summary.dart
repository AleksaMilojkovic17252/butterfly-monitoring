import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/transects/domain/protocol_window.dart';

/// The parts of the project protocol a researcher checks before a visit:
/// season, daily time window and weather thresholds. Shown on the transect
/// detail (T033) and again by the start-visit form's confirmation (T035).
class ProtocolSummary extends StatelessWidget {
  const ProtocolSummary({super.key, required this.protocol});
  final ProjectProtocol protocol;

  @override
  Widget build(BuildContext context) {
    final p = protocol;
    return Column(
      children: [
        _Line(Icons.date_range_outlined, 'Season ${seasonLabel(p)}'),
        _Line(Icons.schedule, 'Daily window ${timeWindowLabel(p)}'),
        _Line(
          Icons.thermostat_outlined,
          '≥ ${_number(p.minTemperatureC)} °C with ≤ '
          '${p.maxCloudCoverPctIfCool} % cloud, or '
          '≥ ${_number(p.sunnyTemperatureC)} °C with any cloud',
        ),
        _Line(Icons.air, 'Wind ≤ ${p.maxWindBeaufort} Bft'),
        _Line(
          Icons.water_drop_outlined,
          p.allowPrecipitation ? 'Rain allowed' : 'No rain',
        ),
      ],
    );
  }
}

/// One row of the summary: an icon and a sentence.
class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(dense: true, leading: Icon(icon), title: Text(text));
  }
}

/// 13.0 → "13", 13.5 → "13.5"
String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
