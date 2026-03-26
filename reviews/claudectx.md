# claudectx (foxj77/claudectx)

*Review #263 | Source: https://github.com/foxj77/claudectx | License: MIT | Author: John Fox | Reviewed: 2026-03-26*

## Rating: 🔥🔥🔥🔥

---

## What It Is

`kubectx` for Claude Code. Lets you switch your entire Claude Code configuration — `settings.json`, `CLAUDE.md`, MCP server list — with a single command or TUI picker. Built in Go, ~5800 lines, zero heavy dependencies.

## What It Does

- **Profile switching:** `claudectx work` swaps settings + CLAUDE.md atomically
- **Interactive TUI:** `claudectx` (no args) → arrow-key picker
- **Toggle:** `claudectx -` bounces between last two profiles
- **MCP config per profile:** Reads/writes `~/.claude.json` mcpServers field, preserving all other fields with `json.RawMessage` passthrough — clean pattern
- **Export/import:** JSON bundles for team sharing or machine transfer
- **Health check:** Validates a profile's settings before switching
- **Auto-backup:** Timestamped backup in `~/.claude/backups/` before every switch
- **Atomic rollback:** If switch fails mid-way, restores previous config automatically
- **Sync detection:** `claudectx sync` compares active config to stored profile via MD5, detects drift

## Architecture

Layered Go packages under `internal/`:
- `store` — profile persistence at `~/.claude/profiles/<name>/`
- `profile` — struct + validation
- `config` — settings.json read/write
- `mcpconfig` — surgical mcpServers patch (json.RawMessage trick to preserve unknown fields)
- `backup` — timestamped snapshots
- `validator` — pre-switch checks
- `selector` — raw terminal TUI (only dep: `golang.org/x/term`)
- `paths` — XDG-aware path resolution

Storage layout:
```
~/.claude/
├── .claudectx-current     # active profile name
├── .claudectx-previous    # enables toggle
├── profiles/
│   ├── work/
│   │   ├── settings.json
│   │   └── CLAUDE.md
│   └── personal/
│       ├── settings.json
│       └── CLAUDE.md
├── backups/               # automatic before each switch
└── settings.json          # active (copied, not symlinked)
```

## What's Good

- **MCP-per-profile is underrated** — different clients need different MCP servers. This handles it cleanly without touching the rest of `~/.claude.json`
- **Sync drift detection** — catches the "I tweaked settings manually and forgot" case
- **Minimal deps** — just `golang.org/x/term`. No cobra, no bubbletea, no viper. Respectable.
- **Rollback on failure** — the kind of thing most quick CLI tools skip

## What's Missing

- No encryption for profiles containing API keys (they're plaintext JSON)
- No `claudectx diff` to show what would change before switching
- Sync is one-way detection only — no `claudectx sync push` to write drift back to profile
- Would benefit from a `--dry-run` flag on switch

## Patterns Worth Stealing

**`json.RawMessage` surgical patch** (internal/mcpconfig): read the whole file into `map[string]json.RawMessage`, update only the key you own, write back. Zero schema drift on fields you don't know about. Copy this for any tool that needs to edit a subset of a JSON config it doesn't fully control.

**Atomic swap with rollback** (cmd/switch.go): backup → validate → copy → verify → if error, restore backup. Straightforward but done right.

## Relevance

Direct utility: we have multiple Claude Code contexts (ODR project, Rue's global setup, potentially client-specific rulesets). `claudectx` handles this cleanly. Pairs well with `.claude/rules/` per-profile.

Also relevant for Debbie — she'll eventually need her own Claude Code profiles separate from Rue's.

Install: `brew install foxj77/tap/claudectx`
