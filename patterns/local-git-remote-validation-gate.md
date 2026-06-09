# Local Git Remote Validation Gate

**Extracted from:** https://github.com/kunchenguid/no-mistakes  
**Author:** Kun Chen / kunchenguid  
**License:** MIT  
**Reviewed:** 2026-06-09

## Pattern

Place a local git remote in front of the real upstream. Developers push to the local remote. A managed bare repository receives the push, triggers a post-receive hook, and starts an asynchronous validation pipeline in a disposable worktree. Only after review, tests, fixes, push, PR creation, and CI monitoring succeed does the system forward work into the normal collaboration path.

This gives autonomous coding agents a delivery checkpoint without requiring developers to learn a new submission protocol. The interface stays `git push`, but the delivery path gains structured review, state, logs, and approval gates.

## When To Use

Use this when:

- developers or coding agents already work through git branches;
- validation can take longer than an ordinary pre-push hook should block;
- the system needs disposable worktrees, persistent run state, and retry/fix loops;
- the delivery gate should be local-first and reversible;
- PR creation and CI monitoring are part of the acceptance workflow.

Do not use it as the only production safety control. Keep server-side branch protection, required CI checks, and repository permissions in place.

## Shape

1. `init` discovers the real upstream and adds a local managed remote.
2. The managed remote points at a local bare repository.
3. The bare repository has a post-receive hook.
4. The hook notifies a daemon and exits successfully.
5. The daemon creates an isolated worktree for the pushed branch.
6. A pipeline records each step, round, finding, approval, fix attempt, and log.
7. Human or agent-facing control surfaces approve, fix, skip, abort, or rerun.
8. Delivery steps push upstream, open/update a PR, append deterministic evidence, and watch CI.

## Implementation Notes

- Keep the hook script small and deterministic.
- Quote binary paths before embedding them in shell.
- Isolate `core.hookspath` for the managed bare repo so unrelated repo tooling cannot silently disable the gate.
- Make setup idempotent and teardown complete.
- Store run state in a local database rather than only in logs.
- Keep step logs on disk and stream events over a narrow IPC protocol.
- Run validation in a worktree separate from the user's current checkout.
- Treat agent-written PR prose as draft content, then append deterministic state-derived sections for risk, tests, and pipeline results.
- Make broad agent permissions explicit in configuration, especially for local tools that can edit files, run commands, or access credentials.

## Benefits

- Git-native developer UX.
- Reversible local installation.
- Long-running validation without blocking normal shell interaction.
- Cleaner separation between "push accepted locally" and "work delivered upstream."
- Durable evidence for review and CI.
- Same control plane can serve a TUI, CLI, or another agent.

## Risks

- A local gate can be bypassed unless the remote repository enforces branch protection.
- Asynchronous hooks may create user confusion if "push succeeded" is interpreted as "review passed."
- Agent fix loops need bounded attempts and durable audit trails.
- Local transcript reading, telemetry, and provider CLI auth can widen the privacy/security boundary.
- Dangerous agent execution flags are powerful and should be scoped to disposable worktrees or trusted repos.

## Minimal Checklist

- [ ] Local bare repo with managed post-receive hook
- [ ] Idempotent install/eject commands
- [ ] Disposable worktree per run
- [ ] Persistent run/step/finding database
- [ ] Streaming logs and subscription events
- [ ] Approval actions: fix, approve, skip, abort
- [ ] Bounded auto-fix limits
- [ ] Deterministic PR evidence sections
- [ ] CI monitoring with timeout and provider-specific checks
- [ ] Server-side branch protection outside the local gate
