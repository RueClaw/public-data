# Continual Learning Bench (pgasawa/continual-learning-bench)

**Repo:** https://github.com/pgasawa/continual-learning-bench  
**License:** Apache-2.0; code and benchmark harness are reusable with attribution  
**Reviewed:** 2026-06-10  
**Stack:** Python 3.13, uv, Pydantic, LiteLLM/OpenAI/Anthropic APIs, Docker, pytest, Ruff, optional FastAPI/uvicorn, Mem0/Qdrant
**What it is:** A Python benchmark framework for evaluating whether AI agents improve across ordered, stateful task sequences instead of solving every task from scratch.

---

## Verdict

✅ **Deploy candidate for research evaluation, not a casual benchmark dependency.** CL-Bench has a real harness, explicit task/system contracts, stateless-baseline gain metrics, trace artifacts, and several substantial tasks. The caveat is operational weight: the repo is large, depends on Docker/provider keys/task data, has no visible GitHub Actions, and local verification was not run in this review because shallow and filtered clones stalled on the large repository payload.

---

## What It Is

Continual Learning Bench is an evaluation harness for systems that should adapt from prior interactions. The core abstraction is a sequence of task instances with stable `instance_id` and `instance_index` values, structured `Query` and `Response` objects, task-provided observations, and normalized `InstanceOutcome` rewards.

The benchmark compares full stateful rollouts against baseline runs where the same system is reset between canonical instances. That produces per-instance reward, cost, latency, and gain series. This is the most important design choice: it asks whether state helped, not just whether a strong model did well.

The repository includes built-in tasks for blind spectrum monitoring, codebase adaptation, cohort studies, database exploration, exploitable poker, and sales prediction. It also includes built-in systems for ICL, ICL with notepad, Claude Code, Codex, Mem0, ACE, and human baseline collection.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python 3.13, uv package management |
| Interfaces | Dataclasses plus Pydantic response schemas |
| Model calls | LiteLLM, OpenAI SDK, provider adapters |
| Agent CLIs | Dockerized Claude Code and Codex adapters |
| Memory baselines | ICL history, ICL-notepad, Mem0/Qdrant, ACE playbooks |
| Task execution | Docker workspaces for coding/shell tasks, SQLite/data files for analytical tasks |
| Artifacts | JSON/JSON.gz traces, run summaries, viewer artifacts |
| Web/human UI | Optional FastAPI/uvicorn |
| Validation | pytest test suite, Ruff config, pre-commit |

## Key Features

### Stateless-Baseline Gain

The harness runs baseline instances with reset semantics, then enriches rollout outcomes with `baseline_reward`, `gain`, `baseline_cost`, and `cost_increase`. Aggregate outputs include `mean_gain_by_index`, `cumulative_mean_gain_by_index`, cost, and latency series.

This is the benchmark's strongest reusable idea. It makes memory and online adaptation falsifiable.

### Typed Task/System Contract

`src/interface.py` defines `ContinualLearningTask`, `ContinualLearningSystem`, `Query`, `Observation`, `Response`, `TaskAgentBrief`, `InstanceOutcome`, and `TaskResult`. Tasks must expose stable instance identity and systems must implement `respond()` and `reset()`.

This contract is clean enough that new tasks and systems can be added without modifying the runner.

### Rich Task Set

The shipped tasks are not just toy prompts. The task READMEs describe latent structure, scoring, schedules, and expected learning modes:

- Blind Spectrum Monitoring rewards a persistent spectrum map across staged observability.
- Codebase Adaptation uses real PR-derived bugfix tasks and scores command efficiency.
- Cohort Studies forces cross-study population inference where no single study observes every target cohort.
- Database Exploration rewards schema/format reuse under drift.
- Exploitable Poker rewards opponent-model adaptation across hand sequences.
- Sales Prediction rewards institutional memory across fragmented annual data rooms.

### Agent Harnesses

The repo includes direct system adapters for ICL, ICL-notepad, Mem0, ACE, Claude Code, Codex, and human play. The Claude/Codex systems run inside Docker containers, parse CLI JSON/stream output, validate structured responses, record usage, and export memory/session artifacts.

### Trace And Viewer Artifacts

The trace layer records queries, responses, observations, timing, usage, memory snapshots, per-instance outcomes, and benchmark aggregates. This gives enough data to debug whether a system improved because of memory, costlier exploration, or incidental variance.

## Architecture

The architecture is organized around a few stable boundaries:

- `src/interface.py` owns public contracts and reward-first result objects.
- `src/runtime/runner.py` owns the task-system interaction loop.
- `src/runs/` owns baseline, repeated rollout, multiprocessing, and aggregate orchestration.
- `src/tasks/<task>/` owns task-specific state, prompts, variants, schedules, and scorers.
- `src/systems/<system>/` owns system-specific memory, provider, and CLI behavior.
- `src/trace_storage.py` and `src/trace_metrics.py` own trace persistence and gain/cost/latency enrichment.

This is a good split. Task authors do not need to understand every system adapter, and system authors do not need to touch task scoring.

## Comparison

| Aspect | CL-Bench | SWE-bench-style coding evals | Single-turn model benchmarks |
|--------|----------|------------------------------|------------------------------|
| Main question | Does state improve later performance? | Can a model fix isolated issues? | Can a model answer isolated prompts? |
| State model | System may retain memory across instances | Usually per-issue workspace state | Usually none |
| Baseline | Reset/stateless instance baseline | Often raw pass/fail | Raw score |
| Output | Reward, gain, cost, latency, traces | Pass/fail or score | Score |
| Best use | Researching memory/adaptation | Coding-agent capability | Model comparison |

## Self-Hosting Notes

Setup requires Python 3.13+, uv, Docker for containerized systems/tasks, and model provider keys for model-backed systems. The README quickstart is:

```bash
git clone https://github.com/pgasawa/continual-learning-bench
cd continual-learning-bench
uv sync --all-extras
source .venv/bin/activate
pre-commit install
clbench setup --all
clbench run exploitable_poker --schedule quick_test --system icl
```

The repository is large. GitHub reports roughly 250 MB of repository data, and it contains committed final result artifacts plus task data. In this review, both shallow and filtered clones stalled, so code inspection used GitHub metadata and raw file/API access instead of local test execution.

## Security And Maturity Notes

The repo is young but active: created 2026-04-30, release commit on 2026-05-04, paper added 2026-06-08, and about 145 stars / 18 forks at review time. GitHub reports 2 open issues and 3 PRs.

There is a real test suite visible in the tree, with 39 test files covering CLI, tasks, systems, trace storage, usage, registry, rollouts, and viewer compression. No `.github/` CI workflow was visible in the repository tree, so automated upstream validation was not confirmed.

Secret scanning via GitHub code search for obvious key/password strings returned no results. Provider keys are expected through environment variables such as `OPENAI_API_KEY` and `ANTHROPIC_API_KEY`.

The Claude and Codex adapters use bypass/permission-skipping CLI modes inside Docker containers. That is reasonable for benchmark automation but should be treated as a research sandbox, not as a general safety boundary.

---

**Attribution:** pgasawa/continual-learning-bench, Apache-2.0, https://github.com/pgasawa/continual-learning-bench
