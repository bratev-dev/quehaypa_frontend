import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/network_providers.dart';
import '../../data/datasources/preferences_remote_data_source.dart';
import '../../data/repositories/preferences_repository_impl.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../../domain/usecases/get_events_feed_use_case.dart';
import '../../domain/usecases/get_interests_use_case.dart';
import '../../domain/usecases/get_my_preferences_use_case.dart';
import '../../domain/usecases/save_preferences_use_case.dart';

final preferencesRemoteDataSourceProvider =
    Provider<PreferencesRemoteDataSource>((ref) {
      return PreferencesRemoteDataSource(dio: ref.read(dioProvider));
    });

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepositoryImpl(
    remoteDataSource: ref.read(preferencesRemoteDataSourceProvider),
  );
});

final saveMyPreferencesUseCaseProvider = Provider<SaveMyPreferences>((ref) {
  return SaveMyPreferences(ref.read(preferencesRepositoryProvider));
});

final getInterestsUseCaseProvider = Provider<GetInterests>((ref) {
  return GetInterests(ref.read(preferencesRepositoryProvider));
});

final getMyPreferencesUseCaseProvider = Provider<GetMyPreferences>((ref) {
  return GetMyPreferences(ref.read(preferencesRepositoryProvider));
});

final getEventsFeedUseCaseProvider = Provider<GetEventsFeed>((ref) {
  return GetEventsFeed(ref.read(preferencesRepositoryProvider));
});
