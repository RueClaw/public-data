# Evidence-Bound Binary Critique Gate

**Source:** https://github.com/brandonsimpson/devils-advocate
**License:** MIT
**Reviewed:** 2026-05-24
**Category:** Agent review workflow, quality gates, planning discipline

---

## Pattern

Turn LLM critique into a binary gate with evidence requirements. Each criterion either passes or fails. Every failure must include:

- a concrete location such as file:line
- a short explanation of the issue
- a specific Fix: suggestion

If the reviewer lacks enough context to make a grounded judgment, it must refuse with a context-insufficient response instead of inventing a score.

## Why It Matters

LLM self-review often becomes soft reassurance. Percentage scores, "looks good overall," and vague risks are easy to ignore and hard to act on. A binary critique gate changes the shape of the output:

- no partial credit for unverified claims
- no failure without evidence
- no evidence without a fix path
- no critique when the artifact or codebase has not been read

This creates useful pressure without pretending the LLM is a proof engine.

## Core Mechanics

### 1. Separate Code and Plan Criteria

Use different checklists for code and plans.

Code criteria should cover correctness, security, quality, performance, consistency, integration, and architecture.

Plan criteria should cover requirement coverage, API verification, task ordering, testing strategy, rollback, dependencies, security design, and architectural fit.

### 2. Add a Context Gate

Before scoring, require the reviewer to confirm it has:

- read the relevant artifact
- understood the task
- explored enough project structure to know boundaries
- found something concrete to critique

If not, return a structured refusal that lists what is missing and what action is needed.

### 3. Add an Independence Gate

If the same model/session authored the artifact, route critique to an independent reviewer when available. The independent reviewer should see only the artifact, project files, and criteria, not the author's reasoning.

If independent review is unavailable, mark the critique as self-review and warn about author bias.

### 4. Discover Local Standards

Before evaluating, read local standards and architectural hints:

- CLAUDE.md, AGENTS.md, or equivalent project guidance
- ADRs and architecture decision files
- nearby utilities and helper patterns
- dominant implementation conventions
- boundary markers such as service layers, API clients, repository modules, and barrel exports

A change that violates a dominant local pattern should fail the relevant consistency or architecture criterion.

### 5. Log Results

Persist a compact session log and detailed critique files. Include git SHA, timestamp, target, pass/fail count, and links to detailed logs. This makes review quality auditable over time and lets teams correlate critique quality with specific commits.

## Output Shape

Use a predictable shape:

```text
DEVIL'S ADVOCATE CRITIQUE (Binary Eval)

Target: <artifact or change>

Correctness:
  tests-pass .... PASS - <evidence>
  edge-cases .... FAIL - <file:line evidence>
                    Fix: <specific fix>

Result: 18/20 PASS - 2 criteria need fixing

Failing criteria with fixes:
1. edge-cases: <fix>
2. no-regressions: <fix>

Unverified:
- <what was not checked>
```

## Implementation Notes

Keep hooks non-blocking at first. A pre-commit reminder can nudge users to run critique without breaking workflows. A plan-file hook can suggest critique after writing a design document.

Avoid turning the gate into bureaucracy. The pattern is valuable when the reviewer is forced to cite evidence; it becomes noise when it merely expands a checklist.

## Caveats

This is not a replacement for tests, typechecks, linters, security scanners, or human review. It is a structured adversarial pass that catches omissions and weak assumptions before stronger verification runs.

Binary criteria can also over-penalize exploratory work. Scope-bound the critique: if a criterion does not apply to the requested change, mark it pass with a note rather than inventing an out-of-scope failure.

---

**Attribution:** brandonsimpson/devils-advocate, MIT

