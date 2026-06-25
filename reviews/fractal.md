# Fractal (Trampoline-AI/fractal)

**Repo:** https://github.com/Trampoline-AI/fractal  
**License:** MIT - reusable with attribution  
**Reviewed:** 2026-06-24  
**Stack:** Python, Click/argparse CLI, DSPy, predict-rlm, Docker SBX, Pydantic, Rich, prompt-toolkit, uv, pytest, Remotion  
**What it is:** Fractal is a terminal coding agent that wraps Trampoline's `predict-rlm` Recursive Language Model runtime, giving it workspace mounting, session persistence, provider setup, an interactive TUI, and a headless mode for delegation from other agents or CI.

---

## Verdict

✅ **Deploy candidate for experimental large-context coding-agent delegation.** Fractal is early, but it is not vapor: the repo has a clean Python package, provider/config plumbing, session persistence, headless JSON output, a distributable agent skill, CI, and a local pass of `uv run pytest -q` at 270 passed / 1 deselected. Use it as a secondary heavy-analysis worker or RLM evaluation surface, not as a fully proven replacement for a mature daily coding agent.

---

## What It Is

Fractal is the easiest public entry point into Trampoline's Recursive Language Model work. The core claim is that the agent loop is not hand-authored orchestration around an LLM; the model writes and runs its own inference code through `predict-rlm`, can spawn sub-LM calls for slices of a task, and folds the results back into a final answer.

The Fractal repo adds the product layer around that runtime: CLI flags, first-run provider setup, model/sub-model selection, Docker SBX execution, direct workspace mounts, multi-turn sessions, usage accounting, a terminal UI, and `-p/--prompt` headless mode. It also ships an agent skill that tells other coding agents when to delegate deep repository analysis to Fractal.

The target user is a developer or agent host that wants to hand off context-heavy work: audits across many files, large logs, broad codebase questions, and tasks where programmatic context slicing matters more than a polished chat interface.

## Stack

| Layer | Tech |
|-------|------|
| Language | Python 3.11+ |
| Agent runtime | `predict-rlm[sbx]`, DSPy |
| Sandbox | Docker SBX via `SbxBackend`, direct host workspace mounts |
| CLI | argparse, Rich, prompt-toolkit |
| Config | TOML, Pydantic schema validation, XDG config/state paths |
| Credentials | Env references, local `credentials.toml` with restrictive permissions, Codex CLI auth option |
| Providers | OpenAI Codex, OpenAI API, Anthropic, Gemini, xAI, Z.AI, DeepSeek, Mistral, Groq, OpenRouter, Ollama, custom OpenAI-compatible |
| Session state | JSON summaries and histories under the Fractal state directory |
| Distribution | PyPI package `fractal-rlm`, uv tool install, shell installer |
| Tests | pytest, ruff, GitHub Actions across Python 3.11-3.13 |
| Media/demo | Remotion release video project |

## Key Features

### Recursive Agent Runtime With Thin Product Shell

Fractal's main design choice is restraint. The runtime is delegated to `predict-rlm`; Fractal wraps it with just enough CLI, config, sandbox, and session machinery to make it usable on real projects. The `FractalAgent` builds a DSPy signature, passes the workspace and session history into `PredictRLM`, and returns a concise response plus changed files.

That makes the repo more interesting as an RLM evaluation harness than as another custom agent loop. Most coding agents add planner/executor/reviewer layers. Fractal exposes a different bet: let the model own the harness inside a sandboxed execution environment.

### Headless Delegation Contract

The headless mode is practical:

```bash
fractal -p "audit this repo for security issues" --workspace /path/to/project
fractal -p "summarize recent changes" --workspace /path/to/project --json --quiet
```

Stdout is the final answer. Stderr carries session id, progress, changed files, usage, and completion status. With `--json --quiet`, stdout becomes a machine-readable result object containing `session_id`, `status`, `response`, `changed_files`, `usage`, and `error`.

That is the right shape for "agent as tool" usage. A primary coding agent can call Fractal for a heavy scan, parse the answer, then decide what to do next.

### Workspace-Scoped Session Memory

