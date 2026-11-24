# Coding Principles for Superpowers — Design

**Status:** draft for approval · **Date:** 2026-11-23

## Intent

AI-written code usually works but doesn't belong. It is over-abstracted,
padded with defensive checks, inconsistent with the code around it,
reinvents helpers and libraries the repo already has, and is hard to
review.

[obra/superpowers](https://github.com/obra/superpowers) has a sound
process for designing, planning and building features, but a repo's idea
of good code never reaches the agents that write and review it. This
plugin puts a repo's coding principles where superpowers' agents already
look, without forking superpowers.

## Why superpowers alone doesn't get there

Facts about superpowers 7.0.2 that shape this design:

- Every implementer and reviewer is a generic subagent. Each one sees
  the repo's CLAUDE.md, its task text, and, for reviewers, a
  **Global Constraints** block copied word for word from the plan. Nothing
  else carries project guidance. Personal auto-memory never reaches them.
- `writing-plans` fills the plan's Global Constraints by copying the
  spec's project-wide requirements, explicitly including "naming and copy
  rules".
- The task reviewer is told "Do not crawl the broader codebase." It sees
  only the diff, so it cannot notice that new code duplicates an existing
  module unless something it reads names that module.
- The reviewer's quality checklist is generic. Style problems are usually
  graded Minor, and Minor findings are recorded but never fixed. Only a
  spec failure or a Critical/Important finding starts the fix loop.
- During implementation superpowers never stops to ask. It records
  "rulings" and keeps going, so any ambiguity left for implementation
  becomes a decision nobody sees in time.
- `using-superpowers` states that the repo's instructions (CLAUDE.md,
  AGENTS.md) take precedence over superpowers' skills.

So principles have to live in two places: the repo's instruction file,
which every agent loads, and each feature's spec, which is the only
channel superpowers enforces strictly.

## Goals

- Each repo gets a guide that reads as if written for that codebase:
  every rule and example uses the repo's own names, modules and language.
- The guide names the repo's canonical modules (one owner per piece of
  knowledge), so a diff-only reviewer can spot duplication from the guide
  alone.
- A rule the repo's linter can enforce is enforced there, as a hard gate.
  The always-loaded section doesn't repeat it; the lint message points to
  the detail file.
- The guide is a good neighbour in `AGENTS.md`: it changes nothing outside
  its markers, never repeats or contradicts what the file already says, and
  matches the file's heading levels.
- The guide doesn't rot as the code changes: it cites modules and symbols,
  never line numbers.
- Every pattern question ("is this a pattern to follow or one to avoid?")
  is settled with a human during setup or feature design, never during
  implementation.
- Every feature spec carries a concrete "Coding principles applied"
  section that superpowers copies into the plan's Global Constraints, so
  task reviewers enforce it as spec compliance.
- Works with unmodified superpowers. Everything the guide relies on is a
  plain file in the repo that people can read and edit.

## Non-goals (v1)

- Automatic refactoring of existing code.
- Learning from corrections: turning a reviewer finding or a human
  correction into a lint rule or a guide decision.
- Separate guides per package in a monorepo. One guide per repo.
- Replacing superpowers' reviewers or how it dispatches them.
- Tools that don't read AGENTS.md.

## Anti-goals

These would make it a failure even if it technically works:

- Generic rules ("use meaningful names") that could be pasted into any
  repo.
- Writing down existing bad patterns as rules because they're common.
- Prose rules for something a linter could enforce.
- A guide so long it bloats every agent on every task.
- Forking superpowers, or Claude-only machinery (hooks, custom agents)
  that isn't visible in the repo.
- Questions coming up during implementation.

## Approaches considered

1. **Setup skill only.** One skill writes the guide, and the guide asks
   designers to "include a principles section in every spec". Cheapest
   and works in any tool, but the spec section would be written unguided:
   likely generic, and nothing searches for code to reuse.
2. **Setup skill plus a design companion. (Chosen.)** The same setup
   skill, plus a second skill used while designing a feature. It searches
   the code the feature touches, finds what to reuse, asks the style
   questions, and writes the spec section with real file paths. This moves
   the codebase search to design time, where questions belong and where
   reviewers can't do it.
3. **Setup skill plus hooks and a custom reviewer.** Strongest enforcement,
   but Claude Code only, invisible in the repo, and it routes around
   superpowers instead of through it. Rejected.

## Design

### Pieces

A Claude Code plugin named `coding-principles` in this repo, which is also
a plugin marketplace so the plugin can be installed from it:

```
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
skills/setting-up-coding-principles/
  SKILL.md
  references/principles/<one file per principle>.md
skills/applying-coding-principles/
  SKILL.md
```

The repo's guide is the interface between the two skills. The setup skill
writes it; the companion reads it. The principles catalog lives only in the
setup skill, because the companion needs the repo's interpretation, not
the generic principle.

### The principles catalog

The starting set:

1. **Deep modules** (Ousterhout). Few abstractions, each hiding real
   complexity behind a small interface. No pass-through layers or thin
   wrappers that only rename.
