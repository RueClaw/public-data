# WANDR (perplexityai/wandr)

**Repo:** https://github.com/perplexityai/wandr  
**License:** Apache-2.0; permissive reuse with attribution and patent grant  
**Reviewed:** 2026-07-28  
**Stack:** Python 3.12, Harbor, Docker/E2B, uv, OpenAI/Anthropic/Perplexity/Exa/Parallel/Gemini adapters  
**What it is:** A benchmark and Harbor task package for wide-and-deep research agents: high-volume discovery, enrichment, entity disambiguation, evidence extraction, and answer synthesis.

---

## Verdict

✅ **Deploy candidate for controlled research-agent evaluation.** WANDR is not a general research assistant; it is a serious benchmark corpus plus runner/evaluator plumbing for comparing remote research endpoints under file-output contracts. The caveat is cost and authority: full runs fan out across 501 tasks and six providers, use public-network task environments, and have no built-in spending cap.

---

## What It Is

WANDR packages a large set of research tasks where an agent must produce JSONL rows backed by fetchable URLs and human-usable excerpts. The scoring pipeline then fetches submitted pages, triages source usability, canonicalizes entity names, deduplicates rows, and judges whether the evidence supports the answer fields.

The repository is split cleanly into source task definitions under `reference/wandr_tasks/`, a deterministic WANDR-to-Harbor adapter, generated Harbor tasks under `datasets/wandr/`, and `Relay`, a generic Harbor agent that adapts remote providers into a common file-output contract.

This is most useful when the evaluation target is "can this agent do large, cited web research without collapsing under entity ambiguity and evidence fidelity?" It is less useful for ordinary tool-calling, browser-control, coding, or conversational benchmarks.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python 3.12, uv workspace |
| Benchmark runner | Harbor 0.18.0 |
| Task environments | Docker locally, optional E2B |
| Solver adapter | Relay Harbor agent |
| Providers | OpenAI, Anthropic, Perplexity, Exa, Parallel, Gemini |
| Evaluator | WANDR pipeline: fetch, triage, canon, dedup, judge |
| Data | 501 generated Harbor task packages |
| CI | Config validation, Ruff lint/format, adapter consistency, Dockerfile check |

## Key Features

### File-Output Benchmark Contract

Every generated task declares literal `metadata.required_file_paths` in `task.toml`. Relay reads that contract, instructs the remote endpoint to produce those files, validates paths, rejects empty required outputs, and materializes them into the Harbor workspace before verification starts.

That is the best architectural move in the repo: the benchmark does not depend on conversational goodwill. A task is complete only when the required files exist.

### Provider-Neutral Relay

Relay normalizes several incompatible delivery modes: OpenAI sandbox files, Anthropic sandbox files, Perplexity shared files, stdout/file fences, and output-schema style APIs. It records provider-neutral events, trajectories, status, final messages, produced files, token usage, and cost when available.

The delivery channel is explicit and authoritative; Relay does not silently switch modes when a provider's preferred file transport fails.

### Evidence-First Scoring

The smoke task shows the benchmark's bias clearly: every row needs a fetchable URL, excerpts must be page-main-text evidence, and entity identifiers must be consistent. The evaluator then fetches, triages, canonicalizes, deduplicates, and judges rather than trusting the submitted JSONL shape alone.

This makes WANDR closer to a provenance benchmark than a search-result-count benchmark.

### Generated Task Packaging

The adapter vendors each task's source and evaluator runtime into `datasets/wandr/<task>/`, so individual tasks can be packaged and verified independently. Consistency tooling checks that generated tasks match source task configs, adapter templates, vendored evaluator files, required output paths, and dataset digests.

## Architecture

The repo keeps source-of-truth boundaries explicit:

- `reference/wandr_tasks/` owns editable task configs, schemas, prompts, and artifacts.
- `adapters/wandr/` renders those sources into Harbor task packages.
- `datasets/wandr/` is generated output and should not be hand-edited.
- `agents/relay/` is generic provider-to-Harbor glue, not WANDR-specific benchmark semantics.

The evaluator runtime uses a staged async pipeline: submission parsing, URL safety/DNS checks, Perplexity-backed page fetch, LLM triage, canonicalization, fuzzy/LLM deduplication, LLM judging, metrics, and HTML reports. URL validation rejects credentials, non-HTTP schemes, control characters, and non-public resolved addresses before verifier-side network access.

## Comparison

| Aspect | WANDR | Tool Eval Bench | Agent Kernel Arena | AutoResearchClaw |
|--------|-------|-----------------|--------------------|------------------|
| Target | Wide/deep web research | Tool-call correctness | GPU kernel optimization agents | Research-paper workflow agents |
| Scoring | Fetch/triage/canon/dedup/judge | Deterministic scenario evaluators | Compile/correctness/performance | Pipeline gates and tests |
| Output contract | Required JSONL files | Tool traces/results | Code artifacts | Research artifacts |
| Runtime cost | Potentially very high | Low/moderate | Hardware-specific | Moderate/high |
| Best use | Compare deep research endpoints | Promote tool-serving models | Measure coding agents on kernels | Study controlled research workflows |

## Self-Hosting Notes

Local setup needs Python 3.12, uv, Docker, and provider keys. `./scripts/wandr check` passed locally on 2026-07-28: config validation, Ruff lint, format check, and adapter consistency all passed.

The cheapest end-to-end run is `./scripts/wandr smoke-local`, but even smoke uses paid OpenAI and Perplexity calls. Full `configs/wandr.yaml` runs 24 concurrent trials across six providers and excludes only the smoke task, so operators should set provider-side budgets before running it.

Security posture is reasonable for a benchmark but not a sandbox product. Agent and verifier environments have public network access, provider credentials are forwarded through config, and full runs can make extensive web and LLM calls. Run it in a dedicated benchmark workspace.

---

**Attribution:** perplexityai/wandr, Apache-2.0
