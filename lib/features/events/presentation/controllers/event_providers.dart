import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/network_providers.dart';
import '../../../authentication/presentation/controllers/authentication_controller.dart';
import '../../../preferences/domain/entities/event_seed.dart';
import '../../../../core/errors/failtures.dart';
import '../../data/event_api.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/event_use_cases.dart';

final eventApiProvider = Provider((ref) => EventApi(ref.watch(dioProvider)));
final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepositoryImpl(ref.watch(eventApiProvider)),
);
final eventUseCasesProvider = Provider(
  (ref) => EventUseCases(ref.watch(eventRepositoryProvider)),
);
final organizerEventsProvider = FutureProvider.autoDispose<List<EventSeed>>((
  ref,
) {
  ref.watch(authenticationControllerProvider.select((state) => state.session));
  return ref.watch(eventUseCasesProvider).organizerEvents();
});

String eventError(Object error) {
  if (error is Failure) return error.message;
  if (error is StateError) return error.message;
  return 'No pudimos completar la operación. Inténtalo de nuevo.';
}
