import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/domain/entities/user.dart';
import '../../authentication/presentation/controllers/register_providers.dart';

final myProfileProvider = FutureProvider<User>((ref) {
  return ref.read(userRepositoryProvider).getProfile();
});
