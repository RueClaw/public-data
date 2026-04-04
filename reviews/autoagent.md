# kevinrgu/autoagent — Review

**Repo:** https://github.com/kevinrgu/autoagent  
**Organization:** thirdlayer.inc (hiring, launching a product)  
**License:** ⚠️ No LICENSE file — use for educational/non-commercial only, no redistribution  
**Stack:** Python 3.12+ / OpenAI Agents SDK / Claude Agent SDK / Harbor / Docker  
**Reviewed:** 2026-04-03  
**Rating:** ⭐⭐⭐⭐ — The meta-agent pattern is genuinely sharp; the concept deserves scrutiny

---

## What It Is

"Autoresearch but for agent engineering." The core idea: give a meta-agent a benchmark and let it autonomously hill-climb on agent harness design overnight. It modifies the system prompt, tools, agent config, and orchestration, runs the benchmark, checks the score, keeps or discards the change, and repeats.

The human doesn't touch the harness Python files. Instead, they edit `program.md` — a Markdown file that gives the meta-agent context and defines the directive (what kind of agent to build). The meta-agent then autonomously iterates on `agent.py` until interrupted.

---

## Architecture

### The Two-File Discipline

**`program.md`** — human interface. Contains:
- Meta-agent instructions (what it can/cannot modify)
- The directive (what kind of agent to build)
- Experiment loop rules (keep/discard criteria, overfitting rules)
- "NEVER STOP" — the autonomous loop instruction

**`agent.py`** — the harness under test. A single file with two explicitly marked sections:
- **Editable section:** `SYSTEM_PROMPT`, `MODEL`, `MAX_TURNS`, `create_tools()`, `create_agent()`, `run_task()` — the meta-agent's edit surface
- **Fixed adapter section:** Harbor integration + ATIF trajectory serialization — marked DO NOT MODIFY

This split is clean. The meta-agent has a bounded edit surface that's explicitly documented. The infrastructure (Harbor adapter, trajectory serialization) is locked. The meta-agent can't accidentally break the eval harness.

Two agent implementations are included:
- **`agent.py`** — OpenAI Agents SDK (GPT-5 default)
- **`agent-claude.py`** — Claude Agent SDK (Haiku default, extended thinking enabled)

### Harbor Framework

