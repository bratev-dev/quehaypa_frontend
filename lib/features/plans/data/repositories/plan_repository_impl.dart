import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failtures.dart';
import '../../domain/entities/plan.dart';
import '../../domain/repositories/plan_params.dart';
import '../../domain/repositories/plan_repository.dart';
import '../datasources/plan_remote_data_source.dart';
import '../../../preferences/domain/entities/event_seed.dart';

/// Implementa el contrato del dominio. Traduce Exception -> Failure.
class PlanRepositoryImpl implements PlanRepository {
  final PlanRemoteDataSource remoteDataSource;

  const PlanRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Plan>> getMyPlans() async {
    try {
      final models = await remoteDataSource.getMyPlans();
      return models.map((m) => m.toEntity()).toList();
    } on UnauthorizedException {
      throw const UnauthorizedFailure(
        'Sesión inválida. Inicia sesión de nuevo.',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ValidationException catch (e) {
      throw ValidationFailure(e.message);
    } on ConflictException catch (e) {
      throw ConflictFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw UnknownFailure('No fue posible obtener tus planes: $e');
    }
  }

  @override
  Future<Plan> createPlan(CreatePlanParams params) async {
    try {
      final model = await remoteDataSource.createPlan(params);
      return model.toEntity();
    } on UnauthorizedException {
      throw const UnauthorizedFailure(
        'Sesión inválida. Inicia sesión de nuevo.',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ValidationException catch (e) {
      throw ValidationFailure(e.message);
    } on ConflictException catch (e) {
      throw ConflictFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw UnknownFailure('No fue posible crear el plan: $e');
    }
  }

  @override
  Future<Plan> updatePlan(UpdatePlanParams params) async {
    try {
      final model = await remoteDataSource.updatePlan(params);
      return model.toEntity();
    } on UnauthorizedException {
      throw const UnauthorizedFailure(
        'Sesión inválida. Inicia sesión de nuevo.',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ValidationException catch (e) {
      throw ValidationFailure(e.message);
    } on ConflictException catch (e) {
      throw ConflictFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw UnknownFailure('No fue posible actualizar el plan: $e');
    }
  }

  @override
  Future<void> deletePlan(int planId) async {
    try {
      await remoteDataSource.deletePlan(planId);
    } on UnauthorizedException {
      throw const UnauthorizedFailure(
        'Sesión inválida. Inicia sesión de nuevo.',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ValidationException catch (e) {
      throw ValidationFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw UnknownFailure('No fue posible eliminar el plan: $e');
    }
  }

  @override
  Future<EventSeed> addEvent(int planId, int eventId) => _eventOperation(
    () => remoteDataSource.addEvent(planId, eventId).then((e) => e.toEntity()),
  );

  @override
  Future<List<EventSeed>> getPlanEvents(int planId) => _eventOperation(
    () => remoteDataSource
        .getPlanEvents(planId)
        .then((events) => events.map((event) => event.toEntity()).toList()),
  );

  Future<T> _eventOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on UnauthorizedException {
      throw const UnauthorizedFailure(
        'Sesión inválida. Inicia sesión de nuevo.',
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on ValidationException catch (e) {
      throw ValidationFailure(e.message);
    } on ConflictException catch (e) {
      throw ConflictFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (_) {
      throw const UnknownFailure(
        'No fue posible actualizar los eventos del plan.',
      );
    }
  }
}
