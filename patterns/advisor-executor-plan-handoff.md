# Advisor-Executor Plan Handoff

**Source:** https://github.com/shadcn/improve  
**License:** MIT  
**Extracted:** 2026-06-20  
**Use when:** A strong model should audit, prioritize, and specify work, while a separate cheaper or sandboxed executor performs the actual edits.

## Pattern

Separate the senior-advisor role from the code-editing role.

The advisor:

- reads the repository and intent docs
- identifies and vets findings with file/line evidence
- prioritizes by impact, effort, risk, and confidence
- writes one self-contained plan per selected finding
- does not edit source code

The executor:

- starts from the plan, not the advisor transcript
- runs the plan's drift check before touching files
- edits only in the declared scope
- runs every verification gate
- stops instead of improvising when STOP conditions trigger

The plan is the contract between the two.

## Plan Contents

A useful handoff plan should include:

- source commit or version it was written against
- mechanical drift check
- why the work matters
- exact files in scope
- files explicitly out of scope
- current-state excerpts from the code
- repo conventions to follow
- ordered implementation steps
- test plan
- verification commands with expected success signals
- done criteria
- STOP conditions
- maintenance and reviewer notes

## Why It Works

Coding-agent failures often happen at the boundary between "understood the problem" and "edited the code." A strong model may understand the system, but a cheaper executor or later human does not inherit that session context. Making the plan self-contained turns understanding into an artifact that can be reviewed, scheduled, retried, and audited.

The read-only advisor boundary also reduces blast radius. Review and planning can happen broadly; mutation happens later in a narrower, disposable, or better-supervised context.

## Caveats

- Host tooling must actually enforce the advisor's read-only role.
- Plans can go stale; commit-stamped drift checks are mandatory.
- Do not publish plans as public issues when they contain sensitive security details.
- The advisor must vet findings itself before writing plans. Subagent reports are leads, not facts.

## Attribution

Pattern extracted from `shadcn/improve`, MIT License.
