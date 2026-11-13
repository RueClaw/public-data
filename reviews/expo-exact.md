# Exact (expo/exact)

**Repo:** https://github.com/expo/exact
**License:** MIT core; vendored code, fonts and media retain separate terms.
**Reviewed:** 2026-11-13 (UTC)
**Revision:** 6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63, main; commit dated 2026-11-12T23:56:20Z. Repository-wide static sampling, emphasizing compiler/runtime, hosts, grants, updates, tooling and example services.
**Verification:** Source and public metadata inspected; no source execution, installations, builds, tests, device access, model downloads or live service probes.
**Stack:** Rust, Contract, TypeScript/Bun, Hermes, Swift/AppKit/UIKit, browser DOM/CSS, Taffy, wgpu/vello and tiny-skia.
**What it is:** Expo's experimental cross-platform application compiler and runtime, designed for both human authors and coding agents—not an LLM provider, numerical library, or a React Native/Expo SDK wrapper.

## Verdict

⚠️ **Interesting — a compelling architecture for a pinned experimental app, not a stable cross-platform foundation yet.** Typed declarative views, a shared inspectable runner, deterministic agent operations and signed recoverable updates fit together unusually well. Deliberately absent compatibility guarantees, uneven host capabilities, incomplete public verification and materially different web security boundaries make production adoption a substantial engineering commitment.

## What It Is

Exact compiles a small declarative language, Contract, into a validated plan. Views, keyed lists, typed resources, state and actions live in Contract; TypeScript or Rust supplies data and effects. The web uses real DOM/CSS; native hosts run a Rust VM and layout kernel, with Apple presenters or painted surfaces. An agent can inspect trees/state/layout, operate controls, capture screenshots and seek a clock through the same ten-operation interface.

The canonical identity is **expo/exact**, with internal names such as **exact2**. It is distinct from Expo's established React Native stack; there is explicitly no JSX/React tier. The README references a separate private design record, which was not accessed and is not evidence for this review. Public guides and implementation are sufficient to establish what is shipped, but not every design justification. No matching canonical-source review was found in the public reviews, README or research index; the owner-qualified slug avoids name collisions.

## Stack

| Layer | Implementation |
|---|---|
| Authoring | Contract view/state/actions; TypeScript or Rust data sources |
| Compilation | syntax → types → analyze → lower; baked plan, generated schema/type declarations |
| Runtime | Rust runner, typed expression VM, keyed instances, seekable time |
| Layout | Columnar kernel and patched Taffy; browser owns web layout |
| Presentation | DOM/CSS; AppKit/UIKit; GPU/CPU painted hosts |
| Data | Hermes on native, browser JS, native or Wasm Rust modules |
| Persistence | Host-owned files/SQLite; browser storage; separate signed update store |
| Tooling | Source-checkout Bun CLI, Cargo workspace, agent driver and Contract tests |

Sources: [README.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/README.md), [Cargo.toml](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/Cargo.toml), [package.json](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/package.json), [contract/cli/src/main.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/contract/cli/src/main.rs), [runner/src/lib.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/runner/src/lib.rs), [kernel/src/lib.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/kernel/src/lib.rs).

## Key Features and Architecture

### One plan, multiple presentation strategies

The compiler is not transpiling an ordinary React application. It restricts view expressions and routes effects through named data sources. The runner checks data shapes and maintains keyed component identity; the kernel uses generated property/opcode tables, generation-checked IDs and validate-before-apply transactions. Both runner and kernel forbid unsafe Rust in their own crates, not in the entire native dependency graph. This architecture makes inspection and deterministic state transitions much more tractable than arbitrary UI scripting.

The web JS target emits an ES module over a small DOM runtime, while other web paths include Wasm. Apple uses a C ABI and native presenters; Linux paints its own tree. Optional canvas, GPU, editor and other modules are separate artifacts rather than prerequisites for the first frame. TypeScript is baked to Hermes bytecode for native use after first pixel. The no-app-JavaScript-before-first-pixel claim is a boot architecture objective—not a promise that apps never execute JavaScript or lack native interop.

### Agent-facing tests are a first-class interface

The ten operations are tree, screenshot, tap, type, state, layout, logs, clock, prefer and perf. Contract test files target the shared driver; seekable time avoids sleep-driven animation tests, and stale-build checks aim to stop tests running against old sources. Test mode substitutes or holds sensitive effects: storage defaults to scratch/none, and subprocesses require declared scripts. These are useful testing controls, not a sandbox around the coding agent itself. A green synthetic drive does not establish real permission prompts, provider responses, accessibility or device behavior. The README itself advises inspecting screenshots because assertions can pass with broken layout.

