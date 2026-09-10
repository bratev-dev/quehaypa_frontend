import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/security_providers.dart';
import '../../core/security/session_events_provider.dart';
import '../../core/security/session_invalidator.dart';
import '../../features/authentication/data/services/session_invalidator_impl.dart';

final sessionInvalidatorProvider = Provider<SessionInvalidator>((ref) {
  return SessionInvalidatorImpl(
    tokenManager: ref.read(tokenManagerProvider),
    sessionEvents: ref.read(sessionEventsProvider),
  );
});
