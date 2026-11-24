# No defensive padding

## Principle

Code handles the cases that can happen and nothing else. Checks, fallbacks, try/catch blocks, retries, and options for impossible cases cost reading time, hide real bugs behind silent defaults, and tell the next reader the impossible case is real. Validate at the edges (user input, network, files, environment) and trust types and invariants inside. Let unexpected errors surface.

## Signals in code

- Null checks on values the type or the caller already guarantees: `x === null || x === undefined` on required parameters, `if x is None` on non-`Optional` arguments, `x == nil` on a value just constructed.
- Re-checking what a constructor or the previous line established, such as an injected `readonly` field tested for null in every method.
- Catch blocks that only rethrow, swallow, or return a default: `catch (e) { throw e; }`, `except ...: pass`, `except Exception: return None`, Go `if err != nil { return nil }`, `_ = err`.
- Fallbacks that mask missing data or config: `?? ""`, `?? []`, `|| {}`, `.get(key, "")`, `os.getenv("X", "")`, `getattr(obj, "x", None)` on attributes that always exist.
- Optional parameters or option objects no caller passes or the body never reads: `options = {}`, `**kwargs` passed nowhere, unused `verbose` or `retries`.
- Runtime type checks on statically typed values: `typeof x === "string"`, `isinstance(`, type switches with one real case.
- Retries, timeouts, or fallbacks around in-process calls that can't fail transiently.
- `default:` or `else` branches for impossible enum cases that return a value instead of failing loudly.

## Ask when

- The value crosses a trust boundary (request body, file, env, third-party API, nullable column): the check may be edge validation that belongs. Ask where the boundary is if the code doesn't make it clear.
- A config fallback may be meant for local development (`?? "http://localhost:3000"`): ask whether missing config should fail at startup.
- A swallowed error may be deliberate best-effort work (telemetry, cache warming, cleanup): ask.
- A library's public API is called by untyped or external code: ask whether the checks are part of its contract.

## Writing the repo rule

Say where validation happens; code past that point trusts it.

- Shape: "Validate <input> at <edge> (`<path>`); past that, don't re-check what the types guarantee."
- Example: "Parse request bodies with the schemas in `src/schemas/`; handlers don't null-check fields a schema requires, and missing config fails at startup."

## Lint enforcement

Partly enforceable, mostly through the type checker and type-aware lint rules:

- JS/TS: `@typescript-eslint/no-unnecessary-condition` (needs `strictNullChecks`), `no-useless-catch`, `@typescript-eslint/no-unused-vars` for parameters the body never reads.
- Python: mypy `warn_unreachable`, or Pyright `reportUnnecessaryComparison` and `reportUnnecessaryIsInstance`; Ruff `S110` (try-except-pass), `BLE001` (blind except), `TRY203` (useless try-except), `ARG` (unused arguments).
- Go: `govet` `nilness` (impossible nil checks), `unparam` (parameters unused or always given the same value), `nilerr` and `errcheck` (dropped errors).
