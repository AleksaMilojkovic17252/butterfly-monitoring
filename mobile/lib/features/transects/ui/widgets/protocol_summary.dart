import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/validation/protocol_window.dart';
import 'package:mobile/features/transects/ui/widgets/protocol_summary_line.dart';

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
        ProtocolSummaryLine(
          Icons.date_range_outlined,
          'Season ${seasonLabel(p)}',
        ),
        ProtocolSummaryLine(
          Icons.schedule,
          'Daily window ${timeWindowLabel(p)}',
        ),
        ProtocolSummaryLine(
          Icons.thermostat_outlined,
          '≥ ${_number(p.minTemperatureC)} °C with ≤ '
          '${p.maxCloudCoverPctIfCool} % cloud, or '
          '≥ ${_number(p.sunnyTemperatureC)} °C with any cloud',
        ),
        ProtocolSummaryLine(Icons.air, 'Wind ≤ ${p.maxWindBeaufort} Bft'),
        ProtocolSummaryLine(
          Icons.water_drop_outlined,
          p.allowPrecipitation ? 'Rain allowed' : 'No rain',
        ),
      ],
    );
  }
}

/// 13.0 → "13", 13.5 → "13.5"
String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
