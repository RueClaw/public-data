# Isolated Divergent Ideation Loop

**Source:** [UditAkhourii/adhd](https://github.com/UditAkhourii/adhd)
**License:** MIT
**Extracted:** 2026-07-25

## Problem

Asking one model to "think of several options" often produces variations of the first plausible answer. The model evaluates while generating, the first option becomes an anchor, and later options drift toward the same center even when the prompt asks for breadth.

## Pattern

Make divergence structural instead of rhetorical:

1. **Strip incidental anchors.** Before brainstorming, remove current-stack details or accidental implementation facts that are not real constraints.
2. **Choose frames before generation.** Pick a small set of cognitive frames, such as regulator, hardware engineer, inversion, logistics, biology, or 3am on-call.
3. **Run branches in isolation.** Each branch gets the same problem plus one frame. Branches do not see each other during generation.
4. **Forbid critique during divergence.** The generator prompt asks for short ideas only: no ranking, no hedging, no evaluation.
5. **Converge in a separate pass.** A critic scores every idea on novelty, viability, and fit.
6. **Name traps explicitly.** The critic flags attractive-but-broken ideas with a concrete reason.
7. **Cluster by angle.** Group ideas by underlying strategy, not surface words.
8. **Deepen only the survivors.** Expand the highest-scoring non-trap ideas into sketches with risks and first steps.
9. **Keep one provocation.** Preserve the highest-novelty edge case as a question even if it is not the main recommendation.

## Why It Works

The isolation boundary prevents the first generated idea from becoming shared context. Frames bias each branch into a different region of the design space, while the critic pass restores discipline after breadth has been created. Trap naming keeps novelty from turning into novelty worship.

## Minimal Version

Use three branches and one critic pass:

```text
Branch A: 3am on-call, generate 5 ideas
Branch B: inversion, generate 5 ideas
Branch C: remove-assumption, generate 5 ideas
Critic: score novelty / viability / fit, name traps, choose top 2
Focus: deepen top 2 into implementation sketches
```

## Implementation Notes

- Do not serialize branches into one transcript. That recreates the anchoring problem.
- Keep branch prompts short. Large shared context multiplies cost across every branch.
- Select frames before reading branch outputs.
- Use structured output for scores and trap labels.
- Treat the critic as a different mode, and preferably a different model when cost and provider access allow it.
- Cap branch count by decision value. This belongs at decision points, not inside routine answer loops.

## Good Fits

- architecture alternatives
- API surface and naming decisions
- fuzzy debugging hypothesis generation
- adversarial test ideas
- product or workflow strategy
- refactor direction selection

## Poor Fits

- factual lookup
- known-root-cause bugs
- straightforward code edits
- low-stakes choices
- any task where the user asked for the canonical or quick answer

---

**Attribution:** UditAkhourii/adhd, MIT License.
