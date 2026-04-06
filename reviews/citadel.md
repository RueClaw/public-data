# Citadel (SethGammon/Citadel)

**Repo:** https://github.com/SethGammon/Citadel
**License:** MIT — full extraction permitted
**Reviewed:** 2026-04-06
**Stack:** Node.js 18+, zero external dependencies
**What it is:** An agent orchestration harness for Claude Code that coordinates multiple AI agents in parallel, persists memory across sessions, and routes intent to the cheapest execution path automatically. Installs as a plugin.

---

## Verdict

📚 **The most architecturally complete open-source Claude Code orchestration framework available.** Core features (routing, skills, campaigns, hooks) are production-ready. Fleet mode and daemon mode need more integration testing. The proportional routing and campaign persistence patterns are genuinely novel. 476 stars, active development.

---

## What It Is

Citadel solves the problem of Claude Code sessions being stateless. Without it, every session starts from zero — you re-explain architecture, re-discover fragile modules, re-paste review checklists. Citadel gives Claude Code persistent campaigns, intelligent routing, lifecycle hooks, and multi-agent coordination.

You install it as a plugin (`claude --plugin-dir /path/to/Citadel`), run `/do setup`, and then use `/do <anything>` as your primary interface. The router classifies intent and dispatches to the cheapest tool that fits: a regex match, a keyword-to-skill lookup, or (only as fallback) an LLM classifier.

The system scales through four tiers: Skills (single-task protocols), Marshal (single-session orchestrator), Archon (multi-session campaigns), and Fleet (parallel agents in isolated git worktrees). Campaign files are the only persistent state — every session is amnesiac but reads the campaign file to rebuild context.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Node.js 18+ |
| Dependencies | Zero (stdlib only) |
| Runtimes | Claude Code (full), Codex CLI (partial) |
| State | Markdown campaign files (file-based, no database) |
| Coordination | File-based scope claims |
| Hooks | 25+ JS lifecycle hooks |

## Key Features

### Proportional Routing

The `/do` router uses a four-tier cascade where first match wins:

1. **Tier 0** (~0 tokens): Regex pattern match — catches trivial commands instantly
2. **Tier 1** (~0 tokens): Active state check — resumes in-progress campaigns
3. **Tier 2** (~0 tokens): Keyword lookup — matches against 38 installed skill keywords
4. **Tier 3** (~500 tokens): LLM classifier — structured complexity analysis, only when tiers 0-2 miss

Most requests resolve at tiers 0-2 for zero token cost. After routing, a proportionality check downgrades over-complex routes (e.g., single-file scope → skip Fleet). The system biases toward under-routing because re-invocation is cheaper than over-routing.

### Campaign Persistence

Multi-session work survives session boundaries via campaign markdown files:

```markdown
# Campaign: {Name}
Status: active
Direction: {original request}

## Phases
1. [complete] Research: ...
2. [in-progress] Build: ...

## Decision Log
- {timestamp}: {decision} (Reason: {why})

## Continuation State
Phase: {N}
Files modified: {list}
Blocking: {blockers}
```

Each Archon invocation reads the campaign file to rebuild context. Each completion updates it. No database, no external state store. The campaign file IS the memory.

### Fleet Coordination

Fleet mode spawns multiple agents in isolated git worktrees, preventing file conflicts. Agents execute in waves (2-3 per wave), and a discovery relay compresses each agent's output to ~500-token briefs that get injected into the next wave's context. Wave 2 agents start with Wave 1's knowledge, preventing rediscovery.

File-based coordination prevents scope overlap: parent/child directories conflict, siblings are safe, read-only scopes never conflict. Dead instances are cleaned up by a sweep process.

### Lifecycle Hooks

25+ hook implementations covering:

- Per-file typecheck on every edit (language-adaptive: TS/Python/Go/Rust)
- Circuit breaker for failure loops (escalation after 3-5 consecutive failures)
- Quality gate scanning for anti-patterns before session end
- Cost tracking with configurable budget thresholds
- Protected file enforcement (blocks edits to critical files)
- External action gating by risk tier (secrets > protected-branch > hard > soft > allow)
- Pre/post context compression state preservation

One hook per lifecycle event — consolidation rather than chaining.

### Skill System

38 built-in skills organized as markdown protocol files that load on demand. Zero token cost when unloaded. Skills define Identity, Orientation, Protocol, Quality Gates, and Exit Protocol sections. Custom project skills live at `.claude/skills/{name}/SKILL.md`.

Categories span orchestration (`/do`, `/marshal`, `/archon`, `/fleet`), code quality (`/review`, `/test-gen`, `/refactor`), research (`/research`, `/experiment`), verification (`/qa`, `/postmortem`), and utilities (`/schedule`, `/daemon`, `/learn`).

## Architecture

The architecture is contracts-first. Core contracts define the boundary between the harness and runtimes:

- `core/contracts/` — Formal capability definitions (events, capabilities, runtime, skill-manifest, project-spec, agent-role)
- `runtimes/claude-code/` and `runtimes/codex/` — Runtime adapters that project canonical definitions to runtime-specific formats
- `core/coordination/` — File-based instance tracking, scope claims, stale process cleanup

Runtime detection probes environment variables, parent process name, and directory markers. Each runtime declares what Citadel features it supports, and unsupported features degrade explicitly rather than failing silently.

The hook system is the heaviest code — `post-edit.js` alone is 615 lines, handling language-adaptive typechecks and dependency pattern warnings. `session-end.js` (555 lines) handles quality gates, cost tracking, and continuation state on session close.

## Comparison

| Aspect | Citadel | CrewAI / LangChain | Aider |
|--------|---------|-------------------|-------|
| Type | Plugin for existing agent | Agent framework | Coding assistant |
| Agent creation | No — orchestrates Claude Code | Yes — build agents from scratch | N/A |
| Multi-session | Campaign files | Custom implementation | No |
| Parallelism | Fleet (worktree isolation) | Custom implementation | No |
| Token overhead | ~2.5% | Framework-dependent | N/A |
| Skills system | 38 built-in, markdown-defined | Tools/agents | N/A |

Citadel is not a framework — it's an operating system layer for an existing agent. You don't write agent code; you install a plugin and get routing, persistence, parallelism, and safety on top of Claude Code. If you're building a custom agent, use a framework. If you're using Claude Code and want it to work better, this is the tool.

## Self-Hosting Notes

No self-hosting in the traditional sense — it's a Claude Code plugin. Clone the repo, point `--plugin-dir` at it, run `/do setup`. Works on all platforms (hooks and scripts are Node.js). Requires Node 18+ and Claude Code.

---

**Attribution:** SethGammon/Citadel, MIT License
