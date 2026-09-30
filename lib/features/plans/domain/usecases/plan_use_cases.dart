import '../entities/plan.dart';
import '../repositories/plan_params.dart';
import '../repositories/plan_repository.dart';
import '../../../preferences/domain/entities/event_seed.dart';

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

class AddPlanEvent {
  final PlanRepository repository;
  const AddPlanEvent(this.repository);
  Future<EventSeed> call(int planId, int eventId) =>
      repository.addEvent(planId, eventId);
}

class GetPlanEvents {
  final PlanRepository repository;
  const GetPlanEvents(this.repository);
  Future<List<EventSeed>> call(int planId) => repository.getPlanEvents(planId);
}
