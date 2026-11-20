# Verus (verus-lang/verus)

**Repo:** https://github.com/verus-lang/verus
**License:** MIT; retain copyright/license notices for code reuse. Dependency terms remain separate; project logos are CC BY 4.0 and are not reproduced here.
**Reviewed:** 2026-11-20 (UTC)
**Revision:** d749566d31400c9d1ab437f0853ee16d769d1b04 (main snapshot; commit dated 2026-11-20). Scope: frontend/IR/solver pipeline, builtins, selected vstd and examples, guide, build/install manifests and CI.
**Verification:** Static source review only. No installation, compilation, solver invocation, proof reproduction, benchmark, or dependency vulnerability scan was performed.
**Stack:** Rust, rustc internals, Verus macros, VIR/AIR, Z3; experimental cvc5; Cargo integration.
**What it is:** A deductive verifier for a growing subset of Rust, aimed at developers willing to write specifications and proofs for systems code.

---

## Verdict

⚠️ **Interesting — strong targeted-verification candidate, not an application-correctness certificate.** Verus puts executable code, mathematical models and ownership-aware ghost resources in one development environment. The architecture and library make serious verification plausible, but adoption requires proof engineering, explicit trust-boundary audits and monitoring of soundness fixes. Start with a bounded algorithm or component, not a promise to verify an arbitrary existing Rust application unchanged.

## What It Is

Verus checks user-written preconditions, postconditions, assertions and invariants by generating solver obligations. It can establish functional properties beyond ordinary Rust type/borrow checking without leaving proof bookkeeping in the executable. Its README explicitly describes incomplete documentation and active development: this is not a stable, universal Rust verifier. [README](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/README.md)

A successful run means the selected obligations were accepted under the encoded semantics and assumptions. It does not establish that the specifications capture the product requirement, that all relevant code/configurations were verified, or that the produced application is immune to implementation bugs in the verifier, solver, compiler, libraries or environment. Inconsistent preconditions or trusted axioms can make obligations vacuously true. Verification is valuable precisely when its scope and assumptions remain visible.

## Stack

| Layer | Implementation and role |
|---|---|
| Syntax/frontend | builtin_macros and forked syn; rustc parsing, expansion and type information |
| Rust integration | rust_verify and compiler-internal overrides/forked components |
| Verification IR | vir AST → statement-oriented SST → AIR assertions/assumptions |
| Solver backend | air emits SMT-LIB and interprets local Z3/cvc5 process responses |
| Libraries | builtin, vstd, state_machines_macros; models, lemmas and trusted interfaces |
| Tooling | cargo-verus, toolchain manifests, verusdoc, regression tests |

## Key Features and Semantics

### Specifications, proofs and executable code are distinct

Function modes are spec, proof and exec. Specification functions express mathematical properties; proof functions establish logical facts; exec functions are compiled. Both spec and proof are ghost code. Mathematical int/nat are not machine integers, and ghost values cannot simply leak into executable computations. Arithmetic safety obligations in exec code must not be confused with mathematical expressions that have unspecified values outside their useful domain. [Modes](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/modes.md), [ghost/exec](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/ghost_vs_exec.md)

Variable modes are a separate distinction: exec, ghost and tracked. Tracked resources are erased like other ghost state but retain ownership discipline, supporting permission/token reasoning rather than freely duplicable mathematical facts. Ghost/Tracked wrappers contain PhantomData in the actual builtin definitions, not runtime copies of the represented proof data. [Variable modes](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/reference-var-modes.md), [builtin](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/builtin/src/lib.rs)

### Contracts need deliberate coverage

The binary search in examples/vectors.rs requires a sorted vector **and the existence of the searched-for value**. Its successful proof would not specify an absent-key API. Its loop carries quantified invariants and a decreases measure. The reverse example uses a ghost snapshot, multiple quantified invariants and an explicit trigger. These are useful, concrete demonstrations of the work needed to connect an efficient implementation to a mathematical specification. [Examples](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/examples/vectors.rs)

