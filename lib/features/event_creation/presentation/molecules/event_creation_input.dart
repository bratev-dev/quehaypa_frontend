import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../event_creation_colors.dart';

class EventCreationInput extends StatelessWidget {
  const EventCreationInput({
    super.key,
    required this.hint,
    required this.onChanged,
    this.initialValue,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.readOnly = false,
    this.onTap,
    this.controller,
    this.onSubmitted,
    this.textAlign = TextAlign.start,
    this.contentPadding,
    this.fontSize = 16,
  });

  final String hint;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onSubmitted;
  final TextAlign textAlign;
  final EdgeInsetsGeometry? contentPadding;
  final double fontSize;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: initialValue,
    onChanged: onChanged,
    onFieldSubmitted: onSubmitted,
    readOnly: readOnly,
    onTap: onTap,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    maxLength: maxLength,
    textAlign: textAlign,
    style: TextStyle(color: EventCreationColors.black, fontSize: fontSize),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: EventCreationColors.hint,
        fontSize: 16,
        fontWeight: FontWeight.w300,
      ),
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      suffixIcon: suffix,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 25, vertical: 17),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(
          color: EventCreationColors.yellow,
          width: 2,
        ),
      ),
    ),
  );
}
