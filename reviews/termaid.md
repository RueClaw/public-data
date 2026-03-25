# termaid — #256

**Repo:** https://github.com/fasouto/termaid  
**Author:** Fabio Souto  
**License:** MIT (Fabio Souto 2026)  
**Language:** Python 3.11+  
**Version:** 0.2.0  
**Stars:** 127 | **Forks:** 5  
**Created:** 2026-02-26 | **Reviewed:** 2026-03-25  
**Rating:** 🔥🔥🔥🔥🔥  
**Cloned:** ~/src/termaid

---

## What It Is

Pure-Python Mermaid diagram renderer for the terminal. Zero runtime dependencies — just the package. Takes `.mmd` Mermaid syntax and outputs Unicode box-drawing art (or ASCII fallback) directly to stdout. No browser, no Node.js, no external service.

9 diagram types supported:
- Flowcharts (TD, LR, RL, BT, all node shapes, all edge styles, subgraphs)
- Sequence diagrams
- Class diagrams
- ER diagrams
- State diagrams
- Block diagrams
- Git graphs
- Pie charts (rendered as bar charts — correct call)
- Treemaps (beta)

---

## Architecture

Clean layered pipeline:
```
Mermaid source → Parser → Graph model → Layout (grid) → Routing (A* pathfinder) → Renderer → Canvas → Output
```

**Key subsystems:**
- `parser/` — one parser per diagram type, custom tokenizers
- `graph/model.py` — shared Graph/Edge/Node model
- `layout/grid.py` — grid-based node placement with subgraph support
- `routing/pathfinder.py` + `router.py` — A* pathfinding with attachment point selection, soft obstacle avoidance, multi-edge routing
- `renderer/` — per-diagram-type renderers, 6 color themes (default, terra, neon, mono, amber, phosphor), Unicode/ASCII charset switching
- `output/` — text, Rich, Textual widget backends
- `cli.py` — pipe-friendly CLI (`cat diagram.mmd | termaid`)

~10K lines of Python. Surprisingly complete for a 1-month-old project.

---

## Why It's Useful

**The problem it solves is real:** Mermaid is the de facto standard for AI-generated diagrams (Claude, ChatGPT, Cursor all output it). But rendering it requires a browser or JS runtime. This gives you:

- Mermaid in SSH sessions
- Mermaid in CI/CD logs
- Mermaid in TUI apps (Textual widget built in)
- Mermaid from Python code (`from termaid import render`)
- Pipe-friendly: `claude -p "make me a flowchart of X" | grep -A999 '```mermaid' | termaid`

**Direct relevance:**
- ODR TUI frontend (Python + Textual) — MermaidWidget drops in for architecture diagrams, review flows
- Agent-generated diagrams — any time an LLM outputs Mermaid, we can render it inline without leaving the terminal
- OpenClaw Drawbridge skill — could replace/supplement the Excalidraw approach for quick structural diagrams

---

## Standout Patterns

**A* edge routing** with attachment point selection and soft obstacle avoidance — this is the hard part of any diagram renderer and it's done properly. Most ASCII diagram tools just draw straight lines and call it a day.

**Charset abstraction** — `charset.py` makes the ASCII fallback clean. Everything goes through one layer, works on any terminal.

**Lazy import pattern** for optional deps (Rich/Textual) — `__getattr__` on the module handles `MermaidWidget`. Good pattern for optional heavy deps.

**Per-type parsers** — each diagram type has its own parser. No god-object trying to parse everything. Composable and testable.

---

## Usage

```bash
pip install termaid
# or: uvx termaid diagram.mmd

echo "graph LR; A-->B-->C" | termaid
termaid diagram.mmd --theme neon
termaid diagram.mmd --ascii

# Python
from termaid import render
print(render("graph LR\n  A --> B"))

# With Rich colors
from termaid import render_rich
from rich import print as rprint
rprint(render_rich("graph LR\n  A --> B", theme="terra"))

# Textual widget
from termaid import MermaidWidget
```

---

## Verdict

🔥🔥🔥🔥🔥 — Does one thing, does it properly, zero dependencies, Python-native. Immediately useful for ODR TUI and anywhere an LLM outputs Mermaid and you want to display it inline. The A* router is the most technically interesting piece — most similar tools skip it entirely.

**Worth stealing:** The charset abstraction pattern and the layered pipeline design are clean templates for any terminal rendering work.

**Install for ODR TUI:** `pip install termaid[textual]` → drop in `MermaidWidget` wherever architecture diagrams show up.
