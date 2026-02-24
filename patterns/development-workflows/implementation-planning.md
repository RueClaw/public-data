# Implementation Planning Pattern

> Extracted from [obra/superpowers](https://github.com/obra/superpowers) (MIT License, Jesse Vincent)

## Core Principle

Write plans for "an enthusiastic junior engineer with poor taste, no judgment, no project context, and an aversion to testing."

If the plan requires interpretation, it's not detailed enough.

## Full Workflow

```
1. BRAINSTORM — Socratic refinement before coding
   → Ask what you're really trying to do
   → Explore alternatives
   → Present design in digestible chunks
   → Get sign-off before proceeding

2. PLAN — Break into bite-sized tasks
   → 2-5 minutes each
   → Exact file paths
   → Complete code to write
   → Verification steps for each task

3. EXECUTE — Subagent-driven or batch
   → Fresh agent per task (no context pollution)
   → Two-stage review after each (spec then quality)
   → OR batch execution with human checkpoints

4. REVIEW — Between tasks
   → Review against plan
   → Report issues by severity
   → Critical issues block progress

5. FINISH — When tasks complete
   → Verify all tests pass
   → Options: merge / PR / keep / discard
   → Clean up worktree
```

## Task Specification Format

Each task should include:
- **What:** Clear description of the change
- **Where:** Exact file paths to create/modify
- **How:** Complete code or precise instructions
- **Verify:** How to confirm it works (test command, expected output)
- **Context:** What the task depends on, what depends on it

## Key Rules

- Tasks should be independent where possible
- Each task should be completable by someone with zero project context
- Emphasize TDD — RED-GREEN-REFACTOR for every task
- YAGNI — don't plan features you don't need yet
- DRY — but only when you see actual duplication, not predicted duplication
- Plan should be a file that can be read by subagents

## Git Worktree Isolation

Before starting any implementation:
1. Create isolated git worktree on a new branch
2. Run project setup in the worktree
3. Verify clean test baseline (all existing tests pass)
4. Work in isolation — no conflicts with other work
