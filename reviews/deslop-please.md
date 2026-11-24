# Deslop Please (deterministic-machines/deslop-please)

**Repo:** https://github.com/deterministic-machines/deslop-please
**License:** MIT; preserve copyright and permission notices when redistributing code.
**Reviewed:** 2026-11-24 (UTC)
**Revision:** `4239b74ce75ded0955306cdbb933f7ff834d723e`, main and peeled v0.1.3 tag; whole-repository static review, with emphasis on src/, tests/, manifests and workflows.
**Verification:** Anonymous GitHub API and HTTPS Git access verified. Source and test definitions inspected; no installation, source execution, local tests, paid calls or accounts used. Upstream test and release runs at this SHA report success, not an independently reproduced result.
**Stack:** Rust 2024; Cargo; rust-analyzer SCIP; serde_json; optional Nix development shell.
**What it is:** A local, opinionated architectural linter for Rust Cargo workspaces—not an AI text cleaner, LLM agent or automatic refactoring service.

---

## Verdict

⚠️ **Interesting — pilot as an architectural review aid, not a universal quality gate.** The strongest idea is following semantic references through trivial wrappers so superficial getter/re-export reshuffling does not automatically make debt disappear. Six implemented lints, actionable terminal diagrams and debt baselining make this more than a manifesto. But its very young release history, hand-built syntax heuristics, fixed thresholds and incomplete cache invalidation call for human judgment and a pinned toolchain before blocking a team's merges.

## What It Is

The project translates the “deep modules, narrow interfaces” philosophy into repeatable checks. It discovers the current Cargo workspace, asks rust-analyzer for a SCIP symbol/reference index, combines that index with source-text analysis, builds dependency graphs, and reports structural findings. It does not determine whether code was AI-written and does not prove correctness, maintainability or security. The README's dramatic example error count is illustration, not a benchmark. [1–4]

Users are Rust maintainers who want architectural feedback beyond formatting and ordinary compiler/Clippy diagnostics. The README proposes adding instructions to AGENTS.md; that is optional adoption advice, not a built-in agent runtime. There is no model provider, API key, hosted backend, database or auto-fix command in the inspected implementation. [1–3]

## Stack

| Layer | Tech |
|-------|------|
| CLI | Rust binary; hand-parsed crate/module scope and allowlist options |
| Workspace discovery | cargo metadata --format-version 1 --no-deps |
| Semantic index | External rust-analyzer scip; build scripts explicitly disabled |
| Analysis | Custom SCIP/protobuf reader, source tokenizer, ownership model, graph components |
| Output/state | Terminal diagnostics and diagrams; local SCIP cache; plain-text debt allowlist |
| Dependencies | One direct crate, serde_json; Cargo.lock records transitive versions/checksums |
| Development/CI | Rust 1.99.0 pinned in CI/Nix; format, Clippy, tests, self-lint |

## Key Features

### Six actual lints, not just the four illustrated in the README

- **module-cycle:** cycles in module-use relationships.
- **tangle:** strongly connected “things” (types with their members, free functions/constants), flagged across modules or when more than seven members occupy one module.
- **field-leak:** outside code manipulating fields of a struct that actually guards some state; plain value reads and simple data bags are deliberately treated differently.
- **shallow-module:** eligible modules/crates showing more than seven working functions, with an overlong interface list and no more hidden than shown functions. Trait implementations and trivial wrappers are excluded from the working-function count.
- **wide-directory / long-file:** more than 15 Rust-bearing directory members, or more than 2,000 lines; blank/comment lines count. Layout checks include test code even though semantic graph checks exclude identified tests. [4–7]

### Resists some metric gaming

Methods belong to the type's home even if an impl is moved elsewhere. Wrapper/forwarder/accessor analysis follows through superficial getters and relay functions. Fixture variants explicitly exercise re-exports, moved impl blocks, padded modules, getters, copies, borrowed reads and real structural fixes. This is stronger evidence than a screenshot, but only for the tested cases. Source analysis uses a custom tokenizer and named-container/type rules rather than a complete independent Rust type checker. Macro-heavy, generated and unusual target configurations need separate evaluation. [3,6,8]

### Incremental adoption with a caveat

Exit status is 0 for success, 1 for reported debt, 2 for operational/argument errors. --update-allow writes current keys and returns success; --allow suppresses known keys and notes fixed entries. A shrinking cycle/tangle stays allowed. This is a useful ratchet for **new keys**, not a guarantee that all worsening debt fails: a previously allowed long-file or field-leak key can worsen while retaining its identity. Baseline changes need code review rather than automatic regeneration in CI. [2,9]

## Architecture

