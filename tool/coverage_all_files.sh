#!/usr/bin/env bash
# Genera una prueba vacía que importa todos los archivos de lib/.
#
# `flutter test --coverage` solo reporta los archivos que alguna prueba
# importa: los que nadie prueba desaparecen del lcov y la cobertura se infla.
# Con esta prueba cada archivo aparece, y el que no tiene pruebas cuenta 0 %.
#
# El archivo generado está en .gitignore: se crea en el CI justo antes de
# `flutter test --coverage` (y después de `dart format` y `flutter analyze`).
set -euo pipefail

output="test/coverage_all_files_test.dart"
package="$(sed -n 's/^name: *//p' pubspec.yaml | head -n 1)"

{
  echo "// GENERADO por tool/coverage_all_files.sh. No editar ni versionar."
  echo "// ignore_for_file: unused_import"
  find lib -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' | sort |
    sed "s|^lib/\(.*\)$|import 'package:${package}/\1';|"
  echo
  echo "void main() {}"
} > "$output"

echo "Generado $output con $(grep -c '^import' "$output") archivos de lib/."
