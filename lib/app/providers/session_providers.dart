import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/session_refresher.dart';
import '../../features/authentication/data/services/session_refresher_impl.dart';
import '../../features/authentication/presentation/controllers/authentication_providers.dart';

final sessionRefresherProvider = Provider<SessionRefresher>((ref) {
  return SessionRefresherImpl(
    refreshSessionUseCase: ref.read(refreshSessionUseCaseProvider),
  );
});
