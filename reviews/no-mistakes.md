# no-mistakes Review

**Source:** https://github.com/kunchenguid/no-mistakes  
**Author:** Kun Chen / kunchenguid  
**License:** MIT  
**Reviewed:** 2026-08-30  
**Version reviewed:** `80b78bccb8bd03a9878d132f98f27ad7a5a15afa` / post-`v1.60.3` main  
**Prior review:** 2026-06-09 at `268cc6863bb5d9dae88592ba90698265d3f3b089` / `v1.27.0`  
**Rating:** ✅ Deploy candidate

## Update Notes

Checked again on 2026-08-30. This is a material update, not a "still current" pass.

- Release line moved from `v1.27.0` to `v1.60.3`, with current main one commit past the tag for an install-script 403 fix.
- Stars/forks moved from 1,114/65 to 8,133/828; open issues moved from 11 to 164.
- Major new work landed in branch custody/recovery, CI repair safety, structured PR attestations, evidence publishing, local review evaluation, provider routing, and agent adapters.
- SCM coverage expanded beyond GitHub/GitLab/Bitbucket to Forgejo, Gitea, and Azure DevOps surfaces.
- The verdict stays ✅ deploy candidate, but the caveat is sharper: configure agent permissions, telemetry, transcript intent extraction, and branch protection deliberately before using it on sensitive repositories.

## Summary

`no-mistakes` is a local git proxy for AI-assisted delivery. A developer pushes to a managed `no-mistakes` remote instead of pushing directly to `origin`; a local bare repository receives the branch, a daemon creates a disposable worktree, and the pipeline reviews, tests, documents, lints, pushes, opens or updates a PR, watches CI, and repairs bounded failures.

The project has grown from a clever git gate into a serious local delivery control plane. It now has stronger branch-custody rules, structured step attestations in PR bodies, evidence publication to an orphan branch, local review-eval tooling, provider-specific identity routing, richer AXI/TOON surfaces for agents, and broader agent/provider support.

Verdict: deploy candidate for personal or sandboxed team use, especially when the problem is turning agent-authored branches into PRs with durable review/test/CI evidence. The tool is much more mature than the June review, but its default posture is still high-trust local automation. Treat the repo/worktree, local agent credentials, transcript readers, and telemetry settings as part of the security boundary.

## What It Does

The core workflow is:

1. `no-mistakes init` records the real upstream remote and adds a managed `no-mistakes` remote.
2. A push to `no-mistakes` lands in a local bare proxy repo instead of going straight to the upstream.
3. A post-receive hook notifies the daemon.
4. The daemon creates an isolated worktree for the pushed branch and starts a pipeline run.
5. Steps run in order: intent, rebase, review, test, document, lint, push, PR, and CI.
6. Findings can be auto-fixed, approved, skipped, or escalated through the TUI, CLI, or agent-facing AXI interface.
7. When the pipeline passes, it forwards the branch, creates/updates the PR, appends deterministic evidence sections, monitors CI, and applies bounded repairs when continuity can be proven.

The README now presents three entry points: explicit `git push no-mistakes`, the interactive `no-mistakes` TUI/wizard, and the `/no-mistakes` agent skill for task-first or validate-existing-work flows.

## Architecture

### Local Git Gate

`internal/gate`, `internal/git`, `internal/worktrees`, and `internal/custody` handle proxy repo setup, hook installation, worktree safety, and branch/ref ownership. The gate preserves the low-friction git UX while keeping validation outside the developer's working tree.

The newer branch-sync/custody code is the biggest architectural improvement since the prior review. The pipeline now has explicit rules for when it may publish a rebased or CI-repaired generation, when it must revalidate from Review, and how it recovers custody after daemon restarts or interrupted remote operations.

### Daemon, Database, and IPC

`internal/daemon`, `internal/db`, and `internal/ipc` persist runs, steps, rounds, decisions, logs, agent invocations, build identity, intent sources, and event streams. The daemon has better process reaping, startup recovery, configurable worktree roots, and observable/bounded native-agent timeouts.

### Pipeline and PR Evidence

The pipeline has become more evidence-oriented:

- structured step attestations are appended to PR bodies;
- test evidence moved out of system temp storage;
- failed host permissions can be surfaced as test evidence;
- CI repair is revalidated or routed through safer review paths when continuity cannot be proven;
- PR enforcement moved into a reusable GitHub Action under `.github/actions/require-no-mistakes`.

