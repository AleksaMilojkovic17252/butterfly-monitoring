// W07, see docs/requirements/validation-rules.md
import 'package:mobile/core/db/app_database.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// Season and daily time-window checks against the project protocol. They only
// warn: a visit outside the window is allowed (T033, and the start-visit form
// in T035). The season and the window are wall-clock times at the study site,
// so the instant is converted to the protocol's time zone first (T104).

/// "1.4.2026. - 30.9.2026."
String seasonLabel(ProjectProtocol protocol) =>
    '${_date(protocol.seasonStart)} - ${_date(protocol.seasonEnd)}';

/// "10:00–17:00"
String timeWindowLabel(ProjectProtocol protocol) =>
    '${_hhmm(protocol.dayStartTime)} - ${_hhmm(protocol.dayEndTime)}';

/// A warning when [now] is outside the season, else null. Compared by the
/// calendar date at the study site; both season days count as inside.
String? seasonWarning(ProjectProtocol protocol, DateTime now) {
  final site = _siteTime(protocol, now);
  final today = DateTime.utc(site.year, site.month, site.day);
  if (today.isBefore(_seasonDay(protocol.seasonStart)) ||
      today.isAfter(_seasonDay(protocol.seasonEnd))) {
    return 'Outside the season (${seasonLabel(protocol)}).';
  }
  return null;
}

/// A warning when [now] is outside the daily time window, else null. The
/// protocol times are wall-clock times (`HH:MM:SS`) at the study site.
String? timeWindowWarning(ProjectProtocol protocol, DateTime now) {
  final site = _siteTime(protocol, now);
  final minute = site.hour * 60 + site.minute;
  if (minute < _minuteOfDay(protocol.dayStartTime) ||
      minute > _minuteOfDay(protocol.dayEndTime)) {
    return 'Outside the daily time window (${timeWindowLabel(protocol)}).';
  }
  return null;
}

bool _zonesLoaded = false;

/// Loads the zone data once. Called before every lookup, so no caller has to
/// remember to initialise it.
void _loadZones() {
  if (!_zonesLoaded) {
    tz_data.initializeTimeZones();
    _zonesLoaded = true;
  }
}

/// Whether this phone knows the protocol's zone name. When it does not, the
/// season and window checks use the phone's own zone instead (T104).
bool timeZoneKnown(ProjectProtocol protocol) {
  _loadZones();
  try {
    tz.getLocation(protocol.timeZone);
    return true;
  } on tz.LocationNotFoundException {
    return false;
  }
}

/// [instant] as wall-clock time at the study site. An unknown zone name falls
/// back to the phone's zone.
DateTime _siteTime(ProjectProtocol protocol, DateTime instant) =>
    siteTimeIn(protocol.timeZone, instant);

/// [instant] as wall-clock time in the zone named [timeZone] (T062 uses it for
/// the year and week of a record). An unknown zone name falls back to the
/// phone's zone. It loads the zone data itself.
DateTime siteTimeIn(String timeZone, DateTime instant) {
  _loadZones();
  try {
    return tz.TZDateTime.from(instant, tz.getLocation(timeZone));
  } on tz.LocationNotFoundException {
    return instant.toLocal();
  }
}

/// The calendar day of a stored season date, at UTC midnight. Season dates are
/// stored as UTC midnight, so the UTC fields are the day the server sent.
DateTime _seasonDay(DateTime d) {
  final utc = d.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

String _date(DateTime d) {
  final day = _seasonDay(d);
  return '${day.day}.${day.month}.${day.year}.';
}

/// "10:00:00" → "10:00"
String _hhmm(String time) => time.substring(0, 5);

/// "10:30:00" → 630
int _minuteOfDay(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}
