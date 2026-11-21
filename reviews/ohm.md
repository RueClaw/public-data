# Ohm (astral-experiments/ohm)

**Repo:** https://github.com/astral-experiments/ohm
**Owner:** Astral experiments; copyright Astral Software Inc. and contributors.
**License:** MIT OR Apache-2.0, at the recipient’s option; shipped compiler, LLVM, linker and dependency notices remain applicable.
**Reviewed:** 2026-11-21 (UTC)
**Revision:** 9d19afd7f3601d325408293a95601b27a46243bb (main; committed 2026-11-21T17:55:47Z).
**Release:** ohm-1.100.0-5, published 2026-11-21T17:51:02Z; release API target commit 88080fb93fc9bb27f2341059835262bdc7997de9, distinct from the reviewed documentation snapshot.
**Scope:** Coordinator README, architecture/optimization/benchmark documents, release manifests, installer, source verifier, packaging, smoke tests, CI and selected pinned Cargo linker/cache modules and regression-test sources. Not a complete audit of the four toolchain forks.
**Verification:** Static review; independent headline arithmetic checked. No installation, compilation, source tests, benchmark replay, toolchain execution or service/device probes.
**Stack:** Rust toolchain forks; Python and POSIX shell/Bash coordinator; rustup; LLVM; Wild linker on supported Linux.
**What it is:** An experimental Rust development toolchain that reduces recompilation and shares build artifacts across local worktrees. This repository coordinates releases and measurements; it is not the complete compiler implementation.

## Verdict

⚠️ **Interesting — a serious iteration-speed experiment, not an authoritative compiler gate.** Release pinning, benchmark provenance and defensive installer handling are substantive. However, the project explicitly accepts potentially unsound reuse and forbids relying on Ohm for production builds, releases, CI correctness or final test results. Keep normal Rust authoritative, and evaluate only on trusted, disposable development workloads. [Security policy][security]

## What It Is

Ohm distributes matching rustc, Cargo, Clippy, rustfmt and a sysroot as a custom rustup toolchain, selected explicitly rather than replacing the default compiler. It targets Apple Silicon macOS and x86-64 GNU/Linux; the installer rejects other architectures, Intel-only macOS and detected musl systems. It is not a Python tool despite the coordinator’s GitHub language classification, and it is not a model runtime or an AI service. [Overview][readme] [Architecture][architecture] [Installer][installer]

The intended workload is repeated Rust edit/check/test cycles, especially many trusted worktrees. The README says all code changes, PR summaries and additional documentation were authored with GPT in Codex, while the README is human-edited. That is a provenance disclosure, not a correctness argument. No paid model call is part of ordinary toolchain use in the inspected design.

Public unauthenticated GitHub metadata and HTTPS source acquisition confirmed accessibility. Searching the public review index, README and reviews for both current and historical astral-sh/ohm identities found no existing canonical review.

## Stack and Architecture

| Layer | Implementation and boundary |
|---|---|
| Coordinator | Python benchmarks/results tooling, shell release/installation scripts, GitHub Actions |
| Compiler/sysroot | Separate ohm-rust fork, derived from upstream Rust; LLVM-based native compilation |
| Build graph | Separate ohm-cargo fork; public-interface hashing, artifact reuse and relinking |
| Developer tools | Separate Clippy and rustfmt forks, overlaid during release assembly |
| Local state | Per-worktree target/incremental state; optional shared build artifacts; GC bookkeeping |
| Linux linker | Bundled, checksum-pinned Wild 0.11.0; selected only for eligible host/target and absent explicit linker controls |
| Distribution | Versioned manifests, archives/checksums, provenance JSON, rustup custom links |

The release manifest pins these component revisions, rather than treating the coordinator SHA as the compiler identity: [Manifest][manifest]

- Rust: a49bb506fec6caff6cd3af19751598d87c2a9999
- Cargo: f82cf2a0203950ffd01aa83c67d2e2faa2e97f63
- Clippy: c62b64916f4fa9b918bf4f3c8cb141eff7152040
- rustfmt: f63d4c44ba9dec69a4e97fd718f4152eae1f515a

