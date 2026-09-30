import 'package:flutter/material.dart';

/// Aviso breve sobre las pantallas y hojas modales.
class TopStatusSnackbar {
  static OverlayEntry? _active;

  static void show(
    BuildContext context, {
    required String message,
    bool success = false,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    if (_active?.mounted ?? false) _active!.remove();
    _active?.dispose();
    _active = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: MediaQuery.paddingOf(overlayContext).top + 12,
        left: 16,
        right: 16,
        child: SafeArea(
          bottom: false,
          top: false,
          child: Material(
            elevation: 8,
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    success ? Icons.check_circle_rounded : Icons.info_rounded,
                    color: success
                        ? const Color(0xFF7ED66D)
                        : const Color(0xFFFFD600),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    _active = entry;
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (identical(_active, entry)) {
        if (entry.mounted) entry.remove();
        entry.dispose();
        _active = null;
      }
    });
  }
}
