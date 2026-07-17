# Git-Derived Agent Worker Scope Gate

**Source:** procoders/superpowers-v  
**Repo:** https://github.com/procoders/superpowers-v  
**License:** MIT  
**Reviewed:** 2026-07-17  

## Pattern

Give each coding-agent worker a declared write scope, then verify the worker's actual changes from git before accepting the result. Treat the model's summary as human context only; the authoritative changed-file list comes from the repository.

## Core Contract

Each dispatched job should carry:

- a stable job id
- a backend or worker type
- an isolation mode
- a baseline commit
- `write_allowed` globs
- advisory `read_allowed` intent
- acceptance criteria
- a result schema with `status`, `files_changed`, `violations`, and `blocked`

The worker prompt can say "do not write outside scope," but the merge gate must verify it independently.

## Git Authority

Build the changed-file set from multiple git probes:

```text
changed =
  git diff --name-only --no-renames -z <baseline>
  UNION git ls-files --others --exclude-standard -z
  UNION git ls-files --others --ignored --exclude-standard -z -- .
```

Important details:

- Use NUL-delimited output so filenames with newlines do not split into fake paths.
- Diff against the pre-worker baseline, not a moving `HEAD`, so a worker that commits inside its worktree is still detected.
- Disable rename detection so both the deleted source and added destination surface.
- Include ignored files so writes to `dist/`, `.env`, `build/`, and similar paths are not invisible.
- Scan for symlinks that resolve outside the worktree and treat them as violations.
- Subtract pre-existing untracked/ignored files only in trusted serial direct mode; prefer fresh worktrees for untrusted or parallel jobs.

## Decision Rule

For every changed path, match it against `write_allowed`.

- If every changed path matches, the job may proceed to review/merge.
- If any path does not match, mark the job `blocked`, record `violations`, and do not merge it.
- If the gate cannot inspect the tree confidently, fail closed.

## Why It Works

Multi-agent coding fails when workers improvise outside their slice: shared files, generated outputs, ignored artifacts, hidden commits, and renames can all bypass a prose-only scope lock.

A git-derived gate turns the boundary into a mechanical check. It also makes lower-trust backends usable in a constrained way: even when a worker cannot be prevented from trying an out-of-scope edit, the orchestrator can refuse to merge the result.

## Caveats

This is a detection gate, not complete sandboxing. It cannot undo external side effects, network actions, or writes outside the repository that are not represented in the checked worktree. Pair it with real sandboxing where available, especially for untrusted tasks.

`read_allowed` is advisory. Git can verify writes, not what a worker read.

---

**Attribution:** Based on `scripts/compound-v-scope-check.py` and backend-launcher docs from procoders/superpowers-v, MIT License.
