import 'package:mobile/core/db/app_database.dart';

/// How long [visit] has been walked at [now] (T039): the time since
/// `startedAt` without the stored `pausedSeconds` and without the pause that
/// is running now. Zero for a visit that has not started.
Duration walkingTime(SurveyVisit visit, DateTime now) {
  final startedAt = visit.startedAt;
  if (startedAt == null) return Duration.zero;
  var walked =
      now.difference(startedAt) - Duration(seconds: visit.pausedSeconds);
  final pausedAt = visit.pausedAt;
  if (pausedAt != null) walked -= now.difference(pausedAt);
  return walked.isNegative ? Duration.zero : walked;
}

/// [duration] as `m:ss`, or `h:mm:ss` from one hour.
String formatWalkingTime(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;
  if (hours == 0) return '$minutes:${two(seconds)}';
  return '$hours:${two(minutes)}:${two(seconds)}';
}
