# Deep modules

## Principle

A module earns its place by hiding real complexity behind an interface much smaller than its implementation (Ousterhout). Prefer a few deep modules over many shallow ones. A layer that only forwards calls, renames them, or puts a class around a function adds interface without hiding anything. So does splitting code into many tiny functions and classes for its own sake, Clean Code style.

## Signals in code

- A class or file whose every method is one line calling the same function or field: `return this\.\w+\.\w+\(`, `return self\._?\w+\.\w+\(`, Go `return \w+\.\w+\.\w+\(`, or the same imported function in each method.
- Types named `*Client`, `*Wrapper`, `*Adapter`, `*Facade`, `*Service`, `*Repository`, `*Gateway` that sit on top of another client and add only names.
- An interface, ABC, or Protocol with exactly one implementation and no test double: Go `type \w+ interface`, Python `\((ABC|Protocol)\)`, TS `interface I[A-Z]\w+` or `implements `.
- A function whose body is a single call passing its own arguments through under another name.
- Private functions of one to three lines, each called from exactly one place.
- Arguments threaded unchanged through three or more layers to reach the one that uses them (pass-through variables, prop drilling).
- Factories, registries, or DI bindings that only ever produce one type.
- Callers that must call several functions in a fixed order, or know an internal detail, to do one thing: the module leaks what it should hide.
- For the example to follow: a file with few exports and a long private body (TS `export` count, Python names without `_`, Go capitalized identifiers, against line count).

## Ask when

- The thin-wrapper pattern appears more than once (say, a client class per resource): it may be the repo's convention, so consistency and depth disagree. Ask which wins for new code and whether existing wrappers stay.
- An instruction file (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`) or architecture doc prescribes the wrapper or layer: ask whether that rule still holds.
- A wrapper isolates a third-party API the team expects to replace, or gives tests a seam: ask whether the replacement or the seam is real.
- A single-implementation interface sits at a framework or package boundary (Go consumer-side interfaces, plugin points, a DI framework that requires it): ask whether it's required.

## Writing the repo rule

Name the deep module to call directly and the shallow shape to avoid, in the repo's own names. Point at a direct caller.

- Shape: "Use `<function()>` in `<path>` directly; don't wrap it in <shallow shape>. Example: `<path:line>`."
- Example: "Call `Store.Query()` in `internal/store/store.go` directly; don't add per-entity repository types that forward to it. Example: `internal/orders/list.go:41`."

## Lint enforcement

Needs human judgment: no linter can tell whether an interface hides anything. Lint catches a few symptoms:

- JS/TS: ESLint `no-useless-constructor`, `@typescript-eslint/no-extraneous-class` (classes that are empty or hold only static members).
- Python: Pylint `useless-parent-delegation` (methods that only call `super()` with the same arguments).
- Go: golangci-lint `iface` with its `unused` and `opaque` analyzers (unused interfaces; functions that return an interface but only ever one concrete type).
- When the decision is about which layers may exist or call each other: import-linter `layers` contracts, ESLint `import/no-restricted-paths`, Go `depguard`.
