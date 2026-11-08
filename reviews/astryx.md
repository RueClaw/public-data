# Astryx (meta/astryx)

**Repo:** https://github.com/meta/astryx
**Author / owner:** Meta Open Source / meta; LICENSE names Meta Platforms, Inc. This attribution is supported by package manifests, the copyright notice, and the verified organization profile—not inferred from the repository name.
**License:** MIT; retain copyright and permission notices in redistributed copies or substantial portions. Dependencies retain their own licenses.
**Reviewed:** 2026-11-08 (UTC)
**Revision:** 4e4c12a9dd528d879b684ea7838ed2522c9cbc75; main snapshot, committed 2026-11-08T17:43:30Z. Scope: root metadata, core component/theme/navigation implementations, CLI API and filesystem/module-loading/release/agent-doc/upgrade boundaries, manifests, representative tests and workflows. Not an exhaustive audit of all packages.
**Verification:** Static review only. No installation, source execution, tests, build, model calls, or device access. Test files and workflow definitions were inspected, not verified passing.
**Stack:** TypeScript/React 19+, StyleX, prebuilt CSS; Node.js ESM CLI, Commander, Zod, jiti, Babel/jscodeshift; pnpm monorepo, Vitest and Playwright.
**What it is:** A customizable React web design system with components, themes, templates, and developer/agent-facing documentation and code-modification tooling. It is not an autonomous-agent runtime or model.

## Verdict

⚠️ **Interesting — pilot the UI library; treat the CLI as trusted development tooling, not a read-only documentation viewer.** The component/theme system and machine-readable CLI API are substantial, coherent implementations. Public beta status, React 19 requirements, a large migration surface, executable project extensions, and global-mode background writes/downloads warrant a pinned, project-local trial before broad adoption.

## What It Is

Astryx targets teams building branded React applications, including teams whose coding assistants need dependable component documentation and reusable templates. The README advertises 150+ accessible components, seven themes, source ejection ("swizzle"), and APIs equally usable by humans and agents. Actual packages and exported APIs substantiate the broad shape; component counts, accessibility across all combinations, and agent productivity were not independently measured. [1][2][3]

The README says the system grew inside Meta over eight years and powers 13,000+ applications. Those are upstream adoption claims, not independently verified production evidence. Public identity is considerably better grounded: the MIT notice names Meta Platforms, Inc.; manifests name Meta Open Source; GitHub identifies the verified organization and links its open-source site. [1][2][4]

"Agent ready" means discoverable documentation, typed response envelopes, templates, upgrade receipts, and generated agent instructions. It does not supply an LLM, an isolation boundary, an agent permission broker, or hosted inference. The application remains responsible for its backend, auth, data handling, and business logic.

## Stack

| Layer | Technology and implications |
|---|---|
| UI | React and react-dom >=19; core peer-depends on StyleX ^0.19.0, with intl-messageformat as a direct dependency |
| Styling | StyleX authoring, published CSS, CSS custom properties, scoped component overrides, light/dark modes |
| Tooling | Node >=22.13.0 CLI; Commander, Zod, jiti, Babel, jscodeshift/recast, PostCSS, node-diff3 |
| Workspace | pnpm 11.10.0 pin, lockfile, shared dependency catalog and security/version overrides |
| Tests | Vitest UI/perf/node projects; Playwright accessibility and interaction suites; Storybook |
| Persistence | Generated project files and agent docs; CLI user settings/state/release cache; optional resizable UI state in localStorage |
| Backend/auth | No required server/database/auth service for the core library; consuming applications provide these |

The reviewed main manifests say 0.7.12, while the latest GitHub release returned at inspection was v0.7.11, published 2026-11-07. Do not equate a main package version with a published npm release. [2][5]

## Key Features

### Cohesive theming without requiring consumers to build StyleX

Core exports typed components and CSS entry points. The Theme component applies tokens, handles nested themes, and synchronizes root HTML attributes so portals and native browser color schemes match. Component overrides use stable target classes and reflected state/prop attributes. Button combines typography/color/motion tokens, interaction and focus helpers, i18n, group contexts, touch targets, and router integration: this is a full design system, not a collection of lightly styled snippets. [2][6]

