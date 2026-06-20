# drawio-skill (Agents365-ai/drawio-skill)

**Repo:** https://github.com/Agents365-ai/drawio-skill
**License:** MIT License - permissive reuse with attribution
**Reviewed:** 2026-06-20
**Stack:** Agent Skills `SKILL.md`, Python stdlib scripts, Graphviz, draw.io desktop CLI, compressed JSON shape data, GitHub Actions
**What it is:** `drawio-skill` is an Agent Skill for generating editable draw.io diagrams from natural language, with local export to PNG/SVG/PDF/JPG and helper scripts for codebase visualization, shape search, brand icons, validation, style presets, and PNG repair.

---

## Verdict

✅ **Deploy candidate for agent-native diagram generation.** This is an unusually practical diagramming skill: it uses the mature draw.io file format instead of inventing a new renderer, adds deterministic validators and import-graph tooling, and keeps the final artifact editable. The main caveat is operational rather than architectural: useful exports require the draw.io desktop CLI, and some advanced visual review loops depend on a vision-capable model.

---

## What It Is

`drawio-skill` turns a diagram request into `.drawio` XML and then exports it locally through the native draw.io desktop CLI. It targets agents that need polished architecture diagrams, ERDs, UML/class/sequence diagrams, network maps, flowcharts, ML model figures, and other structured visuals where Mermaid is too limited and freehand canvas tools are too loose.

The repository is more than a prompt. The skill carries a full operating workflow: dependency detection, layout planning, XML generation, deterministic validation, optional PNG export, vision-based self-check, feedback-driven XML edits, and final embedded exports. The output remains editable in draw.io because final PNG/SVG/PDF exports can embed the source diagram.

The stronger recent additions are the helper scripts. `autolayout.py` uses Graphviz to place and route medium/large graphs. Language importers extract Python, JS/TS, Go, Rust, and Python class-hierarchy graphs. `shapesearch.py` resolves real draw.io shape styles from a bundled 10,000+ shape index. `aiicons.py` resolves LLM and data-store brand logos, with CDN or embedded SVG modes.

## Stack

| Layer | Tech |
|-------|------|
| Agent interface | Agent Skills `SKILL.md` with front matter and progressive references |
| Diagram format | Uncompressed draw.io / mxGraph XML |
| Export runtime | draw.io desktop CLI |
| Layout | Graphviz `dot` and `tred` |
| Helper scripts | Python 3 stdlib |
| Shape data | Bundled gzipped draw.io shape index |
| Brand icons | lobe-icons manifest, unpkg CDN, simple-icons fallback |
| Validation | Custom deterministic `.drawio` linter |
| Tests/CI | Python `unittest`, GitHub Actions |

## Key Features

### Editable Draw.io Output

The core choice is sensible: generate `.drawio` XML and let draw.io export the final image formats. That gives the user a normal, editable artifact rather than a one-way raster or a renderer-specific syntax.

### Codebase-to-Diagram Pipeline

The bundled importers produce graph JSON from Python, JS/TS, Go, Rust, and Python class hierarchies. `autolayout.py` then runs Graphviz and emits draw.io cells with node positions, containers, group colors, and orthogonal edge waypoints. This removes the usual manual-coordinate ceiling for repo structure diagrams.

### Exact Shape and Icon Resolution

`shapesearch.py` is a practical fix for a common draw.io problem: guessed `shape=mxgraph.*` styles silently render badly. Searching the official shape index lets the agent use real AWS, Azure, GCP, Cisco, Kubernetes, UML, BPMN, ER, electrical, P&ID, and general shapes.

`aiicons.py` covers another gap: draw.io does not ship modern AI/LLM brand logos. The script resolves 321 lobe-icons brands and falls back to simple-icons for common RAG/data-store brands.

### Deterministic Validation Before Visual Review

`validate.py` checks duplicate IDs, reserved IDs, dangling edge endpoints, broken parents, invalid geometry, off-grid/negative positions, and sibling overlap warnings. That is exactly the right split: catch structural XML mistakes with code before spending a model call on image review.

### PNG Export Repair

The skill documents and scripts around a specific draw.io CLI issue: `-e` embedded PNG exports can have a truncated IEND chunk. `repair_png.py` fixes the file after final embedded export. This is the kind of unglamorous operational detail that makes the skill feel used rather than merely designed.

## Architecture

The repo keeps the agent-facing skill small enough to route behavior, then pushes deep material into `references/` and executable helpers into `scripts/`. The `SKILL.md` is not just a prompt template; it encodes concrete fallback paths, safety valves, and edit rules for modifying existing XML without regenerating the whole diagram.

The helper scripts are intentionally dependency-light. They use Python stdlib for parsing, URL encoding, XML escaping, icon lookup, validation, and import graph extraction, with Graphviz and draw.io as optional host tools for layout/export. The test suite exercises pure functions and CLI behavior without requiring Graphviz or draw.io for most checks.

Local validation performed:

- `python3 -m unittest discover -s tests -v` passed: 23 tests.
- Targeted secret-string scan found documentation/example hits only, not committed live secrets.
- GitHub metadata on 2026-06-20: 4,248 stars, 316 forks, 0 open issues, latest push 2026-06-20.

## Comparison

| Aspect | drawio-skill | Mermaid/PlantUML | tldraw | Excalidraw |
|--------|--------------|------------------|--------|------------|
| Primary fit | Polished editable diagrams generated by agents | Diagrams-as-code in Markdown/docs | Infinite-canvas app/SDK | Freeform whiteboard sketching |
| Output | `.drawio`, PNG, SVG, PDF, JPG | Text source + rendered images | App/canvas state, exports | App/canvas state, exports |
| Agent workflow | Skill-driven generation, validation, export, repair | Prompt writes syntax | Requires app/API integration | Requires app/API integration |
| Shape library | Strong draw.io/vender shapes plus AI logos | Limited by syntax renderer | Custom shapes possible | Sketchy visual library |
| Main caveat | Requires draw.io CLI for exports | Layout/detail ceiling | Product/SDK integration and licensing | Less precise for formal diagrams |

## Self-Hosting Notes

Install the draw.io desktop CLI first, then install the skill through the target Agent Skills runtime. Graphviz is optional but important for codebase visualization and larger layouts. In sandboxed macOS environments, treat draw.io CLI crashes or empty output as a host isolation problem and use XML/browser fallback rather than repeatedly retrying.

For offline or archival diagrams, prefer embedded final outputs and use `aiicons.py --embed` for logo assets that would otherwise depend on a CDN at render time.

---

**Attribution:** Agents365-ai/drawio-skill, MIT License.
