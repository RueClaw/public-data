# Motus (lithos-ai/motus)

**Repo:** https://github.com/lithos-ai/motus
**License:** Apache-2.0; permissive reuse with attribution and patent grant.
**Reviewed:** 2026-05-17
**Stack:** Python 3.12+, FastAPI/Uvicorn, Pydantic, httpx, OpenAI/Anthropic/Gemini/OpenRouter clients, MCP SDK, Docker SDK, uv, pytest
**What it is:** Motus is an open-source agent serving and runtime framework: write or bring a Python agent, serve it over a session API, run task-graph workflows, connect tools/MCP/sandboxes, and optionally deploy to Motus Cloud.

---

## Verdict

⚠️ **Interesting, but keep deployment boundaries tight.** Motus has a clean Python-first shape and a useful serving/runtime layer for agents without forcing a heavyweight DAG framework. The serving defaults and sandbox/cloud edges deserve scrutiny before internet-facing deployment, but the task runtime and session API are worth studying.

---

## What It Is

Motus presents itself as "agent serving" rather than another agent framework. That framing is useful: the repo includes a native ReAct agent and tool abstractions, but it also supports OpenAI Agents SDK, Anthropic SDK, Google ADK, and plain Python callables. The main product promise is that the same agent code can run locally behind a FastAPI session server or deploy to Motus Cloud.

The core programming model has two parts. For agents, Motus provides a ReAct loop with memory, tools, guardrails, provider clients, prompt caching, tracing, and serving. For workflows, the `@agent_task` decorator turns normal Python functions into futures in a dependency graph; Motus infers parallelism from data flow instead of requiring an explicit DAG file.

The repository is young but not empty: it has docs, examples, plugin assets for coding agents, CODEOWNERS, pre-commit config, and a meaningful unit test suite. A focused local run of `tests/test_executor_exit.py` plus `tests/unit` passed with 873 tests and 18 skips.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python 3.12+, asyncio, thread pool execution for sync tasks |
| Serving | FastAPI, Uvicorn, session/message/resume APIs, SSE events |
| Agent loop | ReActAgent, model clients, tool dispatch, memory, guardrails |
| Workflow | `@agent_task`, AgentFuture, graph scheduler, retries/timeouts/hooks |
| Tools | Function tools, MCP tools, file/search/bash built-ins, sandbox abstraction |
| Providers | OpenAI, Anthropic, Gemini, OpenRouter, optional Google ADK/OpenAI Agents |
| Deployment | LithosAI/Motus Cloud auth and deploy commands |
| Quality | pytest, pytest-asyncio, VCR, pre-commit, ruff settings |

## Key Features

### Session-Based Agent Serving

`src/motus/serve/server.py` exposes a single-agent server with sessions, message submission, resume-after-interrupt, SSE event streaming, health checks, and optional webhooks. This is a pragmatic interface for turning an agent into a service without building the HTTP wrapper from scratch.

### Dataflow Task Runtime

The `@agent_task` decorator returns futures immediately and lets the runtime infer dependencies from arguments. That makes simple parallel workflows feel like normal Python:

- call `fetch()`;
- pass that future to `summarize()` and `extract()`;
- pass both downstream to `publish()`;
- `resolve()` at the edge.

This is the strongest reusable idea in the repo: DAG behavior without a separate DAG syntax.

### Framework Interop

The examples include native Motus agents, OpenAI Agents SDK, Anthropic, Google ADK, MCP tools, serving examples, and runtime demos. That "bring your current agent" posture is more useful than trying to own every abstraction.

### Built-In Guardrails and Memory

Motus includes basic and compaction memory, input/output guardrail hooks, structured output support, and model usage/pricing metadata. The pieces are modest but placed where agent services actually need them.

## Architecture

Important top-level areas:

- `src/motus/agent/` — base agent, ReAct loop, task/model serving helpers.
- `src/motus/runtime/` — futures, task graph scheduler, policies, hooks, tracing.
- `src/motus/tools/` — function tools, MCP sessions, sandbox abstraction, built-ins.
- `src/motus/serve/` — FastAPI session server, CLI client, worker executor.
- `src/motus/models/` — provider clients and pricing metadata.
- `src/motus/memory/` — append-only and compaction memory.
- `src/motus/auth/` and `src/motus/deploy/` — cloud authentication and deployment.
- `examples/`, `docs/`, and `plugins/motus/` — onboarding and coding-agent plugin assets.

The implementation is more approachable than many agent platforms because the code is mostly ordinary Python modules rather than generated plugin sprawl. The tradeoff is that the serving/cloud/sandbox boundaries are powerful enough to need a serious security pass.

## Comparison

| Aspect | Motus | Ruflo | Smaller agent libraries |
|--------|-------|-------|-------------------------|
| Primary shape | Python agent serving/runtime | Claude Code orchestration platform | Agent loop/tool library |
| Adoption posture | Try locally, inspect deploy path | Study/harvest selectively | Often easier to adopt directly |
| Strongest pattern | Dataflow task runtime + session server | Signed witnesses and plugin taxonomy | Simplicity |
| Main risk | Serving/sandbox/cloud security boundaries | Huge alpha surface | Missing operational layer |

## Self-Hosting Notes

`motus serve start myapp:agent --port 8000` starts a local FastAPI server. The server defaults bind to `0.0.0.0` in `AgentServer.run()`, so production or LAN use should put it behind explicit auth and network policy. The CLI can send Authorization headers from Motus credentials, but the reviewed `AgentServer` code does not show corresponding auth middleware on session/message routes.

The webhook feature is useful for async completion, but request-provided webhook URLs can receive agent outputs. In hosted deployments that needs SSRF and data-exfiltration controls at the platform layer.

Docker sandbox support is powerful, but treat it as convenience isolation unless a deployment proves network, mount, user, resource, and capability hardening.

## Security and Maturity Notes

- Public repo metadata at review time: 446 stars, 28 forks, public, pushed 2026-05-12.
- GitHub API did not report a license, but the repository contains Apache-2.0 `LICENSE` and the README badge/pyproject classifiers say Apache.
- `pyproject.toml` version is 0.4.2; latest release visible during reconnaissance was v0.4.1.
- Focused local tests passed: 873 passed, 18 skipped, 134 warnings in about 2m50s.
- `install.sh` and docs promote `curl | sh`, which is common for CLIs but high-friction for locked-down environments.
- Quick secret scan found examples/env usage, not obvious committed credentials.

---

**Attribution:** lithos-ai/motus, Apache-2.0 License.
