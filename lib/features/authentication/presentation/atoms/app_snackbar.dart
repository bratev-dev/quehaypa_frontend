import 'package:flutter/material.dart';

enum SnackbarType { error, success, info }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.error,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    Color backgroundColor;
    IconData iconData;

    switch (type) {
      case SnackbarType.success:
        backgroundColor = const Color(0xFF2E7D32); // Verde éxito
        iconData = Icons.check_circle_outline;
        break;
      case SnackbarType.info:
        backgroundColor = const Color(0xFFF57C00); // Naranja institucional para advertencias/info
        iconData = Icons.warning_amber_rounded;
        break;
      case SnackbarType.error:
      backgroundColor = const Color(0xFFD32F2F); // Rojo para errores
        iconData = Icons.error_outline;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}