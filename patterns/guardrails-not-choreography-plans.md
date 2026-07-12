# Guardrails-Not-Choreography Plans

> Extracted from [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) by Every / Kieran Klaassen and Trevin Chow (MIT License).

## Pattern

For agent-executed engineering work, use plans as decision artifacts rather than implementation scripts.

A good plan captures:

- decisions already made and why they matter
- scope boundaries and explicit non-goals
- stable implementation-unit IDs that do not renumber
- expected files or surfaces, without forcing exact APIs
- verification scenarios for happy paths, edge cases, failures, and integration
- risks, dependencies, and launch-blocking open questions

The executor then decides the actual code shape, commands, method signatures, and sequencing with the current repository in view.

## Why It Works

Agent plans often fail by being over-specific too early. Exact signatures, shell choreography, and pseudo-code can be stale before execution starts. Decision constraints age better: they tell a later human or agent what must remain true without freezing the implementation.

Stable unit IDs are the other important part. If a plan uses `U1`, `U2`, and `U3`, those identifiers should survive reordering and splitting. This keeps review comments, task logs, commits, and resumptions anchored to the same work even as the plan evolves.

## Reuse

Use this pattern when:

- work may span more than one session
- a different agent or human may execute the plan
- the codebase is moving while planning happens
- review, PR, or ticket references need stable anchors
- the task has real verification requirements

Avoid it for tiny one-step edits where a plan would add ceremony.

## Implementation Notes

- Put implementation decisions in the plan only when they are real product or architecture constraints.
- Keep exact code shapes out unless the API contract is already fixed.
- Treat the plan as read-only during execution; record progress in git, task state, or a separate execution log.
- Add a pre-execution check for whether each unit is already satisfied to support idempotent resume.

## Source Signals

Compound Engineering's `ce-plan` and `ce-work` skills state this boundary explicitly: `ce-plan` captures the "what" and execution guardrails, while `ce-work` owns the "how" with code in front of it.

**Attribution:** EveryInc/compound-engineering-plugin, MIT License.
