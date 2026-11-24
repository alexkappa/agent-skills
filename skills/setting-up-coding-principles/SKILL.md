---
name: setting-up-coding-principles
description: Use when setting up or refreshing a repository's coding principles guide, or when asked to write repo-specific coding conventions into AGENTS.md
---

# Setting up coding principles

Build the repo's coding principles guide from its own code: a short block in `AGENTS.md` that every agent loads, and `docs/coding-principles.md` with the examples and the decision record. A rule earns its place by being specific to this repo: its paths, its names, and decisions its human made. A rule you could paste into any repo doesn't belong.

- Format of both files: `references/guide-format.md`. Follow it exactly.
- The principles: every file in `references/principles/`. Read them all before step 3.

## Ground rules

- **The code shows a pattern; the human decides whether it's the rule.** When the code does one thing two ways, or a repeated pattern breaks a principle, ask. Never codify the pattern you found (a wrapper class per resource, a legacy module still in use) without asking.
- **No file changes until the human approves the draft.** That includes lint config.
- **Write only the guide, lint config, a dependency the human approved in step 5 (added with the repo's package manager), and the `@AGENTS.md` line.** Leave source files alone: exempt existing violations in the lint config instead of fixing them, and name only modules and symbols that exist before you write. Offer code fixes as follow-up work.
- **`AGENTS.md` only.** The guide lives in `AGENTS.md`, created if missing. Claude Code loads `AGENTS.md` when the repo has no `CLAUDE.md`, and ignores it when there is one. So never create `CLAUDE.md` or suggest creating one. If `CLAUDE.md` exists without a line `@AGENTS.md`, offer to add that line, and add it only after a yes. If `CLAUDE.md` resolves to `AGENTS.md` (a symlink), make no offer.
- **Be a good neighbour in `AGENTS.md`.** Never change a line outside the markers. A section between another tool's markers (Packmind's, say) belongs to that tool. The block never repeats a rule the file already states. If a decision contradicts a line outside the markers, quote it and ask whether the human will change it at its source, by hand or through the tool that generates it. Until it changes, the rule stays out of the block and its decision line says what it waits on. Match the file's heading level.
- **Every name is real; no line numbers.** Every path and symbol the guide names exists. Neither file cites a line number, because line numbers drift as the code changes. Examples are short snippets written for the point. Anything backticked that looks like a path is read as one, so write a dotted symbol or the import line (process.env, @AGENTS.md) without backticks; `references/guide-format.md` defines the shape.

## Steps

### 1. Read the repo

Languages and frameworks; package manifests and installed dependencies; lint and format config, including which plugins are installed; instruction files (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, editor rule files), including sections other tools manage between their own markers and the heading level of `AGENTS.md`'s sections; `docs/`; the directory structure; recent `git log`. Note every existing rule that touches a principle. If the markers or `docs/coding-principles.md` exist, this is a refresh: also do step 7.

### 2. List canonical modules

For each piece of knowledge the repo keeps in one place (HTTP or API client, config and environment, logging, errors, state, database, auth, feature flags, UI primitives), find the one module that owns it. Two candidates for one concept is a question for step 4.

### 3. Interpret each principle against the code

For each principle file, search with its "Signals in code", then read the code around enough matches to classify each signal. Signals are starting points: some are regexes, some are shapes to look for, and a few match far too much as written. Nothing is an example or a counter-example until you've read it.

Sort what you find:

- **Follow**: a clear example of the principle.
- **Avoid**: a clear counter-example, with no reason in the code or its instruction files to think it's intended.
- **Ask**: it matches the principle's "Ask when", the code does it two ways, or an existing rule conflicts with the principle.
- **Follow-up**: a one-off defect, not a pattern anyone would repeat (an unused dependency, a dead file). It goes on the follow-up list, never into the guide.

A principle with no evidence either way is proposed as dropped in the draft.

### 4. Ask about the ambiguous cases

Ask one principle per message, and wait for the answer before the next. Each question:

1. Names the principle and states what you found in one or two sentences.
2. Shows at most three excerpts in total, each headed by its `path:line` and quoted from the file. A quoted existing rule counts as one of the three.
3. Says what you'd pick and why, in one line.
4. Ends with one question.

Ask first about conflicts with existing rules: quote the existing rule beside the code. Don't ask about clear Follow or Avoid cases; they appear in the draft. Record each answer as a decision dated today (`date +%F`). The excerpts are evidence for the question only; the guide's examples are written in step 6.

