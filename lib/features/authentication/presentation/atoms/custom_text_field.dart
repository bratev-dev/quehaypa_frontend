import 'package:flutter/material.dart';

/// Campo de texto con forma de píldora usado en los formularios de
/// autenticación. Al recibir el foco dibuja un borde de contraste con el
/// fondo de la pantalla: sobre fondo amarillo el borde es azul, y sobre
/// fondo azul el borde es amarillo. El color lo decide quien lo usa, según
/// el fondo de su pantalla.
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Color focusedBorderColor;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry contentPadding;
  final Color? hintColor;
  final List<BoxShadow>? boxShadow;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.focusedBorderColor,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 18,
    ),
    this.hintColor,
    this.boxShadow,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  FocusNode? _internalFocusNode;
  bool _hasFocus = false;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();

    // Si quien nos usa ya maneja su propio FocusNode (por ejemplo para
    // validar al salir del campo) lo reutilizamos en vez de crear otro.
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }

    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!mounted || _focusNode.hasFocus == _hasFocus) return;

    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: widget.boxShadow,
        // El borde se mantiene siempre con el mismo grosor (transparente
        // cuando no hay foco) para que el campo no cambie de tamaño.
        border: Border.all(
          color: _hasFocus ? widget.focusedBorderColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: widget.hintColor ?? Colors.grey,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: widget.contentPadding,
          suffixIcon: widget.suffixIcon,
        ),
      ),
    );
  }
}
