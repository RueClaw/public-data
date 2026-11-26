# Osprey (Nimblesite/osprey)

**Repo:** https://github.com/Nimblesite/osprey
**License:** MIT core; retained component/data terms also apply.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** 6ad8700e39dff01391318d2223207f22b7b2a8b3, main at acquisition and peeled commit of annotated release v0.32.0. Release published 2026-11-25T14:51:49Z; commit dated 2026-11-25T14:40:40Z.
**Scope:** Selected compiler, runtime, package manager, playground, CI, benchmarks and licensing paths, not every application.
**Verification:** Static review only. No installations, source execution, builds, tests, benchmarks, devices, paid APIs or live application probes. Anonymous source/metadata retrieval and review-artifact validation only.
**Stack:** Rust, textual LLVM IR/clang, C runtime, Osprey libraries, Node.js/Express/ws and platform hosts.
**What it is:** An evolving functional language and extensive toolchain, not an AI orchestration product.

---

## Verdict

⚠️ **Interesting — pilot the language, not a production trust boundary.** Effect handlers, explicit target checks and candid benchmark/recovery documentation deserve attention. Correctness remains evolving, and environment access falls outside the playground sandbox gate. Production adoption needs workload-specific correctness, isolation and crash-recovery validation; never expose that service with secrets in its inherited environment.

## What It Is

Osprey separates application logic from effects: code requests operations while an outer handler selects real services or deterministic test doubles. Default braces, ML and Python-like source lower into a common representation. Current tooling also contains a TypeScript flavor. These are Osprey syntaxes, not promises of arbitrary Python/TypeScript compatibility.

The repository includes an LSP, formatter, debugger/profiler, libraries, package registry/client, browser playground and native/mobile examples. Native builds produce executables; mobile targets produce C ABI libraries for platform hosts. Breadth does not imply uniform feature completeness. [E1–E2]

## Stack

| Layer | Technology / role |
|---|---|
| Frontends | Tree-sitter and Rust lowering to a shared AST |
| Semantics | Type inference, algebraic data types, effect/target validation |
| Backend | Textual LLVM IR and external clang |
| Runtime | C; GC, ARC, restricted compile-time ownership; OS-thread fibers |
| Packages | Osprey resolver, digest-pinned bundles, folder registry, optional uv |
| Playground | Express 5, ws, compiler/LSP subprocesses, non-root container |
| Persistence | Project manifests/locks/installed trees; application-specific storage |
| Dependencies | Cargo/npm/uv locks, Rust 1.100.0 pin, clang/OpenSSL/platform SDKs |

## Key Features

### Effects as an application boundary

Handlers avoid threading concrete services through every call. Static handlers can remove dispatch; control continuations have target restrictions. Full independently quantified effect rows, owned escaping continuations and abort unwinding remain unfinished. Consult current target contracts rather than assuming native/WASM/mobile parity. [E2]

### Shared compiler and explicit limits

Frontends, checking, codegen and runtime are separate. WASM rejects unsupported fibers and arbitrary FFI; hosted libraries have different ABI constraints. Persistent lists/maps and arithmetic fault policies are substantive choices. No tail-call optimization and one OS thread per native fiber limit claims about recursion or lightweight concurrency. [E1–E3]

### Integrity-checked packages

The folder registry implements bundle/path validation, digest verification, deterministic resolution, locked builds, capability-surface checks and offline verification. Authenticated public publishing and hosted trust services remain planned. Hashes establish content identity, not publisher identity. The resolver oracle checks bounded search/selection with shared helpers, not the planned 100,000-release performance target. [E4]

## Architecture

Source flavors → shared AST → type/effect checking → LLVM IR → clang/linker → C runtime or host ABI.

The CLI scans capabilities before code generation. Memory backends are selected at link time. The conservative non-moving GC requires registered threads/safepoints; allocation from an unregistered thread permanently disables collection. Native integration discipline therefore affects reclamation. ARC has different costs; neither backend is universally faster. [E3, E5]

