# Omnigent (omnigent-ai/omnigent)

**Repo:** https://github.com/omnigent-ai/omnigent  
**License:** Apache-2.0; permissive reuse with attribution and notice preservation  
**Reviewed:** 2026-07-11  
**Stack:** Python 3.12+, FastAPI/Starlette, SQLAlchemy/Alembic, OpenTelemetry, tmux/PTY wrappers, OS sandboxes, React/web UI, Docker/Kubernetes/cloud sandbox deploys  
**What it is:** Omnigent is a meta-harness for running, governing, sharing, and switching between coding-agent runtimes such as Claude Code, Codex, Cursor, OpenCode, Hermes, Pi, Kimi, Qwen, Copilot, Antigravity, and custom YAML-defined agents.

---

## Verdict

✅ **Deploy candidate for teams serious about agent operations, with alpha caution.** Omnigent is ambitious but unusually concrete: it has real harness adapters, policy gates, OS sandboxing, multi-user auth, hosted/server deployment paths, native/terminal wrappers, cloud sandbox providers, and broad CI. The risk is scope: this is a large fast-moving alpha system, so treat adoption as a staged pilot rather than a drop-in replacement for an existing agent stack.

---

## What It Is

Omnigent gives agent users a common control plane over many different agent runtimes. Instead of building separate workflows around Claude Code, Codex, Cursor, OpenCode, Pi, Hermes, and custom agents, it wraps them behind a shared session model with terminal/browser/mobile access, server-hosted collaboration, policies, cost controls, sandboxing, and model/provider switching.

The repo includes a CLI, server, Python SDKs, web/desktop/mobile-facing UI, native harness integrations, agent YAML format, deployment templates, and a substantial test suite. It is not just a prompt framework. The core product is orchestration and governance across heterogeneous agent runners.

The strongest idea is the separation between "agent harness" and "control plane." Harness-specific code lives behind adapters while policies, auth, sharing, session state, sandboxes, and observability sit above them.

## Stack

| Layer | Tech |
|-------|------|
| Core runtime | Python 3.12+, Pydantic, Click, prompt_toolkit, Rich |
| Server/API | FastAPI, Starlette, Uvicorn, OpenAPI, SSE/WebSocket routes |
| Persistence | SQLAlchemy, Alembic, SQLite/Postgres-compatible design, zstandard-compressed text columns |
| Agent harnesses | Claude SDK/native, Codex/native, Cursor/native, OpenCode, Hermes, Pi, Kimi, Qwen, Copilot, Antigravity, OpenAI Agents |
| Sandboxing | Linux bubblewrap, macOS seatbelt, Windows Job Object containment, cloud sandbox providers |
| Governance | Declarative policies with ALLOW/ASK/DENY, built-in safety/cost/provider policies, admin/session/agent policy layers |
| Observability | OpenTelemetry design, trace propagation across server/runner/harness boundaries |
| Deployment | Docker Compose, Kubernetes, Fly, Render, Railway, Cloudflare, Modal, Daytona, E2B, CoreWeave, OpenShell, Boxlite, Databricks |

## Key Features

### Cross-Harness Agent Sessions

Omnigent can launch native or SDK-backed sessions for multiple coding-agent runtimes and keep them under one UI/session model. That makes it useful when different tools have different strengths: one session can run a Claude Code-style terminal agent, another can use Codex, and custom YAML agents can define tools, subagents, OS access, model credentials, and policies.

### Declarative Policies

Policies evaluate actions at request, response, tool-call, and tool-result phases and return `ALLOW`, `ASK`, or `DENY`. They can be configured at three levels:

- session-level policies from the end user;
- agent-spec policies from the agent developer;
- server-wide policies from an admin.

Built-ins include tool-call limits, shell/file approval gates, skill blocking, sandbox enforcement, PII checks, cost budgets, daily per-user budgets, GitHub/Google access policies, and risk-score routing.

### Sandboxing and Secret Handling

