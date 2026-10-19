import 'package:flutter/material.dart';

/// Aviso de la app antes del diálogo del sistema (HU-5.1). Devuelve true
/// ("Permitir"), false ("Ahora no") o null si se cerró con Atrás.
class LocationConsentDialog extends StatelessWidget {
  const LocationConsentDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LocationConsentDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Permitir el acceso a tu ubicación?'),
      content: const Text(
        "Qué Hay Pa'? usa tu ubicación para mostrarte planes y eventos cerca "
        'de ti. Si no la compartes, usaremos Popayán como referencia. Puedes '
        'cambiarlo cuando quieras en Configuración.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Permitir'),
        ),
      ],
    );
  }
}