The package manager demonstrates effects for file/network/process services and snapshot restoration after reported write errors. The playground is a thin Node supervisor around compiler and LSP. [E4, E6]

## Correctness and Performance Evidence

- **Reported correctness concern, not reproduced:** the regression ledger records generic top-level functions used as values acquiring int-defaulted signatures and producing wrong float results. The inspected identifier_fn_type still falls back to the program function signature. Demand a focused regression run; this review did not execute the reproducer. The ledger’s “since v0.28.2” heading is stale relative to v0.32.0. [E7]
- **Open issues need source reconciliation:** issue #415 describes HTTP client use-after-free, but this revision copies target fields under the mutex and releases the copy after use. The package README’s raw-extern confinement-gap paragraph likewise conflicts with current scanner/release validation, which classify and reject unclassified native declarations. Neither stale warning is treated here as an unfixed exploit. [E4, E8]
- **Benchmarks are useful, not general parity:** 24 compute cases use deterministic output oracles, three warmups and at least ten timing runs. Partial reruns preserve older baseline cells. Tracked results mix machines/dates, identify Osprey measurements with bfde24e2c rather than this SHA, and retain some old baselines with machine unrecorded. A Codon run records load averages 15–22. Do not collapse these into a “faster than Rust” score. [E9]
- Checked arithmetic versus unchecked C/Rust, persistent versus mutable collections, Node startup/JIT, Wasmtime startup and GC/ARC choices affect comparisons. Randomized demos are not the oracle-checked timing lane. Raw hyperfine exports are ignored rather than tracked. No measurements were rerun. [E9]

## Security, Auth and Permissions

### Environment reads fall outside sandbox policy

The CLI sandbox disables filesystem, HTTP/WebSocket, process-spawning and FFI groups, but omits the env builtin. That builtin maps to osp_process_env, which copies getenv(name). The playground spawns the compiler without an environment allowlist; the native runner inherits it while adding a parent-watch marker. Static tracing identifies a path for sandboxed programs to read inherited variables and return them through normal output. The package capability map also omits env. This is a code-level boundary gap, not a live exploit demonstration; actual hosted secrets/exposure were not inspected. Use a secret-free child environment and explicitly gate environment reads before treating this as tenant isolation. [E6, E10]

### Public execution needs additional controls

The inspected Node server has no application authentication or rate limiter. HTTP CORS does not authenticate callers. WebSockets accept a missing Origin and spawn an LSP process per connection without the compile/run sandbox argument. JSON is capped at 10 MiB and compiler children have a 20-second timeout, but stdout/stderr accumulate without a byte cap and there is no application concurrency queue. Fly configuration specifies 512 MiB and request concurrency limits: shared containment, not per-request isolation. The non-root container user is positive. [E6]

Runtime parent-death cleanup exists on Linux/macOS, so it would be inaccurate to claim every timed-out native child survives. This does not prove complete descendant cleanup or bound compiler/LSP memory. A smaller wrapper bug records successful exit code zero as -1 through exitCode || -1, while calculating success correctly: responses can succeed, but diagnostic exit accounting is misleading. [E6, E11]

Ordinary native programs default to all capabilities enabled. FFI/host integrations are outside the language’s memory-safety guarantee. “No panics” describes an intended programming model, not proof that compiler/runtime defects or exhaustion cannot terminate execution.

## Privacy, Provider Egress and Costs

Local compilation needs no paid LLM. The optional playground sends source to its configured hosted API; the backend logs full submitted code, compiler/program output, request metadata, WebSocket headers and LSP excerpts. Temporary-file deletion does not erase logs. Avoid confidential source or credentials without a retention/access policy. [E6]

Optional pydantic_ai adapters send bearer credentials and JSON to configured OpenAI-compatible services including OpenAI, DeepSeek, MoonshotAI and Z.AI; Ollama uses a configured endpoint. These are opt-in application/library calls, not evidence that the compiler phones home. Provider calls can incur token fees; configurable base URLs must be trusted because credentials follow them. Builds/package/model workflows also incur download, CPU/GPU and storage costs. No paid calls or model downloads were made. [E12]

