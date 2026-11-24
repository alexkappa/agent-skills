# Design companion procedure

Checks for `applying-coding-principles` and for the path its output takes through superpowers: spec, plan, task reviewer. Run by hand against the billing-app fixture's `with-guide` variant, with superpowers 7.0.2 installed. Each check runs in a fresh copy unless it says otherwise. Run each check once after every change to the skill.

## Running a check

From this repo's root:

```bash
repo=$(pwd)
log=$(mktemp -d)
allow="Bash(git add:*),Bash(git commit:*),Bash(git status:*),Bash(git log:*),Bash(git ls-files:*),Bash(git diff:*),Bash(git show:*),Bash(date:*),Bash(ls:*)"
copy=$(tests/fixture-copy.sh with-guide)
cd "$copy"
claude -p --plugin-dir "$repo" --permission-mode acceptEdits --allowedTools "$allow" \
  --output-format stream-json --verbose "<prompt>" > "$log/turn-1.jsonl"
jq -r 'select(.type=="result") | .result' "$log/turn-1.jsonl"
```

Continue the conversation with `claude -p -c` and the same flags, one `turn-N.jsonl` per turn. `--allowedTools` grants the git commands superpowers uses to commit specs and plans, and read-only commands.

List a turn's skill calls, file writes, and messages, in order:

```bash
jq -r 'select(.type=="assistant") | .message.content[]? |
  if .type=="tool_use" then "\(.name) \(.input.skill // .input.file_path // "")"
  elif .type=="text" then "text: \(.text[0:100] | gsub("\n"; " "))" else empty end' "$log/turn-1.jsonl"
```

Print a spec's `## Coding principles applied` section, and any backticked path in it that doesn't exist:

```bash
section() { awk '/^## Coding principles applied$/{on=1; next} on && /^## /{exit} on' "$1"; }
section "$spec"
section "$spec" | grep -oE '`[A-Za-z0-9_./@-]+(\.[A-Za-z0-9]{1,5}(:[0-9]+)?|/)`' | tr -d '`' | sed 's/:[0-9]*$//' \
  | sort -u | while read -r p; do [ -e "$p" ] || echo "missing: $p"; done
```

Answer any question the skill asks by accepting its recommendation.

## Checks

### D1: subagents see the guide

Prerequisite: `claude --version` is 2.1.277 or later, which Claude Code needs to load `AGENTS.md`. Otherwise stop and report.

```bash
claude -p "Dispatch a general-purpose subagent. Ask it to quote the first item of the Canonical modules list from its instructions without reading any files."
```

Pass when the subagent quotes the first `### Canonical modules` entry, the one naming `src/lib/http.ts`. Repeat in a fresh copy that also holds a `CLAUDE.md` whose only line is `@AGENTS.md`; it must pass too.

### D2: the companion shapes the spec

Prompt:

> Let's brainstorm a feature: a CSV export of all invoices from the billing API. Finance users download it monthly. No new dependencies. That's everything I can tell you, so don't ask me more questions: pick the approach you recommend and write the spec.

If the turn ends on a question anyway, reply "Go with your recommendation and write the spec."

The spec is the file superpowers wrote under `docs/superpowers/specs/`. Pass when all hold:

- A `Skill` call naming `applying-coding-principles` comes before the message that lays out the approaches and before the spec is written.
- The spec has a section headed exactly `## Coding principles applied`.
- A line of it names `src/lib/http.ts` as the client to use, and a line forbids new wrapper classes around it.
- No backticked path in the section is missing.

Save the section for D4: `section "$spec" | sed '/^$/d' > "$log/constraints.md"`. Keep this copy for D3.

### D3: the plan carries the section verbatim (on D2's copy)

Continue D2's conversation: "Approved. Write the plan."

Pass when every line of the section appears verbatim in the plan's Global Constraints:

```bash
plan=$(ls docs/superpowers/plans/*.md)
gc=$(awk '/^## Global Constraints$/{on=1; next} on && /^## /{exit} on' "$plan")
while IFS= read -r line; do grep -qF -- "${line#- }" <<<"$gc" || echo "missing: $line"; done < "$log/constraints.md"
```

### D4: the reviewer fails a planted wrapper

`tests/fixtures/planted/wrapper-client.diff` adds `src/api/export-client.ts`, a class whose methods only forward to `request()` under new names, and uses it from a new `src/api/invoice-export.ts`. No lint rule catches it.

Set, then run the review below:

