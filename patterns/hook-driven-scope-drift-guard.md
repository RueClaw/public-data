# Hook-Driven Scope Drift Guard

**Source:** ArchAstro/scopey  
**Repo:** https://github.com/ArchAstro/scopey  
**License:** MIT  
**Extracted:** 2026-08-01  

## Pattern

Use agent lifecycle hooks to maintain a current user-scope record, journal meaningful tool activity, and inject reminders or corrections only when the run's observed trajectory drifts from that scope.

The guard is advisory, not a sandbox. It keeps long-running agents pointed at the human's current intent without owning model routing, provider credentials, or tool authorization.

## Core Structure

1. Install hooks at user-prompt, session-start, post-tool, and stop boundaries.
2. Store session state by stable session id, not working directory.
3. On each user prompt, summarize the active scope as a mutation of prior scope.
4. Treat explicit remove, replace, and contradiction as authoritative.
5. Journal tool calls with bounded argument previews and a meaningful-tool counter.
6. Exclude noise tools such as waits, stdin polling, list calls, and token counters from judgement windows.
7. Every N meaningful tools, spawn a background judge over the latest window.
8. Persist the judgement as pending/ready/injected/failed state.
9. Inject ready warning/off-track judgements at the next safe hook boundary.
10. Expire stale judgements so old advice cannot steer a much later run.

## Design Rules

Keep hook handlers fast. Do local parsing, state update, and persistence on the hook path; run model calls in detached background jobs.

Prevent recursive observation. Every child process spawned by the guard should set internal environment variables that make hooks no-op. Without this, the summarizer or judge can be mistaken for the agent being judged.

Use single-flight controls. A per-session lock, minimum job interval, and global job cap prevent process storms when hooks fire rapidly.

Prefer structured tool evidence over raw transcript tails. Raw JSONL tails often end in terminal dumps or internal status events. A bounded journal of tool name, preview, timestamp, and index is easier to judge and easier to explain.

Normalize missing evidence. A judge result that says the transcript is unavailable or there are no tool actions should become `insufficient_evidence`, not `off_track`.

## Why It Works

Agent scope drift usually emerges through actions, not declarations. A model might claim it is still focused while it edits unrelated files, chases optional cleanup, or continues debugging after the requested fix is complete.

A hook-driven guard sees the operational boundary: user prompt, tool batches, and stop. That is enough to remind the agent of the current scope without requiring a new agent runtime.

## Caveats

This pattern does not enforce security policy. The agent can still call any tool the harness allows. Use separate permission, sandbox, and credential controls for hard boundaries.

Injected corrections can lag by design. If judgement runs every N tools and injects at the next hook boundary, the agent may perform additional work before seeing the correction.

Session logs are sensitive. They may include prompts, tool argument previews, file paths, and judgement summaries.

Harness hook contracts change. Keep installers small, test hook payload normalization, and provide uninstall paths.

---

**Attribution:** Based on ArchAstro/scopey, MIT License.
