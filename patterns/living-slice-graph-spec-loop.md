# Living Slice Graph Spec Loop

**Source:** dzhng/skills
**Repo:** https://github.com/dzhng/skills
**License:** MIT
**Reviewed:** 2026-07-05

## Pattern

Represent a large software change as a living spec folder whose slices are independently verifiable contracts. The spec is not a one-time plan. It is the active control surface for the agent loop: current status, next pickup point, slice graph, verification gates, review evidence, assets, and handoff prompts.

## Why It Works

Large agent tasks fail when the plan is a prose wall and implementation expands a slice whenever it discovers new uncertainty. This pattern makes uncertainty visible and forces every implementation pass to answer a narrow question.

The useful rules:

- Start by mapping unknowns before slicing.
- Slice at API seams or reviewable user-visible checkpoints.
- Give every slice a runnable artifact or inspection surface.
- Keep a `Next Agent Prompt` in the spec README so a fresh agent can resume without chat history.
- Treat reslicing as progress when implementation reveals hidden variables.
- Update the spec before broadening the patch.
- Run cleanup and review at each pass, not only at the end.

## Minimal Structure

```text
specs/<feature>/
  README.md
  slices/
    01-first-contract.md
    02-next-contract.md
  assets/
  visualizations/
```

The README owns the goal, current status, dependency graph, global TODOs, firewalls, verification gates, and next-agent prompt. Each slice file owns one contract: inputs, outputs, review surface, tests, screenshots or probes, what must stay green, and what user feedback would change the slice.

## Implementation Guidance

Use this pattern when a change is too large to trust a single implementation prompt. The first pass should produce the spec and the first runnable checkpoint, not attempt the whole feature. Later passes update the spec whenever the code proves the plan stale.

Do not let the README become a transcript. Keep it current and compact; move detailed evidence into slice files or assets.

## Good Fit

- Multi-step product features
- Visual or interactive work requiring review checkpoints
- Agentic implementation that may span sessions
- Refactors with staged ownership migration
- Work where unknowns are as risky as the code itself

## Bad Fit

- One-file fixes
- Straightforward dependency bumps
- Tasks where the user only needs a direct answer
- Mature project management systems that already provide a better structured source of truth

---

**Attribution:** Extracted from dzhng/skills, especially `write-spec`, `implement-spec`, and `explore-unknowns`. MIT License.
