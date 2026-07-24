# LangChain Skills (langchain-ai/langchain-skills)

**Repo:** https://github.com/langchain-ai/langchain-skills
**License:** MIT declared in Claude plugin metadata, but no root LICENSE file and GitHub reports no detected license. Treat code/text reuse with attribution and caution until a LICENSE is added.
**Reviewed:** 2026-07-23
**Stack:** Agent Skills, Markdown, TypeScript, Vitest, pnpm, Claude Code plugin metadata
**What it is:** Official LangChain skill pack for helping coding agents build with LangChain, LangGraph, Deep Agents, Managed Deep Agents, RAG, human-in-the-loop, persistence, and eval engineering.

---

## Verdict

✅ **Deploy candidate for LangChain-family projects, with license and churn caveats.** The pack is practical: it gives agents current framework-selection guidance, quickstart constraints, dependency rules, human-in-the-loop patterns, persistence guidance, and a tested `swarm` utility for parallel row-based work. It is also explicitly early-development, and the missing root license file means broad redistribution/extraction should wait for upstream cleanup.

---

## What It Is

`langchain-skills` is a collection of 21 Agent Skills for agents that support the skills.sh/Agent Skills pattern. The repo targets Claude Code, Cursor, Windsurf, Deep Agents CLI, and similar coding agents that can load `SKILL.md` files on demand.

The content is mostly reference guidance rather than a runtime. Skills cover which LangChain layer to choose, exact dependency/version guidance, local quickstarts for Python and TypeScript, LangGraph graph/persistence/HITL patterns, Deep Agents memory/orchestration/managed deployment, RAG, middleware, and eval engineering with Harbor.

The one substantial executable component is `swarm`, a TypeScript helper skill that creates a table of independent rows, dispatches subagent work with bounded concurrency, batches rows when useful, merges structured JSON results back into the table, and supports filtering/retry flows.

## Stack

| Layer | Tech |
|-------|------|
| Skill format | `SKILL.md` directories under `config/skills/` |
| Agent packaging | skills.sh install flow, Claude Code plugin metadata, Deep Agents install script |
| Utility code | TypeScript ESM for `swarm` scripts |
| Tests | Vitest |
| Package management | pnpm 10 |
| CI | GitHub Actions on Node 22, `pnpm install --frozen-lockfile`, `pnpm test` |

## Key Features

### Ecosystem Router

The `ecosystem-primer` skill tells agents to pick among LangChain, LangGraph, and Deep Agents based on the task shape. This is valuable because a common failure mode in this ecosystem is reaching for LangGraph when `create_agent()` is enough, or using a plain agent loop when durable state, interrupts, or subagents are actually required.

### Fresh Quickstart Discipline

The quickstart skills explicitly tell agents to fetch the live official docs before writing code, create new isolated directories, avoid unnecessary Tavily/LangSmith setup unless requested, keep provider API keys in `.env`, and ask for a provider/model string. That is exactly the kind of guardrail that prevents stale imports and over-scaffolded demos.

### Human-In-The-Loop and Persistence Patterns

The LangGraph and LangChain middleware skills call out details agents often miss: every interrupt needs a checkpointer and thread ID, interrupt payloads must be JSON-serializable, resume re-executes code before `interrupt()`, and `Command` dynamic routing does not cancel separately declared static edges. Those warnings are concrete and useful.

### Eval Engineering Skill

The eval skill is unusually process-aware. It requires mapping the target agent first, separating real agent behavior from reconstruction, asking the user to choose eval direction, building one capability eval at a time, and auditing verifier behavior. That is stronger than a generic "write tests for the agent" prompt.

### Swarm Utility

The `swarm` skill is the repo's real code contribution. It builds durable row tables, validates template placeholders, filters rows, caps default subagent dispatch to 10, batches rows up to bounded sizes, requests structured responses, merges results while protecting reserved columns, and deduplicates failure groups.

## Architecture

The repository is intentionally simple:

```text
config/
  AGENTS.md
  skills/
    <skill-name>/SKILL.md
    swarm/scripts/*.ts
    eval-engineering/references/*.md
tests/
  swarm/*.test.ts
.claude-plugin/
  plugin.json
  marketplace.json
```

Most skills are documentation-as-runtime: their value is in forcing the agent to load the right narrow reference at the right time. The `swarm` skill adds a small TypeScript module with separate files for interpolation, filtering, batching, table storage, executor dispatch, and utilities.

The installer is straightforward Bash: it copies skills into `.claude`, `.deepagents`, or global equivalents, supports `--force`, and can install an AGENTS.md persona for global Deep Agents. Its destructive `rm -rf` paths are scoped to known install directories and skill directories, but it is still an installer script and should be reviewed before global use.

## Comparison

| Aspect | LangChain Skills | addyosmani/agent-skills | obra/superpowers | dzhng/skills |
|--------|------------------|-------------------------|------------------|--------------|
| Primary focus | LangChain/LangGraph/Deep Agents implementation help | General production engineering skills | Coding-agent workflow discipline | Portable software-factory skills |
| Best feature | Current ecosystem-specific code patterns | Breadth and lifecycle coverage | Planning/TDD/review methodology | Spec-slice and visual/workflow patterns |
| Executable code | Tested `swarm` helper | Some validation/install surfaces | Harness packaging/tests | Mostly prompt/workflow assets |
| Main caveat | Early dev, missing root license file | Can be too broad if installed wholesale | Workflow overlap with existing rules | Needs pruning to local process |

Use this pack when the task is specifically LangChain-family development. It is not a general agent behavior layer.

## Self-Hosting Notes

There is no service to self-host. Install selectively with `npx skills add langchain-ai/langchain-skills --skill <name> --yes` or as the Claude plugin. Avoid global `--skill '*'` installs unless the agent workspace is dedicated to LangChain work; a narrower local install keeps context cleaner.

Verification on this checkout passed:

```text
pnpm install --frozen-lockfile
pnpm test

Test Files  7 passed
Tests       172 passed
```

---

**Attribution:** langchain-ai/langchain-skills, MIT declared in plugin metadata; no root LICENSE detected
