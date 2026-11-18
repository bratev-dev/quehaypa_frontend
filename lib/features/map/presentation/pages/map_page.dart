import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../location/domain/entities/user_location.dart';
import '../../../preferences/domain/entities/event_seed.dart';
import '../../domain/entities/event_map_marker.dart';
import '../controllers/map_events_provider.dart';
import '../map_marker_options.dart';

/// Mapa de descubrimiento con eventos públicos que tienen ubicación válida.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({
    super.key,
    this.accessToken = const String.fromEnvironment('ACCESS_TOKEN'),
    this.mapBuilder,
    this.markerWriter,
  });

  final String accessToken;

  /// Permite sustituir la vista nativa en las pruebas de widget.
  final Widget Function(MapWidget map)? mapBuilder;

  /// Permite comprobar el envío de anotaciones sin crear una vista nativa.
  final Future<void> Function(List<CircleAnnotationOptions>)? markerWriter;

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  static const _navigationClearance = 150.0;

  bool _loaded = false;
  bool _loadFailed = false;
  bool _markersFailed = false;
  int _retryCount = 0;
  MapboxMap? _map;
  CircleAnnotationManager? _markers;
  List<EventSeed>? _renderedEvents;
  List<EventSeed>? _pendingEvents;
  bool _rendering = false;

  bool get _canRender => _map != null || widget.markerWriter != null;

  Future<void> _renderMarkers(List<EventSeed> events) async {
    if (!_canRender || !_loaded || identical(_renderedEvents, events)) return;
    _pendingEvents = events;
    if (_rendering) return;
    _rendering = true;
    try {
      while (_pendingEvents != null && _canRender && mounted) {
        final current = _pendingEvents!;
        _pendingEvents = null;
        final points = mapMarkerOptions(
          current.map(EventMapMarker.fromEvent).whereType<EventMapMarker>(),
        );
        final writer = widget.markerWriter;
        if (writer != null) {
          await writer(points);
        } else {
          final manager = _markers ??= await _map!.annotations
              .createCircleAnnotationManager();
          await manager.deleteAll();
          if (points.isNotEmpty) await manager.createMulti(points);
        }
        _renderedEvents = current;
      }
      if (_markersFailed && mounted) setState(() => _markersFailed = false);
    } catch (_) {
      _renderedEvents = events;
      if (mounted) setState(() => _markersFailed = true);
    } finally {
      _rendering = false;
    }
  }

  Future<void> _positionAttribution(
    MapboxMap mapboxMap,
    double bottomMargin,
  ) async {
    await Future.wait([
      mapboxMap.logo.updateSettings(LogoSettings(marginBottom: bottomMargin)),
      mapboxMap.attribution.updateSettings(
        AttributionSettings(marginBottom: bottomMargin),
      ),
    ]);
  }

  void _retry() {
    setState(() {
      _retryCount++;
      _loaded = false;
      _loadFailed = false;
      _markersFailed = false;
      _map = null;
      _markers = null;
      _renderedEvents = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accessToken.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Falta configurar el token público de Mapbox para mostrar el mapa.',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final bottomMargin =
        _navigationClearance + MediaQuery.paddingOf(context).bottom;
    final events = ref.watch(mapEventsProvider);
    if (_canRender && _loaded && events.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _renderMarkers(events.requireValue);
      });
    }

    return Stack(
      children: [
        _buildMap(bottomMargin),
        if (events.isLoading && !_loadFailed)
          const Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Center(child: CircularProgressIndicator()),
          ),
        if (events.hasValue &&
            !events.hasError &&
            !_markersFailed &&
            events.requireValue.every(
              (event) => EventMapMarker.fromEvent(event) == null,
            ) &&
            !_loadFailed)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No hay eventos ubicados para mostrar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        if ((events.hasError || _markersFailed) && !_loadFailed)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF121212),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'No pudimos mostrar los eventos.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (events.hasError) {
                          ref.invalidate(mapEventsProvider);
                        } else {
                          setState(() {
                            _renderedEvents = null;
                            _markersFailed = false;
                          });
                        }
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_loadFailed)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF121212),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No pudimos cargar el mapa.',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextButton(
                      onPressed: _retry,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMap(double bottomMargin) {
    final map = MapWidget(
      key: ValueKey(_retryCount),
      styleUri: MapboxStyles.STANDARD,
      viewport: CameraViewportState(
        center: Point(
          coordinates: Position(
            UserLocation.defaultCity.longitude,
            UserLocation.defaultCity.latitude,
          ),
        ),
        zoom: 13,
      ),
      onMapCreated: (mapboxMap) async {
        _map = mapboxMap;
        await _positionAttribution(mapboxMap, bottomMargin);
      },
      onMapLoadedListener: (_) {
        if (mounted) {
          setState(() {
            _loaded = true;
            _loadFailed = false;
          });
        }
      },
      onMapLoadErrorListener: (_) {
        if (mounted && !_loaded) {
          setState(() => _loadFailed = true);
        }
      },
    );
    return widget.mapBuilder?.call(map) ?? map;
  }
}
