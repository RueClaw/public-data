# OpenTelemetry GenAI Semantic Conventions (open-telemetry/semantic-conventions-genai)

**Repo:** https://github.com/open-telemetry/semantic-conventions-genai  
**License:** Apache-2.0; permissive reuse with attribution  
**Reviewed:** 2026-08-29  
**Stack:** OpenTelemetry semantic-convention YAML, OTel Weaver, generated Markdown docs, Python reference scenarios, uv, GitHub Actions  
**What it is:** The OpenTelemetry GenAI semantic-conventions registry: development-stage spans, metrics, events, schemas, provider attributes, MCP conventions, and reference conformance scenarios for instrumenting generative AI clients, agents, tools, memory, retrieval, workflows, and model providers.

---

## Verdict

✅ **Adopt as the default GenAI telemetry vocabulary, with development-status caveats.** This is the most credible public shape for GenAI observability because it lives in the OpenTelemetry ecosystem, models both low-level inference and higher-level agent operations, and includes reference scenarios across major libraries. Do not treat every field as stable yet: the docs are explicitly Development, the schema URL is still `gen-ai-dev`, and the top-level README still has a `Schema URL TODO`.

---

## What It Is

`semantic-conventions-genai` extends the OpenTelemetry semantic conventions with a GenAI-specific registry. The repo defines canonical attribute names, span types, event types, metrics, JSON schemas for rich content payloads, provider-specific conventions, and MCP tracing guidance.

The scope is broad and practical. It covers inference, embeddings, retrieval, response fetching, memory operations, agent creation/invocation, tool execution, workflow invocation, planning, client/server latency, token usage, tool-call counts, evaluation-result events, and provider namespaces for OpenAI, Anthropic, AWS Bedrock, Azure, Google, Cohere, Groq, Mistral, DeepSeek, xAI, Perplexity, and more.

The repo also includes Python reference scenarios that exercise real client libraries against deterministic local mock servers, capture OpenTelemetry output, and reduce that output into committed per-library coverage reports. That reference layer is what makes the project more useful than a naming list.

## Stack

| Layer | Tech |
|-------|------|
| Registry model | YAML under `model/gen-ai`, `model/mcp`, `model/openai`, `model/aws-bedrock` |
| Generation | OTel Weaver `v0.25.1`, Jinja templates |
| Documentation | Generated and hand-written Markdown under `docs/gen-ai` and `docs/registry` |
| Schemas | JSON Schema files generated from Pydantic models |
| Reference harness | Python 3.12+, uv, pytest, ruff, mypy |
| Reference scenarios | 28 Python scenarios for providers and agent frameworks |
| CI | GitHub Actions for links, Weaver policies, generated-doc drift, lint/format, scenario matrix, status reports, CodeQL, Scorecard, zizmor |
| Release | Dev-channel GitHub Releases with resolved schema artifacts |

## Key Features

### Model and Agent Spans

The registry separates model/client spans from agent/framework spans. Model operations include inference, embeddings, retrieval, fetch-response, and memory. Agent operations include create-agent, invoke-agent over remote services, invoke-agent inside local frameworks, invoke-workflow, plan, and execute-tool.

That split matters because a single agent run is not just "one LLM call." It may plan, call several tools, retrieve context, use memory, invoke a workflow, and make multiple model calls. The conventions give each layer a low-cardinality place in the trace model.

### Token, Latency, and Tool Metrics

The metric set covers token usage, operation duration, time to first chunk/token, time per chunk/token, workflow duration, agent duration, inference-call counts, tool-call counts, and tool execution duration. The token guidance is especially useful: when both used and billable tokens exist, instrumentation should report billable tokens.

### Content Capture Is Opt-In

Potentially sensitive content fields such as `gen_ai.input.messages`, `gen_ai.output.messages`, `gen_ai.system_instructions`, tool definitions, tool-call arguments/results, retrieval documents, and memory records are marked opt-in or explicitly called out as sensitive. That is the right default for telemetry that can otherwise become prompt and user-data exfiltration by accident.

### MCP Semantic Conventions

The MCP section is one of the repo's strongest pieces. It treats MCP as JSON-RPC over multiple transports, recommends propagating W3C trace context through `params._meta`, distinguishes MCP spans from raw HTTP/RPC spans, and maps MCP tool calls onto GenAI `execute_tool` semantics when appropriate.

### Reference Conformance Matrix

The `reference/` tree tracks coverage for 28 libraries and frameworks including OpenAI, Anthropic, Google GenAI, Vertex AI, AWS Bedrock, Azure OpenAI, Azure AI Inference, LangChain, LlamaIndex, Pydantic AI, OpenAI Agents, AutoGen, CrewAI, DSPy, LiteLLM, Haystack, Cohere, Groq, Mistral, and Claude Agent SDK. The generated reports show which spans, events, metrics, and attributes are actually emitted.

## Architecture

The architecture is a source-model-to-generated-docs pipeline. YAML registry files define attributes, spans, metrics, and events. Weaver validates and renders those models into registry docs and generated snippets embedded in human-written docs. Pydantic models generate JSON schemas for richer content structures, while reference scenarios and committed `data.json` files feed coverage reports.

CI is unusually serious for a spec repo: model policy checks, generated-output drift checks, link checks, lint/format, scenario execution matrix, report regeneration checks, CodeQL, Scorecard, and zizmor. Actions are generally pinned by SHA and default permissions are tight.

The weak spots are maturity and local ergonomics. The conventions are Development, not stable. Full local policy validation needs Weaver or Docker/Podman. The Python reference package needs the dev extra installed before plain local pytest works cleanly. The top-level README also still says `Schema URL TODO`, despite `model/manifest.yaml` carrying `https://opentelemetry.io/schemas/gen-ai-dev/1.42.0-dev`.

## Comparison

| Aspect | This Repo | Core OpenTelemetry Semantic Conventions | Langfuse | Tracebase |
|--------|-----------|------------------------------------------|----------|-----------|
| Primary role | Standard vocabulary for GenAI telemetry | Broad service/runtime telemetry vocabulary | Product observability platform | Local agent trace capture |
| Output | YAML registry, docs, schemas, reference reports | Stable and experimental OTel conventions | Hosted/self-hosted app | Local trace store/dashboard |
| GenAI agent coverage | First-class agent/tool/workflow/memory spans | Limited without this extension | App-level traces/evals/prompts | Session/debug traces |
| Adoption caveat | Development-stage schema | More mature base conventions | Platform-specific model | Local tool, not a standard |

Use this repo as the naming and trace-shape source of truth, then choose an observability backend separately.

## Self-Hosting Notes

There is no service to host. To work locally:

```bash
git clone https://github.com/open-telemetry/semantic-conventions-genai.git
cd semantic-conventions-genai
make generate-all
make check-policies
```

`make check-policies` needs either local Weaver or Docker/Podman. Reference tests are under `reference/`:

```bash
cd reference
uv sync --locked --extra dev
uv run pytest
```

Validation during review:

```bash
uv sync --locked --extra dev && uv run pytest
uv tool run --from ruff ruff check src scenarios
uv tool run --from ruff ruff format --check src scenarios
PYTHONPATH=src uv run update-reports
PYTHONPATH=src uv run run-scenario --print-ci-matrix
```

These passed locally. `make check-policies` could not run because neither `weaver` nor Docker/Podman was installed on the review machine.

---

**Attribution:** open-telemetry/semantic-conventions-genai, Apache-2.0