## Persistence and Recovery

Back up manifests, locks and installed source trees. Transaction::commitPrepared resolves proposed content, then writes manifest/overlay and lock separately. Error paths restore snapshots and report restoration failures. This handles reported errors, not atomic activation across crashes/power loss. The registry catalog loads at startup and needs restart after publication. Verify filesystem capabilities per operation: the README’s broad host-gap inventory has stale entries. [E4, E13]

Playground work directories are ephemeral: removed after execution, periodically reaped and deleted wholesale at startup. There is no durable queue/resume protocol. Hosted libraries retain globals across calls without a public library-wide teardown API. SQLite-using examples do not grant database semantics to the whole toolchain. [E2, E6]

## Maturity, Dependencies and CI

Anonymous GitHub metadata on the review date reported 87 stars, 6 forks, 74 open issues/PRs combined and last repository push 2026-11-26T20:55:12Z. These are activity signals, not quality evidence. Latest listed release v0.32.0 resolves to this exact reviewed SHA.

CI defines Rust/C tests, language golden-output backend matrices, packages, platform jobs, coverage gates and linting. The vulnerability workflow pins OSV Scanner 2.6.0 and verifies published SHA256 sums. Other actions use mutable major tags; container bases/downloads are not uniformly content-pinned. Lockfiles help reproducibility, not proof of vulnerability freedom. [E14]