The pipeline is Cargo metadata → cached rust-analyzer SCIP → custom protobuf/symbol reader → source-augmented Model → Graph → lint diagnostics → terminal renderer. Graph construction unifies methods/fields with their owner types, resolves wrappers and computes strongly connected components. BTree collections and sorted diagnostic keys support stable reporting. No JSON/SARIF output, feature-selection flags, target-selection flag or auto-fix is exposed by the current CLI. [2–8]

A small dependency surface is attractive, but substantial parsing and language interpretation are maintained locally. The model expects indexed files to begin with their module definition and reads files named by the index relative to the workspace root; that is a trusted-index assumption, not validation of hostile SCIP input. Disabling build scripts reduces side effects and may also limit understanding of build-generated code. [3,8]

## Quality Evidence and Maturity

Anonymous metadata at review time reported **187 stars, 5 forks**, creation on **2026-11-22**, and last push on **2026-11-23T17:52:01Z**. Popularity is not validation. Reviewed commit time is **2026-11-23T17:49:21Z**; v0.1.3 was published **2026-11-23T17:54:40Z** and resolves to the exact reviewed commit. Earlier v0.1.1/v0.1.2 releases show rapid initial iteration, not long operational history. [10]

Static counting found **75 unit-test annotations in src/** and **12 integration-test annotations** in tests/end_to_end.rs (some tests iterate many variants). Coverage includes graph/parser behavior, lint boundary cases, cross-crate analysis, allowlists, negative examples and metamorphic refactor variants. CI runs cargo fmt --check, release Clippy with warnings denied, locked release tests and self-lint without an allowlist. Public [test run 45231781244](https://github.com/deterministic-machines/deslop-please/actions/runs/45231781244) and [release run 45232245409](https://github.com/deterministic-machines/deslop-please/actions/runs/45232245409) report success for this SHA. These checks were **not run locally**. No precision/recall corpus, comparative maintainability study, performance benchmark or parser fuzzing campaign was identified in the reviewed tree. [8,11]

The seven-item limit references Miller's memory paper in a code comment, and module-depth rules reference Ousterhout. Neither establishes that these exact software thresholds predict quality. Open [issue #9](https://github.com/deterministic-machines/deslop-please/issues/9) requests another-target analysis; open [PR #10](https://github.com/deterministic-machines/deslop-please/pull/10) addresses test-only target modules. Both are maturity/coverage signals, not proven fixes in the reviewed revision. [4,10]

## Security, Execution Authority and Privacy

**Not a sandbox.** The binary launches cargo and rust-analyzer by PATH, inheriting user environment and permissions. It supplies fixed arguments through Command rather than assembling a shell command, and explicitly disables rust-analyzer Cargo build scripts. That does not certify arbitrary hostile workspaces, toolchain binaries, Cargo configuration, dependency resolution or macro behavior as harmless. No process timeout or resource cap is implemented around these subprocesses. Use a restricted checkout/container without credentials for untrusted projects; do not assume “linter” means read-only or no execution. [2,3]

**Writes are real.** Index generation creates a workspace-specific hashed directory under Cargo's target directory and writes ra-config.json, index.scip and index.stamp. --update-allow creates parent directories and directly overwrites its supplied path. No application-level path confinement or symlink defense is apparent for those outputs. There is no network listener/auth/CORS surface to configure. [3,9]

**No native prompt-injection or LLM egress path was found.** There is no model call or prompt interpreter in the inspected CLI. If an external coding agent consumes diagnostics or follows the README's AGENTS.md suggestion, source names, paths and repository instructions remain untrusted data; the agent's permissions and provider policies—not this linter—control subsequent edits and data disclosure. Diagnostics, allowlists and SCIP indexes contain project structure/names and should not be uploaded indiscriminately. Cargo/rust-analyzer may require dependency/toolchain network access; no enforced offline flag is supplied. “No built-in LLM” is not proof of zero subprocess network traffic. [1–3,9]

## Persistence and Recovery

Cache stamps include the rust-analyzer version output, fixed indexing configuration and hashes of discovered Rust files, Cargo manifests and Cargo.lock. A stale/missing stamp or missing index causes regeneration. The previous stamp is removed before indexing and a new stamp is written only after successful indexing: a useful failure-recovery measure. [3]

However, source discovery skips hidden paths and symlinks; the stamp does not capture .cargo/config.toml, arbitrary environment changes or every generated/include input. Configuration changes can therefore leave a stale index, and symlinked sources merit testing. Cache writes are not atomic and have no interprocess lock; simultaneous runs can race. A corrupt existing index with a matching stamp is read and fails parsing rather than automatically retried. Recovery is to invalidate the affected generated cache and rerun, with no other run active. Allowlist replacement is also non-atomic, so version-control it. These are code-derived risks, not failures reproduced during this review. [3,9]

## Licensing and Supply Chain

The actual LICENSE is MIT, copyright 2026 Deterministic Machines, Inc.; code redistribution requires preserving its copyright/permission notice and disclaimer. This review extracts no upstream code. Dependency and toolchain licenses remain their own obligations. [12]

Cargo.lock and flake.lock improve reproducibility; CI builds use --locked. The README's plain cargo install command is not a full pinned-environment recipe. External rust-analyzer is a major semantic dependency despite only one direct Rust crate. The release workflow gates builds on CI, publishes crates.io before GitHub, and offers Linux x86_64/ARM64 musl and Apple ARM64 archives plus SHA-256 files. Checksums detect corruption but are not independent signatures; no artifact attestation/signing step was identified. GitHub Actions are version-tag referenced rather than commit-SHA pinned. The build/test job has read permissions; a separate badge publisher gets contents:write, and release jobs use registry/release credentials. Those are maintainer publishing privileges, not credentials required by ordinary users. [11–13]

## Comparison

| Aspect | Deslop Please | Rust Clippy | cargo-modules / manual architecture review |
|--------|---------------|-------------|--------------------------------------------|
| Primary value | Opinionated coupling, encapsulation and depth checks | Broad Rust correctness/style/performance lints | Structure/dependency exploration and contextual design judgment |
| Workflow | Repeatable diagnostics plus debt allowlist | Established compiler-adjacent lint workflow | More interpretation, less automatic architecture policy |
| Tradeoff | Young heuristics, fixed policy, index dependency | Not a direct replacement for these architecture rules | Humans must decide what structure is problematic |

Use it **alongside**, not instead of, [Clippy](https://github.com/rust-lang/rust-clippy), compiler checks, tests and design review. [cargo-modules](https://github.com/regexident/cargo-modules) is worth considering when the immediate need is understanding dependencies rather than enforcing this particular philosophy. These are fit comparisons, not head-to-head benchmarks.

## Self-Hosting Notes and Costs

There is no service to self-host. Pilot locally on a trusted Rust workspace with compatible Cargo/rust-analyzer available; reproduce the project's Rust 1.99.0 toolchain before comparing diagnostics. Establish a reviewed baseline, keep it in Git and initially report findings without blocking merges. Pin versions in CI; evaluate target, macros, generated code and test-only modules on representative projects before tightening enforcement. The Nix shell is declared for x86_64-linux; released binaries cover the three targets above. No subscription, paid API or model inference cost is built in; costs are developer attention, dependency/toolchain storage and indexing CPU/memory. Actual runtime/resource cost was not benchmarked. [1–3,11,13]

## Verification Limits

This is a static implementation review, not an exploit audit or runtime acceptance test. No source/dependency installation, fixture execution, binary download/execution, provider call or private account access occurred. Upstream CI status, release assets and issue state were observed anonymously and may change. Release checksums/signatures, crates.io contents, full historical evolution, false-positive rates, hostile-workspace behavior and cross-platform operation were not independently verified. The recommended next gate is a secret-free sandbox evaluation against representative known-good and intentionally bad Rust projects.

## Evidence

All code citations are pinned to the reviewed commit; metadata links are live observations from 2026-11-24 UTC.

1. [README](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/README.md)
2. [CLI and run pipeline](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/main.rs)
3. [Indexing/cache](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/indexing.rs), [workspace discovery/file enumeration](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/workspace.rs)
4. [Lint orchestration and seven-item policy](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/lint/mod.rs)
5. [Module cycles](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/lint/cycles.rs), [tangles](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/lint/tangles.rs), [graph](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/graph/mod.rs)
6. [Field leaks](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/lint/leaks.rs), [shallow modules](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/lint/shallow.rs)
7. [Layout thresholds](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/lint/layout.rs)
8. [Index model builder](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/model/from_index/mod.rs), [source heuristics](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/model/from_index/source/mod.rs), [wrappers](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/model/from_index/wrappers.rs), [SCIP parser](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/scip/protobuf.rs), [integration tests](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/tests/end_to_end.rs)
9. [Allowlist persistence and matching](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/src/allow.rs)
10. [Public metadata](https://api.github.com/repos/deterministic-machines/deslop-please), [releases](https://github.com/deterministic-machines/deslop-please/releases), [v0.1.3](https://github.com/deterministic-machines/deslop-please/releases/tag/v0.1.3)
11. [CI workflow](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/.github/workflows/ci.yml)
12. [MIT license](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/LICENSE), [manifest](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/Cargo.toml), [dependency lock](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/Cargo.lock)
13. [Release workflow](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/.github/workflows/release.yml), [Nix toolchain](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/flake.nix), [Nix lock](https://github.com/deterministic-machines/deslop-please/blob/4239b74ce75ded0955306cdbb933f7ff834d723e/flake.lock)

---

**Attribution:** deterministic-machines/deslop-please; Deterministic Machines, Inc.; MIT.
