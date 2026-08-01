# Scopey (ArchAstro/scopey)

**Repo:** https://github.com/ArchAstro/scopey  
**License:** MIT, permissive reuse with attribution  
**Reviewed:** 2026-08-01  
**Stack:** Rust CLI, Clap, JSON/TOML, agent lifecycle hooks, Claude Code, Codex, Grok, Pi, OpenCode, GitHub Actions, Homebrew releases  
**What it is:** A lightweight CLI that watches coding-agent sessions, extracts the active user scope, judges tool activity against that scope, and injects reminders or corrections when the run drifts.

---

## Verdict

✅ **Deploy candidate for agent-hook users who can tolerate pre-1.0 formats.** Scopey is small, MIT licensed, actively released, and has unusually practical safety work for a brand-new hook tool: recursion guards, per-session locks, bounded background jobs, structured logs, stale-judgement expiry, and 89 passing local tests. The main caveats are expected for a first release: it stores sensitive prompts under `~/.scopey/`, invokes local model CLIs, and depends on each harness's hook semantics staying stable.

---

## What It Is

Scopey sits beside coding-agent CLIs rather than replacing them. `scopey setup` installs lifecycle hooks or extensions for Claude Code, Codex, Grok, Pi, and OpenCode. When a user prompt arrives, Scopey records it in a local session store and asks a fast model to produce the current active scope. As tools run, Scopey journals high-signal tool events and periodically asks another model whether the trajectory is on scope, warning, off track, or insufficient evidence.

The correction path is intentionally delayed and bounded. Hooks stay fast by spawning background summarizer/judge jobs, then injecting the result at a later tool boundary or stop event. That means Scopey is not a hard policy engine; it is an attention and steering layer for long agent runs.

The design is particularly useful for sessions where the human says "only do X" and the agent gradually wanders into adjacent cleanup, refactoring, or debugging. Scopey makes that boundary explicit, durable, inspectable, and model-visible again.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Rust 2021 CLI |
| CLI/config | `clap`, TOML config, JSON session files |
| Storage | Local `~/.scopey/work/by-id/<session_id>.json`, JSONL logs |
| Hook targets | Claude Code, Codex, Grok, Pi, OpenCode |
| Model runners | Local product CLIs: `claude`, `codex`, `grok`, `pi`, `opencode` |
| Notifications | OS notifications, optional Herdr integration, optional shell command |
| Packaging | Cargo, GitHub release assets, Homebrew tap |
| CI | fmt, Clippy, docs, tests, package, cargo-audit in GitHub Actions |

## Key Features

### Current-Scope Extraction

Scopey treats each user prompt as a mutation of the current scope instead of appending everything forever. The summarizer prompt distinguishes add, subtract, modify, replace, query, admin, and machine-event operations. Explicit removals and replacements win; silence does not cancel active requirements.

That is the right mental model for agent work. A later "actually only fix the test" should narrow the run. A generated task notification should not become a new user goal.

### Hook-Side Tool Journal

Instead of relying only on raw transcript tails, Scopey keeps a structured tool journal. It records tool name, bounded argument preview, timestamp, noise status, and a meaningful-tool index. Noisy helper events such as `write_stdin`, waits, list calls, and token counts do not advance judgement windows.

This cuts down a common false-positive source: judging a giant terminal-output tail or an internal wait event instead of the agent's actual decisions.

### Background Judging With Recursion Guards

Scopey sets internal environment variables on child model processes so its own summarizer and judge calls cannot trigger Scopey again. It also uses per-session locks, a minimum job interval, a global job cap, and stale judgement expiry.

Those details matter. Hook tools can create process storms if they recursively observe their own model calls or spawn a judge on every tool event.

### Cross-Harness Installers

The setup command writes hook/plugin files for five agent surfaces:

- Claude Code settings
- Codex hooks
- Grok global hooks
- Pi extension
- OpenCode plugin

The repo also includes uninstall paths that can remove hooks while keeping or purging Scopey's local data.

### Session Insights

`scopey insights` turns stored judgements into a cross-session report. It can filter by date, harness, working directory, session, or verdict, and it separates insufficient-evidence warnings from real drift. That makes Scopey useful after the run, not only during the run.

## Architecture

Scopey's code is compact and fairly clean:

- `src/hooks/handlers.rs` normalizes hook payloads, updates the session store, injects corrections, and schedules background jobs.
- `src/trajectory.rs` builds scope/judge prompts, parses model output, and builds reminder/correction text.
- `src/session.rs` owns the durable session store, locking, judgement state, stale expiry, and migration from older cwd-keyed files.
- `src/tool_journal.rs` records and formats high-signal tool events.
- `src/guard.rs` prevents recursive hooks and process storms.
- `src/model.rs` abstracts the supported model-runner CLIs.
- `src/hooks/setup.rs` installs and uninstalls harness hooks.

The best design decision is the division between hook-critical-path work and detached analysis. Hooks do the minimum local update, persist state, and get out of the agent's way. Model calls happen out of band.

## Comparison

| Aspect | Scopey | SageRoute | Foundry | Mindwalk |
|--------|--------|-----------|---------|----------|
| Main job | Keep a live agent run within user scope | Route model strength from trajectory evidence | Provide a durable agent process | Visualize/replay sessions |
| Integration point | Harness hooks/extensions | OpenAI/Anthropic-compatible proxy | Markdown commands/skills | Trace adapters and local visualization |
| Control style | Reminder/correction injection | Model selection and restart policy | Human-readable workflow stages | Post-run inspection |
| Best pattern | Hook-driven scope drift guard | Evidence-derived escalation ladder | Source-to-adapter command generation | Replayable session maps |
| Main caveat | Pre-1.0 hook semantics and sensitive local logs | External decision API and early ops posture | Process/token weight | Observability rather than live control |

Scopey is closest to an agent seatbelt. It does not sandbox tools, select providers, or structure the whole workflow. It watches for scope drift and speaks up at the right boundary.

## Self-Hosting Notes

Install paths are straightforward:

```bash
brew install ArchAstro/tools/scopey
scopey setup
scopey doctor
```

or:

```bash
cargo install --git https://github.com/ArchAstro/scopey.git
scopey setup
scopey doctor
```

Operational notes:

- Treat `~/.scopey/` as sensitive because it contains prompts, tool summaries, judgement history, logs, and config.
- Open Codex `/hooks` and trust the Scopey commands after setup.
- Use `scopey models --verify` before expecting live judgement to work.
- Be deliberate with `model_command` and `notify_command`; both are shell command templates.
- Remember that Scopey steers agents through injected context. It is not an authorization boundary or sandbox.

Local verification on 2026-08-01:

- `cargo test --locked --all-targets --all-features` passed: 84 unit tests and 5 integration tests.
- `cargo clippy --locked --all-targets --all-features -- -D warnings` passed.
- `cargo package --locked --allow-dirty` passed and verified the crate package.
- Local `cargo audit` was not available in this environment; upstream GitHub CI includes a cargo-audit job and the latest CI run on `d7fce6f` passed.

---

**Attribution:** ArchAstro/scopey, MIT License