### 5. Prefer the linter

For each decided rule, read the principle's "Lint enforcement" and the repo's lint config.

- **The repo's linter can enforce it with what's already installed** (a core rule, or a plugin already in its config): propose the config change as a diff, one principle per message. Where the rule takes a custom message, the message says what to do and ends with "See docs/coding-principles.md (<principle>)." If accepted, the rule gets no `### Rules` line and no snippet: one sentence in its principle's summary names the lint rule, plus one `## Decisions` line.
- **It would need something the repo doesn't have** (a linter, a plugin, a custom rule): ask whether to add it, naming it as a build-vs-reuse choice. Never add it unasked. If declined, the rule stays prose.

Apply accepted lint changes with the guide in step 6, not before.

### 6. Show the draft, then write

Show in one message: the full block, the full detail file, the lint config changes accepted in step 5, the principles adopted and dropped with a one-line reason each, and the follow-up list (code fixes and one-off defects). If `CLAUDE.md` lacks `@AGENTS.md`, offer the import in the same message. Ask for approval.

After a yes:

1. Write `docs/coding-principles.md`.
2. Write the block into `AGENTS.md`: create the file holding only the block, or append the block after one blank line (adding the final newline the file lacks), or replace the content between existing markers.
3. Apply the accepted lint config changes, and the `@AGENTS.md` line if accepted.
4. Verify, and fix anything that fails:
   - Outside code fences, grep both files for paths with the pattern `` `[A-Za-z0-9_./@-]+(\.[A-Za-z0-9]{1,5}|/)` `` and confirm each is a path that exists. No backticked token ends in `:<digits>`.
   - Grep the repo for every symbol either file names, snippets included, except names a snippet invents.
   - The block is at most 90 lines, and repeats no rule stated elsewhere in `AGENTS.md`.
   - Nothing outside the markers changed (`git diff`).
   - If you changed lint config, run the repo's lint command; it must pass. If it can't run (dependencies not installed), say so in the summary instead of claiming it passes.

### 7. Refresh

On a re-run, before steps 2 to 6:

1. **Hand edits.** Compare each line of the current block with what the detail file and its decisions support, and read `git log -p -- AGENTS.md` for edits between the markers. Show each hand edit as old and new text and ask whether to keep it. A kept edit becomes a `## Decisions` line, so the regenerated block carries it. Never drop a hand edit silently.
2. **Stale names.** Check every path, symbol, and lint rule in both files and the lint config. Report each rule, snippet, decision, or lint rule that names something missing or renamed, and propose updating or dropping it. Keep a decision whose subject is gone, rewritten without the dead name.
3. **Waiting decisions.** For each decision waiting on a line outside the markers, check whether that line changed. If it did, the rule joins the block.
4. **New ambiguities.** Run steps 2 and 3 again; ask only about cases no decision covers.
5. **Regenerate** the block and the detail file in the current format (no line numbers, no lint-backed lines in `### Rules`), from the detail file and its decisions, keeping everything outside the markers, and show the draft as in step 6.

## Common mistakes

| Mistake | Instead |
|---|---|
| Writing the existing pattern down as the rule ("new clients follow the existing client class") | It's a question when it repeats or competes with another pattern |
| Generic rules: file casing, "name things well", "comments explain why" | Repo-specific rules in the repo's own names; leave style to the formatter |
| Writing files, then summarizing | Draft first, write after a yes |
| Several principles in one question, or a long list of excerpts | One principle, up to three excerpts |
| A lint-backed rule in `### Rules`, or with a snippet | A lint message pointing to the detail file, a sentence in the principle's summary, one decision line |
| `path:line` examples, or excerpts copied from a file | A short snippet written for the point, in the repo's real names |
| An unused dependency or a dead file as an Avoid example | A follow-up item |
| A snippet for a rule the sentence already makes clear | One line of prose under Follow or Avoid |
| A second, differently configured instance of a cheap object flagged as duplication | The change-together test in `references/principles/one-owner.md` |
| A rule that repeats or contradicts a line elsewhere in `AGENTS.md` | Leave it out; ask about the conflict |
| Adding an ESLint plugin, knip, or another tool because the catalog names it | Ask: it's a build-vs-reuse choice |
| Treating every grep hit as evidence | Read the code; signals are starting points |
