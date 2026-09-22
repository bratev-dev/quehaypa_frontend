import 'package:flutter/material.dart';

class PlanCardImageAtom extends StatelessWidget {
  final bool isAddButton;

  /// Alto fijo legacy. Si es null, el átomo se expande al alto disponible
  /// del padre (ideal dentro de Flexible en la tarjeta del grid).
  final double? height;

  const PlanCardImageAtom({super.key, this.isAddButton = false, this.height});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: isAddButton
          ? const Center(child: Icon(Icons.add, size: 36, color: Colors.white))
          : null,
    );

    // Sin alto fijo: se expande al espacio flexible que le dé la tarjeta.
    // (Sin AspectRatio: dentro de un Flexible tight, imponer proporción
    //  puede desbordar el ancho de la celda.)
    if (height != null) return box;
    return SizedBox(width: double.infinity, child: box);
  }
}
