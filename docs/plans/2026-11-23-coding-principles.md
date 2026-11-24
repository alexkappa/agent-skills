# Coding Principles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Claude Code plugin, `coding-principles`, with a setup skill that writes a repo-specific coding-principles guide into `AGENTS.md`, and a design companion that applies it in every superpowers spec.

**Architecture:** Two skills joined by one interface: the guide format (a marked block in `AGENTS.md` plus `docs/coding-principles.md`). The setup skill interprets a catalog of principles against a repo's code and writes the guide; the companion reads the guide during brainstorming and writes a "Coding principles applied" section into the spec, which superpowers carries into plan Global Constraints and task reviews. Skills are tested superpowers-style (`superpowers:writing-skills`): baseline run without the skill, then with it, using headless `claude -p` against a copied fixture repo.

**Tech Stack:** Claude Code plugin (Markdown skills, JSON manifests); Bash for test tooling; TypeScript for the fixture repo only (never built or run).

**Spec:** `docs/specs/2026-11-23-coding-principles-design.md`

## Global Constraints

- Plugin `coding-principles`; skills `setting-up-coding-principles` and `applying-coding-principles`.
- The guide always lives in `AGENTS.md`, created if missing. Never create a `CLAUDE.md`. If a `CLAUDE.md` exists that doesn't import `AGENTS.md`, offer to add the line `@AGENTS.md`.
- Markers: `<!-- coding-principles:start -->` and `<!-- coding-principles:end -->`. Always-loaded block budget about 80 lines; `tests/check-guide.sh` fails it above 90.
- Block headings, in order: `## Coding principles`, then `### Rules`, `### Canonical modules`, `### When designing`, `### Severity`.
- `### When designing` names `applying-coding-principles`, the exact heading "Coding principles applied", and says to copy that section verbatim into the plan's Global Constraints.
- `### Severity` text, exactly: `Breaking a rule in this guide is an Important finding.`
- Detail file: one file, `docs/coding-principles.md`, with `# Coding principles`, one `## <principle name>` per adopted principle each holding `### Follow` and `### Avoid`, then `## Decisions` with lines ending `— decided YYYY-MM-DD`.
- Every cited path must exist and every excerpt must be quoted from the code. Citations use backticked `path` or `path:line`.
- A rule the repo's existing linter can enforce goes into the linter config (shown to the user first). The guide gets one `### Rules` line naming the lint rule and its config file, with no examples; the detail file records only the decision, as one line under `## Decisions`. Adding a new linter or a custom lint rule is a build-vs-reuse question for the user.
- Setup asks one principle at a time, with up to three excerpts per question. The companion runs before approaches are laid out.
- The principles catalog lives only in the setup skill.
- Skill descriptions start with "Use when" and state triggers only, never the workflow.
- Superpowers is never modified. Tested against superpowers 7.0.2. Claude Code ≥ 2.1.277 is required for `AGENTS.md` loading.
- No file outside `tests/fixtures/` references this plan, the spec, or task numbers.

## Review Focus

1. A repo whose `AGENTS.md` already has content, including a rule that conflicts with a principle: setup leaves everything outside the markers byte-identical and raises the conflict instead of overwriting it. (Task 3, check S2)
2. A hand-edited marked block on refresh: the edit is shown, kept if the user says so, and recorded as a decision. (Task 3, check S4)
3. Two candidates for one concept (`src/lib/http.ts` vs `src/legacy/fetch-helper.ts`): setup asks which is canonical instead of picking one. (Task 3, check S1)
4. A spec written without the companion: planning runs the companion first. (Task 4, check D5)
5. A cited example deleted from the code: refresh reports the drifted rule. (Task 3, check S4)

---

### Task 1: Test harness