The ordinary consumption path uses prebuilt CSS; source-level builds and deeper ejection have additional toolchain responsibilities. Modern CSS features such as light-dark() and @scope, hydration behavior, reduced-motion handling, and your actual browser matrix deserve a compatibility pilot. Non-Gregorian calendar documentation also calls out Temporal/polyfill and server/browser date-data differences. No browser certification was performed. [1][6][7]

### One typed content surface for people and tools

The CLI API exports component/docs/search/template/theme/swizzle/upgrade/doctor operations with structured type/data receipts and AstryxError failures. Its host entry is a programmatic CLI entry, not an HTTP server: it can own process cwd, arguments, streams, and process exit. Do not embed it in a shared application server assuming library-like isolation. [3][8]

### Source ownership and migration support

Swizzle copies component source; upgrade coordinates core and integration codemods, registry compositions, hooks, and agent-document refresh. This is useful ownership tooling, but copied components become your maintenance responsibility. Upgrade defaults to a dry-run path unless apply is selected; a failed apply can leave already-modified files, explicitly covered by a failure-receipt test. A receipt is not rollback. Use a clean VCS checkpoint and inspect the diff. [9]

## Architecture

The monorepo separates packages/core, packages/cli, optional build adapters, theme packages, and apps such as the docsite and Storybook. README distinguishes unpublished lab components and canary-only chart/Vega packages from the regular library. The CLI separates clients, an API operation layer, authoring schemas, foundation services, host integration, and packaged docs/templates/codemods. [1][3]

The most reusable architectural idea is shared structured operation results for terminal and programmatic consumers, coupled to docs and migration receipts. The important qualification is that schema validation does not precede all execution: project module loading imports JavaScript or runs TypeScript through jiti first, then parses the default export. This is extensibility under trust, not safe parsing of arbitrary repositories. [10]

## Security, Permissions, and Privacy

### UI boundary

Core's shared navigation policy normalizes control characters and blocks javascript:, vbscript:, and data:text/html; Markdown uses additional resource/link filtering. Tests exercise dangerous URL inputs and custom routing. These are real defenses, not proof of universal XSS safety: custom rendering, plugins, resources, application-supplied data, authorization, CSP, and backend endpoints remain outside that guarantee. No blanket "safe for untrusted content" claim is justified. [11]

Core does not require model credentials or administrator/device permissions. Its browser components run with the consuming page's privileges. Resizable/SideNav persistence can write layout state to localStorage when configured; this is not an application database or cross-device recovery service. [12]

### CLI execution and credential boundary

Config, integrations, templates, and codemods may be executable modules, imported in the CLI process. They inherit its ordinary user filesystem/environment access; Zod validates their exports after execution. A nominally informational operation that loads project extensions must not be assumed safe in an untrusted checkout. No OS sandbox or per-tool approval layer was established in this path. [10]

Global release selection can invoke npm and execute another installed CLI release. Cached installs disable lifecycle scripts with --ignore-scripts, use fixed package names/version validation, bounded fetches, locks, temporary install directories, a version check, and a completion marker. These reduce accidents but do not make downloaded package code harmless: the CLI is then executed. npm's registry/proxy/offline configuration applies, and ordinary subprocess inheritance means existing package-manager credentials/configuration are part of the trust boundary. [13]

### Global installation has ongoing side effects

The global CLI's startRun path schedules update checks, computer-level agent-text maintenance, and optional Core-cache fetching. Agent-text settings default to install when absent; a detached worker writes/links Astryx skill instructions into supported agent locations. This is broader than project scaffolding. It attempts to preserve edited/unmarked files and supports removal through init --user --remove-agents. Prefer project-local use until these effects are deliberately accepted. [14]

CI or NO_UPDATE_NOTIFIER suppresses update checks/notices. It is **not** a universal offline switch or a guarantee against agent-text writes/cache fetching: those are separate paths. Hosted execution skips global background work and cache installation in that handoff path, but still executes authorized CLI/project functionality. [8][14]

