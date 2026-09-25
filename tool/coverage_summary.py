"""Resume coverage/lcov.info con el mismo alcance que SonarCloud.

Lee `sonar.coverage.exclusions` de sonar-project.properties (única fuente de
la lista) y muestra dos cifras: la del alcance declarado y la total sin
exclusiones, más los archivos medidos con menos cobertura. Escribe en
$GITHUB_STEP_SUMMARY si existe; si no, en la salida estándar.

Uso: python3 tool/coverage_summary.py
"""

import os
import re
import sys


def sonar_exclusions(path="sonar-project.properties"):
    text = open(path, encoding="utf-8").read()
    # Une las líneas continuadas con "\" antes de buscar la propiedad.
    text = re.sub(r"\\\r?\n\s*", "", text)
    match = re.search(r"^sonar\.coverage\.exclusions=(.*)$", text, re.M)
    if not match:
        return []
    return [p.strip() for p in match.group(1).split(",") if p.strip()]


def glob_to_regex(pattern):
    # Sintaxis de Sonar: ** = cualquier cantidad de carpetas, * = parte de un nombre.
    out = ""
    i = 0
    while i < len(pattern):
        if pattern.startswith("**/", i):
            out += "(?:.*/)?"
            i += 3
        elif pattern.startswith("**", i):
            out += ".*"
            i += 2
        elif pattern[i] == "*":
            out += "[^/]*"
            i += 1
        else:
            out += re.escape(pattern[i])
            i += 1
    return re.compile(out + "$")


def read_lcov(path="coverage/lcov.info"):
    files = {}
    current = None
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if line.startswith("SF:"):
            current = line[3:].replace("\\", "/")
            files.setdefault(current, [0, 0])
        elif line.startswith("DA:") and current:
            hits = int(line[3:].split(",")[1])
            files[current][0] += 1
            files[current][1] += hits > 0
    return files


def pct(covered, total):
    return 100.0 * covered / total if total else 0.0


def main():
    excluded = [glob_to_regex(p) for p in sonar_exclusions()]
    files = read_lcov()
    in_scope = {
        f: v for f, v in files.items() if not any(r.match(f) for r in excluded)
    }

    def totals(group):
        return sum(v[0] for v in group.values()), sum(v[1] for v in group.values())

    scope_lines, scope_cov = totals(in_scope)
    all_lines, all_cov = totals(files)

    out = [
        "## Cobertura del frontend (flutter test)",
        "",
        "| Alcance | Líneas cubiertas | Cobertura |",
        "|---|---:|---:|",
        f"| Medido (sin widgets solo visuales, como SonarCloud) | {scope_cov}/{scope_lines}"
        f" | **{pct(scope_cov, scope_lines):.1f} %** |",
        f"| Total de lib/ sin exclusiones | {all_cov}/{all_lines}"
        f" | {pct(all_cov, all_lines):.1f} % |",
        "",
        f"Archivos: {len(in_scope)} medidos, {len(files) - len(in_scope)} excluidos"
        " (lista en `sonar-project.properties`).",
        "",
        "### Archivos medidos con menos cobertura",
        "",
        "| Archivo | Sin cubrir | Cobertura |",
        "|---|---:|---:|",
    ]
    worst = sorted(in_scope.items(), key=lambda kv: kv[1][1] - kv[1][0])[:10]
    for name, (lines, cov) in worst:
        if lines > cov:
            out.append(f"| `{name}` | {lines - cov} | {pct(cov, lines):.1f} % |")

    report = "\n".join(out) + "\n"
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write(report)
    sys.stdout.write(report)


if __name__ == "__main__":
    main()