That moves the project closer to the right model: the agent may draft and repair, but the system records the chain of custody and publishes machine-checkable evidence.

### Agent Adapters

Adapters now cover Claude, Codex, OpenCode, Rovo Dev, Pi, Grok, Antigravity, GitHub Copilot CLI transcript intent, and ACP targets through `acpx`. There is also richer model/effort configuration, fallback ordering, session reuse for fixer loops, native timeout handling, and structured-output parsing for more agent wire formats.

The caveat remains important: documented defaults still include broad native permissions unless overridden. Claude defaults can include `--dangerously-skip-permissions`; Codex defaults can include `--dangerously-bypass-approvals-and-sandbox`; Grok can default to bypass-style permission mode. This is not a reason to dismiss the tool, but it is a deployment decision, not a footnote.

### Evaluation and Dogfooding

Since the first review, the repo added local review-eval tooling under `internal/eval`, eval commands/docs, auto-capture of decided review rounds, holdout/gold labeling, dashboards, and dogfood contract tests. This is a strong maturity signal because the project is now measuring its own review behavior instead of relying only on anecdotes.

## Strengths

- **Git-native UX:** `git push no-mistakes` remains the sharpest adoption hook.
- **Local-first durable state:** daemon, DB, logs, worktrees, and evidence remain local unless explicitly published.
- **Better custody model:** rebases, fixer commits, CI repairs, and remote updates now have explicit provenance and recovery rules.
- **Broader provider support:** agent and SCM coverage both expanded materially.
- **Agent-facing control surface:** `no-mistakes axi` gives agents a non-interactive protocol instead of requiring TUI scraping.
- **PR evidence discipline:** deterministic sections and attestations reduce reliance on agent prose.
- **Self-evaluation:** the new eval subsystem gives the project a way to measure review finding quality over time.
- **Strong test posture:** local normal Go tests, e2e tests, and vet passed in this review.

## Caveats

- **Broad agent permissions by default:** configure agent args explicitly before sensitive use.
- **Transcript intent extraction is sensitive:** recent local coding-agent transcripts can be read for intent inference when enabled.
- **Telemetry is compiled into release builds:** disable or redirect it intentionally if needed.
- **Local gate is not server enforcement:** branch protection and/or the no-mistakes PR enforcement action still matter.
- **Fast-moving surface:** 33 minor/patch releases since the June review is good velocity, but it means configuration/docs should be checked before each serious rollout.
- **High open-issue count:** the project is much more popular now, and issue volume has caught up with that visibility.

## Reusable Patterns

- **Local git remote as delivery gate:** intercept delivery with a local bare repo and daemon-backed post-receive flow.
- **Branch custody ledger:** publish only when the pipeline can prove the generation still descends from reviewed work.
- **Deterministic PR appendices:** let agents draft prose, but append evidence from structured run state.
- **Candidate finding decisions:** preserve selected findings, declined decisions, fix rounds, and approval sources across reruns.
- **Local review eval corpus:** turn decided review rounds into replayable eval cases without changing the original pipeline outcome.

See also: [local-git-remote-validation-gate.md](../patterns/local-git-remote-validation-gate.md)

## Verification

Local checks run on 2026-08-30:

```bash
umask 022 && go test ./...
go vet ./...
go test -tags e2e ./internal/e2e/...
```

Results:

- `go test ./...` passed under `umask 022`.
- `go vet ./...` passed.
- `go test -tags e2e ./internal/e2e/...` passed in 335.993s.

Under this review shell's restrictive `umask 077`, two `internal/update` permission fixture tests failed because `os.WriteFile(..., 0751)` created `0700` files before the replacement code ran. The same package passed under `umask 022`, so this is a test-environment assumption rather than a functional failure observed in the update code.

Repository metadata at review time:

- Stars: 8,133
- Forks: 828
- Open issues: 164
- Latest tag: `v1.60.3`
- Latest reviewed commit: `80b78bccb8bd03a9878d132f98f27ad7a5a15afa`
- License: MIT

## Adoption Notes

Good first pilot:

1. Use a disposable or non-sensitive repo first.
2. Set explicit agent args for the sandbox/approval model you want.
3. Decide whether transcript-based intent extraction is acceptable.
4. Set telemetry policy before release use.
5. Keep branch protection or the no-mistakes enforcement action as the non-bypassable layer.
6. Inspect PR evidence and CI repair behavior before trusting unattended operation.

This remains one of the best examples of packaging agent review, fix, test, PR creation, and CI repair behind an interface developers already understand: git.
