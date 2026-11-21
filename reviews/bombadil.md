# Bombadil (antithesishq/bombadil)

**Repo:** https://github.com/antithesishq/bombadil
**License:** MIT; preserve copyright and permission notices when copying substantial source. Dependencies retain their own terms.
**Reviewed:** 2026-11-21 (UTC); original review 2026-11-19
**Revision:** a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0 (released v0.8.0); unreleased main c7bd61f3ec83761634804c50845cd96c521a45f0 compared for CI changes. Release scope: workspace, manual, CLI, browser/terminal drivers, specification/LTL engine, fuzzer/shrinker, trace format, packaging and CI.
**Verification:** Static source review only; no builds, upstream tests, browsers, target programs, installations or hosted-service calls executed. Artifact consistency checks are not product tests.
**Stack:** Rust 2024, TypeScript specifications, Boa, Oxc, Chrome DevTools Protocol, Ghostty VT/portable-pty, Axum, Yew/WASM, Cargo/Nix.
**What it is:** Antithesis's property-based tester for web and terminal interfaces—not an LLM browser agent or a configuration manager.

## Update Notes — 2026-11-21 (UTC)

**No newer release:** The latest non-prerelease remains v0.8.0, published 2026-11-19 at 11:39:03 UTC. Its tag resolves to a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0, exactly the revision reviewed on 2026-11-19. Released-code delta is zero. Binary traces, changed output-path semantics, headless-shell support and campaign exit-code improvements are existing 0.8.0 changes, not newly released features. The upstream “up to 4x” throughput claim was not benchmarked here.

