# Kill AI Slop (yetone/kill-ai-slop)

**Repo:** https://github.com/yetone/kill-ai-slop  
**License:** No license specified. Treat as public reference material only; do not copy code or assets without permission.  
**Reviewed:** 2026-07-10  
**Stack:** Astro static site, TypeScript content catalogue, CSS demos, Agent Skill, dependency-free Node scanner  
**What it is:** A field guide to common AI-generated product design/copy tics, paired with an Agent Skill and scanner that help coding agents identify and remove those patterns from web projects.

---

## Verdict

⚠️ **Useful taste taxonomy, but not cleanly reusable yet.** The project is sharp: it turns a subjective design complaint into a concrete 23-item taxonomy, live before/after examples, a scanner, and an agent workflow that requires triage before edits. The limiting factors are practical: no license, no visible tests/CI, a young v1.0.0 release, and current Astro audit findings in the website dependency tree.

---

## What It Is

`kill-ai-slop` is two artifacts in one repo. The website is a multilingual static field guide that names 23 visual and copywriting tells associated with generated product pages: purple gradients, gradient text, warm beige palettes, stock semantic colors, emoji spam, glassmorphism, over-rounding, badge spam, generic feature-card grids, and the newer "tasteful terminal" look.

The skill turns that catalogue into an agent workflow. It tells an agent to scope the frontend source, run a bundled scanner, manually confirm hits as slop vs. deliberate design, report grouped findings before changing anything, then apply minimal fixes only after approval. That "scan, triage, report, then fix" shape is the best part of the repo.

The scanner is a dependency-free Node script. It walks frontend source files, skips build/vendor/lockfile directories, applies regex patterns for each tell, and emits either a grouped terminal report or JSON. It never edits files.

## Stack

| Layer | Tech |
|-------|------|
| Website | Astro 5, TypeScript, CSS, static output |
| Content model | TypeScript catalogue plus i18n strings |
| Skill | Agent Skill `SKILL.md` with references and remediation playbook |
| Scanner | Node ESM script using only built-in `fs`/`path` modules |
| Languages | English, Chinese, Japanese, Korean |
| Tests/CI | None visible |
| License | No repo license detected |

## Key Features

### 23-Item Slop Taxonomy

The taxonomy is specific enough to be actionable. It separates color, type, copy, component, layout, and evolved patterns, and each entry explains what the tell is, why it reads as machine-made, and what a cleaner alternative looks like.

### Scanner as Lead Generator, Not Judge

The scanner intentionally treats regex matches as leads. The skill repeatedly says that a gradient, serif, emoji, or terminal aesthetic can be a real choice; the agent must read the code and confirm whether it is a default or an intentional brand/design decision.

### Approval-Gated Agent Workflow

The skill explicitly forbids mass-editing before the user sees a report. It asks the agent to present grouped hits and proposed fixes first, then apply selected groups. That is the right safety posture for subjective design changes.

### Before/After Demos

The site rebuilds each tell as HTML/CSS before/after demos rather than relying on screenshots. That makes the examples inspectable and keeps the website aligned with the scanner taxonomy.

## Architecture

The repo is small and cleanly split:

- `website/`: Astro static site, catalogue data, multilingual strings, demos, tokens, and layout/components.
- `skill/`: installable Agent Skill with `SKILL.md`, taxonomy/detection/fix references, and scanner.
- `skill/scripts/scan.mjs`: standalone read-only scanner.

The useful design choice is keeping the taxonomy in several parallel forms:

- public field guide for humans;
- `SKILL.md` workflow for agents;
- `detection.md` regex/false-positive notes;
- `fixes.md` remediation patterns;
- scanner implementation for machine-readable reporting.

That makes the idea portable across visual review, automated triage, and agent-driven cleanup.

## Comparison

| Aspect | Kill AI Slop | Design Linting | Generic UI Review Skills |
|--------|--------------|----------------|--------------------------|
| Primary lens | AI-generated design/copy tics | Rule/style conformance | Broad subjective critique |
| Runtime | Static site plus Node scanner | Usually framework-specific tooling | Prompt/instruction only |
| Strength | Concrete examples and remediation workflow | Repeatability | Wider coverage |
| Caveat | No license/tests and subjective taxonomy | Often misses taste/context | Hard to verify automatically |

This is closer to a design-review checklist plus grep harness than a full linter. That is a strength: it does not pretend the scanner can make taste judgments alone.

## Self-Hosting Notes

The website builds locally:

```bash
cd website
npm ci
npm run build
```

Validation notes from this review:

- `npm run build` completed successfully and produced a static Astro site.
- `node skill/scripts/scan.mjs website/src --json` ran successfully.
- The scanner flags the repo's own demo catalogue heavily because the demo source intentionally contains the "bad" examples. That is expected, but it means self-scan counts are not a quality signal here.
- `npm audit --omit=dev --json` reported 2 vulnerabilities through Astro/esbuild: 1 low and 1 high. The available fix is an Astro major upgrade.

---

**Attribution:** yetone/kill-ai-slop, no license specified, https://github.com/yetone/kill-ai-slop
