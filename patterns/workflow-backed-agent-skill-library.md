# Workflow-Backed Agent Skill Library

**Source:** https://github.com/ragnar-pwninskjold/tech-snacks
**License:** MIT
**Reviewed:** 2026-06-07

## Pattern

Package agent procedures as installable skills, but move complex orchestration into workflow scripts. The skill becomes the activation contract: when to use it, what inputs are required, what must be read before acting, what must never be invented, and where outputs go. The workflow becomes the execution engine: fan-out, verification, ranking, token budgeting, durable artifacts, and isolated fix loops.

## Shape

```text
plugin/
  .claude-plugin/plugin.json
  skills/
    <skill>/
      SKILL.md
      references/
      templates/
      examples/
  agents/
    <domain>/
      <agent>.md
  workflows/
    <workflow>.workflow.js
```

## Why It Works

- The skill catalog stays small enough for routing.
- Detailed procedures load only when the user needs them.
- Templates preserve output shape without bloating the entry point.
- Workflow scripts handle stateful orchestration that Markdown instructions cannot make reliable.
- Refusal rules and qualification gates live near the user-facing skill, where the agent sees them before acting.

## Implementation Notes

Good skills in this pattern include:

- A narrow trigger in frontmatter.
- A clear opening move.
- Explicit phase boundaries.
- References that must be read before each phase.
- Output paths and resume behavior.
- What disqualifies weak outputs.
- A hard stop when the required external capability is missing.

Good workflows in this pattern include:

- Structured schemas for each phase.
- Stable IDs for durable records.
- Token or cost budgets.
- Separate discover, verify, synthesize, and write phases.
- Isolated worktrees or dry-run modes before mutating code.

## Best Fit

Use this for agent tasks that are repeated, high-context, and easy to drift:

- Code review campaigns.
- Project documentation mining.
- UX prompt generation.
- Research fan-out and verification.
- Skill or policy audits.

Avoid this for one-shot prompts or simple deterministic scripts. The ceremony only pays off when the agent needs repeatability and guardrails.

---

**Attribution:** ragnar-pwninskjold/tech-snacks, MIT