An anonymous Actions query filtered to this SHA returned a successful [Release run](https://github.com/Nimblesite/osprey/actions/runs/45636830116). Main CI is PR-triggered; this query did not establish a full exact-commit test pass. Changed-area conditions intentionally skip jobs. KLEE engine gates are excluded from make test while documented blockers remain. Mobile documentation distinguishes older simulator/device evidence from current migrated-source checks. No tests, dependency audit or sanitizers were run here. [E2, E14]

## Licensing

Root LICENSE contains MIT despite GitHub’s “Other / NOASSERTION” metadata. Preserve copyright/permission notices when reusing substantial code. The package audit identifies retained Apache-2.0 (including LLVM exception where applicable), BSD/Boost and Unicode/data material. Compiled distribution does not automatically embed required notices. The audit acknowledges missing historical derivation commits and comparisons predating later additions; it is not legal clearance. Assess packages, dependencies and downloaded models separately. No source code was extracted. [E15]

## Comparison

| Aspect | Osprey | Alternative / tradeoff |
|---|---|---|
| Effects | Multiple frontends and host architecture | [Koka](https://github.com/koka-lang/koka): focused effect-language comparison; semantics differ |
| Functional apps | Integrated evolving compiler/packages | [OCaml](https://ocaml.org/): more established compiler/ecosystem |
| Native production | Inference/effects, emerging correctness evidence | [Rust](https://www.rust-lang.org/): established ownership/systems ecosystem with borrowing costs |
| Python-like native | Osprey semantics and GPU/host integration | [Codon](https://github.com/exaloop/codon): relevant numerical compiler; neither implies drop-in CPython |

These are directional comparisons, not freshly benchmarked or comprehensively audited alternatives. Choose Osprey when its effect/host design is itself valuable; favor established ecosystems when compatibility and predictability dominate.

## Self-Hosting Notes

Pin compiler/runtime artifacts, choose the actual target/memory backend, and reproduce representative outputs before optimizing. Validate release contents for the intended target rather than relying on historical packaging reports or screenshots.

Before exposing a playground, add appropriate authentication, bounded output/concurrency, WebSocket limits, sanitized child environments and process/network/filesystem isolation. Keep logs access-controlled and short-lived. Treat the folder registry as integrity-checked distribution, not authenticated public trust. Back up project state and test interruptions between manifest and lock writes. None of these deployment steps was executed here.

## Evidence and Limitations

Links below pin inspected source to this revision. Issue/Actions/API observations are time-varying. This is selected-path static analysis, not a full compiler soundness audit or penetration test. Source-reported defects and measurements were not independently reproduced.

- **E1:** [README.md](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/README.md); [docs/contributing/repository-map.md](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/docs/contributing/repository-map.md); [src/toolchain/Cargo.toml](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/Cargo.toml).
- **E2:** [src/toolchain/website/src/status.md](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/website/src/status.md).
- **E3:** [src/toolchain/crates/osprey-cli/src/pipeline.rs](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/crates/osprey-cli/src/pipeline.rs); [src/toolchain/crates/osprey-cli/src/target_capabilities.rs](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/crates/osprey-cli/src/target_capabilities.rs).
- **E4:** [src/osprey/packages/manager/README.md](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/osprey/packages/manager/README.md); [src/osprey/packages/manager/core/src/surface.osp](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/osprey/packages/manager/core/src/surface.osp); [src/osprey/packages/manager/core/src/release_files.osp](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/osprey/packages/manager/core/src/release_files.osp).
- **E5:** [src/toolchain/compiler/runtime/memory_gc.c](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/compiler/runtime/memory_gc.c).
- **E6:** [src/toolchain/webcompiler/src/server.js](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/webcompiler/src/server.js); [src/toolchain/webcompiler/Dockerfile](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/webcompiler/Dockerfile); [src/toolchain/webcompiler/fly.toml](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/webcompiler/fly.toml).
- **E7:** [docs/regressions.md](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/docs/regressions.md); [src/toolchain/crates/osprey-codegen/src/builder/function_types.rs](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/crates/osprey-codegen/src/builder/function_types.rs).
- **E8:** [src/toolchain/compiler/runtime/http_client_runtime.c](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/compiler/runtime/http_client_runtime.c).
- **E9:** [src/toolchain/benchmarks/README.md](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/benchmarks/README.md); [src/toolchain/benchmarks/run.sh](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/benchmarks/run.sh); [src/toolchain/benchmarks/results/results.json](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/benchmarks/results/results.json).
- **E10:** [src/toolchain/crates/osprey-cli/src/sandbox.rs](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/crates/osprey-cli/src/sandbox.rs); [src/toolchain/crates/osprey-codegen/src/extern_call.rs](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/crates/osprey-codegen/src/extern_call.rs); [src/toolchain/compiler/runtime/string_runtime_list.c](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/compiler/runtime/string_runtime_list.c); [src/toolchain/crates/osprey-cli/src/native.rs](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/crates/osprey-cli/src/native.rs); [src/toolchain/crates/osprey-cli/src/toolchain.rs](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/crates/osprey-cli/src/toolchain.rs).
- **E11:** [src/toolchain/compiler/runtime/run_parent_watch.h](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/compiler/runtime/run_parent_watch.h).
- **E12:** [src/osprey/packages/pydantic_ai/src/providers_http.py](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/osprey/packages/pydantic_ai/src/providers_http.py).
- **E13:** [src/osprey/packages/manager/cli/lib/transaction.osp](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/osprey/packages/manager/cli/lib/transaction.osp); [src/osprey/packages/manager/cli/tests/src/transaction_tests.osp](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/osprey/packages/manager/cli/tests/src/transaction_tests.osp).
- **E14:** [.github/workflows/ci.yml](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/.github/workflows/ci.yml); [.github/workflows/ci-audit.yml](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/.github/workflows/ci-audit.yml); [Makefile](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/Makefile); [src/toolchain/rust-toolchain.toml](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/toolchain/rust-toolchain.toml).
- **E15:** [LICENSE](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/LICENSE); [src/osprey/packages/README.md](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/osprey/packages/README.md); [src/osprey/packages/license-audit.json](https://github.com/Nimblesite/osprey/blob/6ad8700e39dff01391318d2223207f22b7b2a8b3/src/osprey/packages/license-audit.json).

Additional observations: [release v0.32.0](https://github.com/Nimblesite/osprey/releases/tag/v0.32.0), [issue #415](https://github.com/Nimblesite/osprey/issues/415), [repository metadata](https://api.github.com/repos/Nimblesite/osprey).

---

**Attribution:** NIMBLESITE PTY LTD, Australia / Nimblesite/osprey. MIT core; component/data notices remain applicable.
