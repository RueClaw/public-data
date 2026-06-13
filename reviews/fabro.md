# Fabro Review

Source: https://github.com/fabro-sh/fabro  
Author: fabro-sh / Qlty Software Inc.  
License: MIT  
Review date: 2026-06-13  
Reviewed commit: `bc0bda73a62f2f8beef82e9ac7d2cf4351ed9f69`  
Latest release observed: `v0.254.0` published 2026-06-04

## Verdict

✅ Deploy candidate for trusted single-tenant/internal agent workflow orchestration.

Fabro is one of the more complete open-source attempts at turning AI software work into deterministic, inspectable workflow software. The strongest idea is simple and useful: write agent processes as versioned Graphviz DOT graphs, route model choices separately, run them through sandboxes, and record durable events, checkpoints, stage outputs, and human decisions.

I would not expose it as a public multi-tenant service yet. Its own security docs call it a research preview and recommend private controlled networking; there are no built-in roles/ACLs, no app-level rate limiting, limited security-header controls, and local execution is intentionally not isolated. Treat it as a serious internal tool with serious operator caveats.

## What It Is

Fabro describes itself as an open-source dark software factory for expert engineers. In practice, it is a Rust-based agent workflow runtime plus web UI for running AI coding and automation workflows.

The central artifact is a `.fabro` workflow graph. Nodes model agents, prompts, commands, human gates, wait states, conditionals, parallel fan-out, merges, start, and exit. Run configuration lives in TOML and binds the graph to a goal, model routing, sandbox provider, preparation steps, environment variables, GitHub integration, notifications, checkpoints, artifacts, hooks, and MCP servers.

## Architecture

- Core runtime: Rust workspace with crates for CLI, workflow execution, agents, sandboxing, server, API, GitHub, MCP, LLM routing, telemetry, checkpoints, config, validation, and storage.
- Server/API: Axum/Tokio HTTP server, REST API, SSE event streams, OpenAPI-generated types and clients.
- Storage: SlateDB and object-store integration for durable run state and artifacts.
- UI: React 19, React Router, Vite, Tailwind, Bun, plus an Astro marketing/docs surface and generated TypeScript API client.
- Sandboxes: local, Docker, and Daytona providers behind a shared sandbox abstraction.
- Workflow language: Graphviz DOT with node shapes carrying semantics; model choice can be separated through CSS-like model stylesheets and graph classes.

## Strong Ideas

### Graphs Instead Of Prompt Loops

Fabro moves agent orchestration out of hidden chat transcripts and into a static, reviewable graph. That makes branches, retries, loops, parallel work, and human approvals part of the repo rather than part of a prompt ritual.

### Human Gates As Runtime Nodes

Human approval, interviews, and steering are first-class workflow stages. That is a better model than asking an agent to "check with me" inside prose, because the runtime can pause, resume, record the gate, and keep the graph honest.

### Sandbox Provider Boundary

The sandbox trait separates local execution from Docker and Daytona. The docs are refreshingly direct about the tradeoff: local sandboxes are convenience, not isolation; Docker and Daytona are the safer defaults for untrusted workflows.

### Checkpointed Agent Work

Fabro has explicit run branches, git checkpoints, events, archived runs, stage outputs, and resumability concepts. That is the right direction for long-running coding agents, where debugging the process matters as much as debugging the generated code.

### OpenAPI-First Control Plane

The OpenAPI spec is treated as a contract for Rust and TypeScript surfaces. That matters because agent runtimes tend to sprawl; a schema-first control plane gives other tools a stable place to attach.

## Caveats

- The security docs describe Fabro as a research preview and recommend private networking.
- It is single-tenant; there are no built-in roles, ACLs, or organization isolation.
- Local sandbox execution has the same host access as the Fabro process.
- The packaged Docker deployment can mount `/var/run/docker.sock`, which is effectively host-root-equivalent and should only be used in trusted environments.
- Public internet exposure needs external hardening: auth, reverse proxy policy, rate limiting, headers, allowlisting, and secret management.
- The graph DSL is powerful but could become a new maintenance burden without good authoring/debugging conventions.

## Verification

I reviewed the README, docs, `AGENTS.md`, root Cargo workspace, frontend package manifests, sandbox docs, workflow docs, and security docs at the reviewed commit.

Local checks on macOS:

- `bun --version && cd apps/fabro-web && bun install --frozen-lockfile && bun test`
  - Bun 1.3.14
  - 624 passed, 1 failed
  - The failure was `RunDetail full-height child routes > confirms deleting an archived run and navigates back to runs`.
- `cargo test --workspace --locked`
  - Build completed and many test crates passed before failing in `fabro-cli`.
  - Observed failure summary: 431 passed, 3 failed, 1 ignored in the failing CLI test binary.
  - Two failures involved invalid `FABRO_LOG_DESTINATION` handling around `stdot`; one involved a missing `/Users/zob/.fabro/auth.lock` in the local test environment.

These results are not a clean green local validation, but the failures look concentrated in CLI/env/test-harness edges rather than the core architectural model.

## Reuse Notes

The most reusable pattern is deterministic agent workflow graphs:

- Keep workflow topology in versioned DOT.
- Encode node kind visibly, using graph/node attributes instead of prompt-only convention.
- Keep model routing separate from workflow topology.
- Make human approval a real paused runtime state.
- Emit durable events, checkpoints, and stage outputs.
- Put sandbox provider choice behind one trait and make isolation boundaries explicit.

Extracted pattern: [deterministic-agent-workflow-graphs.md](../patterns/deterministic-agent-workflow-graphs.md)

## Bottom Line

Fabro is worth a private pilot if you are trying to make AI coding agents repeatable, observable, and governable. Its security posture is honest rather than polished, which is good: run it as trusted internal infrastructure first, prefer Docker/Daytona over local execution, and do not mistake the web UI for a hardened SaaS boundary.
