import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../location/domain/entities/user_location.dart';
import '../../../location/presentation/controllers/location_controller.dart';
import '../../../preferences/domain/entities/event_seed.dart';
import '../../domain/entities/event_map_marker.dart';
import '../controllers/map_events_provider.dart';
import '../map_event_selection.dart';
import '../map_marker_options.dart';
import '../molecules/map_event_card.dart';

/// Mapa de descubrimiento con eventos públicos que tienen ubicación válida.
class MapPage extends ConsumerStatefulWidget {
  const MapPage({
    super.key,
    this.accessToken = const String.fromEnvironment('ACCESS_TOKEN'),
    this.mapBuilder,
    this.markerWriter,
    this.locationWriter,
    this.onMarkerTapReady,
    this.onMapTapReady,
    this.now,
  });

  final String accessToken;

  /// Permite sustituir la vista nativa en las pruebas de widget.
  final Widget Function(MapWidget map)? mapBuilder;

  /// Permite comprobar el envío de anotaciones sin crear una vista nativa.
  final Future<void> Function(List<PointAnnotationOptions>)? markerWriter;

  /// Permite observar la anotación de ubicación sin una vista nativa.
  final Future<void> Function(CircleAnnotationOptions?)? locationWriter;

  /// Expone la selección al sustituir las anotaciones nativas en pruebas.
  final void Function(void Function(Map<String, Object>?) select)?
  onMarkerTapReady;

  /// Permite comprobar el cierre al tocar el mapa sin la vista nativa.
  final void Function(VoidCallback dismiss)? onMapTapReady;
  final DateTime Function()? now;

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
  PointAnnotationManager? _markers;
  CircleAnnotationManager? _locationMarkers;
  Future<void> _locationWrites = Future.value();
  bool _centeredOnDevice = false;
  Cancelable? _markerTapSubscription;
  Future<MapPinImages>? _pinImages;
  final Map<String, int> _eventIdsByAnnotation = {};
  DateTime? _lastMarkerTapAt;
  List<EventSeed>? _renderedEvents;
  List<EventSeed>? _pendingEvents;
  EventSeed? _selectedEvent;
  bool _rendering = false;

  bool get _canRender => _map != null || widget.markerWriter != null;
  DateTime get _now => widget.now?.call() ?? DateTime.now();

  UserLocation? _deviceLocation(UserLocation location) =>
      location.source == LocationSource.device ? location : null;

  Point _point(UserLocation location) =>
      Point(coordinates: Position(location.longitude, location.latitude));

  void _syncDeviceLocation(UserLocation? location) {
    if (!_loaded || (_map == null && widget.locationWriter == null)) return;
    final generation = _retryCount;
    _locationWrites = _locationWrites.then((_) async {
      if (!mounted || generation != _retryCount) return;
      try {
        await _writeDeviceLocation(location, generation);
      } catch (_) {
        // El indicador es independiente de los pines de eventos.
      }
    });
    unawaited(_locationWrites);
  }

  Future<void> _writeDeviceLocation(
    UserLocation? location,
    int generation,
  ) async {
    final options = location == null
        ? null
        : CircleAnnotationOptions(
            geometry: _point(location),
            circleRadius: 8,
            circleColor: 0xFF1769D2,
            circleStrokeColor: 0xFFFFFFFF,
            circleStrokeWidth: 3,
          );
    final writer = widget.locationWriter;
    if (writer != null) {
      await writer(options);
      return;
    }
    final map = _map!;
    if (options == null) {
      await _locationMarkers?.deleteAll();
      return;
    }
    final manager =
        _locationMarkers ??
        await map.annotations.createCircleAnnotationManager();
    if (!mounted || generation != _retryCount) return;
    _locationMarkers = manager;
    await manager.deleteAll();
    await manager.create(options);
    if (mounted && generation == _retryCount && !_centeredOnDevice) {
      _centeredOnDevice = true;
      await map.setCamera(CameraOptions(center: options.geometry));
    }
  }

