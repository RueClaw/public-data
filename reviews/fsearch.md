# FSearch (noahdunnagan/fsearch)

**Repo:** https://github.com/noahdunnagan/fsearch
**License:** MIT (free extraction and reuse)
**Reviewed:** 2026-10-11 (repo created 2026-10-08, three days old; 1.7K★, 108 forks)
**Stack:** Rust (edition 2024), ~9,050 lines, zero network dependencies; macOS-only (`getattrlistbulk`, FSEvents, mmap)
**What it is:** Whole-disk file search for macOS: fuzzy name search with typo tolerance, plus trigram-indexed content grep, served by a small daemon over a local Unix socket (or as a Rust crate).

---

## Verdict

✅ **Deploy candidate — the fastest local file-search tool we've verified, with the caveats of a three-day-old project.** It works as claimed on this machine: sub-millisecond name queries, one-edit typo tolerance, live FSEvents updates in ~1s, trigram content grep and symbol lookup all verified working against a real 4.4M-entry disk index. CLI-to-answer took 10 ms; the daemon-reported query time was 111 µs. Zero network dependencies, MIT, ~9K auditable lines. Caveats: zero automated tests, v0.1.0, single author, three days old, and full coverage means granting Full Disk Access to the daemon — a whole-disk read grant for a brand-new binary. Run it without FDA first (it skips consent-gated folders instead of prompting), or accept the grant knowing it reads locally and phones nowhere.

---

## What It Is

FSearch indexes your entire disk once (~50 s on the author's 8.3M-file M4 Max), then keeps the index live off FSEvents with ~0.1 s propagation. Queries are fuzzy by default, with one-typo forgiveness on 5+ letter words, plus filters: `ext: type: kind: in: size: mtime: re: path: grep: regex: sym: limit:` and `'exact`, `^prefix`, `suffix$`, `!exclude` operators. A daemon owns the index; CLI and any app share it (first process owns, the rest follow), communicating JSON-lines over a Unix socket or `fsearch stdio`. Also usable as a linked Rust crate (`fsearch::Engine`).

## Stack

| Layer | Detail |
|-------|--------|
| Language | Rust 2024, 10 source files, ~9,050 lines |
| Deps | libc, rayon, memchr, memmap2, regex, serde — no network crates |
| Name index | One mmap'd file, folder-by-folder (so `in:` is a range), letter bitmaps |
| Content index | Trigram index + per-file filter; identical files indexed once |
| Freshness | FSEvents follow; restart replays only what changed |
| Interface | CLI, daemon, JSON-lines Unix socket, `stdio` mode, library crate |
| Tests | **None** (0 tests in the tree) |

## Key Features

### Genuinely fast, verified locally
On this machine (4.46M entries, 194 MB index): typo-tolerant name search, live file-addition pickup within 1 s, content grep with correct line output, and a 10 ms end-to-end CLI query. The author's 0.13 ms name-search claim is consistent with the observed 111 µs daemon query time.

### Smart defaults for consent-gated folders
Without Full Disk Access it indexes everything it can and skips protected folders silently instead of nagging. With FDA it covers the whole disk. Honest design: it tells you which mode it's in.

### One index, many clients
Single-writer lock on the index; the CLI starts the daemon on demand; a GUI app can share the same index via the socket or the crate. Matches are read fresh from disk, so results never serve stale content.

### Small and auditable
Nine thousand lines, eight dependencies, no network surface, no telemetry. The entire trust question reduces to the local binary.

## Limitations

- **Zero automated tests** — nothing in CI, no `#[test]` anywhere. All verification is manual or ours.
- **Three days old, single author, v0.1.0** — expect churn.
- **macOS-only** by design (`getattrlistbulk`, FSEvents).
- **FDA is a whole-disk read grant** to the daemon. Reasonable for its purpose, but it's a trust decision about a brand-new binary. The mitigations: no network deps, open source, small codebase, works without FDA.
- **Socket has no explicit permission tightening** — relies on `~/Library/Application Support` being user-private (standard macOS practice).
- ~84 `unsafe` blocks — expected for syscall/mmap/FSEvents work, unreviewed.

## Local Verification

Built with `cargo build --release` (clean, 22 s). Ran the daemon with an isolated index dir, let it index the disk (4,456,265 entries), then verified: fuzzy name search, `mian.rs` → `main.rs` typo tolerance, `ext:rs grep:apply_dir` content search, `sym:apply_dir`, a new file appearing in results ~1 s after creation, JSON output (`took_us: 111`), and CLI latency of 10 ms. Daemon and 194 MB test index removed after the run.

## Who Should Use It

Anyone on macOS who wants Spotlight-class search from the terminal, agents included — the JSON-lines socket/`stdio` interface is agent-native by design. If you need ranked retrieval over data exports (JSONL/CSV/DB) rather than files, that's Leviathan's niche, not this.

---

**Attribution:** noahdunnagan/fsearch, MIT. Speed figures are the author's measurements except where marked as locally verified.
