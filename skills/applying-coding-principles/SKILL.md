---
name: applying-coding-principles
description: Use when designing a feature or writing a spec or design doc in a repository whose AGENTS.md has a coding-principles section
---

# Applying coding principles

Turn the repo's coding principles guide into requirements for one feature, written into its spec under the exact heading `## Coding principles applied`. Superpowers' writing-plans copies that section verbatim into the plan's Global Constraints, and each task reviewer, who sees only the diff, checks the code against it as spec compliance. A line belongs there when a reviewer could use it to fail a wrong change.

**When:** once you know what the feature is for, and before you lay out approaches, so what you find to reuse shapes them. Inside superpowers' brainstorming, do steps 1 to 5 before the approaches message and step 6 when you write the spec. On a written spec without the section, do every step and add the section to that spec before planning.

## 1. Read the guide

Read `AGENTS.md` yourself, even if it's already in your context. The guide is the block between `<!-- coding-principles:start -->` and `<!-- coding-principles:end -->`: `## Coding principles`, then `### Rules`, `### Canonical modules`, `### When designing`, `### Severity`. Then read `docs/coding-principles.md`: each principle's `### Follow` and `### Avoid` examples, and the `## Decisions` record.

No block means no guide: say so, offer to set one up with `setting-up-coding-principles`, and stop.

## 2. Find the code the feature touches

The files it will change or extend, and the existing code nearest to what it adds: the module that already does the same kind of thing. Read them.

## 3. Find what to reuse

In order: the guide's canonical modules; helpers near the touched code; the standard library and the framework; libraries already in the package manifest. Adding a dependency, or hand-rolling what a library covers, is a build-vs-reuse question for the user: name both options and what each costs. Skip the question only when the user has already answered it.

## 4. Apply the guide to this feature

For each rule and decision that bears on the feature, decide:

- where new code goes: the existing directory or module it joins;
- which existing module to deepen instead of wrapping;
- names for new concepts, by the guide's naming rules. A concept that's hard to name signals a wrong boundary: flag it to the user rather than settle on a vague name;
- what not to add: a second module for a concept the guide gives a canonical module, a wrapper, defensive padding.

## 5. Ask what the guide doesn't settle

Two plausible homes for new code, a pattern the code does two ways, a rule that seems wrong for this feature: ask the user, one question per message. Show the code as `path:line` excerpts, say what you'd pick and why, and end with one question. If the user has said not to ask, make the call and mark it as yours in the spec.

## 6. Write the section

```markdown
## Coding principles applied

- Read the retry settings through `internal/config/config.go`; add no other environment reads.
- Add the webhook sender as functions in `internal/notify/`; add no client type that forwards to it.
- Ban `net/http` imports outside `internal/httpclient/` with `depguard` in `.golangci.yml`.
```

The section holds these lines, one bullet each:

- every canonical module the feature uses, as the one to use, adding no other;
- every rule in `### Rules` that this feature could break, phrased for this feature;
- each decision from steps 3 to 5;
- a new decision the repo's linter can enforce, as a requirement to add that lint rule, naming the rule and its config file, instead of a prose line.

Rules the linter already enforces are gated by the linter, so they get no line.

Each line is a requirement that stands alone when copied out of the spec: what to use or where to put it, and what not to add. It cites the code it relies on as a backticked `path` that exists now, with the symbol where the path alone is ambiguous, and no line numbers: tasks edit those files while the plan runs. New code is placed by the existing directory it joins, because a new file's path doesn't exist yet. Anything backticked that looks like a path is read as one, so write dotted symbols like process.env without backticks. No sub-bullets, no prose between bullets, no references to other parts of the spec.

Before handing over the spec, check every backticked path in the section exists.

## 7. Propose guide changes

When a decision should outlast this feature, such as a new canonical module or a new rule, tell the user and propose updating the guide with `setting-up-coding-principles`. Leave the `AGENTS.md` block and `docs/coding-principles.md` unedited.
