# FrankenGit (Dicklesworthstone/frankengit)

**Repo:** https://github.com/Dicklesworthstone/frankengit
**License:** LicenseRef-MIT-OpenAI-Anthropic-Rider; source-available, not OSI-approved open source. Named-party and downstream-access restrictions materially limit reuse.
**Reviewed:** 2026-10-14 (UTC)
**Revision:** ff875fcdb85f4c246773ea345a7ecaf745265ca0 (main snapshot; commit dated 2026-10-14 UTC).
**Scope:** README, licensing, workspace/dependency manifests, authority storage, local object fabric, receive validation, native merge admission, HTTP boundary, trusted workspaces, selected tests, compatibility documentation and all eight workflow trigger definitions. Selective source review, not an exhaustive audit of 48 crates.
**Verification:** Static review only. No source, build scripts, binaries or tests executed. Public GitHub metadata retrieved 2026-10-14; no Actions runs returned for this exact SHA.
**Stack:** Rust 2024, pinned nightly, Asupersync, FrankenSQLite, native Git object/pack/wire implementation; JavaScript browser shell.
**What it is:** An experimental Git-compatible node and code-forge implementation that makes Git refs and forge decisions share a single transactional authority history.

---

## Verdict

📚 **Study the transactional architecture; do not entrust it with your only repository copy.** There is substantial executable-path source here, not just a design document: native Git receive validation, conditional authority updates, HTTP/SSH transport, forge transactions and workspace export are implemented. But verified production readiness, broad compatibility and hostile multi-user isolation are not established; the restrictive license is a separate adoption blocker for affected users.

## What It Is

FrankenGit aims to replace the split between a Git repository and a separately authoritative forge database. Immutable bodies are staged first; a conditional authority-head update makes the selected ref state, forge frontier and outbox obligations authoritative together. That is its strongest design idea: a successful PR merge need not leave Git refs and PR metadata disagreeing after a crash.

It is a server/forge experiment, not a drop-in replacement for the local Git CLI or a conventional bare-repository directory. Stock Git interoperability is through wire protocols and import/export. The project explicitly calls itself pre-release and says it is not a production-ready GitHub replacement. Its README also mixes dated reality snapshots, individual historical test reports, library-only features and future architecture; those must not be read as a single current feature guarantee. [README](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/README.md)

## Stack

| Layer | Observed implementation |
|-------|-------------------------|
| Workspace | 48 first-party crates; Rust edition 2024; nightly-2026-08-31 |
| Runtime | Asupersync 0.5.0 workspace requirement |
| Authority | FrankenSQLite 0.4.0, native/async-api profile; conditional head updates |
| Git | Separate object, pack, wire, reference, admission and node crates |
| Storage | Authenticated immutable object fabric plus authority metadata; not ordinary .git as authority |
| UI | Native HTTP API and JavaScript browser modules; not the entire planned Rust/WASM product stack |
| Crypto / OS | BLAKE3 pure feature, Ed25519, ChaCha20-Poly1305; rustix for Linux descriptor-relative workspace operations |

Evidence: [`Cargo.toml`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/Cargo.toml), [`Cargo.lock`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/Cargo.lock), [`rust-toolchain.toml`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/rust-toolchain.toml), [`crates/fgit-authority-fsqlite/Cargo.toml`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-authority-fsqlite/Cargo.toml), [`crates/fgit-node/Cargo.toml`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-node/Cargo.toml). First-party unsafe code is forbidden by workspace lint policy; that is not a security audit of transitive dependencies. No dependency-vulnerability scan or reproducible build was performed. The novel runtime/database dependency stack concentrates integration risk beyond the Git parser alone.

## Key Features and Compatibility

### Native Git objects and wire paths are real, but the matrix is not certification

The receive validator binds external delta bases to an authority-selected, permitted closure, validates objects before staging them and retains a basis-bound proof for durable admission. Merely finding an object on disk is not enough to authorize its use. This is concrete protection against treating unrelated or hidden stored objects as legitimate delta dependencies. See [`crates/fgit-node/src/quarantine_validator.rs`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-node/src/quarantine_validator.rs).

There are source paths and dedicated tests for raw git-daemon, smart HTTP and SSH, SHA-1/SHA-256 formats, atomic/non-atomic receive, hidden refs and upload protocols. The checked-in thin-fetch campaign uses stock Git and checks fetched identity and strict fsck. Its own scope is a synthetic SHA-1 corpus over raw Git and HTTP, not universal byte parity, SSH evidence or a broad performance benchmark. See [`scripts/e2e/suites/transport/thin_fetch.sh`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/scripts/e2e/suites/transport/thin_fetch.sh) and [`crates/fgit-node/tests/sha256_format_matrix.rs`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-node/tests/sha256_format_matrix.rs).

