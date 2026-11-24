# Setup skill procedure

Checks for `setting-up-coding-principles`, run by hand against the billing-app fixture. Each check runs in a fresh copy. Run each check once after every change to the skill.

## Running a check

From this repo's root:

```bash
repo=$(pwd)
log=$(mktemp -d)
allow="Read(/$repo/skills/**),Bash(git log:*),Bash(git ls-files:*),Bash(git diff:*),Bash(git show:*),Bash(date:*)"
copy=$(tests/fixture-copy.sh <variant>)
cd "$copy"
claude -p --plugin-dir "$repo" --permission-mode acceptEdits --allowedTools "$allow" \
  "Write coding conventions for this repository into AGENTS.md" | tee "$log/turn-1.txt"
```

Answer each question the skill asks in the same conversation, saving every reply outside the copy:

```bash
claude -p -c --plugin-dir "$repo" --permission-mode acceptEdits --allowedTools "$allow" "<answer>" | tee "$log/turn-2.txt"
```

`--allowedTools` grants read-only access the headless run can't ask for: reading the skill's own files, which sit outside the copy, and the git and `date` commands the skill uses. It grants no writes.

Check the result with `"$repo/tests/check-guide.sh" "$copy"`.

Standard answers, used unless a check says otherwise:

- Wrapper clients (`src/api/invoices-client.ts`, `src/api/payments-client.ts`): avoid them for new code; call `request()` from `src/lib/http.ts` directly.
- HTTP: `src/lib/http.ts` is canonical; `src/legacy/fetch-helper.ts` is to be avoided.
- A proposed lint rule: accept.
- Any other question: accept the skill's recommendation.
- The draft: approve it.

## Checks

### S1: fresh repo (`none`)

Use the standard answers.

Pass when all hold:

- The skill asks about the two wrapper clients, and separately about `src/lib/http.ts` vs `src/legacy/fetch-helper.ts`.
- It shows its draft before writing any file: `git status --short` in the copy is empty until the turn after the draft.
- It proposes an ESLint rule backing the HTTP decision (for example `no-restricted-imports` for the legacy helper, or restricting `fetch` outside `src/lib/http.ts`), showing the config change first.
- `tests/check-guide.sh` exits 0.
- `### Canonical modules` names `src/lib/http.ts`, `src/lib/errors.ts`, and `src/config.ts`.
- Every `### Rules` bullet cites a backticked path.
- `## Decisions` in `docs/coding-principles.md` records both answers.
- `eslint.config.js` holds the accepted rule, and `### Rules` has one line naming that rule and `eslint.config.js`, with no example; `docs/coding-principles.md` mentions it only in one `## Decisions` line.
- No `CLAUDE.md` exists.

Keep this copy for S4.

### S2: existing conventions (`agents-md`)

The overlay's `AGENTS.md` says "Wrap every API resource in its own client class." Use the standard answers; if the skill offers to change the existing line, decline.

Pass when all hold:

- The skill raises the conflict between that line and deep modules before deciding the wrapper question.
- `AGENTS.md` outside the markers is byte-identical to the overlay:

  ```bash
  sed '/^<!-- coding-principles:start -->$/,/^<!-- coding-principles:end -->$/d' AGENTS.md \
    | diff - "$repo/tests/fixtures/variants/agents-md/AGENTS.md.fixture"
  ```

  Blank lines the skill added around the block are the only allowed difference.
- `tests/check-guide.sh` exits 0.

### S3: existing CLAUDE.md (`claude-md`)

Use the standard answers; accept the offer to import `AGENTS.md`.

Pass when all hold:

- The skill offers to add `@AGENTS.md` to `CLAUDE.md` and does not create the line before you accept.
- `CLAUDE.md` holds a line that is exactly `@AGENTS.md`, and its other lines are unchanged:
  `grep -vx '@AGENTS.md' CLAUDE.md | grep -v '^$' | diff - <(grep -v '^$' "$repo/tests/fixtures/variants/claude-md/CLAUDE.md.fixture")`
- `tests/check-guide.sh` exits 0 and prints no `WARN`.

### S4: refresh (on S1's copy)

Prepare the copy:

1. Commit S1's result: `git add -A && git commit -m "add coding principles guide"`.
2. Hand-edit `AGENTS.md`: append ` Amounts are integer cents; never use floats for money.` to the end of the first `### Rules` bullet that doesn't mention the fetch helper.
3. Delete `src/legacy/fetch-helper.ts` and replace `src/reports/monthly.ts` with:

   ```ts
   import { request } from "../lib/http";

   export async function monthlyTotal(month: string): Promise<number> {
     const rows = await request<{ cents: number }[]>(`/reports/${month}`);
     return rows.reduce((sum, row) => sum + row.cents, 0);
   }
   ```

4. Commit: `git add -A && git commit -m "remove legacy fetch helper"`.

Run setup again with the prompt "Refresh the coding principles guide". Keep the hand edit when asked; for a rule or decision that cited the deleted file, accept the skill's recommendation.

Pass when all hold:

- The skill shows the hand edit before regenerating.
- After you keep it, "integer cents" appears in `## Decisions` and in the regenerated block.
- The skill reports each rule, decision, or lint rule that cited `src/legacy/fetch-helper.ts`.
- `tests/check-guide.sh` exits 0.

### S5: questions (all runs)

Read every transcript from S1 to S4 and S6.

Pass when every question about a principle covers that one principle and shows at most three excerpts, each labelled with `path:line`. The draft review and the `CLAUDE.md` offer are not principle questions.

### S6: no linter (`none`)

Prepare the copy: delete `eslint.config.js`, remove the `eslint` and `typescript-eslint` devDependencies and the `lint` script from `package.json`, and commit. Use the standard answers, but decline any offer to add a linter or a lint rule.

Pass when all hold:

- The skill asks before adding a linter or its dependencies.
- After you decline, no linter config exists and `package.json` matches the commit: `git status --short` lists only `AGENTS.md` and `docs/`.
- `### Rules` states the HTTP rule as prose with an example, not as a lint pointer.
- `tests/check-guide.sh` exits 0.
