import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/visits/domain/walking_time.dart';
import 'package:mobile/features/visits/ui/widgets/header_figure.dart';

/// The walking time of the header, redrawn every second. Only this widget
/// ticks, so the map and the other figures are not rebuilt each second.
class WalkingTimeFigure extends StatefulWidget {
  const WalkingTimeFigure({super.key, required this.visit});
  final SurveyVisit visit;

  @override
  State<WalkingTimeFigure> createState() => _WalkingTimeFigureState();
}

class _WalkingTimeFigureState extends State<WalkingTimeFigure> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walked = walkingTime(widget.visit, DateTime.now().toUtc());
    return HeaderFigure(label: 'Time', value: formatWalkingTime(walked));
  }
}
