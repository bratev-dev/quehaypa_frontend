import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dashboard/controllers/dashboard_controller.dart';
import '../../../preferences/presentation/controllers/preferences_providers.dart';
import '../../../preferences/presentation/interest_catalog_fallback.dart';
import '../../../preferences/presentation/interests_colors.dart';
import '../../../preferences/presentation/organisms/interest_options.dart';
import '../../../preferences/presentation/templates/interests_template.dart';

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
    backgroundColor: interestsYellow,
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: interestsBlue,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    body: InterestsTemplate(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '¿Qué te apasiona?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: interestsBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (loading)
            const SizedBox(
              height: 160,
              child: Center(
                child: CircularProgressIndicator(color: interestsBlue),
              ),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: interestsBlue),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _load,
                      style: TextButton.styleFrom(
                        foregroundColor: interestsBlue,
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else
            InterestOptions(
              catalog: catalog,
              selected: selected,
              onToggle: (interest) => setState(() {
                if (!selected.add(interest)) {
                  selected.remove(interest);
                }
              }),
            ),
          if (!loading && error == null) ...[
            const SizedBox(height: 14),
            Text(
              'Selecciona al menos 4 intereses (${selected.length}/4)',
              textAlign: TextAlign.center,
              style: const TextStyle(color: interestsBlue),
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 259,
                child: FilledButton(
                  onPressed: selected.length < 4 || saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: interestsBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: interestsBlue.withValues(
                      alpha: 0.5,
                    ),
                    disabledForegroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(57),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(saving ? 'Guardando…' : 'Guardar intereses'),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
