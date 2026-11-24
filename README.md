# agent-skills

`coding-principles` is a Claude Code plugin that writes a repo's coding principles into its `AGENTS.md`, built from the repo's own code and decided with you.
When you design a feature with [superpowers](https://github.com/obra/superpowers), it adds a "Coding principles applied" section to the spec, which superpowers carries into the plan and every task review.

## Install

```
/plugin marketplace add alexkappa/agent-skills
/plugin install coding-principles@agent-skills
```

To make it available to everyone working in a repo, add this to the repo's committed `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "agent-skills": {
      "source": { "source": "github", "repo": "alexkappa/agent-skills" }
    }
  },
  "enabledPlugins": {
    "coding-principles@agent-skills": true
  }
}
```

## Usage

1. Once per repo, ask Claude to set up coding principles. The `setting-up-coding-principles` skill reads the code, asks you about the patterns it can't judge alone, and writes the guide into `AGENTS.md` and `docs/coding-principles.md`. Run it again to refresh the guide.
2. Then brainstorm features with superpowers as usual. The `applying-coding-principles` skill runs before the approaches are laid out and writes the spec's "Coding principles applied" section.

## Requirements

- Claude Code 2.1.277 or later, which loads `AGENTS.md`.
- superpowers; tested with 7.0.2.

## Tests

```bash
claude plugin validate .
bash tests/harness.test.sh
bash tests/catalog.test.sh
```

The skills' behaviour is checked by hand with the procedures in `tests/procedures/`: `setup.md` for the setup skill and `design-to-review.md` for the path from spec to plan to task review. Each check runs headless `claude -p` against a fresh copy of the fixture repo in `tests/fixtures/`, made with `tests/fixture-copy.sh <variant>`.
