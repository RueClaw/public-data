# Scanner-Backed Aesthetic Taxonomy Skill

**Source:** yetone/kill-ai-slop  
**Repo:** https://github.com/yetone/kill-ai-slop  
**License:** No license specified  
**Reviewed:** 2026-07-10

## Pattern

Turn a subjective design critique into a usable agent workflow by splitting it into a named taxonomy, detection hints, false-positive guidance, remediation patterns, and a read-only scanner. The scanner finds leads; the agent still owns judgment.

## Shape

```text
design concern
  -> named taxonomy
  -> examples and rationale
  -> code-level detection hints
  -> false-positive notes
  -> read-only scanner report
  -> human-visible triage summary
  -> approval-gated minimal fixes
```

## Why It Works

Taste work fails when it is either too vague to act on or too automated to respect context. This pattern gives the agent enough structure to find common issues while preserving a required judgment step.

The important pieces are:

- each smell has a name, rationale, and preferred fix;
- detection patterns are framed as leads, not verdicts;
- false positives are documented beside the patterns;
- the scanner never edits files;
- the agent must report grouped findings before changing anything;
- fixes are minimal and should prefer shared tokens/components over repeated call-site churn.

## Implementation Notes

- Keep the taxonomy small enough to remember and broad enough to cover real projects.
- Put examples and remediation in separate references so agents can load only what they need.
- Emit machine-readable scanner output for agent triage, and human-readable output for direct use.
- Require visual confirmation when a dev server exists; a lower scanner count is not the same as better design.
- Do not treat common patterns as automatically wrong. A gradient, emoji, serif, terminal style, or badge can be an intentional brand choice.
- For subjective cleanup, ask before applying edits. The report is part of the workflow, not ceremony.

## Caveats

This pattern can become taste-policing if it is applied without context. It works best as a review aid for generated or template-heavy web UIs, not as a universal design system. Also, when the source repo has no license, treat the pattern as a summarized idea only and do not copy code, text, or assets.

---

**Attribution:** Pattern summarized from yetone/kill-ai-slop, no license specified. No source code copied.
