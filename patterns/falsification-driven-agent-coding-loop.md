# Falsification-Driven Agent Coding Loop

**Source:** https://github.com/dsweet99/agent_coding
**License:** No license specified — pattern summary only; do not reuse source prompts or code verbatim without permission.
**Extracted:** 2026-06-07

## Pattern

Use a structured implement/review loop where code changes are produced by one agent session, reviewed by a separate fresh session, challenged through falsifiable hypotheses, and then repaired by the original implementation session until review success is explicit.

## Why It Matters

One-shot coding agents often satisfy local instructions while missing contract mismatches, edge cases, or architectural constraints. A separate reviewer session reduces shared-assumption drift. A falsification step turns vague review concerns into testable claims. A strict acceptance gate keeps the loop from silently treating partial approval as completion.

## Minimal Shape

1. Write or receive a plan file.
2. Run an implementer agent against that plan.
3. Run a fresh reviewer agent against the changed code and grounding/context.
4. If the reviewer returns exactly the agreed success token, stop.
5. Otherwise, ask the reviewer session to falsify its own concerns with concrete tests or evidence.
6. Feed the resulting concern file back into the implementer session.
7. Repeat with a loop limit.
8. Save plan, prompts, review output, and logs as run artifacts.

## Design Notes

- Keep the implementer session continuous so it retains context across fixes.
- Keep reviewer sessions fresh so they are less anchored to implementation choices.
- Use a precise success token, such as `LGTM`, to avoid ambiguous approval.
- Require concerns to cite evidence or include a minimal falsifying test.
- Preserve run artifacts for debugging the agent process itself.
- Bound the loop count so automation cannot spin forever.

## When To Use

- Coding tasks where correctness matters more than latency.
- Refactors with broad blast radius.
- Bug fixes with measurable reproduction commands.
- Agent evaluations where the process needs to be inspectable.

## Caveats

- The loop can burn tokens quickly.
- A weak reviewer can still rubber-stamp bad code.
- A strict success token helps orchestration but can hide nuance if the review prompt is poor.
- This pattern needs sandboxing and clear tool permissions if used outside a trusted local repo.

## Public Reuse Guidance

Because the source repository does not specify a license, treat this as a high-level pattern inspired by the public project. Reimplement from first principles for production use.

---

**Attribution:** Inspired by dsweet99/agent_coding.
