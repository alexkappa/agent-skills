# Guide format

The guide is two files: a block in `AGENTS.md` that every agent loads, and `docs/coding-principles.md`, which agents read on demand. Text in `<angle brackets>` is a placeholder; everything else is literal.

## The block in `AGENTS.md`

````markdown
<!-- coding-principles:start -->
## Coding principles

Examples, counter-examples, and the decisions behind these rules: `docs/coding-principles.md`.

### Rules
- <Rule in this repo's own names, saying what to do and what not to do>.

### Canonical modules
One owner each: use it, and don't add another.
- <Concept>: `<path>` (`<symbol>`).

### When designing
When designing a feature or writing a spec, use the `applying-coding-principles` skill. The spec must include its section under the exact heading "Coding principles applied". When planning, copy every line of that section verbatim into the plan's Global Constraints. If a spec lacks the section, run `applying-coding-principles` before planning.

### Severity
Breaking a rule in this guide is an Important finding.
<!-- coding-principles:end -->
````

- Markers and headings are exact, in this order. Nothing else goes between the markers.
- Heading level follows the file. When the file's sections are `#` headings, the block uses `# Coding principles` and `##` for the four subsections; otherwise `##` and `###` as shown.
- About 60 lines; never more than 90.
- `### Rules`: one bullet per decided prose rule, grouped by principle, with no example and no path beyond the modules it names. A rule a lint rule enforces gets no bullet. A rule that repeats or contradicts a line elsewhere in `AGENTS.md` gets no bullet.
- `### Canonical modules`: one line per piece of knowledge the repo keeps in one place (HTTP or API client, config and environment, logging, errors, state, database, auth, feature flags, UI primitives). An entry stays even when a lint rule backs it.
- `### When designing` and `### Severity`: copy the text above as is.

## `docs/coding-principles.md`

````markdown
# Coding principles

The always-loaded rules are in the coding principles block of `AGENTS.md`. This file holds the examples and the decisions behind them.

## <Principle name>

<The repo's rule for this principle, in one or two sentences. Name any lint rule that enforces part of it.>

### Follow
<What makes this the shape to copy, in one line.>
```<lang>
<a short snippet written to make the point>
```

### Avoid
<What is wrong with this shape and what to do instead, in one line.>
```<lang>
<a short snippet written to make the point>
```

## Decisions
- <What was decided, in the repo's names> — decided <YYYY-MM-DD>
````

- One `## <principle name>` per adopted principle (a short name is fine), each with `### Follow` and `### Avoid`.
- Snippets are written, not quoted: one to eight lines in the repo's language, calling its real modules and symbols, trimmed or exaggerated until the point is obvious. An Avoid snippet shows the shape to avoid, not a file to fix.
- A snippet appears only where the rule's sentence alone could be misread. Otherwise `### Follow` or `### Avoid` holds one line of prose.
- A lint-backed rule has no snippet. Its traces are a sentence in its principle's summary naming the lint rule, and its line under `## Decisions`. Its lint message points here where the rule takes one; otherwise the rule's name is how a reader finds it.
- `## Decisions` is last. One line per decision made with the human: each answer, each principle adopted or dropped, each lint rule accepted or declined, each hand edit kept. A decision waiting on a change outside the markers says so: "<decision>, once <the line it conflicts with> changes at its source". Every line ends with ` — decided YYYY-MM-DD` (an em dash) and nothing after it.

## Citations

- Neither file cites a line number.
- Outside code fences, a backticked token is a path when it is made only of letters, digits, and `_./@-` and ends in a dot plus one to five letters or digits, or ends in `/`. Each must exist, written exactly as the path. Write anything else of that shape without backticks: process.env, config.apiToken, the @AGENTS.md import line.
- Symbols go in backticks as `request()`, `HttpError`, or `config`. Every symbol either file names, inside snippets or out, exists in the repo, except local names a snippet invents to make its point.
