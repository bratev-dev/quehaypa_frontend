import '../entities/plan.dart';
import 'plan_params.dart';

/// Contrato que necesita el dominio. Lo implementa Data.
abstract class PlanRepository {
  Future<List<Plan>> getMyPlans();
  Future<Plan> createPlan(CreatePlanParams params);
  Future<Plan> updatePlan(UpdatePlanParams params);
  Future<void> deletePlan(int planId);
}
