# Anti-Rationalization Skill Anatomy

**Source:** https://github.com/addyosmani/agent-skills
**License:** MIT
**Reviewed:** 2026-07-05

## Pattern

Write agent skills as executable process contracts, not advice pages. A good skill tells the agent when to use it, what steps to follow, what excuses it will be tempted to make, what red flags indicate drift, and what evidence is required before the skill is complete.

## Shape

```markdown
---
name: focused-skill-name
description: Does one concrete thing. Use when specific trigger conditions apply.
---

# Focused Skill Name

## Overview
What this workflow does and why it matters.

## When to Use
- Positive triggers.
- Negative triggers or exclusions.

## Process
1. Concrete step.
2. Concrete step.
3. Concrete step.

## Common Rationalizations
| Rationalization | Reality |
|---|---|
| "This is simple, I can skip the step." | The skipped step is cheap and catches expensive failures. |

## Red Flags
- Observable signs the process is being violated.

## Verification
- [ ] Evidence-backed completion check.
```

## Why It Works

Agents do not usually fail because they lack a principle like "test your work." They fail because, in the moment, they rationalize skipping the principle:

- "This is too small for a spec."
- "I'll add tests later."
- "The docs probably have not changed."
- "The user said ship, so verification can wait."

Putting those rationalizations inside the skill gives the agent a local tripwire. It does not have to remember a general operating philosophy; the specific excuse appears next to the workflow it would undermine.

## Design Rules

- Keep the skill focused on a repeatable process.
- Put trigger conditions in the frontmatter description.
- Include negative triggers so the skill does not hijack tiny tasks.
- Make every step observable.
- Prefer evidence checks over vibes.
- List the failure modes that look like productivity.
- Keep references and long checklists outside the main skill unless they are needed every time.
- Validate skill names, frontmatter, required sections, and cross-skill references in CI.
- Keep exemptions in validator code, not in skill-owned frontmatter.

## Good Uses

- Coding workflow skills.
- Review and security procedures.
- Test and release checklists.
- Documentation and ADR workflows.
- Incident/debugging procedures.
- Any repeated agent task where "I can skip this just once" is a known failure mode.

## Poor Uses

- One-off facts or static documentation.
- Skills whose trigger is basically "use for everything."
- Generic best-practice essays with no exit criteria.
- Procedures where the host runtime cannot supply the required evidence.

## Validator Checks

A minimal validator should block:

- missing `SKILL.md`;
- missing or malformed frontmatter;
- `name` not matching the directory;
- non-kebab-case skill names;
- missing description;
- descriptions that lack "use when" trigger language;
- missing required sections;
- dead cross-skill references.

It can warn, rather than block, for softer concerns such as overly long skills, duplicated guidance, or too many supporting files.

## Caveats

This pattern improves instruction quality; it does not enforce runtime behavior. The host agent can still ignore the skill, tools can still fail, and evidence can still be fabricated unless the surrounding runtime validates outputs. Use it with real tool checks, tests, logs, and review gates.

---

**Attribution:** Extracted from addyosmani/agent-skills, MIT.