Recursive spec/proof functions need termination reasoning for consistency. Executable termination is subtler: the guide calls its default decreases checking a lightweight lint conditional on callees terminating, not a complete termination guarantee; exec nontermination is allowed. Do not advertise verification as universal liveness, deadlock freedom or termination. [Termination](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/exec_termination.md)

## Architecture

The driver uses rustc expansion/type information and lowers HIR through rust_verify into VIR. The vir crate handles well-formedness, mode checks, simplification, recursion and verification-condition translation; SST removes expression/statement nesting before AIR. The air crate manages SMT processes, resource limits and result interpretation. Compilation is a distinct path with ghost erasure and ordinary Rust code generation. The decomposition is a good maintainability feature, but each translation is a potential semantic correctness boundary. [Architecture](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/CODE.md), [driver](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/rust_verify/src/driver.rs), [verifier](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/rust_verify/src/verifier.rs), [modes](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/vir/src/modes.rs)

The inspected solver result code distinguishes unsat, sat, unknown and cancellation; it is not merely searching the log for the word “verified.” Nevertheless, this review found a solver-response-based pipeline, not evidence of an independently checked end-to-end proof certificate for the generated executable. Solver correctness and faithful encoding remain trust assumptions. cvc5 is described as experimental, and is not an automatic independent cross-check of every Z3 result. [SMT result handling](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/air/src/smt_verify.rs), [process interface](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/air/src/smt_process.rs)

**Documentation discrepancy:** source/CODE.md says Ghost/Tracked “unwrap to T” in its erasure section, while builtin/src/lib.rs defines PhantomData wrappers and the guide says ghost/tracked values are erased. The latter is the appropriate reading; do not infer runtime storage of proof values from the overview sentence. The erasure guide's illustrative counterexample also appears internally inconsistent (its shown verification branch returns zero despite a nonzero postcondition). Its explicit warning about configuration divergence is still important, but that snippet was not reproduced or treated as an observed successful proof. [Erasure guide](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/erasure.md)

## Trust Boundaries: What a Green Result Does Not Remove

- **admit and assume:** the frontend lowers admit to an assumption of false; assume inserts the supplied proposition as an assumption. An admit is a proof hole, not evidence. A contradictory assumption can justify arbitrary conclusions. [Lowering](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/rust_verify/src/fn_call_to_vir.rs)
- **external_body / axioms:** a proof function with an unverified body can introduce an axiom; an exec function with external_body has an assumed contract rather than a verified implementation. assume_specification and external function specifications likewise move obligations into the trusted boundary. [Trust guide](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/tcb.md), [assumed specs](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/reference-assume-specification.md)
- **external is different:** ignoring a function does not itself make that function callable from verified code with arbitrary guarantees. A trusted wrapper often supplies the bridge. Ignored trait implementations can still affect rustc's reasoning, including Send/Sync. [Trust guide](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/tcb.md)
- **Trait and library assumptions:** unchecked external trait specifications can constrain all implementations, including future unverified ones. vstd documents an obeys_* pattern to make such conditions explicit. “Standard library” does not mean “every implementation proved”: vstd combines proved lemmas, axioms and external interfaces. Seq has both lemmas replacing older axioms and a remaining axiom declaration; raw pointers use an abstract provenance model and tracked permissions. [Traits](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/external_trait_specifications.md), [Seq](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/vstd/seq.rs), [pointers](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/vstd/raw_ptr.rs)
- **Unsafe and FFI:** absence of the unsafe keyword is not a sufficient audit for Verus. Its memory-safety guide explains APIs whose safety depends on verified preconditions rather than defensive checks for arbitrary unverified Rust callers. Foreign code, OS interfaces and unverified dependencies need an explicitly reviewed specification/implementation bridge; this review establishes no blanket FFI guarantee. [Memory safety](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/memory-safety.md), [unverified calls](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/calling-unverified-from-verified.md)
- **Erasure and build parity:** the code/configuration actually compiled must match the verified exec behavior. The guide explicitly warns that conditional executable code using verus_only can break guarantees. Include features, target architecture, dependencies, compiler and solver versions in the verification record.
- **Remaining TCB:** macro expansion, rustc integration, VIR/AIR transformations, models/axioms, solver, ghost erasure, rustc/LLVM, linking and runtime/environment assumptions. This is not a fully verified compiler stack. Application claims also require adequate specifications for I/O, security policy, failure handling, side channels and concurrency progress; those are not implicit outputs of a successful proof.

