import 'package:flutter/material.dart';

/// Acciones persistentes para la página Mis planes.
class PlanActionsSpeedDial extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onCreate;
  final bool hasPlans;
  final bool hasOwnedPlans;

  const PlanActionsSpeedDial({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.onShare,
    required this.onDelete,
    required this.onCreate,
    required this.hasPlans,
    required this.hasOwnedPlans,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: isOpen
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Action(
                    label: 'Compartir',
                    icon: Icons.ios_share_rounded,
                    onPressed: hasPlans ? onShare : null,
                  ),
                  _Action(
                    label: 'Eliminar',
                    icon: Icons.delete_outline_rounded,
                    onPressed: hasOwnedPlans ? onDelete : null,
                  ),
                  _Action(
                    label: 'Crear',
                    icon: Icons.add_rounded,
                    onPressed: onCreate,
                  ),
                  const SizedBox(height: 8),
                ],
              )
            : const SizedBox.shrink(),
      ),
      FloatingActionButton(
        heroTag: 'my-plans-actions',
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFFD600),
        tooltip: isOpen ? 'Cerrar acciones' : 'Abrir acciones del plan',
        onPressed: onToggle,
        child: AnimatedRotation(
          turns: isOpen ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.add_rounded, size: 30),
        ),
      ),
    ],
  );
}

class _Action extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _Action({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: onPressed == null ? Colors.black45 : Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          height: 52,
          child: FloatingActionButton(
            heroTag: 'my-plans-action-$label',
            backgroundColor: onPressed == null
                ? Colors.grey.shade400
                : const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            tooltip: label,
            onPressed: onPressed,
            child: Icon(icon),
          ),
        ),
      ],
    ),
  );
}
