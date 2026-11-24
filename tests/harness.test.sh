#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
failures=0

pass() { echo "ok   $1"; }
bad() { echo "FAIL $1"; failures=$((failures + 1)); }

check() { # check <name> <command...>
  local name=$1; shift
  if "$@" >/dev/null 2>&1; then pass "$name"; else bad "$name"; fi
}

# A well-formed guide in a fresh fixture repo; prints the repo dir.
make_good() {
  local dir
  dir=$("$here/fixture-copy.sh" none)
  mkdir -p "$dir/docs"
  cat > "$dir/AGENTS.md" <<'GUIDE'
# Billing app

<!-- coding-principles:start -->
## Coding principles

### Rules
- Use `request` for HTTP; see `src/lib/http.ts:3`.
- Hide currency rules in `src/lib/money.ts:10`.
- Keep layers honest; lint rule `import/no-restricted-paths` enforces it.

### Canonical modules
- `src/lib/` holds shared helpers.

### When designing
Use the `applying-coding-principles` skill, and copy the "Coding principles applied" section verbatim into the plan's Global Constraints.

### Severity
Breaking a rule in this guide is an Important finding.
<!-- coding-principles:end -->
GUIDE
  cat > "$dir/docs/coding-principles.md" <<'DETAIL'
# Coding principles

## Deep modules

### Follow
- Hide detail behind a small interface, as in `src/lib/money.ts`.

### Avoid
- Thin wrappers such as `src/api/invoices-client.ts`.

## Decisions
- Keep one HTTP client — decided 2026-11-23
DETAIL
  echo "$dir"
}

edit() { # edit <file> <sed-expression>
  sed "$2" "$1" > "$1.new" && mv "$1.new" "$1"
}

expect_fail() { # expect_fail <name> <repo> <substring>
  local out status=0
  out=$("$here/check-guide.sh" "$2" 2>&1) || status=$?
  if [ "$status" -eq 1 ] && grep -qF "FAIL: $3" <<<"$out"; then pass "$1"; else bad "$1"; fi
}

# fixture-copy.sh
none=$("$here/fixture-copy.sh" none)
check "none: has src/lib/http.ts" test -f "$none/src/lib/http.ts"
check "none: no AGENTS.md" test ! -e "$none/AGENTS.md"
check "none: no CLAUDE.md" test ! -e "$none/CLAUDE.md"
[ "$(git -C "$none" rev-list --count HEAD)" = 1 ] && pass "none: one commit" || bad "none: one commit"

agents=$("$here/fixture-copy.sh" agents-md)
check "agents-md: AGENTS.md exists" test -f "$agents/AGENTS.md"
[ -z "$(find "$agents" -name '*.fixture')" ] && pass "agents-md: no .fixture left" || bad "agents-md: no .fixture left"

status=0
"$here/fixture-copy.sh" nope >/dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] && pass "unknown variant exits 2" || bad "unknown variant exits 2"

# check-guide.sh
good=$(make_good)
check "good guide passes" "$here/check-guide.sh" "$good"

r=$(make_good)
edit "$r/AGENTS.md" '/coding-principles:end/d'
expect_fail "missing end marker" "$r" "missing end marker"

r=$(make_good)
awk '/coding-principles:end/ { for (i = 0; i < 90; i++) print "- filler" } { print }' "$r/AGENTS.md" > "$r/AGENTS.md.new" && mv "$r/AGENTS.md.new" "$r/AGENTS.md"
expect_fail "block over 90 lines" "$r" "block is"

r=$(make_good)
edit "$r/AGENTS.md" '/^### Canonical modules$/d'
expect_fail "missing heading" "$r" "missing heading: ### Canonical modules"

r=$(make_good)
edit "$r/AGENTS.md" 's|src/lib/http.ts:3|src/lib/nope.ts|'
expect_fail "cited path missing" "$r" "cited path does not exist: src/lib/nope.ts"

r=$(make_good)
edit "$r/AGENTS.md" 's|src/lib/money.ts:10|src/lib/money.ts:9999|'
expect_fail "line past end of file" "$r" "cited line past end of file: src/lib/money.ts:9999"

r=$(make_good)
edit "$r/AGENTS.md" 's|Coding principles applied|something else|'
expect_fail "When designing lacks section name" "$r" "### When designing does not name \"Coding principles applied\""

r=$(make_good)
edit "$r/AGENTS.md" 's|applying-coding-principles|some-skill|'
expect_fail "When designing lacks skill name" "$r" "### When designing does not name applying-coding-principles"

r=$(make_good)
edit "$r/AGENTS.md" 's|Breaking a rule in this guide is an Important finding.|Rules are nice.|'
expect_fail "wrong severity text" "$r" "### Severity text is not exact"

r=$(make_good)
rm "$r/docs/coding-principles.md"
expect_fail "missing detail file" "$r" "docs/coding-principles.md is missing"

r=$(make_good)
edit "$r/docs/coding-principles.md" '/^## Decisions$/d'
expect_fail "detail file without Decisions" "$r" "docs/coding-principles.md has no ## Decisions"

r=$(make_good)
edit "$r/docs/coding-principles.md" '/^### Avoid$/d'
expect_fail "principle without Avoid" "$r" "principle \"Deep modules\" has no ### Avoid"

r=$(make_good)
edit "$r/docs/coding-principles.md" 's| — decided 2026-11-23||'
expect_fail "decision without date" "$r" "decision line lacks"

r=$(make_good)
{ cat "$r/AGENTS.md"; sed -n '/coding-principles:start/,/coding-principles:end/p' "$r/AGENTS.md"; } > "$r/AGENTS.md.new" && mv "$r/AGENTS.md.new" "$r/AGENTS.md"
expect_fail "doubled block" "$r" "start marker appears more than once"

r=$(make_good)
printf '\n  ```ts\n  request(`/users/`)\n  ```\n' >> "$r/docs/coding-principles.md"
check "template literal in excerpt passes" "$here/check-guide.sh" "$r"

r=$(make_good)
printf 'Build notes only.\n' > "$r/CLAUDE.md"
out=$("$here/check-guide.sh" "$r" 2>&1) && status=0 || status=$?
{ [ "$status" -eq 0 ] && grep -q '^WARN:' <<<"$out"; } && pass "CLAUDE.md without import warns" || bad "CLAUDE.md without import warns"

[ "$failures" -eq 0 ] || { echo "$failures failed"; exit 1; }
echo "all passed"
