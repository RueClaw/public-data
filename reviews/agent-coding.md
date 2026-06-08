# Agent Coding (dsweet99/agent_coding)

**Repo:** https://github.com/dsweet99/agent_coding
**License:** No license specified — educational/personal use only; do not reuse code or prompts verbatim without permission.
**Reviewed:** 2026-06-07
**Stack:** Markdown prompt commands, Python 3.10+, Click, pytest, ruff, cursor-agent, optional Harbor/SWE-bench integration
**What it is:** A compact agent-coding workflow repo that packages reusable Cursor command prompts and a Python CLI, `malvin`, for automating implement/review/revise loops with separate coder and reviewer agent sessions.

---

## Verdict

📚 **Study the workflow, not the code.** The project is valuable because it turns a personal coding-agent habit into a concrete loop: plan, implement, adversarially review, falsify review findings, fix concerns, repeat until `LGTM`. The runnable `malvin` wrapper has a real test suite and clean local validation, but the repo has no license, thin packaging docs, and strong coupling to Cursor Agent.

---

## What It Is

`agent_coding` is a small collection of agent instructions for coding work. The top-level `rules.md` defines strict session behavior such as reading a local style file first, distinguishing claims from hypotheses, observing bugs before fixing them, and running quality gates. The `commands/` directory then adds named workflows: planning (`rr`), implementation, review, concern resolution, falsification (`kpop`), creative boundary exploration (`mbc2`), and session learning.

The most substantial component is `malvin`, a Python package that automates the manual workflow described in the README. Given a plan file, it creates run artifacts, invokes `cursor-agent` for implementation, starts fresh reviewer sessions for two review phases, runs a falsification prompt when reviews are not `LGTM`, and routes the resulting `review.md` back to the coder session for fixes.

The repo also includes a small benchmark-style demo comparing a plain `cursor-agent` run with the `malvin` loop on a generated KNN CLI task. That demo is anecdotal rather than a rigorous benchmark, but it clearly communicates the intended advantage: structured review and retry loops can catch contract mismatches that a one-shot coding agent misses.

## Stack

| Layer | Tech |
|-------|------|
| Prompt workflow | Markdown command files for Cursor-style agents |
| CLI | Python package `malvin` |
| CLI framework | Click |
| Agent runtime | `cursor-agent` CLI |
| Quality gates | pytest, ruff, kiss, optional Rust/Cargo checks |
| Artifacts | `_malvin/<run-id>/` logs, copied plan, review file |
| Integration | Optional Harbor installed-agent wrapper and bundle builder |

## Key Features

### Two-Role Coding Loop

`malvin` keeps implementation and review as different roles. The coder session handles implementation and concern fixes; each review attempt gets a fresh reviewer session. This separation is the main design idea: the reviewer is less likely to inherit the implementer's assumptions, while the coder keeps continuity across fixes.

### Exact `LGTM` Gate

Review success is deliberately simple: a review phase passes only when the reviewer writes exactly `LGTM`. Anything else becomes a concern file and triggers another repair attempt until the configured loop limit is reached.

### Falsification Prompt

The `kpop` command asks the agent to formulate falsifiable hypotheses, predictions, and tests. This is a good antidote to vague agent review language: the loop encourages concrete checks, logs, and attempts to disprove a claim before turning it into a fix.

### Persistent Run Artifacts

Each run creates a timestamped `_malvin` directory and logs agent streams into named files. That matters for agentic coding because failures are often process failures, not just code failures; having durable prompts, reviews, and logs makes postmortems possible.

### Harbor Bundle Support

The `malvin` package includes helper code for packaging itself into a deterministic tarball with metadata, installing into a Harbor-style task environment, and writing a plan into the remote environment safely with base64 encoding. This is early, but it shows attention to portable evaluation harnesses.

## Architecture

The architecture is straightforward:

- `AgentClient` wraps `cursor-agent` chat creation, authentication probing, streaming JSON parsing, retry, and optional tee output.
- `Orchestrator` encodes the workflow state machine: implement, review phase 1, review phase 2, optional learn.
- `PromptStore` materializes default prompts into `~/.malvin/prompts` so users can edit them without modifying the package.
- `RunArtifacts` creates `_malvin/<timestamp>_<token>/` and copies the source plan into the run folder.
- Harbor helpers package and install `malvin` in external task environments.

The code is intentionally small and testable. The main limitations are not algorithmic; they are product boundaries: Cursor Agent is assumed, `style.md`/`.style/main.md` conventions are personal, and the top-level instructions include repo-specific opinions such as "NEVER CALL GIT" that will not fit every team.

## Validation

Local checks performed:

- `python3 -m compileall -q /tmp/agent_coding/malvin/src /tmp/agent_coding/demo` passed.
- `uv run pytest -q` initially failed during collection because the invoked pytest environment could not import `click`.
- `uv run --with pytest --with click pytest -q` passed: 75 tests.
- `uv run --with ruff ruff check .` passed.

The dependency wrinkle is worth noting: the package declares `click>=8.1`, and `uv pip list` showed `click` installed afterward, but the plain `uv run pytest` path still failed here. A documented test command or dev dependency group would remove that ambiguity.

## Comparison

| Aspect | Agent Coding / Malvin | 12-Factor Agents | Webwright | Workflow Skill Libraries |
|--------|------------------------|------------------|-----------|--------------------------|
| Main focus | Coding-agent implement/review loop | Production agent design principles | Browser tasks as reusable scripts | Reusable agent procedures |
| Runtime | Cursor Agent CLI | Conceptual guide/examples | Python + Playwright | Usually Markdown skills |
| Strength | Concrete review/falsification loop | Strong architecture rubric | Durable executable artifacts | Easy routing and reuse |
| Limitation | No license and Cursor coupling | Not a coding harness | Browser-specific | Often not executable |

## Self-Hosting Notes

For local experimentation:

1. Install and authenticate `cursor-agent`.
2. Install `malvin` from `malvin/`.
3. Provide a plan file.
4. Run `malvin plan.md`.

Expect output under `_malvin/`. Treat this as a local trusted-development tool: it can run coding agents with broad repository access, quality gates, and shell commands.

---

**Attribution:** dsweet99/agent_coding, no license specified.
