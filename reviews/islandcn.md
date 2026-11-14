# islandcn (opencoredev/islandcn)

**Repo:** https://github.com/opencoredev/islandcn
**License:** MIT, copyright 2026 Leo; preserve the notice. Bundled font and dependency terms apply separately; Apple trademarks are not licensed by MIT.
**Reviewed:** 2026-11-14 (UTC)
**Revision:** 0011a41ea4882f3818caf35c98f3ee46b80c4a2c (main); engine, presets, playground, registry/build scripts, site routes, documentation and tests.
**Verification:** Static source review only. No installation, build, test execution, browser/device interaction, or live endpoint/security probes.
**Stack:** TypeScript, React 19/React DOM, custom SVG/spring renderer; Next.js 16.4.1 and Blume for the demonstration/documentation site; shadcn source registry.
**What it is:** An in-page Dynamic Island-style activity display for React applications—not a desktop shell, native iOS Live Activities integration, recorder, upload service, or AI agent runtime.

## Verdict

⚠️ **Interesting — a serious motion component worth a bounded React pilot, not yet an accessibility-verified drop-in.** The strongest work is the separation of activity state from deterministic spring geometry, plus editable source distribution and thoughtful keyboard/reduced-motion provisions. The public repository is less than a day old at review time, has no checked-in CI workflow, and does not include the reference recordings needed to verify its visual-fidelity claims. Assistive-technology activation and hostile share-link resource bounds deserve explicit fixes or acceptance testing before broad use.

## What It Is

islandcn places a black pill at the top of a page or positioned container. Activities supply compact, minimal and expanded React content; the engine selects idle, single-activity, split and expanded presentations. Priorities select the foreground activities, while groups allow several activities from one source to take turns. Upload, timer, music, incoming-call, ETA, recording, nearby-transfer and battery presets demonstrate the UI vocabulary.

Those names describe presentation, not service integrations. The reviewed engine/presets do not implement microphone capture, telephony, transport, background upload execution, or an OS-level island. The embedding app supplies real state, media permissions and callbacks. A playground edits activities and motion, exports code, and serializes designs into shareable URLs. An optional coding-agent skill teaches installation and composition; it is not an embedded model or paid provider integration. [README](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/README.md), [recording preset](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/components/islandcn/recording-activity.tsx)

## Stack

| Layer | Technology and boundary |
|---|---|
| Installed engine | React 19 and React DOM; no additional animation dependency |
| Rendering | SVG paths, custom geometry, analytic springs, direct DOM frame writes |
| Content kit | React components; Hugeicons packages for glyphs |
| Demo/docs | Next.js 16.4.1, Tailwind 4, Blume 2.2.7, Fumadocs negotiation |
| Distribution | shadcn registry copies source into the consumer project |
| State | In-memory activity store; playground URL serialization; no activity database |

“React only” is a fair shorthand for the animation engine, not the entire repository or content kit. React 19 is material: the provider uses the newer context-provider form. The agent skill first says the content kit adds no packages, then correctly explains its Hugeicons dependencies; the registry/manifests are the more reliable dependency inventory. [Manifest](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/package.json), [skill](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/skills/islandcn/SKILL.md), [registry](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/registry/presets.json)

## Key Features and Architecture

### Activity state is separate from rendering


actions → in-memory store → derived scene → measured geometry/choreography → SVG and content layers

The store exposes start/update/end/expand/collapse, stable handles and subscriptions. Reusing an ID updates rather than duplicates an activity. Priority sorting is stable by start order; group handoffs have explicit timers, and delayed alert content has cancellation/flush paths. React consumers use useSyncExternalStore; useIslandActions avoids unnecessary consumer subscriptions. This is more substantial than a CSS morph demo. [Store](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/store.ts), [hooks](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/use-island.ts)

### Motion is interruptible and inspectable

Closed-form spring evaluation and per-transition choreography let shape targets change mid-flight instead of restarting an unrelated CSS animation. A controllable frame clock supports pause, step and seek for captures; the optional window devtools object is off by default. SVG pill/bubble/neck geometry and separate entering/leaving content layers produce the characteristic split and merge effects. Frame work writes DOM properties without requiring a React rerender for every frame. The main surface is nevertheless 2,296 lines, a significant maintenance and regression surface for copied source. [Spring solver](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/spring.ts), [choreography](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/choreography.ts), [surface](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/surface.tsx), [clock](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/clock.ts)

### Source ownership is useful, but updates are your work

Registry generation checks imports against site-only modules and verifies declared registry/npm dependencies. The core item ships engine files rather than requiring the Next.js site. Presets use a lifecycle hook that starts after hydration, updates from dependencies and ends on unmount. This supports ordinary React apps, including a documented Vite path, but the code is DOM-oriented—not React Native or non-React UI. [Registry builder](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/scripts/build-registry.ts), [engine item](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/registry/engine.json), [lifecycle hook](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/components/islandcn/use-activity.ts)