Evidence: [scripts/agent.mjs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/scripts/agent.mjs), [runner/src/agent.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/runner/src/agent.rs), [data/host/src/lib.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/data/host/src/lib.rs), [packages/child-process/README.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/packages/child-process/README.md).

### Update delivery has real recovery machinery

The production store verifies Ed25519 signatures against baked keys, checks app/channel/compatibility identity, verifies digests and rejects sequences below its accepted floor. An authenticated envelope is checked before its referenced index is fetched. Downloaded entries are assembled temporarily and renamed into place. Selection/activation is separate from download; verified generations pin assets, and a live-record recheck protects against stale download state overwriting newer decisions.

Boot failure counters are written before launch and cleared after first pixel, with last-good/embedded fallback. Unknown store codecs leave the record alone and choose the embedded bundle. This is stronger than simply replacing files in place. **First pixel is not application health**, however: later data corruption or functional regressions need app-level validation and backups. Trust-key rotation requires a new binary; development can explicitly admit unsigned heads. Windows durable update storage refuses rather than claiming parity. Apple TypeScript/Rust and Linux Rust update support are not interchangeable, nor does an update grant new installed capabilities.

Evidence: [update/src/lib.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/update/src/lib.rs), [update/src/store.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/update/src/store.rs), [update/src/store/disk.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/update/src/store/disk.rs), [update/src/envelope.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/update/src/envelope.rs), [README.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/README.md).

## Security, Execution and Privacy Boundaries

### Grants are valuable, but not universal isolation

The grant parser models exact network origin tuples, explicit wildcard/scheme grants and filesystem prefixes compared by whole path components. Traversal-shaped paths are refused rather than normalized into authority. The filesystem helper walks owned directory descriptors with no-follow opens and rejects symlinks/non-regular static files. That is concrete hardening, not merely a permission paragraph.

Still, builders, Cargo build scripts, native modules and ordinary native Rust code execute with their process's authority. Treat source checkouts, build dependencies and native extensions as trusted software; do not use a declared grant list as a substitute for OS sandboxing. A broad scheme grant is broad authority. Camera, microphone, files and other optional modules add platform permissions when used; their availability and operating-system prompts differ by host.

The child-process package supports macOS/Linux, requires a named process grant and rejects tool/wake/device-origin calls as person-required; app-authored code remains allowed. A permitted executable can itself perform work outside Exact's API grant checks. This package is unsupported on the other listed hosts at this revision.

Evidence: [grants/src/lib.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/grants/src/lib.rs), [filesystem/src/directory.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/filesystem/src/directory.rs), [packages/child-process/README.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/packages/child-process/README.md), [runner/src/process.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/runner/src/process.rs).

### Web redirects expose a meaningful parity limit

The web JS admission code calls browser fetch and checks the **final response URL afterward**. The public reference explicitly documents that native fetch checks each redirect before contact, whereas browser-controlled intermediate hops may already receive a request—including a POST body preserved by a 307 redirect. Static/dev pages have no supplied CSP; render-server CSP bounds app-wide origins, not necessarily the originating source's narrower grants. Ordinary page code can also call browser fetch directly.

Therefore, Exact grants are **not a browser sandbox or a reliable per-source egress boundary**. CORS does not undo a request already sent. For sensitive data, design a trusted server-mediated flow, constrain redirect behavior and set an appropriate deployment CSP; do not send secrets assuming a final-URL refusal prevents disclosure. This is a documented/code-confirmed limitation, not a live exploit claim.

Evidence: [host/web-js/admission.js](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/host/web-js/admission.js) (fetch and post-response check), [host/web/http-body.js](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/host/web/http-body.js), [docs/reference.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/docs/reference.md) (network grants/redirect discussion).

### Authentication and local development

The shared auth-session layer validates authorization/callback URL structure, refuses URL userinfo, requires nonempty state and centralizes callback admission. It deliberately treats a returned callback as delivery, not completed sign-in; provider token exchange and server-side authorization remain app responsibilities. Sign-in helpers and OAuth fixtures do not make every app a complete secure identity service. Platform secret storage and presence policies also need host-specific qualification, not an assumption that browser storage equals an Apple Keychain.

The web dev server defaults to loopback, with explicit LAN/tunnel host admission and a Host gate; local installer access is separated from shareable page access. Keep development interfaces private. The optional Linux VNC surface is development-only and uses an explicitly configured short password; do not treat it as encrypted Internet-facing remote access.

Evidence: [runner/src/auth.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/runner/src/auth.rs), [runner/src/secrets.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/runner/src/secrets.rs), [packages/sign-in/web/index.js](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/packages/sign-in/web/index.js), [host/web/dev.mjs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/host/web/dev.mjs), [scripts/install-page.mjs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/scripts/install-page.mjs), [README.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/README.md).

