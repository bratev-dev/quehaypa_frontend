import 'package:flutter/material.dart';

class SearchInputAtom extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController controller;

  const SearchInputAtom({
    super.key,
    required this.onChanged,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Busca el nombre de tu plan',
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: Colors.white.withValues(alpha: 0.4),
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E1E), // Fondo gris oscuro tipo Spotify
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
