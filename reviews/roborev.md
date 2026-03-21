# roborev — Repo Review

**Repo:** https://github.com/roborev-dev/roborev  
**License:** MIT  
**Language:** Go (~56K lines)  
**Cloned:** ~/src/roborev  
**Rating:** 🔥🔥🔥🔥🔥

---

## What It Is

**Continuous code review daemon for AI coding agents.** Installs a git post-commit hook. Every commit triggers a background AI review. Findings surface in a TUI in seconds — while context is fresh. Then `roborev fix` feeds findings back to a coding agent to close the loop.

The pitch: agents write code fast and compound errors. roborev is the quality gate that runs continuously in the background, catching issues before they stack.

---

## Architecture

```
CLI (roborev) → HTTP API → Daemon (port 7373) → Worker Pool → Agent adapters
                                 ↓                    ↓
                             SQLite DB ←──sync──→ PostgreSQL (optional)
                                 ↓
                          CI Poller → GitHub PRs
```

- **Daemon:** Long-lived HTTP server (auto-finds port if 7373 busy). Many CLI commands are thin HTTP clients.
- **Workers:** Pool of 4 parallel review workers (configurable)
- **Storage:** SQLite at `~/.roborev/reviews.db` (WAL mode) + optional PostgreSQL sync for multi-machine
- **TUI:** Bubbletea terminal UI — review queue, individual review view, task views. Vim-style nav.
- **Git hook:** Post-commit. Background daemon work never touches the working tree; foreground fix flows may.
- **Worktrees:** Isolated git worktrees for fix jobs — safe, parallel, non-destructive.

### Agent Registry (11 implementations)

| Agent | File |
|---|---|
| Claude Code | `claude.go` |
| Codex CLI | `codex.go` |
| Gemini CLI | `gemini.go` |
| GitHub Copilot | `copilot.go` |
| Cursor | `cursor.go` |
| OpenCode | `opencode.go` |
| Kiro | `kiro.go` |
| Kilo | `kilo.go` |
| Droid | `droid.go` |
| Pi (OpenClaw) | `pi.go` |
| ACP (generic) | `acp.go` |

**Pi is in there.** As in OpenClaw's Pi agent. roborev explicitly supports OpenClaw as a review backend.

### Skills System
Three markdown skill files in `skills/`:
- `roborev-design-review.md` — design review skill
- `roborev-fix.md` — fix findings from the daemon
- `roborev-respond.md` — respond to review findings

These drop into coding agent skill directories. Agents can then be invoked by roborev to act on reviews.

### The Refine Loop
```
roborev refine
```
Fully automated: fix findings → commit → re-review → fix again → repeat until all reviews pass (or `--max-iterations` hit). Runs in an isolated worktree. This is the closest thing to a self-correcting agentic loop I've seen in a standalone tool.

### Code Analysis
Beyond review, it does targeted static-ish analysis via AI:
- Duplication, complexity, refactoring suggestions, test fixture extraction, dead code, API design, architecture review
- Results appear in the review queue, fixable with `roborev fix <id>`

### Review Compaction
`roborev compact` — verifies current findings against the actual code (filters stale findings), consolidates related issues, removes false positives. Anti-noise mechanism.

### CI Integration
GitHub Actions integration + CI poller. Reviews can gate PRs.

---

## What's Exceptional

### The Refine Loop Design
`fix → commit → re-review → fix → ...` in an isolated worktree is the right architecture for autonomous code improvement. It's safe (worktree isolation), observable (each iteration is a commit), and terminates (max-iterations). Most agentic loops either don't isolate or don't terminate cleanly.

### Pi / OpenClaw Integration
We're in the agent registry. `pi.go` means roborev can use OpenClaw as a review or fix agent. Worth exploring — continuous commit-triggered reviews running through us.

### False Positive Handling
`roborev compact` doing verification before surfacing findings is the right instinct. Cross-agent code review (like the `/auditcodex` pattern from the sterling commands) hallucinates — you need a validation pass. roborev bakes this in.

### AGENTS.md Quality
The `AGENTS.md` in this repo is one of the better examples I've seen — precise package map with "start with" file pointers, clear daemon vs. foreground/background distinctions, boundary warnings. Good reference for how to write AGENTS.md for a Go project.

### Skills as Drop-ins
The markdown skills in `skills/` are designed to be copied into any coding agent's skill directory. Same pattern as OpenClaw skills or Claude Code's `.claude/commands/`. Portable, composable.

---

## Practical Relevance for Us

1. **Install it.** `brew install roborev-dev/tap/roborev` → `roborev init` in any active project. Automatic commit-triggered reviews while we code.
2. **Wire it to Claude Code or OpenClaw.** Already supported via `claude.go` and `pi.go`.
3. **Use the refine loop on ODR.** The CGC refactor work (90+ raw DB calls) is exactly the kind of work that benefits from `roborev refine`.
4. **Steal the AGENTS.md format** for our Go projects.

---

## What's Not Interesting

- PostgreSQL sync (we don't need multi-machine review sync)
- GitHub Actions CI integration (nice but not urgent)
- Nix flake (`flake.nix` + `flake.lock`) — they use Nix for reproducible builds; we don't

---

## Verdict

One of the most directly useful tools in this review series. MIT licensed, Go, works today, already supports OpenClaw, and fills a real gap: continuous quality feedback on agent-written code. The `refine` loop is the standout feature — genuine autonomous code quality improvement, safely isolated, with natural termination.

Install this. Wire it to Claude Code on ODR this weekend.

---

*Source: https://github.com/roborev-dev/roborev | License: MIT | Reviewed: 2026-03-21*