**Files:**
- Create: `tests/fixtures/billing-app/` with `package.json` (TypeScript and ESLint as devDependencies), `tsconfig.json`, a minimal flat `eslint.config.js`, and the `src/` files listed in Step 3
- Create: `tests/fixtures/variants/agents-md/AGENTS.md.fixture`
- Create: `tests/fixtures/variants/claude-md/CLAUDE.md.fixture`
- Create: `tests/fixture-copy.sh`
- Create: `tests/check-guide.sh`
- Test: `tests/harness.test.sh`

**Interfaces:**
- Produces: `tests/fixture-copy.sh <variant>` prints the absolute path of a new temp directory: a git repo with one commit containing `billing-app` plus `tests/fixtures/variants/<variant>/` overlaid with the `.fixture` suffix stripped. Variants: `none`, `agents-md`, `claude-md`, `with-guide` (its overlay arrives in Task 3). Unknown variant: exit 2 with a message on stderr.
- Produces: `tests/check-guide.sh <repo-dir>` exits 0 when the guide matches the Global Constraints format; otherwise exits 1, printing one `FAIL: <reason>` line per failure. A `CLAUDE.md` without an `@AGENTS.md` line prints `WARN: ...` and does not change the exit code. A cited path is a backticked token ending in a file extension (optionally followed by `:line`) or ending in `/`; other backticked tokens, such as lint rule names and symbols, are not checked.

- [ ] **Step 1: Write the failing test** in `tests/harness.test.sh`, building sample guides inline in a temp dir:
  - `fixture-copy.sh none` → dir has `src/lib/http.ts`, no `AGENTS.md` or `CLAUDE.md`, and `git rev-list --count HEAD` is `1`
  - `fixture-copy.sh agents-md` → `AGENTS.md` exists and no `*.fixture` file remains
  - `fixture-copy.sh nope` → exit 2
  - `check-guide.sh` passes a well-formed sample, and prints a distinct `FAIL` for each of: missing end marker, block over 90 lines, a missing heading, a cited path that doesn't exist, a `path:line` past the file's end, `### When designing` without `Coding principles applied`, missing `docs/coding-principles.md`, detail file without `## Decisions`; and passes a sample citing `import/no-restricted-paths` (a lint rule name, not a path)
  - a sample with `CLAUDE.md` lacking `@AGENTS.md` → `WARN` and exit 0

