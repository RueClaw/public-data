# AutoForge Two-Agent Pattern

> **Source:** [leonvanzyl/autoforge](https://github.com/leonvanzyl/autoforge)
> **License:** No explicit license (educational use only)
> **Description:** Two-agent architecture for long-running autonomous coding with features/story tracking and parallel execution.

## Overview

AutoForge implements a two-agent pattern for building complete applications autonomously over multiple sessions:

1. **Initializer Agent** — First session reads an app spec and creates features in a SQLite database
2. **Coding Agent** — Subsequent sessions implement features one by one, marking them as passing

## Key Architecture Components

### Agent Session Flow

1. Check if `features.db` has features (determines initializer vs coding agent)
2. Create ClaudeSDKClient with security settings
3. Send prompt and stream response
4. Auto-continue with 3-second delay between sessions

### Feature State Machine

Features tracked in SQLite with states:
- `pending` — Not started
- `in_progress` — Currently being worked on
- `passing` — Complete
- `failing` — Failed, needs retry

### Parallel Mode

When running with `--parallel`, the orchestrator:
1. Spawns multiple Claude agents as subprocesses (up to `--max-concurrency`)
2. Each agent claims features atomically via `feature_claim_and_get`
3. Features blocked by unmet dependencies are skipped
4. Browser contexts isolated per agent using `--isolated` flag

### Process Limits

- `MAX_PARALLEL_AGENTS = 5` — Maximum concurrent coding agents
- `MAX_TOTAL_AGENTS = 10` — Hard limit on total agents (coding + testing)
- Testing agents capped at `max_concurrency` (same as coding agents)

## MCP Tools for Feature Management

```yaml
feature_get_stats:       Progress statistics
feature_get_by_id:       Get single feature by ID
feature_get_summary:     Get summary of all features
feature_get_ready:       Get features ready to work on (dependencies met)
feature_get_blocked:     Get features blocked by unmet dependencies
feature_get_graph:       Get full dependency graph
feature_claim_and_get:   Atomically claim next available feature (for parallel mode)
feature_mark_in_progress: Mark feature as in progress
feature_mark_passing:    Mark feature complete
feature_mark_failing:    Mark feature as failing
feature_skip:            Move feature to end of queue
feature_add_dependency:  Add dependency between features (with cycle detection)
```

## YOLO Mode (Rapid Prototyping)

Skips all testing for faster feature iteration:

- No regression testing
- No Playwright MCP server (browser automation disabled)
- Features marked passing after lint/type-check succeeds
- Faster iteration for prototyping

## Security Model

Defense-in-depth approach:
1. OS-level sandbox for bash commands
2. Filesystem restricted to project directory only
3. Bash commands validated using hierarchical allowlist system

### Hierarchical Command Control

1. **Hardcoded Blocklist** — NEVER allowed (dd, sudo, shutdown, etc.)
2. **Org Blocklist** — Cannot be overridden by projects
3. **Org Allowlist** — Available to all projects
4. **Global Allowlist** — Default commands (npm, git, curl, etc.)
5. **Project Allowlist** — Project-specific commands

## Prompt Loading Pattern

Fallback chain:
1. Project-specific: `{project_dir}/.autoforge/prompts/{name}.md`
2. Base template: `.claude/templates/{name}.template.md`

## Key Design Principles

- **Two agents, one goal** — Initializer decomposes, Coder implements
- **Atomic feature claims** — No race conditions in parallel mode
- **Dependency-aware scheduling** — Features respect their dependencies
- **Fresh context per session** — Avoids context window bloat
- **Auto-continue** — No manual intervention between sessions
