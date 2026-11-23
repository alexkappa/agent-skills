# Consistency with the repo

## Principle

New code follows the patterns already established around it: structure, error handling, naming, async style, test style, libraries. A reader shouldn't be able to tell which lines an agent wrote. If the local pattern is wrong, change it everywhere in its own refactor, or leave it; don't start a second style in one corner.

## Signals in code

Compare siblings to find the pattern new code must match, and the places where two patterns compete:

- Sibling files with different shapes: classes vs plain functions, default vs named exports, different verbs for one operation (`get*`, `fetch*`, `load*`; `list_*`, `all_*`).
- Error styles side by side: `throw` vs a returned `{ error }` or `Result`, exceptions vs `None` returns, Go `%w` wrapping vs `github.com/pkg/errors`.
- Async styles side by side: `.then(` chains vs `await`, callbacks vs promises, threads vs `asyncio`.
- Test styles side by side: `describe`/`it` vs `test(`, pytest functions vs `unittest.TestCase`, table-driven vs one function per case in Go, fixtures vs factories.
- Layout by feature (`users/`, `orders/`) mixed with layout by layer (`controllers/`, `services/`).
- Which style is current: `git log --since="6 months ago" --name-only` over the competing files, and what recent commits added.
- Style already settled by tools: `.editorconfig`, Prettier, Biome, Black, Ruff format, `gofmt`, linter configs. Those need no guide rule.

## Ask when

- Two styles coexist and neither clearly dominates, or the majority style is the older one: ask which new code follows.
- The established pattern breaks another principle (a wrapper class per resource vs deep modules): ask which wins, and whether to migrate.
- A directory is deliberately different (generated code, vendored code, a separate service or language): ask whether it's exempt.

## Writing the repo rule

Point at the best existing instance and name the one or two traits that matter, instead of describing the pattern at length.

- Shape: "New <kind of code> follows `<path:line>`: <trait>, <trait>."
- Example: "New HTTP handlers follow `internal/api/orders.go:22`: decode, call one service function, encode; errors go through `writeError()`."

## Lint enforcement

Formatting and syntax-level style belong to the formatter and linter the repo already runs; don't restate them as guide rules. Pattern-level consistency mostly needs human judgment. Lint helps when the choice is syntactic:

- JS/TS: `import/no-default-export` or `import/prefer-default-export`, `promise/prefer-await-to-then`, `no-restricted-syntax` for a construct the repo dropped (such as `ClassDeclaration` in a functions-only directory).
- Python: Ruff `PT` (flake8-pytest-style) for one test style; `UP` (pyupgrade) for one syntax generation.
- Go: `errorlint` for `%w` wrapping; `depguard` banning `github.com/pkg/errors` once the standard `errors` package is chosen.
