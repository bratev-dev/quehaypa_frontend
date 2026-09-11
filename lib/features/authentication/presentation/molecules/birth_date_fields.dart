import 'package:flutter/material.dart';

class BirthDateFields extends StatelessWidget {
  final TextEditingController ddController;
  final TextEditingController mmController;
  final TextEditingController yyController;

  const BirthDateFields({
    super.key,
    required this.ddController,
    required this.mmController,
    required this.yyController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ddController,
            keyboardType: TextInputType.number,
            maxLength: 2,
            decoration: const InputDecoration(labelText: 'DD', counterText: ''),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: mmController,
            keyboardType: TextInputType.number,
            maxLength: 2,
            decoration: const InputDecoration(labelText: 'MM', counterText: ''),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: yyController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'YY', counterText: ''),
          ),
        ),
      ],
    );
  }
}
