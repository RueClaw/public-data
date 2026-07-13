# Personal Claude Code Cheat Sheet (sants2001/personal-claude-code-cheatsheet)

**Repo:** https://github.com/sants2001/personal-claude-code-cheatsheet  
**License:** No license file detected; README claims MIT, but GitHub reports no license. Treat as educational/personal-use-only until a real license is added.  
**Reviewed:** 2026-07-12  
**Stack:** Single Claude Code Agent Skill, static HTML example, inline CSS/JS  
**What it is:** A Claude Code skill that asks the agent to generate a personalized offline HTML cheat sheet from the current session's skill list and local Claude configuration files.

---

## Verdict

⚠️ **Interesting small skill, but not install-ready as shared infrastructure.** The idea is useful: make a user's live skill inventory and local conventions visible in one searchable offline page. The repo is also tiny and easy to inspect. The blockers are practical: no committed license despite MIT badges, no installer/package manifest beyond README instructions, no tests or validation harness, and the generated content depends on the model correctly extracting session/config data.

---

## What It Is

This repo contains three files: `SKILL.md`, `README.md`, and `example.html`. The skill defines a `/cheatsheet` command that should collect the current Claude Code session's live skill list, optional `CLAUDE.md` files, model routing rules, and local usage patterns, then write a self-contained dark-theme HTML reference to `~/Claude Code/cheatsheet.html` or `~/Desktop/claude-cheatsheet.html`.

The intended output has eight tabs: shortcuts, skills, prompt patterns, precision techniques, token guidance, model routing, full catalog, and a "How Claude Works" explainer. The example HTML is a static, offline-capable artifact with inline CSS and JavaScript, global search, tab navigation, collapsible skill categories, and copy buttons.

The strongest idea is not the specific cheat sheet content; it is the "reflect the live agent setup back to the user" pattern. Agent skill catalogs and local instruction files get invisible quickly. A generated, searchable local reference is a good way to make that configuration legible.

## Stack

| Layer | Tech |
|-------|------|
| Skill | Claude Code `SKILL.md` with `/cheatsheet` trigger |
| Output | Single-file HTML, inline CSS, inline JavaScript |
| Data inputs | Current session skill list, `~/.claude/CLAUDE.md`, `~/CLAUDE.md`, optional rules files |
| Packaging | README `npx skills add` instruction; no package manifest in repo |
| Tests | None detected |

## Key Features

### Live Skill Inventory

The skill tells Claude to use the live skills list from the current session rather than scraping a directory. If the host session exposes that list reliably, the generated cheat sheet reflects what the user can actually invoke right now.

### Offline HTML Artifact

The example page is self-contained: no CDN, no `fetch()` calls, and no external script or stylesheet references. Copy buttons use `navigator.clipboard` with a textarea fallback.

### Personal Configuration Awareness

The skill asks Claude to read local `CLAUDE.md` files and model-routing/pattern rules when present, then tailor the cheat sheet with name, stack, trigger table, autonomy rules, and routing preferences.

### Meta-Usage Guidance

The content includes useful reminders about context window behavior, hallucination triggers, feedback loops, model routing, and precision prompting. Some of it is host-specific and should be regenerated for the user's actual environment rather than treated as universal truth.

## Architecture

This is prompt-driven generation, not a deterministic tool. `SKILL.md` describes what data to gather and what HTML to produce; the model is responsible for parsing the session, extracting local config, organizing skills into categories, and writing the final file.

That keeps the repo simple, but it also means output quality depends heavily on the model and session shape. There is no parser, no schema, no fixture test, no HTML snapshot test, and no check that the generated file avoids leaking overly personal local configuration.

## Comparison

| Aspect | This Skill | visual-explainer | codebase-to-course |
|--------|------------|------------------|--------------------|
| Primary output | Personal Claude Code cheat sheet | HTML explainers/diagrams | Static codebase courses |
| Determinism | Prompt-driven only | Prompt-driven with stronger artifact guidance | Prompt-driven with structured module guidance |
| Best idea | Make live agent setup searchable | Turn dense terminal/context output visual | Teach a codebase through product-first modules |
| Main risk | No license/tests; model may leak or misclassify local config | Generated HTML quality variance | No license; large generated static site surface |

## Self-Hosting Notes

This is a local skill, not a server. Installation should be treated as an unverified prompt-layer addition:

- Inspect `SKILL.md` before installing.
- Prefer a sandbox/test Claude profile first.
- Do not publish generated cheat sheets without reviewing local `CLAUDE.md`-derived content.
- Ask the author to add a real `LICENSE` file before copying or redistributing the skill.

No local test suite exists to run. Manual review found no external network calls in the example HTML.

---

**Attribution:** sants2001/personal-claude-code-cheatsheet. No license file detected; README claims MIT.
