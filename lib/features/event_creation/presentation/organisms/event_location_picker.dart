import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../location/domain/entities/user_location.dart';
import '../../../map/domain/entities/event_coordinates.dart';

class EventLocationPicker extends StatefulWidget {
  const EventLocationPicker({super.key, this.initialPoint, this.mapBuilder});

  final EventCoordinates? initialPoint;
  final Widget Function(MapWidget map)? mapBuilder;

  @override
  State<EventLocationPicker> createState() => _EventLocationPickerState();
}

class _EventLocationPickerState extends State<EventLocationPicker> {
  MapboxMap? _map;
  bool _loaded = false;
  bool _failed = false;
  bool _confirming = false;
  int _attempt = 0;

  Future<void> _confirm() async {
    final map = _map;
    if (map == null || _confirming) return;
    setState(() => _confirming = true);
    try {
      final camera = await map.getCameraState();
      final center = camera.center.coordinates;
      final point = EventCoordinates(
        center.lat.toDouble(),
        center.lng.toDouble(),
      );
      if (!point.isValid) throw StateError('Punto fuera de rango');
      if (mounted) Navigator.of(context).pop(point);
    } catch (_) {
      if (!mounted) return;
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos seleccionar el punto.')),
      );
    }
  }

  void _retry() => setState(() {
    _map = null;
    _loaded = false;
    _failed = false;
    _attempt++;
  });

  Widget _buildMap() {
    final start = widget.initialPoint;
    final fallback = UserLocation.defaultCity;
    final attempt = _attempt;
    final mapWidget = MapWidget(
      key: ValueKey(attempt),
      styleUri: MapboxStyles.STANDARD,
      viewport: CameraViewportState(
        center: Point(
          coordinates: Position(
            start?.longitude ?? fallback.longitude,
            start?.latitude ?? fallback.latitude,
          ),
        ),
        zoom: 15,
      ),
      onMapCreated: (map) {
        if (mounted && attempt == _attempt) _map = map;
      },
      onMapLoadedListener: (_) {
        if (mounted && attempt == _attempt) {
          setState(() {
            _loaded = true;
            _failed = false;
          });
        }
      },
      onMapLoadErrorListener: (_) {
        if (mounted && attempt == _attempt && !_loaded) {
          setState(() => _failed = true);
        }
      },
    );
    return widget.mapBuilder?.call(mapWidget) ?? mapWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubicación del evento')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: _buildMap()),
          if (_loaded)
            const IgnorePointer(child: Icon(Icons.my_location, size: 32))
          else if (_failed)
            FilledButton(
              onPressed: _retry,
              child: const Text('Reintentar mapa'),
            )
          else
            const CircularProgressIndicator(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mueve el mapa para ubicar el evento en el centro.'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loaded && !_confirming ? _confirm : null,
              child: const Text('Confirmar ubicación'),
            ),
          ],
        ),
      ),
    );
  }
}
