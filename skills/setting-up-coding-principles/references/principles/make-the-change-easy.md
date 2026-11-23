# Make the change easy, then make the easy change

## Principle

Kent Beck's rule: when a change fits the code badly, first refactor so it fits, as its own behavior-preserving step, then make the change as a small diff. Preparatory refactors in other parts of the repo are welcome. The anti-pattern is forcing the change in: a flag, a special case, a copy-and-tweak, or a parallel path beside code that should have changed.

## Signals in code

Look in code and history for changes that were forced in:

- Boolean or mode parameters added to shared functions so one caller gets different behavior (`skipValidation`, `legacy=True`, `mode: "bulk"`).
- Special cases keyed on one caller or record: `if (type === "legacy")`, `if tenant == "acme"`, `if user.id == ADMIN_ID`.
- Copy-and-tweak: near-identical functions or files (`handler.ts` and `handler-v2.ts`, `process_order` and `process_order_bulk`); `git log --follow` shows one born as a copy of the other.
- Parallel paths kept alive: `old`, `new`, `v2`, `legacy` names; feature flags that are always on.
- Functions with a long tail of optional parameters, each added by a different commit (`git log -L :<function>:<file>`).
- How the repo lands changes: `refactor:` commits ahead of `feat:` commits, or large diffs that mix both (`git log --oneline --stat`).

## Ask when

- The refactor that would make a change easy touches a public API, another team's code, or a hot path: ask whether it's in scope by default or needs sign-off.
- The repo prefers small PRs: ask whether preparatory refactors land as their own PR or as separate commits in the same PR.
- A flag or special case may be the repo's chosen extension point (plugin hooks, strategy maps, per-tenant config): ask before treating it as a smell.

## Writing the repo rule

Say how preparatory refactors land and what they may touch.

- Shape: "If a change doesn't fit, refactor first in a separate <commit or PR> with no behavior change, then make the change. <Scope limit, if any>. Example: `<path:line>`."
- Example: "Refactor first, in its own `refactor:` commit, then add the feature; refactors anywhere in `src/` are in scope without asking. Example: `src/pricing/rules.ts:12`, a strategy map an earlier refactor made for this."

## Lint enforcement

Needs human judgment: whether to refactor first is a design decision a linter can't see. Commit-message tools such as commitlint can require `refactor:` and `feat:` prefixes, but can't check that a refactor left behavior unchanged.
