import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/event_api.dart';
import 'event_image.dart';
import 'event_detail_page.dart';

class OrganizerEventsPage extends ConsumerWidget {
  const OrganizerEventsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(organizerEventsProvider);
    return SafeArea(
      child: events.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eventError(error),
                style: const TextStyle(color: Colors.white),
              ),
              TextButton(
                onPressed: () => ref.invalidate(organizerEventsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(organizerEventsProvider);
            await ref.read(organizerEventsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 150),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const Text(
                'Mis eventos',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Crea tu primer evento desde el calendario.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              for (final event in items)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => EventDetailPage(eventId: event.id),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EventImage(url: event.imageUrl),
                        ListTile(
                          title: Text(event.title),
                          subtitle: Text(event.eventText),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