The source verifier checks exact revisions, tracked bytes, clean checkouts, Rust’s Cargo gitlink and expected repository identity. It explicitly removes inherited Git-object/index variables and disables replacement objects. These are good release-integrity controls, not proof of semantic equivalence or reproducible binaries. The separate component repositories were also publicly accessible during review. [Source verification][verify]

## Key Features and Correctness Boundaries

### Reuse instead of recompilation

The documented core combines public-interface hashes, saved link objects, native-build-to-check reuse and selected check-to-build checkpoints. A private dependency edit can retain downstream compilation while relinking the executable with changed code. Missing or mismatched inputs should force rebuilding. The docs describe restrictions for procedural macros, inline assembly, native libraries and unsupported configurations; these are documented intended behavior, not exhaustively verified compiler guarantees. [Optimizations][optimizations]

That distinction matters: an unchanged interface is not sufficient when a macro, build script or native helper observes an untracked input. The project explicitly calls reuse potentially unsound. Disabling automatic defaults is a useful comparison control, but does not transform this fork into the upstream correctness oracle. A clean authoritative-toolchain rebuild remains necessary.

### Real implementation, but narrower inspection than the whole compiler

At the pinned Cargo revision, the linker module incorporates default flags into unit fingerprints, respects explicit linker configuration and opaque response files, and avoids automatic Wild selection when its executable is absent. The ThinLTO cache module checks platform, compiler capability, wrapper/backend settings and compile mode before enabling caching. When shared provenance cannot be recorded it keeps optional state private. These inspected modules support the claimed engineering direction; they do not independently establish the correctness of public-API hashing or relink invalidation. [Linker][linker] [ThinLTO cache][thinlto]

### Worktree sharing and recovery

The documented design keeps each worktree’s incremental state and final outputs separate while reusing eligible dependencies in a shared build directory. It uses locking and compiler/input identity checks. Worktree seeding uses copy-on-write where available; its benefit depends on filesystem and workload. Share only across a common trust domain, never across hostile projects/users. Authentication of a package’s origin does not make arbitrary procedural-macro or build-script behavior safe to cache. [Optimizations][optimizations]

Selected Cargo regression sources cover separation of unsupported compiler/wrapper modes and release/test targets, GC busy-target behavior, invalid registries, inaccessible paths and preserving reused dependencies. These are meaningful tests present in source, not tests run by this review. [Shared-stage tests][stage-tests] [GC tests][gc-tests]

## Performance Evidence: Stronger Than a Headline, Still Vendor Evidence

The current README reports 1,415.37 seconds for summed stock-Rust sessions versus 685.88 seconds with Ohm: independently recalculating those displayed totals gives **2.0636×** and **51.54% time saved**. This verifies arithmetic only. It is an aggregate of selected recorded workflows, not a universal Rust compilation speedup or application-runtime improvement. [README][readme] [Sessions][sessions]

Useful methodological detail includes pinned workload revisions, paired toolchains on each host, alternate execution order, warmup separation, offline timed commands, contention rejection, source edits and structured results. The results index describes 216 individual-command samples and five developer workflows per project with four repetitions per toolchain. The session JSON records two repetitions for its Ruff/uv/Codex runs; ty is a separate study. Matching command success/test counts cannot establish all compiler semantics. [Benchmark guide][benchmarks] [Results index][results]

**Important comparability caveats:**

- Session replays enable procedural-macro trust. Developer workflows and the ty session additionally enable native-tool trust. Individual-command studies use default trust settings. The headline is therefore not simply the default-install experience.
- The APFS disk table compares **Ohm 1.99.0-11 with Rust 1.99.0**, not the current 1.100.0-5 release; do not attach its savings to the new release or assume Linux reproduces them.
- Some large gains are specifically API-preserving dependency edits, no-op formatting or warm reuse. Fresh builds and arbitrary edits are different workloads.
- Published structured records include local log references; their existence is not independent access to every raw run. No benchmark or full log replay was performed here.
- The optimization document still introduces 1.100.0-1 and contains older example measurements. Use the versioned manifest and current results for release-specific claims.

The repository preserves older slower-workflow confirmations rather than presenting every change as a universal win. This is a positive reporting signal, not an independent replication. [Results index][results]

## Security, Permissions and Execution

