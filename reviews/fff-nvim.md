# fff.nvim (dmtrKovalenko/fff.nvim)

*Review #279 | Source: https://github.com/dmtrKovalenko/fff.nvim | License: MIT | Author: dmtrKovalenko | Reviewed: 2026-03-27 | Stars: 2,044*

## Rating: 🔥🔥🔥🔥🔥

---

## What It Is

A fuzzy file finder for Neovim AND an MCP server for AI agents — sharing the same Rust core. The interesting part isn't the Neovim plugin (there are plenty). It's that the MCP server gives any agent (Claude Code, Codex, OpenCode, etc.) a frecency-ranked, git-aware file search engine with persistent memory across sessions.

The pitch: agents spend too many tokens doing redundant file searches. fff remembers which files you've been in, ranks results accordingly, boosts recently-modified-and-dirty git files, and tells the agent to stop after 2 greps and just read.

---

## Architecture

Five Rust crates + Lua bindings:

- **fff-core** — frecency tracker (LMDB via heed), file picker (background scanner + fswatch), git integration (git2), scoring engine, query tracker
- **fff-grep** — ripgrep-style content search (uses ripgrep's searcher/sink pattern directly)
- **fff-query-parser** — inline constraint DSL (`*.rs query`, `src/ query`, `!tests/ query`)
- **fff-c** — C FFI layer (cbindgen-generated header), exposes the core as `libfff_c.dylib` for Bun/Node bindings
- **fff-mcp** — MCP stdio server (rmcp crate), implements `grep`, `find_files`, `multi_grep` tools

The Neovim side is Lua calling into the same Rust binary via nvim-oxi or downloaded prebuilt. The MCP server runs the same Rust core via a separate `fff-mcp` binary.

Distribution: prebuilt binaries via npm packages per platform (`fff-bin-darwin-arm64`, `fff-bin-linux-x64-gnu`, etc.), pulled via a postinstall script. Also available as a Bun/Node npm package for TypeScript consumers.

---

## The Frecency Engine

The core insight: file relevance = frequency × recency, not alphabetical or fzf score alone.

**Implementation:**
- LMDB database (heed) stores per-file access timestamps as `VecDeque<u64>` keyed by `blake3(path)`
- Decay model: `score = Σ exp(-λ * days_ago)` for all accesses within the retention window
- Decay constant: `ln(2)/10` = 10-day half-life (files accessed 10 days ago score half of today)
- Normalization: scores ≤ 10 are linear; above 10 use `10 + sqrt(score - 10)` (diminishing returns for high-frequency files)

**Two modes with different decay params:**
- **Neovim mode**: 10-day half-life, 30-day retention window. Human editing sessions are spread over weeks.
- **AI mode**: 3-day half-life, 7-day retention window. AI sessions are "shorter and more intense." Files irrelevant after a week.

**Git modification scoring:** If a file is modified in git (dirty status), it gets a bonus based on how recently it was modified, with linear interpolation between thresholds:
```
2min → 16pts | 15min → 8pts | 1hr → 4pts | 1day → 2pts | 1week → 1pt
```
AI mode compresses these: 30sec → 16pts, 5min → 8pts, 15min → 4pts, etc.

**Database GC:** Background thread periodically purges stale entries (all timestamps older than retention window) and compacts the LMDB file by rebuilding it from scratch. Clean pattern for persistent KV with time-bounded retention.

---

## The MCP Tools

Three tools exposed via stdio MCP:

**`grep`** — default tool for searching file contents. Inline constraint syntax: `*.rs MyStruct` or `src/ TODO`. Plain text first, regex when needed. Auto-expands definition context (shows struct fields, function signatures) so the agent often doesn't need a follow-up read.

**`find_files`** — fuzzy filename matching. Use when you don't have a specific identifier, just a topic or filename pattern.

**`multi_grep`** — OR logic across multiple patterns in one call. Use for case variants (`['PrepareUpload', 'prepare_upload']`) or multiple identifiers. Avoids 3 sequential grep calls.

**The instructions prompt** (hardcoded in MCP_INSTRUCTIONS) is notably opinionated about agent behavior:
- "Search BARE IDENTIFIERS only" — no regex spanning multiple tokens
- "Stop searching after 2 greps — READ the code"
- "Never use regex unless you truly need alternation"
- Explicit constraint syntax docs with ✓/✗ examples

This is the rare MCP server that ships instructions telling the agent *how to use it well*, not just what the tools do.

---

## Install for MCP (Claude Code / Codex)

```bash
curl -L https://dmtrkovalenko.dev/install-fff-mcp.sh | bash
# Then add to CLAUDE.md:
# For any file search or grep in the current git indexed directory use fff tools
```

Or via npm for Node/Bun consumers: `npm install fff` / `bun add fff`

The frecency DB defaults to `~/.cache/nvim/fff_nvim/` if Neovim exists, otherwise `~/.fff/frecency.mdb`. Shared between the Neovim plugin and MCP server — open a file in Neovim, the MCP server knows it was recently relevant.

---

## Performance Claims

The README includes a chart comparing fff against Claude Code's built-in file tools, claiming lower token usage and fewer roundtrips. The benchmark script is at `scripts/benchmark-claude.sh`. Independent verification not done, but the architecture supports the claim: frecency ranking means the first result is more likely correct, and `multi_grep` collapses sequential searches.

Also tested on the Linux kernel repo (100k files, 8GB) in the Neovim demo. The mmap warmup (pre-warming file content into page cache after initial scan) is the mechanism there.

---

## Caveats

- The MCP binary needs to be compiled from source or downloaded via the install script. The install script pulls from `dmtrkovalenko.dev` — review it before running (`install-mcp.sh` is in the repo).
- Frecency is only useful after it accumulates data. Cold start = no memory advantage.
- The "AI mode" frecency parameters are tuned for the author's workflow. May need adjustment.
- The Neovim plugin is beta — the README explicitly asks for debug logs and score sharing.

---

## Relevance

🔥🔥🔥🔥🔥 — The frecency engine is the extractable gem here. The decay model, dual-mode parameters (human vs AI session), git-status boost with interpolation, and LMDB GC pattern are all worth understanding for any system that needs to rank recently-relevant items.

**For our setup:**
- The MCP server is a direct drop-in for Claude Code sessions — `fff-mcp` handles grep and file search with frecency ranking out of the box. One install script, one line in CLAUDE.md.
- The shared frecency DB between Neovim and MCP means file relevance from human editing sessions flows into AI sessions automatically.
- The frecency decay model is directly applicable to Ori-Mnemos or any memory system that needs time-weighted relevance scoring.

MIT. Prebuilt binaries for darwin-arm64 (our platform).
