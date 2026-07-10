# Motion Review Quality Gate

**Source:** [emilkowalski/skills](https://github.com/emilkowalski/skills)
**License:** MIT
**Extracted:** 2026-07-09

## Pattern

Treat UI motion as a first-class review surface with explicit block conditions, not as subjective polish. A motion review should force each finding into:

| Before | After | Why |
|--------|-------|-----|
| Current motion code or behavior | Specific replacement | Concrete user-experience, performance, or accessibility reason |

The useful part is the gate shape:

1. Ask whether the animation should exist at all.
2. Match the animation to how often users see it.
3. Check easing, duration, origin, interruptibility, performance, and accessibility.
4. Prefer deleting or reducing motion before tuning it.
5. Require concrete code-level replacements, not taste-only commentary.

## Block Conditions

These are good default blockers for agent-authored UI motion:

- Animation on keyboard-initiated or very high-frequency actions.
- `transition: all`.
- `ease-in` on responsive UI interactions.
- `scale(0)` entrances.
- Trigger-anchored popovers/dropdowns/tooltips scaling from center.
- UI animation over roughly 300ms without a clear reason.
- Animating layout properties like width, height, margin, padding, top, or left.
- Gesture or rapidly-triggered motion implemented with non-interruptible keyframes.
- Missing reduced-motion handling for transform-based movement.
- Ungated hover motion on touch-capable contexts.

## Why It Matters

Agents tend to generate motion that technically runs but feels sluggish, disconnected, or expensive. A checklist of exact failure modes is more useful than telling an agent to "make it feel polished." It gives reviewers and implementers a shared vocabulary and keeps motion quality tied to user feedback, spatial consistency, performance, and accessibility.

## Adoption Notes

Use this as a review gate for:

- Component libraries.
- Design-system pull requests.
- Frontend agent output.
- Interactive prototypes with drawers, popovers, tooltips, toasts, modals, drag gestures, or animated navigation.

Do not make every animation elaborate. The first acceptable fix for high-frequency or purposeless motion is often deletion.

---

**Attribution:** Pattern distilled from `review-animations/SKILL.md` and `review-animations/STANDARDS.md` in [emilkowalski/skills](https://github.com/emilkowalski/skills), MIT License.
