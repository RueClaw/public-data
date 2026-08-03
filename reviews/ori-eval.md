# Ori Eval (OpenRouter / OpenRouterLabs/ori-releases)

**Source:** https://openrouter.ai/ori/eval  
**Release repo:** https://github.com/OpenRouterLabs/ori-releases  
**License:** Apache-2.0. The release repo includes Apache-2.0 binaries, installer, checksums, and `ori-source.tar.gz`; bundled third-party components keep their own licenses.  
**Reviewed:** 2026-08-03  
**Stack:** TypeScript, Bun, Effect, OpenRouter, OpenAI-compatible model routing, `bun test`, generated `ori/eval` SDK, local CLI/runtime daemon  
**What it is:** Ori Eval is an OpenRouter CLI workflow for model and agent evaluation. It helps an agent create `*.eval.ts` files, runs them with `ori eval`, asserts on tool calls and completion behavior, grades open-ended answers with an LLM judge, and compares candidate models on cost, latency, and quality.

---

## Verdict

✅ **Deploy candidate for controlled model-selection and agent-regression pilots.** Ori Eval has a clean contract: evals are TypeScript test files, discovered by the CLI, run by Bun, and reported with candidate/judge spend split out instead of hidden. The caveats are real but manageable: it runs paid model calls, stores/uses OpenRouter credentials, emits opt-out telemetry, and is still young enough that local validation found one macOS path-assumption test failure.

---

## What It Is

Ori Eval attacks a painful gap in AI app development: people often choose models from vibes, leaderboards, or one-off prompts instead of running the exact agent behavior they care about. The product page describes an eval tool that runs the user's agent and model on prompts, checks which tools were called, and grades answers with an LLM judge so regressions and model tradeoffs show up before shipping.

The workflow has two layers. The human-facing page explains the basic usage: install Ori, sign in with `ori login`, write a `*.eval.ts` file with `setupAgent`, call `agent.run(prompt)`, assert with helpers such as `run.tool("x").toBeCalled()`, `run.toComplete()`, and `run.toMention("...")`, then run `ori eval`. The agent-facing `spawn-ori-eval` and built-in `create-eval` skills go further: they guide a coding agent through finding model call sites, collecting prompts/data, choosing criteria, selecting candidates, running comparisons, and reporting the result.

Unlike a pure landing page, the release has inspectable source. `OpenRouterLabs/ori-releases` publishes binaries plus `ori-source.tar.gz`; the source archive is a Bun/TypeScript monorepo with CLI code, an eval command, SDK injection, scratch workspaces, credential resolution, telemetry, docs, and a large test tree.

## Stack

| Layer | Tech |
|-------|------|
| CLI/runtime | TypeScript, Bun, Effect |
| Agent runtime | Local Ori runtime/daemon, OpenRouter-backed model calls |
| Eval files | `*.eval.ts`, `bun test`, `ori/eval`, `ori/test` |
| Assertions | Tool-call assertions, completion assertions, literal mention checks, judge-backed scoring |
| Reporting | Human output, JSON envelopes, JUnit, Markdown reports, `.ori/eval/history.jsonl` baselines |
| Model/catalog layer | OpenRouter model/provider metadata, candidate selection, provider variants |
| Auth | `OPENROUTER_API_KEY`, `ori login`, workspace/global credential files |
| Distribution | `curl` installer, GitHub release assets, SHA256SUMS, platform binaries, source tarball |

## Key Features

### Evals as Normal Test Files

The central design choice is good: an eval is a `*.eval.ts` file that imports `setupAgent` from `ori/eval` and runs under `bun test`. The CLI is not inventing a separate test runner. It discovers eval files, injects the bundled SDK when needed, starts a temporary runtime, passes result-file paths through env vars, and lets Bun own the test lifecycle.

### Tool and Answer Assertions

The skill docs push authors toward assertions that match agent behavior:

- `run.tool("search").toBeCalled()`
- `run.tool("delete_file").toNotBeCalled()`
- `run.toComplete()`
- `run.toFinishWithin(...)`
- `run.toCostAtMost(...)`
- judge criteria for semantic answer quality

That is the right level. Agent evals should test whether the agent did the job and used the right tools, not only whether a model emitted a pleasant paragraph.

### Cost and Judge Separation

