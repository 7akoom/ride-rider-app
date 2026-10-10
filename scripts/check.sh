#!/usr/bin/env bash
# Everything that must pass before a commit.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== dependencies and generated translations"
flutter pub get
flutter gen-l10n

echo "== no hardcoded user-visible text"
scripts/check-hardcoded-strings.sh

echo "== design system used (tokens, start/end)"
scripts/check-design-usage.sh

echo "== no oversized files"
scripts/check-file-size.sh

echo "== analyzer (new code spotless; legacy code: no errors or warnings)"
scripts/check-analyzer.sh

echo "== tests"
flutter test

echo "All checks passed."
