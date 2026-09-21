import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/controllers/register_providers.dart';
import '../../data/datasources/preferences_remote_data_source.dart';
import '../../data/repositories/preferences_repository_impl.dart';
import '../../domain/repositories/preferences_repository.dart';
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