### Feedback is consent-oriented, not nonexistent

The CLI keeps command metadata and agent-authored diaries locally. Default feedback policy is ask; local/never policies and EXACT_FEEDBACK=0 refuse sending. Policy is keyed to the real project path in user configuration, so cloning a project does not import consent. Sending goes to Expo's collector (or an override), includes redacted diary/command metadata, and attaches project README material only through a separate option/confirmation. A receipt supports deletion; concurrent sends are explicitly not coordinated.

This is considerably better than automatic hidden upload. But regex redaction cannot guarantee anonymity, and an agent can invoke the explicit yes flag: consent remains a responsibility of the authoring harness and operator. Diaries, logs and sent copies are retained local artifacts; use the local/never controls for confidential work. Nothing was sent during this review.

Evidence: [scripts/feedback.mjs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/scripts/feedback.mjs), [scripts/feedback-note.mjs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/scripts/feedback-note.mjs), [docs/diary.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/docs/diary.md).

## Persistence, Providers and Costs

UI state is not automatically durable. The README todo example keeps data in memory; persistent apps explicitly use files/SQLite. Native data storage distinguishes durable data, evictable cache and temporary directories; browser storage is subject to browser-origin lifecycle/quotas. The Fieldnotes example demonstrates backup/restore, but this is not a framework-wide guarantee of database migration, synchronization or recovery. Test recovery of app data separately from signed bundle rollback. Snapback is optional and its source directory is absent in the reviewed repository; related commands refuse without it.

Exact itself requires no model account to compile and run an ordinary app. External coding agents have their own subscriptions/API costs and see whatever source/screenshots their workflow supplies. Optional language-model adapters include Apple's Foundation Models and the browser Prompt API, with availability checks, device/OS restrictions and scripted agent substitutes. Browser downloads and model readiness are additional lifecycle concerns, not universal offline availability.

The Messages demo instead uses a local Bun transport to OpenRouter: key stays in the service, messages leave the machine, jobs/results are held in memory, and the service caps six active generations, a two-minute timeout and 2,048 output tokens. Host/Origin checks and JSON validation reduce browser abuse, but requests without an Origin are accepted and there is no per-user authentication or monetary budget. Local processes and allowed development origins remain trusted. Restart loses active jobs; request-ID reuse is not durable exactly-once billing protection. This is a demo service, not a public multi-tenant gateway. Provider/model pricing, hosting, signing and store distribution costs are separate from Exact's MIT license.

Evidence: [data/host/src/lib.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/data/host/src/lib.rs), [apps/fieldnotes/app.ts](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/apps/fieldnotes/app.ts), [apps/messages/service.ts](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/apps/messages/service.ts), [packages/language-model/web/index.js](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/packages/language-model/web/index.js), [packages/language-model/apple/LanguageModelApple.swift](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/packages/language-model/apple/LanguageModelApple.swift), [README.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/README.md).

## Platform and Installation Reality

- **Web:** fastest accessible authoring path; DOM/CSS, browser-dependent APIs and the security differences above.
- **macOS/iOS:** AppKit/UIKit, Xcode/signing/SDK requirements; native validation requires actual Apple runtime access. Linux cross-compilation does not execute an iOS Simulator.
- **Linux:** GPU/CPU painted runtime, documented DRM/KMS/headless paths and direct input/display dependencies. Do not equate the headline with a turnkey GTK/Qt desktop integration. The Linux source now names Parley text measurement while the README architecture paragraph still names cosmic-text—a small but concrete documentation drift signal. Editing and some language segmentation remain limited in the documented matrix.
- **Android/Windows:** present but explicitly early/unfinished; module capability, platform-control presentation and delivery parity vary. Read individual package manifests rather than assuming every host supports every device API.

There is no packaged stable CLI: generated apps refer to a source checkout by path. Tooling pins Bun 1.4.2, Rust 1.97.0 and numerous JS dependencies; Cargo/Bun lockfiles and vendored patch inventories improve reproducibility. Setup still installs toolchains, components, npm packages, Binaryen and Hermes artifacts, and builds execute source-controlled scripts. Pinned/attested Hermes bundles are a good provenance measure, not proof that every transitive dependency is safe. Offline ordinary builds depend on prior provisioning; no clean-machine build or artifact attestation was independently exercised here. Freeze the whole checkout and archive working toolchain/SDK inputs before updating.