**This is a native toolchain, not a sandbox.** Running Cargo, build scripts, procedural macros, linker helpers or produced test binaries grants ordinary process authority to code being built. A faster worktree is not an isolation boundary. Keep untrusted repositories away from credentials and shared writable caches; enforce isolation outside Ohm. There is no web server/auth/CORS boundary in the inspected coordinator’s normal use.

The installer downloads a checksum-pinned release, validates archive paths and member types, rejects symlinks/hardlinks and broad installation prefixes, stages onto the destination filesystem, verifies binaries, and refuses replacement of immutable exact-version rustup registrations. It also executes the archive’s inner installation script and installed binaries for version checks: **installation is code execution**, even after a valid hash. [Installer][installer]

Checksums bind archives to the installer’s embedded expectation. They do not independently authenticate a compromised installer/release publisher. The supplied provenance JSON is a source/build record, not evidence here of a separately verified signed attestation or reproducible-build comparison. GitHub listed the latest release as immutable, but no release binary, signature or attestation was downloaded or verified. [Release][release] [Provenance generation][provenance]

Supply-chain positives include exact component commits, pinned Wild version/hash, SHA-pinned workflow actions, disabled checkout credential persistence and restricted job permissions. Coordinator formatting uses pinned Prettier plus a lockfile; npm configuration disables install scripts and sets a minimum release age. Building from source still trusts upstream bootstrap/compiler/dependency tooling, CI infrastructure and all component contents; the coordinator’s small npm manifest is not the total toolchain dependency graph. [CI][ci] [Release workflow][release-workflow] [Manifest][manifest]

## Privacy and Egress

No application-level telemetry or model upload was identified in the inspected coordinator/selected Cargo paths; this was not a whole-toolchain network audit. Installation fetches from the release host, and build/release/benchmark preparation can access GitHub, registries and upstream toolchain infrastructure. Ordinary Cargo dependencies and user code may perform network I/O independently. Cargo’s offline mode restricts Cargo fetching, not arbitrary subprocess networking.

Artifacts, diagnostics, incremental state and saved objects can retain source-derived information and filesystem paths. Shared caches increase the retention and disclosure surface. Limit permissions and trust scope; do not publish benchmark logs or caches without inspection. No live traffic capture or egress enforcement test was performed.

## Persistence and Recovery

Installation retains versioned toolchains and a moving ohm alias. The installer backs up an existing alias while changing registration, tries to restore it on failure, and preserves a recovery backup if restoration fails. It cleans staging state through traps; abrupt termination or storage failure is not proven crash-atomic. Activation moves entries into the destination rather than a single transactional directory swap. No reboot/failure-injection recovery test was run. [Installer][installer]

Build state is durable local filesystem state rather than a required long-running compiler server. The inspected private ThinLTO cache prunes under a lock with 2 GiB, 100,000-entry and 30-day limits; shared objects defer collection to Cargo GC. These are **specific cache limits**, not a global disk-use ceiling. Compiler-cache eviction is intended to become a cache miss; it is not a substitute for backups of source work. [ThinLTO cache][thinlto]

For reproducible comparisons, pin an exact Ohm revision, keep target directories distinct and keep upstream build output separate. If results disagree, reproduce with the repository’s normal Rust toolchain and fresh artifacts; do not bless Ohm output because its own tests pass.

## Maturity and Verification

Public metadata on review day reported 30 stars, 1 fork, creation on 2026-08-01 and last push on 2026-11-21. The six open items returned by the issues endpoint included four pull requests and two issues; that is not six confirmed defects. Recent releases 1.100.0-3, -4 and -5 show active iteration, not stabilization. [Metadata][metadata] [Open items][issues]

The exact reviewed coordinator SHA had a successful public CI run. Its workflow exercises benchmark/result tooling, manifest validation/history, source verification, installer/packaging tests and shell linting. Release workflows add assembled-toolchain smoke testing and a separate Linux qualification path. The relink smoke test explicitly changes embedded assembly input bytes, checks executable output and expects missing-input failure—a better signal than merely testing that compilation exits zero. [Observed CI run][ci-run] [CI][ci] [Relink smoke source][smoke]

**Actually verified here:** public access/canonical identity; exact checked-out SHA; source pins and source-level architecture; installer/provenance/CI logic; selected Cargo modules/test definitions; displayed headline arithmetic; public CI conclusion; artifact provenance, markup and task-only diff.

