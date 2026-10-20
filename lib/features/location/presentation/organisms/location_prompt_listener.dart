import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/top_status_snackbar.dart';
import '../controllers/location_controller.dart';
import '../controllers/location_state.dart';
import '../molecules/location_consent_dialog.dart';

/// Al montarse (al abrir el feed) inicia el flujo de ubicación, muestra el
/// aviso de la app cuando toca y sus mensajes. No dibuja nada: devuelve [child].
class LocationPromptListener extends ConsumerStatefulWidget {
  final Widget child;

  const LocationPromptListener({super.key, required this.child});

  @override
  ConsumerState<LocationPromptListener> createState() =>
      _LocationPromptListenerState();
}

class _LocationPromptListenerState
    extends ConsumerState<LocationPromptListener> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(locationControllerProvider.notifier).onFeedOpened();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LocationState>(locationControllerProvider, (previous, next) {
      if (next.status == LocationStatus.askingConsent &&
          previous?.status != LocationStatus.askingConsent) {
        _askConsent();
      }
      final notice = next.notice;
      if (notice != null && notice != previous?.notice) {
        TopStatusSnackbar.show(context, message: notice.message);
      }
    });
    return widget.child;
  }

  Future<void> _askConsent() async {
    final allowed = await LocationConsentDialog.show(context);
    if (!mounted) return;
    final controller = ref.read(locationControllerProvider.notifier);
    switch (allowed) {
      case true:
        await controller.allow();
      case false:
        await controller.decline();
      case null:
        controller.dismiss();
    }
  }
}
