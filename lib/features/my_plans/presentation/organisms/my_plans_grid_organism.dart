import 'package:flutter/material.dart';

import '../molecules/plan_card_molecule.dart';
import 'create_plan_modal.dart'; // Importa tu modal de creación

class MyPlansGridOrganism extends StatefulWidget {
  const MyPlansGridOrganism({super.key});

  @override
  State<MyPlansGridOrganism> createState() => _MyPlansGridOrganismState();
}

class _MyPlansGridOrganismState extends State<MyPlansGridOrganism> {
  final List<String> _plans = ['P0', 'Plan 2', 'Plan 3', 'Plan 4', 'Plan 5'];

  @override
  Widget build(BuildContext context) {
    final totalCount = _plans.length + 1;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index == _plans.length) {
          return PlanCardMolecule(
            isAddCard: true,
            title: '',
            onTap: () {
              showCreatePlanModal(context);
            },
            onViewMore: () {},
          );
        }

        final planName = _plans[index];

        return Dismissible(
          key: Key(planName),
          direction: DismissDirection.horizontal,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delete_sweep_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          onDismissed: (direction) {
            final deletedPlan = planName;
            final deletedIndex = index;

            setState(() {
              _plans.removeAt(index);
            });

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF1E1E1E),
                content: Text(
                  'Plan "$deletedPlan" eliminado',
                  style: const TextStyle(color: Colors.white),
                ),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'DESHACER',
                  textColor: const Color(0xFFFFD600),
                  onPressed: () {
                    setState(() {
                      _plans.insert(deletedIndex, deletedPlan);
                    });
                  },
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          child: PlanCardMolecule(
            title: planName,
            onTap: () {
              // Lógica al tocar la tarjeta del plan
            },
            onViewMore: () {
              // Lógica al tocar "Ver más"
            },
          ),
        );
      },
    );
  }
}
