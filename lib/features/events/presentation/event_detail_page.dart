import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/controllers/authentication_controller.dart';
import '../../preferences/domain/entities/event_seed.dart';
import '../../saved_to_plans/presentation/modals/save_to_plans_bottom_sheet.dart';
import '../data/event_api.dart';
import 'event_image.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({super.key, required this.eventId});
  final int eventId;
  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  EventSeed? event;
  bool registered = false, loading = true, saving = false;
  String? error;
  String? registrationError;
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
      registrationError = null;
    });
    try {
      final api = ref.read(eventApiProvider);
      final result = await api.get(widget.eventId);
      final isOrganizer = ref
          .read(authenticationControllerProvider)
          .isOrganizer;
      if (mounted) setState(() => event = result);
      if (!isOrganizer) {
        try {
          final status = await api.registration(widget.eventId);
          if (mounted) setState(() => registered = status);
        } catch (e) {
          if (mounted) setState(() => registrationError = eventError(e));
        }
      }
    } catch (e) {
      if (mounted) setState(() => error = eventError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _toggle() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await ref
          .read(eventApiProvider)
          .setRegistered(widget.eventId, !registered);
      if (mounted) setState(() => registered = !registered);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(eventError(e))));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizer = ref.watch(
      authenticationControllerProvider.select((s) => s.isOrganizer),
    );
    final value = event;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del evento')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              ),
            )
          : value == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: EventImage(url: value.imageUrl, height: 240),
                ),
                const SizedBox(height: 16),
                Text(
                  value.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(value.category),
                Text(value.eventText),
                if (value.endsAt != null)
                  Text(
                    'Finaliza: ${value.endsAt.toString().replaceFirst("T", " ")}',
                  ),
                Text(
                  [
                    value.city,
                    value.venue,
                  ].where((s) => s != null && s.isNotEmpty).join(' · '),
                ),
                Text(
                  value.audience == 'ADULTS_ONLY'
                      ? 'Solo mayores de 18 años'
                      : 'Todo público',
                ),
                const SizedBox(height: 16),
                Text(value.description),
                if (!organizer) ...[
                  const SizedBox(height: 24),
                  if (registrationError != null) ...[
                    Text(registrationError!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Reintentar inscripción'),
                    ),
                  ],
                  FilledButton(
                    onPressed: saving || registrationError != null
                        ? null
                        : _toggle,
                    child: Text(
                      saving
                          ? 'Guardando…'
                          : registered
                          ? 'Cancelar inscripción'
                          : 'Inscribirme',
                    ),
                  ),
                  if (registered)
                    const Text(
                      'Estás inscrito en este evento.',
                      textAlign: TextAlign.center,
                    ),
                  OutlinedButton(
                    onPressed: () => showSaveToPlansBottomSheet(
                      context,
                      eventId: value.id,
                      eventTitle: value.title,
                    ),
                    child: const Text('Agregar a un plan'),
                  ),
                ],
              ],
            ),
    );
  }
}