### Known soundness reports: a real operational consideration

Public issue data retrieved on 2026-11-20 includes **open #3566**, reporting that a use import inside a tokenized state-machine transition can rebind pre or a field type and permit proving false. The report includes purported verifier output; **this review did not run it or establish applicability to this exact SHA**. It is a reason to review the feature's issue/fix status before relying on it, not a reproduced finding. [Issue #3566](https://github.com/verus-lang/verus/issues/3566)

The same snapshot shows closed reports #3565 (transition-let side effects omitted from a relation), #3564 (forging generated instances from within the macro body), #3502 (dyn supertrait positivity) and #3498 (recursive call type arguments in decreases checking). These document the kinds of subtle bugs a verifier must exclude. Closed status alone is not proof that a chosen binary contains the fix; verify its commit ancestry and regressions. No claim is made that all these closed issues affect the reviewed revision. [#3565](https://github.com/verus-lang/verus/issues/3565), [#3564](https://github.com/verus-lang/verus/issues/3564), [#3502](https://github.com/verus-lang/verus/issues/3502), [#3498](https://github.com/verus-lang/verus/issues/3498)

## Supported Rust and Adoption Cost

The feature matrix (itself dated 2026-05-13) lists ordinary functions, structs/enums, shared/mutable references and many traits as supported. It lists async/await, function-pointer types, Pin, hardware intrinsics, printing/I/O, custom Drop and transmute as unsupported; floating point, pointer operations, iterators, dyn traits and multi-crate integration have partial support. This is a documented snapshot, not an independent exhaustive compatibility test. Existing applications often need a verified core plus unverified integration boundaries. [Feature matrix](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/docs/guide/src/features.md)

Budget for writing models/contracts, identifying loop invariants, proving helper lemmas, managing quantifier triggers and reveal/fuel choices, and adapting proofs after dependency or solver changes. Timeout/unknown is not a counterexample, and more solver budget is not a substitute for a missing invariant. The repository's examples, guide, negative tests and libraries are meaningful maturity signals; they do not establish a predictable proof-to-code ratio or maintenance cost. No proof-effort benchmark was run.

vstd covers collections, arithmetic, raw memory, interior mutability, atomics and concurrency helpers; examples extend to linked structures, state machines and a cuckoo hash table. That is substantially more useful than a minimal syntax demo. Review the exact abstractions used rather than extrapolating to full Rust ecosystem coverage. [vstd](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/vstd), [examples](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/examples), [tests](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/rust_verify_test/tests)

## Build, CI, Releases and Reproducibility

This main snapshot pins **Rust 1.100.0** (including rustc-dev/LLVM tooling) and downloads **Z3 4.16.0** in its helper. Cargo.lock is committed, while the manifest also contains a Git dependency on the parse-partial branch of getopts; retain the lockfile rather than assuming the branch name is immutable. Vendored syn/prettyplease and compiler-related source make upgrades coupled to internal compiler interfaces. [Toolchain](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/rust-toolchain.toml), [workspace](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/Cargo.toml), [lockfile](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/Cargo.lock), [build instructions](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/BUILD.md)

