import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/validation/protocol_window.dart';
import 'package:mobile/features/statistics/data/statistics_data.dart';
import 'package:mobile/features/statistics/domain/iso_week.dart';
import 'package:mobile/features/statistics/domain/phenology.dart';
import 'package:mobile/features/statistics/domain/transect_indicators.dart';
import 'package:mobile/features/statistics/ui/widgets/indicator_table.dart';
import 'package:mobile/features/statistics/ui/widgets/phenology_chart.dart';
import 'package:mobile/features/statistics/ui/widgets/top_species_list.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';

/// Indicators for the researcher's own data, or the whole project's (T112), at
/// `/projects/:id/statistics`: per transect and year (visits, true zeros,
/// species, individuals, per km, per hour, top 10) and a weekly phenology chart
/// for one species. Same definitions as the server's T061 views (D-099, D-100).
/// Reads Drift only, so it works offline.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  // The user's picks. Null means "use the default".
  int? _year;
  String? _transectId;
  String? _taxonId;
  int? _isoYear;

  // "My records" or "Whole project" (T112). Kept here, so it resets when the
  // screen closes. The year, transect and species picks above stay as long as
  // they still exist in the new data.
  bool _wholeProject = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(
      statisticsDataProvider((
        projectId: widget.projectId,
        wholeProject: _wholeProject,
      )),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: SafeArea(
        top: false,
        child: data == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('My records')),
                      ButtonSegment(value: true, label: Text('Whole project')),
                    ],
                    selected: {_wholeProject},
                    onSelectionChanged: (selection) =>
                        setState(() => _wholeProject = selection.first),
                  ),
                  const SizedBox(height: 16),
                  ..._indicatorSection(context, data),
                  const SizedBox(height: 24),
                  ..._phenologySection(context, data),
                ],
              ),
      ),
    );
  }

  List<Widget> _indicatorSection(BuildContext context, StatisticsData data) {
    final years = indicatorYears(data.visits, data.timeZone);
    if (years.isEmpty) {
      return const [Text('No finished visits yet.')];
    }
    // Default: the current site year if it has data, else the newest year.
    final currentYear = siteTimeIn(data.timeZone, DateTime.now().toUtc()).year;
    final year = years.contains(_year)
        ? _year!
        : (years.contains(currentYear) ? currentYear : years.first);

    final withVisits = indicatorTransects(data.visits, year, data.timeZone);
    final transects = [
      for (final t
          in ref.watch(projectTransectsProvider(widget.projectId)).value ??
              const [])
        if (withVisits.contains(t.id)) t,
    ];
    if (transects.isEmpty) return const [Text('No finished visits yet.')];
    final transectId = transects.any((t) => t.id == _transectId)
        ? _transectId!
        : transects.first.id;

    final indicators = transectIndicators(
      visits: data.visits,
      records: data.records,
      transectId: transectId,
      year: year,
      timeZone: data.timeZone,
      scientificNames: data.scientificNames,
    );

    return [
      DropdownButtonFormField<int>(
        key: ValueKey('year-$year'),
        initialValue: year,
        decoration: const InputDecoration(labelText: 'Year'),
        items: [
          for (final y in years) DropdownMenuItem(value: y, child: Text('$y')),
        ],
        onChanged: (y) => setState(() => _year = y),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        key: ValueKey('transect-$transectId-$year'),
        initialValue: transectId,
        decoration: const InputDecoration(labelText: 'Transect'),
        items: [
          for (final t in transects)
            DropdownMenuItem(value: t.id, child: Text('${t.code} · ${t.name}')),
        ],
        onChanged: (id) => setState(() => _transectId = id),
      ),
      const SizedBox(height: 12),
      IndicatorTable(indicators: indicators),
      const SizedBox(height: 16),
      Text('Top species', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      TopSpeciesList(top: indicators.top, data: data),
    ];
  }

  List<Widget> _phenologySection(BuildContext context, StatisticsData data) {
    final title = Text(
      'Phenology',
      style: Theme.of(context).textTheme.titleLarge,
    );
    final names = data.scientificNames;
    final taxonIds = phenologyTaxa(data.phenologyRecords).toList()
      ..sort((a, b) => (names[a] ?? a).compareTo(names[b] ?? b));
    if (taxonIds.isEmpty) {
      return [title, const SizedBox(height: 8), const Text('No records yet.')];
    }
    final taxonId = taxonIds.contains(_taxonId) ? _taxonId! : taxonIds.first;

    final years = phenologyYears(data.phenologyRecords, data.timeZone);
    final currentYear = isoWeek(
      siteTimeIn(data.timeZone, DateTime.now().toUtc()),
    ).isoYear;
    final isoYear = years.contains(_isoYear)
        ? _isoYear!
        : (years.contains(currentYear) ? currentYear : years.first);

    final weeks = phenology(
      records: data.phenologyRecords,
      taxonId: taxonId,
      isoYear: isoYear,
      timeZone: data.timeZone,
    );
    var (first, last) = _seasonWeeks(data, isoYear);
    for (final w in weeks) {
      if (w.week < first) first = w.week;
      if (w.week > last) last = w.week;
    }

    return [
      title,
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        key: ValueKey('taxon-$taxonId'),
        initialValue: taxonId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Species'),
        items: [
          for (final id in taxonIds)
            DropdownMenuItem(
              value: id,
              child: Text(
                '${data.displayName(id)} · ${data.scientificNames[id] ?? ''}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (id) => setState(() => _taxonId = id),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        key: ValueKey('iso-year-$isoYear'),
        initialValue: isoYear,
        decoration: const InputDecoration(labelText: 'Year (ISO)'),
        items: [
          for (final y in years) DropdownMenuItem(value: y, child: Text('$y')),
        ],
        onChanged: (y) => setState(() => _isoYear = y),
      ),
      const SizedBox(height: 16),
      PhenologyChart(weeks: weeks, firstWeek: first, lastWeek: last),
    ];
  }

  /// The ISO weeks of the protocol's season start and end, placed in
  /// [isoYear]. A date that falls in a neighbouring ISO year (a season ending
  /// on 30 December is in week 1 of the next year) is clamped to the first or
  /// last week of [isoYear]. Without a protocol, the whole year.
  (int, int) _seasonWeeks(StatisticsData data, int isoYear) {
    final p = data.protocol;
    if (p == null) return (1, 52);
    // Season dates are stored at UTC midnight (D-094); take the day as sent.
    final start = p.seasonStart.toUtc();
    final end = p.seasonEnd.toUtc();
    final first = isoWeek(DateTime.utc(isoYear, start.month, start.day));
    final last = isoWeek(DateTime.utc(isoYear, end.month, end.day));
    // 28 December is always in the last ISO week of its year.
    final lastWeekOfYear = isoWeek(DateTime.utc(isoYear, 12, 28)).week;
    final firstWeek = first.isoYear < isoYear ? 1 : first.week;
    final lastWeek = last.isoYear > isoYear ? lastWeekOfYear : last.week;
    return firstWeek <= lastWeek ? (firstWeek, lastWeek) : (1, lastWeekOfYear);
  }
}
