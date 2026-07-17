# Deterministic Tool-Call Benchmark Harness

**Source:** SeraphimSerapis/tool-eval-bench  
**Repo:** https://github.com/SeraphimSerapis/tool-eval-bench  
**License:** MIT  
**Reviewed:** 2026-07-17  

## Pattern

Evaluate model/tool-serving quality with deterministic scenario definitions that carry their own tool schemas, mock tool behavior, expected behavior, and scoring logic. Keep the serving backend swappable through a small adapter, but keep the test corpus stable enough to compare models, parser settings, and runtime changes over time.

## Core Structure

Each scenario should define:

- prompt and follow-up turns
- available tool schemas
- mock tool handlers
- expected behavior
- evaluator function
- tool-choice and response-format overrides when relevant
- difficulty/category metadata
- trace/report metadata

The runner should execute a realistic loop:

1. Send the prompt and tool definitions to the endpoint.
2. Normalize provider-specific tool-call output.
3. Execute mock tool calls locally.
4. Inject tool results into the conversation.
5. Continue follow-up turns when the scenario requires state.
6. Score pass, partial, or fail using deterministic evaluators.
7. Preserve the full trace for audit.

## Design Rules

Keep evaluators close to scenarios. A reader should be able to inspect a failed case and understand exactly what behavior was expected.

Separate benchmark logic from serving adapters. The same scenario corpus should run against vLLM, SGLang, llama.cpp, LiteLLM, hosted OpenAI-compatible APIs, or future local endpoints.

Treat safety as a gate, not just another category. If prompt injection, authorization, hallucinated action, or unsafe-tool behavior falls below the floor, cap the deployment rating even when the aggregate score is high.

Prefer deterministic mock tools over live services for the core suite. Live datasets and throughput plugins are useful, but the promotion gate should not depend on network flakiness or changing third-party data.

Write trace-complete reports. A score without the conversation, tool calls, tool responses, and evaluator summary is hard to debug and easy to overtrust.

## Why It Works

Tool-call demos are often too shallow. A model can call one function correctly and still fail multi-turn chaining, error recovery, refusal, large toolsets, structured output, localization, or context pressure.

A deterministic harness makes these failures reproducible. It also gives serving-stack changes a clear regression target: if parser flags, templates, speculative decoding, context settings, or model revisions change behavior, the scenario report shows where.

## Caveats

Determinism is not the same thing as truth. String matching and strict JSON checks can be brittle, and synthetic scenarios cannot prove full agent competence. Use this as a pre-deployment gate and regression suite, then pair it with live task evaluation.

LLM-as-judge can help explain failures, but it should not silently replace deterministic scoring unless the benchmark explicitly marks that scoring mode.

---

**Attribution:** Based on SeraphimSerapis/tool-eval-bench, MIT License.
