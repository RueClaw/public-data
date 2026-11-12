# Blaze (indexable-inc/blaze)

**Repo:** https://github.com/indexable-inc/blaze
**Owner:** Indexable, Inc. (ix) and contributors
**License:** MIT OR Apache-2.0; component/asset notices apply separately.
**Reviewed:** 2026-11-12 (UTC)
**Revision:** 043896a73e63240444c70dbfbcc5f730d459bdf9; main snapshot, committed 2026-11-12T18:22:02Z.
**Scope:** Selected compiler, CLI/daemon/API, codegen, sandbox, registry/update, VFS/store/GC, benchmarks and CI paths; not an exhaustive compiler audit.
**Verification:** Static only. No installation, compilation, tests, benchmarks, toolchain/model/dataset downloads, daemon or live service probes.
**Stack:** Rust; rust-analyzer-derived frontend; custom incremental queries and content store; copy-and-patch stencils, LLVM, Wasmtime; Python/Rust harnesses and Nix tooling.
**What it is:** An experimental Rust compiler and persistent build daemon for faster edit/build loops, including structured interfaces for coding agents.

## Verdict

⚠️ **Interesting — pilot beside Cargo, not instead of its correctness gate.** Fine-grained content-addressed compilation, tracked build-time execution and explicit recovery contracts are substantive engineering. But headline speedups measure an older implementation, documentation trails rapidly changing code, and compiler equivalence is not established for this revision. Keep the project's pinned rustc/Cargo CI authoritative.

## What It Is

Previously named **ra-jit** (renamed 2026-10-24), this is ix's Rust compiler/build project—not an AI inference engine, web framework, or the unrelated Blaze/Bazel family. It implements resolution, frontend work, code generation and linking, rather than simply wrapping Cargo with a faster linker. Unsupported builds fail instead of silently falling back to rustc. Cargo-like syntax is not a guarantee of full Cargo or Rust compatibility. [README](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/README.md), [command reference](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/docs/cargo.md).

The tree also includes client integrations, a site, a separate native harness workspace and extensive plans. These do not establish production availability of every hosted CI, shared-cache or live-edit design. No prior matching public review was found; the owner-qualified slug disambiguates the name.

## Stack and Architecture

| Layer | Implementation |
|---|---|
| Entry/orchestration | blaze-engine launcher; blaze-cargo CLI and daemon |
| Frontend | rust-analyzer-derived parsing/HIR; Blaze MIR and analyses |
| Incrementality | blaze-query dependency fingerprints, constructive traces, early cutoff and single-flight work |
| Source state | blaze-vfs Merkle trees, named heads, rebased transactions and journals |
| Native code | opt-level 0/1: copy-and-patch stencils; 2/s/z: LLVM O2; 3: LLVM O3 |
| Proc macros | wasm32-wasip1 modules in Wasmtime with host bridge/WASI imports |
| Storage | BLAKE3-keyed packs, mmap indexes, content hashes and block CRCs |
| API | Versioned CBOR frames over local socket; optional bearer-authenticated HTTP/JSON responses |

Results are shared by equal inputs, not just whole-crate or checkout identity. Reuse checks recorded dependency fingerprints; a changed result can stop propagating when its fingerprint stays equal. VFS views are immutable and edits rebase file by file or report conflicts. The useful pattern is precise dependency accounting—not hashing alone: an incomplete cache key can consistently return the wrong answer. [queries](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-query/src/lib.rs), [VFS](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-vfs/src/lib.rs), [store](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-cas/src/lib.rs).

**Read implementation ahead of overview prose.** README credits Cranelift, but current native policy selects stencils/LLVM; Cranelift still participates in Wasm/IR work. The usage guide says v2 has no live edits, yet current code selects Live mode for eligible dev executables and implements shared-code-memory launch/patch handling. That is substantive code, not an independently verified platform or latency guarantee. [backend policy](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-codegen/src/plan.rs), [build wiring](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-cargo/src/serve/unit/codegen.rs), [dev runtime](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-cargo/src/serve/unit/run/inproc.rs).

