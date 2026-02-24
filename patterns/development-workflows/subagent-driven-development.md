# Subagent-Driven Development Pattern

> Extracted from [obra/superpowers](https://github.com/obra/superpowers) (MIT License, Jesse Vincent)

## Core Principle

Fresh subagent per task + two-stage review (spec compliance then code quality) = high quality, fast iteration.

## Why Fresh Subagents?

- No context pollution between tasks
- Each agent starts clean with exactly the context it needs
- Parallel-safe (agents don't interfere)
- Agent can ask questions before and during work

## The Process

```
For each task in plan:
  1. DISPATCH implementer subagent with full task text + context
  2. Implementer asks questions? → Answer, then proceed
  3. Implementer implements, tests, commits, self-reviews
  4. DISPATCH spec reviewer subagent
     → Does code match the spec? Nothing missing? Nothing extra?
     → If NO: implementer fixes → spec reviewer re-reviews → loop until ✅
  5. DISPATCH code quality reviewer subagent
     → Is the code well-built? Clean? Maintainable?
     → If NO: implementer fixes → quality reviewer re-reviews → loop until ✅
  6. Mark task complete

After all tasks:
  DISPATCH final code reviewer for entire implementation
  → Finish development branch (merge/PR/keep/discard)
```

## Two-Stage Review (Critical)

**Stage 1: Spec Compliance** — "Did we build what we said we'd build?"
- All requirements met?
- Nothing missing from spec?
- Nothing extra added (YAGNI)?

**Stage 2: Code Quality** — "Is what we built any good?"
- Clean, maintainable code?
- Good test coverage?
- No magic numbers, proper naming?

**Order matters.** Spec compliance FIRST. Don't polish code that doesn't meet the spec.

## Key Rules

- Never skip reviews (spec OR quality)
- Never proceed with unfixed issues
- Don't dispatch multiple implementers in parallel (conflicts)
- Don't make subagent read plan file (provide full text instead)
- If reviewer finds issues → implementer fixes → reviewer re-reviews → repeat until approved
- If subagent fails task → dispatch fix subagent with specific instructions (don't fix manually — context pollution)

## Cost vs Value

**More expensive:** implementer + 2 reviewers per task, review loops add iterations.
**But:** catches issues early (cheaper than debugging later), prevents drift AND quality decay, spec compliance prevents over/under-building.
