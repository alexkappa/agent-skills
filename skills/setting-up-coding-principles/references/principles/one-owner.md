# One owner per piece of knowledge

## Principle

Knowledge that must change in one place has one owner: how outbound calls are logged and authenticated, how config is loaded, how a protocol or a context-management scheme works, a schema, a business rule. A second copy of that knowledge drifts from the first, and every reader has to learn which one is real.

Code that can diverge freely is not shared knowledge. Copy it without guilt: a little copying is better than a little dependency (Pike), and duplication is far cheaper than the wrong abstraction (Metz). A second model client configured with a cheaper model, two loops that look alike, the same three lines of setup in two tests: none of these needs a shared factory.

The test: when one copy changes, must the other change with it? Yes: one owner. No: leave the copies alone.

## Signals in code

Each signal is a candidate; apply the test before calling it a finding.

- The low-level primitive called from more than one module: `fetch\(`, `axios`, `XMLHttpRequest`, `requests\.`, `httpx\.`, `urllib`, `http\.(Get|Post|NewRequest)`, `&http\.Client\{`.
- Environment read outside the config module: `process\.env`, `import\.meta\.env`, `os\.environ`, `os\.getenv`, `os\.Getenv`, `viper\.Get`.
- More than one logger setup: `console\.(log|error)` beside a logger, several `logging\.basicConfig` calls, `log\.Print` beside `slog`, `zap`, or `zerolog`.
- More than one base error type or wrapping helper: `extends Error` roots in several files, several `class \w+Error\(Exception\)` roots, a custom errors package beside `errors\.New`.
- More than one `createContext\(`, store (zustand `create\(`, `createSlice`, `writable\(`, `defineStore`), or cache holding the same entity.
- The same constant, enum, route, or schema defined by hand in two places: status strings, flag names, API types beside generated ones.
- Non-trivial logic repeated with small edits in two modules: the same parsing, mapping, or state handling, where `git log` shows the copies changing together.
- Paired names: `legacy/`, `old/`, `v2/`, `*2.ts`, `*_new.py`, or both `common/` and `shared/`.
- Two dependencies for one job in `package.json`, `pyproject.toml`, `requirements*.txt`, or `go.mod`: `axios` and `node-fetch`, `requests` and `httpx`, `moment` and `dayjs`, two loggers or ORMs.

## Ask when

- Two implementations of one piece of knowledge are both in use: ask which is the owner, and whether the other is to be avoided, migrated, or tolerated.
- The code and its history don't answer the test: ask whether the copies are one piece of knowledge or two.
- Generated code (OpenAPI clients, ORM models, protobuf) overlaps with hand-written types: ask which is the source.
- Not a question: a second instance of a library object configured for a different job (another model, another timeout), or lines that look alike while the knowledge differs. Leave them alone, unless they bypass an owner the repo has, such as a client built without the shared HTTP setup.

## Writing the repo rule

Each owner goes in the guide's canonical-modules list as its path and symbol. A `### Rules` line carries what the list can't: what to stop using, or where copying is fine.

- Shape: "Use `<symbol>` in `<path>` for <knowledge>; don't <the duplicate you found>."
- Example: "Read settings only from `settings` in `app/config.py`; don't call os.getenv() elsewhere."
- Example: "Configure each model client where it's used; only its HTTP client comes from `make_http_client()`."

## Lint enforcement

Usually enforceable: ban the primitive or the duplicate everywhere except the owner.

- JS/TS: ESLint `no-restricted-imports` (a library, or the legacy module's path), `no-restricted-globals` or `no-restricted-syntax` (`CallExpression[callee.name='fetch']`), `no-restricted-properties` (`process.env`), with the owner excluded through `ignores` or its own `files` block.
- Python: Ruff `TID251` banned-api (`requests`, `os.getenv`) with `per-file-ignores` for the owner, or an import-linter `forbidden` contract. Exempt a single line elsewhere with `# noqa: TID251`, not the whole file, so the file's other bans still hold.
- Go: `depguard` for packages, `forbidigo` for identifiers such as `^http\.Get$` or `^os\.Getenv$`, each excluding the owner's package.