```bash
planted=wrapper-client.diff
constraints=$(cat "$log/constraints.md")
task='### Task 1: Invoice CSV export

Add `exportInvoicesCsv(): Promise<string>`. It loads every invoice from the billing API and returns CSV: a header row `id,userId,totalCents`, then one row per invoice, joined with newlines.'
report='Added `exportInvoicesCsv()` in `src/api/invoice-export.ts`. It loads all invoices and returns CSV with a header row and one row per invoice. Requests go through a small `ExportClient` class in `src/api/export-client.ts`. No new dependencies; the fixture has no test runner, so there are no tests.'
```

`constraints` is D2's section. If you ran D3, use that plan's Global Constraints and its first task instead.

Pass when the review's Spec Compliance is ❌ and names `src/api/export-client.ts`. Note whether it cites a constraint line.

### D5: a spec without the section gets one before planning

Prerequisite: as D1, since the trigger is the guide's `### When designing` line.

```bash
mkdir -p docs/superpowers/specs
cp "$repo/tests/fixtures/planted/spec-without-section.md" docs/superpowers/specs/invoice-csv-export-design.md
git add docs && git commit -q -m "add invoice export spec"
```

Prompt: "Write the implementation plan for docs/superpowers/specs/invoice-csv-export-design.md."

Pass when a `Skill` call naming `applying-coding-principles` comes before the plan is written, the spec gains a `## Coding principles applied` section, and that section's lines appear verbatim in the plan's Global Constraints (save the section as in D2 and check as in D3).

### D6: how a reviewer grades a guide violation (recorded, not pass or fail)

`tests/fixtures/planted/plan-comment.diff` adds `sumMoney()` to `src/lib/money.ts` under a comment that references the plan. Before the review, make sure the reviewer loads the guide: on Claude Code older than 2.1.277, write a `CLAUDE.md` whose only line is `@AGENTS.md` into the copy.

```bash
planted=plan-comment.diff
constraints=
task='### Task 1: Sum money amounts

Add `sumMoney(amounts: Money[], currency: Currency): Money` to `src/lib/money.ts`. It returns the total of the amounts in the given currency, and a zero amount for an empty list.'
report='Added `sumMoney()` to `src/lib/money.ts`. It folds the amounts with `addMoney()` from zero, so an empty list returns zero and a currency mismatch throws. No tests: the fixture has no test runner.'
```

Run the review below. Record the severity the reviewer gives the comment (Critical, Important, Minor, or not flagged) and whether it cites the guide.

## Review

Run with `planted`, `constraints`, `task`, and `report` set, from inside the copy. It commits the planted diff, builds a one-task plan, makes the brief and review package with superpowers' own scripts, fills `task-reviewer-prompt.md`, and runs it.

```bash
sp=~/.claude/plugins/cache/claude-plugins-official/superpowers/7.0.2/skills/subagent-driven-development
base=$(git rev-parse HEAD)
git apply --index "$repo/tests/fixtures/planted/$planted"
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m "$planted"
plan=docs/superpowers/plans/review-check.md
mkdir -p "$(dirname "$plan")"
printf '# Review check\n\n## Global Constraints\n\n%s\n\n%s\n' "$constraints" "$task" > "$plan"
ws=$(bash "$sp/scripts/sdd-workspace" "$plan")
bash "$sp/scripts/task-brief" "$plan" 1
bash "$sp/scripts/review-package" "$plan" "$base" HEAD
printf '%s\n' "$report" > "$ws/task-1-report.md"
awk '/^  prompt: \|$/{on=1; next} on && /^```$/{exit} on' "$sp/task-reviewer-prompt.md" | sed 's/^    //' > "$ws/reviewer-prompt.md"
BRIEF_FILE="$ws/task-1-brief.md" GLOBAL_CONSTRAINTS="$constraints" REPORT_FILE="$ws/task-1-report.md" \
  BASE_SHA=$base HEAD_SHA=$(git rev-parse HEAD) \
  DIFF_FILE="$ws/review-$(git rev-parse --short "$base")..$(git rev-parse --short HEAD).diff" \
  perl -0pi -e 's/\[(BRIEF_FILE|GLOBAL_CONSTRAINTS|REPORT_FILE|BASE_SHA|HEAD_SHA|DIFF_FILE)\]/$ENV{$1}/g' "$ws/reviewer-prompt.md"
claude -p --plugin-dir "$repo" --allowedTools "Bash(git diff:*),Bash(git log:*),Bash(git show:*)" \
  < "$ws/reviewer-prompt.md" | tee "$log/review.txt"
```