## Accessibility and Platform Compatibility

There is real accessibility work: a named region, native button hit targets, activity labels, polite live announcements, Enter/Space expansion, Escape/outside collapse, focus restoration when content disappears, visible focus outlines, and inert/aria-hidden outgoing layers. Reduced motion follows the system by default, replacing overshoot/blur/scale with gentler transitions. This is not the same as “no animation”: the documented reduced-motion shape transition still eases over 0.2 seconds. [Root interactions](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/island-root.tsx), [layers](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/layer.tsx), [engine guide](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/README.md)

**A concrete activation gap:** the pill/bubble buttons wire pointer handlers and onKeyDown, but no onClick. Enter/Space is manually handled; an assistive technology that activates a native button by dispatching a click without those input events has no corresponding activation handler. This is a static code finding, not a reproduced VoiceOver/NVDA failure. Add and test semantic activation without double-triggering the pointer path. The detached bubble also lacks the pill's aria-expanded attribute. Test full keyboard traversal, focus after activity replacement, screen-reader activation and live-region verbosity with real application content. [Surface interaction code](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/surface.tsx#L2084-L2088), [buttons](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/surface.tsx#L2205-L2238)

Browser-specific code detects Apple WebKit to adjust filter compositing and shadows. Comments report Safari improvements, not independently verified cross-browser benchmarks. The engine depends on browser DOM/SVG, ResizeObserver, animation frames and modern focus/inert behavior. Test Safari, Chromium and Firefox, touch long-press, narrow layouts, zoom, text resizing and reduced motion; phone-width clamps and clipped compact slots can hide long or localized labels. This review does not certify WCAG conformance, mobile frame rate or older-browser support. [Platform workaround](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/platform.ts)

## Security, Privacy and Authority Boundaries

- **Engine authority:** ordinary same-page React code. No network client, credential store, model provider, account login or privileged OS service was found in the reviewed engine/presets. App-provided React nodes and callbacks are trusted executable code, not sandboxed content. A “Pay” or “Approve” button still needs application-side authorization and server validation; the UI is not an approval security boundary.
- **Install authority:** the README's npx shadcn@latest command executes a moving CLI and retrieves a mutable hosted registry that writes project files. Review/pin the CLI and source snapshot, inspect the generated files/dependencies, and commit a baseline before installing. The reviewed Git SHA is not proof that the current hosted registry bytes match it. The optional skill also writes instructions into both .agents/skills and .claude/skills; install only intentionally. [Skill item](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/registry/skill.json)
- **Share-link parsing:** fields are reconstructed through allowlisted kinds, icons, actions and sample-photo names, with text and numeric limits; sample-photo inputs are not arbitrary remote URLs. This is good defense against treating a URL as executable UI configuration. But the claimed 64 KiB inflated-JSON guard is checked only after Response.arrayBuffer has fully materialized the decompressed stream. Plain base64 JSON has no equivalent total-size cap. Bound encoded input and enforce a streaming decompression limit before allocation; otherwise crafted links may consume excessive browser memory/CPU. This is a static resource-exhaustion concern, not a demonstrated exploit. [URL parser](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/components/site/playground/url-state.ts)
- **Sharing is not secrecy:** the design lives in the query string, compressed/encoded, not encrypted. It can be copied, retained in history and received/logged by the hosting server when opened. Do not include credentials, private transcript text or real customer data. The component does not introduce a cloud sync account, but the URL is deliberately transferable.
- **Development routes:** frame/fidelity endpoints read reference/capture files and are enabled outside production, or with ISLANDCN_DEV_TOOLS=1. They validate root names, slugs and frame filenames and normally return 404 in production. They do not authenticate callers; do not expose a development/capture server. Filename checks are not a realpath/symlink confinement policy, so keep configured roots trusted. Build tracing excludes references, captures and env files as an additional packaging precaution, not an authentication substitute. [Route policy](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/app/api/dev/dirs.ts), [frame reader](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/app/api/dev/frames/%5Broot%5D/%5Bname%5D/%5Bfile%5D/route.ts), [Next configuration](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/next.config.mjs)

No paid inference, provider OAuth or API keys are required by the component. Hosting, development and optional external coding-agent costs are separate and user-selected. No live hosting privacy behavior or dependency vulnerability audit was verified.

## Persistence, Recovery and Operational Fit

The activity store is ephemeral. Reloading/remounting does not resume an upload, timer or recording from a journal. The application must reconstruct UI from authoritative job state and distinguish “hide/end this indicator” from “cancel the actual operation.” Group-hidden activities remain in the store; more activity state does not imply every task stays visible. Declarative presets clean up their own activity on unmount; imperative users own their handle lifecycle.

