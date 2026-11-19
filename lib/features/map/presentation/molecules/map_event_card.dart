import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../events/presentation/event_image.dart';
import '../../../preferences/domain/entities/event_seed.dart';
import '../map_event_card_details.dart';

class MapEventCard extends StatelessWidget {
  const MapEventCard({super.key, required this.event, required this.onClose});

  final EventSeed event;
  final VoidCallback onClose;

  static const _pink = Color(0xFFEB4A9A);
  static const _yellow = Color(0xFFFCD413);
  static const _black = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    final details = MapEventCardDetails.fromEvent(event);
    final hasImage = event.imageUrl?.trim().isNotEmpty == true;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 10, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _pink,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      event.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Semantics(
                  label: 'Cerrar tarjeta del evento',
                  button: true,
                  child: InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(22),
                    child: SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _black,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/images/map_event_close.svg',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (hasImage) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: EventImage(url: event.imageUrl, height: 96),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              event.title,
              style: const TextStyle(
                color: _black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              details.when,
              style: const TextStyle(color: _black, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              details.where,
              style: const TextStyle(color: _black, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Tag(label: details.price, color: _yellow, textColor: _black),
                if (details.adultsOnly)
                  const _Tag(
                    label: 'Mayores de edad',
                    color: _black,
                    textColor: Colors.white,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
