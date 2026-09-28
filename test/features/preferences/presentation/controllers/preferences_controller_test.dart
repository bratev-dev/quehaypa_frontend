import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers/network_providers.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/preferences/domain/entities/interest.dart';
import 'package:frontend/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_controller.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_providers.dart';
import 'package:frontend/features/preferences/presentation/controllers/preferences_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_http_adapter.dart';

class _MockPreferencesRepository extends Mock
    implements PreferencesRepository {}

void main() {
  late _MockPreferencesRepository repository;
  late ProviderContainer container;

  PreferencesController controller() =>
      container.read(preferencesControllerProvider.notifier);
  PreferencesState state() => container.read(preferencesControllerProvider);

  setUp(() {
    repository = _MockPreferencesRepository();
    container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  group('loadCatalog', () {
    test('éxito deja los nombres del catálogo', () async {
      when(() => repository.getInterests()).thenAnswer(
        (_) async => const [
          Interest(id: 1, name: 'Música'),
          Interest(id: 2, name: 'Cine'),
        ],
      );

      await controller().loadCatalog();

      expect(state().status, PreferencesStatus.success);
      expect(state().catalog, ['Música', 'Cine']);
    });

    test('un Failure deja su mensaje', () async {
      when(() => repository.getInterests())
          .thenThrow(const NetworkFailure('Sin conexión'));

      await controller().loadCatalog();

      expect(state().status, PreferencesStatus.error);
      expect(state().errorMessage, 'Sin conexión');
    });

    test('un error inesperado deja un mensaje genérico', () async {
      when(() => repository.getInterests()).thenThrow(StateError('x'));

      await controller().loadCatalog();

      expect(
        state().errorMessage,
        startsWith('No fue posible cargar intereses'),
      );
    });
  });

  test('los providers conectan los casos de uso con el Dio central', () async {
    final adapter = FakeHttpAdapter(
      const FakeReply(200, {
        'data': ['Cine'],
      }),
    );
    final wired = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dioWith(adapter))],
    );
    addTearDown(wired.dispose);

    expect(await wired.read(getMyPreferencesUseCaseProvider)(), ['Cine']);
    expect(adapter.last.path, '/api/v1/preferences/me');
    expect(wired.read(saveMyPreferencesUseCaseProvider), isNotNull);
    expect(wired.read(getInterestsUseCaseProvider), isNotNull);
    expect(wired.read(getEventsFeedUseCaseProvider), isNotNull);
  });
}
