import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/controllers/register_providers.dart';
import '../../data/datasources/plan_remote_data_source.dart';
import '../../data/repositories/plan_repository_impl.dart';
import '../../domain/repositories/plan_repository.dart';
import '../../domain/usecases/plan_use_cases.dart';

final planRemoteDataSourceProvider = Provider<PlanRemoteDataSource>((ref) {
  return PlanRemoteDataSource(dio: ref.read(dioProvider));
});

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepositoryImpl(
    remoteDataSource: ref.read(planRemoteDataSourceProvider),
  );
});

final getMyPlansUseCaseProvider = Provider<GetMyPlans>((ref) {
  return GetMyPlans(ref.read(planRepositoryProvider));
});

final createPlanUseCaseProvider = Provider<CreatePlan>((ref) {
  return CreatePlan(ref.read(planRepositoryProvider));
});

final updatePlanUseCaseProvider = Provider<UpdatePlan>((ref) {
  return UpdatePlan(ref.read(planRepositoryProvider));
});

final deletePlanUseCaseProvider = Provider<DeletePlan>((ref) {
  return DeletePlan(ref.read(planRepositoryProvider));
});
