# visual-explainer (nicobailon/visual-explainer)

**Repo:** https://github.com/nicobailon/visual-explainer
**License:** MIT License - permissive reuse with attribution
**Reviewed:** 2026-06-25
**Stack:** Agent Skills Markdown, Claude Code plugin metadata, Pi package extension in TypeScript, browser-rendered self-contained HTML, Mermaid, Chart.js
**What it is:** `visual-explainer` is an Agent Skill and multi-harness package that pushes coding agents away from terminal ASCII tables and toward self-contained HTML pages for diagrams, diff reviews, plan reviews, project recaps, slide decks, and dense comparison tables.

---

## Verdict

⚠️ **Interesting as an agent-output pattern, not a full diagramming platform.** The repo has matured from a simple presentation trick into a portable skill package with real multi-harness installation docs, a Pi native render tool, compressed routing guidance, and careful Mermaid interaction patterns. It is still prompt/template driven and has no visible automated tests, so treat it as a useful skill/pattern source rather than a production dependency.

---

## What It Is

`visual-explainer` targets a real coding-agent failure mode: when an agent needs to explain architecture, review a large diff, compare a plan against code, or show a dense matrix, the terminal response often collapses into broken ASCII diagrams and unreadable pipe tables. This skill tells the agent to generate a portable HTML artifact instead, usually under `~/.agent/diagrams/`.

The package now supports several agent environments. Claude Code gets marketplace metadata. Pi gets package metadata plus a TypeScript extension exposing one `visual_explainer` tool with `prepare` and `render` actions. Codex, OpenCode/opencode, Cursor, and OpenClaw get install/config guidance. The canonical skill lives under `plugins/visual-explainer/`, with command templates, reference docs, and HTML templates.

The useful part is not "pretty HTML." It is the operational guidance around when to move information out of chat, how to choose the visual representation, and how to avoid common Mermaid/browser rendering traps: zoom/pan shells, complex-diagram thresholds, table overflow handling, slide deck rules, and scanner-safe SVG insertion.

## Stack

| Layer | Tech |
|-------|------|
| Agent interface | Agent Skills `SKILL.md` with progressive reference routing |
| Commands | Markdown prompt templates for diff review, plan review, fact check, project recap, slides, and web diagrams |
| Native tool | Pi extension in TypeScript |
| Output | Self-contained HTML files under `~/.agent/diagrams/` |
| Diagrams | Mermaid with custom zoom/pan shell |
| Charts | Chart.js guidance |
| Templates | HTML templates for architecture pages, Mermaid flowcharts, data tables, and slide decks |
| Packaging | Claude Code plugin metadata, Pi package metadata, Codex/OpenCode/Cursor/OpenClaw guidance |
| Tests/CI | No visible automated tests in the reviewed checkout |

## Key Features

### Visual Routing Rules

The skill gives concrete thresholds instead of vague design advice. If a table would have 4+ rows or 3+ columns, render it as HTML. Use Mermaid for flows, topology, sequence, ER, class, state, and C4-like diagrams. Use CSS grid cards for text-heavy architecture and hybrid pages for 15+ elements.

That kind of routing is valuable because it changes the agent's default response medium before the output becomes unreadable.

### Pi `visual_explainer` Tool

The TypeScript extension adds one native tool:

- `prepare` returns a recommended visual-explanation workflow, optional subagent prompt, target audience, files, and steps.
- `render` validates that the submitted string is a complete HTML document, writes it to `~/.agent/diagrams/`, rejects path traversal, avoids symlink writes for the output path, and optionally opens it with the platform browser opener.

This is a lightweight but sensible bridge between "instruction-only skill" and "tool-backed artifact delivery."

### Mermaid Interaction Pattern

The repo's Mermaid guidance is unusually specific. It forbids bare `<pre class="mermaid">`, requires a `diagram-shell` / `mermaid-wrap` / `mermaid-viewport` / `mermaid-canvas` structure, and expects zoom controls, pan, reset, expand, Ctrl/Cmd-scroll zoom, and complex-diagram splitting.

The June 2026 changelog also notes a scanner-facing improvement: Mermaid SVG output is parsed through a lenient HTML parser rather than assigned through `innerHTML`, preserving `foreignObject` labels while avoiding common sink warnings.

### Prompt Compression

Version 0.8.0 compressed the skill and command prompts from 10,824 words to 2,131 words while preserving the core render, Mermaid, table, slide, and review-section requirements. For agent skills, that matters: bulky skills are expensive to load and easy for models to ignore.

### Multi-Harness Packaging

The project is mostly a packaging and guidance repo now. It keeps one canonical skill directory and supplies adapters or instructions for Claude Code, Pi, Codex CLI, OpenCode/opencode, Cursor, and OpenClaw. That makes it a useful reference for skill authors trying to avoid copy-pasted divergent skill bodies.

## Architecture

The repo is deliberately small:

- `plugins/visual-explainer/SKILL.md` is the canonical agent-facing instruction file.
- `plugins/visual-explainer/commands/` contains command templates for common visual-review workflows.
- `plugins/visual-explainer/references/` stores larger style, library, slide, and responsive-nav guidance.
- `plugins/visual-explainer/templates/` contains reference HTML pages for common output shapes.
- `plugins/visual-explainer/extension.ts` implements the Pi native tool.
- `configs/` contains harness-specific guidance.

The design pattern is good: keep the trigger/routing surface short, lazy-load deeper references only when needed, and make final output a local artifact rather than a giant terminal answer.

Local validation performed:

- Shallow clone succeeded at commit `528b71feb85dab5d92b82c3554880826f50a75da`, release `v0.8.1`.
- Static secret/sink scan found no committed live secrets; hits were expected references to `writeFileSync`, browser opener `spawn`, and changelog/reference discussion of `innerHTML`.
- No test files or test scripts were present in the reviewed checkout.
- GitHub metadata on 2026-06-25: 8,918 stars, 599 forks, 20 open issues, latest push 2026-06-25.

## Comparison

| Aspect | visual-explainer | drawio-skill | HTML Anything |
|--------|------------------|--------------|---------------|
| Primary fit | Agent-generated explanatory HTML pages | Editable formal diagrams | Local web app for agent-generated HTML publishing |
| Output | Self-contained HTML | `.drawio`, images, PDFs | HTML, images, social/docs/deck exports |
| Runtime | Mostly instruction/templates; Pi has a small file-render tool | draw.io CLI plus validators/importers | Next.js app spawning local agent CLIs |
| Strength | Clear routing and visual-output discipline | Editable artifact pipeline | Streaming preview and export surfaces |
| Weakness | Prompt-dependent, no visible tests | Host dependency on draw.io/Graphviz | Security-sensitive shell boundary |

## Self-Hosting Notes

There is no server to host. Install it as an agent skill or plugin for the target harness. The main operational issue is browser access: generated HTML is only useful if the local environment can write and open files, or at least return a file path to the user.

For teams, pin a version or commit. Skill behavior is prompt-driven, and small instruction changes can alter generated output style, safety posture, and token use.

---

**Attribution:** nicobailon/visual-explainer, MIT License.
