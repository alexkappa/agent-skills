#!/usr/bin/env bash
# Usage: check-guide.sh <repo-dir>
set -euo pipefail

repo=$(cd "${1:?usage: check-guide.sh <repo-dir>}" && pwd)
start='<!-- coding-principles:start -->'
end='<!-- coding-principles:end -->'
detail=docs/coding-principles.md
failures=0

fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

block=
if [ -f "$repo/AGENTS.md" ]; then
  block=$(sed -n "/^$start\$/,/^$end\$/p" "$repo/AGENTS.md")
else
  fail "AGENTS.md is missing"
fi
[ "$(grep -cxF "$start" <<<"$block" || true)" -ge 1 ] || fail "missing start marker"
[ "$(grep -cxF "$end" <<<"$block" || true)" -ge 1 ] || fail "missing end marker"
[ "$(grep -cxF "$start" "$repo/AGENTS.md" 2>/dev/null || true)" -le 1 ] || fail "start marker appears more than once"
[ "$(grep -cxF "$end" "$repo/AGENTS.md" 2>/dev/null || true)" -le 1 ] || fail "end marker appears more than once"

lines=$(grep -c '' <<<"$block" || true)
[ "$lines" -le 90 ] || fail "block is $lines lines, over the 90 limit"

previous=0
for heading in '## Coding principles' '### Rules' '### Canonical modules' '### When designing' '### Severity'; do
  n=$(grep -nxF -m1 "$heading" <<<"$block" | cut -d: -f1 || true)
  if [ -z "$n" ]; then
    fail "missing heading: $heading"
  else
    [ "$n" -gt "$previous" ] || fail "heading out of order: $heading"
    previous=$n
  fi
done

designing=$(sed -n '/^### When designing$/,/^### Severity$/p' <<<"$block")
grep -qF 'applying-coding-principles' <<<"$designing" || fail "### When designing does not name applying-coding-principles"
grep -qF 'Coding principles applied' <<<"$designing" || fail "### When designing does not name \"Coding principles applied\""

grep -qxF 'Breaking a rule in this guide is an Important finding.' <<<"$block" || fail "### Severity text is not exact"

if [ ! -f "$repo/$detail" ]; then
  fail "$detail is missing"
else
  grep -qx '# Coding principles' "$repo/$detail" || fail "$detail has no # Coding principles title"
  grep -qx '## Decisions' "$repo/$detail" || fail "$detail has no ## Decisions"

  while IFS= read -r problem; do fail "$problem"; done < <(awk '
    function check() {
      if (name == "" || name == "Decisions") return
      if (!follow) print "principle \"" name "\" has no ### Follow"
      if (!avoid) print "principle \"" name "\" has no ### Avoid"
    }
    /^## / { check(); name = substr($0, 4); follow = avoid = 0; next }
    /^### Follow$/ { follow = 1 }
    /^### Avoid$/ { avoid = 1 }
    END { check() }
  ' "$repo/$detail")

  undated=$(sed -n '/^## Decisions$/,$p' "$repo/$detail" | grep '^- ' | grep -vE '— decided [0-9]{4}-[0-9]{2}-[0-9]{2}$' || true)
  [ -z "$undated" ] || fail "decision line lacks '— decided YYYY-MM-DD': $undated"
fi

# Cited paths: backticked tokens ending in a file extension (optionally :line) or in /
path_re='^[A-Za-z0-9_./@-]+\.[A-Za-z0-9]{1,5}(:[0-9]+)?$|^[A-Za-z0-9_./@-]+/$'
while IFS= read -r token; do
  [[ $token =~ $path_re ]] || continue
  file=${token%%:*}
  line=
  [ "$file" = "$token" ] || line=${token#*:}
  if [ ! -e "$repo/$file" ]; then
    fail "cited path does not exist: $file"
  elif [ -n "$line" ] && [ "$line" -gt "$(awk 'END { print NR }' "$repo/$file")" ]; then
    fail "cited line past end of file: $token"
  fi
done < <({ echo "$block"; [ ! -f "$repo/$detail" ] || cat "$repo/$detail"; } | awk '/^```/ { skip = !skip; next } !skip' | { grep -o '`[^`]*`' || true; } | tr -d '`' | sort -u)

if [ -f "$repo/CLAUDE.md" ] && ! grep -qE '^@AGENTS\.md[[:space:]]*$' "$repo/CLAUDE.md"; then
  echo "WARN: CLAUDE.md does not import @AGENTS.md"
fi

[ "$failures" -eq 0 ]
