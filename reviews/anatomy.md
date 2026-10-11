# Anatomy (wheresryan22/anatomy)

**Repo:** https://github.com/wheresryan22/anatomy
**License:** MIT (free extraction and reuse)
**Reviewed:** 2026-10-11 (repo created 2026-10-08; 2.0K★, 153 forks)
**Stack:** Standard Agent Skill (SKILL.md + kit + references + examples); Node ≥20.10, zero dependencies, plain JS/SVG/WebGL
**What it is:** A Claude Code / Agent Skills skill that turns a technical idea into a crafted, interactive isometric figure of a real machine — dozens of small shaded parts in correct painter's order, a framed card with live readout, eased motion, optional WebGL shaders inside the drawing, and a geometry audit that proves no part passes through another.

---

## Verdict

✅ **Deploy candidate — install it for your agents.** Anatomy is the highest-craft generation skill we've reviewed: the core idea ("the object is the explanation" — invent a physical machine whose working *is* the concept, not boxes and arrows) is backed by a real kit (lathe, tube routing, painter's-order engine, shared WebGL context), eight complete examples, per-concept eval prompts, and an **audit mode that verifies the geometry** — we ran the Raptor engine build with `--audit`: 80 tubes, 267 solids, 1,119 depth states, 1.7M overlap checks, 4,292 order rules, **audit passed** in 3m21s. Zero dependencies, MIT, builds verified locally in milliseconds. It's a content-generation skill, so the risk profile is small; the only caveats are that it's three days old, Claude Code-shaped (standard SKILL.md, so other Agent-Skills-compatible harnesses work), and the 3D mode is marked beta. The craft rules in `references/` are worth reading even if you never run the skill.

---

## What It Is

Ask for a figure that explains a technical idea, and Anatomy has the agent invent a physical object whose mechanism demonstrates it — a pin-tumbler lock for cache-key invalidation, a gantry plotter for one GPU context serving many canvases. The agent then builds the figure from small solid shaded parts using the shipped kit (`iso-kit`, `lathe`, `tube`, `audit`, WebGL helpers), producing a standalone HTML page, a lone SVG, or React/Next.js components. Every number shown comes from the same model that moves the parts.

## Stack

| Layer | Detail |
|-------|--------|
| Format | Standard Agent Skill: `SKILL.md` + `kit/` + `references/` + `examples/` + `evals/` |
| Runtime | Node ≥20.10, **zero npm dependencies** — built-ins only |
| Output | Standalone HTML, lone SVG, or React/Next.js components; light/dark themes |
| Figure kinds | SVG (core), SVG+WebGL (fire/water/caustics/light), 3D mode (beta) |
| Kit | iso-kit painter's-order engine, lathe (round parts), tube (pipes/cables), geometry audit, shared GL context |
| Verification | `--audit` flag proves no interpenetration, mounts, bend quality, depth order |
| CI | macOS workflow rebuilding every example on push/PR |
| Evals | `evals/evals.json` with per-concept prompts and expected outputs |

## Key Features

### The object is the explanation
The skill's central discipline: don't draw diagrams — invent a well-made machine whose operation *is* the concept, with real numbers from the user (pool sizes, rates, thresholds). The README's habit list ("name the idea, not the drawing") is a genuinely reusable prompting pattern.

### Geometry audit as self-check
The build can prove its own correctness: nothing passes through anything at rest, apart, or in any replayed frame; every tube end sits on a real mount; no bend pinches or folds; every overlap draws in depth order. Verified locally on the Raptor engine (1.7M overlap checks, passed). Generated art with a proof step is rare.

### WebGL inside the drawing
Shaders (exhaust plume, water caustics, lamp light) render in a canvas sandwiched between back and front SVG layers in the figure's own isometric camera — effects live *inside* the illustration, and the SVG still reads without WebGL.

### Honest engineering posture
Zero dependencies, committed built pages (open any example HTML directly), CI rebuilds all examples, evals shipped in-repo, 3D mode labeled beta, a documented limits section.

## Limitations

- **Three days old, single author** — though the craft suggests long prior development.
- **Claude Code-shaped** (install flows target `~/.claude/skills/`); it's a standard SKILL.md so other Agent-Skills harnesses can load it, but prompts/evals assume a strong visual-generation model.
- **3D mode is beta** and its audit is slow (documented).
- **Generation quality is model-dependent** — the kit and audits constrain geometry, but inventing the right machine is the model's job; weak models will produce weak figures.
- Example builds are fast except the Raptor (~minutes with audit).

## Local Verification

Built and ran on this machine (Node 26): `dial-indicator` (0.13 s), `desk-computer` (0.14 s), and `raptor-engine --audit` — 80 tubes, 267 solids, 478 items, 1,119 depth states, 1,707,702 overlaps, 4,292 order rules, **audit passed**. Output pages written as committed. No `eval(`/dynamic-code red flags in the kit.

## Who Should Use It

Anyone producing technical documentation, blog posts, or landing pages who wants explanatory figures at a Linear/Vercel craft level — especially agent-driven docs pipelines. The `references/craft.md`, `motion.md`, and `verify.md` files double as a concise course in making machine-made illustrations look hand-built.

---

**Attribution:** wheresryan22/anatomy, MIT.
