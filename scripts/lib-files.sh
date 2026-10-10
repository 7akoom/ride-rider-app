#!/usr/bin/env bash
# Prints the Dart files under lib/ that the checks apply to: everything except generated
# code and the legacy files listed in scripts/legacy-files.txt.
set -euo pipefail
cd "$(dirname "$0")/.."

legacy_patterns=$(mktemp)
trap 'rm -f "$legacy_patterns"' EXIT
grep -v '^#' scripts/legacy-files.txt | sed '/^$/d' > "$legacy_patterns"

find lib -name '*.dart' -not -path 'lib/l10n/gen/*' | sort | grep -vxF -f "$legacy_patterns" || true
