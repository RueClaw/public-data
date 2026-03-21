# Ghost OS (ghostwright/ghost-os)

**Rating:** 🔥🔥🔥🔥🔥  
**License:** MIT  
**Source:** https://github.com/ghostwright/ghost-os  
**Reviewed:** 2026-03-21  
**Version:** v2.2.1

## What It Is

Full macOS computer-use for AI agents via MCP. 29 tools to see and operate any app on your Mac. Accessibility tree first, local vision model fallback. Self-learning recipe system.

```bash
brew install ghostwright/ghost-os/ghost-os
ghost setup
```

## Architecture

```
AI Agent (Claude Code, Cursor, any MCP client)
    │
    │ MCP Protocol (stdio)
    │
Ghost OS MCP Server (Swift, ~7000 lines)
    │
    ├── Perception ──── AX tree (macOS Accessibility API)
    ├── Vision ──────── ShowUI-2B (local, 3GB, auto-downloads)
    ├── Actions ─────── click, type, scroll, keys, drag
    ├── Recipes ─────── self-learning JSON workflows
    └── AXorcist ────── steipete's macOS accessibility engine
```

## Key Design Decision: AX Tree First, Vision Fallback

Other computer-use tools take screenshots and guess. Ghost OS reads the macOS accessibility tree — structured, labeled data about every element in every native app: roles, names, positions, actions, DOM IDs.

When the AX tree falls short (Gmail, Slack web — Chrome exposes everything as `AXGroup`), ShowUI-2B handles visual grounding locally. No pixel-guessing for native apps.

## The Recipe System

**Frontier model figures out the workflow once → JSON recipe → small model runs it forever.**

Recipes are transparent JSON with:
- Typed parameters with descriptions
- Preconditions (app running, URL contains)
- Steps with AX attribute matching (`AXRole + computedNameContains`)
- Wait conditions between steps (`elementExists`, `elementGone`, `titleContains`)
- Per-step failure handling

Example — gmail-send (7 steps):
```json
{
  "schema_version": 2,
  "name": "gmail-send",
  "app": "Google Chrome",
  "params": {"recipient": ..., "subject": ..., "body": ...},
  "preconditions": {"url_contains": "mail.google.com"},
  "steps": [
    {"action": "click", "target": {"AXRole": "AXButton", "computedNameContains": "Compose"}, "wait_after": {"condition": "elementExists", "value": "To recipients", "timeout": 5}},
    ...
    {"action": "hotkey", "params": {"keys": "cmd,return"}, "wait_after": {"condition": "elementGone", "value": "Send", "timeout": 10}}
  ]
}
```

Bundled recipes: `gmail-send`, `slack-send`, `arxiv-download`, `finder-create-folder`.

## Self-Learning (v2.2.1)

```
ghost_learn_start task_description:"send email in Gmail"
...user performs the task manually...
ghost_learn_stop
→ returns enriched action sequence (CGEvent tap + AX tree context)
→ agent synthesizes parameterized recipe
→ ghost_recipe_save
```

No screenshots. No vision model during learning. Pure accessibility events via CGEvent tap enriched with AX context at each step. Requires Input Monitoring permission.

## 29 Tools

**Perception:** `ghost_context` (current app/window/URL/elements), `ghost_state` (all running apps + windows), `ghost_find` (search by name/role/DOM id/CSS class), `ghost_read` (extract text), `ghost_inspect` (element metadata), `ghost_element_at` (element at coordinates)

**Vision:** `ghost_ground` (ShowUI-2B visual grounding), `ghost_parse_screen` (detect all elements visually), `ghost_screenshot`, `ghost_annotate` (screenshot + numbered labels + coordinates)

**Actions:** `ghost_click`, `ghost_type`, `ghost_hover`, `ghost_long_press`, `ghost_drag`, `ghost_press`, `ghost_hotkey`, `ghost_scroll`

**Windows:** `ghost_focus`, `ghost_window` (minimize/maximize/close/move/resize), `ghost_wait` (URL change / element appear/disappear / title change)

**Recipes:** `ghost_recipes`, `ghost_run`, `ghost_recipe_show`, `ghost_recipe_save`, `ghost_recipe_delete`

**Learning:** `ghost_learn_start`, `ghost_learn_stop`, `ghost_learn_status`

## MCP Agent Instructions (GHOST-MCP.md)

Bundled system prompt for the MCP client:
1. Always check recipes first before doing anything manually
2. Orient with `ghost_context` before acting (or you'll click the wrong thing)
3. Find elements by: DOM id (most reliable for web) → identifier (native) → role+query → query alone
4. Perception tools work from background (no app focus needed); action tools try AX-native first then synthetic fallback

## Permissions Required

- Accessibility (for AX tree reads and native AX actions)
- Screen Recording (for screenshots and vision sidecar)
- Input Monitoring (for `ghost_learn_*` only)

`ghost setup` configures all of them.

## Diagnostics

```bash
ghost doctor
# → checks all permissions, MCP config, recipes, AX tree, vision model
```

## Companion: Shadow

`ghostwright/shadow` — 14-modality ambient capture, proactive suggestions, episode generation, on-device LLM inference, computer-use training data. Separate project, integrates with Ghost OS.

## Relevance

- Automates any macOS desktop workflow, not just browsers
- Native Slack, Apple Notes, Messages, Finder — all AX tree first-class
- `ghost_learn_start` → show it a workflow → recipe saved — meaningfully different from writing automation scripts
- Slack recipe navigates via Cmd+K (how a human would) rather than clicking sidebar elements
- MCP means it works with Claude Code (which we actively use) out of the box
- Single install, `ghost setup` handles everything
