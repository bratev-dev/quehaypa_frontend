import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/events/data/event_api.dart';
import 'package:frontend/features/preferences/data/datasources/preferences_remote_data_source.dart';

/// Opt-in: usa el mismo datasource del front contra los contenedores activos.
/// flutter test --dart-define=LIVE_API_BASE_URL=http://127.0.0.1:8080 test/features/events/live_catalog_test.dart
void main() {
  const baseUrl = String.fromEnvironment('LIVE_API_BASE_URL');
  test(
    'el front interpreta categorías y eventos reales del gateway',
    () async {
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      addTearDown(() => dio.close(force: true));
      final categories = await EventApi(dio).categories();
      expect(categories, isNotEmpty);
      final source = PreferencesRemoteDataSource(dio: dio);
      final events = await source.getEvents();
      for (final event in events) {
        expect(event.id, greaterThan(0));
        expect(event.title, isNotEmpty);
        expect(DateTime.tryParse(event.startsAt ?? ''), isNotNull);
      }
      final filtered = await source.getEvents(category: categories.first);
      expect(
        filtered.every((event) => event.category == categories.first),
        isTrue,
      );
    },
    skip: baseUrl.isEmpty
        ? 'Requiere LIVE_API_BASE_URL y el backend Docker activo'
        : false,
  );
}
