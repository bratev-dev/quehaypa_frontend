import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_events.dart';

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final sessionEvents = SessionEvents();

  ref.onDispose(sessionEvents.dispose);

  return sessionEvents;
});

final sessionInvalidatedProvider = StreamProvider<void>((ref) {
  final sessionEvents = ref.watch(sessionEventsProvider);

  return sessionEvents.onSessionInvalidated;
});