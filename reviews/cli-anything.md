# CLI-Anything (HKUDS/CLI-Anything)

*Review #265 | Source: https://github.com/HKUDS/CLI-Anything | License: Apache 2.0 | Author: HKUDS (Hong Kong Univ. DS Lab) | Reviewed: 2026-03-26*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

A framework for making any software agent-native via automatically generated CLI harnesses. You point it at a codebase (or GitHub URL), it runs a 7-phase pipeline, and outputs an installable Python CLI package with REPL mode, `--json` output, state management, undo/redo, and 100+ tests.

21 applications covered with 1,917 passing tests: GIMP, Blender, Inkscape, Audacity, LibreOffice, OBS Studio, Kdenlive, Shotcut, Zoom, MuseScore, Draw.io, Mermaid, ComfyUI, NotebookLM, AdGuard Home, Ollama, FreeCAD, iTerm2, RenderDoc, Sketch, and more.

**The thesis:** GUI software was designed for humans. Agents need structured CLI interfaces. CLI-Anything generates those interfaces, calling real application backends — not reimplementations.

---

## Architecture

### 7-Phase Generation Pipeline
1. **Analyze** — maps source code → GUI capabilities → CLI command groups
2. **Design** — architects state model, command hierarchy, output formats
3. **Implement** — Click CLI with unified ReplSkin, JSON output flag, undo/redo
4. **Plan Tests** — writes TEST.md with unit + E2E test plan
5. **Write Tests** — implements comprehensive test suite
6. **Document** — updates TEST.md with results
7. **Publish** — generates setup.py, installs to PATH as `cli-anything-<software>`

### Per-Harness Package Structure
```
<software>/agent-harness/
└── cli_anything/<software>/
    ├── <software>_cli.py    # Click entry point
    ├── core/                # Domain modules (project, session, etc.)
    ├── utils/
    │   ├── <software>_backend.py  # Real software integration
    │   └── repl_skin.py           # Shared REPL UI (banners, history, prompts)
    ├── skills/SKILL.md            # Agent-discoverable skill definition
    └── tests/
        ├── test_core.py           # Unit tests
        └── test_full_e2e.py       # E2E tests against real software
```

### SKILL.md Auto-Generation (Phase 6.5)
Each generated CLI ships a `SKILL.md` inside the Python package. The REPL banner prints the absolute path at startup — agents can read it immediately without configuration. This is how CLI-Anything bridges into OpenClaw, Claude Code, Codex, etc.

### CLI-Hub Meta-Skill
Registry at `registry.json` → GitHub Actions → `docs/hub/SKILL.txt` (live catalog). A meta-skill lets agents autonomously discover and install the right CLI for any task. The meta-skill is available directly for OpenClaw and nanobot.

---

## Key Technical Decisions

**Real backends, no substitutes.** LibreOffice exports to real PDF (magic bytes verified). Blender renders actual 3D scenes via `blender --background`. Audacity processes audio through sox. Tests *fail* (not skip) if the backend is missing — authenticity is enforced.

**Dual-mode operation.** Every CLI runs as REPL (`cli-anything-gimp`) or subcommand (`cli-anything-gimp --json project new`). The REPL provides interactive sessions with command history. JSON mode provides structured output for agent consumption.

**Persistent state.** Project state is serialized to JSON. Commands operate on this state file, enabling multi-step workflows across invocations. Undo/redo via state snapshots.

**Filter translation lessons** (from HARNESS.md — this is hard-won knowledge):
- MLT → ffmpeg: watch for duplicate filter merging, interleaved stream ordering, parameter space differences, unmappable effects
- Timecode: non-integer frame rates (29.97fps) cause cumulative rounding; use `round()` not `int()`, ±1 frame tolerance in tests
- Export verification: never trust exit 0; check magic bytes, ZIP structure, pixel analysis, audio RMS, duration

---

## Browser Harness — Notable Pattern

The browser harness wraps DOMShell MCP (Chrome Accessibility Tree as virtual filesystem). Commands like `ls`, `cd`, `cat`, `grep`, `click` operate on the accessibility tree. This is accessibility-first, not vision-based — cleaner and more reliable than ShowUI-type approaches for structured pages.

---

## What's Good

- **Scope is enormous.** 21 professional applications, 1,917 tests, 100% pass rate, updated daily by community contributions.
- **HARNESS.md is the real artifact.** The SOP itself is production quality — a codified methodology for GUI→CLI translation applicable to any project doing similar wrapping.
- **OpenClaw native.** `openclaw-skill/SKILL.md` already exists. Install: `cp CLI-Anything/openclaw-skill/SKILL.md ~/.openclaw/skills/cli-anything/SKILL.md`. Then `@cli-anything build a CLI for ./gimp`.
- **CLI-Hub meta-skill.** `openclaw skills install cli-anything-hub` gives agents autonomous CLI discovery. They browse the catalog, install what they need, and use it — zero human intervention.
- **repl_skin.py** is a clean shared REPL component worth extracting for any agent-facing CLI project. Branded banner, styled prompts, history, progress indicators — consistent across all CLIs.

## What to Watch

- Requires frontier-class models (Sonnet/Opus-tier) for reliable generation. Smaller models produce incomplete harnesses.
- Source code required — compiled-binary-only targets degrade substantially.
- Community is moving fast (multiple merges per day in March 2026).
- ClawHub exclusion still applies — supply-chain concern. But this is GitHub-hosted and we own the clone.

## Relevance

**Immediate use:** OpenClaw skill already provided. We can wire up existing harnesses for AdGuard Home, Ollama, Mermaid, etc. directly to Rue.

**ODR:** The HARNESS.md methodology maps well to ODR's code review problem — structured pipeline analysis, phase-based generation, state management. Worth reading before the next ODR architecture pass.

**Parkinson's agent:** The offline-video angle (ArcDLP review) plus LibreOffice harness = potential for agent-driven document generation in Marcos's support workflow.

**Pattern steal:** `repl_skin.py` + SKILL.md generation pipeline. Both are generic enough to reuse in any agent-facing CLI tool we build.

Install the OpenClaw skill:
```bash
mkdir -p ~/.openclaw/skills/cli-anything
cp ~/src/CLI-Anything/openclaw-skill/SKILL.md ~/.openclaw/skills/cli-anything/SKILL.md
```
