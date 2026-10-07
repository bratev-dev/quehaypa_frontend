import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failtures.dart';
import '../../domain/repositories/plan_params.dart';
import '../../../preferences/domain/entities/event_seed.dart';
import 'plans_providers.dart';
import 'plans_state.dart';

final plansControllerProvider = NotifierProvider<PlansController, PlansState>(
  PlansController.new,
);

/// Coordina UI <-> casos de uso. Sin Dio, sin JSON, sin SecureStorage.
class PlansController extends Notifier<PlansState> {
  @override
  PlansState build() => const PlansState();

  Future<void> loadMyPlans() async {
    state = state.copyWith(status: PlansStatus.loading, errorMessage: null);
    try {
      final plans = await ref.read(getMyPlansUseCaseProvider)();
      state = state.copyWith(status: PlansStatus.success, plans: plans);
    } on Failure catch (e) {
      state = state.copyWith(
        status: PlansStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: PlansStatus.error,
        errorMessage: 'No fue posible cargar tus planes: $e',
      );
    }
  }

  Future<bool> createPlan({
    required String title,
    String description = '',
    DateTime? meetingDate,
  }) async {
    state = state.copyWith(status: PlansStatus.loading, errorMessage: null);
    try {
      await ref.read(createPlanUseCaseProvider)(
        CreatePlanParams(
          title: title,
          description: description,
          meetingDate: meetingDate,
        ),
      );
      await loadMyPlans();
      return true;
    } on Failure catch (e) {
      state = state.copyWith(
        status: PlansStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: PlansStatus.error,
        errorMessage: 'No fue posible crear el plan: $e',
      );
      return false;
    }
  }

  Future<bool> updatePlan({
    required int planId,
    required String title,
    String description = '',
    DateTime? meetingDate,
  }) async {
    state = PlansState(status: PlansStatus.loading, plans: state.plans);
    try {
      final updated = await ref.read(updatePlanUseCaseProvider)(
        UpdatePlanParams(
          planId: planId,
          title: title,
          description: description,
          meetingDate: meetingDate,
        ),
      );
      state = PlansState(
        status: PlansStatus.success,
        plans: [
          for (final plan in state.plans)
            if (plan.id == updated.id) updated else plan,
        ],
      );
      return true;
    } on Failure catch (e) {
      state = state.copyWith(
        status: PlansStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: PlansStatus.error,
        errorMessage: 'No fue posible actualizar el plan: $e',
      );
      return false;
    }
  }

  Future<bool> deletePlan(int planId) async {
    final previous = state.plans;
    state = state.copyWith(
      plans: previous.where((p) => p.id != planId).toList(),
    );
    try {
      await ref.read(deletePlanUseCaseProvider)(planId);
      await loadMyPlans();
      return true;
    } on Failure catch (e) {
      state = state.copyWith(
        plans: previous,
        status: PlansStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        plans: previous,
        status: PlansStatus.error,
        errorMessage: 'No fue posible eliminar el plan: $e',
      );
      return false;
    }
  }

  Future<List<EventSeed>> loadPlanEvents(int planId) =>
      ref.read(getPlanEventsUseCaseProvider)(planId);

  Future<void> removePlanEvent(int planId, int eventId) =>
      ref.read(removePlanEventUseCaseProvider)(planId, eventId);
}
