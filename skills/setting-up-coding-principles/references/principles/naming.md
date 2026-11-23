# Naming is a design signal

## Principle

A good name says what a thing is or does, in the domain's words. When something is hard to name, it usually does too much or too little: the abstraction is wrong, and a better name won't fix it. Move the boundary and the name follows. One concept gets one word across the repo.

## Signals in code

- Empty role suffixes, worst when stacked: `\w+(Manager|Helper|Utils?|Handler|Processor|Service|Data|Info|Impl|Base)\b`.
- Names joined by `And`, `Or`, or `_and_`: the function does two things (`validateAndSave`, `fetch_and_parse`).
- Grab-bag files: `utils`, `helpers`, `misc`, `common`, `shared` holding unrelated functions.
- Boolean or mode parameters that switch behavior (`isAdmin: boolean`, `mode=`, `flag=True`): two functions under one name.
- A name that disagrees with its body: `get*`, `is*`, or `check*` that writes; `validate*` that mutates; `to*` with side effects.
- One concept under several names (`customer`, `client`, `account` for one entity), or one name for two concepts: compare model, table, and API type names.
- Placeholder or sequence names: `tmp`, `data2`, `newHandler`, `processV2`, `doStuff`.

## Ask when

- A vague name is entrenched (a `*Service` in dozens of files): ask whether it's the accepted convention or something to stop extending.
- The code uses two words for one domain concept: ask which is the domain's word, after checking the README, `docs/`, and any glossary.
- A hard-to-name thing turns up: ask whether to rework its boundary. Don't offer a rename as the fix.
- Suffixes come from the framework (NestJS `*Service`, Django `*View`, Angular `*Component`): ask whether they're required there and unwanted elsewhere.

## Writing the repo rule

Name the domain word to use, or the suffix to avoid and what to do instead of renaming.

- Shape: "<Concept> is `<Term>`; don't call it <synonyms>. Example: `<path:line>`." Or: "Don't add `*Manager` or `*Helper` types; if nothing better fits, split or merge the code. Example: `<path:line>`."
- Example: "The paying party is `Account` everywhere; don't introduce `Customer` or `Payer`. Example: `pkg/accounts/account.go:9`."

## Lint enforcement

Whether a name fits needs human judgment. Lint can ban specific words and enforce casing:

- JS/TS: ESLint `id-denylist` for exact names (`data`, `tmp`); `@typescript-eslint/naming-convention` with a `custom` regex and `match: false` to ban suffixes such as `(Manager|Helper)$`.
- Python: Pylint `disallowed-name` with `bad-names` or `bad-names-rgxs`; Ruff `N` (pep8-naming) covers casing only.
- Go: `revive` `var-naming` covers casing and initialisms; no common rule bans words.
