# Ledger-Backed Compaction Memory

**Source:** https://github.com/elpapi42/pi-observational-memory  
**Reviewed:** 2026-06-06  
**License context:** MIT. This is an architecture summary with attribution, not copied implementation.

## Pattern

Represent long-session memory as append-only ledger entries rather than as a chain of recursively summarized text. During the session, background workers record concrete observations and distill durable reflections. When context compaction happens, fold the ledger deterministically and render a compact memory summary without making a fresh model call.

The core entry types are:

- observations recorded;
- reflections recorded;
- observations dropped or tombstoned.

Observations cite source entry ids. Reflections cite supporting observation ids. Drops remove observations from the active pool without deleting the historical record.

## Why It Matters

Compaction often happens at the worst possible time: the work is long, the context is dense, and the system is under pressure. Asking a model to summarize everything at that moment is slow and brittle.

A ledger-backed memory layer moves the expensive judgment earlier. The compaction path becomes deterministic: fold valid memory entries, apply token budgets, and render the active observations/reflections. That reduces latency and limits summary-of-summary drift.

## Implementation Notes

- Keep source entries, memory entries, and compaction entries distinct.
- Treat memory entries as records with ids, not just prose.
- Reject invalid memory records instead of trying to repair them during compaction.
- Use tombstones for dropped observations so history remains auditable.
- Keep a narrow recall tool for source evidence behind a memory id.
- Do not let background memory work block the compaction hook.

## Good Fit

- Coding-agent sessions that run for days.
- Review or research pipelines where shared links, completed work, and interruptions must survive restarts.
- Agent runtimes that already have append-only session events.
- Systems where compact memory must remain traceable to raw evidence.

## Poor Fit

- Short chat sessions where ordinary summaries are enough.
- Runtimes without stable source entry ids.
- Memory systems that need global cross-user retrieval rather than session-local continuity.

---

**Attribution:** Pattern derived from the public architecture of `elpapi42/pi-observational-memory`.
