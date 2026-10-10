#!/usr/bin/env bash
# Fails when code outside the legacy list contains text a user could see.
# All user-visible text lives in lib/l10n/app_*.arb and is read with context.l10n.
set -euo pipefail
cd "$(dirname "$0")/.."

mapfile -t files < <(scripts/lib-files.sh)
[ ${#files[@]} -eq 0 ] && exit 0

# Arabic-script letters (Arabic and Kurdish) anywhere in code, comments included.
arabic='[\x{0600}-\x{06FF}\x{0750}-\x{077F}\x{08A0}-\x{08FF}\x{FB50}-\x{FDFF}\x{FE70}-\x{FEFF}]'
# Text('literal') / Text("literal").
text_literal="\\bText\\(\\s*['\"][^'\"]"
# Literal strings in the usual user-facing widget arguments.
named_literal="\\b(hintText|labelText|helperText|errorText|counterText|prefixText|suffixText|tooltip|semanticLabel|semanticsLabel|title|subtitle|label)\\s*:\\s*['\"][^'\"]"

# Arabic letters need grep to read the files as UTF-8.
export LC_ALL=C.UTF-8

status=0
for pattern in "$arabic" "$text_literal" "$named_literal"; do
  rc=0
  grep -nP -- "$pattern" "${files[@]}" || rc=$?
  case $rc in
    0) status=1 ;;                                   # found something
    1) ;;                                            # clean
    *) echo "grep failed ($rc)" >&2; exit $rc ;;     # the check itself broke
  esac
done

if [ $status -ne 0 ]; then
  echo "Hardcoded user-visible text found above. Move it to lib/l10n/app_*.arb." >&2
fi
exit $status
