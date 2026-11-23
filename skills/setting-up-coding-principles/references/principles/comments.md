# Comments

## Principle

A comment says what the code can't, right where it applies: why this choice, which invariant holds, what a caller must know. Three kinds don't belong in code:

- Warnings about far-away consequences ("changing this breaks the export job"). The reader can't check them and they rot. Make the dependency visible in code instead: a shared constant, a type, a test.
- References to specs, plans, or task numbers. Those live in `docs/` and in commit messages; the code outlives them.
- Names from the ideation phase (codenames, plan labels, "new approach", "v2") in comments or identifiers.

## Signals in code

Search comment lines (`//`, `#`, `/*`, `"""`, `--`) for:

- Plan and spec references: `\b(spec|plan|RFC|ADR|design doc|milestone)\b`, `(Task|Step|Phase) \d`, `per the`, `as discussed`, `docs/`.
- Far-away consequences: `if you change`, `must match`, `keep in sync`, `will break`, `don't touch`, `see also`, or another file's path.
- Ideation names: words from `docs/` titles, branch names (`git branch -a`), and early commit subjects (`git log --reverse --format=%s`) that appear in code but not in the domain.
- Change-log comments: `now uses`, `previously`, `changed to`, `updated to`, `added`, `removed`. History belongs in commits.
- Comments that repeat the next line (`// increment i`, `# return the result`) or narrate steps (`// Step 1:`).
- Ticket references: `[A-Z][A-Z0-9]+-\d+`, `#\d+`, issue URLs.

## Ask when

- Ticket references are common: ask whether they're accepted pointers in this repo or plan references to stop adding.
- A cross-file warning guards a real invariant the code can't express yet: ask whether to keep it or make it checkable.
- A term looks like a codename but may be the product's real name: ask.
- Doc comments (JSDoc, docstrings, godoc) are required by tooling or a public-API policy: ask what's required so the rule doesn't fight it.

## Writing the repo rule

Say what comments are for and name the exact terms to keep out, using this repo's codenames and doc locations.

- Shape: "Comments explain why, next to the code they explain; don't reference <plans, specs, tickets> or use <codenames>. Example: `<path:line>`."
- Example: "Don't mention specs, plans, task numbers, or the `orbit` codename in code; put that context in the commit message. Example: `lib/sync/queue.py:40`."

## Lint enforcement

Word lists are enforceable; whether a comment earns its place needs human judgment.

- JS/TS: ESLint `no-warning-comments` with custom `terms` (the repo's codenames, "spec", "plan") and `location: "anywhere"`.
- Any language: a regex check in CI or a pre-commit hook with `language: pygrep`, scoped to source files and to the repo's own codenames and phrases to keep false positives low.
- Ruff and golangci-lint have no general rule for comment wording; use the regex check.