Store reset clears alert/press and pending-content timers. Surface observers/subscriptions have cleanup, and the frame clock stops scheduling when it has neither listeners nor timers. These are useful local lifecycle measures, not crash recovery, durable background work or guaranteed timer delivery in throttled tabs. Use wall-clock/server deadlines for consequential timing. [Store](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/store.ts), [clock](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/clock.ts), [provider](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/lib/island/provider.tsx)

Source-copy updates can overwrite local edits. A regression test specifically guards a prior shadcn --overwrite import-resolution problem. Track upstream patches and review a three-way diff; rollback with project version control rather than assuming a package uninstall restores modified source. [Regression test](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/tests/engine-files.test.ts)

## Build, Tests, Maturity and Claims

The manifest is private version 0.1.0 with a pnpm lockfile and pnpm 11.28.7 selection. Build runs registry generation, a Blume docs build, then Next; it is not needed merely to consume already-reviewed core source. Build scripts execute local tooling and replace generated docs/registry output. Workspace policy permits esbuild/sharp build steps, uses copied package imports, and overrides two transitive dependency versions. These are positive supply-chain measures, not evidence that all dependencies are vulnerability-free. [Workspace policy](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/pnpm-workspace.yaml), [docs builder](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/scripts/build-docs.ts)

Fourteen checked-in test files cover share-link compatibility/validation, generated code, playground behavior, docs snippets, labels, keylines and registry naming. Some checks skip without a production build or generated registry; the reference-measurement check skips because the recordings/data are not public. No .github workflow directory was present at this revision. Tests were inspected, not run: there is no claimed passing count, typecheck or build result in this review. The public suite is not evidence of comprehensive browser interaction, accessibility, store-state-machine or visual regression coverage. [Tests](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/tests), [reference notice](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/reference/README.md)

The engine guide contains highly specific simulator-fitting numbers, but the referenced recordings and fidelity tooling are not included as a reproducible public measurement bundle. Treat “fitted to the real island” as upstream provenance/engineering claims; the mathematics and parameter tables are inspectable, the underlying fidelity result is not independently reproduced here.

Public GitHub metadata checked 2026-11-14: repository created 2026-11-13, latest push 2026-11-13T15:14:36Z, 390 stars, 38 forks, zero open issues, and no releases returned by the releases API. The reviewed commit updates Next and transitive dependency overrides. These are a snapshot of launch activity, not reliability or security scores. A shallow clone does not establish the complete development history. [Public metadata](https://api.github.com/repos/opencoredev/islandcn)

## License and Assets

The root MIT license permits reuse/modification/distribution with its copyright and permission notice. The README says no Apple assets are copied and explicitly disclaims affiliation; that statement does not grant Apple's trademarks or settle look-and-feel rights for a product. The bundled Geist font directory includes OFL terms; fonts and Hugeicons dependencies retain their applicable notices. Sample photos/covers exist, but this review did not independently establish their individual provenance. Prefer your own product imagery rather than assuming the root code license clears every depicted subject or brand. No source/assets were extracted into this review. [License](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/LICENSE), [font license](https://github.com/opencoredev/islandcn/blob/0011a41ea4882f3818caf35c98f3ee46b80c4a2c/app/og/fonts/OFL.txt)

## Comparison

| Option | Best fit | Tradeoff |
|---|---|---|
| islandcn | Continuous compact/split/expanded task status with a particular Apple-like motion language | Strong specialized geometry; copied-source maintenance and unverified assistive activation |
| Sonner or Radix Toast | Conventional transient notifications and actions | Simpler notification model; no equivalent measured island choreography |
| Motion for React plus application components | Bespoke animated status surfaces | Broader animation tooling; you own activity selection, accessibility and layout |
| Native Apple ActivityKit | Actual iOS Live Activities and system Dynamic Island | Native platform entitlements/lifecycle; not a portable DOM component |

These are architectural alternatives, not head-to-head performance or accessibility test results. If you only need upload progress, an inline status and accessible progress element may be simpler than any global floating surface.

## Adoption / Self-Hosting Notes

For a pilot, take a reviewed source snapshot into a disposable React 19 project, use only required registry items, and keep the optional agent skill separate. Connect one non-sensitive task, then test cancellation versus dismissal, background-tab recovery, multiple activity priorities, pointer/keyboard/assistive activation and reduced motion. Fix bounded share decoding before accepting untrusted playground links in a sensitive environment.

You do not need to host the upstream demo to embed the component. If hosting that site, use a production build, keep dev/capture tooling disabled, do not mount private capture roots, and establish ordinary dependency updates, logging/privacy controls and security headers. No deployment was performed here.

**Bottom line:** technically interesting, unusually detailed motion work with useful source ownership. Adopt selectively as UI, not as a durable activity system or a substitute for tested accessibility and authorization.

---
**Attribution:** opencoredev/islandcn; MIT, copyright 2026 Leo. Independent static analysis of the pinned public revision.
