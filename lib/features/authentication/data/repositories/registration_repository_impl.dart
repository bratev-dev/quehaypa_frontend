import '../../domain/repositories/registration_repository.dart';
import '../datasources/registration_remote_data_source.dart';
import 'profile_failures.dart';

class RegistrationRepositoryImpl implements RegistrationRepository {
  final RegistrationRemoteDataSource _source;
  const RegistrationRepositoryImpl(this._source);

  @override
  Future<bool> begin() => _perform(_source.begin);
  @override
  Future<void> complete() => _perform(_source.complete);
  @override
  Future<void> cancel() => _perform(_source.cancel);

  Future<T> _perform<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      throw toProfileFailure(
        e,
        unauthorizedMessage:
            'Tu sesión expiró. Inicia sesión para recuperar el registro.',
        unknownMessage:
            'No fue posible actualizar el registro. Inténtalo de nuevo.',
      );
    }
  }
}
