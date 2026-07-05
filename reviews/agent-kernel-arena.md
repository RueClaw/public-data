# AgentKernelArena Review

Source: https://github.com/AMD-AGI/AgentKernelArena
Author: AMD-AGI
License: Apache-2.0
Reviewed: 2026-07-05
Commit reviewed: `ebc31a1b182585947997fae286e89d9d42826c34`
Release checked: `v0.1.0`

## Verdict

✅ Deploy candidate for AMD ROCm agent-evaluation labs.

AgentKernelArena is an end-to-end benchmark harness for comparing coding agents on GPU kernel optimization tasks. It runs agents such as Cursor Agent, Claude Code, Codex, and custom launchers against the same task corpus, then scores compile success, correctness, and GPU performance through a centralized evaluator.

This is strongest when treated as controlled lab infrastructure for ROCm/HIP/Triton work, not as a general-purpose agent leaderboard. It is young, hardware-specific, and intentionally powerful: the Docker runner uses privileged GPU access and the benchmark can run trusted task commands and agent CLIs with broad permissions.

## What It Is

AgentKernelArena provides a siloed benchmarking environment for LLM-powered coding agents that optimize GPU kernels. The repo includes:

- 284 task configs across HIP, Triton, Torch2HIP, instruction-to-Triton, and FlyDSL-style categories.
- A Docker-first ROCm workflow targeting MI300/MI350-class systems.
- Agent launchers for Cursor, Claude Code, Codex, and a task validator agent.
- Per-task workspace copies so each agent run gets an isolated task directory.
- Baseline-before-agent evaluation and centralized post-agent compile/correctness/performance measurement.
- Multi-GPU parallel execution through a shared descriptor queue.
- Held-out shape generation and evaluation for checking overfitting/generalization.
- Sphinx docs and a static visualization dashboard for run reports.

## Stack

- Python benchmark harness
- YAML task configs
- Docker ROCm/SGLang images
- HIP, Triton, PyTorch, FlyDSL task surfaces
- Agent CLI launchers for Cursor, Claude Code, Codex
- Sphinx documentation
- Static dashboard generator and HTTP helper
- GitHub Actions for perf-helper drift checks

## Strong Ideas

### Baseline Before The Agent

The runner measures baseline compile/correctness/performance before letting the agent touch a copied workspace. That gives the later optimized result a concrete local comparison point instead of relying on static leaderboard metadata.

### Centralized Evaluation

Agents are asked to edit code, but the framework owns scoring. The agent does not write the final task result; compile, correctness, performance parsing, speedup calculation, and `task_result.yaml` emission happen in the benchmark harness.

That separation is exactly what agent benchmarks need: agents produce artifacts, evaluators decide outcomes.

### Siloed Workspaces

Each task is copied into a run workspace under a timestamped run directory. That keeps task mutations localized and makes logs/artifacts easier to audit. The design is simple, but it prevents a lot of accidental cross-task contamination.

### Multi-GPU Queue

Parallel execution uses a shared `.parallel/` queue with `pending`, `running`, `done`, and `failed` descriptor directories. Workers claim work through atomic descriptor moves, each with a masked GPU and worker-local run scope.

This is a practical pattern for expensive hardware benchmarks: no central service is needed, and the artifact trail is inspectable.

### Held-Out Shape Evaluation

The `held_out/` tooling generates unseen input shapes, injects them into completed workspaces, and compares original versus optimized implementations again. For kernel optimization agents, this matters: an agent can overfit visible tests while breaking broader shape behavior.

The implementation is still text-injection-heavy, but the eval idea is good and worth borrowing.

### Task Validator Agent

The validator agent is a useful meta-benchmark step. It inspects task definitions for structure, reproducibility, and required files before the task becomes part of the corpus. That gives the benchmark a route to scale beyond hand-maintained tasks.

## Scoring Model

The score is transparent:

- Compile success contributes 20 points.
- Correctness contributes 100 points.
- Speedup contributes `speedup_ratio * 100`.
- Compile failure yields 0.

This is easy to explain and good for per-task comparison. It is not yet a full statistical leaderboard methodology, especially because performance timing methods differ across task categories.

The benchmark methodology docs are honest about that: cross-category speed comparisons need care, and consistency of measurement method is tracked.

## Safety And Operational Caveats

### Privileged Docker Is Expected

The Docker runner uses ROCm GPU devices, host networking, host IPC, privileged mode, `/dev/kfd`, `/dev/dri`, and `/dev/mem`. That is normal for some ROCm benchmarking setups, but it means this should run on a dedicated benchmark host, not a personal workstation with unrelated secrets.

### Agent Credentials Are Mounted

The runner can mount host agent config/auth directories for Codex, Claude, and Cursor into the container. The parallel-run path has a better isolation story, with worker-local homes and read-only/copy semantics, but credential handling is still a central trust boundary.

Prefer isolated benchmark machines, scoped API credentials, and the repo's agent-home isolation mode where possible.

### Task Configs Are Trusted Code

Task configs can specify shell commands for compile, correctness, performance, and setup. Some task setup paths also clone repositories and run post-clone install commands. This is appropriate for a benchmark corpus, but not safe for arbitrary untrusted task submissions.

### Agent Launchers Use Broad Powers

The bundled launchers intentionally invoke agents in permissive modes inside the benchmark environment. That is understandable for autonomous kernel optimization, but it raises the blast radius if the container or mounted credentials are not isolated.

### CI Is Thin

The repo has a GitHub Actions workflow for perf-helper drift checks, plus CODEOWNERS for sensitive files. I did not find a broad automated test, lint, typecheck, Docker smoke, or task-validation CI suite. For a benchmark that wants reproducibility, CI depth is a current maturity gap.

### Public Leaderboard Is Not There Yet

The README advertises a leaderboard as coming soon, and current table values are placeholders. Treat this as a runnable harness and corpus, not as a source of settled public agent rankings.

## Verification Performed

Local safe checks passed without ROCm hardware:

- `python3 -m compileall main.py src agents held_out visualization/backend`
- `python3 src/tools/sync_perf_helpers.py --check`
- `python3 visualization/backend/scripts/build_dashboard_data.py`
- Python task registry load, reporting 284 task configs

Full benchmark execution, Docker smoke, and GPU performance validation were not run because they require the target ROCm/Docker environment and logged-in agent CLIs.

## Relevance

AgentKernelArena is useful if you need to answer questions like:

- Does an agent improve HIP or Triton kernels beyond a baseline?
- Does adding an MCP server, skill, prompt, or tool help on a fixed GPU kernel task suite?
- Does an agent overfit visible shapes?
- How do multiple agent CLIs behave under identical task, GPU, and scoring conditions?
- Can expensive multi-GPU evals be run with inspectable artifacts instead of opaque service orchestration?

It is less useful if you want a plug-and-play generic SWE benchmark, CPU-only eval harness, or a mature public leaderboard.

## Borrowable Pattern

Extracted pattern:

- [Siloed Agent Benchmark Arena](../patterns/siloed-agent-benchmark-arena.md)

The core pattern is to give agents isolated task workspaces, let them mutate artifacts, keep scoring centralized, compare against a local baseline, and preserve logs/results for audit.

## Bottom Line

AgentKernelArena is one of the better public examples of a practical agent benchmark harness for GPU kernel work. It has the right instincts: isolate workspaces, centralize scoring, measure real compile/correctness/performance outcomes, support A/B testing, and evaluate held-out generalization.

The operational posture is the tradeoff. It is designed for high-power local lab execution with privileged ROCm Docker and mounted agent credentials. Use it in a dedicated benchmark environment, not as a casual desktop tool.
