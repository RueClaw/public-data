# FSearch (noahdunnagan/fsearch)

**Repo:** https://github.com/noahdunnagan/fsearch
**License:** MIT; see license details below for reuse obligations.
**Reviewed:** 2026-10-12 (UTC)
**Revision:** `ffcb37d9297e716fcfdcef3169d752fcf18e3b1b`
**Scope:** root crate, src, examples, manifest and license
**Verification:** Static source review only. No source code, installs, tests, builds, generated pages or benchmarks executed. Any upstream CI result is separately attributed.
**Stack:** Rust 2024 · mmap · FSEvents
**What it is:** macOS filename and indexed-content search through a local daemon, CLI and Rust library.

---

## Verdict

⚠️ **Interesting.** Interesting for an isolated macOS pilot, not yet a privileged agent-facing deployment recommendation. The specialist index design is compelling, but missing regression CI, service bounds and symlink confinement need attention.

## Update Notes

Checked 2026-10-12 UTC. Previous review dated 2026-10-11 recorded no exact source revision. This revision-pinned refresh changes Deploy candidate to Interesting, clarifies content-search coverage and service trust boundaries, and replaces unreproduced historical local performance claims with explicitly attributed source claims. No source delta is asserted against the unrecorded previous revision.

## What It Is

macOS filename and indexed-content search through a local daemon, CLI and Rust library. Folder-local mmap names and deduplicated trigram/Bloom-filter content searches offer a credible low-latency design. Published speed figures were not reproduced.

## Stack

| Layer | Technology |
|---|---|
| Implementation | Rust 2024 · mmap · FSEvents |
| Reviewed boundary | root crate, src, examples, manifest and license |

## Key Features

### Specialist index

Folder-local mmap names and deduplicated trigram/Bloom-filter content searches offer a credible low-latency design. Published speed figures were not reproduced.

### Not exhaustive grep

Content eligibility, size caps, indexing lag and query budgets constrain recall. Search absence is not proof a file or secret does not exist.

### Local does not mean sandboxed

Full Disk Access is broad authority. Socket bounds, permissions and ancestor-symlink handling deserve explicit hardening.

## Architecture, Evidence and Security

## Metadata
Public GitHub API snapshot: created 2026-10-08; pushed 2026-10-11T03:00:37Z; 1,892 stars; 124 forks; not archived; main branch. API open_issues_count=13 includes pull requests: queried list contains 3 open issues and 10 open PRs. Releases endpoint returns [] (no GitHub releases). Cargo package 0.1.0, edition 2024; Cargo.lock committed. Actual root LICENSE is MIT (copyright Noah Dunnagan 2026), matching manifest. MIT permits commercial use/modification/distribution with copyright and permission notice retained, no warranty; dependency licenses need separate distribution review.
Sources: https://api.github.com/repos/noahdunnagan/fsearch ; https://api.github.com/repos/noahdunnagan/fsearch/releases ; https://api.github.com/repos/noahdunnagan/fsearch/issues?state=open&per_page=30
License: https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/LICENSE#L1-L21
Manifest: https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/Cargo.toml#L1-L21

## Architecture and value
macOS-specific CLI/daemon plus embeddable Rust Engine. Parallel getattrlistbulk traversal enumerates file metadata, avoids crossing mount points, understands firmlinks; FSEvents drives updates/replay. Memory-mapped name index uses folder locality, name character bitmaps, fuzzy/typo scoring. Content index has immutable mmap segments, deduplicated content IDs, trigram posting lists and 5-/7-byte Bloom filters; candidate files are reread for actual matches. Locking elects a single index writer while followers share saved state. CLI/stdio and Unix-domain JSON-lines socket expose name and content searches, no external search provider or embeddings required. Not semantic/vector search.
Architecture citations:
- https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/README.md#L52-L80
- https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/walk.rs#L1-L6
- https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/content.rs#L1-L18
- https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/engine.rs#L80-L108

## Findings
1. **Attractive specialist performance design, but benchmark claims are not independently proven.** README gives M4 Max/8.3M-file medians of 0.13ms filename searches, 2.3ms content search, 3.3ms CLI latency and 49s initial readiness; compares an earlier version rather than competing tools. Content index disk use increases 0.32GB→0.76GB in its Chromium case. Keep-warm explicitly spins a CPU during its window, so low repeated-interaction latency has a power tradeoff. This is promising engineering, not a universally established speed claim.
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/README.md#L12-L29
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/engine.rs#L144-L175