2. **One owner per piece of knowledge.** Knowledge that must change in
   one place (a protocol, a policy, a context-management scheme, how
   outbound calls are logged) has one owner. Code that can diverge freely
   is copied without guilt (Pike: a little copying is better than a little
   dependency; Metz: duplication is cheaper than the wrong abstraction).
   The test: when one copy changes, must the other change with it? A
   second model client configured with a cheaper model is not a finding.
3. **Reuse before building.** Take the first option that works: don't
   build it at all, use what's already in the codebase, use the standard
   library or a platform feature, use an installed dependency, and only
   then write new code (after ponytail's ladder). Build vs reuse is a human
   decision, made at design time.
4. **Naming is a design signal.** If something is hard to name, the
   abstraction is probably wrong; renaming alone doesn't fix it.
5. **Consistency with the repo.** New code follows the patterns already
   established around it.
6. **Comments.** No comments about far-away consequences, none that
   reference specs or plans (those live in `docs/`), and no names from the
   ideation phase leaking into code.
7. **No defensive padding.** No checks, fallbacks, or options for cases
   that can't happen.
8. **Make the change easy, then make the easy change** (Beck). Preparatory
   refactors elsewhere are welcome.

Each catalog file holds: the principle in a few lines; the signals that
reveal it in code (what to search for); what counts as ambiguous and must
be asked; how to phrase a repo-specific rule; and which parts of it a
linter can typically enforce.

### The guide in each repo

Two parts:

**1. The always-loaded section**, in the repo's `AGENTS.md` between
`<!-- coding-principles:start -->` and `<!-- coding-principles:end -->`
markers. Budget: about 80 lines. It holds:

- Each adopted principle as a repo-specific rule in the repo's own names.
  Examples live in the detail file.
- A list of canonical modules, each a path and its symbol, introduced once
  with "use it; don't add another". Typical concepts include HTTP/API
  clients, config and environment, logging, error types, state stores,
  database access, auth, feature flags, and UI primitives.
- Design instructions: when designing a feature or writing a spec, use the
  `applying-coding-principles` skill; the spec must include its section
  under the exact heading "Coding principles applied"; when planning, copy
  every line of that section verbatim into the plan's Global Constraints;
  if a spec lacks the section, run the companion before planning. The
  heading is the contract between the spec and the plan.
- A severity line: breaking a rule in this guide is an Important finding.

A rule the repo's linter enforces gets no line in the always-loaded
section: the linter reports it when it matters, and its message, where the
rule takes one, says what to do and points to the detail file. The detail
file names the lint rule in its principle's summary and records the
decision behind it, as one line in the decision record. The
canonical-modules list stays even when a lint rule backs an entry,
because designers use it to find what to reuse.

**2. A detail file**, `docs/coding-principles.md`. Per principle, it holds
examples and counter-examples written in place: short snippets in the
repo's language and real names, shaped to make the point, never `path:line`
citations that drift as the code changes. An example appears only where
the rule's sentence alone could be misread. A one-off defect (an unused
dependency, a dead file) is follow-up work, not an example. The file ends
with a record of every decision made with a human ("thin wrappers around
`ApiClient`: avoid — decided 2026-11-23"). Agents read it on demand. It is
not loaded on every task.

**Instruction file:** the guide always lives in `AGENTS.md`, created if
missing. The skill never creates a `CLAUDE.md`. Claude Code reads
`AGENTS.md` only when no `CLAUDE.md` exists, so if the repo already has a
`CLAUDE.md` that doesn't import `AGENTS.md`, the skill offers to add the
line `@AGENTS.md` to it.

**Neighbours:** `AGENTS.md` is shared. The skill changes nothing outside
its markers, and a section another tool manages (between that tool's own
markers) belongs to that tool. The block never repeats a rule the file
already states. A decision that contradicts a line outside the markers
stays out of the block until that line changes at its source; the detail
file records it as a decision waiting on that change. The block's headings
start at the level of the file's own top-level sections.

### Setup skill: `setting-up-coding-principles`

Invoked to set up a repo, and again to refresh the guide.

1. **Read the repo.** Languages and frameworks, existing instruction files
   (including sections other tools manage), lint and format config,
   structure, and any existing convention docs. Existing rules are
   respected: a conflict with a principle is raised with the user, never
   overwritten silently.
2. **List canonical modules.** Find the single source of truth for each
   common concept, with paths. Two candidates for one concept is a question
   for the user.
3. **Interpret each principle against the code.** Search for examples
   using the catalog's signals and sort them into: clear examples to follow,
   clear counter-examples, and ambiguous cases.
4. **Ask about ambiguous cases.** One principle at a time, showing up to
   three real excerpts per question, in the style of superpowers'
   brainstorming. The user also confirms which principles the repo adopts
   or drops.
5. **Prefer the linter.** For each decided rule, check whether the repo's
   existing linter can enforce it (for example, limiting which module may
   import a library). If it can, propose the config change, with a message
   that says what to do and points to the detail file, and apply it once
   the user approves. Adding a linter the repo doesn't use, or writing a
   custom lint rule, is a build-vs-reuse question for the user.
6. **Show the draft, then write.** Write the always-loaded section and the
   detail file. Every path and symbol either file names must exist.
7. **Refresh mode.** On a re-run, regenerate the content between the
   markers from the detail file's decision record, keep human edits
   elsewhere, re-ask only new ambiguities, and report rules whose paths,
   symbols or lint rules no longer exist. If someone edited the marked block by hand since the
   last run, show the difference, record each edit as a decision in the
   detail file, and only then regenerate. Hand edits are never lost.

### Design companion: `applying-coding-principles`

Used during feature design, normally from inside superpowers'
brainstorming. Its description triggers on designing a feature or writing
a spec in a repo that has a coding-principles guide. The guide's design
instruction is the main trigger; the description is the fallback.

**Timing:** once the feature's "what" is understood and before approaches
are laid out, so reuse candidates shape the approaches. Its output goes
into the written spec.

1. Read the guide and the detail file.
2. Identify the code the feature will touch or extend.
3. **Find reuse candidates:** canonical modules from the guide, existing
   helpers near the touched code, framework features, and libraries already
   in the dependencies. Adding a new dependency or hand-rolling something a
   library covers is a build-vs-reuse question for the user.
4. **Apply each relevant principle** to this feature: where new code goes,
   which module to deepen rather than wrap, names for new concepts (a
   concept that's hard to name gets flagged), and what not to add.
5. **Ask about ambiguities**, one at a time.
6. **Write the "Coding principles applied" section** for the spec: short
   lines written as requirements with real paths, for example "Calls to the
   billing API go through `src/lib/http.ts`; add no new client." They are
   written so `writing-plans` can copy them verbatim into Global
   Constraints. A decision the repo's linter can enforce becomes a
   requirement to add that lint rule instead of a prose line.
7. If a decision changes the guide (a new canonical module, a new rule),
   propose a guide update.

### How it reaches superpowers' agents

- **Baseline:** the always-loaded section is in `AGENTS.md`, which every
  subagent loads (directly, or through `CLAUDE.md`'s import), so
  implementers and reviewers all see the rules and the canonical-module
  table.
- **Enforcement:** spec's "Coding principles applied" section → plan's
  Global Constraints (`writing-plans`) → each task reviewer's constraints
  block, verbatim → a violation is a spec failure → the fix loop runs.
- **Final review:** the whole-branch reviewer reads the plan, so it sees
  the same constraints.

### Distribution

- Installed from this repo's marketplace. A repo can enable it in its
  committed `.claude/settings.json` (`extraKnownMarketplaces` and
  `enabledPlugins`) so it's available to anyone working there.
- The skills are plain SKILL.md folders, so they can also be installed with
  the `skills` CLI for other tools.
- The guide is plain markdown in each repo. It works without the plugin;
  only the companion needs the plugin.

## Verification

- **Fixture repo** (under `tests/fixtures/` in this repo): a small,
  realistic codebase with a linter config, one canonical HTTP client, a
  couple of thin wrappers around it (ambiguous), a comment that references
  a plan, and similar planted cases. Fixtures are stored without live instruction files
  and copied to a temporary directory for each run, so they never act as
  instructions while someone works in this repo.
- **How checks run:** each check below is a written procedure that an
  agent runs against a fresh copy of the fixture and reports on. Each check
  runs once after every change to the skill it covers. There is no CI
  harness in v1; runs are not deterministic enough to assert on
  automatically.
- **Setup on the fixture:** every named path exists and no line number is
  cited; no rule is generic; the skill asks about the wrappers; a
  lint-enforceable decision lands in the linter config, with no line in the
  always-loaded section and a message pointing to the detail file; in a copy
  with no linter, the skill asks before adding one; the always-loaded
  section stays within budget.
- **End to end on the fixture:** brainstorm a feature that tempts a new
  thin wrapper around the existing HTTP client, a rule no linter enforces.
  The spec must name the existing client and forbid the wrapper, the plan's
  Global Constraints must carry those lines, and the task reviewer must
  flag a planted wrapper as a spec failure.
- **Compatibility checks:** subagents see a guide that lives only in
  `AGENTS.md`, both with no `CLAUDE.md` and with one that imports it;
  brainstorming invokes the companion from the guide's instruction alone;
  reviewers treat the severity line as written.
  If they don't, the spec path remains the enforcement route.
- **Pilot:** run setup on a real repo and judge whether the guide reads as
  written for that codebase.

## Risks

- Brainstorming may not invoke the companion reliably from one instruction
  line. Mitigation: the skill description also triggers it, and the end-to-end
  test checks it.
- Reviewers may keep grading guide violations as Minor despite the severity
  line. Mitigation: the spec path is the primary enforcement.
- `writing-plans` may paraphrase or drop the "Coding principles applied"
  lines when it fills Global Constraints. Mitigation: the guide's explicit
  verbatim-copy instruction, checked in the end-to-end test.
- A superpowers update could change how Global Constraints flow. Mitigation:
  document the tested version and keep the end-to-end test as a
  compatibility check.

## Left to the builder

The exact wording of both SKILL.md files and catalog entries, the search
heuristics per language, the fixture's contents, the question format, and
how excerpts are quoted.
