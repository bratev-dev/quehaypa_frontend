import '../repositories/registration_repository.dart';

class ManageRegistrationUseCase {
  final RegistrationRepository _repository;
  const ManageRegistrationUseCase(this._repository);
  Future<bool> begin() => _repository.begin();
  Future<void> complete() => _repository.complete();
  Future<void> cancel() => _repository.cancel();
}
