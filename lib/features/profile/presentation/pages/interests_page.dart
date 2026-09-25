import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/atoms/interest_chip.dart';
import '../../../dashboard/controllers/dashboard_controller.dart';
import '../../../preferences/presentation/controllers/preferences_providers.dart';
import '../../../preferences/presentation/interest_catalog_fallback.dart';
import '../profile_colors.dart';

class InterestsPage extends ConsumerStatefulWidget {
  const InterestsPage({super.key});

  @override
  ConsumerState<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends ConsumerState<InterestsPage> {
  List<String> catalog = fallbackInterests;
  Set<String> selected = {};
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final provider = ref.read(getInterestsUseCaseProvider);
      final mineProvider = ref.read(getMyPreferencesUseCaseProvider);
      final result = await Future.wait([
        provider().then((items) => items.map((item) => item.name).toList()),
        mineProvider(),
      ]);
      if (!mounted) return;
      setState(() {
        catalog = {...result[0], ...result[1]}.toList();
        selected = result[1].toSet();
        loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'No pudimos recuperar tus intereses guardados. Reintenta antes de cambiarlos.';
        });
      }
    }
  }

  Future<void> _save() async {
    if (saving || selected.length < 4) return;
    setState(() => saving = true);
    try {
      final saved = await ref.read(saveMyPreferencesUseCaseProvider)(
        selected.toList(),
      );
      ref.read(dashboardControllerProvider.notifier).setUserInterests(saved);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron guardar los intereses: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: profileBackground,
    appBar: AppBar(
      title: const Text('Mis intereses'),
      backgroundColor: profileBackground,
      foregroundColor: Colors.white,
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Qué te apasiona?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona al menos 4 intereses (${selected.length}/4)',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            if (loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: profileYellow),
                ),
              )
            else if (error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: catalog
                        .map(
                          (interest) => InterestChip(
                            label: interest,
                            isSelected: selected.contains(interest),
                            onTap: () => setState(() {
                              if (!selected.add(interest)) {
                                selected.remove(interest);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            if (!loading && error == null)
              FilledButton(
                onPressed: selected.length < 4 || saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: profileYellow,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text(saving ? 'Guardando…' : 'Guardar intereses'),
              ),
          ],
        ),
      ),
    ),
  );
}
