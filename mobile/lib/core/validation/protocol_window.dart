// W07, see docs/requirements/validation-rules.md
import 'package:mobile/core/db/app_database.dart';

// Season and daily time-window checks against the project protocol. They only
// warn: a visit outside the window is allowed (T033, and the start-visit form
// in T035).

/// "1.4.2026. – 30.9.2026."
String seasonLabel(ProjectProtocol protocol) =>
    '${_date(protocol.seasonStart)} – ${_date(protocol.seasonEnd)}';

/// "10:00–17:00"
String timeWindowLabel(ProjectProtocol protocol) =>
    '${_hhmm(protocol.dayStartTime)}–${_hhmm(protocol.dayEndTime)}';

/// A warning when [now] is outside the season, else null. Compared by local
/// calendar date; both season days count as inside.
String? seasonWarning(ProjectProtocol protocol, DateTime now) {
  final today = _day(now);
  if (today.isBefore(_day(protocol.seasonStart)) ||
      today.isAfter(_day(protocol.seasonEnd))) {
    return 'Outside the season (${seasonLabel(protocol)}).';
  }
  return null;
}

/// A warning when [now] is outside the daily time window, else null. The
/// protocol times are local wall-clock times (`HH:MM:SS`).
String? timeWindowWarning(ProjectProtocol protocol, DateTime now) {
  final local = now.toLocal();
  final minute = local.hour * 60 + local.minute;
  if (minute < _minuteOfDay(protocol.dayStartTime) ||
      minute > _minuteOfDay(protocol.dayEndTime)) {
    return 'Outside the daily time window (${timeWindowLabel(protocol)}).';
  }
  return null;
}

/// The local calendar day of [d], at midnight. `toLocal()` first, so a date
/// read back as UTC still gives the day it was stored as.
DateTime _day(DateTime d) {
  final local = d.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String _date(DateTime d) {
  final day = _day(d);
  return '${day.day}.${day.month}.${day.year}.';
}

/// "10:00:00" → "10:00"
String _hhmm(String time) => time.substring(0, 5);

/// "10:30:00" → 630
int _minuteOfDay(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}
