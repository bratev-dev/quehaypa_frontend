import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failtures.dart';
import '../../preferences/presentation/controllers/preferences_providers.dart';
import 'dashboard_state.dart';

class DashboardController extends Notifier<DashboardState> {
  bool _feedStarted = false;
  int _request = 0;
  int _preferencesVersion = 0;

  @override
  DashboardState build() => const DashboardState();

  void setUserInterests(List<String> interests) {
    _preferencesVersion++;
    final category = interests.contains(state.selectedCategory)
        ? state.selectedCategory
        : 'General';
    state = state.copyWith(
      userInterests: List<String>.unmodifiable(interests),
      selectedCategory: category,
    );
    if (_feedStarted) {
      loadEvents();
    }
  }

  Future<void> load() async {
    _feedStarted = true;
    final preferences = ref.read(getMyPreferencesUseCaseProvider);
    final events = loadEvents();
    final preferencesVersion = _preferencesVersion;
    try {
      final interests = await preferences();
      if (ref.mounted && preferencesVersion == _preferencesVersion) {
        state = state.copyWith(userInterests: interests);
      }
    } catch (_) {
      // Un organizador puede consultar eventos sin preferencias de usuario regular.
    }
    await events;
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    if (_feedStarted) {
      loadEvents();
    }
  }

  Future<void> loadEvents() async {
    _feedStarted = true;
    final request = ++_request;
    final category = state.selectedCategory;
    state = state.copyWith(
      status: DashboardStatus.loading,
      visibleEvents: const [],
    );
    try {
      final events = category == 'General'
          ? await ref.read(getEventsFeedUseCaseProvider)()
          : await ref.read(getEventsUseCaseProvider)(category: category);
      if (!ref.mounted || request != _request) {
        return;
      }
      state = state.copyWith(
        status: DashboardStatus.success,
        visibleEvents: events,
      );
    } on Failure catch (error) {
      _showError(request, error.message);
    } catch (_) {
      _showError(request, 'No pudimos cargar los eventos. Inténtalo de nuevo.');
    }
  }

  void _showError(int request, String message) {
    if (!ref.mounted || request != _request) {
      return;
    }
    state = state.copyWith(
      status: DashboardStatus.error,
      visibleEvents: const [],
      errorMessage: message,
    );
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );
