import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/dashboard/controllers/dashboard_controller.dart';
import 'package:frontend/features/dashboard/controllers/dashboard_state.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:frontend/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_providers.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements PreferencesRepository {}

const _event = EventSeed(
  id: 27,
  title: 'Evento de la API',
  category: 'Cine',
  eventText: 'Texto recibido',
);

void main() {
  late _Repository repository;
  late ProviderContainer container;
  DashboardController controller() =>
      container.read(dashboardControllerProvider.notifier);
  DashboardState state() => container.read(dashboardControllerProvider);

  setUp(() {
    repository = _Repository();
    when(() => repository.getFeed()).thenAnswer((_) async => [_event]);
    when(() => repository.getMyPreferences()).thenAnswer((_) async => ['Cine']);
    when(() => repository.getEvents(category: any(named: 'category')))
        .thenAnswer((_) async => [_event]);
    container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('inicia sin eventos ni intereses simulados', () {
    expect(state().status, DashboardStatus.initial);
    expect(state().visibleEvents, isEmpty);
    expect(state().userInterests, isEmpty);
  });

  test('carga feed y preferencias de la API', () async {
    await controller().load();
    expect(state().status, DashboardStatus.success);
    expect(state().visibleEvents.single.id, 27);
    expect(state().userInterests, ['Cine']);
    verify(() => repository.getFeed()).called(1);
    verify(() => repository.getMyPreferences()).called(1);
  });

  test('categoría usa el endpoint filtrado y General vuelve al feed', () async {
    await controller().load();
    controller().selectCategory('Cine');
    await Future<void>.delayed(Duration.zero);
    verify(() => repository.getEvents(category: 'Cine')).called(1);
    expect(state().selectedCategory, 'Cine');
    controller().selectCategory('General');
    await Future<void>.delayed(Duration.zero);
    verify(() => repository.getFeed()).called(2);
  });

  test('respuesta vacía permanece vacía sin fallback local', () async {
    when(() => repository.getFeed()).thenAnswer((_) async => []);
    await controller().load();
    expect(state().status, DashboardStatus.success);
    expect(state().visibleEvents, isEmpty);
  });

  test('error de red limpia eventos y permite reintento', () async {
    await controller().load();
    when(() => repository.getFeed())
        .thenThrow(const NetworkFailure('Sin conexión'));
    await controller().loadEvents();
    expect(state().status, DashboardStatus.error);
    expect(state().errorMessage, 'Sin conexión');
    expect(state().visibleEvents, isEmpty);
    when(() => repository.getFeed()).thenAnswer((_) async => [_event]);
    await controller().loadEvents();
    expect(state().status, DashboardStatus.success);
    expect(state().errorMessage, isNull);
  });

  test('un error inesperado no expone la excepción técnica', () async {
    when(() => repository.getFeed()).thenThrow(StateError('detalle interno'));
    await controller().loadEvents();
    expect(state().status, DashboardStatus.error);
    expect(state().errorMessage, isNot(contains('detalle interno')));
  });

  test(
    'sin preferencias de usuario regular carga eventos sin inventarlas',
    () async {
      when(() => repository.getMyPreferences())
          .thenThrow(const UnauthorizedFailure('Organizador'));
      await controller().load();
      expect(state().status, DashboardStatus.success);
      expect(state().userInterests, isEmpty);
      expect(state().visibleEvents, [_event]);
    },
  );

  test(
    'una respuesta lenta anterior no reemplaza la categoría nueva',
    () async {
      final previous = Completer<List<EventSeed>>();
      when(() => repository.getFeed()).thenAnswer((_) => previous.future);
      final first = controller().loadEvents();
      controller().selectCategory('Cine');
      await Future<void>.delayed(Duration.zero);
      expect(state().visibleEvents, [_event]);
      previous.complete([]);
      await first;
      expect(state().selectedCategory, 'Cine');
      expect(state().visibleEvents, [_event]);
    },
  );

  test('cargar preferencias conserva el error previo del feed', () async {
    final preferences = Completer<List<String>>();
    when(() => repository.getMyPreferences())
        .thenAnswer((_) => preferences.future);
    when(() => repository.getFeed())
        .thenThrow(const NetworkFailure('Sin conexión'));
    final loading = controller().load();
    await Future<void>.delayed(Duration.zero);
    expect(state().errorMessage, 'Sin conexión');
    preferences.complete(['Cine']);
    await loading;
    expect(state().status, DashboardStatus.error);
    expect(state().errorMessage, 'Sin conexión');
    expect(state().userInterests, ['Cine']);
  });

  test('guardar intereses actualiza categorías y recarga el feed', () async {
    await controller().load();
    controller().selectCategory('Cine');
    await Future<void>.delayed(Duration.zero);
    controller().setUserInterests(['Arte']);
    await Future<void>.delayed(Duration.zero);
    expect(state().userInterests, ['Arte']);
    expect(state().selectedCategory, 'General');
    verify(() => repository.getFeed()).called(2);
  });

  test(
    'preferencias antiguas no reemplazan una selección recién guardada',
    () async {
      final pending = Completer<List<String>>();
      when(() => repository.getMyPreferences())
          .thenAnswer((_) => pending.future);
      final loading = controller().load();
      controller().setUserInterests(['Arte']);
      pending.complete(['Cine']);
      await loading;
      expect(state().userInterests, ['Arte']);
    },
  );
}
