# pi-codex-goal (fitchmultz/pi-codex-goal)

**Repo:** https://github.com/fitchmultz/pi-codex-goal  
**License:** MIT. Permissive reuse with attribution.  
**Reviewed:** 2026-06-06  
**Stack:** TypeScript, Pi extension API, Node test runner, Crabbox platform smoke tests  
**What it is:** A Pi extension that adds Codex-style session goals, model-callable goal tools, hidden continuations, token/elapsed-time accounting, and recovery behavior for long-running agent tasks.

---

## Verdict

✅ **Deploy candidate for Pi users who want goal-following behavior inside long sessions.** The package is small, focused, and much more carefully tested than most agent add-ons: 305 local tests pass, typecheck passes, production audit is clean, and the release gate tests packed installs plus real model-backed goal runs across macOS, Ubuntu, and native Windows. The main caveat is tight coupling to Pi's extension/session lifecycle, so the ideas are portable but the package itself is for Pi.

---

## What It Is

`pi-codex-goal` brings the Codex goal pattern into Pi. It registers a `/goal` command, a `/create-goal` prompt template, and three model-callable tools: `get_goal`, `create_goal`, and `update_goal`. The goal is stored in Pi session custom entries, so it survives session reload, resume, tree navigation, fork, and compaction without a separate database.

The package is not just a task label. While a goal is active it tracks elapsed active time, counts completed assistant input/output tokens, marks budget-limited goals, sends hidden follow-up continuations when the agent is idle, and suppresses stale queued continuations after a goal is completed, cleared, replaced, or interrupted.

The interesting part is how much defensive lifecycle work exists around a small public surface. The repo handles aborted turns, compaction boundaries, provider errors, context overflow recovery, delayed terminal events, stale continuation prompts, and usage coalescing so goal state does not corrupt itself during long sessions.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Pi extension API via `@earendil-works/pi-coding-agent` |
| Language | TypeScript ESM |
| Commands | `/goal`, `/create-goal` prompt template |
| Model tools | `get_goal`, `create_goal`, `update_goal` |
| Persistence | Pi custom session entries |
| State machines | Goal transition planner, recovery machine, stale queued-work reducer |
| Release checks | TypeScript, Node test runner, Crabbox platform smoke tests |
| Package | npm package, optional Pi peer dependencies |

## Key Features

### Session-native goal state

Goal snapshots and compact runtime usage updates are appended as Pi custom entries. Reconstruction walks the session branch, applies set/clear entries, and accepts runtime usage entries only when they are for the current goal and do not rewind status or usage. That makes the goal follow Pi's own history model instead of introducing an external store.

### Hidden continuation scheduler

When a goal is active and Pi is idle, the extension queues hidden follow-up messages to keep work moving. It tracks which goal has a queued continuation, waits through pending messages, cancels scheduled continuations on completion/replacement, and compacts older active continuations into bookkeeping markers so provider context does not fill with repeated goal prompts.

### Stale work guard

The stale queued-work reducer is the repo's most defensive subsystem. It detects hidden goal work that belongs to an old goal, aborts stale-only launches, skips late terminal events, and avoids charging old turn tokens to a replacement goal. This is the right kind of machinery for agent runtimes, where terminal events can arrive late or overlap with a new user-driven turn.

### Recovery behavior

Provider errors do not trigger blind hidden retry loops. Context overflow is left to Pi's host compaction/retry path first, transient errors surface pending attention, and repeated unrecoverable failures pause the goal with resume guidance. Terminal provider-limit errors pause immediately instead of pretending host retry will fix them.

### Cross-platform release smoke

The platform smoke gate packs the npm package, installs the packed artifact into a clean Pi project, verifies `pi list`, and runs a real model-backed goal-tool smoke on macOS, Ubuntu Linux, and native Windows. It also records artifacts, redacts forwarded secrets, and fails cleanup issues instead of hiding them.

## Architecture

The code is split around lifecycle ownership:

```text
src/index.ts
  -> goal-runtime-controller.ts
  -> tools.ts / commands.ts / goal-runtime-events.ts
  -> goal-state-controller.ts / goal-transition.ts / goal-persistence.ts
  -> continuation-scheduler.ts / stale-queued-work-* / recovery-*
```

The strongest architectural choice is that transitions are planned before side effects. `goal-transition.ts` validates allowed state changes, returns persistence decisions, and lists effects such as clearing continuation state, accounting, recovery, and budget warnings. That keeps the command/tool/event handlers from scattering ad hoc lifecycle mutations.

The package also treats provider-context rewriting as part of the runtime contract. Stale continuations are rewritten to non-runnable bookkeeping messages, older active continuations are superseded, and pasted continuation-marker text from normal user input is allowed through. That distinction is easy to get wrong and well covered by tests here.

## Comparison

| Aspect | pi-codex-goal | pi-observational-memory | Oh My Pi |
|--------|---------------|-------------------------|----------|
| Primary role | Goal tracking and continuation for Pi sessions | Long-session memory across compaction | Full local coding-agent harness |
| Persistence | Pi custom goal entries | Pi custom memory ledger entries | Session/runtime systems across a larger CLI |
| Best pattern | Lifecycle-safe hidden goal continuation | Ledger-backed compaction memory | Broad IDE/native coding-agent tool surface |
| Main caveat | Pi-specific extension lifecycle | Pi-specific and memory-model dependent | Large operational surface |

## Self-Hosting Notes

Install through Pi:

```sh
pi install npm:pi-codex-goal
```

The reviewed release is `0.1.24`, verified by the author against Pi `0.78.1`. The Pi runtime peer dependencies are optional wildcards, so npm does not hard-block newer Pi releases, but runtime behavior should be treated as verified against the documented baseline until a later package release says otherwise.

Local verification on 2026-06-06:

- Reviewed commit: `d80c67129f0ca3bcd1ac1e48965f84416ca49f5c`.
- GitHub metadata: 119 stars, 7 forks, 0 open issues, pushed 2026-06-04.
- `npm ci`: passed with 0 reported vulnerabilities.
- `npm test`: passed, 305/305 tests.
- `npm run typecheck`: passed.
- `npm audit --omit=dev`: 0 vulnerabilities.
- No GitHub Actions workflows were present in the repo; release validation is documented as a local Crabbox smoke gate.

---

**Attribution:** fitchmultz/pi-codex-goal, MIT.
