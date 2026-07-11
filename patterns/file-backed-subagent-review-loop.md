# File-Backed Subagent Review Loop

**Source:** obra/superpowers  
**Repo:** https://github.com/obra/superpowers  
**License:** MIT  
**Reviewed:** 2026-07-11  

## Pattern

For multi-agent coding work, move the task contract, diff, implementer report, review package, verdicts, and progress state into workspace files instead of passing everything through the parent agent's chat context.

The parent agent acts as coordinator. Implementer and reviewer agents read bounded artifacts from disk, write their reports back to disk, and the parent advances from a progress ledger.

## Why It Helps

Chat-context handoffs are expensive and easy to distort. Pasted diffs stay in the session forever, task text gets paraphrased, and a parent agent that wants progress can accidentally coach reviewers around real defects.

File-backed handoffs give each participant the same durable evidence:

- task brief;
- relevant diff or review package;
- implementer report with test evidence;
- reviewer verdicts;
- progress ledger;
- final review package.

This makes long-running work cheaper to resume and easier to audit.

## Shape

```text
.agent-work/
  task-briefs/
    task-001.md
  implementer-reports/
    task-001.md
  review-packages/
    task-001.diff
  reviewer-verdicts/
    task-001.md
  progress-ledger.md
```

The exact directory name is not important. Use a git-ignored, per-worktree location so generated coordination artifacts do not enter product commits.

## Review Rules

The reviewer should be read-only and should judge from artifacts, not from the controller's optimism. Strong rules:

- The controller cannot tell the reviewer what to ignore.
- The controller cannot pre-rate severity.
- Plan-mandated defects are still defects; the human decides whether to accept them.
- The reviewer should cite evidence from the diff or files.
- If the reviewer cannot verify a requirement from the diff, it should say so explicitly.

## When To Use

Use this for:

- subagent-driven development;
- long-running implementation plans;
- code review loops;
- bug fixes where root cause, patch, and verification need separate evidence;
- resumable agent jobs.

Avoid it for tiny one-file edits where the artifact overhead is larger than the task.

## Implementation Notes

- Create the artifact directory before dispatching the first worker.
- Write complete task briefs: objective, exact files, constraints, verification, and expected report path.
- Generate review packages from the actual diff, not a prose summary.
- Keep the progress ledger append-only enough to reconstruct what happened.
- Make the artifact directory self-ignoring or globally ignored.
- Run a final whole-branch review after task-level reviews pass.

---

**Attribution:** Derived from the subagent-driven-development design in obra/superpowers, MIT.
