# Reuse before building

## Principle

Take the first option that works:

1. Don't build it: the need is speculative or already met another way.
2. Use what the codebase already has: a helper, a module, an established pattern.
3. Use the standard library or a platform feature: language stdlib, framework config or plugin, database feature, browser or OS API.
4. Use a dependency that's already installed.
5. Write new code, once, where the repo would look for it.

A new dependency is an alternative to step 5, never a default. Build vs reuse is a human decision made at design time, not something an agent settles mid-implementation.

## Signals in code

- Hand-rolled common utilities: deep clone (`JSON\.parse\(JSON\.stringify`), deep merge, debounce, retry or backoff loops, UUID or slug generation, query-string building, date arithmetic, CSV parsing.
- The same verb defined in several `utils`, `helpers`, or `common` files: `function format\w+`, `def format_\w+`, `func Format\w+`.
- Installed dependencies that cover hand-written code: read `package.json`, `pyproject.toml`, `requirements*.txt`, `go.mod`, then look for `p-retry` or `tenacity` beside a custom retry, `zod` or `pydantic` beside manual validation, `date-fns` or `dayjs` beside date math.
- Framework features re-implemented: custom auth or CORS middleware, manual caching, hand-written migrations, ad-hoc config parsing beside the framework's settings.
- Copied third-party code: `third_party/`, foreign license headers, `copied from` or `adapted from` comments.
- Dependencies nothing imports.

## Ask when

- Hand-written code duplicates the stdlib, the platform, or an installed dependency: ask whether to replace it, or whether it exists for a reason (bundle size, an upstream bug, licensing).
- The repo has a dependency policy (an allowlist, "no new dependencies", vendoring): ask whether it holds and who approves exceptions.
- A capability that features keep needing (validation, retries, dates) has no settled answer: ask which library or module new code uses, so later designs don't re-decide it.

## Writing the repo rule

Record the order once, then one line per concrete decision.

- Order: "Before writing a helper, check `<utils path>`, the standard library, and installed dependencies; ask before adding a dependency or a new helper."
- Decision shape: "For <need>, use <existing module or package>; don't hand-roll it. Example: `<path:line>`."
- Example: "Retry network calls with `tenacity`, already a dependency; don't write retry loops. Example: `app/sync/fetch.py:27`."

## Lint enforcement

Choosing among the options needs human judgment. Lint can lock in a choice once it's made:

- Ban a rejected library or a replaced helper: ESLint `no-restricted-imports`, Ruff `TID251`, Go `depguard` or `gomodguard`.
- Prefer built-ins: `eslint-plugin-unicorn` rules such as `prefer-structured-clone`; Ruff `UP` (pyupgrade).
- Unused dependencies: `knip` or `depcheck` (JS/TS), `deptry` (Python), `go mod tidy` with a clean-diff check in CI.
