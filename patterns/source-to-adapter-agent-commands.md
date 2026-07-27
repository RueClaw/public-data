# Source-to-Adapter Agent Commands

> **Source:** [simoncorry/foundry](https://github.com/simoncorry/foundry) by Simon Corry
> **License:** MIT
> **Extracted:** 2026-07-26

## Pattern

Keep one editable command source tree, generate each agent harness's required shape from it, and make CI fail when generated files drift or orphan files appear.

Foundry uses `.cursor/commands/` as the source of truth. A generator emits:

- `.claude/commands/<name>.md` as a byte-identical copy
- `.agents/skills/<name>/SKILL.md` as a frontmattered Codex skill
- `.agents/skills/<name>/agents/openai.yaml` with manual-only invocation policy

## Why It Works

Agent command libraries tend to spread across tool-specific folders. Once authors edit one generated copy by hand, the command's behavior depends on which harness loads it. Foundry avoids that by making the editable source obvious and making drift a failing check.

The design is also easy to inspect. The generator needs no dependencies, derives the skill description from the command's first sentence, and treats orphan generated files as drift rather than ignoring them.

## Implementation Shape

```text
.cursor/commands/              # source of truth
  build-it.md
  frame-it.md
  ...
.claude/commands/              # generated
  build-it.md
  frame-it.md
.agents/skills/                # generated
  build-it/SKILL.md
  build-it/agents/openai.yaml
```

CI should run the generator in confirm mode:

```bash
node scripts/generate-command-shapes.js --confirm
```

Confirm mode checks that every generated file matches expected output and that no extra generated files exist without a source command.

## Adaptation Guide

1. Pick the harness with the simplest authoring shape as the source tree.
2. Generate every other harness-specific layout from that source.
3. Mark generated files as generated at the top.
4. Add a confirm mode that exits nonzero on drift, missing files, and orphans.
5. Run confirm mode in the repo's normal check command.

This pattern works for agent skills, slash commands, prompt packs, MCP server prompts, and reusable workflow playbooks.

## Caveats

- Do not hide meaningful harness differences. If one adapter needs extra policy, generate it explicitly.
- Put local overrides somewhere outside the generated tree.
- Keep generated descriptions short; they show up in agent skill selectors and command palettes.
