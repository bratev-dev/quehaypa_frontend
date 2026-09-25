import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mocked_events.dart';
import 'dashboard_state.dart';

class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    return const DashboardState(
      userInterests: [
        'Tecnología',
        'Música',
        'Deportes',
        'Arte',
        'Cine',
        'Gastronomía',
      ], // TODO(QHP-78): hidratar desde User + PUT /preferences/me.
    );
  }

  /// Hidrata intereses persistidos (ej. tras registro) y re-filtra.
  void setUserInterests(List<String> interests) {
    state = state.copyWith(userInterests: interests);
    _applyFilter(state.selectedCategory);
  }

  // Seleccionar una categoría al hacer clic y filtrar eventos quemados.
  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _applyFilter(category);
  }

  void _applyFilter(String category) {
    if (category == 'General') {
      // Feed general: solo eventos de mis intereses (filtrado local QHP-78).
      final filtered = kMockedEvents
          .where((e) => state.userInterests.contains(e.category))
          .toList();
      state = state.copyWith(
        visibleEvents: filtered.isEmpty ? kMockedEvents : filtered,
      );
      return;
    }
    state = state.copyWith(
      visibleEvents: kMockedEvents
          .where((e) => e.category == category)
          .toList(),
    );
  }
}

// Declaración moderna con NotifierProvider
final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(() {
      return DashboardController();
    });
