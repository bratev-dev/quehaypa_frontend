import 'package:flutter/material.dart';

import '../organisms/dashboard_header.dart';
import '../molecules/event_card.dart';

class DashboardTemplate extends StatelessWidget {
  const DashboardTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // Header deslizable/colapsable con el arco y los círculos
          const SliverToBoxAdapter(child: DashboardHeader()),

          // Espaciado antes del feed
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Feed de eventos (Simulando las tarjetas del prototipo)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return EventCard(
                  title: 'Evento Cultural en Popayán #${index + 1}',
                  category: index.isEven ? 'Tecnología' : 'Música',
                  date: '15 Oct - 8:00 PM',
                );
              },
              childCount: 6, // Cantidad de elementos de prueba para el scroll
            ),
          ),

          // Margen inferior para comodidad visual
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
