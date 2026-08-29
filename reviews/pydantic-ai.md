# Pydantic AI (pydantic/pydantic-ai)

**Repo:** https://github.com/pydantic/pydantic-ai
**License:** MIT; permissive reuse with attribution
**Reviewed:** 2026-08-28
**Stack:** Python 3.10+, Pydantic v2, pydantic-core, AnyIO, httpx2, OpenTelemetry, uv workspace, Starlette extras, provider SDK extras
**What it is:** A typed Python SDK for building AI agents, model-provider integrations, realtime sessions, structured outputs, toolsets, evals, graph workflows, CLI/web interfaces, and durable execution integrations.

---

## Verdict

✅ **Deploy candidate for typed Python agent applications.** This is a mature, heavily used SDK from the Pydantic team, with strong provider coverage, typed tools and outputs, composable capabilities, graph/eval packages, and unusually serious CI and dependency hygiene. The caveat is scope: it is a broad, fast-moving framework, so teams should adopt it deliberately and write provider-specific smoke tests around the model surfaces they actually use.

---

## What It Is

Pydantic AI is the Pydantic team's agent SDK. It uses Pydantic models, type hints, and validators to make agent dependencies, tool arguments, structured outputs, and eval cases visible to Python tooling instead of hiding them in prompt strings.

The monorepo publishes multiple packages: `pydantic-ai`, `pydantic-ai-slim`, `pydantic-graph`, `pydantic-evals`, `clai`, and examples. The core agent package covers model providers, typed function tools, toolsets, MCP, deferred tools, provider-native tools, realtime APIs, web/CLI integration, instrumentation, cost calculation, durable execution adapters, and declarative agent specs.

The current README also positions Pydantic AI beside a separate first-party Pydantic AI Harness package. That harness is not the same source tree, but the core repo clearly supports the same architectural direction: capabilities, tool search, compaction-related primitives, approval/deferred tools, model selection, and typed graph execution.

At review time the repo had about 19.6k stars, 2.6k forks, 749 open issues, and a latest release of `v2.36.0` published on 2026-08-29 UTC. The fetched commit was `6aee1c09bd065725ff14f21a15f731b0c3c88e0c`.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python 3.10+ |
| Validation | Pydantic v2, pydantic-core |
| Async/concurrency | AnyIO, asyncio |
| HTTP | httpx2, provider SDKs |
| Agent core | `pydantic_ai_slim/pydantic_ai` |
| Graphs | `pydantic_graph` |
| Evals | `pydantic_evals` |
| Interfaces | CLI (`clai`), web/UI adapters, realtime |
| Observability | OpenTelemetry, Logfire integration, genai-prices |
| Packaging | uv workspace, hatchling, uv-dynamic-versioning |
| License | MIT |

## Key Features

### Typed Agents, Tools, and Outputs

The main `Agent` abstraction is built around typed dependencies, typed outputs, Pydantic-validated tool arguments, retry budgets, usage tracking, model settings, and structured message history. This is the main reason to use it: agent behavior becomes more like normal Python API design.

### Capability Middleware

Capabilities are reusable bundles of agent behavior. They can contribute instructions, tools, toolsets, native tools, lifecycle hooks, model settings, model selection, history processing, event stream processing, and deferred loading. This is the best architectural idea in the repo because it gives extensions a stable composition surface instead of encouraging ad hoc patching of the agent loop.

### Toolsets and Deferred Tools

Toolsets are first-class lifecycle objects with stable IDs, per-run/per-step preparation, approval wrappers, metadata, filtering, and composition. Deferred tools cover human approval, externally executed calls, and follow-up runs that resume with deferred results. That is a practical foundation for UI-mediated agents and background workflows.

### Provider-Adaptive Model and Tool Surfaces

The repo supports many providers through model/provider/profile modules: OpenAI, Anthropic, Google, Bedrock, Groq, Mistral, xAI, OpenRouter, Ollama, Hugging Face, and more. Provider-native tools and local fallbacks share capability APIs where possible, while MCP defaults local unless native exposure is explicitly requested.

### Graphs, Evals, and Durable Execution

`pydantic-graph` provides a typed graph/state-machine layer where edges are modeled with return types. `pydantic-evals` supplies dataset/case/evaluator/reporting primitives for stochastic functions and agents. Durable execution integrations let model/tool calls participate in workflow engines such as Temporal, DBOS, and Prefect.

### Operational and Security Posture

The repository has explicit SSRF protection for local web fetches, including protocol validation, DNS resolution before requests, private/metadata IP blocking, redirect checks, sensitive-header stripping, and bounded downloads. The local web UI has Host-header validation for DNS rebinding and JSON content-type checks for chat endpoints. CI uses broad test matrices, type checks, linting, coverage aggregation, pinned Actions, Dependabot, `zizmor`, `exclude-newer`, transitive security floors, and explicit dependency conflict modeling.

## Architecture

The project is organized as a uv workspace with separate packages for core agent behavior, graph execution, evals, CLI, and examples. The core package is deliberately modular: providers, models, profiles, capabilities, toolsets, realtime, durable execution, UI adapters, output handling, and instrumentation all live in distinct modules.

The agent loop is not just a hidden while loop. It sits on graph/run abstractions that expose streaming, stateful iteration, cancellation, run IDs, conversation IDs, message history, usage, and final results. That design makes long-running and UI-driven agents easier to inspect than a one-call wrapper around a model API.

The capability and toolset layers are the main extension boundary. A capability can wrap model requests, tool calls, output validation, stream events, model selection, and tool exposure. Toolsets can be combined, filtered, prepared, metadata-tagged, approval-gated, or loaded on demand.

## Comparison

| Aspect | Pydantic AI | LangChain / LangGraph | Inspect AI | OpenRouter Ori Eval |
|--------|-------------|-----------------------|------------|---------------------|
| Primary focus | Typed Python agent SDK | Broad app/agent orchestration ecosystem | Evaluation framework | Code-native eval runner |
| Type discipline | Central design point | Varies by component | Strong task/scorer contracts | TypeScript eval files |
| Agent loop | Agent, capability, toolset, graph primitives | Chains/graphs/state machines | Solver/task/scorer execution | Test-style eval execution |
| Evals | Built-in `pydantic-evals` package | LangSmith/LangChain eval surfaces | Core purpose | Core purpose |
| Best fit | Python teams that want typed agents | Teams already in LangChain ecosystem | Security/model eval work | Model comparison and CI evals |
| Caveat | Large and moving quickly | Broad ecosystem complexity | Not an app SDK | Not a general SDK |

## Self-Hosting Notes

Install the main package with uv or pip, then add only the extras needed for chosen providers and interfaces. The root package forwards many optional extras from `pydantic-ai-slim`, including provider SDKs, MCP, CLI, web, realtime, evals, Logfire, Temporal, DBOS, Prefect, and provider-specific realtime bundles.

For production use:

- Pin package versions and provider SDK extras.
- Write smoke tests for each provider/model/tool combination actually used.
- Enable observability, but configure content redaction for sensitive prompts and binary data.
- Use deferred tools or server-side authorization for sensitive actions; human approval is not a substitute for endpoint authentication.
- Prefer the outer web app with Host validation when using the local web UI.
- Treat broad MCP/tool exposure as an authority boundary, not just a convenience feature.

Local validation on this review machine:

```text
uv run pytest tests/test_function_schema.py tests/test_tool_search.py tests/test_ssrf.py -q
547 passed, 5 skipped

uv run python -m pip check
No broken requirements found.
```

---

**Attribution:** pydantic/pydantic-ai, MIT