Evidence: [rust-toolchain.toml](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/rust-toolchain.toml), [package.json](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/package.json), [Cargo.toml](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/Cargo.toml), [host/linux/src/lib.rs](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/host/linux/src/lib.rs), [vendor/taffy/EXACT-PATCHES.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/vendor/taffy/EXACT-PATCHES.md), [README.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/README.md).

## Maturity, Tests and Claims

Public GitHub metadata retrieved on 2026-11-13 UTC reported creation on 2026-11-02, 3,352 stars, 82 forks and 58 open issues/PRs combined. The public releases endpoint returned an empty list. Those are a dated visibility snapshot, not evidence of engineering age or quality: checked-in documentation predates public repository creation.

There is substantial test infrastructure: Rust tests, compiler corpus, browser/script tests, cross-host Contract fixtures, update recovery tests and benchmark directories. But the fast GitHub CI workflow performs checks/lint rather than tests; the separate tests workflow runs default-member Cargo tests and Linux script tests. Its comments explicitly exclude Apple app/XCTest/simulator drives and Android/Windows builds from CI. Actions use version tags rather than immutable action SHAs. No passing run at this revision was established; the queried ci run was queued during inspection.

More importantly, a current public issue records missing async-lane notes and pre-existing main-branch test failures. That is an upstream report, not a failure reproduced in this review. Another open select-menu issue has already updated its progress to say accessibility support landed while native popup presentation remains unfinished—its older title/body alone would overstate the remaining defect. This is a fast-moving tree that needs revision-specific verification.

The README's ~20 KB runtime, 100 ms startup/restart budgets, ~99 ms edit loop and comparison against React are upstream measurements/targets on specific applications and conditions, not independent general benchmarks. Shared clocks cannot eliminate real network, OS, permission or scheduling failures. Private design-document citations do not add publicly reproducible evidence. No performance, battery, accessibility or security certification is inferred.

Evidence: [.github/workflows/ci.yml](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/.github/workflows/ci.yml), [.github/workflows/tests.yml](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/.github/workflows/tests.yml), [issues/20261110-async-lane-results-are-not-on-origin.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/issues/20261110-async-lane-results-are-not-on-origin.md), [issues/20261111-select-menu-reaches-no-assistive-technology.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/issues/20261111-select-menu-reaches-no-assistive-technology.md), [SECURITY.md](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/SECURITY.md), [public repository metadata](https://api.github.com/repos/expo/exact), [releases](https://api.github.com/repos/expo/exact/releases), [revision CI run](https://github.com/expo/exact/actions/runs/43332991873).

## Comparison and Practical Fit

| Alternative | Prefer it when | Exact's differentiator/tradeoff |
|---|---|---|
| React Native + Expo | Existing React skills, mature mobile ecosystem and established distribution matter | New small language and agent-inspectable runtime; no drop-in JSX migration |
| Flutter | A broadly established cross-platform widget/rendering stack is needed | Native Apple controls plus DOM web strategy rather than one universal widget surface |
| Tauri + web UI | Reusing an existing web app with a native shell is the goal | Exact avoids a native webview UI, but requires a different authoring/runtime model |
| Qt/QML or Slint | Conventional desktop/embedded tooling and deployment are priorities | Exact's compiler/agent/testing integration is attractive; maturity and platform qualification are the cost |

These are architectural alternatives, not comparative benchmark results. Start with a disposable, nonsensitive vertical slice: one real persistent feature, keyboard/accessibility requirements and the weakest required host. Pin the commit; verify rendering, grants, offline restore and update failure behavior on actual targets. Require an app-specific passing test baseline and a toolchain/update plan before shipping. Avoid it for a fixed-deadline product that needs stable APIs, React compatibility or unquestioned host parity.

## License and Review Limits

The root MIT license names 650 Industries, Inc. (Expo); retain its copyright/license notice when reusing substantial code. NOTICE identifies separately licensed vendored components, OFL/other fonts, permission-based media and a CC BY 4.0 animation/model contribution. Do not assume every screenshot or asset is MIT. This review extracts no implementation or media.

This is a sampled static review, not a full audit. No dependencies installed, source tests run, simulator/device/desktop accessed, accounts created, deployments performed or paid calls made. Network use was limited to public source/metadata acquisition and publication. Native grant enforcement, every provider adapter, binary supply-chain receipts and platform permissions were not exhaustively audited. Public documentation drift and references to unavailable design materials limit certainty. Review conclusions apply only to the recorded SHA.

**Attribution:** [Expo / expo/exact](https://github.com/expo/exact), MIT core; see [LICENSE](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/LICENSE) and [NOTICE](https://github.com/expo/exact/blob/6b10991dc21b1eb4c794f73ebcc7fc91f72bcf63/NOTICE) for scope and exceptions.
