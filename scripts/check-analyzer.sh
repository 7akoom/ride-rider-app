#!/usr/bin/env bash
# Runs the analyzer over the whole project and judges the result:
#   - errors and warnings fail anywhere (legacy code included);
#   - infos (lints) fail in new code and tests; legacy files may keep theirs until
#     they are migrated.
set -euo pipefail
cd "$(dirname "$0")/.."

root="$(pwd)/"
report=$(mktemp)
legacy=$(mktemp)
trap 'rm -f "$report" "$legacy"' EXIT

grep -v '^#' scripts/legacy-files.txt | sed '/^$/d' > "$legacy"

# Machine format: SEVERITY|TYPE|CODE|FILE|LINE|COLUMN|LENGTH|MESSAGE, one issue per line.
rc=0
dart analyze --format=machine > "$report" 2>&1 || rc=$?

if [ $rc -ne 0 ] && ! grep -q '|' "$report"; then
  cat "$report" >&2
  echo "The analyzer itself failed." >&2
  exit $rc
fi

failed=0
while IFS='|' read -r severity _type code file line _col _len message; do
  [ -z "${file:-}" ] && continue
  path="${file#"$root"}"

  if [ "$severity" = "INFO" ] && grep -qxF "$path" "$legacy"; then
    continue
  fi

  echo "$severity $path:$line $code: $message"
  failed=1
done < <(grep '|' "$report")

if [ $failed -ne 0 ]; then
  echo "Analyzer issues above must be fixed." >&2
fi
exit $failed