### Network and public reporting

Blog commands fetch the public Astryx site, with a 15-second timeout, 5 MB cap, and canonical-origin validation of feed-provided post URLs. However fetch uses redirect: follow, so the initial-origin check alone is not a final-hop egress allowlist. This is a boundary caveat from static code, not a demonstrated exploit. Optional generated font instructions reference Google Fonts; choosing those assets has third-party request/privacy implications. [15]

Gap reports can invoke the authenticated gh CLI to create public issues. The GitHub fallback and public handlers require confirmPublic; inspect report content and destination before opting in. Debug code contains redaction helpers, but this review did not establish exhaustive secret scrubbing. No universal absence-of-telemetry or zero-network claim is made across all apps, integrations, and build tooling. [16]

### File protection is not a hostile-filesystem sandbox

Path helpers reject traversal, unsafe names, and symlink escapes in normal resolution. assertWithin falls back to lexical validation on some non-PathSafetyError canonicalization failures, and path validation is distinct from atomic filesystem access. Do not use these helpers as a security boundary against concurrent hostile filesystem mutation. Create-only publication uses atomic hard links where available; the exclusive-copy fallback explicitly accepts a crash-truncation window. [17]

## Persistence and Recovery

- CLI settings and state are stored in platform user configuration directories; cached releases live in user cache directories. Completion markers, lock ownership, bounded retries, and temporary-directory rename publication avoid accepting half-installed releases. These are operational integrity checks, not independent package authenticity attestation. [13][14]
- Agent-text refresh tracks written versions and preserves user-edited/unowned files; opt-out is persisted. Review generated instructions as policy-affecting configuration, not merely documentation. [14]
- Upgrade can fail after partial edits; failure receipts identify changed files. Recovery should use the consuming project's VCS/backup, not an assumed transaction rollback. [9]
- UI localStorage persists only the opted-in layout information; ordinary application data, backups, and synchronization are the application's job. [12]

## Tests, CI, and Maturity

This is a substantial beta repository rather than a README-only launch. A filesystem inventory found 1,578 files matching *.test.* under packages (files, not executed test cases). Sampled suites cover malicious navigation values, filesystem safety, concurrent/no-clobber publication, module-output isolation, global release handling, and partial-upgrade failure receipts. Vitest separates UI, performance, and Node environments. [9][10][11][17][18]

CI defines PR/merge-queue checks, builds, accessibility/visual/RTL lanes, and release gating. Important nuance: not every heavy accessibility/visual job runs on every PR; some are scheduled/release checks or label opt-ins. The cross-platform global-CLI smoke workflow is manually dispatched and targets macOS, Windows, and Ubuntu. Workflow presence is not evidence that this exact SHA passed every lane. Current run conclusions and coverage percentages were not independently verified. [18]

Public GitHub metadata at retrieval reported 15,925 stars, 1,279 forks, and 683 open items in the API's open_issues_count (which includes pull requests), with a recent push at the reviewed commit time. These are activity/discovery signals, not safety or support guarantees. The README explicitly says Beta; latest release notes contain numerous accessibility, hydration, interaction, and migration fixes, so pinning and upgrade rehearsal are sensible. [4][5]

## Comparison

| Option | Prefer it when | Tradeoff versus Astryx |
|---|---|---|
| shadcn/ui + Radix | You want copy-owned components and a Tailwind-centered workflow | Greater local ownership; you assemble more of the design/migration conventions yourself |
| MUI | You want an established styled React ecosystem and Material-oriented components | More established ecosystem; Astryx emphasizes brand-level theming and a unified agent-facing CLI |
| React Aria Components | You want accessible behavior primitives with your own visual language | Less ready-made product styling; a clearer choice when behavior rather than a complete themed system is the priority |

These are architectural comparisons, not measured performance/accessibility rankings. Existing design systems should not be replaced merely to gain "agent readiness"; structured docs and templates may deliver much of that benefit without a migration.

## Self-Hosting Notes and Costs