The [`docs/GIT_COMPATIBILITY_MATRIX.md`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/docs/GIT_COMPATIBILITY_MATRIX.md) explicitly labels itself a **target registry, not an implementation claim**. Some rows are dated or lag newer source. Do not translate “required-v1” into “verified supported.” Signed push certificates, bundle profiles, reflog views, alternates and hook semantics need individual assessment. The server's native authority store is not filesystem-compatible with Git refs, reflogs, index files or arbitrary bare-repository maintenance commands. Import/export is a migration boundary, not permission to point Git plumbing at its storage directory.

### Ref updates and forge state share one publication decision

[`crates/fgit-admission/src/merge/native.rs`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-admission/src/merge/native.rs) evaluates and stages the ref, forge and outbox fold before publication. [`crates/fgit-authority-fsqlite/src/engine.rs`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-authority-fsqlite/src/engine.rs) wraps head exchange and token issuance in a database transaction; the conditional update includes the predecessor token and strictly increasing generation. Losers do not silently overwrite a newer head. Commit failure is followed by rollback handling, rather than abandoning an active transaction for the next caller.

The node currently sets **MAX_CONCURRENT_WRITERS = 1** and gates publication within the serving process. Read/ingress concurrency is distinct from commit concurrency. This is sensible containment of the current database envelope, but it does not substantiate the headline per-core, microbatched, extreme-scale story. Nor is a process-local gate proof that arbitrary multiple independent server processes sharing a store are supported. See [`crates/fgit-node/src/lib.rs`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-node/src/lib.rs) (WriterGate and MAX_CONCURRENT_WRITERS).

### Recovery is designed explicitly; “no data loss” is not demonstrated

Local object publication writes a fresh staging file, syncs it, installs it with a non-overwriting hard link, then syncs the destination directory. An existing object is read back and compared, rather than blindly replaced. Body placement precedes authority publication, so staged-but-unselected objects are not canonical ref state. See [`crates/fgit-object-fabric/src/local.rs`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-object-fabric/src/local.rs).

The native-merge crash test contains process-exit points after staged event/position/outbox bodies and around head CAS. Importantly, it explicitly disclaims power-loss/fsync fault proof. That is good test design and honest scope—not a passing result at this SHA. [`crates/fgit-node/tests/native_merge_durable_crashes.rs`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-node/tests/native_merge_durable_crashes.rs)

Outcome recovery is scoped to authenticated principal/repository/idempotency key; cancellation or a lost response is not automatically reported as rollback. See [`crates/fgit-node/src/treefs_workspace/transaction_recovery.rs`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-node/src/treefs_workspace/transaction_recovery.rs). Operators still need independently exercised backups, restores, storage-full behavior, power-loss testing, corruption recovery and multi-process failure campaigns before trusting durability claims. No such campaign was run in this review.

### Working trees are bounded export/import workspaces, not arbitrary Git worktrees

The Linux sparse-workspace adapter uses openat2 beneath/no-symlink/no-cross-device resolution, staging and root-last rename. It imports declared paths and refuses unsupported or undeclared changes. Its documented profile excludes symlink materialization and gitlinks, requires a protected parent directory and requires the caller to exclude concurrent tools during import/close. Those restrictions are operationally significant for real repositories. [`crates/fgit-runner/src/sparse_workspace.rs`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-runner/src/sparse_workspace.rs)

Trusted workspace execution clears the environment and exports a candidate pack without moving a ref, but runs at host-user privileges. There is **no namespace, cgroup, network or secret isolation**, and killing the direct child cannot prove descendant quiescence; affected workspaces are retained for reconciliation. This is not a safe endpoint for hostile agents or arbitrary CI jobs. [`crates/fgit-node/src/treefs_workspace/trusted_tool.rs`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-node/src/treefs_workspace/trusted_tool.rs)

## Security and Operational Fit

- **Good boundaries:** quarantine before admission; permitted object closure; explicit resource/deadline limits; immutable placement and conditional publication; dedicated hidden-ref and malformed-input tests. These are observed mechanisms, not a completed penetration test.
- **HTTP is a local capability profile:** the implementation refuses non-loopback listeners, does not terminate TLS or provide organization/team IAM, and does not trust forwarded identity headers. Git routes can use a token as a Basic password; native API routes require explicit Bearer credentials to avoid browser-cached Basic authorization leaking into them. [`crates/fgit-node/src/smart_http/server.rs`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/crates/fgit-node/src/smart_http/server.rs)
- **Other interfaces need separate trust:** README documents self-asserted principals on CLI/MCP and explicitly bound principals on the raw receive lane. Do not expose trusted-local interfaces to untrusted callers and mistake a supplied principal ID for authentication.
- **Size and time are compatibility constraints:** documented defaults bound received packs and expanded content, and selected-pack writing buffers the finished pack. Large repositories can be refused intentionally; widening limits increases memory/resource demands. See the receive/write envelopes in the compatibility matrix.
- **A reverse proxy does not finish the product:** TLS can protect a hop but cannot create missing IAM, runner isolation, complete release gates or proven recovery. Only disposable, separately backed-up experimentation is recommended.

