# Context Firewall (nik1t7n/context-firewall)

**Repo:** https://github.com/nik1t7n/context-firewall
**License:** Apache-2.0 in repository files; GitHub API reported `NOASSERTION` at review time, so downstream reuse should rely on the checked-in `LICENSE`.
**Reviewed:** 2026-06-16
**Stack:** Rust 2024, Clap, rusqlite, deterministic reducers, MCP over stdio
**What it is:** A local-first command-output firewall for coding agents. It runs noisy terminal commands, stores full stdout/stderr locally, and returns compact summaries plus span handles for exact retrieval.

---

## Verdict

✅ **Deploy candidate for local coding-agent work, with early-project caveats.** The product is narrow in the right way: it does not try to become a general context manager, it focuses on the terminal-output path where agents waste context every day. The implementation already has useful safety properties: local raw artifacts, deterministic reducers, policy checks, duplicate suppression, secret-like raw-output guard, receipts, and MCP tools.

---

## What It Is

Context Firewall wraps shell commands through `cfw run -- <command>`. It captures stdout and stderr, writes raw artifacts to a local data directory, reduces the output according to command shape, and prints a compact result with a `cfw://span/<id>` handle. If the agent needs exact evidence later, it can call `cfw show <span-id>` or retrieve a line range.

The target user is anyone running coding agents inside a real repository. Test logs, `rg` results, diffs, JSON dumps, path listings, browser snapshots, and repeated commands can dominate a turn's context. Context Firewall keeps the agent-visible part small while preserving the raw evidence on disk.

This is not a sandbox or hosted observability product. Its trust boundary is workstation-local command evidence: reduce accidental context waste, keep raw output retrievable, and make token-savings claims auditable through local receipts.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Rust 2024, Clap |
| Storage | Local filesystem artifacts plus SQLite via `rusqlite` |
| Reducers | Deterministic Rust reducers for generic, test output, git, search, logs, JSON, outline, browser snapshots |
| Policy | TOML config with default deny/generated path rules and action classes |
| Agent interface | MCP stdio server exposing `cfw_run`, `cfw_show`, `cfw_spans`, `cfw_receipt` |
| Agent adapters | Installer paths for generic AGENTS.md, Gemini, Antigravity, Claude Code, Cursor, Codex wrapper notes |
| Tests | Rust integration tests for CLI, storage, receipt JSON, secret guard, dedupe, policy, MCP, and installer behavior |

## Key Features

### Evidence-Preserving Command Compaction

The important design choice is that reduction does not destroy evidence. Every run stores raw combined output, split stdout/stderr, metadata, hashes, and a local ledger row. The agent gets a summary plus retrieval commands.

### Deterministic Reducers

Reducers are simple, auditable code rather than LLM summaries. Search results are grouped by file, test output preserves failure-looking lines and summaries, JSON output becomes shape/samples, logs preserve severity lines and context, and browser snapshots preserve roles and key accessible nodes.

### MCP Tool Surface

The stdio MCP server exposes the core workflow directly to compatible agents. That matters because the best version of this pattern is not "remember to run this wrapper"; it is a first-class tool surface with raw retrieval and receipt inspection.

### Local Receipt Accounting

`cfw receipt` reports recent raw and returned token estimates, with savings tied to delivery statuses that prove compact output was returned. The token estimator is intentionally rough, but the accounting model is better than hand-wavy "compression saved a lot" claims.

### Guarded Raw Retrieval

`cfw show` checks exact raw output for common secret-like patterns and requires `--force` before printing suspicious content. That is not a secrets scanner, but it is a useful default tripwire for the most dangerous failure mode: retrieving raw logs back into an agent context.

## Architecture

The workspace is split cleanly:

- `cfw-cli` owns command execution, adapters, MCP, receipts, policy commands, and raw retrieval.
- `cfw-core` owns span/receipt/token primitives.
- `cfw-store` owns local paths and SQLite persistence.
- `cfw-policy` owns default budgets, path rules, and command classification.
- `cfw-reducers` owns deterministic compaction logic.
- `cfw-codex` owns Codex install/doctor/canary helpers.

The runtime path is straightforward: classify command, run it, capture output, choose reducer, write artifacts, compute hashes and repeat fingerprint, dedupe when useful, insert a span row, then print compact output and span metadata.

The main limitation is that delivery is currently advisory for normal shell usage: agents must route noisy commands through `cfw run` or the MCP tool. It cannot magically intercept every tool result unless a host integrates it natively.

## Comparison

| Aspect | Context Firewall | Tracebase | ctx |
|--------|------------------|-----------|-----|
| Primary purpose | Compact noisy command output while preserving raw evidence | Capture and inspect full agent session traces | Recommend relevant skills/tools/context bundles |
| Scope | Terminal command output | Agent run observability | Context selection |
| Storage | Local SQLite plus raw artifacts | Encrypted/raw trace blobs plus indexes | Knowledge graph/wiki artifacts |
| Agent surface | MCP tools plus CLI wrapper | Read-only MCP plus dashboard/API | CLI/dashboard/harness recommendations |
| Best use | Keep one coding turn clean | Debug what happened across runs | Decide what context to load |

Context Firewall pairs naturally with local agent observability tools, but it is not trying to replace them. It works earlier in the loop: before raw terminal output floods the model context.

## Self-Hosting Notes

Install from source today with:

```bash
cargo install --path crates/cfw-cli
```

Then connect an adapter:

```bash
cfw install agent
cfw install claude
cfw install cursor
cfw install gemini
```

For real use, treat the data directory as sensitive. It contains raw command output and local paths. Set `CFW_DATA_DIR` if you want explicit placement, use `cfw purge --older-than-days <n>` for retention, and avoid syncing raw artifacts into shared storage.

---

**Attribution:** nik1t7n/context-firewall, Apache-2.0.
