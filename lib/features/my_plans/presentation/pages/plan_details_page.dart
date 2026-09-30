import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plans/domain/entities/plan.dart';
import '../../../plans/presentation/controllers/plans_providers.dart';
import '../../../preferences/domain/entities/event_seed.dart';

/// Vista de consulta de los eventos guardados en un plan.
class PlanDetailsPage extends ConsumerStatefulWidget {
  final Plan plan;

  const PlanDetailsPage({super.key, required this.plan});

  @override
  ConsumerState<PlanDetailsPage> createState() => _PlanDetailsPageState();
}

class _PlanDetailsPageState extends ConsumerState<PlanDetailsPage>
    with SingleTickerProviderStateMixin {
  List<EventSeed>? _events;
  String? _error;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _events = null;
      _error = null;
    });
    try {
      final events = await ref.read(getPlanEventsUseCaseProvider)(
        widget.plan.id,
      );
      if (mounted) setState(() => _events = events);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No pudimos cargar los eventos del plan.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Scaffold(
      backgroundColor: const Color(0xFFFFD600),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD600),
        foregroundColor: Colors.black,
        title: const Text('Mi plan'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              plan.title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(plan.description, style: const TextStyle(fontSize: 15)),
            ],
            const SizedBox(height: 28),
            const Text(
              'Eventos guardados',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              _StatusCard(
                icon: Icons.cloud_off_outlined,
                message: _error!,
                buttonLabel: 'Reintentar',
                onPressed: _load,
              )
            else if (_events == null)
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Column(
                  children: List.generate(
                    3,
                    (_) => Container(
                      height: 96,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.white54,
                          Colors.white,
                          _pulse.value,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              )
            else if (_events!.isEmpty)
              const _StatusCard(
                icon: Icons.event_available_outlined,
                message: 'Todavía no hay eventos en este plan. Explora y guarda uno.',
              )
            else
              ..._events!.map(
                (event) => Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  const _StatusCard({
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(icon, size: 40, color: const Color(0xFFE91E63)),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        if (buttonLabel != null && onPressed != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: onPressed, child: Text(buttonLabel!)),
        ],
      ],
    ),
  );
}
