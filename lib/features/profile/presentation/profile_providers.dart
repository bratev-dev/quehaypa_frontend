import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/domain/entities/user.dart';
import '../../authentication/presentation/controllers/authentication_controller.dart';
import '../../authentication/presentation/controllers/register_providers.dart';
import '../domain/usecases/get_my_profile_use_case.dart';

final getMyProfileUseCaseProvider = Provider<GetMyProfileUseCase>((ref) {
  return GetMyProfileUseCase(
    ref.watch(userRepositoryProvider),
    ref.watch(organizerRepositoryProvider),
  );
});

final myProfileProvider = FutureProvider<User>((ref) {
  final identity = ref.watch(
    authenticationControllerProvider.select(
      (state) => (state.session?.subject, state.isOrganizer),
    ),
  );
  return ref.watch(getMyProfileUseCaseProvider)(isOrganizer: identity.$2);
});
