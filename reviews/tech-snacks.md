# Tech Snacks (ragnar-pwninskjold/tech-snacks)

**Repo:** https://github.com/ragnar-pwninskjold/tech-snacks
**License:** MIT; reusable with attribution. The vendored `intent-layer` skill preserves its own MIT license.
**Reviewed:** 2026-06-07
**Stack:** Claude Code plugin manifest, Markdown skills, JavaScript dynamic workflows, shell helpers
**What it is:** A Claude Code plugin that bundles reusable builder-oriented skills, research agents, templates, and workflow scripts.

---

## Verdict

⚠️ **Interesting skill-library pattern, not a deployable app.** Tech Snacks is useful if you live in Claude Code and want packaged workflows for UI cloning, PRD-to-UX prompt generation, CLAUDE.md scaffolding, session mining, and React performance refactor tournaments. The strongest part is the packaging discipline: each skill has an explicit trigger, references, templates, and boundary rules. The weak point is maturity: no test harness or CI is visible, and most behavior is prompt/workflow contract rather than executable code that can be verified automatically.

---

## What It Is

Tech Snacks is a small Claude Code marketplace plugin. It installs one plugin named `tech-snacks` and exposes a set of peer skills under `plugins/tech-snacks/skills/`, plus research agents and JavaScript workflow scripts under `plugins/tech-snacks/`.

The repo is aimed at builders who want repeatable agent procedures rather than one-off prompts. The skills cover website UI replication, translating PRDs into UX-generator prompts, scaffolding project-level `CLAUDE.md`, setting up intent-layer `AGENTS.md` files, terse tooling research, mining Claude Code sessions for durable project guidance, and running a React refactor tournament.

This is not a conventional library with an API. It is more like a packaged operating manual for Claude Code: install it, let Claude load the skill catalog, and then invoke the relevant skill or workflow when the user's request matches.

## Stack

| Layer | Tech |
|-------|------|
| Plugin packaging | Claude Code `.claude-plugin` marketplace and plugin manifests |
| Skill definitions | Markdown `SKILL.md` files with YAML frontmatter |
| Workflows | JavaScript dynamic workflow scripts |
| Agents | Markdown agent definitions for research fan-out |
| Helper scripts | Shell scripts inside the vendored `intent-layer` skill |
| Runtime services | None |

## Key Features

### Installable Skill Catalog

The repo uses the Claude Code plugin structure cleanly: a root marketplace file points at `plugins/tech-snacks`, and the plugin manifest carries version, author, license, and keywords. The README documents the expected install flow:

```bash
/plugin marketplace add ragnar-pwninskjold/tech-snacks
/plugin install tech-snacks@tech-snacks
```

That makes the repo easy to consume as a toolbox rather than a folder of copied prompts.

### Skills With References and Templates

The better skills avoid putting every instruction in the top-level `SKILL.md`. `ui-cloner` and `prd-to-ux` split the procedure into phase references and output templates. That keeps the entry skill readable while preserving detailed process where the agent can load it only when needed.

This is a good pattern for large agent skills: short catalog description, narrow trigger, then progressive disclosure through references, templates, and examples.

### Workflow-Backed Skills

`mine-claude-md` and `react-refactor-tournament` are wrappers around dynamic workflow scripts. They explicitly disable ad hoc inline execution and require the workflow runner because the workflow is doing the important part: fan-out, verification, ranking, isolated worktrees, token budgeting, and durable backlog writing.

That separation is the most interesting design decision in the repo. The skill describes when and how to run. The workflow owns orchestration.

### Built-In Skepticism

Several skills encode useful refusal and verification rules. `scaffold-claude` refuses to invent project conventions from directory structure. `mine-claude-md` requires candidates to be non-obvious, multi-file, not already documented, and adversarially verified. `react-refactor-tournament` refuses to run unless the real `vercel-react-best-practices` skill is installed.

Those rules are worth copying conceptually: agent workflows should define what does not qualify, not only what to produce.

## Architecture

The repo is shallow and readable:

- `.claude-plugin/marketplace.json` advertises the plugin.
- `plugins/tech-snacks/.claude-plugin/plugin.json` defines the installable plugin.
- `plugins/tech-snacks/skills/*/SKILL.md` are the skill entry points.
- `plugins/tech-snacks/skills/*/references/` holds detailed phase instructions.
- `plugins/tech-snacks/skills/*/templates/` holds canonical output shapes.
- `plugins/tech-snacks/agents/research/` holds helper agents for the research skill.
- `plugins/tech-snacks/workflows/*.workflow.js` holds dynamic workflow orchestration.

The main architectural move is "skill as contract, workflow as engine." Markdown decides when to activate and what constraints matter; JavaScript handles multi-agent orchestration and persistence.

## Comparison

| Aspect | Tech Snacks | Single Prompt Gist | Full Agent Framework |
|--------|-------------|--------------------|----------------------|
| Distribution | Claude Code plugin marketplace | Manual copy/paste | Package manager or app install |
| Structure | Skills, references, templates, agents, workflows | Usually one file | Code modules, runtime, APIs |
| Verification | Prompt-level gates plus workflow checks | Rare | Can be automated |
| Best use | Reusable Claude Code procedures | Small one-off behaviors | Production agent systems |
| Main weakness | Runtime behavior is hard to test without Claude Code | Drifts quickly | Heavier to adopt |

## Self-Hosting Notes

There is no server to host. The deployment model is plugin installation into Claude Code. Users who want to audit before installing should review the Markdown skills and workflow scripts directly because the plugin delegates a lot of behavior to agent instructions.

No hardcoded secrets were found in a basic scan. The repo also has a normal MIT root license and a separate license file for the vendored `intent-layer` skill.

---

**Attribution:** ragnar-pwninskjold/tech-snacks, MIT
