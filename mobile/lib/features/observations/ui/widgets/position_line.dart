import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/core/validation/observation_rules.dart';

/// The top line of the sheet: how accurate the position is, with a warning
/// above the limit, and the section the observer is in.
class PositionLine extends StatelessWidget {
  const PositionLine({
    super.key,
    required this.fix,
    required this.accuracyWarningM,
    required this.sectionCode,
  });
  final Position? fix;
  final double accuracyWarningM;
  final String? sectionCode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accuracyM = fix?.accuracy;
    final poor = isPoorAccuracy(accuracyM, accuracyWarningM); // W02
    final color = poor ? scheme.error : scheme.onSurfaceVariant;
    final text = accuracyM == null
        ? 'No GPS fix yet – Save will get one'
        : '± ${accuracyM.round()} m${poor ? ' · Low GPS accuracy' : ''}';
    return Row(
      children: [
        Icon(poor ? Icons.warning_amber : Icons.gps_fixed, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: color)),
        ),
        Text('Section ${sectionCode ?? '—'}'),
      ],
    );
  }
}
