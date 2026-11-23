# One source of truth per concept

## Principle

Each concept has one owner: one HTTP client, one config loader, one logger, one error hierarchy, one store or context provider per piece of state, one definition per schema or constant. Duplicated lines are cheap, and often better than a shared helper extracted too early (Metz: duplication is far cheaper than the wrong abstraction). Duplicated concepts are not: a second HTTP client or config source drifts from the first, and every reader has to learn which one is real.

## Signals in code

- The low-level primitive called from more than one module: `fetch\(`, `axios`, `XMLHttpRequest`, `requests\.`, `httpx\.`, `urllib`, `http\.(Get|Post|NewRequest)`, `&http\.Client\{`.
- Environment read outside the config module: `process\.env`, `import\.meta\.env`, `os\.environ`, `os\.getenv`, `os\.Getenv`, `viper\.Get`.
- More than one logger setup: `console\.(log|error)` beside a logger, several `logging\.basicConfig` calls, `log\.Print` beside `slog`, `zap`, or `zerolog`.
- More than one base error type or wrapping helper: `extends Error` roots in several files, several `class \w+Error\(Exception\)` roots, a custom errors package beside `errors\.New`.
- More than one `createContext\(`, store (zustand `create\(`, `createSlice`, `writable\(`, `defineStore`), or cache holding the same entity.
- The same constant, enum, route, or schema defined by hand in two places: status strings, flag names, API types beside generated ones.
- Paired names: `legacy/`, `old/`, `v2/`, `*2.ts`, `*_new.py`, or both `common/` and `shared/`.
- Two dependencies for one job in `package.json`, `pyproject.toml`, `requirements*.txt`, or `go.mod`: `axios` and `node-fetch`, `requests` and `httpx`, `moment` and `dayjs`, two loggers or ORMs.

## Ask when

- Two implementations of one concept are both in use: ask which is canonical, and whether the other is to be avoided, migrated, or tolerated.
- A second copy may be deliberate (a client for a different service, browser vs server config, test-only setup): ask whether they are one concept or two.
- Generated code (OpenAPI clients, ORM models, protobuf) overlaps with hand-written types: ask which is the source.
- Not a question: lines that are duplicated while the concept is not (two loops that look alike). Leave them alone.

## Writing the repo rule

Each canonical concept goes in the guide's canonical-modules table ("for X use `path`; don't add another"). The `### Rules` line carries what the table can't, such as what to stop using.

- Shape: "Use `<thing>` in `<path>` for <concept>; don't <the duplicate you found>. Example: `<path:line>`."
- Example: "Read settings only from `settings` in `app/config.py`; don't call `os.getenv()` elsewhere. Example: `app/jobs/sync.py:18`."

## Lint enforcement

Usually enforceable: ban the primitive or the duplicate everywhere except the canonical module.

- JS/TS: ESLint `no-restricted-imports` (a library, or the legacy module's path), `no-restricted-globals` or `no-restricted-syntax` (`CallExpression[callee.name='fetch']`), `no-restricted-properties` (`process.env`), with the canonical file excluded through `ignores` or its own `files` block.
- Python: Ruff `TID251` banned-api (`requests`, `os.getenv`) with `per-file-ignores` for the canonical module, or an import-linter `forbidden` contract.
- Go: `depguard` for packages, `forbidigo` for identifiers such as `^http\.Get$` or `^os\.Getenv$`, each excluding the canonical package.
