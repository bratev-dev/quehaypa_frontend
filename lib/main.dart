import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';

Future<void> main() async {
  // Aseguramos la inicialización de los bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Cargamos el archivo .env antes de arrancar la app
  await dotenv.load(fileName: ".env");

  runApp(const ProviderScope(child: App()));
}
