# Inspect AI (UKGovernmentBEIS/inspect_ai)

**Repo:** https://github.com/UKGovernmentBEIS/inspect_ai
**Docs:** https://inspect.aisi.org.uk/
**License:** MIT. Permissive reuse with attribution; bundled dependencies and optional provider SDKs keep their own licenses.
**Reviewed:** 2026-08-03
**Stack:** Python 3.10+, Click, Pydantic, FastAPI/Uvicorn, Textual/Rich, Quarto docs, React/TypeScript embedded viewer, Docker/Kubernetes/Modal/Proxmox/Vagrant sandbox extensions, many model-provider adapters
**What it is:** Inspect AI is the UK AI Security Institute's open-source framework for large language model evaluations. It provides composable tasks, datasets, solvers, agents, tools, scorers, sandboxing, log analysis, live run control, and a catalog of 200+ ready-to-run benchmark implementations.

---

## Verdict

✅ **Deploy candidate for serious model and agent evaluation work.** Inspect is one of the strongest open eval frameworks available: broad model support, agent/tool/sandbox primitives, good docs, a real log viewer, live control for long runs, approval policies, and active maintenance from an AI safety institute. The main caveat is operational complexity: meaningful runs can spend provider money, execute model-written code in sandboxes, produce sensitive transcripts, and require deliberate log/credential handling.

---

## What It Is

Inspect turns an evaluation into a Python `Task` made from three core pieces: a dataset, a solver or agent, and one or more scorers. Simple benchmarks can be a `generate()` call plus a text or model-graded scorer. Harder evaluations can run tool-using agents through bash, Python, web, browser, computer, MCP, and custom tools inside Docker or other sandbox backends.

The framework is not just an SDK. It ships an `inspect` CLI, an interactive log viewer, a VS Code extension, dataframe/log APIs, transcript scanners, model/provider adapters, and a growing benchmark catalog. The documentation is also unusually agent-friendly: the site publishes `llms.txt`, `llms-guide.txt`, and `llms-full.txt`, and every docs page has a Markdown form.

The most distinctive recent feature is the control channel. Every running eval can expose a local Unix-socket endpoint, and `inspect ctl` can list tasks/samples, read live transcript events, detect stalls, flush logs, retune config, pause/resume, cancel samples, and run detached evals with a JSON launch handoff.

## Stack

| Layer | Tech |
|-------|------|
| Core framework | Python package `inspect_ai`, typed APIs, Pydantic models |
| CLI | Click command tree under `inspect` |
| Models | OpenAI, Anthropic, Google, OpenRouter, Groq, Mistral, xAI/Grok, Together, Fireworks, Hugging Face, vLLM, SGLang, Ollama, llama.cpp, Bedrock, Azure, Cloudflare, and OpenAI-compatible APIs |
| Eval primitives | `Task`, dataset loaders, solvers, agents, scorers, metrics, reducers |
| Agent/tooling | ReAct, deep agent, custom/multi-agent APIs, agent bridge, bash/Python/browser/computer/web/MCP tools |
| Sandboxing | Docker plus extension APIs for Kubernetes, Modal, Proxmox, Vagrant, and custom backends |
| Observability | Eval logs, transcript events, dataframe extraction, scanners, Inspect View, tracing |
| Live control | Local Unix-domain socket, `inspect ctl`, JSON launch handoff, detached eval support |
| Docs/UI | Quarto docs, VS Code extension, embedded React/TypeScript viewer |
| Testing posture | 626 Python test files observed; focused local run passed 29 tests / 18 skipped |

## Key Features

### Composable Evaluation Tasks

The `Task(dataset, solver, scorer)` shape is clean and reusable. It keeps benchmark input, model behavior, and scoring logic separate, while still letting advanced tasks override runtime settings such as sandbox, approval, token/message/time/cost limits, epochs, retries, and model roles.

### Agent and Tool Evaluation

Inspect treats agentic evaluation as a first-class use case rather than a bolt-on. Agents can act as solvers, standalone workflow pieces, tools, or participants in multi-agent handoffs. Tool calls can run through built-ins, custom Python functions, MCP servers, and external agent bridges.

### Sandboxing and Approval

The security model is practical for evals where models execute code or drive browsers. Sandboxes isolate tool execution, while approval policies can route tool calls through human, automatic, or custom approvers with matching on tool names and arguments.

### Live Control Channel

Long evals fail in boring ways: stuck samples, rate limits, bad retries, half-written logs, and foreground terminals that die. Inspect's `inspect ctl` surface addresses that directly with local-only live state, resumable transcript/event reads, pause/resume, cancellation, config retuning, and detached run handoff.

### Logs That Support Analysis

Inspect logs are not just final scores. The framework records transcripts, model calls, tool events, errors, scores, and runtime metadata, then exposes them through the viewer, dataframe APIs, scanners, and JSON/CLI surfaces.

## Architecture

The useful boundary is:

```text
task author writes:
  dataset + solver/agent + scorer + limits/sandbox/approval

inspect runtime owns:
  model/provider resolution
  concurrency and retry behavior
  sandbox lifecycle
  transcript/event logging
  scoring and reducers
  live control socket
  log viewer and dataframe analysis
```

That split is why Inspect scales from a small QA benchmark to a long-running coding-agent eval. The task remains inspectable code, while the framework owns execution plumbing.

The local control server is deliberately scoped: it binds under the current user's Inspect data directory, is not network reachable, and uses peer/user checks rather than exposing a remote API by default. That is the right default for eval observability.

## Comparison

| Aspect | Inspect AI | Ori Eval | tool-eval-bench |
|--------|------------|----------|-----------------|
| Primary target | General model, tool, and agent eval framework | OpenRouter model/agent selection workflow | Deterministic tool-calling benchmark harness |
| Main language | Python | TypeScript/Bun | Python |
| Best feature | Full eval runtime with logs, sandboxes, agents, and live control | Evals as normal `*.eval.ts` test files | Stable mock-tool scenarios and trace-complete reports |
| Operational weight | Medium to high | Low to medium | Low |
| Best fit | Serious eval suites and long-running agent benchmarks | App-specific model comparisons | Endpoint/tool-call regression gates |

Inspect is the broadest and most mature of the three. Ori Eval is lighter for application teams already using OpenRouter, while tool-eval-bench is more focused and deterministic for tool-call serving quality.

## Self-Hosting Notes

Install from PyPI:

```bash
pip install inspect-ai
```

A useful first run looks like:

```bash
inspect eval simpleqa.py --model openai/gpt-4o
inspect view
```

For long runs, use the documented detached/control workflow instead of leaving an eval tied to a terminal:

```bash
inspect eval task.py --detach
inspect ctl task list --json
inspect ctl sample errors
```

Use dedicated provider keys, set cost/token/time limits, and treat eval logs as sensitive artifacts when prompts, traces, tool outputs, or model reasoning may contain private data.

## Validation Notes

Local source checkout built successfully with `uv`. A focused validation run passed:

```text
29 passed, 18 skipped
```

The first broader command, `uv run pytest tests/test_task_list -q`, failed during collection because two task-list fixture files share the same module basename (`epsilon.py`) in different hidden directories. That looks like a pytest collection-target hazard rather than evidence that the framework is broken, but it is a real local test gotcha.

---

**Attribution:** UK AI Security Institute / UKGovernmentBEIS/inspect_ai, MIT
