# Open Multi-Agent (open-multi-agent/open-multi-agent)

**Repo:** https://github.com/open-multi-agent/open-multi-agent  
**License:** MIT; permissive reuse with attribution  
**Reviewed:** 2026-07-06  
**Stack:** TypeScript, Node.js, Vitest, OpenAI/Anthropic/Gemini/Bedrock/OpenAI-compatible providers, optional MCP and Vercel AI SDK bridges  
**What it is:** A TypeScript multi-agent orchestration framework that turns a high-level goal into a runtime task DAG, runs independent tasks in parallel, and synthesizes the result.

---

## Verdict

✅ **Deploy candidate for TypeScript teams that want goal-driven agent orchestration.** The core design is practical: a coordinator emits an inspectable task graph, a deterministic scheduler executes it, and production controls cover tools, checkpoints, plan replay, model routing, context management, traces, and human gates. The caveat is the same one every LLM-planned DAG inherits: dynamic plans are less predictable than hand-authored graphs, so production use should lean on `planOnly`, approval hooks, replay artifacts, and tight tool grants.

---

## What It Is

Open Multi-Agent, published as `@open-multi-agent/core`, is a small Node/TypeScript framework for running teams of LLM agents. The headline API is `runTeam(team, goal)`: a coordinator agent decomposes the goal into tasks, assigns or leaves them schedulable, and the runtime executes dependency-free branches in parallel before synthesis.

It also supports lower-control paths. `runAgent()` runs a single agent, `runTasks()` executes an explicit task graph, and `runFromPlan()` replays a serialized plan without asking the coordinator to re-plan. That gives users a useful ladder from simple calls to generated DAGs to reviewed, version-controlled plans.

The repository is young but not toy-shaped. At review time it had about 6.5k stars, 2.4k forks, 14 open issues, an active same-day push, CI across Node 18/20/22, package smoke tests, scaffold smoke tests, and a substantial Vitest suite around orchestration, tools, providers, checkpoints, budgets, and edge cases.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | TypeScript ESM, Node.js >= 18 |
| Package | `@open-multi-agent/core` plus `create-oma-app` scaffolder |
| Providers | Anthropic, OpenAI, Azure OpenAI, Gemini, Bedrock, Copilot, DeepSeek, Grok, Groq/OpenAI-compatible, Hunyuan, MiMo, MiniMax, Doubao, Qiniu, Ollama-style endpoints |
| Validation | Zod for custom tool schemas and structured outputs |
| Tools | Built-in bash/filesystem/search tools, custom tools, optional stdio MCP tools |
| Memory | In-memory store, file-backed store, custom `MemoryStore` interface |
| Testing | Vitest, TypeScript typecheck, GitHub Actions matrix |

## Key Features

### Goal-to-DAG Orchestration

The key product decision is runtime planning. Instead of requiring callers to declare every node and edge, OMA lets the coordinator produce a task DAG from the goal, then the scheduler runs ready tasks under configurable strategies: dependency-first, round-robin, least-busy, or keyword capability-match.

That is a good fit for broad research, coding, review, and triage jobs where the shape of the work changes per request. It is less ideal for regulated or deterministic workflows unless the plan is previewed and approved first.

### Plan Preview and Replay

`planOnly` and `createPlanArtifact()` are the strongest production affordances. They split planning from execution: preview the coordinator's graph, persist it as JSON, edit or review it, then execute the exact graph later with `runFromPlan()`. This does not make the LLM outputs deterministic, but it does make the workflow structure inspectable and repeatable.

### Tool Safety Posture

Built-in tools are default-deny. An agent receives no bash or filesystem tools unless they are explicitly granted by `tools` or `toolPreset`. Filesystem tools are path-contained to a working directory by default and resolve symlinks before access checks. The docs are also unusually candid that `bash` is not sandboxed and should be treated as host shell access.

The security model is not a full isolation boundary, but the defaults are sensible for a library that will be embedded inside other applications.

### Checkpoint and Resume

Checkpointing is opt-in and implemented through the same `MemoryStore` interface used for shared memory. Runs snapshot task queue state, completed results, and shared memory at task boundaries, with a zero-dependency `FileStore` option for restart durability.

The limitation is explicit: recovery is task-grained, not mid-task, and the system is snapshot-based rather than event-sourced.

### Provider and Cost Controls

The provider surface is broad, and the model-routing policy is deterministic: route coordinator/synthesis to a stronger model, leaf tasks to cheaper models, or match by agent, task role, priority, dependency shape, and phase. That is the right primitive for real cost control in multi-agent systems, where planner calls and leaf calls often deserve different models.

## Architecture

The repository is a compact monorepo:

- `packages/core/src/orchestrator/` owns `OpenMultiAgent`, scheduling, task execution, checkpoints, consensus, plan replay, and synthesis.
- `packages/core/src/agent/` owns agent state, runner loops, streaming, structured output, loop detection, and pools.
- `packages/core/src/tool/` owns built-in tools, Zod-validated custom tools, MCP integration, output truncation, and grant filtering.
- `packages/core/src/memory/` owns shared memory, checkpoints, and the file store.
- `packages/create-oma-app/` is a zero-runtime-dependency scaffolder that ships a runnable template.

The design is conventional in a good way: typed interfaces, small subsystems, clear tests, and docs that match the implementation. The most important pattern is separating LLM planning from deterministic scheduling. The coordinator can be probabilistic; the task queue and scheduler remain ordinary software.

## Comparison

| Aspect | Open Multi-Agent | LangGraph JS | Mastra | CrewAI |
|--------|------------------|--------------|--------|--------|
| Primary shape | Goal-driven runtime DAG | Explicit graph | Developer-wired workflows/agents | Python multi-agent teams |
| Language fit | TypeScript/Node backend apps | JS/TS ecosystem | TypeScript app framework | Python ecosystem |
| Determinism | Dynamic unless using plan preview/replay | Stronger graph determinism | Depends on workflow design | Depends on crew/task design |
| Best use | Adaptive multi-step jobs in Node apps | Durable hand-modeled workflows | App-level agent products | Python-first agent teams |

OMA is strongest when the caller wants the system to decide the task graph. If the graph is known and must be stable, graph-first tooling remains a better default.

## Self-Hosting Notes

This is a library, not a server to deploy. Install `@open-multi-agent/core`, grant tools narrowly, wire provider credentials through environment variables or explicit config, and use process/container isolation if granting shell access to agents.

For long-running jobs, use a durable `MemoryStore` or `FileStore` checkpoint backend, set human approval hooks around generated plans, and store plan artifacts when repeatability matters. The CLI and `create-oma-app` package are useful for demos and CI-style runs, but production embedding should call the TypeScript API directly.

## Verification

Reviewed source at commit `ef03695d290691dddab1b8193d2803fd1c5ac65e` from 2026-07-06. Local tests were not run because the shallow clone had no installed dependencies (`vitest: command not found`). Static review covered README/docs, package manifests, CI, source layout, scheduler/orchestrator/tool/memory paths, built-in tool safety tests, checkpoint tests, and a grep scan for obvious secret/eval hazards.

---

**Attribution:** open-multi-agent/open-multi-agent, MIT