Sessions have two layers: a compressed summary that is baked into future signature instructions, and full trace history passed as structured data for exact inspection. The session state is stored outside the project by default under the user state directory, keyed by workspace.

The important detail is that Fractal treats session memory as an audit artifact, not just a chat transcript. It records user turns, agent status, changed files, file reads, commands, errors, usage, and traces when runtime hooks support them.

### Provider And Credential Hygiene

The config layer is stronger than many early agent CLIs. It rejects raw secret fields in config, validates provider ids and env-var names, redacts credential references in rendered output, supports stored credentials in a separate credentials file, and uses restrictive permissions for config and credentials.

Provider support is broad enough for experimentation: hosted APIs, Codex CLI auth, local Ollama, and custom OpenAI-compatible endpoints. The model menu is curated but not artificially exhaustive.

### Sandboxed Execution With Real File Mounts

Every RLM turn runs through Docker SBX. The workspace is mounted directly into the sandbox, and optional `--include` paths can mount additional directories. The README says the sandbox has no network access by default.

This is powerful and sharp-edged. Direct mounts mean edits happen to real files immediately. That is exactly what a coding agent needs, but it means Fractal should be run in a git-controlled workspace with ordinary local-agent caution.

## Architecture

The codebase is compact and readable:

- `src/fractal/cli.py` owns interactive/headless entry points, flags, stdout/stderr contracts, exit codes, and setup flow.
- `src/fractal/runtime.py` coordinates sessions, runtime events, interruption handling, provider labels, and calls into the agent.
- `src/fractal/agent/service.py` wraps `PredictRLM`, builds SBX interpreters, loads workspace `AGENTS.md`, and constructs direct mounts.
- `src/fractal/agent/signature.py` defines the model-facing workspace editing contract, including always-visible session summary text.
- `src/fractal/config.py`, `providers.py`, `credentials.py`, and `runtime_lms.py` handle provider selection, config layering, validation, secret separation, and LM object construction.
- `src/fractal/session.py` stores durable turn summaries, full history, usage, and headless JSON result models.
- `.agents/skills/fractal/` ships the delegation skill other agent hosts can install.

The runtime hook reducer in `events.py` is a useful observability layer. It normalizes PredictRLM file and subprocess hooks into user-facing status and durable per-turn facts while suppressing nested duplicate events.

## Comparison

| Aspect | Fractal | Codex / Claude Code style agents | Decapod | Context Firewall |
|--------|---------|----------------------------------|---------|------------------|
| Primary role | RLM-powered coding-agent CLI and delegation target | General interactive coding agents | Repo-local governance and proof kernel | Command-output compression and retrieval layer |
| Core bet | Model owns recursive harness logic | Host owns tool loop and context management | Agents need explicit intent/boundary/proof calls | Agents need smaller terminal output with raw evidence preserved |
| Sandbox | Docker SBX direct workspace mounts | Host-dependent | Containerized validation emphasis | Runs host commands, stores raw output locally |
| Best fit | Large-context analysis and RLM experimentation | Daily coding work | Agent governance and verification | Noisy command/log workflows |
| Maturity | Alpha but tested | More mature products | Study/architecture substrate | Narrow local utility |

Fractal is closest to a new runtime shape, not a governance or observability tool. It pairs naturally with tools like Decapod or Context Firewall but does not replace them.

## Self-Hosting Notes

Install paths:

```bash
uv tool install fractal-rlm
fractal --help
```

or:

```bash
curl -LsSf https://fractal.trampoline.ai/install.sh | sh
```

Operational requirements matter:

- Python 3.11+ and uv.
- Docker plus `sbx` v0.33.0+, logged in.
- A configured provider or local Ollama.
- A git-controlled workspace so direct edits are reviewable.
- Careful use of `--include`, because included paths are also writable inside the sandbox.

The shell installer bootstraps uv from Astral if missing, then installs the PyPI tool and warns about SBX prerequisites. That is convenient, but security-conscious users should inspect the installer first or use `uv tool install` directly.

---

**Attribution:** Trampoline-AI/fractal, MIT, https://github.com/Trampoline-AI/fractal
