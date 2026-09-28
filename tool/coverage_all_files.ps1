$ErrorActionPreference = 'Stop'

# Equivalente nativo en Windows de coverage_all_files.sh.
$coverageRoot = Split-Path -Parent $PSScriptRoot
$coverageLib = Join-Path $coverageRoot 'lib'
$coverageOutput = Join-Path $coverageRoot 'test/coverage_all_files_test.dart'
$coverageManifest = Get-Content -LiteralPath (Join-Path $coverageRoot 'pubspec.yaml')
$coverageName = $coverageManifest | Where-Object { $_ -match '^name:\s*(\S+)\s*$' } | Select-Object -First 1
if (-not $coverageName) {
    throw 'No se encontró el nombre del paquete en pubspec.yaml.'
}
$coveragePackage = ($coverageName -replace '^name:\s*', '').Trim()
$coverageSources = Get-ChildItem -LiteralPath $coverageLib -Recurse -File -Filter '*.dart' |
    Where-Object { $_.Name -notmatch '\.(g|freezed)\.dart$' } |
    ForEach-Object { $_.FullName.Substring($coverageLib.Length + 1).Replace('\', '/') } |
    Sort-Object
$coverageLines = @(
    '// GENERADO por tool/coverage_all_files.ps1. No editar ni versionar.'
    '// ignore_for_file: unused_import'
)
$coverageLines += $coverageSources | ForEach-Object { "import 'package:${coveragePackage}/$_';" }
$coverageLines += @('', 'void main() {}', '')
[IO.File]::WriteAllText($coverageOutput, ($coverageLines -join "`n"), [Text.UTF8Encoding]::new($false))
Write-Output "Generado test/coverage_all_files_test.dart con $($coverageSources.Count) archivos de lib/."
