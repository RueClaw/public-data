# Diagram Design (cathrynlavery/diagram-design)

**Repo:** https://github.com/cathrynlavery/diagram-design  
**License:** MIT - permissive reuse with attribution  
**Reviewed:** 2026-08-14  
**Stack:** Agent Skills, Markdown references, static HTML/SVG, Python validators/importers, Claude Code/Codex/Pi plugin metadata  
**What it is:** Diagram Design is an Agent Skill and plugin package for creating branded editorial diagrams as self-contained HTML/SVG/PNG, with 27 visual types, semantic behavior patterns, draw.io and Mermaid redraw flows, brand onboarding, accessibility checks, and optional constrained motion.

---

## Verdict

✅ **Deploy candidate for agent-generated technical diagrams.** This is a strong example of what an artifact-generation skill should look like: opinionated design rules, progressive references, deterministic validators, import extractors, and portable packaging across multiple agent runtimes. It is not a general canvas editor; its value is making agents produce cleaner static diagrams with fewer generic boxes and fewer unsafe renderer dependencies.

---

## What It Is

Diagram Design is a packaged diagram-making skill for Claude Code, Codex, and Pi. It generates standalone HTML files with inline SVG and CSS across 27 diagram types: architecture, flowchart, sequence, state, ER, timeline, swimlane, quadrant, radar, loop, nested, tree, org chart, layer stack, Venn, pyramid, bar, line, Gantt, scatter, process, medallion, data-flow, data-platform integration, security matrix, and related variants.

The repo is strongest where ordinary model output is usually weakest: choosing the right diagram type, limiting density, reserving accent color for one or two focal elements, keeping labels readable, and treating Mermaid/draw.io inputs as semantic source material rather than layouts to copy. Imports are redraws, not renderer conversions.

The skill also includes brand onboarding. It can extract palette and typography cues from a website, installed skill, or local design-system folder, then map them to semantic diagram tokens. That keeps diagrams visually aligned with their destination without forcing the agent into ad hoc color picking.

## Stack

| Layer | Tech |
|-------|------|
| Agent interface | Agent Skills `SKILL.md`, Claude Code plugin metadata, Codex plugin metadata, Pi install path |
| Diagram output | Self-contained HTML with inline SVG/CSS; optional SVG/PNG export path |
| Design system | Markdown style guide with semantic color and typography roles |
| Visual references | 27 `type-*.md` reference files plus HTML examples and gallery |
| Importers | Python draw.io and Mermaid extractors that emit bounded semantic digests |
| Validation | Python checks for accessibility, geometry, skin, motion, docs sync, package consistency |
| CI | GitHub Actions across Ubuntu, macOS, Windows and Python 3.11/3.12 |

## Key Features

### Static-First Diagram Grammar

Static output is the default. Ordinary diagrams need no JavaScript, no external images, and no renderer service. The examples are HTML/SVG files that can be opened directly in a browser, which is the right default for documentation, decks, and posts.

### Semantic Pattern Routing

The repo separates behavior from layout. Seven semantic patterns cover cases like queues, policy traces, secure paved roads, governance catalogs, unstructured-input transformation, and compensating security layers. The pattern decides the meaning-bearing primitives; the visual type decides layout grammar.

### Draw.io and Mermaid Redraws

The import path treats source diagrams as untrusted content and parses them with local Python extractors. Mermaid labels, click targets, styling, and URLs are inert content; draw.io compressed payloads are decoded into a digest. The agent then redraws the diagram in the skill's design system at the requested size and detail level.

### Accessibility and Geometry Gates

The test suite checks accessible SVG naming, safe single-file output rules, label-mask clipping, motion structure, icon generation, sequence examples, docs sync, and import behavior. The local verification run passed the major gates: accessibility, semantic motion, shipped motion files, skin linting, draw.io import, Mermaid import, docs sync, self-check, and geometry.

### Constrained Optional Motion

Motion is explicit and constrained. Animated examples use one reviewed controller from `template-motion.html`; arbitrary inline scripts, remote assets, executable attributes, and lookalike font hosts are rejected by the lint/self-check path. Reduced-motion behavior is part of the contract.

## Architecture

The repo is organized like a mature skill package rather than a pile of examples. The main `SKILL.md` handles routing, philosophy, setup, anti-patterns, and universal primitives. Deep details live in `references/`: one file per diagram type, plus import, export, animation, onboarding, style, semantic-pattern, icon, annotation, and terminal references.

The examples in `skills/diagram-design/assets/` serve as both gallery and regression surface. Scripts under `scripts/` and `skills/diagram-design/scripts/` verify packaging, imports, visual safety, accessibility, docs sync, and geometry. This gives the design rules executable teeth.

GitHub metadata at review time: 16,511 stars, 989 forks, 8 open issues, latest push 2026-08-14. The reviewed commit was `a5e3978088cf89c7caff5c20cabd99fbc2a301de`.

## Comparison

| Aspect | Diagram Design | drawio-skill | Mermaid / PlantUML | Tufte chart skill |
|--------|----------------|--------------|--------------------|-------------------|
| Primary fit | Editorial technical/product diagrams generated by agents | Editable draw.io artifacts | Docs-native diagram syntax | Quantitative charts and chart critique |
| Source artifact | Standalone HTML/SVG skill examples | `.drawio` XML | Text syntax | HTML/SVG or chart-library snippets |
| Import stance | Redraw Mermaid/draw.io semantically | Generate/edit draw.io | Render declared syntax | Usually create from data/story |
| Main strength | Design grammar, semantic patterns, static-first safety | Editability in draw.io | Plain-text docs integration | Chart selection and anti-pattern discipline |
| Main caveat | Not a full editor; generated diagrams still need taste review | draw.io CLI dependency | Layout/style ceiling | Narrow chart domain |

## Self-Hosting Notes

Install through the target agent runtime rather than manually copying individual files. For Codex, the repo publishes a Codex plugin manifest; for Claude Code, it publishes a Claude plugin manifest; Pi can install from the repository URL.

For local customization, clone the repo and edit `skills/diagram-design/references/style-guide.md`, then open `skills/diagram-design/assets/index.html` to inspect the gallery. Generated motion diagrams should be checked with the packaged self-check script before publishing.

---

**Attribution:** cathrynlavery/diagram-design, MIT License.
