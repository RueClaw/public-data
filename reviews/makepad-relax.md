# Relax (makepad/relax)

**Repo:** https://github.com/makepad/relax

**License:** MIT at root; crate manifests declare MIT OR Apache-2.0; bundled component notices also apply.

**Reviewed:** 2026-11-12 (UTC)

**Revision:** 82b568b00473e749d5217a309f2e72bdb364cc39 — repository-wide static survey, focused on compiler/runtime, runner, caches, macro host and transport. Commit timestamp: 2026-11-12 18:48:23 UTC.

**Verification:** Static source review only. No compilation, tests, benchmarks, application execution, dependency installation or live service/device probes.

**Stack:** Rust, custom Rust frontend/type system/IR/optimizers, x86-64 and AArch64 backends, native OS services.

**What it is:** An experimental Rust live compiler and JIT runtime for faster development iteration—not a relaxation app, GUI toolkit, rustc wrapper or release compiler.

## Verdict

⚠️ **Interesting: substantial live Rust tooling, suitable for a bounded development pilot.** Function-level JIT compilation, retained-state patching and built-in observability solve a real iteration problem. But this is a new public compiler with semantic compatibility bugs, default background borrow checking, significant memory/cache costs and no public GitHub CI. Keep rustc as the correctness and shipping gate; never treat the bare runner as a sandbox for arbitrary agent-generated repositories.

## What It Is

Relax runs a Cargo package from source, compiling functions when demanded and promoting hot functions to optimized native code while the application runs. It implements parsing, typing, borrow checking, code generation and loading itself. Rust/cargo are still needed to build Relax; “no rustc/LLVM/linker in the loop” describes ordinary JIT execution after bootstrap, not installation or every optional native dependency path. [Overview][readme]

It comes from Makepad, but this repository's binary is the **bare runner**. Its entry point calls relax_runner::main with BARE; BARE registers no Makepad window host or provided crates. The README explicitly places makepad run, the caption-ring UI, retained-window restart and devhub integration in the Makepad project. Those are not turnkey UI features delivered by installing this CLI. [Runner][runner] [Entry][entry]

The best audience is toolchain researchers and developers of trusted, repeatedly exercised Rust applications who can compare outputs against rustc. It is not a guarantee that arbitrary crates.io graphs behave identically.

## Stack

| Layer | Implementation |
|---|---|
| Source/graph | relax-lex/base/session/front: tokens, manifests, registry/git handling, hashes and macro expansion |
| Semantics | relax-types: inference, traits, layouts, constant evaluation and borrow checking |
| Optimization | relax-codegen over Relax IR (RIR), interpreter and O1/O3 optimization |
| Backend | relax-backend: register allocation, ABI planning, x86-64/AArch64 emission |
| Runtime | relax-compiler: lazy slots, tiering, reload, std, macro world, tests and inspect |
| CLI | relax-runner, package version 0.1.0, publish=false |
| Storage/network | Rebuildable local cache stores; registry/git fetching through bundled HTTP and OS networking |

The workspace and runner/compiler manifests use local support crates, consistent with the claim that building the tool needs no crates.io dependencies. That is **not zero dependencies or zero supply-chain surface**: there are numerous bundled crates, OS APIs, ported components and the target program's dependencies. [Workspace][workspace] [Compiler manifest][manifest]

## Key Features

### Demand-driven compilation and live editing

The JIT maintains per-function identities and code slots, choosing interpreter/baseline execution before background optimized code. Reload parsing/classification and installation are organized as a patch transaction; old code remains valid for existing frames. Body edits are the reliable advertised case. Structural changes can require restart. The implementation attempts guarded layout/macro/visibility changes beyond the README's conservative description, so neither “every layout edit works” nor “no layout edit can ever work” is accurate. [JIT][jit] [Reload][reload]