2. **Privileged local search is not a hardened agent/service boundary.** README encourages Full Disk Access; server binds a local socket and dispatches each connection to a new thread. Reviewed source has no explicit chmod/umask hardening or peer-identity authentication; effective exposure depends on macOS socket and ancestor permissions, not a demonstrated cross-user exploit. BufReader.lines has no request-size bound or timeout; connection count is uncapped, per_file and limit accept user values, and budget_ms=0 disables the grep deadline. Any connector should enforce a strict per-user socket/dir boundary, fixed search roots and result/request/concurrency ceilings; do not expose it directly over a network or give untrusted model input unrestricted whole-disk search. Content results can include private text.
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/README.md#L45-L55
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/server.rs#L16-L41
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/server.rs#L77-L95
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/server.rs#L195-L249

3. **Concrete symlink ancestor caveat.** open_sized uses O_NONBLOCK and O_NOFOLLOW and verifies a regular file: good FIFO/leaf-symlink protections. O_NOFOLLOW here protects only the final pathname component, not symlinked ancestors. A previously indexed directory replaced with a symlink can redirect later full-path reads, subject to actual filesystem permissions/races. Do not treat lexical in: filtering as a security sandbox. This is independently visible in code; open PR #22 “Full-path opens: reject symlinked ancestors” also tracks the area, but is not merged into reviewed SHA. Recommend fd-relative traversal/appropriate macOS no-follow-any semantics with regressions before relying on root confinement.
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/content.rs#L3137-L3151
https://github.com/noahdunnagan/fsearch/pull/22

4. **Search completeness needs explicit consumer handling.** Indexed content is only eligible text under HOME, excludes many generated/cache/library trees, caps files at 1MiB (extensionless at 256KiB), skips minified JS and package-lock.json. Default output is 5 matching lines/file with a 250ms budget. Responses expose complete and indexing, while candidates can lag writes; fresh rereads prevent stale matching text but cannot guarantee no missed new matches. complete means budget/limit handling within eligible candidates, not whole-disk exhaustive grep. The symbol mode is declaration-pattern matching, not language-aware AST indexing. Good interactive discovery, unsuitable as sole evidence that no secret/string/symbol exists.
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/content.rs#L32-L85
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/content.rs#L1055-L1085
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/content.rs#L2290-L2309
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/server.rs#L224-L233
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/content.rs#L2406-L2445

5. **Very early maturity, weak checked-in verification story.** No tracked .github workflows, tests directory, or #[test] cases at this SHA. examples/rig.rs and examples/e2e.rs are benchmarking/comparison harnesses, not a CI-enforced regression suite; e2e compare prints differing response counts, rather than failing with assertions. Open PRs #12/#13/#14 propose tests; #27 proposes releases, but not present on main. Issue #16 reports potential unbounded FSEvents/Live::priors memory growth and PR #25 proposes a fix; these are unverified reports, not proof of a runtime failure in this review. Unsafe mmap/FFI and custom allocation increase audit value, especially with no demonstrated stress coverage. Never load externally supplied index files as trusted data: loaders validate magic/layout length but are not presented as hardened parsers.
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/examples/e2e.rs#L1-L22
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/examples/e2e.rs#L264-L289
https://github.com/noahdunnagan/fsearch/blob/ffcb37d9297e716fcfdcef3169d752fcf18e3b1b/src/index.rs#L541-L589
https://github.com/noahdunnagan/fsearch/issues/16
https://github.com/noahdunnagan/fsearch/pull/25


## Comparison

ripgrep with fd/fzf favors mature cross-platform composition; Spotlight favors OS integration; Recoll targets document search. These are fit comparisons, not separately benchmarked or audited alternatives.

## Self-Hosting Notes

macOS-specific. Start without Full Disk Access and keep index/socket directories private. Do not relay unrestricted whole-disk results to an agent or network service.

## Verification and Limitations

Public unauthenticated source acquisition and static inspection at the exact revision above. No runtime, exploit, performance, model-quality, dependency-vulnerability or distribution-provenance verification was performed. Review is sampled, not exhaustive; absence of an observed problem is not a security guarantee. Public metadata is a 2026-10-12 snapshot and not evidence of quality.

---

**Attribution:** [noahdunnagan/fsearch](https://github.com/noahdunnagan/fsearch), MIT. Source claims and upstream status are distinguished from this review’s static findings.
