import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/preferences/data/datasources/preferences_remote_data_source.dart';
import 'package:frontend/features/preferences/data/models/event_seed_model.dart';
import 'package:frontend/features/preferences/data/repositories/preferences_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements PreferencesRemoteDataSource {}

/// Mapeo de excepciones del datasource a Failures del dominio, por método.
void main() {
  late _MockRemote remote;
  late PreferencesRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    repository = PreferencesRepositoryImpl(remoteDataSource: remote);
  });

  group('saveMyPreferences', () {
    test('éxito devuelve las categorías guardadas', () async {
      when(() => remote.saveMyPreferences(any()))
          .thenAnswer((_) async => ['Cine']);

      expect(await repository.saveMyPreferences(['Cine']), ['Cine']);
    });

    final casos = <String, (Exception, Matcher)>{
      'ValidationException -> ValidationFailure': (
        const ValidationException('inválida'),
        isA<ValidationFailure>(),
      ),
      'UnauthorizedException -> UnauthorizedFailure': (
        const UnauthorizedException('x'),
        isA<UnauthorizedFailure>(),
      ),
      'NetworkException -> NetworkFailure': (
        const NetworkException('sin red'),
        isA<NetworkFailure>(),
      ),
      'ServerException -> ServerFailure': (
        const ServerException('500'),
        isA<ServerFailure>(),
      ),
      'otra excepción -> UnknownFailure': (
        const FormatException('rara'),
        isA<UnknownFailure>(),
      ),
    };
    casos.forEach((nombre, caso) {
      test(nombre, () {
        when(() => remote.saveMyPreferences(any())).thenThrow(caso.$1);
        expect(repository.saveMyPreferences(['Cine']), throwsA(caso.$2));
      });
    });
  });

  group('getMyPreferences', () {
    test('éxito devuelve las categorías', () async {
      when(() => remote.getMyPreferences()).thenAnswer((_) async => ['Arte']);

      expect(await repository.getMyPreferences(), ['Arte']);
    });

    test('ValidationException -> ValidationFailure', () {
      when(() => remote.getMyPreferences())
          .thenThrow(const ValidationException('x'));
      expect(repository.getMyPreferences(), throwsA(isA<ValidationFailure>()));
    });

    test('UnauthorizedException -> UnauthorizedFailure', () {
      when(() => remote.getMyPreferences())
          .thenThrow(const UnauthorizedException('x'));
      expect(
        repository.getMyPreferences(),
        throwsA(isA<UnauthorizedFailure>()),
      );
    });

    test('NetworkException -> NetworkFailure', () {
      when(() => remote.getMyPreferences())
          .thenThrow(const NetworkException('x'));
      expect(repository.getMyPreferences(), throwsA(isA<NetworkFailure>()));
    });

    test('ServerException -> ServerFailure', () {
      when(() => remote.getMyPreferences())
          .thenThrow(const ServerException('x'));
      expect(repository.getMyPreferences(), throwsA(isA<ServerFailure>()));
    });

    test('otra excepción -> UnknownFailure', () {
      when(() => remote.getMyPreferences()).thenThrow(StateError('x'));
      expect(repository.getMyPreferences(), throwsA(isA<UnknownFailure>()));
    });
  });

  group('getInterests', () {
    test('ValidationException -> ValidationFailure', () {
      when(() => remote.getInterests())
          .thenThrow(const ValidationException('x'));
      expect(repository.getInterests(), throwsA(isA<ValidationFailure>()));
    });

    test('NetworkException -> NetworkFailure', () {
      when(() => remote.getInterests()).thenThrow(const NetworkException('x'));
      expect(repository.getInterests(), throwsA(isA<NetworkFailure>()));
    });

    test('ServerException -> ServerFailure', () {
      when(() => remote.getInterests()).thenThrow(const ServerException('x'));
      expect(repository.getInterests(), throwsA(isA<ServerFailure>()));
    });

    test('otra excepción -> UnknownFailure', () {
      when(() => remote.getInterests()).thenThrow(StateError('x'));
      expect(repository.getInterests(), throwsA(isA<UnknownFailure>()));
    });
  });

  group('getFeed', () {
    test('NetworkException -> NetworkFailure', () {
      when(() => remote.getFeed()).thenThrow(const NetworkException('x'));
      expect(repository.getFeed(), throwsA(isA<NetworkFailure>()));
    });

    test('ServerException -> ServerFailure', () {
      when(() => remote.getFeed()).thenThrow(const ServerException('x'));
      expect(repository.getFeed(), throwsA(isA<ServerFailure>()));
    });

    test('otra excepción -> UnknownFailure', () {
      when(() => remote.getFeed()).thenThrow(StateError('x'));
      expect(repository.getFeed(), throwsA(isA<UnknownFailure>()));
    });
  });

  group('getEvents', () {
    test('éxito convierte modelos en entidades y pasa la categoría', () async {
      when(() => remote.getEvents(category: 'Cine')).thenAnswer(
        (_) async => [
          EventSeedModel.fromJson(const {
            'id': 1,
            'title': 'Estreno',
            'category': 'Cine',
            'eventText': 'Hoy',
            'description': 'd',
          }),
        ],
      );

      final events = await repository.getEvents(category: 'Cine');

      expect(events.single.title, 'Estreno');
    });

    test('NetworkException -> NetworkFailure', () {
      when(() => remote.getEvents(category: any(named: 'category')))
          .thenThrow(const NetworkException('x'));
      expect(repository.getEvents(), throwsA(isA<NetworkFailure>()));
    });

    test('ServerException -> ServerFailure', () {
      when(() => remote.getEvents(category: any(named: 'category')))
          .thenThrow(const ServerException('x'));
      expect(repository.getEvents(), throwsA(isA<ServerFailure>()));
    });

    test('otra excepción -> UnknownFailure', () {
      when(() => remote.getEvents(category: any(named: 'category')))
          .thenThrow(StateError('x'));
      expect(repository.getEvents(), throwsA(isA<UnknownFailure>()));
    });
  });
}
