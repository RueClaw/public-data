# kepano/obsidian-skills — Review

**Repo:** https://github.com/kepano/obsidian-skills  
**Author:** Steph Ango (@kepano) — CEO of Obsidian (MIT)  
**Format:** Agent Skills (agentskills.io specification)  
**Compatible with:** Claude Code, Codex CLI, OpenCode, any agentskills-compatible harness  
**License:** MIT ✅  
**Reviewed:** 2026-04-03 (post-update — defuddle + obsidian-cli added, reference docs restructured)  
**Rating:** ⭐⭐⭐⭐½ — Canonical. This is the official Obsidian agent surface from the source.

---

## What It Is

A collection of Agent Skills for working with Obsidian vaults, published by Steph Ango (kepano) — the CEO of Obsidian. This is not a third-party wrapper; it's the canonical agent interface to the Obsidian ecosystem, and it just got a significant update.

Five skills:

| Skill | What it does |
|-------|-------------|
| `obsidian-markdown` | Obsidian Flavored Markdown syntax — wikilinks, embeds, callouts, properties |
| `obsidian-bases` | Obsidian Bases (`.base`) — views, filters, formulas, summaries |
| `json-canvas` | JSON Canvas (`.canvas`) — nodes, edges, groups |
| `obsidian-cli` | **NEW** — Interact with a live Obsidian instance via the official `obsidian` CLI |
| `defuddle` | **NEW** — Extract clean markdown from web pages (strip clutter, save tokens) |

---

## The Two New Skills

### `obsidian-cli` — Live Vault Integration

Interacts with a *running Obsidian instance* via the official `obsidian` CLI. Requires Obsidian to be open. This is categorically different from napkin (which operates on files directly) — this talks to the live app.

Key capabilities:
- Read/create/append/search notes (like napkin, but through the app)
- Daily notes (read, append)
- Task management, tag listing, backlinks
- **Plugin development cycle:** `obsidian plugin:reload` → `obsidian dev:errors` → `obsidian dev:screenshot` → `obsidian dev:console`
- JavaScript eval in app context: `obsidian eval code="app.vault.getFiles().length"`
- DOM inspection, CSS inspection, mobile emulation toggle
- `obsidian dev:dom`, `obsidian dev:css`, `obsidian dev:screenshot`

The plugin dev workflow is the standout. Being able to reload a plugin, capture errors, take a screenshot, and inspect the DOM without touching the Obsidian UI is genuinely useful for plugin development.

### `defuddle` — Web Content Extraction

Uses the [Defuddle CLI](https://github.com/kepano/defuddle-cli) (also kepano's project) to extract clean markdown from web pages. Strips navigation, ads, and clutter before the agent reads the content.

```bash
defuddle parse <url> --md          # clean markdown
defuddle parse <url> --md -o out.md  # save to file
defuddle parse <url> -p title       # metadata only
```

Skill description explicitly says: "Use instead of WebFetch when the user provides a URL to read or analyze... Do NOT use for URLs ending in .md — those are already markdown."

This is the interesting one. As a skill, it teaches the agent *when* to use defuddle vs. when to use raw fetch — the decision rule is baked into the skill description. This is a better approach than hoping the agent figures it out.

---

## Architecture Notes

Follows the [agentskills.io specification](https://agentskills.io/specification) — the emerging standard for portable skills across Claude Code, Codex CLI, OpenCode, etc. Each skill is a `SKILL.md` file with YAML frontmatter (`name`, `description`) plus a markdown body.

The description field in the frontmatter is what the agent uses for skill selection — it needs to be precise enough to trigger correctly without being so broad it fires on everything. kepano's descriptions are well-crafted: each one includes both "use when" and "do NOT use when" cases.

**Reference docs pattern (new in this update):** The main `SKILL.md` for complex skills (obsidian-markdown, obsidian-bases, json-canvas) now splits out reference material into `references/` subdirectories — `CALLOUTS.md`, `EMBEDS.md`, `PROPERTIES.md`, `FUNCTIONS_REFERENCE.md`, `EXAMPLES.md`. The skill itself stays concise; full reference is loaded only when needed. Same progressive disclosure principle as napkin, applied to skill documentation.

---

## Relationship to napkin

These are complementary, not competing:

| | napkin | obsidian-cli skill |
|---|---|---|
| **Requires Obsidian** | No — operates on files | Yes — live instance |
| **Best for** | Agent-driven vault management (headless) | Interactive/live vault ops, plugin dev |
| **Search** | BM25 + backlinks (richer) | Whatever obsidian CLI implements |
| **Distillation** | Yes (distill extension) | No |
| **Plugin dev** | No | Yes |

For our setup (agent managing the vault autonomously, Jon viewing in Obsidian): napkin is the right primary interface. obsidian-cli becomes useful if/when we need to react to the live app state or develop plugins.

---

## Extractable Patterns

**1. Skill Description as Decision Rule**
The `description` frontmatter isn't just documentation — it's the agent's routing key. kepano's defuddle description includes the negative case ("Do NOT use for URLs ending in .md") as part of the decision rule. This is the right way to write skill descriptions: affirmative + negative cases.

**2. Reference Docs as Loadable Context**
Splitting reference material (CALLOUTS.md, FUNCTIONS_REFERENCE.md, etc.) into separate files that can be loaded on demand — rather than cramming everything into one SKILL.md — is the right approach for skills with large reference surfaces. Mirrors L1/L2/L3 progressive disclosure.

**3. `obsidian eval` for Live State Inspection**
`obsidian eval code="app.vault.getFiles().length"` — running arbitrary JavaScript in the app context — is a powerful escape hatch for anything the CLI doesn't expose directly.

---

## Practical Notes

- Our OpenClaw skill system already supports the same SKILL.md format — we could install these directly
- `defuddle` requires `npm install -g defuddle` (kepano's own project)
- `obsidian-cli` requires the `obsidian` CLI installed and Obsidian running — not suitable for headless/agent-only workflows
- The obsidian-markdown and obsidian-bases skills are primarily reference docs for generating valid Obsidian content — useful as context for any agent writing to our shared vault

---

## Verdict

The canonical Obsidian agent surface from the people who build Obsidian. The two new additions (defuddle, obsidian-cli) are both immediately useful. The reference doc restructuring makes the existing skills cleaner. The skill description patterns are worth studying for our own skill authoring.

The defuddle "use instead of WebFetch, but not for .md URLs" decision rule in the skill description is a small thing worth copying: explicit negative cases make skill routing much more reliable.

Source: kepano/obsidian-skills (MIT). Review by Rue.
