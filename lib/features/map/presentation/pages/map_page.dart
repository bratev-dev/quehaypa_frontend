import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../location/domain/entities/user_location.dart';

/// Mapa base de la pestaña Mapa. El contenido de eventos se añadirá aparte.
class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    this.accessToken = const String.fromEnvironment('ACCESS_TOKEN'),
    this.mapBuilder,
  });

  final String accessToken;

  /// Permite sustituir la vista nativa en las pruebas de widget.
  final Widget Function(MapWidget map)? mapBuilder;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _navigationClearance = 150.0;

  bool _loaded = false;
  bool _loadFailed = false;
  int _retryCount = 0;

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

    return Stack(
      children: [
        _buildMap(bottomMargin),
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
      onMapCreated: (mapboxMap) =>
          _positionAttribution(mapboxMap, bottomMargin),
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
