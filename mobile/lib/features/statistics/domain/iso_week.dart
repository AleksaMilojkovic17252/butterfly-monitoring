/// The ISO 8601 year and week of a calendar date (T062). Dart has no ISO week.
/// Only the year, month and day of [date] are used, so pass the local date at
/// the study site. Week 1 is the week with the year's first Thursday.
({int isoYear, int week}) isoWeek(DateTime date) {
  // Work in UTC so a daylight saving change cannot shift the day count.
  final day = DateTime.utc(date.year, date.month, date.day);
  // The Thursday of this week decides the ISO year (Monday = 1 ... Sunday = 7).
  final thursday = day.add(Duration(days: 4 - day.weekday));
  final firstDay = DateTime.utc(thursday.year, 1, 1);
  final dayOfYear = thursday.difference(firstDay).inDays;
  return (isoYear: thursday.year, week: dayOfYear ~/ 7 + 1);
}
