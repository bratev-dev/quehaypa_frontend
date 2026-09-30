import 'package:flutter/material.dart';

import '../../../saved_to_plans/presentation/modals/save_to_plans_bottom_sheet.dart';

class EventCard extends StatelessWidget {
  final int eventId;
  final String title;
  final String category;
  final String date;

  const EventCard({
    super.key,
    required this.eventId,
    required this.title,
    required this.category,
    required this.date,
  });

  static const Color _pink = Color(0xFFFF4081);
  static const double _cardRadius = 24;
  static const double _contentPadding = 12;
  static const double _imageRadius = _cardRadius - _contentPadding;
  static const double _imageHeight = 180;
  static const double _actionSize = 44;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(_contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen o banner del evento
            Container(
              height: _imageHeight,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(_imageRadius),
              ),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: _contentPadding),
            Row(
              children: [
                // Etiqueta de categoría
                Expanded(
                  child: Container(
                    height: _actionSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _pink,
                      borderRadius: BorderRadius.circular(_actionSize / 2),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _gap),
                // Botón de compartir
                _CircleActionButton(
                  icon: Icons.share_outlined,
                  onPressed: () {
                    // Acción de compartir
                  },
                ),
                const SizedBox(width: _gap),
                // Botón de guardar / marcador (¡Aquí está la integración!)
                _CircleActionButton(
                  icon: Icons.bookmark_border,
                  onPressed: () {
                    // Despliega el bottom sheet estilo Spotify para guardar en planes
                    showSaveToPlansBottomSheet(
                      context,
                      eventId: eventId,
                      eventTitle: title,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: EventCard._pink,
        foregroundColor: Colors.white,
        fixedSize: const Size.square(EventCard._actionSize),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