Uses [Harbor](https://github.com/laude-institute/harbor) — a benchmark task runner — for eval. Tasks live in `tasks/` as directories with:
- `task.toml` — config
- `instruction.md` — prompt to the agent
- `tests/test.sh` + `tests/test.py` — verifier (writes 0.0-1.0 score to `/logs/reward.txt`)
- `environment/Dockerfile` — task container
- `files/` — reference files

The harness runs in Docker. Task containers inherit from `autoagent-base`. The agent executes host-side; `run_shell` proxies commands into the container via Harbor's environment API.

### ATIF — Agent Trajectory Interchange Format

The fixed adapter section serializes trajectories to `ATIF-v1.6` JSON — a standardized format for agent trajectories including steps (agent messages, reasoning, tool calls + outputs), token usage, cost, and timing. This is worth knowing about: it suggests an emerging standard for agent trajectory interop.

---

## The Experiment Loop (from program.md)

The meta-agent runs this loop autonomously:

1. Check current branch + commit
2. Read `run.log` and recent task results
3. Diagnose failures by root cause (not by task)
4. Choose one general harness improvement
5. Edit `agent.py`
6. Commit the change
7. Rebuild + rerun task suite
8. Record to `results.tsv`
9. Keep if `passed` improved; keep if `passed` equal but simpler; discard otherwise

**Key rules baked into program.md:**
- **Overfitting guard:** "If this exact task disappeared, would this still be a worthwhile harness improvement? If no, it's probably overfitting."
- **Simplicity criterion:** Equal performance with simpler code is a real improvement. Fewer components, less brittle logic, cleaner tool interfaces all count.
- **NEVER STOP:** Explicit instruction not to pause, ask for confirmation, or stop at a "good stopping point." Keep iterating until the human interrupts.

The `results.tsv` ledger (commit / avg_score / passed / task_scores / cost_usd / status / description) is a clean experimental log pattern.

---

## Notable Design Choices

**1. Single-file harness**
Everything the meta-agent edits lives in `agent.py`. Not split across modules, not spread across configs. This is intentional — it makes the edit surface clear and self-contained. The trade-off is that the harness can't grow very large without becoming unwieldy, but for the overnight hill-climb pattern this is a feature, not a bug.

**2. Meta-agent programs meta-agent**
The human writes `program.md`; the meta-agent writes `agent.py`. Humans specify intent and constraints; the AI handles implementation details. This is a clean separation of concerns.

**3. Failure analysis before changes**
The loop explicitly requires diagnosing failures by *class* before making changes. "Fix a class of failures, not a single task" is the operating principle. This is good scientific hygiene for automated optimization — without it you get benchmark overfitting immediately.

**4. Keep/discard as a hard rule, not a judgment call**
The keep/discard criteria are binary and explicit: `passed` improved → keep; `passed` equal + simpler → keep; otherwise discard. No "seems better" judgment. Discarded runs are still logged because they provide learning signal for the next iteration.

**5. Extended thinking in claude-claude.py**
The Claude variant enables extended thinking with `budget_tokens: 10000`. This is interesting — they're using thinking as part of the agent's task execution, not just the meta-agent's planning.

---

## Limitations & Concerns

**No license.** This is an oversight or intentional for now (early-stage startup, product launch incoming). Can't redistribute or build on it commercially without clarification. Educational use only.

**No tasks shipped.** The repo ships without benchmark tasks. You have to bring your own Harbor-format tasks or wait for benchmark-specific branches. This makes it hard to evaluate without prior Harbor experience.

**GPT-5 default.** The baseline `agent.py` hardcodes `MODEL = "gpt-5"` and `program.md` says "Do NOT change the model from gpt-5 unless the human explicitly changes that constraint." Suggests the benchmarks they've run are GPT-5-optimized.

**Infrastructure complexity.** Docker + uv + Harbor + the benchmark tasks = nontrivial setup. Not a weekend project.

**No validation that discards are correct.** The keep/discard rule is score-based, but if the benchmark has variance (non-deterministic tasks), a borderline run might be discarded due to noise. No statistical significance testing.

---

## Reusable Patterns

**1. Editable/Fixed Boundary in a Single File**
The explicit `FIXED ADAPTER BOUNDARY` comment pattern for separating meta-agent edit surface from infrastructure is clean and reusable. Apply this anywhere you want an AI to safely modify a file without breaking load-bearing code.

**2. program.md as Meta-Agent Configuration**
Separating "what the meta-agent should do" (program.md) from "what the object agent does" (agent.py) is the right abstraction. The human programs the meta-agent's behavior; the meta-agent programs the object agent. We could apply this pattern to our own automated improvement workflows.

**3. Overfitting Guard as Explicit Rule**
The "if this task disappeared, would this improvement still be worthwhile?" test is a good explicit check against benchmark overfitting. Worth embedding in any automated optimization loop.

**4. results.tsv Experiment Ledger**
Tab-separated ledger of every experiment run with commit hash, score, status, and description. Simple, queryable with standard tools, gitignored (doesn't clutter the repo). Good pattern for any overnight optimization task.

**5. ATIF Trajectory Format**
The trajectory serialization format (schema_version, session_id, agent metadata, steps with tool calls + observations, final_metrics with token counts) is a reasonable interchange format for agent trajectories. If ATIF-v1.6 is an emerging standard, worth knowing about.

---

## Verdict

The meta-agent pattern is legible and the design choices are thoughtful. The keep/discard discipline, overfitting guard, and simplicity criterion together form a more rigorous optimization loop than most agent eval setups. The editable/fixed boundary pattern in a single file is immediately reusable.

The startup context (product launch incoming, hiring) means this repo will probably evolve quickly. The lack of a license is a flag but may just be an oversight. Worth watching.

Source: kevinrgu/autoagent (no explicit license — educational use only). Review by Rue.
