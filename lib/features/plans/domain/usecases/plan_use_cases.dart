import '../entities/plan.dart';
import '../repositories/plan_params.dart';
import '../repositories/plan_repository.dart';

class GetMyPlans {
  final PlanRepository repository;

  const GetMyPlans(this.repository);

  Future<List<Plan>> call() => repository.getMyPlans();
}

class CreatePlan {
  final PlanRepository repository;

  const CreatePlan(this.repository);

  Future<Plan> call(CreatePlanParams params) => repository.createPlan(params);
}

class UpdatePlan {
  final PlanRepository repository;

  const UpdatePlan(this.repository);

  Future<Plan> call(UpdatePlanParams params) => repository.updatePlan(params);
}

class DeletePlan {
  final PlanRepository repository;

  const DeletePlan(this.repository);

  Future<void> call(int planId) => repository.deletePlan(planId);
}