Default execution runs borrow checking beside the program; --check-first waits instead. A live-reload regression test explicitly expects a lazy-mode borrow error to be reported **after installation**, rather than as “live edit refused.” Do not equate successful startup or type checking with rustc-style completed borrow verification. [Reload tests][reloadtests]

### Runtime diagnostics, not only hot reload

The inspect tree implements profiling/call trees, stacks and locals, breakpoints, panic handling, heap views, code versions and a flight recorder. README claims include bounded recorder memory, automatic saves on panic/fault/long hitch and selective warm test reruns. These are implemented surfaces, not independently reproduced guarantees. Heap tracking's documented qualified targets are Linux x86-64 and macOS arm64. Panic retry/restart is debugging control, **not rollback of network, filesystem or application effects**. [Inspect][inspect] [Overview][readme]

### Content-derived caches with deliberate crash handling

Cache keys include compiler/codegen identity, function body, positions, crate interfaces and dependencies, including inlined code. This is much more precise than timestamp-only reuse. The store uses shared/exclusive locks, appended payloads and alternating index slots; recovery validates pending tails/checksums and can fall back to the previous commit. Generational files avoid replacing mappings held by other processes. [Cache][cache] [Store][store]

The store explicitly promises **rebuildable-cache crash safety, not durable application state**. README reports 120–190 MB of cache even for hello. cache.rs describes a default cap at least 4 GB and twice the run's use; native-build storage is outside that cap. Published JIT code is append-only during the process lifetime, so long editing sessions need memory monitoring and eventual restart. Checksums detect corruption, not malicious local writers; do not share writable executable caches across trust boundaries.

## Architecture

The layered pipeline combines lexer/base/session, frontend, semantics, IR optimization/backend and runtime/runner, with local serialization, profiling, remote-control and native-macro support. The executable is intentionally thin. A separate proc-macro “world” has its own Program, type context and JIT unit; source-matched native macros can bypass JIT compilation, otherwise macro code runs in-process. [Macro host][pmhost]

The standout combination is stable function identity, indirection for code publication, hash-bound cache reuse and observable compiler work. It is also a large trusted computing base: a Rust implementation must agree on name resolution, layout, drops/unwinding, ABI, unsafe operations and optimizer assumptions—not merely accept familiar syntax.

### Concrete semantic risk at this revision