## Key Features

- **Warm fine-grained rebuilds:** retain frontend/code state and invalidate by observed inputs; cold startup, memory and semantic correctness remain separate questions.
- **Structured agent operations:** commits/edits, builds, diagnostics, launch and digest-pinned fetching. This is a powerful control plane, not a read-only inspection service. [API](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-api/src/lib.rs).
- **Tracked build-time code:** sandboxed build scripts, cached observed inputs, constant-output elision with a verification switch, and Wasm proc macros. Opt-outs deliberately restore broader host authority. [scripts](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-cargo/src/serve/unit/script.rs), [macros](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-macro-eval/src/wasm.rs).
- **Explainable persistence:** build explanations, profile history, explicit layout markers and recovery rules are valuable; they are not backup or secure deletion.

## Claims, Benchmarks and Correctness

### Historical speedups do not measure this implementation

The README reports approximately **10× / 24× / 11×** faster edits on macOS arm64 / Linux aarch64 / Linux x86-64. It and the benchmark document explicitly identify these as **v1** results; no published v2 run supports transferring them to this SHA. The old ~20 ms live-edit headline needs the same qualification. [methodology and raw-result links](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/docs/benchmarks.md).

Positive evidence includes pinned project revisions, cold/no-op/body/signature edit cases, warm incremental Cargo baselines, repeated medians, raw JSON, machine/load details, fallback labels and memory/disk accounting. Limits include small samples (often three or five edits), different machines across platforms, busy Mac measurements and no confidence interval establishing a universal multiplier. Download time is excluded. Headline Cargo uses the default linker rather than the fastest mold/wild configuration; separate setup experiments should not be conflated with that baseline.

Historical memory costs are substantial: Linux x86-64 reports roughly **1.7 GB versus 528 MB** for a ripgrep edit and **28.9 GB versus 8.5 GB** for Bevy. Historical optimized-runtime geometric means are **1.10–1.18× slower** than Cargo release. These are old measurements, not current resource guarantees.

**The edit harness is not a compiler-equivalence proof.** In the inspected harness, expected output comes from Blaze's cold program, and later edited outputs are compared against that. Cargo is primarily the speed baseline. Some fixtures only build or run help/version commands. Self-consistency can preserve an existing miscompile. [harness/bench.py](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/harness/bench.py).

### Borrow-checking scores need dates and exclusions

The detailed page reports historical **1587/1590 Polonius** and **1585/1588 NLL** matches, with **460 units out of scope**. It says the rustc-comparison harness was deleted on 2026-10-30 and a successor application check was queued; later application false positives are also recorded. The short usage guide still says “about two thirds.” Neither is a fresh pass rate for this revision. Acceptance of known valid cases cannot establish soundness. Preserve normal Cargo checks and representative full tests on the project's actual toolchain. [borrow checker](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/docs/borrowck.md), [usage](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/docs/usage.md).

## Security, Execution and Privacy

**Owner authority, not multi-tenant isolation.** Unix sockets check ownership/peer identity and private permissions. The active API uses schema-versioned CBOR with size and queued-output bounds. Optional HTTP requires a nonempty BLAZE_API_TOKEN; its comparison is written to avoid secret-content-dependent timing. This is HTTP, not intrinsic TLS. Prefer local sockets or a separately secured transport, and do not expose a shared public compiler. One bearer credential reaches broad daemon operations rather than per-workspace RBAC. [socket](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-cargo/src/socket.rs), [server](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-api/src/server.rs), [startup](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-cargo/src/serve.rs).

