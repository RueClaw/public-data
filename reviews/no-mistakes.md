# no-mistakes Review

**Source:** https://github.com/kunchenguid/no-mistakes  
**Author:** Kun Chen / kunchenguid  
**License:** MIT  
**Reviewed:** 2026-06-09  
**Version reviewed:** `268cc6863bb5d9dae88592ba90698265d3f3b089` / `v1.27.0`  
**Rating:** ✅ Deploy candidate

## Summary

`no-mistakes` is a local git proxy for AI-assisted delivery. Instead of pushing directly to `origin`, a developer pushes to a managed `no-mistakes` remote. A local bare repository receives the push, a post-receive hook notifies a daemon, the daemon creates a disposable worktree, and a sequential pipeline reviews, tests, fixes, pushes upstream, opens a PR, and monitors CI.

The project is much more substantial than the tagline suggests. It combines git plumbing, daemon process management, SQLite run state, JSON-RPC IPC, Cobra CLI commands, Bubble Tea/Lip Gloss TUI surfaces, SCM provider adapters, and agent adapters for Claude, Codex, Rovo Dev, OpenCode, Pi, and ACP targets.

Verdict: deploy candidate for personal or sandboxed team use, especially when the goal is to turn "agent produced a branch" into a PR with review/test/CI evidence. The main caveat is that native agent adapters default to broad local permissions unless overridden, so use it in repositories and worktrees where that trust boundary is acceptable.

## What It Does

The core workflow is:

1. `no-mistakes init` records the real upstream remote and adds a managed `no-mistakes` remote.
2. A push to `no-mistakes` lands in a local bare proxy repo instead of going straight to the upstream.
3. A post-receive hook calls `no-mistakes daemon notify-push`.
4. The daemon creates an isolated worktree for the pushed branch and starts a pipeline run.
5. Steps run in order: rebase/intent/lint/review/test/document/push/PR/CI, with configurable skips and auto-fix limits.
6. Findings can pause for user approval, be auto-fixed, be skipped, or be escalated through the TUI/CLI/agent-facing AXI interface.
7. If the pipeline reaches the delivery stages, it pushes upstream, creates or updates the PR/MR, appends deterministic pipeline/testing/risk sections, and monitors CI.

It also ships an agent-native skill in `skills/no-mistakes/SKILL.md` so a coding agent can drive the gate through `no-mistakes axi ...` commands rather than relying only on the terminal UI.

## Architecture

### Local Git Gate

`internal/gate` owns repository setup and teardown. It normalizes subdirectory/worktree invocations back to the main repo, discovers `origin`, creates a deterministic per-repo bare proxy, installs hooks, adds the `no-mistakes` remote, and records the mapping in SQLite.

`internal/git/hook.go` is a particularly strong part of the design:

- managed post-receive hooks notify the daemon asynchronously and keep git push completion non-blocking;
- binary paths are shell-quoted before being embedded in hook scripts;
- hook files are written atomically and made executable;
- the managed bare repo isolates `core.hookspath` in worktree config so tools that mutate hooks in the main repository do not disable the gate.

This is a useful pattern: make the AI delivery gate feel like normal git, but keep it local, reversible, and observable.

### Daemon And IPC

`internal/daemon` manages run lifecycle:

- startup recovery for stale runs and orphaned managed servers/worktrees;
- pid file and signal handling;
- run subscription and event fanout;
- branch-level locking so pushes to the same branch do not race;
- cancellation, rerun, and approval routing.

`internal/ipc` defines a JSON-RPC protocol with methods for push notification, run lookup, rerun, subscribe, respond, cancel, health, and shutdown. That gives the CLI, TUI, and agent-facing AXI surface a common control plane.

### Pipeline

The pipeline is implemented around a small `Step` interface in `internal/pipeline`. The executor is stateful in the right places: it records step results and rounds, tracks auto-fix attempts, freezes timing while waiting for user approval, persists logs per step, emits structured events, and keeps previous findings available for follow-up fix rounds.

The strongest steps are:

- **review:** asks the agent to inspect the branch diff and return structured findings with `auto-fix`, `ask-user`, or `no-op` actions.
- **test:** runs configured tests when present, otherwise asks the agent to choose meaningful validation and collect evidence artifacts.
- **PR:** generates title/body content but appends deterministic risk/testing/pipeline sections from recorded step results.
- **CI:** monitors provider checks, waits for pending checks, handles empty-check grace periods, fetches failed check logs where supported, and attempts bounded fixes.

