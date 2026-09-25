import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failtures.dart';
import '../../domain/entities/plan.dart';
import '../../domain/repositories/plan_params.dart';
import '../../domain/repositories/plan_repository.dart';
import '../datasources/plan_remote_data_source.dart';

/// Implementa el contrato del dominio. Traduce Exception -> Failure.
class PlanRepositoryImpl implements PlanRepository {
  final PlanRemoteDataSource _remoteDataSource;

  const PlanRepositoryImpl({required this._remoteDataSource});

  @override
  Future<List<Plan>> getMyPlans() async {
    try {
      final models = await _remoteDataSource.getMyPlans();
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
      final model = await _remoteDataSource.createPlan(params);
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
      final model = await _remoteDataSource.updatePlan(params);
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
      await _remoteDataSource.deletePlan(planId);
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
}
