# Agent Evals as Test Files

**Source:** OpenRouter Ori Eval  
**URL:** https://openrouter.ai/ori/eval  
**Release/source:** https://github.com/OpenRouterLabs/ori-releases  
**License:** Apache-2.0  
**Reviewed:** 2026-08-03

## Pattern

Represent agent and model evaluations as ordinary test files, then let a CLI provide the runtime, model credentials, result capture, reporting, and history.

The useful boundary is:

```text
eval author writes *.eval.ts
  -> imports a small eval SDK
  -> calls the real agent/runtime
  -> asserts on tools, completion, latency, cost, and judged answer quality

eval CLI owns:
  -> discovery
  -> runtime startup/teardown
  -> SDK injection
  -> credential resolution
  -> candidate model execution
  -> result JSONL/JUnit/Markdown reports
  -> run history and baseline comparison
```

This keeps the eval readable and commit-friendly while leaving the messy runtime wiring outside the test body.

## Why It Works

Agent behavior is not only output text. A good eval often needs to prove:

- the right tool was called;
- a dangerous tool was not called;
- the agent completed instead of stalling;
- the answer contained an exact required field;
- open-ended quality met a judge criterion;
- latency or cost stayed inside a practical limit.

A normal test-file shape makes those contracts visible in code review. A CLI-backed runtime makes them reproducible in CI and comparable across model runs.

## Implementation Notes

- Use a unique eval suffix such as `*.eval.ts` so discovery is explicit.
- Provide a dry-run mode that loads files, checks imports, and spends no model money.
- Reject non-portable imports before running paid calls.
- Capture per-run results in append-only JSONL so killed processes do not erase completed rows.
- Separate candidate-model cost from judge cost in reports.
- Treat missing cost, duration, or score as `unmeasured`, never as zero.
- Store run history beside the eval workspace so prompt/model iterations can compare against prior runs.
- Prefer scratch workspaces for one-off model selection, then let users move useful evals into the repo later.

## When To Use

Use this when a model-backed feature has user-visible behavior that can regress:

- support triage;
- tool-calling agents;
- research or retrieval agents;
- routing between cheap and strong models;
- provider or model migration;
- prompt changes that need behavioral evidence.

Do not use it as a replacement for deterministic unit tests. If no model or agent is involved, ordinary tests are cheaper and clearer.

---

**Attribution:** OpenRouter Ori Eval, Apache-2.0