**Sandboxed does not mean secret-free.** Build scripts receive the invocation's environment, with tracing/lending for cache keys; enumeration or child execution can expose all of it. The documented default filesystem view is broadly read-only, not necessarily project-only. Network denial and OUT_DIR write limits matter, but readable secrets can still enter outputs/logs. macOS also allows a per-user compiler cache. Workspace opt-outs and BLAZE_SANDBOX=off are execution grants. Plain tests and launched programs run as the user; test sandboxing is an opt-in experiment. [sandbox contract](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/docs/cargo.md#build-scripts-and-proc-macros-run-in-a-sandbox), [implementation](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-cargo/src/sandbox/v2.rs).

**Credentials/configuration are executable trust.** Registry support reads Cargo-compatible tokens and can spawn configured credential-provider/token-from-stdout commands. They are local executables, not isolated provider APIs. Registry credential files have private-mode handling, not an encrypted-keystore guarantee. Review repository/config provenance before use. [registry auth](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-registry/src/auth.rs), [provider processes](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-registry/src/auth/process.rs).

**Network is broader than building.** Dependencies, toolchains, native inputs and releases are fetched. Update warning mode checks release metadata by default; automatic installation and offline modes are distinct. Digest-pinned fetch-url can retrieve bytes/Git trees and optionally write an output directory. A digest validates content, not permission to contact a host. Treat API callers as trusted owners and apply external egress controls where needed. No LLM provider, model or paid inference API is required by the compiler itself. Costs are CPU/RAM/disk plus any separately chosen hosted infrastructure; no hosted pricing/service guarantee was established. [updates](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-engine/src/update.rs), [fetch handler](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-cargo/src/serve/fetch_url.rs).

**Remote-store machinery is not a secure shared service.** SECURITY.md says no shared store is active. The source nonetheless contains remote client/server machinery that explicitly trusts its channel, lacks its own TLS/auth, refuses non-loopback TCP listeners, and verifies content without proving key-to-value mappings. No remote-store wiring was found in sampled normal daemon startup paths. Do not infer active cloud caching or tenant security from this module/roadmap. [remote tier](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-cas/src/remote.rs), [security policy](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/.github/SECURITY.md).

The policy calls Blaze a prototype without a security review. Its Windows warning also trails code: socket/windows.rs contains SID/DACL and peer-process checks where the policy says they are absent. This review does not validate Windows protection. Source inspection found meaningful controls, not proof against hostile code or sandbox escapes.

## Persistence, Retention, Export and Recovery

Build directories, fetched source, compiled objects, VFS journals, images, build-script outputs, profiles and logs may contain proprietary material. State is local by default; no at-rest encryption or comprehensive secret-redaction guarantee was established. Keep stores owner-only: checksums detect damage, not a malicious writer substituting build code.

The detailed reference puts builds outside the checkout under the cache root, keyed by workspace path; the short guide's target/ wording is stale. Large output placement requires filesystem cloning according to the reference, failing on unsupported/cross-volume layouts instead of silently copying. Check filesystem fit. [storage layout](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/docs/cargo.md#where-a-build-writes).

Recovery includes VFS torn-tail handling, block/content checks, explicit format mismatch rules, and daemon-image cold-start/refusal behavior. A graceful stop makes state durable. These were inspected, not crash-tested; retain source/lockfiles separately rather than treating cache state as backup. [VFS](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-vfs/src/lib.rs), [store](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-cas/src/lib.rs).

GC protects leased/live directories, uses marked trash and rejects dangerous cleanup targets. Defaults include a 14-day workspace TTL, a 16 GiB workspace cap and grace periods. **Daemon state/store/image/journal are excluded from GC, and store-value eviction is not implemented.** Workspace cleaning therefore does not erase all retained source/build history or guarantee a total disk bound. serve.log rotates to two files totaling 16 MiB, not a global retention limit. [GC contract](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/docs/gc.md), [collector](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-gc/src/lib.rs), [fetch retention](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/crates/blaze-cargo/src/serve/fetch_url.rs).

Outputs are native build artifacts and local diagnostic/profile formats, not an application-data export service. No complete portable backup/restore or secure-purge procedure was validated. Stop the daemon and inventory all retained roots before migration/decommissioning.

