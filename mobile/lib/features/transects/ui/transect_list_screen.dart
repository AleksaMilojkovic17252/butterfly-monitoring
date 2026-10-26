import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:mobile/features/projects/domain/project_stats.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/transects/domain/visit_stats.dart';

/// The two orders of the list.
enum _Sort { code, distance }

/// One transect of the list with its distance from the phone, worked out once
/// per build so that filtering and sorting can use it.
class _TransectRow {
  const _TransectRow({required this.transect, required this.distanceM});
  final Transect transect;

  /// Metres to the nearest vertex of the line, or null without a position.
  final double? distanceM;
}

/// The project's transects on this phone, so a researcher can find the one
/// they are standing next to (outline §11.2 D). Search by name or code, sort
/// by code or by distance from the last known position.
class TransectListScreen extends ConsumerStatefulWidget {
  const TransectListScreen({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<TransectListScreen> createState() => _TransectListScreenState();
}

class _TransectListScreenState extends ConsumerState<TransectListScreen> {
  String _search = '';
  _Sort _sort = _Sort.code;

  /// A fix taken with the refresh button. It wins over the last known
  /// position, which Android may not have updated yet.
  Position? _freshPosition;
  bool _locating = false;

  /// Takes a new GPS fix for the distances.
  Future<void> _refreshPosition() async {
    setState(() => _locating = true);
    try {
      final position = await ref.read(currentPositionProvider)();
      if (!mounted) return;
      setState(() => _freshPosition = position);
      ref.invalidate(lastKnownPositionProvider);
    } on LocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_locationMessage(e.failure))));
    } on Exception {
      // Any other geolocator error: the list keeps the position it had.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get a location. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transects = ref.watch(projectTransectsProvider(widget.projectId));
    final position =
        _freshPosition ?? ref.watch(lastKnownPositionProvider).value;
    final downloaded =
        ref.watch(projectDownloadedProvider(widget.projectId)).value ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transects'),
        actions: [
          IconButton(
            tooltip: 'Update my location',
            onPressed: _locating ? null : _refreshPosition,
            icon: _locating
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch (transects) {
          AsyncData(:final value) => _content(value, position, downloaded),
          AsyncError(:final error) => Center(child: Text('$error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _content(
    List<Transect> transects,
    Position? position,
    bool downloaded,
  ) {
    if (transects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No transects on this phone. Download the project from the '
            'project list.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Distance of each transect from the position, or null without one.
    final here = position == null
        ? null
        : LatLng(position.latitude, position.longitude);
    final rows = [
      for (final t in transects)
        _TransectRow(
          transect: t,
          distanceM: here == null
              ? null
              : distanceToNearestVertexM(here, parseLineString(t.geometry)),
        ),
    ];

    final query = _search.trim().toLowerCase();
    final shown = rows
        .where(
          (r) =>
              query.isEmpty ||
              r.transect.code.toLowerCase().contains(query) ||
              r.transect.name.toLowerCase().contains(query),
        )
        .toList();
    if (_sort == _Sort.distance) {
      // Nearest first; transects without a distance go last, by code.
      shown.sort((first, second) {
        final firstDistance = first.distanceM;
        final secondDistance = second.distanceM;
        if (firstDistance == null && secondDistance == null) {
          return first.transect.code.compareTo(second.transect.code);
        }
        if (firstDistance == null) return 1;
        if (secondDistance == null) return -1;
        return firstDistance.compareTo(secondDistance);
      });
    }
    // Sorting by code needs nothing: the query already returns that order.

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name or code',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              const Text('Sort by'),
              const SizedBox(width: 12),
              SegmentedButton<_Sort>(
                segments: const [
                  ButtonSegment(value: _Sort.code, label: Text('Code')),
                  ButtonSegment(value: _Sort.distance, label: Text('Distance')),
                ],
                selected: {_sort},
                onSelectionChanged: (s) => setState(() => _sort = s.first),
              ),
            ],
          ),
        ),
        if (position == null)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'No location yet: tap the location button for distances.',
            ),
          ),
        Expanded(
          child: shown.isEmpty
              ? const Center(child: Text('No transect matches the search'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: shown.length,
                  itemBuilder: (context, i) => _TransectTile(
                    projectId: widget.projectId,
                    transect: shown[i].transect,
                    distanceM: shown[i].distanceM,
                    downloaded: downloaded,
                  ),
                ),
        ),
      ],
    );
  }
}

/// One transect in the list. Opens the transect detail.
class _TransectTile extends ConsumerWidget {
  const _TransectTile({
    required this.projectId,
    required this.transect,
    required this.distanceM,
    required this.downloaded,
  });
  final String projectId;
  final Transect transect;
  final double? distanceM;

  /// Whether the project's offline package is complete on this phone.
  final bool downloaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final stats = ref.watch(transectVisitStatsProvider(transect.id)).value;
    final visits = _visitsLabel(stats);

    return Card(
      child: ListTile(
        leading: Tooltip(
          message: downloaded ? 'Downloaded' : 'Download not finished',
          child: Icon(
            downloaded ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: downloaded ? scheme.primary : scheme.outline,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                '${transect.code} · ${transect.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!transect.active) ...[
              const SizedBox(width: 8),
              const _InactiveTag(),
            ],
          ],
        ),
        subtitle: Text(visits),
        trailing: Text(distanceM == null ? '—' : formatDistance(distanceM!)),
        onTap: () =>
            context.push('/projects/$projectId/transects/${transect.id}'),
      ),
    );
  }
}

/// Small "Inactive" label: the transect is no longer walked.
class _InactiveTag extends StatelessWidget {
  const _InactiveTag();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Inactive',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: scheme.onErrorContainer),
      ),
    );
  }
}

/// "No visits yet", "1 visit · last 26.10.2026." or "3 visits · last …". The
/// date is left out when the latest visit has none yet.
String _visitsLabel(TransectVisitStats? stats) {
  if (stats == null || stats.count == 0) return 'No visits yet';
  final count = stats.count == 1 ? '1 visit' : '${stats.count} visits';
  final last = stats.lastVisitAt;
  return last == null ? count : '$count · last ${_date(last)}';
}

String _locationMessage(LocationFailure failure) => switch (failure) {
  LocationFailure.serviceOff => 'Location is off. Turn it on in Android.',
  LocationFailure.denied => 'Location permission was not given.',
  LocationFailure.deniedForever =>
    'Location permission is blocked. Allow it in Android settings.',
  LocationFailure.unavailable => 'No GPS fix yet. Try again outside.',
};

/// Local date, "26.10.2026."
String _date(DateTime d) {
  final local = d.toLocal();
  return '${local.day}.${local.month}.${local.year}.';
}
