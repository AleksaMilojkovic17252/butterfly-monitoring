import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/db/app_database.dart';
import 'package:mobile/features/map/domain/map_filter.dart';
import 'package:mobile/features/map/domain/map_layers.dart';
import 'package:mobile/features/map/domain/map_taxa.dart';
import 'package:mobile/features/map/ui/map_popups.dart';
import 'package:mobile/features/observations/data/observation_repository.dart';
import 'package:mobile/features/observations/data/photo_repository.dart';
import 'package:mobile/features/observations/ui/free_observation_entry.dart';
import 'package:mobile/features/resources/data/habitat_repository.dart';
import 'package:mobile/features/resources/data/plant_repository.dart';
import 'package:mobile/features/resources/domain/habitat_names.dart';
import 'package:mobile/core/geo/polygon_math.dart';
import 'package:mobile/features/resources/domain/plant_taxon_search.dart';
import 'package:mobile/features/transects/data/transect_repository.dart';
import 'package:mobile/features/transects/domain/geo_line.dart';
import 'package:mobile/features/transects/domain/section_with_habitat.dart';
import 'package:mobile/features/transects/ui/widgets/transect_map.dart';
import 'package:mobile/features/visits/data/track_point_repository.dart';
import 'package:mobile/features/visits/data/visit_repository.dart';

/// The map of the project map screen (T059): transects, sections, the
/// observations as clusters, the user's plant records (T052: green markers for
/// points, filled areas for patches), the user's habitat features (T054: brown
/// markers, lines and areas), the route of the visit chosen in the filters and
/// the OpenStreetMap basemap, each as a layer that can be switched off.
///
/// It is a stateful widget for three things that must survive a rebuild: the
/// camera fit (computed once, so a filter never moves the map), the hit
/// notifier that tells which line was tapped, and the memos of the markers and
/// lines (see [_markersFor]).
class ProjectMapView extends ConsumerStatefulWidget {
  const ProjectMapView({super.key, required this.projectId});
  final String projectId;

  @override
  ConsumerState<ProjectMapView> createState() => _ProjectMapViewState();
}

class _ProjectMapViewState extends ConsumerState<ProjectMapView> {
  /// Where the camera starts. Set once, when the first data is there.
  CameraFit? _fit;

  /// Filled by the polyline layer with the lines under the last pointer-down.
  final LayerHitNotifier<Object> _hits = ValueNotifier(null);

  /// The same for the plant patches and habitat areas, which share a polygon
  /// layer of their own: a polygon layer and a polyline layer cannot share one
  /// notifier, and two polygon layers cannot either.
  final LayerHitNotifier<Object> _polygonHits = ValueNotifier(null);

  // Memo of the plant markers and patches, by the same idea as the markers
  // below. Filters do not apply to plants (D-081).
  List<PlantResourceObservation>? _plantsSource;
  List<Marker> _plantMarkers = const [];
  Map<String, PlantResourceObservation> _plantsById = const {};
  List<Polygon<Object>> _plantPolygons = const [];

  // Memo of the habitat markers, lines and areas, the same way (T054).
  List<HabitatFeature>? _habitatsSource;
  List<Marker> _habitatMarkers = const [];
  Map<String, HabitatFeature> _habitatsById = const {};
  List<Polygon<Object>> _habitatPolygons = const [];
  List<Polyline<Object>> _habitatLines = const [];

  // Memo of the markers. The cluster layer builds its whole cluster tree again
  // whenever it gets a different list instance, which is slow with thousands
  // of markers. So a new list is built only when the filtered observations are
  // a different list than last time (`identical`); a rebuild for any other
  // reason (a layer switch, a sheet) hands over the same list.
  List<ButterflyObservation>? _markersSource;
  List<Marker> _markers = const [];
  Map<String, ButterflyObservation> _observationsById = const {};

  /// The species of the observations, by id, for the popup. Watched in
  /// `build`, which keeps the query alive while the map is open (a one-off
  /// read of an `autoDispose` provider is disposed before it has a value).
  Map<String, Taxon> _taxaById = const {};

  // Memo of the parsed transect and section lines, by the same idea.
  List<Transect>? _transectsSource;
  List<SectionWithHabitat>? _sectionsSource;
  List<Polyline<Object>> _transectLines = const [];
  List<Polyline<Object>> _sectionLines = const [];