## Installation, Updates, License and Maturity

- **Toolchain substitution:** Blaze builds with its own pinned Rust rather than the project's rustup pin. Check MSRV/nightly assumptions independently.
- **Installer trust:** the advertised curl-to-shell executes a moving installer. Its code enforces HTTPS and release checksums, but sums from the same release origin are not independent publisher authentication. Inspect/pin installers and artifacts. Updates may replace the default binary; explicit pins and update policy matter. [installer](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/site/install.sh), [pinning](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/docs/cargo.md#pinning-a-release-of-blaze).
- **Dependencies:** Cargo/Blaze/Nix locks and pinned native LLVM inputs help; heavily patched/vendor components, native libraries and bootstrap tooling enlarge the trust surface. No vulnerability scan or reproducible binary comparison was performed.
- **License:** actual MIT/Apache texts exist. NOTICE attributes rust-analyzer, rowan-derived syntax-tree, Hegel and separate harness/font components. Preserve notices and check each bundled component before redistribution. No code extraction accompanies this review. [NOTICE](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/licenses/NOTICE), [MIT](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/LICENSE-MIT), [Apache](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/LICENSE-APACHE).
- **CI:** substantial unit/property/fuzz/scenario infrastructure exists. The merge gate is narrower than the post-merge train. Current workflow comments identify ARM64 as primary, x86-64 cross-compilation rather than execution there, and Mac coverage on main. Actions such as checkout use version tags rather than immutable SHAs. Promotion logic is a policy, not proof this SHA passed. [merge gate](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/.github/workflows/blaze.yaml), [promotion](https://github.com/indexable-inc/blaze/blob/043896a73e63240444c70dbfbcc5f730d459bdf9/.github/workflows/promote.yaml).
- **Public metadata snapshot:** created 2026-10-19; 2,230 stars, 84 forks, 437 open issues/PRs combined, and last push 2026-11-12. The first returned release was **v0.20261105.4**, a bootstrap canary/prerelease. This is very young, fast-moving software. Sampled recent workflows were unrelated fork-PR runs awaiting action, not evidence of this SHA's result. [metadata](https://api.github.com/repos/indexable-inc/blaze), [releases](https://github.com/indexable-inc/blaze/releases).

## Comparison

| Option | Better fit | Tradeoff |
|---|---|---|
| Cargo/rustc with tuned profiles and mold/lld/wild where supported | Lower-risk improvements retaining upstream semantics | Less radical fine-grained reuse |
| sccache | Reusing unchanged compilations across builds/CI | Not per-function edit invalidation |
| rustc_codegen_cranelift | Faster dev code generation behind rustc's frontend | Nightly/platform and optimization constraints |
| Dioxus subsecond | State-preserving reload in integrated applications | Requires integration/platform qualification |
| Blaze | Warm-daemon build research and carefully measured local pilots | Compiler divergence, memory, documentation drift and current evidence gaps |

## Self-Hosting and Practical Verdict

Start with an authorized non-sensitive project and a pinned release/SHA, not a global Cargo replacement. Compare cold/warm edits, runtime behavior, full tests, memory, retained disk and restart recovery on the actual platform. Keep normal Cargo CI. Untrusted repositories belong in an external disposable secret-free sandbox even when Blaze's internal sandbox is enabled. Reconsider broad deployment after current-version benchmarks, representative correctness evidence and platform/security acceptance.

## Verification Limits

All conclusions derive from public source at the recorded SHA and dated public metadata. No repository code ran; **no tests were run or claimed passing**. Binary provenance, crash recovery, sandbox resistance, benchmark numbers, live patching and hosted services were not independently reproduced. Documentation conflicts are reported, not resolved by assumption.

---

**Attribution:** indexable-inc/blaze, Indexable, Inc. and contributors; MIT OR Apache-2.0 with third-party notices.