Open [PR #95](https://github.com/makepad/relax/pull/95), observed on the review date, reports wrong constructor dispatch and a heap abort with large enums. Static inspection corroborates the narrow representation: FnKey::Glue(u8, TyId), GLUE_CTOR = 16, and constructor keys formed as GLUE_CTOR + vi as u8 in jit.rs/lower.rs. That cannot uniquely encode every constructor of an enum with hundreds of variants. The reported crash was not independently reproduced, and the proposed fix was not in this pinned revision. [JIT][jit] [Lowering][lower]

[KNOWN_GAPS.md][gaps] is useful but not a fresh test report: it lists macro collisions, an unreproduced serde trait issue, an unreproduced slow check and lint discrepancies. The current macro registry already contains caller-dependency lookup/collision handling beyond the document's “first bare name wins” explanation. Treat listed repros as things to rerun on a pinned build, not independently verified current failures. [Macro registry][macroreg]

## Performance Evidence

The README's developer measurements dated 2026-11-12 report 11 seconds cold and 1.15 seconds warm to a large game's first frame on an M4, and 3.7/0.41 seconds for a small app. These are startup/iteration observations, **not** proof of faster steady-state execution or representative third-party benchmarks. Makepad agent-loop results include 3.6-second median patch latency but 86-second p90; the tail matters.

For 21 workloads, reported Relax/rustc elapsed-time geomeans are 1.12× on x64 and 1.24× on arm64 against stock release; against native-CPU release they are 1.22×/1.25×. Lower is better: Relax is slower overall. The two largest stock-x64 wins disappear against the like-for-like native baseline; 3D model building is roughly twice as slow. Methods name median-of-three rounds, OS/architecture and rustc/LLVM versions, which is better than a headline alone, but no independent replication was performed here. Kernel figures are explicitly provisional because of a warm-cache tier-up bug. Cold relax check is acknowledged to be slower and more memory-intensive than cargo check. [Measurements][readme]

## Security and Privacy Boundaries

- **Bare runner means trusted-code execution.** BARE chooses pmhost::Policy::Open: proc macros retain unsafe and std filesystem/network/process/environment capabilities. Even checking/expanding a crate can execute compile-time code. The stricter Makepad policy is not the bare runner's default. [Runner][runner] [Macro host][pmhost]
- **Sandbox code is not blanket containment.** sandbox.rs implements module arenas, rewritten memory accesses, thunk call targets, shadow stacks and fuel; Windows arena allocation is explicitly unsupported. Its presence does not confine ordinary relax run or establish audited isolation. --no-asm is a narrower refusal, not a complete OS sandbox. [Sandbox][sandbox] [CLI help][help]
- **Native escape paths are explicit.** --allow-c invokes cargo/system C builds and links native dependencies, adding build-script/compiler/linker authority. Target programs run with the runner's machine authority. Use disposable OS isolation without credentials for untrusted projects; none was executed here. [CLI help][help]
- **Local inspection is powerful.** Unix transport uses a user-owned 0700 directory, 0600 socket and peer-UID checks. This protects against other users, not another process/agent running as the same user; evaluation/debugging can expose program data. Shared remote infrastructure also includes loopback-token and paired LAN/TLS carriers: “nothing on the network” must be scoped to ordinary local inspection, not every library capability. No listener was enabled. [Unix carrier][unix] [Remote server][remote]
- **Offline mode scopes compiler acquisition.** Missing registry packages may be downloaded, with archive SHA-256 checked against the index. HTTPS redirects are bounded and must remain HTTPS. MAKEPAD_RUN_OFFLINE=1/Cargo offline settings suppress this acquisition, not arbitrary networking by the program/open proc macros. Public git fetch stores repository data separately. [Registry][registry] [Network][network] [Fetch][fetch]
- **Diagnostics can be sensitive.** Locals, evaluation, source names, traces and saved recorder files may contain application data. Review diagnostics before sharing. No credentials, accounts or model service are inherently required by the compiler; no blanket no-egress claim can cover all target programs.

## Platforms, Installation and Updates

The upstream-qualified fresh-clone targets are **Linux x86-64 and macOS arm64**. Native emission supports x86-64/AArch64. Windows-specific code exists but the README calls Windows untested; module arenas are not implemented there. Android/web/wasm modules show implementation work, not a verified standalone support matrix.

The documented source build is:

    cargo build --release --manifest-path relax/Cargo.toml -p relax-runner --bin relax

It needs a stable Rust toolchain. Run from the target Cargo package directory with the **package name**, not a filesystem path. Keep the Relax checkout: the runner reads std sources from the tree used to build it. This is not a freely relocatable single-binary installation. No installation was performed. [Setup][readme] [Contributing][contributing]

For updates, deliberately select a revision and rebuild; retain the matching std tree and isolate cache directories for A/B comparisons. CONTRIBUTING documents MAKEPAD_RUN_STD and MAKEPAD_RUN_CACHE_DIR for this. Do not replace std underneath an old binary or infer safe upgrades from a changed executable alone. relax clean removes rebuildable compilation artifacts; application backups/state migration remain application responsibilities. This is developer tooling, not a self-hosted web service.

## Tests, License and Maturity

There are substantial unit/integration fixtures for reload, borrow checking, caching, macros, ABI, std behavior and negative cases. Static enumeration found **208 Cargo.toml files under compiler/tests**, including nested fixture crates; that is not 208 passing suites or independent confirmation of the README's “96 end-to-end packages.” The compiler manifest disables Cargo autotests for intentionally failing fixture programs, so ordinary Cargo tests alone do not establish all fixture parity. CONTRIBUTING recommends release workspace tests plus differential runs against rustc, and explicitly says **there is no GitHub CI**. No .github workflow files were found. [Manifest][manifest] [Tests][tests] [Contributing][contributing]

Public GitHub metadata retrieved 2026-11-12 showed creation on 2026-11-11, last push 2026-11-12 18:48:47 UTC, 220 stars, 14 forks and 16 open issues/PRs combined; the releases API returned no releases. Public youth does not establish the age of all Makepad-derived code, and popularity is not correctness evidence. [Metadata](https://api.github.com/repos/makepad/relax) [Releases](https://api.github.com/repos/makepad/relax/releases)

The root license is MIT, copyright 2026 makepad. Several manifests declare MIT OR Apache-2.0; preserve applicable notices rather than assuming the root string covers everything. std/CREDITS records smallvec, arrayvec, Rust/portable-simd, libm and dlmalloc origins and MIT/Apache or per-file notices. Branding/favicon provenance was not independently audited; those assets are not copied. No source extraction is included. [License][license] [Credits][credits]

## Comparison

| Option | What it buys | What it does not replace |
|---|---|---|
| Cargo + rustc/LLVM | Reference semantics, standard ecosystem and release artifacts | Retained-state per-function JIT editing |
| rustc_codegen_cranelift | Alternative faster compilation backend retaining rustc's frontend | Relax's runtime/inspection/hot-patching; check its own feature matrix |
| cargo-watch / bacon | Low-disruption watch/check/test workflow | Runtime state retention across rebuild/restart |
| evcxr | Interactive Rust REPL/notebook experimentation | Equivalent large-application live runtime or compatibility guarantee |
| Makepad runner | UI-host integration around Relax | Not the same artifact as this repository's bare CLI |

These are functional alternatives, not measured head-to-head results: [Cranelift backend](https://github.com/rust-lang/rustc_codegen_cranelift), [bacon](https://github.com/Canop/bacon), [evcxr](https://github.com/evcxr/evcxr).

## Practical Adoption Gate

Pilot a trusted non-critical package on a qualified platform. Pin Relax/std together, retain rustc check/test/release gates, compare outputs and drop/panic behavior, use check-first when correctness matters more than speculative latency, and measure cold/warm startup, p95 editing latency, RSS and disk growth. Test successful body edits, rejected edits, restart and crash recovery separately. Broader adoption needs demonstrated dependency compatibility and externally inspectable regression/release evidence—not just a faster first frame.

**Bottom line:** compelling compiler/runtime engineering and development ergonomics; not yet a substitute for Rust's production correctness contract.

---

**Attribution:** Makepad, [makepad/relax](https://github.com/makepad/relax), MIT root with component notices. Performance and upstream test results above are attributed, not reproduced.

[readme]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/README.md
[runner]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/tools/run/runner/src/lib.rs
[entry]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/tools/run/runner/src/bin/relax.rs
[workspace]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/Cargo.toml
[manifest]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/Cargo.toml
[jit]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/src/jit.rs
[reload]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/src/reload.rs
[reloadtests]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/src/lazy_reload_tests.rs
[inspect]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/src/inspect/mod.rs
[cache]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/src/cache.rs
[store]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/src/store.rs
[pmhost]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/src/pmhost.rs
[lower]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/src/lower.rs
[gaps]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/KNOWN_GAPS.md
[macroreg]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/front/src/macro_reg.rs
[sandbox]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/src/sandbox.rs
[help]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/tools/run/runner/src/help.rs
[unix]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/remote/src/carrier/unix.rs
[remote]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/remote/src/server.rs
[registry]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/base/src/registry.rs
[network]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/src/registry_net.rs
[fetch]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/tools/run/runner/src/fetch.rs
[contributing]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/CONTRIBUTING.md
[tests]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/tests
[license]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/LICENSE
[credits]: https://github.com/makepad/relax/blob/82b568b00473e749d5217a309f2e72bdb364cc39/libs/relax/compiler/std/CREDITS.md
