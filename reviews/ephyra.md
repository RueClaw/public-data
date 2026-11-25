# Ephyra (datadog-labs/ephyra)

**Repo:** https://github.com/datadog-labs/ephyra
**License:** MIT; retain copyright and permission notices for copied substantial material. Dependencies and tested targets have separate terms.
**Reviewed:** 2026-11-25 (UTC)
**Revision:** `3983b2e339ac5f6b843bef62c7fa6a88eba75370` (main; commit dated 2026-11-12). Scope: workspace manifests, four crates, CLI/server, runner/replay/coverage/verification paths, CI, documentation and selected case-study reports.
**Verification:** Static source review and anonymous public metadata checks only. No builds, tests, installs, target execution, model calls or live security probes.
**Stack:** Rust 2024 / MSRV 1.88, Cargo, procedural macros, seeded ChaCha randomness, Serde JSON, optional LLVM coverage; optional DogStatsD/ureq integration.
**What it is:** A Rust property-testing toolkit designed for coding agents to author and iteratively improve generators, shrinkers, mutators and correctness oracles. It is not itself a bundled LLM agent service.

---

## Verdict

⚠️ **Interesting — a credible agent-facing testing toolkit, not autonomous correctness assurance.** Explicit generator contracts, replayable failures and coverage feedback make this worth a bounded trial on a disposable test workspace. The public implementation is substantial, but the library is experimental 0.0.1, “verification” is sampled testing rather than proof, and both the coding agent and Cargo retain ordinary host execution authority. Keep the local visualization server private and turn important findings into plain regression tests.

---

## What It Is

Datadog Systems Research positions Ephyra as generator-level hill climbing: an agent writes a valid generator, measures coverage, then rewrites it to reach new code. The actual repository separates that outer workflow from the runtime. `STARTUP.md` describes how an external coding agent should choose oracles, author tests, inspect coverage, triage and iterate; the four workspace crates implement the testing machinery, source discovery, visualization and optional Datadog export. No model-provider client or autonomous LLM optimization controller is present in the reviewed workspace. [1][2][3]

This distinction matters. A conventional Rust property test can run without an account, LLM or Datadog subscription. Testing a non-Rust database/compiler requires a Rust harness driving its API, process or connection. The agent may improve that harness, but a useful oracle still depends on the target specification and independent human reasoning. An agent-written generator and an agent-written predicate can agree while both being wrong. [2][4]

## Stack

| Layer | Tech |
|---|---|
| Core | `ephyra`: generators, runner, shrinking, mutation, reports, regression replay |
| Syntax | `ephyra-macros`: test/generator/shrinker attributes and Arbitrary derive |
| Local tooling | `ephyra-cli`: syn source indexing, Cargo orchestration, std-library HTTP server and embedded HTML |
| Coverage | Optional in-process LLVM counters and mappings; instrumented builds required |
| Persistence | JSON/JSONL regressions, reports, observations and targets; HTML coverage pages, profraw files |
| Optional export | `ephyra-datadog`: DogStatsD UDP metrics/events, sampled JSONL input logs, ureq dashboard API |
| Auth | No user authentication for local visualization; optional Datadog API/app keys for dashboard operations |

The workspace excludes case studies and the standalone locate demo; a successful workspace build does not validate every showcased target. [3][5][6]

## Key Features

### Explicit, testable generators and shrinkers

Generators own their shrinking and mutation hooks. Support predicates check whether generated/shrunk/mutated values remain valid; shrink checks additionally test size reduction. `ephyra check` indexes marked generators and properties, runs generated check tests, and distinguishes clean (0), failed (1), and work-left (2) outcomes. These are practical quality gates, not mathematical verification: checks sample inputs using the supplied predicates. [4][7]

### Search, shrinking and reproducibility

The runner supports random generation, scored targeted mutation and coverage-guided retention, plus multiple distinct failure signatures and shrinking. The runtime therefore also mutates promising inputs; the README’s contrast between generator rewriting and conventional fuzzing describes the external workflow, not an absence of mutation inside Ephyra. Coverage identifies missing regions; it does not establish semantic correctness or guarantee that a better coverage score finds more bugs. [1][8]

Failures carry seed/iteration replay points. Regression entries store the original and shrunk Debug renderings alongside provenance; replay regenerates the input and warns when its rendering changes. This is better than silently replaying a different case, but it is not a version-independent serialized corpus: the comparison uses report truncation limits and Debug equality is not a semantic identity check. Preserve the generator revision, lockfile and target version, and retain a concrete regression test for important bugs. [9]

### Feedback a coding agent can consume

JSON reports, observation files, explicit targets and coverage HTML are useful feedback artifacts. The local page can discover and rerun tests and append coverage targets. Coverage leases keep Ephyra runs from polluting each other, but unrelated test threads are not stopped; exact attribution needs single-threaded tests and correct instrumentation/filter settings. [5][10]

## Architecture

