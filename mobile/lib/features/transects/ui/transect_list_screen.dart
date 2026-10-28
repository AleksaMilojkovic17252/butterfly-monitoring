import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/core/location/location_provider.dart';
import 'package:mobile/features/projects/domain/project_stats.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/transects/ui/widgets/transect_tile.dart';

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
                  itemBuilder: (context, i) => TransectTile(
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

String _locationMessage(LocationFailure failure) => switch (failure) {
  LocationFailure.serviceOff => 'Location is off. Turn it on in Android.',
  LocationFailure.denied => 'Location permission was not given.',
  LocationFailure.deniedForever =>
    'Location permission is blocked. Allow it in Android settings.',
  LocationFailure.unavailable => 'No GPS fix yet. Try again outside.',
};
