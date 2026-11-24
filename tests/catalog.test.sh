#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
dir="$here/../skills/setting-up-coding-principles/references/principles"
failures=0

pass() { echo "ok   $1"; }
bad() { echo "FAIL $1"; failures=$((failures + 1)); }

sections='## Principle
## Signals in code
## Ask when
## Writing the repo rule
## Lint enforcement'

# H1 and H2 lines outside fenced code blocks.
headings() { awk '/^```/ { fenced = !fenced; next } !fenced && /^##? /' "$1"; }

while IFS='|' read -r file name; do
  path="$dir/$file"
  if [ ! -f "$path" ]; then bad "$file: exists"; continue; fi
  pass "$file: exists"

  [ "$(headings "$path" | grep '^# ')" = "# $name" ] && pass "$file: H1 is \"$name\"" || bad "$file: H1 is \"$name\""
  [ "$(headings "$path" | grep '^## ')" = "$sections" ] && pass "$file: sections in order" || bad "$file: sections in order"

  lines=$(awk 'END { print NR }' "$path")
  [ "$lines" -le 60 ] && pass "$file: at most 60 lines" || bad "$file: at most 60 lines (has $lines)"
done <<'CATALOG'
deep-modules.md|Deep modules
one-owner.md|One owner per piece of knowledge
reuse-before-building.md|Reuse before building
naming.md|Naming is a design signal
consistency.md|Consistency with the repo
comments.md|Comments
no-defensive-padding.md|No defensive padding
make-the-change-easy.md|Make the change easy, then make the easy change
CATALOG

[ "$failures" -eq 0 ] || { echo "$failures failed"; exit 1; }
echo "all passed"
