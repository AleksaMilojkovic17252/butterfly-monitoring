import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/visits/ui/widgets/header_figure.dart';
import 'package:mobile/features/visits/ui/widgets/walking_time_figure.dart';

/// Walking time, distance, current section and observation count, in one
/// row of large figures.
class VisitHeader extends StatelessWidget {
  const VisitHeader({
    super.key,
    required this.visit,
    required this.distanceM,
    required this.sectionCode,
    required this.observations,
  });
  final SurveyVisit visit;
  final double distanceM;
  final String? sectionCode;
  final int observations;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: WalkingTimeFigure(visit: visit)),
            Expanded(
              child: HeaderFigure(
                label: 'Distance',
                value: formatDistance(distanceM),
              ),
            ),
            Expanded(
              child: HeaderFigure(label: 'Section', value: sectionCode ?? '—'),
            ),
            Expanded(
              child: HeaderFigure(
                label: 'Observations',
                value: '$observations',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
