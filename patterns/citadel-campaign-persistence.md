# Campaign Persistence Pattern

**Source:** [SethGammon/Citadel](https://github.com/SethGammon/Citadel) (MIT)
**Pattern type:** Multi-session state management for AI agents

## Problem

AI agent sessions are stateless. Multi-day work (architecture overhauls, large refactors, incident investigations) loses context at session boundaries. Users manually re-explain decisions, progress, and blockers every session.

## Solution

Use a structured markdown file as the single source of truth for multi-session work. Every session is amnesiac — it reads the campaign file to rebuild context, executes, then updates the file before closing. No database, no external state store.

## Format

```markdown
# Campaign: {Name}

Status: active | paused | complete
Direction: {original user request, verbatim}

## Claimed Scope
- src/auth/
- src/middleware/

## Phases
1. [complete] Research: Audit existing auth module
2. [in-progress] Build: Implement token rotation
3. [pending] Verify: Integration tests + compliance check

## Feature Ledger
| Feature | Status | Phase |
|---------|--------|-------|
| Token rotation | built | 2 |
| Session store migration | blocked | 2 |

## Decision Log
- 2026-04-01: Chose opaque tokens over JWT (Reason: compliance C-447 requires server-side revocation)
- 2026-04-02: Fell back to Postgres from Redis for session store (Reason: Redis adapter incompatible with new token format)

## Active Context
Currently implementing token rotation in src/auth/tokens.ts.
Session store migration blocked on Redis adapter fix.

## Continuation State
Phase: 2
Sub-step: token rotation implementation
Files modified: src/auth/middleware.ts, src/auth/tokens.ts
Blocking: Redis adapter compatibility
checkpoint-phase-1: stash@{0}
```

## Key Design Decisions

**Why markdown, not JSON/YAML/database:**
- Human-readable and human-editable (users can inspect and fix state)
- No schema migrations
- Diffs are meaningful in git
- No external dependencies
- Structured enough for machine parsing via section headers

**Why amnesiac sessions:**
- No context window bloat from accumulated session history
- State machine is explicit and inspectable
- Failed sessions don't corrupt persistent state (file only updated on success)
- Any session can pick up any campaign — no session affinity

**Why phases with machine-verifiable end conditions:**
- Prevents drift: each phase has a concrete exit criterion
- Enables progress tracking without human judgment
- Supports automatic resumption: read the continuation state, find the next pending phase

## Implementation Notes

- Campaign files live in a `.planning/campaigns/` directory
- One file per campaign, named by slug: `auth-middleware-rewrite.md`
- Git stash checkpoints (`stash@{N}`) enable rollback to any phase boundary
- Scope claims (directories the campaign will modify) prevent parallel campaigns from conflicting
- The decision log is append-only — never edit past decisions, only add new ones

## When to Use

- Any multi-session agent work (>1 hour estimated)
- Work that spans multiple days or has natural pause points
- Tasks where decisions compound (each choice constrains future choices)
- Parallel agent coordination (scope claims prevent conflicts)

## When Not to Use

- Single-session tasks (just do them)
- Exploratory work with no clear phases
- Tasks where the user wants to manually direct every step

---

**Attribution:** SethGammon/Citadel, MIT License
