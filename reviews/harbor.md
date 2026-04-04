# harbor-framework/harbor — Review

**Repo:** https://github.com/harbor-framework/harbor  
**Author:** Alex Shaw / Harbor Framework Team  
**Origin:** From the creators of [Terminal-Bench](https://www.tbench.ai)  
**License:** Apache 2.0 ✅  
**Stack:** Python 3.12+ / Pydantic v2 / Typer CLI / Docker / LiteLLM / FastAPI (viewer)  
**Version:** 0.3.0 (active development)  
**Adapters:** 55 benchmarks  
**Reviewed:** 2026-04-04  
**Rating:** ⭐⭐⭐⭐⭐ — The canonical open-source agent evaluation framework. Essential infrastructure.

---

## What It Is

Harbor is an agent evaluation framework that runs arbitrary coding agents (Claude Code, Codex, OpenHands, Aider, Gemini CLI, Hermes, OpenCode, Cursor CLI, Cline, QwenCoder, etc.) against benchmark tasks in sandboxed container environments. You get a single CLI that understands both the agents *and* the benchmarks and handles everything in between.

Three primary use cases:
1. **Evaluation** — benchmark any agent against any supported dataset
2. **Custom benchmarks** — build and share your own task suites
3. **RL rollout generation** — produce training data for RL optimization

Cloud execution providers: Docker (local), Daytona, Modal, E2B, Runloop, GKE.

This is the official harness for Terminal-Bench 2.0 and the backend that autoagent (reviewed yesterday) runs against.

---

## Architecture

### The Three Abstractions

**Task** — a directory with:
- `task.toml` — config (timeouts, resources, metadata, environment spec)
- `instruction.md` — the natural language prompt the agent receives
- `environment/` — Dockerfile or environment definition
- `tests/` — verification scripts (`test.sh` writes reward 0.0–1.0 to `/logs/verifier/reward.txt`)
- `solution/` — optional reference solution

**Agent** (`BaseAgent` ABC) — implements four methods:
- `name()` → static string identifier
- `version()` → version string
- `setup(environment)` → pre-run setup
- `run(instruction, environment, context)` → execute the task

**Environment** (`BaseEnvironment` ABC) — the sandbox. Methods: `start()`, `stop()`, `exec(command, timeout_sec)`, `upload_file()`, `download_file()`. Backends are pluggable.

The agent runs host-side; `exec()` proxies commands into the container. This is the same architecture autoagent uses (and explicitly said so in its README, citing Harbor).

### Trial → Job Hierarchy

- **Trial**: single execution of one agent on one task
- **Job**: collection of trials (multiple agents × tasks × attempts)

Jobs support concurrency (`-n 100`), sweeps (parameter search), and pass@k metrics.

### ATIF — Agent Trajectory Interchange Format

Harbor defines and owns ATIF, the trajectory serialization format we saw in autoagent. Full schema lives in `src/harbor/models/trajectories/`. A trajectory has:
- `schema_version` (currently ATIF-v1.6)
- `session_id`
- `agent` metadata (name, version, model)
- `steps` array (each step: source, message, tool_calls, observations, reasoning_content, model_name)
- `final_metrics` (token counts, cost, duration, num_turns)

ATIF is the standardized output format for agent benchmarking. Agents signal support via `SUPPORTS_ATIF = True` class variable.

---

## Benchmark Coverage (55 Adapters)

Selected highlights:

| Domain | Benchmarks |
|--------|-----------|
| SWE (code repair) | SWEBench, SWEBench-Pro, SWEBench-Multilingual, SWESmith, SWTBench, SWELancer, MultiSWEBench |
| Code generation | Aider Polyglot, LiveCodeBench, HumanEvalFix, EvoEval, DevEval, AutoCodeBench |
| Terminal/shell | Terminal-Bench 2.0 (via `--dataset terminal-bench@2.0`) |
| Algorithms | USACO, AlgoTune, CompileBench, CrustBench (Rust) |
| Reasoning | GPQA-Diamond, AIME, ReasoningGym, IneqMath |
| Tools/Function calling | BFCL, SpreadsHeetBench, Spider2-dbt |
| Safety | StrongReject |
| ML/Research | MLGym-Bench, ReplicationBench, CodePDE |
| Finance | FinanceAgent, Pixiu, DABStep, DACode |
| Medical | MedAgentBench |
| Legal | LawBench |
| Science | BixBench, LabBench, QCircuitBench |
| Multimodal | MMAU, MMMLU |

Each adapter converts the source dataset into Harbor's task format. The `run_adapter.py` CLI in each adapter directory generates Harbor-compatible tasks from the raw benchmark data. Adapters also ship with `parity_experiment.json` — a validation experiment proving the adapter produces results consistent with the original benchmark's leaderboard.

---

## Built-in Agents

15 production agents, all implementing `BaseAgent`:

| Agent name | CLI flag | Notes |
|-----------|---------|-------|
| Claude Code | `claude-code` | Full Claude SDK, thinking support |
| Codex CLI | `codex` | OpenAI Codex CLI |
| OpenHands | `openhands`, `openhands-sdk` | Both direct and SDK modes |
| Aider | `aider` | Polyglot benchmark optimized |
| Gemini CLI | `gemini-cli` | Google's coding agent |
| Goose | `goose` | Block's agent |
| Hermes | `hermes` | ACP-backed durable threads |
| OpenCode | `opencode` | OpenCode agent |
| QwenCoder | `qwen-coder` | Alibaba's coding model |
| Cursor CLI | `cursor-cli` | Cursor's coding agent |
| Cline CLI | `cline-cli` | Cline's coding agent |
| Kimi CLI | `kimi-cli` | Moonshot's agent |
| MiniSWEAgent | `mini-swe-agent` | Lightweight SWE agent |
| SWEAgent | `swe-agent` | Princeton SWE-Agent |
| Terminus | `terminus`, `terminus-2` | Harbor's internal agent |

Plus `oracle` (always returns the reference solution, for testing verifier correctness) and `nop` (does nothing, for environment testing).

Agent installation uses Jinja2 templates (`install-{agent}.sh.j2`) — Harbor installs the agent *inside* the container environment as part of task setup.

---

## The Adapter Pattern

Adapters are the mechanism for connecting external benchmark datasets to Harbor's task format. Each adapter is a self-contained directory:

```
adapters/{benchmark_name}/
├── adapter.py           # Conversion logic: dataset → Harbor tasks
├── run_adapter.py       # CLI: run the conversion
├── adapter_metadata.json
├── parity_experiment.json  # Validation against original leaderboard
└── template/            # Task template files
```

The `parity_experiment.json` is the useful part — it's a reproducibility contract. Running it should produce results statistically consistent with the benchmark's published leaderboard. If it doesn't, the adapter is broken.

---

## Quality Infrastructure

**`harbor adapter review`** — interactive adapter review CLI with quality scoring
**`harbor quality`** — quality checker with rubric-based LLM evaluation of task quality
**`harbor debug`** — debug checker for failed trials
**`harbor analyze`** — LLM-powered analysis of job results
**Annotator CLI** — human annotation interface for labeling trajectories

The quality rubric (`src/harbor/cli/quality_checker/default_rubric.toml`) defines criteria for evaluating whether a benchmark task is well-formed. The debug checker uses an LLM to analyze why a trial failed and suggest fixes.

---

## Viewer

A React Router + shadcn/ui web viewer for inspecting results (`harbor view`). Shows job-level aggregates, per-trial results, trajectory replay, and agent comparison. Built with Bun + Vite, served by the FastAPI backend.

---

## Key Patterns

**1. Pluggable environment backends without agent code changes**
The `BaseEnvironment.exec()` abstraction means the same agent code runs against Docker locally or Modal at 100× concurrency. Agent authors don't think about the backend.

**2. Reward file as verifier output**
`/logs/verifier/reward.txt` containing 0.0–1.0 is the universal verifier interface. Any verifier that writes this file works. No framework coupling required.

**3. Adapter parity experiments**
Each adapter ships with a validation experiment. This is excellent practice — it means adapters can be trusted to produce results comparable to the original leaderboard.

**4. ATIF as cross-harness standard**
ATIF is how Harbor makes trajectories portable. If you build a custom agent for autoagent, Harbor, or any other ATIF-compatible harness, the same trajectory format works everywhere.

**5. Oracle agent for verifier testing**
The oracle agent always uses the reference solution. Running oracle on a task suite and expecting near-100% score is how you validate that your verifier is correct. If oracle doesn't pass, the bug is in the verifier, not the agent.

**6. `--ae` env var passthrough**
`harbor run ... --ae AWS_ACCESS_KEY_ID=$KEY --ae REGION=us-east-1` passes arbitrary env vars to agents at runtime without baking them into task definitions.

---

## Relationship to autoagent

autoagent (reviewed yesterday) uses Harbor as its eval backend. Its `agent.py` uses the `harbor.environments.base.BaseEnvironment` and `harbor.agents.base.BaseAgent` ABCs directly. The ATIF trajectory format in autoagent is Harbor's format. Harbor is the infrastructure; autoagent is a meta-learning loop on top of it.

This means any agent built for Harbor can be plugged into autoagent's hill-climbing loop. The two systems compose cleanly.

---

## Getting Started

```bash
# Install
uv tool install harbor

# Run Terminal-Bench 2.0 against Claude Code (local Docker)
export ANTHROPIC_API_KEY=...
harbor run --dataset terminal-bench@2.0 --agent claude-code --model anthropic/claude-opus-4-1 --n-concurrent 4

# Run SWEBench against multiple agents
harbor run --dataset swebench@verified --agent claude-code --model anthropic/claude-sonnet-4-5 -n 10

# List all available datasets
harbor datasets list

# Initialize a custom task
harbor init

# Build and run a custom agent
harbor run --agent-import-path my_agent:MyAgent --dataset my-tasks/
```

---

## Verdict

This is essential infrastructure for anyone doing agent evaluation. The 55-adapter library covering most major benchmarks (SWEBench family, USACO, GPQA, Terminal-Bench, etc.) plus 15 production agents plus pluggable cloud execution backends makes Harbor the most complete open-source agent evaluation platform available.

The ATIF format, oracle agent pattern, and parity validation experiments are the three patterns most worth stealing for custom evaluation work.

If we ever need to formally benchmark models against each other for VOS/ODR decisions, Harbor is the harness.

Source: harbor-framework/harbor (Apache 2.0). Review by Rue.
