/// Local date and time, "26.10.2026. 10:05". Times are UTC in the database
/// and local only in the UI.
String formatLocalDateTime(DateTime d) {
  final l = d.toLocal();
  return '${l.day}.${l.month}.${l.year}. ${formatLocalTime(l)}';
}

/// Local time of day, "10:05".
String formatLocalTime(DateTime d) {
  final l = d.toLocal();
  final mm = l.minute.toString().padLeft(2, '0');
  return '${l.hour}:$mm';
}