The public latest-release API reported **release/0.2026.11.02.8bf68ee**, published 2026-11-02, at retrieval. That is not the same revision as this review. Installation recommends point releases and offers rolling builds. Pin the actual release/SHA, toolchain, solver, target, lockfile, verification flags and vstd version together; do not silently upgrade a proof baseline. [Release](https://github.com/verus-lang/verus/releases/tag/release/0.2026.11.02.8bf68ee), [installation](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/INSTALL.md)

CI definitions include formatting, clippy, full Linux AIR/verifier tests, vstd build/verification, cvc5 smoke/selected tests, cross-platform basic tests and configuration smoke checks. These are **configured jobs**, not observed green runs for this SHA. CI also uses mutable action references and a latest verusfmt installer piped to sh; contents: write is set at workflow scope. Some documentation tools are explicitly checksum-checked. [CI](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/.github/workflows/ci.yml)

## Installation, Privacy and Security Notes

This is primarily local developer tooling, not a hosted application needing an auth/CORS/database deployment review. The inspected solver interface uses local process pipes; cloud submission is not necessary for the basic verification pipeline. That is not a comprehensive no-telemetry audit. The separately linked browser playground entails sending source to another service; do not assume local-processing privacy there.

Build/install executes compilers, Cargo build scripts/procedural macros and downloaded tooling. Treat both the verifier supply chain and code being verified as executable development inputs; verification is not a sandbox. The Z3 helper downloads a versioned ZIP over HTTPS and unpacks/copies it without a visible checksum verification step. Installation also describes removing macOS quarantine and a rustup shell installer. None was executed in this review. Use isolated builds, explicit artifact provenance and pinned dependencies; examine scripts before adopting them. [Z3 helper](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/source/tools/get-z3.sh), [installation](https://github.com/verus-lang/verus/blob/d749566d31400c9d1ab437f0853ee16d769d1b04/INSTALL.md)

The workspace manifest itself flags older transitive dependencies in some auxiliary tools. That is a maintenance signal, not evidence of an exploitable vulnerability in the verifier: no advisory matching or reachability assessment was performed. Logs of VIR/AIR/SMT and diagnostics can contain source/specification details; treat CI logs and proof traces as code-sensitive artifacts. CPU/memory exhaustion and long solver runs also matter when accepting untrusted projects.

## Comparison

| Option | Best fit relative to Verus | Important tradeoff |
|---|---|---|
| Creusot | Another Rust deductive-verification workflow, using Why3 | Compare supported language/library subsets and specification ergonomics on the actual component |
| Prusti | Rust contract/ownership-oriented verification research | Different backend and feature/maturity tradeoffs; do not assume drop-in compatibility |
| Kani | Automated harness-based bit-precise checking of Rust | Bounded model-checking workflows differ from maintaining quantified deductive invariants; bound/unwinding obligations matter |
| Dafny | Verification-first programming with specifications and automated reasoning | Different source language/toolchain rather than verification of an existing Rust component |
| Lean/Rocq frameworks | Explicit theorem development and small-kernel checking styles | Usually greater modeling/integration burden to connect to executable Rust behavior |

These are conceptual alternatives, not benchmarked or separately audited in this review. Official starting points: [Creusot](https://github.com/creusot-rs/creusot), [Prusti](https://github.com/viperproject/prusti-dev), [Kani](https://github.com/model-checking/kani), [Dafny](https://github.com/dafny-lang/dafny), [Lean](https://github.com/leanprover/lean4), [Rocq](https://github.com/rocq-prover/rocq).

## Recommended Evaluation Gate

Choose a bounded component with a meaningful contract; enumerate all trusted functions/axioms and unchecked callers; prohibit admits and unreviewed assumptions; verify specification completeness with independent review and negative tests. Record the exact executable build configuration and proof-tool versions. Re-run proof/regression tests on upgrades and explicitly check soundness fixes affecting used features. Keep ordinary testing, fuzzing and integration/security review: they address gaps in specifications, tool implementations and external systems.

## Verification Record and Limitations

Public anonymous source acquisition succeeded. Canonical identity is verus-lang/verus, root repository scope; .git is only the input URL suffix. Public review files, README and repository tracking index were searched for that canonical source; no prior matching review was found in the inspected destination snapshot. GitHub metadata showed 3,882 stars and 268 forks at retrieval, and a last push of 2026-11-20; these are volatile popularity/activity observations, not quality scores.

Read-only static inspection covered the files cited above, not every implementation or dependency. Public issue descriptions are attributed reports, not independently reproduced exploits. No code from the source repository was executed, no toolchain/solver/model was downloaded, and no source tests were run. Artifact validation is limited to generated Markdown/HTML/index consistency and offline markup/provenance checks, not browser rendering or verification of Verus itself.

---

**Attribution:** Verus Contributors, [verus-lang/verus](https://github.com/verus-lang/verus), MIT. Analysis refers to public source and documentation at the recorded revision; public issue/release metadata is a separately dated snapshot.
