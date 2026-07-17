# Tool Eval Bench (SeraphimSerapis/tool-eval-bench)

**Repo:** https://github.com/SeraphimSerapis/tool-eval-bench  
**License:** MIT. Safe to adapt with attribution.  
**Reviewed:** 2026-07-17  
**Stack:** Python 3.11+, OpenAI-compatible chat-completions adapters, deterministic scenario evaluators, Markdown/JSON reports, Docker, GitHub Actions  
**What it is:** A local benchmark for testing tool-calling quality across LLM serving stacks such as vLLM, SGLang, llama.cpp, LiteLLM, and other OpenAI-compatible endpoints.

---

## Verdict

✅ **Deploy candidate for local tool-calling evaluation.** This is a serious benchmark harness, not a thin prompt collection. It has a layered architecture, 69 deterministic core scenarios plus hard-mode cases, mock tools, multi-turn orchestration, safety gating, structured-output tests, plugin benchmarks, trace-complete reports, Docker packaging, and a strong CI/test posture. The caveat is scope: it measures tool-call behavior under synthetic deterministic scenarios, not full open-ended agent productivity.

---

## What It Is

Tool Eval Bench evaluates whether an LLM endpoint can choose tools, provide precise arguments, chain calls, recover from errors, refuse unsafe actions, preserve context, follow formatting rules, and produce structured outputs. It targets OpenAI-compatible `/v1/chat/completions` servers, so the same scenario registry can be pointed at local or routed serving stacks.

The benchmark is intentionally deterministic. Scenarios define tool schemas, prompts, expected behavior, mock tool handlers, evaluators, follow-up messages, optional tool-choice overrides, optional response-format requirements, difficulty, and checkpoint metadata. Results are scored as pass, partial, or fail, then aggregated into category and final scores. Category K safety failures trigger warnings and can cap the rating when safety falls below the configured threshold.

This makes it useful for comparing local serving stacks, model versions, parser settings, context-pressure behavior, and tool-call regressions before promoting an endpoint into real agent workflows.

## Key Features

### Deterministic Tool-Use Scenarios

The scenario registry covers tool selection, argument precision, multi-step chains, restraint/refusal, error recovery, localization, structured reasoning, instruction following, state/context handling, code-pattern tools, safety boundaries, large toolsets, autonomous planning, creative composition, structured output, and hard mode.

The useful design choice is that each scenario carries both the mock tool behavior and the evaluator. That keeps test evidence close to the intended behavior and makes failures inspectable without relying on a hidden LLM judge.

### Multi-Turn Orchestration

The runner includes a realistic tool-call loop: model response, tool-call parsing, mock tool execution, tool-result injection, follow-up turns, malformed JSON repair, noisy tool responses, optional error injection, parallel-tool-call controls, and context-pressure nonces to avoid prefix-cache bias.

That matters because many model endpoints pass single-turn "call this function" demos but degrade when a task requires state, recovery, or deciding not to call a tool.

### Safety and Rating Gates

Safety is not only another additive category. The methodology documents a Category K safety gate: when safety category performance is below 50%, the rating is capped even if other categories score well. Reports also preserve safety warnings and scenario traces.

That is the right bias for agent deployment. A tool-calling model that is fast and capable but bad at prompt-injection resistance, authorization boundaries, or hallucinated actions should not receive a clean deployability signal.

### Reports and Plugin Benchmarks

Runs can emit JSON and Markdown reports with category scores, scenario details, traces, throughput samples, context-pressure data, and environment/run context. Optional plugin benchmarks extend beyond tool calls into GSM8K, MMLU, IFEval, throughput, speculative decoding monitoring, and llama-benchy integration.

The included `SKILL.md` is also agent-friendly: it tells agents to use JSON output, read stderr progress JSONL, probe endpoints, and interpret exit codes instead of screen-scraping rich terminal output.

## Architecture

The codebase is split into clear layers:

```text
src/tool_eval_bench/
  domain/       scenario, model, tool, scoring primitives
  evals/        scenario registries and evaluators
  runner/       orchestration, judging, throughput, pressure sweeps
  adapters/     OpenAI-compatible endpoint adapter
  storage/      reports, history, persistence
  plugins/      accuracy/perf benchmark plugins
  cli/          user-facing command surfaces
  application/  service layer
```

The OpenAI-compatible adapter handles non-streaming and streaming chat completions, normalizes provider tool calls, measures timing, returns graceful 4xx scenario errors, and repairs common streamed tool-argument truncation. Reports are written under the caller's `./runs/` directory rather than inside the installed package, which is a small but thoughtful packaging detail.

## Verification

Reviewed commit `8d5c48ab88d5e5c15b3ae9ee090310d2e7f74545` from 2026-07-16. GitHub metadata at review time: 233 stars, 21 forks, 0 open issues, MIT license, created 2026-04-17, last pushed 2026-07-16.

Local verification:

```bash
python3 -m compileall -q src tests scripts
python3 -m venv .venv
.venv/bin/python -m pip install -e '.[dev]'
.venv/bin/python -m pytest tests --ignore=tests/test_llama_benchy.py --tb=short -q
```

Result: compile passed; 2107 tests passed, 1 skipped. `tests/test_llama_benchy.py` was excluded because it is integration-oriented and depends on external benchmark tooling.

CI is also substantial: Python 3.11/3.12/3.13 lint, format, mypy, pytest, coverage, module coverage, Docker build, optional perf tests, wheel smoke, and manual live-canary workflow.

## Caveats

Deterministic evaluators are inspectable and reproducible, but they are still approximations. The methodology is candid about fragile string matching, JSON strictness variance, and the absence of semantic similarity in default scoring. Optional LLM-judge support can improve diagnostics but weakens pure determinism if used as a scoring authority.

The benchmark does not replace live agent evaluation. It can tell you whether an endpoint handles specific tool-call behaviors under controlled conditions; it cannot prove that a model will be good at messy real-world repo work, browsing, product decisions, or long-running delegated tasks.

Live use requires an actual endpoint and API key or local server. Dataset-backed accuracy plugins may download from Hugging Face, though the security docs note `trust_remote_code=False` for the datasets path and a REST fallback.

## Best Uses

- Compare vLLM, SGLang, llama.cpp, LiteLLM, and hosted-compatible endpoints on tool-call quality.
- Regression-test local model upgrades, parser flags, tool-call templates, context windows, and serving-stack changes.
- Add a pre-promotion quality gate before exposing a model to OpenClaw/Codex-style agent workflows.
- Study scenario/evaluator design for domain-specific agent benchmark suites.

## Extracted Pattern

Extracted to `public-data/patterns/deterministic-tool-call-benchmark-harness.md`.

The reusable pattern is to package tool-call quality as versioned deterministic scenarios with mock tools, evaluator-local expected behavior, safety-gated scoring, trace-complete reports, and endpoint adapters that can compare many serving stacks without changing the test corpus.

---

**Attribution:** SeraphimSerapis/tool-eval-bench, MIT License
