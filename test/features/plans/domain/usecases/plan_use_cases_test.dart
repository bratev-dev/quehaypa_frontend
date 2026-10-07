import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/plans/domain/entities/plan.dart';
import 'package:frontend/features/plans/domain/repositories/plan_params.dart';
import 'package:frontend/features/plans/domain/repositories/plan_repository.dart';
import 'package:frontend/features/plans/domain/usecases/plan_use_cases.dart';
import 'package:frontend/features/preferences/domain/entities/event_seed.dart';
import 'package:mocktail/mocktail.dart';

class MockPlanRepository extends Mock implements PlanRepository {}

void main() {
  late MockPlanRepository repository;

  const plan = Plan(id: 1, title: 'Plan test', userRole: 'CREATOR');

  setUpAll(() {
    registerFallbackValue(const CreatePlanParams(title: 't'));
    registerFallbackValue(const UpdatePlanParams(planId: 1, title: 't'));
  });

  setUp(() {
    repository = MockPlanRepository();
  });

  test('GetMyPlans delega al repositorio', () async {
    when(() => repository.getMyPlans()).thenAnswer((_) async => [plan]);

    final result = await GetMyPlans(repository)();

    expect(result, hasLength(1));
    verify(() => repository.getMyPlans()).called(1);
  });

  test('CreatePlan delega al repositorio', () async {
    when(() => repository.createPlan(any())).thenAnswer((_) async => plan);

    final result = await CreatePlan(repository)(
      const CreatePlanParams(title: 'Nuevo'),
    );

    expect(result.title, 'Plan test');
    verify(() => repository.createPlan(any())).called(1);
  });

  test('UpdatePlan delega al repositorio', () async {
    when(() => repository.updatePlan(any())).thenAnswer((_) async => plan);

    final result = await UpdatePlan(repository)(
      const UpdatePlanParams(planId: 1, title: 'Edit'),
    );

    expect(result.id, 1);
    verify(() => repository.updatePlan(any())).called(1);
  });

  test('DeletePlan delega al repositorio', () async {
    when(() => repository.deletePlan(any())).thenAnswer((_) async {});

    await DeletePlan(repository)(1);

    verify(() => repository.deletePlan(1)).called(1);
  });

  test('AddPlanEvent delega al repositorio', () async {
    const event = EventSeed(
      id: 7,
      title: 'Concierto',
      category: 'Música',
      eventText: 'Viernes',
    );
    when(() => repository.addEvent(1, 7)).thenAnswer((_) async => event);

    final saved = await AddPlanEvent(repository)(1, 7);

    expect(saved.id, 7);
    verify(() => repository.addEvent(1, 7)).called(1);
  });

  test('GetPlanEvents delega al repositorio', () async {
    when(() => repository.getPlanEvents(1)).thenAnswer((_) async => []);

    final events = await GetPlanEvents(repository)(1);

    expect(events, isEmpty);
    verify(() => repository.getPlanEvents(1)).called(1);
  });

  test('RemovePlanEvent delega los dos identificadores', () async {
    when(() => repository.removeEvent(1, 7)).thenAnswer((_) async {});

    await RemovePlanEvent(repository)(1, 7);

    verify(() => repository.removeEvent(1, 7)).called(1);
  });
}