**Not verified:** compiler soundness, all dependency invalidation paths, cross-platform behavior, test suite execution, benchmark speed/memory/disk gains, binaries matching source, release signatures, complete license inventory or actual recovery behavior. No tools were installed and no source-supplied scripts were executed.

## Comparison

| Option | Best fit | Tradeoff against Ohm |
|---|---|---|
| Upstream Rust/Cargo | Correctness, CI and production/release builds | Mandatory authority; lacks this combined experimental reuse bundle |
| sccache with upstream Rust | Reusing supported compilation outputs locally or remotely | Narrower caching approach; not equivalent to Ohm’s API-aware downstream reuse; Rust caching limitations still matter |
| mold/LLD with upstream Rust | Workloads demonstrably bottlenecked on linking | Smaller change surface; does not remove frontend or dependency rebuild work |
| Blaze | Persistent, fine-grained experimental Rust compilation | Larger architectural departure and daemon/state model; see the [existing review](indexable-blaze.md) |
| Relax | Live/JIT iteration and hot patching | Different execution model and semantic-compatibility questions; see the [existing review](makepad-relax.md) |

These are architectural comparisons, not new head-to-head measurements. Start with upstream profiling and a narrower bottleneck fix; study Ohm when repeated trusted-worktree builds justify the extra correctness boundary.

## Self-Hosting Notes

There is no service to deploy. This is a local, explicitly selected toolchain with substantial persistent build state. Its supported host set and exact upstream Rust pairing matter. Keep the default project toolchain, CI and shipping pipeline unchanged; do not globally instruct agents to replace them. The README’s example trust opt-ins are deliberately unsound tradeoffs, not recommended defaults for correctness-sensitive work.

## License and Attribution

The README and both root license texts specify **MIT OR Apache-2.0**, despite GitHub’s single Apache-2.0 metadata classification. Reuse must preserve the selected license’s notices and conditions; bundled LLVM, Wild and other components require their own notice review. This review contains analysis, not redistributed compiler code. [MIT][mit] [Apache-2.0][apache]

**Attribution:** astral-experiments/ohm and its component contributors; MIT OR Apache-2.0 at root.

[readme]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/README.md
[security]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/SECURITY.md
[architecture]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/docs/architecture.md
[optimizations]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/docs/optimizations.md
[manifest]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/toolchains/1.100.0/5.json
[installer]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/scripts/install.sh
[verify]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/scripts/verify-release-sources.sh
[provenance]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/scripts/stage-release-dist.sh
[benchmarks]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/BENCHMARKS.md
[results]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/scripts/benchmark_results/README.md
[sessions]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/scripts/benchmark_results/sessions.json
[ci]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/.github/workflows/ci.yml
[release-workflow]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/.github/workflows/release.yml
[smoke]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/scripts/smoke-test-relink.sh
[release]: https://github.com/astral-experiments/ohm/releases/tag/ohm-1.100.0-5
[ci-run]: https://github.com/astral-experiments/ohm/actions/runs/44932703999
[metadata]: https://api.github.com/repos/astral-experiments/ohm
[issues]: https://github.com/astral-experiments/ohm/issues
[linker]: https://github.com/astral-experiments/ohm-cargo/blob/f82cf2a0203950ffd01aa83c67d2e2faa2e97f63/src/compiler/ohm_linker.rs
[thinlto]: https://github.com/astral-experiments/ohm-cargo/blob/f82cf2a0203950ffd01aa83c67d2e2faa2e97f63/src/compiler/ohm_thinlto_cache.rs
[stage-tests]: https://github.com/astral-experiments/ohm-cargo/blob/f82cf2a0203950ffd01aa83c67d2e2faa2e97f63/tests/testsuite/ohm_shared_stages.rs
[gc-tests]: https://github.com/astral-experiments/ohm-cargo/blob/f82cf2a0203950ffd01aa83c67d2e2faa2e97f63/tests/testsuite/ohm_build_gc.rs
[mit]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/LICENSE-MIT
[apache]: https://github.com/astral-experiments/ohm/blob/9d19afd7f3601d325408293a95601b27a46243bb/LICENSE-APACHE
