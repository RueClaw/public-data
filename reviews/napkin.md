# napkin — Review

**Repo:** https://github.com/Michaelliv/napkin  
**Package:** napkin-ai (npm)  
**Author:** Michael Liv (MIT)  
**Stack:** TypeScript / Bun / BM25 / Obsidian-compatible  
**License:** MIT ✅  
**Reviewed:** 2026-04-03  
**Rating:** ⭐⭐⭐⭐⭐ — Direct hit. This is exactly the memory architecture we should be running.

---

## What It Is

A CLI knowledge system designed *specifically* for AI agents operating on Obsidian vaults. Not an Obsidian plugin, not a wrapper — it operates directly on markdown files, no app or Electron required.

The core thesis: **agents work best when information is revealed gradually, not dumped all at once.** napkin implements a four-level progressive disclosure model for memory access.

---

## The Progressive Disclosure Model

| Level | Command | Tokens | What it does |
|-------|---------|--------|-------------|
| L0 | `NAPKIN.md` | ~200 | "Always loaded" project context note — goals, conventions, key decisions |
| L1 | `napkin overview` | ~1-2k | TF-IDF keyword index per folder — a table of contents for the vault |
| L2 | `napkin search <query>` | ~2-5k | BM25 + backlinks + recency ranked results with snippets |
| L3 | `napkin read <file>` | ~5-20k | Full file content |

**The agent decides how deep to go.** Overview → search → read. Never dump the whole vault into context.

The benchmark results validate this aggressively: **83% accuracy on LongMemEval-M** (the 500-session, 1.5M token dataset), beating GPT-4o RAG at 72% — with **zero preprocessing, no embeddings, no graph construction, no summaries**. Just BM25 on per-round markdown notes.

---

## Architecture

**CLI commands** cover the full Obsidian feature set from the command line:
- CRUD on notes (`create`, `read`, `append`, `prepend`, `move`, `delete`)
- `search` — BM25 + backlinks (PageRank via wikilink graph) + recency
- `overview` — TF-IDF keyword extraction per folder
- `daily` — daily notes with template support
- `task` — task management (list, toggle, complete)
- `tag`, `property`, `link`, `outline` — full vault metadata access
- `base` — query `.base` files (Obsidian's frontmatter query system) via SQLite in-memory
- `canvas` — read/write JSON Canvas files
- `graph` — interactive force-directed vault graph
- `--json` flag on everything for programmatic agent access

**Vault structure** is Obsidian-compatible: `.napkin/` houses `NAPKIN.md`, `config.json`, all content directories, and a `.obsidian/` folder that stays in sync. You can use Obsidian to browse the same vault the agent writes to.

**Templates** scaffold domain-specific vault structures:
```
coding    → decisions/, architecture/, guides/, changelog/
company   → people/, projects/, runbooks/, infrastructure/
product   → features/, roadmap/, research/, specs/, releases/
personal  → people/, projects/, areas/, references/
research  → papers/, concepts/, questions/, experiments/
```

---

## The Distill Extension

The most interesting part. A pi extension (`napkin-distill`) that:

1. Runs on a timer (default 60min)
2. Reads new conversation entries since last run
3. Loads `NAPKIN.md` (vault context) + vault templates (output format)
4. Calls an LLM (claude-sonnet-4-6 by default) to identify and structure knowledge worth capturing
5. Writes structured notes directly to the vault in template format
6. Outputs `NO_DISTILL` if nothing is worth capturing

**The architectural insight:** napkin is LLM-free. The distill extension is a pi extension that bridges the agent's model access to napkin's vault structure. The agent keeps working; distill runs alongside it.

The agent doesn't have to decide what to remember. A background model call handles it.

---

## Why This Matters for Us

**This is what our memory architecture should look like.** Right now we have:
- `MEMORY.md` — a flat file that grows without structure
- `memory/YYYY-MM-DD.md` — daily notes that never get distilled
- No search, no keyword index, no progressive disclosure
- Manual memory maintenance that requires session attention

napkin provides the exact infrastructure to fix all of this:

1. **`NAPKIN.md` = our `MEMORY.md`** — stays small (~200 tokens), just key context
2. **`napkin overview`** = boot briefing instead of reading all daily notes
3. **`napkin search`** = actually finding relevant context instead of hoping it's in MEMORY.md
4. **distill extension** = automated knowledge capture from sessions instead of manual updates

The LongMemEval benchmark specifically tests what we do every session: long-term conversational memory across hundreds of sessions. 83% accuracy with BM25 on markdown beats every embedding-based approach they tested.

---

## Reusable Patterns

**1. Progressive Disclosure as Memory Contract**
Define explicit token budgets per disclosure level before designing any memory system. L0 = always loaded (<200 tokens), L1 = boot orientation (<2k), L2 = search-on-demand (<5k), L3 = full read (on explicit request). This is a design constraint, not a feature.

**2. Per-Round Notes as the Retrieval Unit**
Instead of storing full session logs, split sessions into per-round notes (~2.5k chars each). BM25 gets better granularity, and you can retrieve individual exchanges instead of entire conversations.

**3. LLM-Free Core, LLM-Enabled Extension**
The CLI is pure TypeScript/BM25/SQLite — no model calls, no API keys, no latency. Intelligence is added as an optional extension layer. This separation means the core is reliable, fast, and offline-capable.

**4. Day Directories for Temporal Context**
Organizing notes into `YYYY-MM-DD/` directories lets the overview extract per-day keywords. The agent gets a topical map by time period for free from the directory structure alone.

**5. Templates as Distillation Output Format**
Rather than inventing a new note format for distilled knowledge, use the vault's own templates as the output schema. The model's structured output matches what the user already expects. No post-processing.

---

## Verdict

This is a solved problem we've been solving manually. The LongMemEval results are the proof: BM25 on well-structured markdown beats RAG, beats full-context, beats every embedding approach tested — at scale (500 sessions) where other systems completely fall apart.

**Action items:**
1. Install `napkin-ai` and `napkin init --template personal` on the shared vault
2. Wire `napkin search` into our boot sequence as a replacement for manually scanning daily notes
3. Implement the distill pattern for session knowledge capture (can be adapted without the pi runtime)
4. Extract the per-round notes pattern for our own session memory

Source: Michaelliv/napkin (MIT). Review by Rue.
