import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/plans/data/datasources/plan_remote_data_source.dart';
import 'package:frontend/features/plans/data/models/plan_model.dart';
import 'package:frontend/features/plans/data/repositories/plan_repository_impl.dart';
import 'package:frontend/features/plans/domain/repositories/plan_params.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements PlanRemoteDataSource {}

/// Mapeo Exception -> Failure para cada operación del repositorio de planes.
void main() {
  late _MockRemote remote;
  late PlanRepositoryImpl repository;

  const model = PlanModel(
    id: 7,
    title: 'Asado',
    description: '',
    userRole: 'CREATOR',
  );
  const update = UpdatePlanParams(planId: 7, title: 'Asado');

  setUpAll(() {
    registerFallbackValue(const CreatePlanParams(title: 't'));
    registerFallbackValue(update);
  });

  setUp(() {
    remote = _MockRemote();
    repository = PlanRepositoryImpl(remoteDataSource: remote);
  });

  test('updatePlan devuelve la entidad actualizada', () async {
    when(() => remote.updatePlan(any())).thenAnswer((_) async => model);

    expect((await repository.updatePlan(update)).id, 7);
  });

  test('deletePlan delega en el datasource', () async {
    when(() => remote.deletePlan(7)).thenAnswer((_) async {});

    await repository.deletePlan(7);

    verify(() => remote.deletePlan(7)).called(1);
  });

  // Cada operación con cómo simular que el datasource lanza [e].
  final operaciones =
      <String, (void Function(Object e), Future<Object?> Function())>{
        'getMyPlans': (
          (e) => when(() => remote.getMyPlans()).thenThrow(e),
          () => repository.getMyPlans(),
        ),
        'createPlan': (
          (e) => when(() => remote.createPlan(any())).thenThrow(e),
          () => repository.createPlan(const CreatePlanParams(title: 'x')),
        ),
        'updatePlan': (
          (e) => when(() => remote.updatePlan(any())).thenThrow(e),
          () => repository.updatePlan(update),
        ),
        'deletePlan': (
          (e) => when(() => remote.deletePlan(any())).thenThrow(e),
          () => repository.deletePlan(7),
        ),
        'addEvent': (
          (e) => when(() => remote.addEvent(7, 3)).thenThrow(e),
          () => repository.addEvent(7, 3),
        ),
        'getPlanEvents': (
          (e) => when(() => remote.getPlanEvents(7)).thenThrow(e),
          () => repository.getPlanEvents(7),
        ),
      };

  final casos = <String, (Object, Matcher)>{
    'UnauthorizedException -> UnauthorizedFailure': (
      const UnauthorizedException('x'),
      isA<UnauthorizedFailure>().having(
        (f) => f.message,
        'message',
        'Sesión inválida. Inicia sesión de nuevo.',
      ),
    ),
    'NetworkException -> NetworkFailure': (
      const NetworkException('sin red'),
      isA<NetworkFailure>().having((f) => f.message, 'message', 'sin red'),
    ),
    'ValidationException -> ValidationFailure': (
      const ValidationException('título vacío'),
      isA<ValidationFailure>().having(
        (f) => f.message,
        'message',
        'título vacío',
      ),
    ),
    'ServerException -> ServerFailure': (
      const ServerException('caído'),
      isA<ServerFailure>().having((f) => f.message, 'message', 'caído'),
    ),
    'otra excepción -> UnknownFailure': (
      StateError('x'),
      isA<UnknownFailure>(),
    ),
  };

  operaciones.forEach((operacion, op) {
    group(operacion, () {
      casos.forEach((nombre, caso) {
        test(nombre, () {
          op.$1(caso.$1);
          expect(op.$2(), throwsA(caso.$2));
        });
      });
    });
  });

  // deletePlan no distingue conflictos: un 409 termina como error desconocido.
  for (final operacion in [
    'getMyPlans',
    'createPlan',
    'updatePlan',
    'addEvent',
    'getPlanEvents',
  ]) {
    test('$operacion: ConflictException -> ConflictFailure', () {
      final op = operaciones[operacion]!;
      op.$1(const ConflictException('duplicado'));
      expect(op.$2(), throwsA(isA<ConflictFailure>()));
    });
  }

  test('deletePlan: ConflictException -> UnknownFailure', () {
    final op = operaciones['deletePlan']!;
    op.$1(const ConflictException('duplicado'));
    expect(op.$2(), throwsA(isA<UnknownFailure>()));
  });
}
