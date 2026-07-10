# Skills For Design Engineers (emilkowalski/skills)

**Repo:** https://github.com/emilkowalski/skills
**License:** MIT. Safe to adapt with attribution.
**Reviewed:** 2026-07-09
**Stack:** Markdown Agent Skills, skills.sh distribution, motion/design review guidance
**What it is:** A compact skill pack that teaches AI coding agents better UI motion and design-engineering judgment, centered on animation taste, animation review, motion vocabulary, and Apple-style fluid interface principles.

---

## Verdict

✅ **Deploy candidate as a UI/motion craft layer.** This is small, focused, and unusually concrete for a design skill pack: it gives agents duration budgets, easing curves, transform-origin rules, reduced-motion guidance, and a review format that forces before/after specificity. It is not a general frontend system or a validation harness, but it is strong enough to install selectively wherever agents are building or reviewing interactive UI.

---

## What It Is

`emilkowalski/skills` packages four Markdown skills for design engineers. The main skill, `emil-design-eng`, captures practical UI polish rules around animation purpose, easing, duration, button feedback, popover origin, tooltips, layout, and interaction details.

The strongest part is `review-animations`, a dedicated motion-review skill backed by `STANDARDS.md`. It treats animation as a reviewable quality surface rather than decoration. It flags `transition: all`, `scale(0)`, `ease-in` on UI, high-frequency animation, wrong transform origins, layout-property animation, missing reduced-motion handling, and other common agent-generated motion mistakes.

The other two skills are narrower but useful: `animation-vocabulary` gives agents the right words for effects like rubber-banding, shared element transitions, stagger, clip-path reveals, and press feedback; `apple-design` translates Apple-style fluid-interface ideas into web implementation guidance around springs, direct manipulation, velocity handoff, momentum projection, materials, accessibility, and typography.

## Stack

| Layer | Tech |
|-------|------|
| Skill format | Markdown `SKILL.md` files with YAML frontmatter |
| Distribution | `npx skills@latest add emilkowalski/skills`, skills.sh badge |
| Runtime | Host agent skill loader |
| Domain | UI design engineering, animation review, motion vocabulary |
| CI/tests | No visible automated validation |

## Key Features

### Motion Review Standards

The `review-animations` skill is the most directly operational artifact. It requires a before/after/why table, defines explicit block-worthy issues, and points to a standards file for exact values instead of vague taste language.

Examples of concrete rules:

- UI animations should usually stay under 300ms.
- Entering/exiting UI should use `ease-out` or a strong custom curve.
- Popovers/dropdowns/tooltips should scale from their trigger, not center.
- Motion should animate `transform` and `opacity`, not layout properties.
- `prefers-reduced-motion` should be honored by reducing movement, not deleting all feedback.

### Animation Vocabulary

The vocabulary skill is useful for agent prompting and designer handoff. It maps vague descriptions to terms like "shared element transition", "origin-aware animation", "rubber-banding", "hold to confirm", "stagger", "clip-path", and "number ticker." That helps an agent ask for or implement the intended effect instead of guessing from fuzzy language.

### Apple-Style Fluid Interface Notes

The Apple design skill is broader than animation. It emphasizes pointer-down response, direct manipulation, interruptibility, springs, release velocity, projected momentum, rubber-banding, translucent materials, reduced transparency, contrast, typography, and clear information architecture. It is best treated as a design reference skill rather than a hard rulebook.

## Architecture

The repo is deliberately simple:

```text
skills/
  emil-design-eng/SKILL.md
  review-animations/SKILL.md
  review-animations/STANDARDS.md
  animation-vocabulary/SKILL.md
  apple-design/SKILL.md
```

There is no runtime code, package manifest, test suite, or validator. The architecture value is in the decomposition: one broad design-engineering skill, one strict review skill, one lookup vocabulary, and one platform-philosophy reference. That split keeps the review surface sharper than a single large "make it pretty" prompt.

## Comparison

| Aspect | emilkowalski/skills | addyosmani/agent-skills | dzhng/skills |
|--------|---------------------|-------------------------|--------------|
| Primary focus | UI motion and design craft | Full software lifecycle skills | Software-factory workflow skills |
| Best use | Frontend implementation and motion review | Production coding workflow gates | Planning, slicing, visual verification |
| Validation | No automated validation | Validators and CI | Limited helper script, no catalog CI |
| Portability | High: Markdown-only | High, but larger surface | High, some host-specific helpers |
| Main caveat | Taste guidance depends on host obedience | Large overlapping workflow layer | Less enforced than a runtime |

## Self-Hosting Notes

There is nothing to self-host. Install with:

```bash
npx skills@latest add emilkowalski/skills
```

For a coding-agent environment, the best adoption path is selective loading:

- Use `review-animations` for PR/code review of motion changes.
- Use `emil-design-eng` when building polished UI components.
- Use `animation-vocabulary` when translating user-described motion into exact implementation terms.
- Use `apple-design` for gesture-driven UI, sheets, drag/swipe interactions, and spring tuning.

Do not install it as a substitute for product-specific design systems, accessibility checks, browser testing, or actual visual review.

---

**Attribution:** emilkowalski/skills, MIT License
