# Compound Engineering Plugin (EveryInc/compound-engineering-plugin)

**Repo:** https://github.com/EveryInc/compound-engineering-plugin  
**License:** MIT. Free to use, fork, and extract with attribution.  
**Reviewed:** 2026-07-12  
**Stack:** TypeScript/Bun CLI, Agent Skills, multi-surface plugin manifests, Markdown prompt assets  
**What it is:** A cross-harness agent workflow plugin that turns engineering work into a repeated loop: ideate, brainstorm, plan, implement, simplify, review, and capture learnings for the next run.

---

## Verdict

✅ **Deploy candidate for teams already using coding agents heavily.** The repo is not just a prompt pack: it has native plugin manifests, conversion/install tooling, a large regression suite, release automation, platform-specific docs, and careful migration code for Codex/OpenCode/Pi/Kiro/Antigravity-style targets. The main caveat is that much of the product is procedural behavior in skill documents, so adoption should start with a few skills rather than turning on the whole workflow everywhere at once.

---

## What It Is

Compound Engineering packages Every's internal agent-engineering workflow as an installable plugin. Its core premise is that each unit of engineering work should make the next unit easier: requirements become reusable plans, plans become implementation guardrails, reviews capture repeatable mistakes, and solved problems become future context.

The workflow is split into named skills such as `ce-ideate`, `ce-brainstorm`, `ce-plan`, `ce-work`, `ce-code-review`, `ce-debug`, `ce-polish`, `ce-compound`, and `lfg`. The stronger design choice is the separation between planning and execution: `ce-plan` records decisions, scope, implementation units, files, risks, and test scenarios, while `ce-work` figures out the actual code with the repository in front of it.

The repo also ships adapter code for multiple agent surfaces. Native Codex plugin install handles skills while the Bun converter fills gaps such as custom agents; other targets receive generated artifacts, MCP config, hooks, and cleanup behavior.

## Stack

| Layer | Tech |
|-------|------|
| Runtime / CLI | Bun, TypeScript, `citty` |
| Content format | Markdown skills, plugin manifests, YAML/TOML/JSON config |
| Target adapters | Codex, OpenCode, Pi, Kiro, Antigravity, Copilot/Droid-related converters |
| Tests | `bun test`, 1,930 passing tests locally |
| CI / release | GitHub Actions, release-please, plugin schema validation |
| License | MIT |

## Key Features

### Full Agent Engineering Loop

The best part is the opinionated workflow shape. The repo does not treat "ask an agent to code" as one step. It decomposes work into ideation, requirements, planning, execution, simplification, review, PR feedback, and learning capture.

This gives teams a shared vocabulary for when an agent should explore, when it should decide, when it should implement, and when it should stop and record what was learned.

### Guardrails-Not-Choreography Planning

`ce-plan` explicitly avoids pre-writing code or shell choreography. Plans define what must be true: decisions, scope boundaries, stable unit IDs, expected files, test scenarios, and risks. Execution is left to the implementer with current code in view.

That is a useful antidote to brittle agent plans that look specific but rot immediately.

### Cross-Harness Distribution

The plugin supports native manifests and conversion paths rather than assuming one agent runtime. `src/converters/claude-to-codex.ts` is a good example: by default it emits Codex agents only and lets native Codex plugin install own skills, avoiding double registration.

### Serious Test Posture

After `bun install --frozen-lockfile`, local `bun test` passed:

```text
1930 pass
0 fail
Ran 1930 tests across 73 files.
```

Tests cover converters, writer safety, path sanitization, session-history scripts, release metadata, skill contract invariants, and workflow documentation contracts.

## Architecture

The repo has three major layers:

1. Markdown skill assets under `skills/` and user-facing docs under `docs/skills/`.
2. TypeScript converters/writers under `src/` for turning one plugin source into target-specific artifacts.
3. Tests that enforce both code behavior and prose-level workflow contracts.

The code is more migration-aware than most prompt-pack repos. Codex writing tracks install manifests, sanitizes path components, preserves user symlinks, skips escaped managed stores, backs up configs before merging, and records only paths it actually wrote. That matters because plugin installers are filesystem mutators.

## Comparison

| Aspect | Compound Engineering | obra/superpowers | addyosmani/agent-skills |
|--------|----------------------|------------------|--------------------------|
| Primary focus | End-to-end engineering loop | Skill methodology and file-backed SDD | Broad production-engineering skill catalog |
| Packaging | Multi-surface plugin with converters | Multi-harness skills/plugins | Skills plus command parity validation |
| Strongest pattern | Plan/work/review/compound loop | File-backed implementation/review artifacts | Anti-rationalization and specialist review gates |
| Adoption risk | Workflow weight and prompt-procedure complexity | Process overhead if installed wholesale | Router/skill sprawl if unpruned |

## Self-Hosting Notes

This is a local plugin/tooling repo, not a server. Install paths vary by agent surface:

- Claude Code uses plugin marketplace install.
- Codex can add the GitHub repo as a custom marketplace, then install `compound-engineering`.
- Codex CLI can add the marketplace and plugin via `codex plugin marketplace add` and `codex plugin add`.
- The Bun CLI can convert/install for other supported targets.

Run installation in a test profile first. The repo is careful about backups and path safety, but any plugin that writes agent skills, hooks, prompts, config, and managed manifests should be treated as a local tooling change with real authority.

---

**Attribution:** EveryInc/compound-engineering-plugin, MIT License.