### Agent Adapters

`internal/agent` defines a common `Agent` interface and normalizes structured output. It accepts raw JSON, fenced JSON, and final bare JSON objects, then validates against JSON schema where provided.

Adapters exist for:

- Claude CLI
- Codex CLI
- OpenCode
- Rovo Dev
- Pi
- ACP targets through `acpx`

The capability breadth is excellent, but there is an important operational caveat: the Claude adapter defaults to `--dangerously-skip-permissions` unless permission args are provided, and the Codex adapter defaults to `--dangerously-bypass-approvals-and-sandbox` unless sandbox/execution flags are provided. That is reasonable for a local autonomous gate, but it should be treated as a deliberate trust decision.

## Strengths

- **Git-native UX:** `git push no-mistakes` is much easier to adopt than a separate ticket runner or web app.
- **Local-first control plane:** the gate, daemon, DB, logs, and worktrees all live on the developer machine.
- **Good state model:** runs, steps, rounds, findings, selected findings, PR URLs, logs, and approvals are persisted.
- **Multiple human surfaces:** CLI, TUI, and agent-facing AXI commands all use the same underlying run model.
- **Provider-aware delivery:** GitHub, GitLab, and Bitbucket support is factored behind SCM host interfaces.
- **Reparability:** gate setup is idempotent and teardown removes the remote, bare repo, worktrees, and DB mapping.
- **Strong tests:** local `go test ./...` passed across the workspace.
- **CI discipline:** upstream CI runs gofmt, go vet, race tests, OS matrix tests, builds, and Linux e2e checks.

## Caveats

- **Broad agent permissions by default:** Claude and Codex native adapters use dangerous/full-permission modes unless overridden through agent args.
- **Push is locally accepted before validation:** the proxy hook is asynchronous and exits successfully, so the gate controls forwarding/PR creation rather than making the original git push block until validation completes.
- **Branch protection still matters:** the project can enforce a `no-mistakes` PR signature with its own workflow, but teams still need repository branch rules to prevent direct merge paths.
- **Telemetry is compiled into release builds:** telemetry can be disabled with `NO_MISTAKES_TELEMETRY=0`, and dev builds without a website id are effectively no-op, but release adopters should make the choice explicit.
- **Agent transcript intent extraction is privacy-sensitive:** the default config enables recent local-agent transcript reading for intent inference. That is useful, but teams should audit the reader scope before using it around sensitive projects.
- **Requires local tool auth:** PR and CI features depend on provider CLIs/APIs such as `gh` being installed and authenticated.

## Reusable Patterns

- **Local git remote as delivery gate:** use a local bare repo and post-receive hook to intercept delivery without changing everyday git habits.
- **Disposable validation worktrees:** validate the pushed branch away from the developer's working tree.
- **Step-round finding ledger:** record every review/test/lint/CI round, selected findings, fix summaries, and approval source.
- **Deterministic PR appendices:** let agents draft prose, but append pipeline/risk/testing evidence from structured state.
- **Agent-facing control API:** expose a machine-oriented CLI/API so another agent can observe and drive the gate safely.

See also: [local-git-remote-validation-gate.md](../patterns/local-git-remote-validation-gate.md)

## Verification

Local checks run on 2026-06-09:

```bash
go test ./...
```

Result: passed.

Repository metadata at review time:

- Stars: 1,114
- Forks: 65
- Open issues: 11
- Latest tag: `v1.27.0`
- Latest reviewed commit: `268cc6863bb5d9dae88592ba90698265d3f3b089`
- License: MIT

## Adoption Notes

Good first pilot:

1. Run only in a disposable or non-sensitive repo.
2. Set explicit agent args to preserve the sandbox/approval model you want.
3. Set `NO_MISTAKES_TELEMETRY=0` if telemetry should be disabled.
4. Keep branch protection rules requiring CI and/or the no-mistakes PR signature.
5. Inspect the generated PR body and evidence artifacts before trusting the workflow unattended.

This is one of the cleaner examples of packaging agent review, fix, test, and PR creation behind an interface developers already understand: git.
