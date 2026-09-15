import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      ], // Los intereses del usuario se deben de sacar de la clase usuario. Para Camilo
    );
  }

  // Seleccionar una categoría al hacer clic
  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  // Efecto de rotación tipo tambor de revólver
  void rotateRevolver(bool clockwise) {
    final currentOffset = state.revolverRotationOffset;
    final totalInterests = state.userInterests.length;

    int newOffset;
    if (clockwise) {
      newOffset = (currentOffset + 1) % totalInterests;
    } else {
      newOffset = (currentOffset - 1 + totalInterests) % totalInterests;
    }

    state = state.copyWith(revolverRotationOffset: newOffset);
  }
}

// Declaración moderna con NotifierProvider
final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(() {
      return DashboardController();
    });
