#!/usr/bin/env bash
# Fails when a Dart file outside the legacy list is longer than MAX_LINES.
# A file that grows past it is split by responsibility, not trimmed.
set -euo pipefail
cd "$(dirname "$0")/.."

MAX_LINES=${MAX_LINES:-200}
status=0

while IFS= read -r file; do
  lines=$(wc -l < "$file")
  if [ "$lines" -gt "$MAX_LINES" ]; then
    echo "$file: $lines lines (max $MAX_LINES)"
    status=1
  fi
done < <(scripts/lib-files.sh)

exit $status
