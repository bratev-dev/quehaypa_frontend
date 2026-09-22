import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plans/presentation/controllers/plans_controller.dart';
import '../templates/my_plans_template.dart';

/// Página canónica de Mis Planes (UI Spotify + backend real).
/// Dispara `GET /my-plans` al entrar para que el grid y el bottom-sheet
/// siempre vean datos frescos.
class MyPlansPage extends ConsumerStatefulWidget {
  const MyPlansPage({super.key});

  @override
  ConsumerState<MyPlansPage> createState() => _MyPlansPageState();
}

class _MyPlansPageState extends ConsumerState<MyPlansPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(plansControllerProvider.notifier).loadMyPlans(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFD600),
      body: MyPlansTemplate(),
    );
  }
}
