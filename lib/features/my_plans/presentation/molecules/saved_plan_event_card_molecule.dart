import 'package:flutter/material.dart';

import '../../../preferences/domain/entities/event_seed.dart';
import '../../../events/presentation/event_image.dart';
import '../../../events/presentation/event_detail_page.dart';

class SavedPlanEventCardMolecule extends StatelessWidget {
  final EventSeed event;
  final bool canRemove;
  final bool isRemoving;
  final VoidCallback onRemove;

  const SavedPlanEventCardMolecule({
    super.key,
    required this.event,
    required this.canRemove,
    required this.isRemoving,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventImage(url: event.imageUrl, height: 100),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EventDetailPage(eventId: event.id),
                    ),
                  ),
                  child: const Text('Ver evento'),
                ),
                Text(
                  event.category.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (event.eventText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(event.eventText),
                ],
              ],
            ),
          ),
          if (canRemove) ...[
            const SizedBox(width: 8),
            isRemoving
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: onRemove,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE91E63),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Quitar'),
                  ),
          ],
        ],
      ),
    ),
  );
}