  void _selectMarker(Map<String, Object>? customData) {
    final selected = eventForMarkerTap(_renderedEvents ?? const [], customData);
    if (selected != null && mounted) {
      _lastMarkerTapAt = _now;
      setState(() => _selectedEvent = selected);
    }
  }

  void _onMapTap() {
    if (mounted &&
        _selectedEvent != null &&
        shouldCloseCardOnMapTap(_lastMarkerTapAt, _now)) {
      setState(() => _selectedEvent = null);
    }
  }

  Future<void> _renderMarkers(List<EventSeed> events) async {
    if (!_canRender || !_loaded || identical(_renderedEvents, events)) return;
    _pendingEvents = events;
    if (_rendering) return;
    _rendering = true;
    try {
      while (_pendingEvents != null && _canRender && mounted) {
        final current = _pendingEvents!;
        _pendingEvents = null;
        final images = await (_pinImages ??= MapPinImages.load());
        final located = current
            .where((event) => EventMapMarker.fromEvent(event) != null)
            .toList();
        final points = mapMarkerOptions(located, images);
        final writer = widget.markerWriter;
        if (writer != null) {
          await writer(points);
        } else {
          final manager = _markers ??= await _map!.annotations
              .createPointAnnotationManager();
          _markerTapSubscription ??= manager.tapEvents(
            onTap: (annotation) {
              final selected = eventForAnnotationTap(
                _renderedEvents ?? const [],
                annotation.id,
                _eventIdsByAnnotation,
                annotation.customData,
              );
              if (selected != null) _selectMarker({'eventId': selected.id});
            },
          );
          await manager.deleteAll();
          _eventIdsByAnnotation.clear();
          if (points.isNotEmpty) {
            final created = await manager.createMulti(points);
            for (var i = 0; i < created.length; i++) {
              final annotation = created[i];
              if (annotation != null) {
                _eventIdsByAnnotation[annotation.id] = located[i].id;
              }
            }
          }
        }
        _renderedEvents = current;
        if (writer != null) widget.onMarkerTapReady?.call(_selectMarker);
        if (_selectedEvent != null && mounted) {
          final refreshed = eventForMarkerTap(current, {
            'eventId': _selectedEvent!.id,
          });
          setState(() => _selectedEvent = refreshed);
        }
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
    _markerTapSubscription?.cancel();
    _markerTapSubscription = null;
    _eventIdsByAnnotation.clear();
    setState(() {
      _retryCount++;
      _loaded = false;
      _loadFailed = false;
      _markersFailed = false;
      _map = null;
      _markers = null;
      _locationMarkers = null;
      _locationWrites = Future.value();
      _centeredOnDevice = false;
      _renderedEvents = null;
      _selectedEvent = null;
    });
  }

  @override
  void dispose() {
    _markerTapSubscription?.cancel();
    super.dispose();
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
    ref.listen(
      locationControllerProvider.select(
        (state) => _deviceLocation(state.location),
      ),
      (_, location) => _syncDeviceLocation(location),
    );
    if (widget.mapBuilder != null) widget.onMapTapReady?.call(_onMapTap);
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
        if (_selectedEvent != null)
          Positioned(
            left: 18,
            right: 18,
            bottom: bottomMargin,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.52,
              ),
              child: SingleChildScrollView(
                child: MapEventCard(
                  event: _selectedEvent!,
                  onClose: () => setState(() => _selectedEvent = null),
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
    final generation = _retryCount;
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
        if (!mounted || generation != _retryCount) return;
        _map = mapboxMap;
        mapboxMap.addInteraction(TapInteraction.onMap((_) => _onMapTap()));
        await _positionAttribution(mapboxMap, bottomMargin);
      },
      onMapLoadedListener: (_) {
        if (mounted && generation == _retryCount) {
          setState(() {
            _loaded = true;
            _loadFailed = false;
          });
          final location = ref.read(locationControllerProvider).location;
          _syncDeviceLocation(_deviceLocation(location));
        }
      },
      onMapLoadErrorListener: (_) {
        if (mounted && generation == _retryCount && !_loaded) {
          setState(() => _loadFailed = true);
        }
      },
    );
    return widget.mapBuilder?.call(map) ?? map;
  }
}
