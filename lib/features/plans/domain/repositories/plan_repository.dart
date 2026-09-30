import '../entities/plan.dart';
import 'plan_params.dart';
import '../../../preferences/domain/entities/event_seed.dart';

/// Contrato que necesita el dominio. Lo implementa Data.
abstract class PlanRepository {
  Future<List<Plan>> getMyPlans();
  Future<Plan> createPlan(CreatePlanParams params);
  Future<Plan> updatePlan(UpdatePlanParams params);
  Future<void> deletePlan(int planId);
  Future<EventSeed> addEvent(int planId, int eventId);
  Future<List<EventSeed>> getPlanEvents(int planId);
}