**Material unreleased delta:** Main is c7bd61f3ec83761634804c50845cd96c521a45f0, one commit ahead (#469). The complete diff changes only .github/workflows/ci.yml and .github/actions/setup-nix/action.yml (21 insertions, 12 deletions). Third-party Nix/cache/Cachix, Chrome setup, GitHub release and Docker actions now use full commit hashes. Top-level permissions become contents: read plus actions: write; release, npm/Docker OIDC and Pages jobs receive required write permissions individually. GitHub-maintained actions remain version-tagged and cache-related actions: write remains a workflow default. This is meaningful hardening, not complete least privilege or pinning, and does not retroactively harden published 0.8.0 binaries.

**Prior findings rechecked:** The inspector still binds all interfaces without router authentication; reproduction hints still interpolate headers/cookies without redaction or shell quoting; URL rules still filter link actions/force Back rather than enforce network isolation; replay still matches recorded actions and can finish without proving the original violation recurred. Those implementation files are identical between release and main, and the relevant paths were reread. No runtime fix is present. License, manifests/lockfiles, changelog, runtime architecture, packaging and manuals are unchanged. Verdict remains ⚠️ Interesting. This refresh corrects the stale CI assessment for main, without calling it a new release.

**Verification:** Anonymous public release/repository metadata, exact tag and main SHAs, the complete one-commit diff and targeted static rereads only. No installation, build, upstream tests, browser/terminal target execution, network-isolation probe, release-binary verification or hosted-service call. Release-pinned citations below remain applicable.

Evidence: [latest release](https://github.com/antithesishq/bombadil/releases/tag/v0.8.0), [complete main change](https://github.com/antithesishq/bombadil/commit/c7bd61f3ec83761634804c50845cd96c521a45f0).

## Verdict

⚠️ **Interesting: a strong isolated-staging testing companion, not a production-safe autonomous explorer.** Its shared temporal-property engine, randomized action trees, trace inspection and calibrated shrinking are substantive engineering. Adoption needs application-specific oracles, disposable targets and network containment: the inspector binds all interfaces without authentication, reproduction hints echo supplied credentials, and URL exploration rules do not confine network effects. Keep conventional regression tests and treat local replay as best effort.

## What It Is

Instead of scripting one happy path, developers export TypeScript properties and action generators. Bombadil repeatedly captures observable UI state, evaluates properties, chooses an available action and waits for the next interesting event. Defaults make first runs easy; meaningful domain correctness still comes from specifications supplied by the application owner. Browser and terminal drivers share the same runner, verifier, fuzzing and shrinking machinery. [Introduction](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/docs/manual/src/01-introduction.md)

Local runs do not require an Antithesis subscription or a model API. Antithesis integration supplies state-boundary hooks and assertion reporting when used inside its environment; that is separate from claiming deterministic whole-system simulation on a developer laptop. This review did not exercise the hosted service or establish its pricing, privacy terms or operational guarantees. [Runner](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil/src/runner.rs)

## Stack and Architecture

| Layer | Implementation |
|---|---|
| CLI | Rust/Clap browser and terminal test, fuzz, shrink; trace and browser inspect |
| Specification | Oxc bundling/transformation, Boa evaluation, Rust temporal formulas and residual evaluation |
| Browser | CDP control, state/extractor capture, JS instrumentation, screenshots, action fingerprints |
| Terminal | PTY subprocess, bounded input/output queues, Ghostty virtual terminal state |
| Campaigns | Parallel workers, weighted action trees, random walks and swarm action-category subsets |
| Artifacts/UI | Versioned binary traces with JSON state metadata and payloads; Axum + Yew/WASM inspection |

The driver/session interface separates target execution from the generic runner. Each state produces snapshots, property outcomes and an action tree; the trace is written before the selected action is applied. Time limits, driver stalls, interrupts, closed drivers and error events have distinct handling. The runner attempts trace finalization and session termination even when a run fails, preserving the primary error while reporting cleanup errors. This is much better than treating every abnormal stop as a property success. [Runner](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil/src/runner.rs), [driver contract](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil/src/driver.rs)

## Exploration, Oracles and Failure Detection

### Random exploration is real; exhaustive coverage is not

The local fuzzer starts independent sessions, draws per-worker/per-run seeds and selects from weighted available action leaves. Swarm mode probabilistically excludes action categories for a run, retaining the whole tree if exclusion would remove everything. The inspected local selection path is random/swarm, not a coverage-guided corpus optimizer. JavaScript block hits and abstract snapshots are useful instrumentation; the changelog explicitly describes abstract snapshots as support for **future** targeted fuzzing. Neither those records nor a long clean campaign prove all relevant states were visited. [Fuzzer](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil/src/fuzzer.rs), [changelog](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/CHANGELOG.md)

### Defaults are narrow smoke-test oracles

Browser defaults check navigation response status, uncaught exceptions, unhandled promise rejections and console errors. The HTTP property reads the first navigation performance entry; it is **not** an assertion that every fetch/XHR or subresource request succeeded. Console noise can create failures unrelated to business correctness; silent corrupt calculations can pass. Terminal defaults check replacement characters and nonzero exit codes when the exit has no signal; the exported exitSuccess formula alone does **not** reject signal termination. Add explicit crash/signal, persisted-state, business-invariant and bounded-response properties rather than trusting the names. [Browser defaults](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil/src/specification/browser/defaults/properties.ts), [terminal defaults](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil/src/specification/terminal/defaults/properties.ts)

Temporal formulas distinguish false, true and residual obligations. The runner reports false outcomes as violations; residual outcomes are not failures at that point. An unbounded eventually condition can remain unresolved until a campaign ends, so use explicit deadlines and review actual reached states. A finite run with no violations is evidence about its observations, not a proof of liveness or universal correctness. Missing states, extractor mistakes and action reachability remain part of the oracle's trust boundary. [Specification manual](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/docs/manual/src/03-specification-language.md), [runner](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil/src/runner.rs)

Campaign reporting records failed runs and worker panics separately. The CLI returns exit code 2 for detected violations; without violations, failed runs/panics produce errors. That supports useful CI gating, but CI should retain the report and distinguish infrastructure failure from an application counterexample. [Campaign report](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-cli/src/fuzz_report.rs)

## Replay and Shrinking

Browser reproduction consumes recorded actions and matches them to available action templates, preferring the recorded template identity. It errors when an action no longer matches; completing the recorded action prefix is not a byte-for-byte comparison of application state or assurance that the original violation recurred. A seed cannot freeze server databases, clocks, network responses, browser versions or scheduling. Preserve the app/specification revision, dependencies, browser variant/options, fixtures and reset procedure alongside the trace. [Strategy](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-browser/src/strategy.rs), [workflows](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/docs/manual/src/04-workflows.md)

Shrinking targets a selected violated property, calibrates reproducibility and repeatedly reruns shorter candidates. Defaults include three calibration runs, up to five confirmation runs and a 0.25 minimum confirmation ratio. It writes the currently smallest known trace while searching. This is valuable flakiness-aware minimization, not proof of a globally minimal or reliably deterministic counterexample; both shrinking and fuzzing are marked experimental in the release history. Repeated candidates also repeat real target side effects. [Shrinker](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil/src/shrink/mod.rs)

## Security and Operational Boundaries

### Inspector exposure is the clearest deployment concern

The inspect server binds HTTP to **0.0.0.0**, with trace and screenshot GET routes and no authentication middleware in its router. Reachability depends on firewall/container networking, but this is not loopback-only by default. A reachable inspector exposes captured application data. Keep it in an isolated network namespace or enforce host-side ingress restrictions; do not publish its port or put sensitive traces behind an unauthenticated proxy. This finding is static, not a live exploit test. [Server construction](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-cli/src/inspect_server.rs#L233-L269)

### Exploration boundaries are not egress controls

The default allow pattern follows the initial scheme/host/port; explicit patterns replace it. Enforcement filters recognizable link clicks and forces Back after landing outside the permitted URL set. It does not form a network firewall for fetches, redirects or custom JavaScript. Chrome permission defaults explicitly include local-network access variants, and the browser applies permission grants without an origin restriction in that call. Run with denied-by-default egress outside the disposable test environment, not with access to private services merely because the target URL is allowed. [CLI options](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-cli/src/browser.rs#L203-L265), [strategy](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-browser/src/strategy.rs), [browser setup](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-browser/src/browser.rs#L279-L328)

### Authentication material and target authority

Extra headers are installed at the CDP session level for browser requests; they are not implemented as a per-origin secret broker. Cookies have browser scoping semantics, with explicit Domain/Path/Secure/HttpOnly overrides. Use short-lived, least-privilege synthetic accounts; do not pass a production bearer header to an arbitrary-page explorer.

More concretely, reproduce_command_args interpolates supplied header values and cookies into the reproduction command that the test command prints. This can copy credentials into terminal recordings and CI logs. Header/cookie arguments are also not shell-quoted there, so a printed hint is not a safe command to paste blindly. Redact logs, avoid reusable credentials and inspect hints before reuse. [Hint construction](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-cli/src/browser.rs#L591-L629), [printing](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-cli/src/browser.rs#L790-L804)

Managed Chrome gets temporary user-data/crash directories and process cleanup. Its sandbox is disabled only when requested through no_sandbox; it is not intrinsically disabled in the launcher. External-browser mode instead connects to an existing debugging endpoint, which may carry existing session authority. Neither mode makes mutations harmless: clicks can submit orders, delete records, send mail or start downloads. Downloads are actually allowed into a temporary directory despite an outdated source comment saying they are prevented. [Launcher](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-browser/src/chromium.rs), [download behavior](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-browser/src/browser.rs#L304-L317)

Terminal mode starts the requested program in a real PTY at the current working directory, without an OS sandbox or explicit environment clearing in that spawn path. It can mutate files and invoke network services with the program's authority; PTY cleanup kills/waits for the child but is not rollback. Do not fuzz a real shell, privileged CLI or authenticated coding agent against valuable workspaces. Bounded input queues can drop input when full, another reason not to equate a recorded intended action with guaranteed target receipt under overload. [PTY implementation](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-terminal/src/pty.rs)

Specifications are executable code, not passive JSON. Boa is not Node.js, but browser extractors/custom actions run against the target page; imported specification dependencies and target code must be trusted for this use. Application isolation, output review, resource limits and side-effect suppression remain operator responsibilities.

## Artifact Retention and Recovery

Version 0.8 introduces a binary envelope and append-only records with header/payload CRC-32, bounded record lengths and an explicit END marker. Readers distinguish incomplete final records from corruption and report unfinished traces; inspector handling can serve a readable prefix with an error indication. Overwrites first create an envelope in a sibling temporary file and rename it, and shrink input aliases are rejected. These are thoughtful recovery safeguards—not encryption, tamper-proof signatures, a full disk quota or a whole-campaign transaction. [Trace format](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-trace/src/lib.rs), [inspection](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/bombadil-cli/src/inspect_server.rs)

Traces include snapshots, actions, URLs and visual/terminal payloads: treat them as sensitive data even if auth fields are absent. Default output uses unique system-temp files; fuzz output creates numbered sibling files. Downloads use separate temporary storage removed afterwards. Choose durable output directories, access controls, retention limits and disk monitoring explicitly; ephemeral cleanup is not an archival policy, and a process kill can leave temporary files. The 0.8 trace format is incompatible with earlier versions, so preserve the matching tool version and export JSON where useful. [Workflows](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/docs/manual/src/04-workflows.md), [0.8 changes](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/CHANGELOG.md)

## Build, Installation, License and Maturity

The manifest pins a Git revision for libghostty-rs and the repository includes Cargo.lock and flake.lock. Native/browser/JS-engine dependencies make this more than a tiny Rust-only build. Nix, Cargo build scripts, third-party sources and browser binaries remain supply-chain inputs; lockfiles reduce drift but do not certify safety. No dependency vulnerability scan or reproducible-build comparison was performed. [Workspace manifest](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/Cargo.toml)

The npm package builder emits type declarations and a Node wrapper that selects a bundled Linux x64/arm64 or macOS arm64 executable, rather than an LLM or a runtime model download. CI assembles binaries and publishes with npm provenance. Manual binary installation uses versioned GitHub releases; the shown download instructions do not perform signature/digest verification and advise curl to avoid macOS GateKeeper blocking. Verify origin/integrity independently instead of interpreting that workaround as a security guarantee. No automatic updater was established in the inspected entry paths. Pin tool/browser versions and deliberately migrate traces on upgrades. [Packaging](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/lib/nix/npm-package.nix), [installation](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/docs/manual/src/02-getting-started.md)

CI defines Linux/macOS unit/browser tests, a headless-shell lane, inspector testing, browser/terminal fuzz smoke tests, Docker and npm smoke tests, formatting and Clippy. The source contains LTL equivalence/depth tests, fake-driver shrink tests, trace round-trip/recovery tests and numerous browser fixtures. Those are strong maintenance signals, not results independently reproduced here. At released v0.8.0, workflow actions use version tags and the top-level workflow grants several write permissions. Unreleased main addresses much of this with third-party action pinning and job-specific publication/OIDC permissions; GitHub-maintained actions remain tag-based and default actions: write remains for caches. See Update Notes for the exact revision and remaining limits. This is source inspection, not proof of a successful hardened release build. [CI](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/.github/workflows/ci.yml)

Public GitHub metadata retrieved 2026-11-21 showed 2,943 stars, 106 forks, 43 open issues/PRs combined and a last push on 2026-11-20. The latest public release was v0.8.0, published 2026-11-19 at 11:39:03 UTC; the reviewed commit subject is release v0.8.0. This is an active pre-1.0 tool with intentional compatibility breaks, not a frozen stable test protocol. Metadata/popularity does not establish quality. [Repository metadata](https://api.github.com/repos/antithesishq/bombadil), [release](https://github.com/antithesishq/bombadil/releases/tag/v0.8.0), [MIT terms](https://github.com/antithesishq/bombadil/blob/a56bfa7af69fcb51fc2f99cd7e04d9c9073324f0/LICENCE)

## Comparison and Practical Fit

| Alternative | Prefer it when | Bombadil's distinctive value |
|---|---|---|
| Playwright / Cypress | You need explicit workflow regressions, known assertions and controlled fixtures | Generates unexpected action sequences and evaluates temporal properties continuously |
| fast-check + Playwright | You want a custom model/state-machine harness and bespoke reset/shrink behavior | Integrated UI observation, driver loop, action generators and inspection reduce assembly work |
| Hypothesis stateful testing | Python-level APIs/domain models are the most useful abstraction | Direct browser/terminal exploration with one shared property engine |
| Antithesis platform | You need controlled whole-system scheduling/fault exploration in a separate hosted environment | Open local/CI harness and integration hooks; local execution is not equivalent to the platform |

No LLM inference provider or token bill is required for the core flows inspected. Costs instead come from CPU/browser workers, repeated target transactions, artifact storage and optional external infrastructure. If the target is itself an AI/API application, fuzzing and shrinking can trigger paid requests; Bombadil's time/parallelism controls are not a provider spend cap.

**Recommended pilot:** disposable fixture data, sandboxed terminal targets, isolated Chrome, synthetic credentials, constrained egress, non-public inspector, fixed tool/browser/spec versions and explicit bounded business properties. First deliberately inject a known fault to validate the oracle, then reproduce and shrink it while checking fixture resets and retained artifacts. Keep your deterministic regression suite. Promote only after your own safety and reproducibility acceptance tests; none of that execution was performed for this review.

---

**Attribution:** Antithesis / antithesishq/bombadil, MIT. Analysis is independent; no upstream source copied as a reusable component.
