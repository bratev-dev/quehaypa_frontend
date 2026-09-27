import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/network_providers.dart';
import '../../data/datasources/organizer_remote_data_source.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../data/repositories/organizer_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/organizer_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/sync_organizer_use_case.dart';
import '../../domain/usecases/sync_profile_use_case.dart';
import '../../domain/usecases/update_profile_use_case.dart';
import '../../data/datasources/registration_remote_data_source.dart';
import '../../data/repositories/registration_repository_impl.dart';
import '../../domain/usecases/manage_registration_use_case.dart';
export '../../../../app/providers/network_providers.dart' show dioProvider;

final manageRegistrationUseCaseProvider = Provider<ManageRegistrationUseCase>((
  ref,
) {
  return ManageRegistrationUseCase(
    RegistrationRepositoryImpl(
      RegistrationRemoteDataSource(ref.read(dioProvider)),
    ),
  );
});

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(dio: ref.read(dioProvider));
});

final organizerRemoteDataSourceProvider = Provider<OrganizerRemoteDataSource>((
  ref,
) {
  return OrganizerRemoteDataSource(dio: ref.read(dioProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: ref.read(userRemoteDataSourceProvider),
  );
});

final organizerRepositoryProvider = Provider<OrganizerRepository>((ref) {
  return OrganizerRepositoryImpl(
    remoteDataSource: ref.read(organizerRemoteDataSourceProvider),
  );
});

final syncProfileUseCaseProvider = Provider<SyncProfileUseCase>((ref) {
  return SyncProfileUseCase(ref.read(userRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.read(userRepositoryProvider));
});

final syncOrganizerUseCaseProvider = Provider<SyncOrganizerUseCase>((ref) {
  return SyncOrganizerUseCase(ref.read(organizerRepositoryProvider));
});
