import 'package:mobile/core/db/app_database.dart';

extension ProjectPeriod on Project {
  /// "1.4.2026. – 30.9.2026.", or "from 1.4.2026." for an open-ended project.
  String get periodLabel {
    final end = endDate;
    return end == null
        ? 'from ${_date(startDate)}'
        : '${_date(startDate)} – ${_date(end)}';
  }
}

String _date(DateTime d) => '${d.day}.${d.month}.${d.year}.';
