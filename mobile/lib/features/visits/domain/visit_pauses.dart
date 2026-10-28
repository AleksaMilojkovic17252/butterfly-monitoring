import 'dart:convert';

import 'package:mobile/core/db/app_database.dart';

/// One pause of a visit (T040, D-068): GPS was off from [startedAt] to
/// [endedAt]. Both are UTC.
class VisitPause {
  const VisitPause({required this.startedAt, required this.endedAt});
  final DateTime startedAt;
  final DateTime endedAt;

  /// The pause as the server's `pauses` list holds it.
  Map<String, String> toPayload() => {
    'started_at': startedAt.toUtc().toIso8601String(),
    'ended_at': endedAt.toUtc().toIso8601String(),
  };
}

/// Reads the `pauses` column (JSON text). Text that is not a list gives an
/// empty list, so one bad row cannot break the Finish screen (the same rule
/// as `parseLineString`). An item that is not a pause is skipped, not the
/// whole list: the list is sent back on Resume and Finish, and an empty one
/// would erase the good pauses on the server.
List<VisitPause> parsePauses(String json) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return [];
  }
  if (decoded is! List<dynamic>) return [];
  final pauses = <VisitPause>[];
  for (final item in decoded) {
    if (item is! Map<String, dynamic>) continue;
    final startedAt = DateTime.tryParse('${item['started_at']}');
    final endedAt = DateTime.tryParse('${item['ended_at']}');
    if (startedAt == null || endedAt == null) continue;
    pauses.add(
      VisitPause(startedAt: startedAt.toUtc(), endedAt: endedAt.toUtc()),
    );
  }
  return pauses;
}

/// [pauses] as the payload list of an `update`.
List<Map<String, String>> pausesPayload(List<VisitPause> pauses) => [
  for (final pause in pauses) pause.toPayload(),
];

/// [pauses] as the text for the `pauses` column.
String encodePauses(List<VisitPause> pauses) =>
    jsonEncode(pausesPayload(pauses));

/// The pause bookkeeping of [visit] after its running pause (if any) ends at
/// [now]: the total `pausedSeconds` and the `pauses` list. Resume and Finish
/// both use it, so they close a pause the same way. A visit that is not
/// paused gives its stored values.
({int pausedSeconds, List<VisitPause> pauses}) closePause(
  SurveyVisit visit,
  DateTime now,
) {
  final pauses = parsePauses(visit.pauses);
  final pausedAt = visit.pausedAt;
  if (pausedAt == null) {
    return (pausedSeconds: visit.pausedSeconds, pauses: pauses);
  }
  final seconds = now.difference(pausedAt).inSeconds;
  return (
    pausedSeconds: visit.pausedSeconds + (seconds < 0 ? 0 : seconds),
    pauses: [
      ...pauses,
      VisitPause(startedAt: pausedAt.toUtc(), endedAt: now.toUtc()),
    ],
  );
}