There is no required Astryx backend to host. Ship the core library with an existing React web application. A normal developer computer is sufficient for UI/CLI work; no GPU, model download, mobile device, special accelerator, or inference account is required. No minimum RAM/storage benchmark was established; the full monorepo and browser/visual testing toolchain are substantially heavier than consuming prebuilt packages.

The MIT source has no license fee. Normal package-registry bandwidth, app hosting, CI, engineering/migration work, and any separately selected assistant/model usage remain your costs. The project's own CI mentions paid larger runners; that is not a consumer requirement. No paid service or model call was used for this review.

Practical pilot: choose a pinned published core/theme/CLI set, start project-local, build one real form/table/dialog workflow, test keyboard/screen-reader/touch behavior and target browsers, verify SSR/theme hydration, inspect generated files, and rehearse a migration on a disposable branch. Keep secrets out of untrusted project-module execution. Avoid global setup until its agent-text, cache, and network behavior is accepted explicitly.

## Verification Limits

No dependency installation, source/test execution, runtime/browser audit, npm-tarball equivalence check, vulnerability-database scan, bundle-size/performance benchmark, production deployment, or full dependency-license audit was performed. The README's adoption and accessibility claims remain upstream claims. This review is an implementation-grounded static assessment, not a security certification. Source continued evolving during review; all source citations below pin the inspected SHA.

## Evidence

1. [README and scope claims](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/README.md)
2. [Core manifest](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/core/package.json), [CLI manifest](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/package.json), [MIT LICENSE](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/LICENSE), [workspace catalog](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/pnpm-workspace.yaml)
3. [CLI API exports](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/api/index.mjs)
4. [Public repository metadata](https://api.github.com/repos/meta/astryx), [verified organization profile](https://api.github.com/orgs/meta), retrieved 2026-11-08 UTC; mutable metadata
5. [v0.7.11 release](https://github.com/meta/astryx/releases/tag/v0.7.11)
6. [Theme implementation](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/core/src/theme/Theme.tsx), [Button implementation](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/core/src/Button/Button.tsx)
7. [Calendar platform caveats](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/assets/docs/tree/calendar-systems.doc.mjs)
8. [Programmatic host](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/host/index.mjs)
9. [Upgrade pipeline](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/api/upgrade/run/run.mjs), [failure-receipt test](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/api/upgrade/run/failure-receipt.test.mjs)
10. [Executable module loading](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/foundation/fs/module-loader.mjs)
11. [Navigation sanitizer](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/core/src/utils/safeUrl.ts), [Markdown URL policy](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/core/src/Markdown/url.ts), [Markdown boundary tests](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/core/src/Markdown/Markdown.renderBoundary.test.tsx)
12. [Resizable persistence](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/core/src/Resizable/resizableModel.ts)
13. [Release installation/cache](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/foundation/release/cache.mjs)
14. [Global handoff](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/foundation/release/handoff.mjs), [state/background work](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/foundation/release/global-state.mjs), [default agent-text settings](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/foundation/env/user-settings.mjs), [agent-text writer](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/foundation/agent-docs/computer-agent-text.mjs), [update opt-out scope](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/foundation/release/update-notice-env.mjs)
15. [Blog fetch adapter](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/api/blog/_adapter.mjs), [optional font guidance](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/api/theme/build/font-warning.mjs)
16. [Public gap-report delivery](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/api/gap-report/gap-report.mjs), [debug redaction](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/foundation/debug/redact.mjs)
17. [Path checks](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/foundation/fs/path-safety.mjs), [create-only file publication](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/packages/cli/foundation/fs/publish-file.mjs)
18. [Vitest configuration](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/vitest.config.ts), [CI](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/.github/workflows/ci.yml), [manual cross-platform CLI smoke workflow](https://github.com/meta/astryx/blob/4e4c12a9dd528d879b684ea7838ed2522c9cbc75/.github/workflows/cli-global-mode-smoke.yml)

---

**Attribution:** meta/astryx, Meta Open Source; copyright Meta Platforms, Inc.; MIT. Analysis only; no upstream implementation copied into this review.
