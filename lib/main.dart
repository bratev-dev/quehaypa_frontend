import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app/app.dart';
import 'features/organizer_dashboard/presentation/pages/organizer_dashboard_page.dart';

Future<void> main() async {
  // Aseguramos la inicialización de los bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  const organizerPreview = bool.fromEnvironment('ORGANIZER_PREVIEW');
  if (!(kDebugMode && organizerPreview)) {
    // La vista previa no necesita configuración ni conexión con el backend.
    await dotenv.load(fileName: '.env');
  }
  const mapboxAccessToken = String.fromEnvironment('ACCESS_TOKEN');
  if (mapboxAccessToken.isNotEmpty) {
    MapboxOptions.setAccessToken(mapboxAccessToken);
  }
  runApp(
    ProviderScope(
      child: kDebugMode && organizerPreview
          ? const MaterialApp(home: OrganizerDashboardPage(preview: true))
          : const App(),
    ),
  );
}
