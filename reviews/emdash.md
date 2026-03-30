# Emdash (generalaction/emdash)

*Review #290 | Source: https://github.com/generalaction/emdash | License: MIT | Author: General Action / YC W26 | Reviewed: 2026-03-29 | Stars: 3,314*

## Rating: 🔥🔥🔥🔥

---

## What It Is

A desktop application (Electron + React) that functions as an "Agentic Development Environment" (ADE). The core premise: parallel coding agents, each isolated in their own git worktree, running against the same codebase simultaneously. You manage tasks via Linear/GitHub/Jira tickets, review diffs, run CI checks, and merge — all without leaving the app. YC W26.

If Paperclip (review #289) is about running organizations of agents, Emdash is about running a developer workstation of agents — more focused, more tactile, aimed at solo engineers or small teams drowning in parallel work.

---

## Architecture

Electron desktop app. TypeScript throughout.

```
src/
├── main/           — Electron main process
│   ├── services/   — 36+ services
│   ├── workers/    — background worker threads
│   ├── ipc/        — IPC channel definitions
│   └── db/         — SQLite via Drizzle ORM (local-first)
├── renderer/       — React UI
├── shared/         — shared types/utils
└── types/
```

**Process model:** Standard Electron split. Main process owns all system access (SSH, git, PTY, file I/O), renderer is the UI layer, IPC channels bridge them. The SSH architecture docs include full component diagrams.

**Data storage:** Local-first SQLite at `~/Library/Application Support/emdash/emdash.db` (macOS). Projects, connections, SSH credentials, worktrees, task sessions all stored locally.

---

## Core Feature: Git Worktree Isolation

Each coding agent gets its own git worktree. This is the right primitive — isolates agents from each other without requiring separate clones. You can have Claude Code working on feature A, Codex working on a bug fix, and Qwen Code refactoring tests, all in the same repo simultaneously, without stepping on each other.

Services involved: `WorktreeService`, `WorktreePoolService`, `WorkspaceProviderService`, `RepositoryManager`. The worktree pool manages allocation/deallocation as tasks come and go.

---

## Agent Support

23 CLI providers. The breadth is notable:

**Coding agents:** Claude Code, Codex, Qwen Code, Amp, Cursor, Cline, Gemini, Goose, Continue, Hermes Agent (NousResearch), Kilocode, Kiro (AWS), Mistral Vibe, OpenCode, Pi, Rovo Dev (Atlassian), Auggie, Autohand Code, Charm/Crush, Codebuff, Droid (Factory)

Each agent runs in a dedicated PTY (`RemotePtyService`). `TerminalSnapshotService` can capture terminal state. `AgentEventService` tracks what agents are doing.

Special integrations:
- **ClaudeConfigService + ClaudeHookService**: direct hooks into Claude Code's hook system (lifecycle events)
- **OpenCodeHookService**: same for OpenCode
- **SkillsService**: inject skills/context into agents at runtime
- **McpService + mcp/**: MCP server management — agents can be given access to MCP tools
- **LifecycleScriptsService**: pre/post task lifecycle scripts (ProjectPrep, setup automation)

---

## Issue Tracker Integration

Pass tickets directly to agents. Three integrations:
- **LinearService** — Linear API key auth
- **JiraService** — Atlassian API token
- **GitHubService** (+ **GitHubCLIInstaller**) — via `gh` CLI auth

The `PrGenerationService` handles PR creation after agent work completes. CI/CD check visibility and merge are in-app.

---

## SSH Remote Development

The most technically substantial feature beyond the agent orchestration itself. Full SSH remote development:

- Connect to any SSH server (agent auth, key auth, or password)
- Run agents against remote codebases — same parallel workflow as local
- `RemoteGitService`: git operations over SSH
- `RemotePtyService`: interactive PTY over SSH tunnel
- `SshCredentialService`: credentials stored in OS keychain
- `SshHostKeyService`: host key verification against known_hosts
- SFTP for file operations

Architecture: Electron main process manages the connection pool. Renderer issues IPC calls (`ssh:*` channels). Full diagram in `docs/ssh-architecture.md`.

This is genuinely useful for the "run heavy agents on a remote machine with more RAM/compute, manage from laptop" use case.

---

## Additional Services

- **ForgejoService** — Forgejo/Gitea self-hosted git integration
- **GitLabService** — GitLab support
- **AutomationsService** — trigger workflows on events
- **PlanLockIpc** — plan-locking to prevent conflicts when multiple agents work on related code
- **OAuthFlowService** — OAuth for provider auth flows
- **EmdashAccountService** — optional cloud account sync
- **ChangelogService** + **AutoUpdateService** — in-app updates
- **PlainService** — generic/plain agent wrapper for anything not explicitly supported

---

## Telemetry

Anonymous via PostHog — app start/close, feature names, versions. No code, no file paths, no prompts, no PII. Toggle off in Settings → General → Privacy & Telemetry, or `TELEMETRY_ENABLED=false` env var.

---

## Installation

```bash
# macOS (Apple Silicon)
brew install --cask emdash

# Or download directly
https://github.com/generalaction/emdash/releases/latest/download/emdash-arm64.dmg
```

Also: Windows (x64 MSI/portable), Linux (AppImage/deb).

---

## Comparison to Alternatives

- **tmux + multiple Claude Code terminals**: No isolation, no task tracking, no issue integration, no diff review
- **Paperclip (review #289)**: Different abstraction level. Paperclip = org chart + goals + budgets for long-running autonomous agents. Emdash = developer workstation for interactive parallel coding sessions. Complementary, not competing.
- **Cursor**: Single-agent IDE. No parallelism, no worktree isolation, no multi-provider.
- **Sweep/SWE-bench tools**: Typically pipeline-based, not interactive. Emdash is a workflow tool for engineers actively involved in directing the agents.

---

## Caveats

- Electron = heavy (128MB repo, desktop app). Not server-deployable without display.
- 3,314 stars — less viral than Paperclip, but YC W26 backing and active development (last commit: today).
- No API/server mode — this is designed to be used interactively by a human at a desk, not orchestrated programmatically.
- The plan-locking mechanism (`planLockIpc.ts`) exists but I haven't verified how robust multi-agent conflict resolution is in practice.
- `EmdashAccountService` suggests cloud sync features; unclear what data leaves the machine if enabled.

---

## Verdict

🔥🔥🔥🔥 — The right primitives (git worktree isolation, 23 agent adapters, issue tracker integration, SSH remote development, skill injection, MCP support) packaged in a desktop app that actually ships. Not as architecturally ambitious as Paperclip but more immediately practical for a developer who wants to stop babysitting parallel Claude Code sessions. The SSH remote development feature is particularly well-built. MIT. Cloned to `~/src/emdash`.
