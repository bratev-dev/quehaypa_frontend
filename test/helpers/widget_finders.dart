import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Campo de texto identificado por su hint (los formularios no usan labels).
Finder fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

/// Pantalla amplia para que los formularios completos quepan sin desbordes.
/// La fuente de pruebas dibuja cada letra tan ancha como alta, así que los
/// textos ocupan bastante más que en un teléfono con la fuente real.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(2000, 2800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}