## Tests, CI and Maturity

Public metadata on 2026-10-14: created 2026-08-20; last push 2026-10-14; 29 stars, one fork and two open issues. The releases endpoint returned an empty list. These indicate a young, active repository, not deployment evidence. Source packages inspected are version 0.0.1 and publish=false.

All eight checked-in GitHub workflow definitions use **workflow_dispatch**, not push/pull_request triggers. Their existence is therefore not continuous enforcement for every commit. The [Actions API query for the exact reviewed SHA](https://api.github.com/repos/Dicklesworthstone/frankengit/actions/runs?head_sha=ff875fcdb85f4c246773ea345a7ecaf745265ca0&per_page=1) returned zero runs. This does not rule out local or external testing; it means no GitHub Actions run for that SHA was observed. The latest run returned by the unfiltered endpoint was a [failed historical run from September 28](https://github.com/Dicklesworthstone/frankengit/actions/runs/36480385659), which cannot establish current build status.

Tests are unusually explicit about refusal twins, tampering, transport binding and crash boundaries. However, **authored tests, historical passing reports and current passing tests are different evidence classes**. No test was run here. The README's September reality snapshot admits serious verification debt and past fake-DOM tests missing actual browser failures. Later source adds workflow, delivery, indexing and policy machinery, so the snapshot's individual defect list should not be repeated as a verified current bug list without retracing each path.

## License and Reuse

The actual [`LICENSE`](https://github.com/Dicklesworthstone/frankengit/blob/ff875fcdb85f4c246773ea345a7ecaf745265ca0/LICENSE) is MIT text plus an overriding OpenAI/Anthropic rider, copyright Jeffrey Emanuel (2026). It withholds permission from the named companies, affiliates and broadly defined persons acting on their behalf or for their benefit. It also restricts providing access to them; expressly includes analysis, indexing, testing, benchmarking and machine-learning pipelines within “use”; requires the rider in derivatives; and contains termination and enforcement terms.

**Do not label this simply “MIT” or “open source.”** Its downstream restrictions are materially unlike ordinary permissive licensing. Organizations contemplating use, redistribution, hosted access or AI-assisted processing should obtain qualified advice or express permission where applicable. This review provides original analysis and links, not copied implementation or reusable extracted source. It makes no determination about enforceability.

## Comparison

| Need | Better starting point | FrankenGit tradeoff |
|------|-----------------------|---------------------|
| Reliable self-hosted team forge | [Forgejo](https://forgejo.org/) or [Gitea](https://about.gitea.com/) | Study its shared ref/forge authority; do not substitute it for a mature operational forge today |
| Local Git-compatible workflow improvements | [Jujutsu](https://github.com/jj-vcs/jj) | Different problem: FrankenGit is principally a server/forge and authority redesign |
| Git implementation components | [gitoxide](https://github.com/GitoxideLabs/gitoxide) | Assess a narrower component library rather than adopting an entire experimental forge/runtime/database constellation |
| Conventional repository storage and interoperability | [Git](https://git-scm.com/) | FrankenGit preserves native object/wire concepts but uses a different authoritative storage model |

No affiliation, derivation or implementation relationship to Anthropic's “Redesigning source control” article is asserted. Adjacent discussion is not technical provenance; this repository's README instead explicitly cites its Franken-suite dependencies and Cursor's “Git at Any Scale” as design inputs.

## Self-Hosting Notes

Treat the pinned toolchain, lockfile and specific source revision as part of the experiment. Build and test only in an isolated environment, with no production credentials and an independent copy of the repository. Exercise stock-client clone/fetch/push and fsck, compare ref/OID inventories, test a full restore, and deliberately interrupt publication before considering broader use. Keep trusted workspace commands strictly local and trusted. No install or deployment was attempted here.

## Bottom Line

The valuable material is **one authority decision for refs plus forge state, quarantine tied to a permitted closure, and outcome-aware recovery**. The missing confidence is current independent end-to-end verification and proven operations across the entire product. Revisit after reproducible release artifacts, SHA-bound passing transport/browser/crash campaigns, a documented production trust model and acceptable licensing for your use case.

---

**Attribution:** Jeffrey Emanuel / Dicklesworthstone, FrankenGit. Source-available under LicenseRef-MIT-OpenAI-Anthropic-Rider. Public-source analysis only; no implementation extracted.