Local OS access is explicitly declared in agent YAML. Linux uses bubblewrap, macOS uses seatbelt, and Windows has degraded process-tree containment through Job Objects. The repo also includes cloud sandbox provider integrations for running agent work away from the user's laptop.

The standout security pattern is the sandbox credential proxy: real credentials stay in the parent process, while sandboxed tools either get no credential at all or a synthetic placeholder. The egress proxy attaches the real credential only for the configured host and rejects placeholder replay to the wrong host.

### Multi-User Server and Sharing

Omnigent can run as a local CLI/web UI or as a deployed server. The Docker stack supports built-in accounts, OIDC, header-proxy auth, invite links, HTTPS via Caddy overlay, and Postgres-backed persistence. Recent release notes emphasize sharing modes, "Shared with me" sessions, project/worktree grouping, and mobile/browser continuity.

### Large Test and CI Surface

The repo has hundreds of tests and a broad CI setup: Python unit/e2e suites, web tests, visual snapshots, Windows smoke checks, security-gated fork PR workflows, coverage reporting, performance benchmarks, and workflow-level unit tests for repo automation. That is a strong maturity signal for a project that is still labeled alpha.

## Architecture

Omnigent is organized around a few big boundaries:

- `omnigent/inner/` holds executor, harness, sandbox, tool, policy, and tracing internals.
- `omnigent/server/` holds auth, accounts, sharing, routes, host/runner tunnels, policy registry, and server config.
- `omnigent/*_native.py` and `omnigent/inner/*_harness.py` files implement harness-specific adapters.
- `docs/AGENT_YAML_SPEC.md` describes portable agent declarations.
- `docs/POLICIES.md` describes the ALLOW/ASK/DENY policy model.
- `deploy/` contains deployment recipes for local Docker and many cloud/sandbox providers.

The architecture is sprawling, but the conceptual split is good: agent runtimes are replaceable harnesses; the control plane owns identity, sessions, permissions, policy, sandboxing, collaboration, and observability.

## Comparison

| Aspect | Omnigent | Superpowers | open-multi-agent | Mission Control |
|--------|----------|-------------|------------------|-----------------|
| Primary role | Agent runtime/control plane | Coding-agent workflow skills | Multi-agent planning/execution framework | Agent operations dashboard/control plane |
| Enforcement | Runtime policies, sandboxing, auth, server controls | Prompt/skill behavior shaping | Tool allowlists/checkpoints | Runtime dispatch/control UI |
| Harness scope | Broad multi-harness adapters | Skill packages across harnesses | Provider/model framework | Operational agent management |
| Deployment | Local CLI, server, Docker, cloud sandboxes | Installed per coding harness | App/framework | Self-hosted app |
| Caveat | Very broad alpha surface | Not a runtime guardrail | Narrower orchestration focus | Less cross-harness native wrapping |

## Self-Hosting Notes

For local use, the README recommends installing through `uv tool install omnigent`, Homebrew, or the bootstrap script. For shared deployment, the Docker Compose path is the clearest starting point:

- built-in accounts are default;
- OIDC is supported for real multi-user deployments;
- HTTPS should sit in front of any public deployment;
- server-managed cloud sandboxes require provider-specific credentials and careful policy defaults.

Windows support is explicitly degraded: server/web/SDK harnesses work, but native tmux/PTY wrappers and bwrap/seatbelt network/filesystem sandboxing do not.

## Verification Notes

Local checks on 2026-07-11:

- Cloned current `main` at `6e3c77855b08c9b612bf20763fe14f57a7ff9ad4`.
- Latest GitHub release: `v0.5.1`, published 2026-07-10.
- GitHub API reported license metadata as null, but the repo contains an Apache-2.0 `LICENSE` and README badge.
- `python3 -m compileall -q omnigent sdks/python-client/omnigent_client` passed.
- Targeted pytest could not run because this machine has `uv 0.11.7` and the repo requires `uv >=0.11.8`.
- Secret-pattern scan found canary/test fixture strings only, in tests that assert redaction behavior.

---

**Attribution:** omnigent-ai/omnigent, Apache-2.0
