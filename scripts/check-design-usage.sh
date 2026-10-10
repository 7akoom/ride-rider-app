#!/usr/bin/env bash
# Fails when code outside the legacy list bypasses the design system:
#   1. colours or font sizes/weights written directly, instead of context.palette and
#      context.typo (only lib/design/tokens and lib/design/theme may define them);
#   2. left/right instead of start/end, which breaks the Arabic and Kurdish layouts.
set -euo pipefail
cd "$(dirname "$0")/.."

mapfile -t files < <(scripts/lib-files.sh)
[ ${#files[@]} -eq 0 ] && exit 0

token_files=()
for f in "${files[@]}"; do
  case "$f" in
    lib/design/tokens/*|lib/design/theme/*) ;;
    *) token_files+=("$f") ;;
  esac
done

export LC_ALL=C.UTF-8
status=0

run() { # pattern, files...
  local pattern=$1; shift
  [ $# -eq 0 ] && return 0
  local rc=0
  grep -nP -- "$pattern" "$@" || rc=$?
  case $rc in
    0) status=1 ;;
    1) ;;
    *) echo "grep failed ($rc)" >&2; exit $rc ;;
  esac
}

# 1. Design tokens only.
run '\bColor\(0x' "${token_files[@]}"
run '\bColors\.(?!transparent\b)\w+' "${token_files[@]}"
run '\b(fontSize|fontWeight)\s*:' "${token_files[@]}"

# 2. Directional layout only.
run '\bEdgeInsets\.(only\([^)]*\b(left|right)\s*:|fromLTRB)' "${files[@]}"
run '\bAlignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)\b' "${files[@]}"
run '\bTextAlign\.(left|right)\b' "${files[@]}"
run '\bPositioned\([^)]*\b(left|right)\s*:' "${files[@]}"

if [ $status -ne 0 ]; then
  echo "Use context.palette / context.typo and start/end (EdgeInsetsDirectional," >&2
  echo "AlignmentDirectional, PositionedDirectional, TextAlign.start/end) instead." >&2
fi
exit $status