The result renderer explicitly separates candidate model runs from judge runs. That matters because LLM-as-judge can dominate spend. Ori's code also treats missing cost/duration as unmeasured rather than zero, which prevents false "free" or "instant" readings when a runtime did not report usage.

### Scratch Workspaces

`ori eval scratch` creates a temporary self-contained workspace with local SDK wiring, starter eval template, `data/`, `features/`, and a local lockfile. That is a strong default for exploratory model selection: measure first, then move the eval into the repo only if the result is worth keeping.

### Agent-Guided Eval Creation

The `create-eval` skill is unusually opinionated. It requires the agent to collect workspace context once, ask for real traffic, present candidates before spending model money, run the comparison only after approval, diagnose prompt-versus-model failures, and finish with cost/timing. That process discipline is more valuable than a bare SDK.

## Architecture

The eval command has a clean split:

```text
ori eval
  -> discover *.eval.ts files
  -> reject non-portable imports
  -> materialize/inject ori/eval SDK when needed
  -> resolve OpenRouter credential
  -> start temporary runtime provider
  -> spawn bun test
       -> SDK appends run/result JSONL
       -> Bun writes JUnit
  -> read JSONL/JUnit after child exits
  -> write report/history/baseline comparison
  -> emit telemetry
```

Two implementation choices stand out:

- Result rows are JSONL rather than one JSON document, so a killed child can still leave completed rows readable.
- `--dry-run` loads eval files without running test bodies or requiring credentials, which catches syntax/import problems before paid model calls.

## Comparison

| Aspect | Ori Eval | Tool Eval Bench | LangSmith Evals | Ad Hoc Prompt Runs |
|--------|----------|-----------------|-----------------|--------------------|
| Primary job | Agent/model comparison in a repo | Deterministic tool-calling benchmark suite | Hosted traces/datasets/evals | Manual experimentation |
| Eval shape | `*.eval.ts` plus CLI runtime | Python benchmark scenarios | Hosted/project-specific evals | Unstructured prompts |
| Model breadth | OpenRouter catalog | OpenAI-compatible endpoints | Provider integrations | Whatever the user tries |
| Strength | Agent-guided workflow, cost reporting, CI-friendly file shape | Deterministic benchmark coverage | Hosted observability and datasets | Fast to start |
| Caveat | Young CLI, paid calls, OpenRouter dependency | Not tailored to one app by default | SaaS dependency | Not reproducible |

Ori Eval is not a general observability platform. It is closer to a portable eval authoring and execution layer for deciding which model should handle a concrete behavior.

## Self-Hosting Notes

Install is via:

```bash
curl -fsSL https://openrouter.ai/labs/ori/install.sh | bash
```

The installer downloads platform binaries from `OpenRouterLabs/ori-releases`, verifies SHA256SUMS, installs to `~/.local/bin` by default, and may try to link `/usr/local/bin/ori`. It emits installer telemetry unless `ORI_TELEMETRY=0` or `ORI_TELEMETRY=false` is set.

Operational cautions:

- `ori eval` spends real OpenRouter credits unless using discovery or dry-run modes.
- Interactive use stores credentials through `ori login`; CI should use `OPENROUTER_API_KEY` from secrets.
- The CLI emits anonymous usage telemetry by default and creates `~/.ori/telemetry.json`; set `ORI_TELEMETRY=0` for sensitive environments.
- The eval agent reads project prompts, data, and tool surfaces. Do not point it at confidential production data unless that data is allowed to leave through the selected models/judges.
- Keep generated scratch evals out of the repo until the result is worth preserving.

## Verification

Reviewed OpenRouter's public page, `spawn-ori-eval` skill, installer script, release metadata, Apache LICENSE/NOTICE, SHA256SUMS, and the `ori-source.tar.gz` source archive for version `0.4.0+063b32e`.

Local checks:

- `bun install --frozen-lockfile`: passed.
- Focused eval/telemetry tests: 294 passed, 1 failed across 35 files. The failure was `ori eval scratch > creates a persistent self-contained workspace`, where the test expected the scratch path to start with `/tmp/` but this macOS environment returned `/private/tmp/...`. That looks like a portability assertion issue, not a core eval-runtime failure.

---

**Attribution:** OpenRouter / OpenRouterLabs/ori-releases, Apache-2.0, https://openrouter.ai/ori/eval
