# Systematic Debugging Pattern

> Extracted from [obra/superpowers](https://github.com/obra/superpowers) (MIT License, Jesse Vincent)

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

Random fixes waste time and create new bugs. Quick patches mask underlying issues.

## The Four Phases

### Phase 1: Root Cause Investigation

**BEFORE attempting ANY fix:**

1. **Read error messages carefully** — don't skip. They often contain the exact solution. Read stack traces completely.
2. **Reproduce consistently** — can you trigger it reliably? If not reproducible, gather more data, don't guess.
3. **Check recent changes** — git diff, new deps, config changes, environmental differences.
4. **Gather evidence in multi-component systems** — log what enters/exits each component boundary. Run once to see WHERE it breaks.
5. **Trace data flow** — where does the bad value originate? Keep tracing up until you find the source. Fix at source, not symptom.

### Phase 2: Pattern Analysis

1. Find working examples of similar code in the same codebase
2. Compare against reference implementations — read every line, don't skim
3. Identify every difference, however small
4. Understand all dependencies and assumptions

### Phase 3: Hypothesis and Testing

1. **Form single hypothesis** — "I think X is the root cause because Y"
2. **Test minimally** — smallest possible change, one variable at a time
3. **Verify before continuing** — didn't work? Form NEW hypothesis. Don't stack fixes.

### Phase 4: Implementation

1. **Create failing test case** before fixing
2. **Single fix** — one change at a time, no "while I'm here" improvements
3. **Verify** — test passes, no other tests broken
4. **If 3+ fixes failed** — STOP. Question the architecture. This is not a failed hypothesis, it's a wrong architecture. Discuss with your team before attempting more fixes.

## Red Flags — STOP and Return to Phase 1

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "I don't fully understand but this might work"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before tracing data flow
- Each fix reveals a new problem in a different place

## Impact

- Systematic approach: 15-30 minutes to fix
- Random fixes approach: 2-3 hours of thrashing
- First-time fix rate: 95% vs 40%
- New bugs introduced: Near zero vs common