  // Memo of the route points of the chosen visit as map points.
  List<SurveyTrackPoint>? _routeSource;
  List<LatLng> _routePoints = const [];

  @override
  void dispose() {
    _hits.dispose();
    _polygonHits.dispose();
    super.dispose();
  }

  /// The markers of [observations]; the same list as last time when
  /// [observations] is the same instance.
  List<Marker> _markersFor(List<ButterflyObservation> observations) {
    if (!identical(observations, _markersSource)) {
      _markersSource = observations;
      _observationsById = {for (final o in observations) o.id: o};
      _markers = [
        for (final o in observations)
          Marker(
            // The key is how a tap finds the observation again.
            key: ValueKey(o.id),
            point: LatLng(o.lat, o.lon),
            width: 24,
            height: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ];
    }
    return _markers;
  }

  /// The green markers of the point records and the patches of the polygon
  /// records. Built again only when [plants] is a different list than last
  /// time.
  void _updatePlants(List<PlantResourceObservation> plants) {
    if (identical(plants, _plantsSource)) return;
    _plantsSource = plants;
    final markers = <Marker>[];
    final polygons = <Polygon<Object>>[];
    _plantsById = {for (final record in plants) record.id: record};
    for (final record in plants) {
      final shape = parseGeometry(record.geometryGeojson);
      if (shape == null) continue;
      if (shape.type == 'Polygon') {
        // flutter_map asserts on a polygon with fewer than 3 points.
        if (shape.points.length < 3) continue;
        polygons.add(
          Polygon<Object>(
            points: shape.points,
            color: Colors.green.withValues(alpha: 0.3),
            borderColor: Colors.green.shade800,
            borderStrokeWidth: 2,
            hitValue: record,
          ),
        );
      } else {
        markers.add(
          Marker(
            // The key is how a tap finds the record again (as for butterflies).
            key: ValueKey(record.id),
            point: shape.points.first,
            width: 28,
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.local_florist,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    }
    _plantMarkers = markers;
    _plantPolygons = polygons;
  }

  /// The brown markers of the point features, the lines of the line features
  /// and the areas of the polygon features. Built again only when [habitats]
  /// is a different list than last time. A shape with too few points for
  /// flutter_map (a line under 2, a polygon under 3) is left out, because the
  /// layers assert on it.
  void _updateHabitats(List<HabitatFeature> habitats) {
    if (identical(habitats, _habitatsSource)) return;
    _habitatsSource = habitats;
    final markers = <Marker>[];
    final polygons = <Polygon<Object>>[];
    final lines = <Polyline<Object>>[];
    _habitatsById = {for (final feature in habitats) feature.id: feature};
    for (final feature in habitats) {
      final shape = parseGeometry(feature.geometryGeojson);
      if (shape == null) continue;
      switch (shape.type) {
        case 'Polygon':
          if (shape.points.length < 3) continue;
          polygons.add(
            Polygon<Object>(
              points: shape.points,
              color: Colors.brown.withValues(alpha: 0.3),
              borderColor: Colors.brown.shade800,
              borderStrokeWidth: 2,
              hitValue: feature,
            ),
          );
        case 'LineString':
          if (shape.points.length < 2) continue;
          lines.add(
            Polyline<Object>(
              points: shape.points,
              strokeWidth: 5,
              color: Colors.brown.shade600,
              hitValue: feature,
            ),
          );
        default:
          markers.add(
            Marker(
              // The key is how a tap finds the feature again.
              key: ValueKey(feature.id),
              point: shape.points.first,
              width: 28,
              height: 28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.brown.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.terrain, size: 16, color: Colors.white),
              ),
            ),
          );
      }
    }
    _habitatMarkers = markers;
    _habitatPolygons = polygons;
    _habitatLines = lines;
  }

  /// Parses the transect and section lines again only when the lists changed.
  void _updateLines(List<Transect> transects, List<SectionWithHabitat> all) {
    if (identical(transects, _transectsSource) &&
        identical(all, _sectionsSource)) {
      return;
    }
    _transectsSource = transects;
    _sectionsSource = all;
    _transectLines = [
      for (final t in transects)
        ...() {
          final points = parseLineString(t.geometry);
          // flutter_map asserts on a line with fewer than 2 points.
          if (points.length < 2) return <Polyline<Object>>[];
          return [
            Polyline<Object>(
              points: points,
              strokeWidth: 10,
              color: Colors.grey.withValues(alpha: 0.6),
              hitValue: t,
            ),
          ];
        }(),
    ];
    // Sections are coloured by their position in their own transect, as in
    // the transect map. `all` is ordered by transect code, then walking order.
    final indexInTransect = <String, int>{};
    _sectionLines = [
      for (final entry in all)
        ...() {
          final index = indexInTransect.update(
            entry.section.transectId,
            (i) => i + 1,
            ifAbsent: () => 0,
          );
          final points = parseLineString(entry.section.geometry);
          if (points.length < 2) return <Polyline<Object>>[];
          return [
            Polyline<Object>(
              points: points,
              strokeWidth: 4,
              color: sectionColor(index),
              hitValue: entry,
            ),
          ];
        }(),
    ];
  }

  /// The camera that shows every transect, section and observation. The lines
  /// are the parsed ones from [_updateLines], so nothing is parsed twice.
  CameraFit? _computeFit(
    List<ButterflyObservation> observations,
    List<PlantResourceObservation> plants,
    List<HabitatFeature> habitats,
  ) {
    final points = [
      for (final line in _transectLines) ...line.points,
      for (final line in _sectionLines) ...line.points,
      for (final o in observations) LatLng(o.lat, o.lon),
      // The centre of a patch is enough for the camera.
      for (final p in plants) LatLng(p.lat, p.lon),
      for (final h in habitats) LatLng(h.lat, h.lon),
    ];
    if (points.isEmpty) return null;
    return CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: const EdgeInsets.all(32),
      maxZoom: 18,
    );
  }

  /// The route as map points; the same list as last time when [points] is the
  /// same instance, so a rebuild does not convert thousands of points again.
  List<LatLng> _routeFor(List<SurveyTrackPoint> points) {
    if (!identical(points, _routeSource)) {
      _routeSource = points;
      _routePoints = [for (final p in points) LatLng(p.lat, p.lon)];
    }
    return _routePoints;
  }

  /// A tap on a line: the topmost line under the finger gets its popup.
  void _onLineTap(List<Transect> transects) {
    // `hitValues` is ordered top to bottom, so the first is the top line.
    final hit = _hits.value?.hitValues.firstOrNull;
    if (hit == null) return;
    Transect? transectById(String id) =>
        transects.where((t) => t.id == id).firstOrNull;

    switch (hit) {
      case Transect():
        showTransectPopup(context, hit);
      case SectionWithHabitat():
        final transect = transectById(hit.section.transectId);
        if (transect != null) {
          showSectionPopup(context, entry: hit, transect: transect);
        }
      case SurveyVisit():
        showRoutePopup(
          context,
          visit: hit,
          transect: transectById(hit.transectId),
        );
      case HabitatFeature():
        _onHabitatTap(hit);
    }
  }

  /// A tap on a single plant marker (not a cluster).
  void _onPlantMarkerTap(Marker marker) {
    final key = marker.key;
    if (key is! ValueKey<String>) return;
    final record = _plantsById[key.value];
    if (record != null) _onPlantTap(record);
  }

  /// A tap on a single habitat marker (not a cluster).
  void _onHabitatMarkerTap(Marker marker) {
    final key = marker.key;
    if (key is! ValueKey<String>) return;
    final feature = _habitatsById[key.value];
    if (feature != null) _onHabitatTap(feature);
  }

  /// A tap on a plant patch or habitat area: the topmost one under the finger
  /// gets its popup.
  void _onPolygonTap() {
    final hit = _polygonHits.value?.hitValues.firstOrNull;
    if (hit is PlantResourceObservation) {
      _onPlantTap(hit);
    } else if (hit is HabitatFeature) {
      _onHabitatTap(hit);
    }
  }

  /// A tap on a habitat marker, line or area: its popup, with the names of its
  /// habitat and management type (read once, deactivated types included).
  Future<void> _onHabitatTap(HabitatFeature feature) async {
    final repository = ref.read(habitatRepositoryProvider);
    final habitatTypes = await repository.watchHabitatTypes().first;
    final managementTypes = await repository.watchManagementTypes().first;
    if (!mounted) return;
    final habitat = habitatTypes
        .where((t) => t.id == feature.habitatTypeId)
        .firstOrNull;
    final managementId = feature.managementTypeId;
    final management = managementId == null
        ? null
        : managementTypes.where((t) => t.id == managementId).firstOrNull;
    showHabitatPopup(
      context,
      record: feature,
      habitatName: habitat == null ? null : habitatTypeTitle(habitat),
      managementName: management == null
          ? null
          : managementTypeTitle(management),
    );
  }

  /// A tap on a plant marker or patch: its popup, with the primary photo and
  /// the plant's name (read once).
  Future<void> _onPlantTap(PlantResourceObservation record) async {
    final repository = ref.read(plantRepositoryProvider);
    final taxonId = record.plantTaxonId;
    final taxa = taxonId == null
        ? const <PlantTaxon>[]
        : await repository.watchPlantTaxaByIds([taxonId]).first;
    final photos = await ref
        .read(photoRepositoryProvider)
        .watchPhotos(record.id)
        .first;
    if (!mounted) return;
    final photo =
        photos.where((p) => p.isPrimary).firstOrNull ?? photos.firstOrNull;
    showPlantPopup(
      context,
      record: record,
      plantName: taxa.isEmpty ? null : plantTitle(taxa.first),
      photo: photo,
    );
  }

  /// A tap on an observation marker.
  Future<void> _onMarkerTap(Marker marker) async {
    final key = marker.key;
    if (key is! ValueKey<String>) return;
    final observation = _observationsById[key.value];
    if (observation == null) return;

    // The observation's photos, read once (newest first): the primary one is
    // shown in the popup, else the newest.
    final photos = await ref
        .read(photoRepositoryProvider)
        .watchPhotos(observation.id)
        .first;
    if (!mounted) return;
    final photo =
        photos.where((p) => p.isPrimary).firstOrNull ?? photos.firstOrNull;

    final sections =
        ref.read(projectSectionsProvider(widget.projectId)).value ?? const [];
    final sectionId = observation.transectSectionId;
    final sectionCode = sectionId == null
        ? null
        : sections
              .where((s) => s.section.id == sectionId)
              .firstOrNull
              ?.section
              .sectionCode;
    showObservationPopup(
      context,
      observation: observation,
      taxon: _taxaById[observation.taxonId],
      sectionCode: sectionCode,
      photo: photo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectId = widget.projectId;
    final observations = ref.watch(projectObservationsProvider(projectId));
    final transects = ref.watch(projectTransectsProvider(projectId));
    final sections = ref.watch(projectSectionsProvider(projectId));
    final plants = ref.watch(plantRecordsProvider(projectId));
    final habitats = ref.watch(habitatFeaturesProvider(projectId));
    final queries = [observations, transects, sections, plants, habitats];
    if (queries.any((q) => !q.hasValue)) {
      // A failed query would otherwise leave the spinner on for ever.
      final failed = queries.where((q) => q.hasError).firstOrNull;
      return Center(
        child: failed == null
            ? const CircularProgressIndicator()
            : Text('${failed.error}'),
      );
    }
    final allTransects = transects.requireValue;
    final allSections = sections.requireValue;
    final allObservations = observations.requireValue;
    final allPlants = plants.requireValue;
    final allHabitats = habitats.requireValue;

    // Watched here, which keeps the query alive while the map is open.
    final taxa = ref.watch(projectTaxaProvider(projectId));
    _taxaById = {for (final t in taxa) t.id: t};

    // The camera is fitted once, on the first data, to everything unfiltered.
    _updateLines(allTransects, allSections);
    _updatePlants(allPlants);
    _updateHabitats(allHabitats);
    final fit = _fit ??= _computeFit(allObservations, allPlants, allHabitats);
    if (fit == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nothing on this phone yet. Download the project first.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final layers = ref.watch(mapLayersProvider);
    final filtered = ref.watch(filteredObservationsProvider(projectId));
    final visits = ref.watch(projectVisitsProvider(projectId)).value ?? [];

    // The route of the visit chosen under Filters.
    final visitId = ref.watch(
      effectiveMapFilterProvider(projectId).select((f) => f.visitId),
    );
    final visit = visitId == null
        ? null
        : visits.where((v) => v.id == visitId).firstOrNull;
    final routePoints = _routeFor(
      visit == null
          ? const <SurveyTrackPoint>[]
          : ref.watch(visitRouteProvider(visit.id)).value ?? const [],
    );

    // The areas of both record types go in one layer with one hit notifier.
    // Habitats first, so a plant patch inside a habitat area stays on top and
    // gets the tap.
    final polygons = [
      if (layers.contains(MapLayer.habitats)) ..._habitatPolygons,
      if (layers.contains(MapLayer.plants)) ..._plantPolygons,
    ];

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: fit,
        // A long press on the ground starts a free observation there (T047).
        onLongPress: (_, point) =>
            openFreeObservation(context, ref, projectId, placedAt: point),
        minZoom: 3,
        maxZoom: 19,
        backgroundColor: const Color(0xFFE6E8E3),
        // No rotation: north stays up, as in the transect map.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // OSM asks every app to identify itself with the user agent. flutter_map
        // keeps the tiles it has shown in its cache; there is no prefetching.
        if (layers.contains(MapLayer.basemap))
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'rs.amilojkovic.butterfly',
          ),
        // The plant patches and habitat areas, below the lines. A tap on one
        // finds it through the shared hit notifier; `deferToChild` lets a tap
        // that misses every area fall through to whatever is below.
        if (polygons.isNotEmpty)
          GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: _onPolygonTap,
            child: PolygonLayer<Object>(
              hitNotifier: _polygonHits,
              polygons: polygons,
            ),
          ),
        // A tap on the lines. `deferToChild`: the detector only takes the tap
        // when a line is hit, and a drag that starts on a line still pans.
        GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: () => _onLineTap(allTransects),
          child: PolylineLayer<Object>(
            hitNotifier: _hits,
            minimumHitbox: 15,
            // Bottom to top: transects, sections, habitat lines, the route. A
            // hedge along a transect stays tappable above the section.
            polylines: [
              if (layers.contains(MapLayer.transects)) ..._transectLines,
              if (layers.contains(MapLayer.sections)) ..._sectionLines,
              if (layers.contains(MapLayer.habitats)) ..._habitatLines,
              if (layers.contains(MapLayer.visitRoute) &&
                  visit != null &&
                  routePoints.length >= 2)
                Polyline<Object>(
                  points: routePoints,
                  strokeWidth: 3,
                  color: Colors.black87,
                  hitValue: visit,
                ),
            ],
          ),
        ),
        // Habitat points are clustered the same way, in brown, below the plants.
        if (layers.contains(MapLayer.habitats) && _habitatMarkers.isNotEmpty)
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              markers: _habitatMarkers,
              size: const Size(40, 40),
              maxClusterRadius: 60,
              maxZoom: 18,
              centerMarkerOnClick: false,
              onMarkerTap: _onHabitatMarkerTap,
              builder: (context, markers) => DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.brown.shade800,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${markers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Plant points are clustered like the butterflies: many records on one
        // spot become one numbered green circle, and a tap spreads them out.
        if (layers.contains(MapLayer.plants) && _plantMarkers.isNotEmpty)
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              markers: _plantMarkers,
              size: const Size(40, 40),
              maxClusterRadius: 60,
              maxZoom: 18,
              centerMarkerOnClick: false,
              onMarkerTap: _onPlantMarkerTap,
              builder: (context, markers) => DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.green.shade800,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${markers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (layers.contains(MapLayer.observations))
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              markers: _markersFor(filtered),
              size: const Size(40, 40),
              maxClusterRadius: 60,
              // Below this zoom markers are clustered; the package default
              // (17) would split them a level too early for this map.
              maxZoom: 18,
              centerMarkerOnClick: false,
              onMarkerTap: _onMarkerTap,
              builder: (context, markers) => DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${markers.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (layers.contains(MapLayer.basemap))
          const SimpleAttributionWidget(
            source: Text('OpenStreetMap contributors'),
          ),
      ],
    );
  }
}
