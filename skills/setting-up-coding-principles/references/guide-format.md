# Guide format

The guide is two files: a block in `AGENTS.md` that every agent loads, and `docs/coding-principles.md`, which agents read on demand. Text in `<angle brackets>` is a placeholder; everything else is literal.

## The block in `AGENTS.md`

````markdown
<!-- coding-principles:start -->
## Coding principles

Examples, counter-examples, and the decisions behind these rules: `docs/coding-principles.md`.

### Rules
- <Rule in this repo's own names, saying what to do and what not to do>. Example: `<path:line>`.
- <Rule a lint rule enforces>: `<lint rule>` in `<config file>`.

### Canonical modules
- <Concept>: `<path>` (`<symbol()>`); don't add another.

### When designing
When designing a feature or writing a spec, use the `applying-coding-principles` skill. The spec must include its section under the exact heading "Coding principles applied". When planning, copy every line of that section verbatim into the plan's Global Constraints. If a spec lacks the section, run `applying-coding-principles` before planning.

### Severity
Breaking a rule in this guide is an Important finding.
<!-- coding-principles:end -->
````

- Markers and headings are exact, in this order. Nothing else goes between the markers.
- About 80 lines; never more than 90.
- `### Rules`: one bullet per decided rule, grouped by principle. A prose rule cites exactly one real example as backticked `path:line`. A lint-backed rule is one line naming the lint rule and its config file, with no example.
- `### Canonical modules`: one line per concept the repo has (HTTP or API client, config and environment, logging, errors, state, database, auth, feature flags, UI primitives). An entry stays even when a lint rule backs it.
- `### When designing` and `### Severity`: copy the text above as is.
- In both files, a backticked token is a citation when it is made only of letters, digits, and `_./@-` and ends in a dot plus one to five letters or digits (optionally followed by `:line`), or ends in `/`. Each citation must be a path that exists, written exactly as the path. Write anything else of that shape without backticks: process.env, config.apiToken, the @AGENTS.md import line. Symbols go in backticks as `request()`, `HttpError`, or `config`.

## `docs/coding-principles.md`

````markdown
# Coding principles

The always-loaded rules are in the coding principles block of `AGENTS.md`. This file holds the evidence and the decisions behind them.

## <Principle name>

<The repo's rule for this principle, in one or two sentences.>

### Follow
- `<path:line>`: <why this is the example to copy>.
  ```<lang>
  <one to three lines copied from the file, starting at that line>
  ```

### Avoid
- `<path:line>`: <what is wrong here and what to do instead>.
  ```<lang>
  <one to three lines copied from the file, starting at that line>
  ```

## Decisions
- <What was decided, in the repo's names> — decided <YYYY-MM-DD>
````

- One `## <principle name>` per adopted principle, in catalog order, each with `### Follow` and `### Avoid`, even when lint enforces all of its rules. When the code has nothing for one side, write the rule as one line there, with no excerpt.
- A lint-backed rule has no examples here; its only trace is its line under `## Decisions`. The principle's other rules and its canonical modules still get examples.
- `## Decisions` is last. One line per decision made with the human: each answer, each principle adopted or dropped, each lint rule accepted or declined, each hand edit kept. Every line ends with ` — decided YYYY-MM-DD` (an em dash) and nothing after it.
- Every cited path exists, every `path:line` points at the quoted line, and every excerpt is copied from the file, not paraphrased.
