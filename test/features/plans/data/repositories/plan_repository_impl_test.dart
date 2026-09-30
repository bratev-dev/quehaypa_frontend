import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/exceptions.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/plans/data/datasources/plan_remote_data_source.dart';
import 'package:frontend/features/plans/data/models/plan_model.dart';
import 'package:frontend/features/plans/data/repositories/plan_repository_impl.dart';
import 'package:frontend/features/plans/domain/repositories/plan_params.dart';
import 'package:frontend/features/preferences/data/models/event_seed_model.dart';
import 'package:mocktail/mocktail.dart';

class MockPlanRemoteDataSource extends Mock implements PlanRemoteDataSource {}

void main() {
  late MockPlanRemoteDataSource remote;
  late PlanRepositoryImpl repository;

  const planModel = PlanModel(
    id: 1,
    title: 'Plan test',
    description: 'Desc',
    userRole: 'CREATOR',
  );

  setUpAll(() {
    registerFallbackValue(const CreatePlanParams(title: 't'));
    registerFallbackValue(const UpdatePlanParams(planId: 1, title: 't'));
  });

  setUp(() {
    remote = MockPlanRemoteDataSource();
    repository = PlanRepositoryImpl(remoteDataSource: remote);
  });

  test('getMyPlans retorna entidades al éxito', () async {
    when(() => remote.getMyPlans()).thenAnswer((_) async => [planModel]);

    final plans = await repository.getMyPlans();

    expect(plans, hasLength(1));
    expect(plans.first.title, 'Plan test');
    verify(() => remote.getMyPlans()).called(1);
  });

  test('createPlan retorna entidad al éxito', () async {
    when(() => remote.createPlan(any())).thenAnswer((_) async => planModel);

    final plan = await repository.createPlan(
      const CreatePlanParams(title: 'Nuevo'),
    );

    expect(plan.id, 1);
    verify(() => remote.createPlan(any())).called(1);
  });

  test('401 se mapea a UnauthorizedFailure', () {
    when(() => remote.getMyPlans())
        .thenThrow(const UnauthorizedException('No autorizado.'));

    expect(repository.getMyPlans(), throwsA(isA<UnauthorizedFailure>()));
  });

  test('error de red se mapea a NetworkFailure', () {
    when(() => remote.getMyPlans())
        .thenThrow(const NetworkException('Sin conexión'));

    expect(repository.getMyPlans(), throwsA(isA<NetworkFailure>()));
  });

  test('deletePlan propaga éxito', () async {
    when(() => remote.deletePlan(any())).thenAnswer((_) async {});

    await repository.deletePlan(1);

    verify(() => remote.deletePlan(1)).called(1);
  });

  test('addEvent devuelve la entidad del evento guardado', () async {
    when(() => remote.addEvent(1, 7)).thenAnswer(
      (_) async => const EventSeedModel(
        id: 7,
        title: 'Concierto',
        category: 'Música',
        eventText: 'Viernes',
      ),
    );

    final event = await repository.addEvent(1, 7);

    expect(event.id, 7);
    expect(event.title, 'Concierto');
    verify(() => remote.addEvent(1, 7)).called(1);
  });

  test('getPlanEvents devuelve las entidades del plan', () async {
    when(() => remote.getPlanEvents(1)).thenAnswer(
      (_) async => const [
        EventSeedModel(
          id: 7,
          title: 'Concierto',
          category: 'Música',
          eventText: 'Viernes',
        ),
      ],
    );

    final events = await repository.getPlanEvents(1);

    expect(events.single.id, 7);
    verify(() => remote.getPlanEvents(1)).called(1);
  });
}