The normal path is authored generator + property → macro-generated test or manual Run loop → seeded generation → property execution → retained score/coverage inputs → failure shrinking → report and regression artifacts. Separately, the CLI indexes Rust syntax and asks Cargo to build/run checks. Its visualization process reads artifacts, streams events and subprocess output, and reruns selected tests/examples. The external agent reads that feedback and edits source; that edit/approval loop is not an enforcement mechanism inside the library. [2][5][7][8]

## Claims and Independent Evidence

- **Bug yield:** the README reports 70+ SQLite bugs, 20 PostgreSQL bugs, 25 Lean bugs and additional findings in other systems. Case-study directories include reports, reproductions and some harnesses, but explicitly say several harnesses will follow. These are author-reported totals, not an independently audited comparative benchmark. No equal-budget comparison against Proptest/libFuzzer, controlled agent ablation, or complete cost accounting was established in this review. [1][11]
- **External spot-check:** upstream sqlparser issue [#2764](https://github.com/apache/datafusion-sqlparser-rs/issues/2764) exists and describes the FLUSH TABLES statement-separation defect, target revisions and AI-assisted triage. At retrieval it remained open with zero comments. That corroborates public reporting outside this repository, not maintainer acceptance, an independently reproduced bug, or the aggregate yield. [12]
- **Build evidence:** GitHub reports the named CI workflow successful for the exact reviewed SHA: [run 43289663427](https://github.com/datadog-labs/ephyra/actions/runs/43289663427). This is observed upstream CI, not a local test result or evidence all case studies work.
- **Release/activity:** manifests declare 0.0.1; the changelog dates its first crates.io release to 2026-10-29. The anonymous crates.io API returned HTTP 403, but the public sparse registry index independently showed `ephyra` 0.0.1, not yanked, MSRV 1.88. GitHub releases returned an empty list. Snapshot metadata: 128 stars, 1 fork, last push 2026-11-19; the two open items returned were dependency PRs. Stars and activity are not safety evidence. [13][14]

## Security, Authority, Privacy and Costs

**Execution is not sandboxed.** Properties, generators, build scripts, proc macros and test binaries execute with the invoking user’s permissions. CLI discovery builds binaries and executes them with `--list`; that is not a harmless static operation. Commands use structured process arguments rather than a shell, but the child inherits the process environment with additional Ephyra settings. The server can also run examples. Use a secret-free disposable environment with limited filesystem/network access and no production database credentials. Agent permission gates must be supplied by the agent host. [5][7]

**Loopback is the visualization trust boundary, not authentication.** The server binds to 127.0.0.1, limits declared request bodies to 1 MiB, blocks basic grid-path traversal and rejects many cross-site POSTs. However, `same_origin` accepts a missing Origin or any Origin beginning with `http://127.0.0.1:` or `http://localhost:`; it does not compare the exact server origin/port. Request parsing does not enforce a Host allowlist. Local clients and pages on other accepted loopback ports are therefore not separated principals. There is no login/token/RBAC layer, and served grid HTML is read directly from the artifact directory. Do not expose it through a public proxy or open attacker-controlled artifact directories. This is a static boundary assessment, not a demonstrated remote exploit. [5]

**Budgets are cooperative.** Search stopping rules check elapsed time between work units. They do not preempt a hung generator/property, fence subprocess side effects or enforce LLM spend. Apply external process time/memory limits; the server documents that stopping its accept loop leaves an ongoing Cargo run to finish. [5][8]

**Egress is optional but consequential.** The core needs no model service. Cargo may fetch dependencies, test targets may communicate externally, and an external coding agent may send source and failures to its provider. Installing the Datadog sink sends metrics/events to a configured UDP endpoint (default loopback DogStatsD); it is not enabled merely by using the core crate. Logs can include Debug-rendered inputs, and failures can include sensitive reports. The dashboard CLI uses API/app keys in headers to `https://api.{DD_SITE}`; even default print mode queries Datadog before printing JSON, while create/update write remotely. Treat endpoint environment variables as trusted configuration and scope keys to required read/dashboard permissions. [6][15]

**Costs:** MIT use has no software fee, but compilation, repeated execution, instrumentation and artifact storage cost resources. Agent inference is separately billed if a paid provider is chosen. Datadog ingestion/retention and custom metric cardinality depend on the account; per-run text-tag caps do not constitute a monetary cap. No dollar-per-bug or throughput claim was independently reproduced. [6]

## Persistence, Recovery and Export

The file-based design is inspectable and portable: copy `.ephyra` reports, regressions, targets, observations and coverage pages alongside exact source/target revisions. JSONL and dashboard JSON avoid a mandatory hosted store. Regression loading silently skips malformed lines, and saving uses append with read-before-write deduplication, without a transaction, explicit fsync or process-wide file locking in that module. A damaged tail or concurrent writers can therefore weaken completeness; do not confuse replay files with a transactional crash-recovery database. [5][9]

Run output is held in memory and capped at 4,000 lines, dropping older chunks. Reports and artifacts survive separately, but no durable job queue/resume journal or full outer-agent checkpoint system was established. Stopping visualization does not cancel active Cargo work. Back up useful artifacts, manage retention explicitly and review generated input dumps before committing or exporting them. Deleting local artifacts does not delete any copies already sent to an agent provider or Datadog. [5][6]

## Maturity, License and Supply Chain

MIT text is present with Datadog’s 2026 copyright and standard notice requirements. `LICENSE-3rdparty.csv` supplies dependency-license inventory; do not extend the root license to externally fetched database/compiler targets. No code was extracted by this review. [16]

Positive signals include a Cargo.lock, SHA-pinned CI actions, weekly Cargo/Actions Dependabot configuration, a security reporting policy, unit/integration/snapshot tests, and CI jobs for formatting, Clippy, Linux/macOS/Windows tests, feature combinations, instrumented coverage, MSRV, documentation and packaged-consumer smoke testing. Publishing depends on those jobs. This is considerably stronger than a prompt-only demo. [17]

Caveats: Rust toolchain channels and semver dependency ranges can move; case studies are updated separately and excluded from the workspace; default workspace tests do not imply every optional integration/platform path is covered. Repository/package provenance and dependency advisories were not exhaustively audited, and no binary reproducibility or independent security audit was established. The authors explicitly call the code experimental. [1][3][17]

## Comparison

| Aspect | Ephyra | Proptest | cargo-fuzz / libFuzzer |
|---|---|---|---|
| Best fit | Agent-authored structured generators with inspectable contracts and feedback | Conventional Rust property suites with composable generation/shrinking | Coverage-guided fuzz targets and sanitizer-oriented bug hunting |
| Distinctive approach | Explicit shrinker/mutator checks plus external generator-rewrite loop | Per-value generation and shrinking; established architecture | Native fuzzing engine mutates a corpus |
| Operational tradeoff | Young API; external agent/host supplies isolation and approvals | Less reason to migrate an already effective property suite | Nightly/LLVM sanitizer/C++ toolchain and supported Unix platform constraints |

Proptest describes itself as close to feature-complete with passive maintenance; cargo-fuzz documents its libFuzzer/toolchain constraints. Neither comparison was benchmarked here. Prefer Proptest for an existing stable property suite; add Ephyra when explicit generator-quality checks and agent feedback are the actual missing capability. Use cargo-fuzz when mutation throughput and sanitizer coverage are the main goal. These approaches can complement one another. The existing [Bombadil review](bombadil.md) covers a different layer: browser/terminal stateful exploration rather than an in-process Rust generator library. [18]

## Self-Hosting Notes

This is a development toolkit, not a multi-tenant deployment service. Start with a pinned source/package and a disposable workspace, independently correct properties and ordinary non-coverage tests. For later coverage trials, instrument the intended target, set its coverage filter, serialize test execution and bound the whole OS process. Keep visualization on loopback, keep all artifacts trusted, disable optional export unless required, and inspect any provider/Datadog data policy before using proprietary fixtures. Validate replay after changing the generator and promote confirmed failures to explicit tests. No installation or trial was performed for this review.

## Evidence and Verification Limits

Source links below are pinned to the reviewed commit except explicitly live metadata/alternative references. Anonymous GitHub API access and an unauthenticated HTTPS clone established public availability. Canonical-source search of the existing review collection, README and repository index found no prior Ephyra review. Artifact markup/template/link/redaction checks are publication checks, not tests of Ephyra. No source execution, model downloads, paid requests, account creation, service probes or private-data use occurred.

[1]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/README.md
[2]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/STARTUP.md
[3]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/Cargo.toml
[4]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra/README.md
[5]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra-cli/src/serve.rs
[6]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra-datadog/README.md
[7]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra-cli/src/check.rs
[8]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra/src/runner/search.rs
[9]: https://github.com/datadog-labs/ephyra/tree/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra/src
[10]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra/src/coverage/counters.rs
[11]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/case-studies/sqlparser/README.md
[12]: https://github.com/apache/datafusion-sqlparser-rs/issues/2764
[13]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra/CHANGELOG.md
[14]: https://index.crates.io/ep/hy/ephyra
[15]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra-datadog/src/bin/ephyra-datadog.rs
[16]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/LICENSE
[17]: https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/.github/workflows/ci.yml
[18]: https://github.com/proptest-rs/proptest/blob/master/proptest/README.md

Additional inspected evidence: [regression storage](https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra/src/regressions.rs), [replay checks](https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra/src/runner/remember.rs), [verification implementation](https://github.com/datadog-labs/ephyra/blob/3983b2e339ac5f6b843bef62c7fa6a88eba75370/crates/ephyra/src/verify/check.rs), [cargo-fuzz](https://github.com/rust-fuzz/cargo-fuzz), [public metadata](https://api.github.com/repos/datadog-labs/ephyra), [releases](https://api.github.com/repos/datadog-labs/ephyra/releases).

---

**Attribution:** Datadog Systems Research / datadog-labs/ephyra; MIT, Copyright (c) 2026 Datadog, Inc. Analysis is independent of the project.