- [ ] **Step 2: Run it to verify it fails**

  Run: `bash tests/harness.test.sh`
  Expected: FAIL (scripts don't exist)

- [ ] **Step 3: Create the fixture and the two scripts**

  `billing-app/src/` plants these cases (procedures in Tasks 3 and 4 rely on them):
  - `lib/http.ts`: the canonical client, `request<T>(path: string, init?: RequestInit): Promise<T>`, using `config.apiBaseUrl`, an auth header, and throwing `HttpError`
  - `lib/errors.ts`: `HttpError`, the canonical error type
  - `config.ts`: canonical config, reads env once
  - `lib/money.ts`: a deep module (parse, format, add) hiding cents and currency rules
  - `api/users.ts`: calls `request` directly, and has the comment `// Task 3 from the plan: fetch users before invoices`
  - `api/invoices-client.ts` and `api/payments-client.ts`: thin wrapper classes whose methods only forward to `request` under new names
  - `legacy/fetch-helper.ts`: a second HTTP helper calling `fetch` directly, used by `reports/monthly.ts`
  - `services/invoice-service.ts`: class `InvoiceServiceManagerHelper` with null checks on non-nullable parameters, a catch-and-rethrow, and an unused `options` parameter with defaults

  The `agents-md` overlay holds a short existing `AGENTS.md`: a setup-commands section and the rule "Wrap every API resource in its own client class." The `claude-md` overlay holds a `CLAUDE.md` with a few lines of build notes and no import.

- [ ] **Step 4: Run the tests to verify they pass**

  Run: `bash tests/harness.test.sh && find tests/fixtures \( -name AGENTS.md -o -name CLAUDE.md \)`
  Expected: all pass; `find` prints nothing

- [ ] **Step 5: Commit** (`test: add fixture repo and guide checker`)

### Task 2: Principles catalog

**Files:**
- Create: `skills/setting-up-coding-principles/references/principles/` with `deep-modules.md`, `one-source-of-truth.md`, `reuse-before-building.md`, `naming.md`, `consistency.md`, `comments.md`, `no-defensive-padding.md`, `make-the-change-easy.md`
- Test: `tests/catalog.test.sh`

**Interfaces:**
- Produces: eight catalog files. Each has the H1 name below, then `## Principle`, `## Signals in code`, `## Ask when`, `## Writing the repo rule`, `## Lint enforcement`, and is at most 60 lines. H1 names, in file order: "Deep modules", "One source of truth per concept", "Reuse before building", "Naming is a design signal", "Consistency with the repo", "Comments", "No defensive padding", "Make the change easy, then make the easy change".

- [ ] **Step 1: Write the failing test**: `tests/catalog.test.sh` asserts the eight files exist, each H1 matches its name exactly, the five H2 headings appear in order, and no file exceeds 60 lines.

- [ ] **Step 2: Run it to verify it fails**

  Run: `bash tests/catalog.test.sh`
  Expected: FAIL (files missing)

- [ ] **Step 3: Write the eight files** from the spec's catalog section. Signals are search-ready and not tied to one language. `reuse-before-building.md` gives the options in order: don't build it, existing code, standard library or platform, installed dependency, new code. "Ask when" names the cases a human must decide (for example, a wrapper pattern used more than once). "Writing the repo rule" shows how to turn a decision into a one-line rule with a `path:line` example. "Lint enforcement" names the kinds of linter rules that can enforce the principle (import restrictions, banned APIs), or says plainly that it needs human judgment.

- [ ] **Step 4: Run it to verify it passes**

  Run: `bash tests/catalog.test.sh`
  Expected: PASS

- [ ] **Step 5: Commit** (`feat: add coding principles catalog`)

### Task 3: Setup skill and plugin manifests

**Files:**
- Create: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- Create: `skills/setting-up-coding-principles/SKILL.md`
- Create: `skills/setting-up-coding-principles/references/guide-format.md`
- Create: `tests/procedures/setup.md`
- Create: `tests/fixtures/variants/with-guide/AGENTS.md.fixture`, `tests/fixtures/variants/with-guide/docs/coding-principles.md.fixture`, `tests/fixtures/variants/with-guide/eslint.config.js`

**Interfaces:**
- Consumes: `tests/fixture-copy.sh`, `tests/check-guide.sh` (Task 1); the catalog paths (Task 2).
- Produces: the installable plugin; the `with-guide` variant, which is a reviewed guide for the fixture that Task 4 starts from.

- [ ] **Step 1: Write the procedure** `tests/procedures/setup.md`. Preamble: copy a variant with `tests/fixture-copy.sh`, run `claude -p --plugin-dir <this repo> --permission-mode acceptEdits "<prompt>"` inside the copy, and answer the skill's questions with `claude -p -c --plugin-dir <this repo> --permission-mode acceptEdits "<answer>"`. Checks:
  - **S1** (`none`): the skill asks about the two wrapper clients and about `src/lib/http.ts` vs `src/legacy/fetch-helper.ts`, and shows its draft before writing any file. Answers: wrappers are to be avoided; `src/lib/http.ts` is canonical and the fetch helper is to be avoided. Pass when `tests/check-guide.sh` exits 0; `### Canonical modules` names `src/lib/http.ts`, `src/lib/errors.ts`, and `src/config.ts`; every `### Rules` bullet cites a path; `## Decisions` records both answers; no `CLAUDE.md` exists. The skill also proposes an ESLint rule backing the HTTP decision (for example, restricting imports of `src/legacy/fetch-helper.ts` or direct `fetch` outside `src/lib/http.ts`). After accepting, `eslint.config.js` holds the rule, and the guide has one `### Rules` line naming it and the config file, with no examples for it in the detail file.
  - **S2** (`agents-md`): the skill raises the conflict between the existing wrapper rule and deep modules. Pass when the file outside the markers is byte-identical to the overlay.
  - **S3** (`claude-md`): the skill offers the `@AGENTS.md` import. After accepting, `CLAUDE.md` holds that line with its other lines unchanged, and `check-guide.sh` prints no `WARN`.
  - **S4** (refresh, on S1's result): hand-edit one `### Rules` bullet, delete `src/legacy/fetch-helper.ts` and its use, commit, re-run setup. Pass when the skill shows the hand edit, and after it's kept the edit appears in both `## Decisions` and the regenerated block; the skill reports the rule or decision that cited the deleted file; and `check-guide.sh` exits 0.
  - **S5** (all runs): every question covers one principle and shows at most three excerpts, each with `path:line`.
  - **S6** (`none`, no linter): in the copy, delete `eslint.config.js` and the ESLint devDependency, commit, run setup, and decline any offer to add a linter. Pass when the skill asks before adding one, and after declining, no linter config or dependency is added and the rules are written as prose in the guide.

- [ ] **Step 2: Run the baseline (RED)** without the plugin: in a `none` copy, run `claude -p --permission-mode acceptEdits "Write coding conventions for this repository into AGENTS.md"`, then `tests/check-guide.sh <copy>`.
  Expected: FAIL. In the report, record whether the baseline asked anything, whether its rules were generic, and whether it named canonical modules.

- [ ] **Step 3: Write the manifests**

  `plugin.json`: name `coding-principles`, version `0.1.0`, description "Repo-specific coding principles for superpowers: a guide built from your own code, applied in every spec", author name `Alex Kalyvitis`, license `MIT`, repository `https://github.com/alexkappa/agent-skills`.
  `marketplace.json`: name `alexkappa`, owner name `Alex Kalyvitis`, one plugin entry `coding-principles` with source `./` and the same description and version.

- [ ] **Step 4: Write `references/guide-format.md` and `SKILL.md`**

  `guide-format.md` is the guide format from Global Constraints as an annotated skeleton of both files.
  `SKILL.md` frontmatter:
  ```yaml
  name: setting-up-coding-principles
  description: Use when setting up or refreshing a repository's coding principles guide, or when asked to write repo-specific coding conventions into AGENTS.md
  ```
  The body covers the spec's seven setup steps and the instruction-file rule, and points to `references/guide-format.md` and `references/principles/*.md` by relative path. Follow `superpowers:writing-skills`.

- [ ] **Step 5: Validate the plugin**

  Run: `claude plugin validate .`
  Expected: passes

- [ ] **Step 6: Run the procedure (GREEN)**

  Run every check in `tests/procedures/setup.md` once, each in a fresh copy.
  Expected: S1 to S6 pass. If any check fails, close the gap in `SKILL.md` and re-run.

- [ ] **Step 7: Save the `with-guide` variant** from S1's `AGENTS.md` and `docs/coding-principles.md`, adding the `.fixture` suffix, and S1's `eslint.config.js` as is.

  Run: `d=$(tests/fixture-copy.sh with-guide) && tests/check-guide.sh "$d"`
  Expected: exit 0

- [ ] **Step 8: Commit** (`feat: add setting-up-coding-principles skill`)

### Task 4: Design companion and README

**Files:**
- Create: `skills/applying-coding-principles/SKILL.md`
- Create: `tests/procedures/design-to-review.md`
- Create: `tests/fixtures/planted/wrapper-client.diff`, `tests/fixtures/planted/plan-comment.diff`, `tests/fixtures/planted/spec-without-section.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: the `with-guide` variant and the plugin manifests (Task 3); `tests/fixture-copy.sh`, `tests/check-guide.sh` (Task 1).
- Produces: a spec section headed exactly `## Coding principles applied`, whose bullets are requirements that cite backticked paths.

- [ ] **Step 1: Write the planted inputs and the procedure**

  `wrapper-client.diff` adds `src/api/export-client.ts`, a class whose methods only forward to `request` under new names, and uses it from a new `src/api/invoice-export.ts`. No lint rule catches this. `plan-comment.diff` adds a function with a comment referencing "the plan". `spec-without-section.md` is a short spec for invoice CSV export with no principles section.

  `tests/procedures/design-to-review.md`. Prerequisite: `claude --version` ≥ 2.1.277; otherwise stop and report. Checks, each in a fresh `with-guide` copy:
  - **D1**: `claude -p "Dispatch a general-purpose subagent. Ask it to quote the first row of the Canonical modules table from its instructions without reading any files."` Pass when the subagent quotes it. Repeat with a `CLAUDE.md` containing only `@AGENTS.md`.
  - **D2**: brainstorm "Add a CSV export of all invoices from the billing API". Answers: finance users download it monthly; no new dependencies. Pass when the transcript shows `applying-coding-principles` invoked before the approaches message, and the written spec has `## Coding principles applied` with lines naming `src/lib/http.ts` as the client to use and forbidding new wrapper classes around it, where every cited path exists.
  - **D3**: ask superpowers to write the plan for D2's spec. Pass when every bullet of the spec's section appears verbatim in the plan's Global Constraints (`grep -F` on each bullet's text).
  - **D4**: apply `wrapper-client.diff` in the copy. Fill superpowers 7.0.2's `task-reviewer-prompt.md` with the plan's first task brief (superpowers' `task-brief` script), the plan's Global Constraints, a review package of the diff (superpowers' `review-package` script), and a one-paragraph report. Run it with `claude -p`. Pass when Spec Compliance is ❌ and names `src/api/export-client.ts`.
  - **D5**: put `spec-without-section.md` in the copy and ask superpowers to plan it. Pass when `applying-coding-principles` runs before the plan is written and the plan's Global Constraints carry its lines.
  - **D6** (recorded, not pass or fail): as D4 but with `plan-comment.diff` and empty Global Constraints. Record the severity the reviewer gives the comment.

- [ ] **Step 2: Run the baseline (RED)**: D2 without `--plugin-dir`.
  Expected: the spec lacks the section or doesn't name `src/lib/http.ts`. Record what it produced.

- [ ] **Step 3: Write `SKILL.md`**

  ```yaml
  name: applying-coding-principles
  description: Use when designing a feature or writing a spec or design doc in a repository whose AGENTS.md has a coding-principles section
  ```
  The body covers the spec's seven companion steps, names the guide headings it reads, and states the exact output heading. A decision the repo's linter can enforce becomes a spec line requiring that lint rule, not a prose rule. Build-vs-reuse goes to the user. Guide changes are proposed through `setting-up-coding-principles`. Follow `superpowers:writing-skills`.

- [ ] **Step 4: Run the procedure (GREEN)**

  Run D2, D4 and D6 once, each in a fresh copy. D2 gives the answers in its first prompt and asks for the spec without further questions, so it takes one or two turns. D1, D3 and D5 are written down but run by hand later: D1 needs Claude Code >= 2.1.277, and D3 and D5 test superpowers' own planning, which costs a full plan run.
  Expected: D2 and D4 pass, and D6 is recorded. If a check fails, close the gap in `SKILL.md` and re-run that check, at most twice.

- [ ] **Step 5: Update `README.md`**: what the plugin does (two lines); install (`/plugin marketplace add alexkappa/agent-skills`, then `/plugin install coding-principles@alexkappa`); enabling it in a repo's committed `.claude/settings.json`; usage (run setup once per repo, then brainstorm as usual); requirements (superpowers 7.0.2 tested, Claude Code ≥ 2.1.277); and how to run `tests/` and `tests/procedures/`.

  Run: `claude plugin validate . && bash tests/harness.test.sh && bash tests/catalog.test.sh`
  Expected: all pass

- [ ] **Step 6: Commit** (`feat: add applying-coding-principles skill`)

---

After Task 4: pilot setup on a real repo and judge whether the guide reads as written for that codebase. That judgment is a human's, not part of execution.
