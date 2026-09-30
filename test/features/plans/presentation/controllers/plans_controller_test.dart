import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/providers/network_providers.dart';
import 'package:frontend/core/errors/failtures.dart';
import 'package:frontend/features/plans/domain/entities/plan.dart';
import 'package:frontend/features/plans/domain/repositories/plan_params.dart';
import 'package:frontend/features/plans/domain/repositories/plan_repository.dart';
import 'package:frontend/features/plans/presentation/controllers/plans_controller.dart';
import 'package:frontend/features/plans/presentation/controllers/plans_providers.dart';
import 'package:frontend/features/plans/presentation/controllers/plans_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fake_http_adapter.dart';

class _MockPlanRepository extends Mock implements PlanRepository {}

const _asado = Plan(id: 1, title: 'Asado', userRole: 'CREATOR');
const _cine = Plan(id: 2, title: 'Cine', userRole: 'PARTICIPANT');

void main() {
  late _MockPlanRepository repository;
  late ProviderContainer container;

  PlansController controller() =>
      container.read(plansControllerProvider.notifier);
  PlansState state() => container.read(plansControllerProvider);

  setUpAll(() {
    registerFallbackValue(const CreatePlanParams(title: 't'));
    registerFallbackValue(const UpdatePlanParams(planId: 1, title: 't'));
  });

  setUp(() {
    repository = _MockPlanRepository();
    container = ProviderContainer(
      overrides: [planRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('estado inicial vacío', () {
    expect(state().status, PlansStatus.initial);
    expect(state().plans, isEmpty);
    expect(_asado.isCreator, isTrue);
    expect(_cine.isCreator, isFalse);
  });

  group('loadMyPlans', () {
    test('éxito deja los planes y el estado success', () async {
      when(() => repository.getMyPlans())
          .thenAnswer((_) async => [_asado, _cine]);

      await controller().loadMyPlans();

      expect(state().status, PlansStatus.success);
      expect(state().plans, [_asado, _cine]);
      expect(state().errorMessage, isNull);
    });

    test('un Failure deja su mensaje', () async {
      when(() => repository.getMyPlans())
          .thenThrow(const NetworkFailure('Sin conexión'));

      await controller().loadMyPlans();

      expect(state().status, PlansStatus.error);
      expect(state().errorMessage, 'Sin conexión');
    });

    test('un error inesperado deja un mensaje genérico', () async {
      when(() => repository.getMyPlans()).thenThrow(StateError('x'));

      await controller().loadMyPlans();

      expect(
        state().errorMessage,
        startsWith('No fue posible cargar tus planes'),
      );
    });
  });

  group('createPlan', () {
    test('éxito crea con los datos dados y recarga la lista', () async {
      final fecha = DateTime(2026, 10, 3, 19);
      when(() => repository.createPlan(any())).thenAnswer((_) async => _asado);
      when(() => repository.getMyPlans()).thenAnswer((_) async => [_asado]);

      final ok = await controller().createPlan(
        title: 'Asado',
        description: 'En casa',
        meetingDate: fecha,
      );

      expect(ok, isTrue);
      final params =
          verify(() => repository.createPlan(captureAny())).captured.single
              as CreatePlanParams;
      expect(
        (params.title, params.description, params.meetingDate),
        ('Asado', 'En casa', fecha),
      );
      expect(state().plans, [_asado]);
    });

    test('un Failure devuelve false con su mensaje', () async {
      when(() => repository.createPlan(any()))
          .thenThrow(const ValidationFailure('Título vacío'));

      expect(await controller().createPlan(title: ''), isFalse);
      expect(state().errorMessage, 'Título vacío');
      verifyNever(() => repository.getMyPlans());
    });

    test('un error inesperado devuelve false con mensaje genérico', () async {
      when(() => repository.createPlan(any())).thenThrow(StateError('x'));

      expect(await controller().createPlan(title: 'x'), isFalse);
      expect(state().errorMessage, startsWith('No fue posible crear el plan'));
    });
  });

  group('updatePlan', () {
    test('éxito actualiza el plan indicado y recarga la lista', () async {
      when(() => repository.updatePlan(any())).thenAnswer((_) async => _asado);
      when(() => repository.getMyPlans()).thenAnswer((_) async => [_asado]);

      expect(
        await controller().updatePlan(planId: 1, title: 'Asado 2'),
        isTrue,
      );

      final params =
          verify(() => repository.updatePlan(captureAny())).captured.single
              as UpdatePlanParams;
      expect((params.planId, params.title), (1, 'Asado 2'));
      expect(state().status, PlansStatus.success);
    });

    test('un Failure devuelve false con su mensaje', () async {
      when(() => repository.updatePlan(any()))
          .thenThrow(const ServerFailure('No encontrado'));

      expect(await controller().updatePlan(planId: 9, title: 'x'), isFalse);
      expect(state().errorMessage, 'No encontrado');
    });

    test('un error inesperado devuelve false con mensaje genérico', () async {
      when(() => repository.updatePlan(any())).thenThrow(StateError('x'));

      expect(await controller().updatePlan(planId: 9, title: 'x'), isFalse);
      expect(
        state().errorMessage,
        startsWith('No fue posible actualizar el plan'),
      );
    });
  });

  group('deletePlan', () {
    setUp(() async {
      when(() => repository.getMyPlans())
          .thenAnswer((_) async => [_asado, _cine]);
      await controller().loadMyPlans();
    });

    test('éxito quita el plan y recarga la lista', () async {
      when(() => repository.deletePlan(1)).thenAnswer((_) async {});
      when(() => repository.getMyPlans()).thenAnswer((_) async => [_cine]);

      expect(await controller().deletePlan(1), isTrue);
      expect(state().plans, [_cine]);
    });

    test('un Failure restaura la lista anterior', () async {
      when(() => repository.deletePlan(1))
          .thenThrow(const UnauthorizedFailure('Sesión inválida'));

      expect(await controller().deletePlan(1), isFalse);
      expect(state().plans, [_asado, _cine]);
      expect(state().errorMessage, 'Sesión inválida');
    });

    test('un error inesperado restaura la lista anterior', () async {
      when(() => repository.deletePlan(1)).thenThrow(StateError('x'));

      expect(await controller().deletePlan(1), isFalse);
      expect(state().plans, [_asado, _cine]);
      expect(
        state().errorMessage,
        startsWith('No fue posible eliminar el plan'),
      );
    });
  });

  test('los providers conectan el caso de uso con el Dio central', () async {
    final adapter = FakeHttpAdapter(
      const FakeReply(200, {
        'data': [
          {'id': 3, 'title': 'Picnic', 'userRole': 'CREATOR'},
        ],
      }),
    );
    final wired = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dioWith(adapter))],
    );
    addTearDown(wired.dispose);

    final plans = await wired.read(getMyPlansUseCaseProvider)();

    expect(plans.single.title, 'Picnic');
    expect(adapter.last.path, '/api/v1/plans/my-plans');
    expect(wired.read(createPlanUseCaseProvider), isNotNull);
    expect(wired.read(updatePlanUseCaseProvider), isNotNull);
    expect(wired.read(deletePlanUseCaseProvider), isNotNull);
    expect(wired.read(addPlanEventUseCaseProvider), isNotNull);
    expect(wired.read(getPlanEventsUseCaseProvider), isNotNull);
  });
}
