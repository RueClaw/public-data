# Test-Driven Development Pattern

> Extracted from [obra/superpowers](https://github.com/obra/superpowers) (MIT License, Jesse Vincent)

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? **Delete it.** Start over. No exceptions.
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

## Red-Green-Refactor

### RED — Write Failing Test
- One behavior per test
- Clear name describing behavior ("and" in name? Split it)
- Real code, not mocks (unless unavoidable)

### Verify RED — Watch It Fail (MANDATORY)
- Test fails (not errors)
- Failure message is expected
- Fails because feature is missing, not typos
- Test passes immediately? You're testing existing behavior. Fix the test.

### GREEN — Minimal Code
- Simplest code to pass the test
- Don't add features, refactor, or "improve" beyond what the test requires
- YAGNI — You Aren't Gonna Need It

### Verify GREEN — Watch It Pass (MANDATORY)
- Test passes
- All other tests still pass
- Output pristine (no errors, warnings)

### REFACTOR — Clean Up
- Only after green
- Remove duplication, improve names, extract helpers
- Keep tests green. Don't add behavior.

## Why Order Matters

| Claim | Reality |
|-------|---------|
| "I'll write tests after" | Tests passing immediately prove nothing. You never saw it catch the bug. |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run, easy to forget cases. |
| "Deleting X hours of work is wasteful" | Sunk cost fallacy. Keeping unverified code is technical debt. |
| "TDD is dogmatic, I'm being pragmatic" | TDD IS pragmatic. Finds bugs before commit, prevents regressions, enables refactoring. |
| "Tests after achieve the same goals" | Tests-after: "what does this do?" Tests-first: "what SHOULD this do?" Tests-after are biased by your implementation. |
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "Need to explore first" | Fine. Throw away exploration, then start with TDD. |

## Verification Checklist

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check all boxes? You skipped TDD. Start over.

## Bug Fixes

Bug found? Write failing test reproducing it. Follow TDD cycle. Test proves fix and prevents regression. Never fix bugs without a test.
