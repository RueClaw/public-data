# ThreeUI Community (MengTo/threeui)

**Repo:** https://github.com/MengTo/threeui
**License:** MIT application/component code and ThreeUI-authored bundled imagery; OFL-1.1 fonts; external media and trademarks have separate rights.
**Reviewed:** 2026-10-31 (UTC)
**Revision:** 68802d5428071ada5c20db8094b1649e6bb770ed — public repository root, catalog, representative renderers, packaging, CLI, tests and CI.
**Verification:** Static source review only; no installs, builds, tests, browser rendering, vulnerability audit, login or paid calls performed for this refresh.
**Stack:** TypeScript, React, Three.js, raw WebGL, Canvas 2D, HTML iframe scenes, Vite, Node.js CLI.
**What it is:** A login-free Community catalog and reusable React package of authored visual effects and interactive scenes, not a general-purpose accessible design system or an AI UI generator.

## Verdict

⚠️ **Interesting — selectively adopt visual components, not the whole catalog as a production baseline.** The source/export pipeline and public-versus-Pro boundary checks are genuinely useful. However, heterogeneous renderers, inconsistent motion/lifecycle handling, remote asset dependencies and installer trust gaps require per-component qualification. Use it for prototypes and carefully tested marketing sections; keep critical navigation, forms and product semantics in a conventional UI system.

## Update Notes

This replaces the 2026-08-26 review in place. That review reported package 1.1.0 and successful local build/audit checks but recorded no exact source SHA, so a reliable commit-to-commit comparison is unavailable. The current manifest is 1.2.0, the sync report is dated 2026-08-31, and this refresh adds revision-pinned evidence, renderer/accessibility and CLI boundary analysis, closer alternatives, and a standalone page. Prior build/audit results are historical, not current validation. The rating is narrowed from Deploy candidate to Interesting on the evidence below.

## What It Is

ThreeUI Community is the public slice of Meng To’s ThreeUI product. It provides a browse/search application, variant controls, live previews, source-code tabs and copy-oriented implementation guides. The npm package is `@designcodeio/threeui`; the optional Pro downloader is a separate `@designcodeio/threeui-cli` package. Pro source and the entitlement backend are not part of the public Community library.

A generated catalog connects metadata to renderers and package exports. Some components are ordinary React hosts around graphics engines; others embed complete authored HTML documents. This preserves scenes faithfully but makes styling, accessibility, loading and integration less uniform than a traditional component toolkit.

The current [sync report][report] records **43 Community parents, 104 routes and 163 variant records**, excluding 108 Pro and 23 Beta parents. The README still says 50 parents/111 routes and a different variant summary. Prefer the report for this snapshot; neither number independently proves completeness against the unavailable private source.

## Stack

| Layer | Technology / boundary |
|---|---|
| Catalog | React 19 development app, TypeScript, CSS, custom browser routing |
| Consumer package | ESM, declarations, CSS/assets exports, component subpaths; React 18–19 peer range |
| Graphics | Three.js peer plus aliased Three.js 0.128 and 0.165 dependencies; raw WebGL and Canvas 2D |
| Build | Vite 7, TypeScript 5.9, npm lockfile; Node 24 in CI |
| Backend | Generated catalog/source JSON; no Community database/account backend required |
| Optional Pro | Node CLI, browser OAuth PKCE, hosted entitlement API and downloaded source files |

## Key Features

### Source and package distribution

[package.json][package] exports ESM, types, shared CSS, assets and component subpaths. [The library config][lib] preserves modules and externalizes React and the Three.js variants. This provides a small-import path, but does not establish a measured bundle budget: multiple Three.js versions can coexist, and authored HTML/runtime assets add costs outside the JS import graph.

### Public subset validation

[Boundary tests][tests] compare catalog/report counts, check variant/control parity, validate source bundle hashes, exclude paid entries and inspect runtime documents. Release tests cover semver classification; CLI tests exercise PKCE, path rejection, auth persistence, byte-preserving downloads and overwrite refusal. This is stronger packaging evidence than a screenshots-only collection, but self-consistency with a generated report is not proof of renderer correctness or private-tree completeness. See the existing [public subset pattern](../patterns/public-subset-boundary-audit.md).

### Heterogeneous rendering

[WovenCloth][cloth] uses titled, `allow-scripts`-only sandboxed `srcDoc` iframes for companion variants. This avoids granting parent same-origin privileges. It is not an offline or no-network boundary: scene code can still fetch libraries/assets, and restrictive CSP/CORS policies may break individual scenes.

[WarpFieldBackground][warp] instead owns a canvas renderer, resize/intersection observers and an animation loop, disposing resources on unmount. Its [renderer][renderer] caps DPR at 2, shares some geometry/materials and explicitly disposes textures and layers. Those are concrete engineering positives, not a library-wide FPS or memory guarantee.

## Architecture

The main flow is `src/main.tsx → App.tsx → catalog/docs → selected renderer`. Generated `src/data/shaders.tsx`, `src/index.ts` and `src/package-components/` connect the catalog to package entry points. `public/source-code.json` supplies the code tab. Synchronization from a separately held upstream snapshot filters access tiers and copies public source/assets; consumers do not need that private snapshot to use the checked-in tree.

Site and library have separate Vite builds. A third surface, `packages/cli`, handles optional authenticated Pro downloads. Keep those trust domains separate: a login-free Community renderer does not require installing or authenticating that CLI.

## Rendering, Accessibility and Performance

- **Motion is component-specific.** Search preview videos respect reduced-motion preference and use buttons with descriptive labels. The sampled Warp Field host has no reduced-motion check, and its canvas has no explicit accessible description or decorative hiding. Supply semantic alternatives or mark truly decorative visuals appropriately.
- **A lifecycle edge needs testing.** Warp Field schedules its next frame only when intersecting and the document is visible. If a callback observes `document.hidden`, the loop stops, but the host has no `visibilitychange` restart listener. Returning to an unchanged viewport can therefore leave it paused until an intersection transition. This is static control-flow evidence, not a reproduced browser bug.
- **Timing is frame-dependent.** The sampled renderer advances elapsed time by 1/60 and position by a fixed step each render, rather than real delta time. Refresh rate can change apparent speed. It also captures variant at construction while the React effect has no dependencies; changing the variant prop without remounting does not rebuild the chosen scene.
- **Modal semantics are incomplete evidence.** [SearchDialog][search] declares dialog/aria-modal, initially focuses the input, supports Escape there and labels results. No focus trap or focus restoration is implemented in that component, and the input has placeholder text without an explicit label. No screen-reader or keyboard traversal audit was run.
- **Do not generalize visual polish into platform support.** WebGL, observer APIs, GPU limits, root-relative assets, iframe origin rules and client execution matter. SSR/framework integration, context-loss recovery, touch behavior, low-end mobile thermals, contrast and memory stability remain untested.

## Security, Privacy and Execution Boundaries

Community needs no model provider, API key or paid service. That does **not** mean zero outbound traffic: asset notices document ThreeUI-hosted previews/media and public CDN resources. A self-hosted copy still needs a per-scene request inventory and licensing/CSP decisions. The hosted service/backend was not audited.

The optional [OAuth implementation][oauth] uses random state and S256 PKCE, a loopback browser callback, atomic auth-file replacement and owner-only modes when creating files/directories. Refreshable bearer credentials live in a local JSON file, not an OS credential vault. Server-side entitlement enforcement is a README claim outside this public tree’s verification scope.

The [installer][install] rejects absolute/traversal paths and duplicates, and refuses changed-file overwrites unless forced. **Containment is lexical, not filesystem-real:** it does not resolve/reject symlink ancestors before mkdir/writeFile. A pre-existing linked directory can redirect writes outside the intended destination. This is a static risk, not a tested exploit. Use a fresh trusted destination; add real-path/no-follow safeguards before accepting hostile bundles or working trees. Writes are sequential rather than transactional, and remote bundles have no explicit size budget or independent signature check here.

The [CLI entry point][cli] allows development API/metadata overrides without an HTTPS/origin allowlist. An existing valid session can be reused while the API endpoint is overridden; an untrusted command line can therefore redirect an authenticated download request. Treat those flags as credential-routing authority. Downloaded source is not automatically installed/executed by this installer, but becomes executable when incorporated into a project. The CLI can launch a system browser; none of it was run for this review.

The public audit is a useful heuristic, not a security scanner. Its [text-extension allowlist][audit] omits .ts/.tsx, so sensitive-assignment scanning does not cover the primary TypeScript files. Build auditing checks selected signatures and source maps, not arbitrary secrets or hostile logic. No fresh dependency vulnerability assessment was performed; the old review’s clean audit is not today’s result.

## Tests, CI and Maturity

[CI][ci] declares clean install, tests/typecheck/site and library builds, audits and anonymous package-install smoke checks on Linux/Node 24. npm publishing uses provenance/OIDC and an environment, but is a separate workflow; public configuration alone does not prove publishing waits for every verification job. Actions are version-tagged, not immutable SHA-pinned. The inspected tests emphasize packaging/boundary/release/CLI behavior, not automated browser accessibility or rendering benchmarks.

GitHub’s public API on 2026-10-31 reported 6,977 stars, 657 forks, eight open items (issues plus pull requests), creation on 2026-08-21 and last repository push on 2026-09-03. The reviewed commit is dated 2026-09-01 UTC. The releases endpoint returned no GitHub Releases. These are activity/popularity snapshots, not reliability evidence.

[Issue #43](https://github.com/MengTo/threeui/issues/43) reports unsupported static routes falling through to the first shader. App.tsx maps only pricing/oauth-consent to not-found before casting other page values; this supports the reported coverage concern, but routes were not exercised. [PR #42](https://github.com/MengTo/threeui/pull/42) concerns sandboxed Sylva font loading; the latest returned PR CI run [failed](https://github.com/MengTo/threeui/actions/runs/35340205232). That does not establish that reviewed main fails; main CI status and failure cause were not independently established.

## Comparison

| Option | Best fit | Tradeoff relative to ThreeUI |
|---|---|---|
| [React Bits](https://github.com/DavidHDev/react-bits) | Browse/copy animated React effects | Closer effect-library alternative; compare exact component dependencies and licensing |
| [React Three Fiber](https://github.com/pmndrs/react-three-fiber) and [Drei](https://github.com/pmndrs/drei) | Compose custom Three.js scenes | More control and coherent React graphics APIs; more authoring than a finished specimen |
| [Radix Primitives](https://github.com/radix-ui/primitives) | Accessible product UI interactions | Better category fit for dialogs/menus/controls, not shader backgrounds |

These are architectural alternatives, not fresh benchmark/security comparisons. A useful combination is conventional accessible primitives plus one qualified decorative ThreeUI effect.

## Self-Hosting Notes

Use locked dependencies and a supported Node version when validating later; this review installed nothing. The site is a static Vite app with `base: "/"`, root-relative assets and browser routing. Configure SPA deep-link fallback deliberately; do not assume arbitrary subdirectory hosting works unchanged. Package consumers need shared CSS, a sized parent and any required runtime documents at the documented public paths or supported URL overrides.

Before production adoption: qualify the selected renderer on target devices; add reduced-motion/semantic fallback; test hidden-tab resume and unmount; inventory requests; measure loaded assets/frame time/memory; audit dependencies; validate routes and CSP; avoid Pro CLI unless needed. A selected effect is a reasonable pilot; wholesale production endorsement is unsupported by this static review.

## Verification and Limits

Confirmed by reading the exact public checkout: identity/version, manifests/licenses, source/export layout, report counts, representative renderers, CLI auth/write paths, audit coverage and declared tests/workflows. Public API acquisition and Git revision inspection succeeded. **No repository code, tests, builds, install hooks or graphics demos were executed.** No current FPS, bundle-size, vulnerability-free, accessibility-conformance, platform-compatibility or server-entitlement claim is made. The private upstream was not acquired; an older review without a SHA cannot establish precise source deltas.

## Evidence

All source links below are pinned to the reviewed revision.

[package]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/package.json
[report]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/public/community-sync-report.json
[lib]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/vite.lib.config.js
[tests]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/scripts/public-boundary.test.mjs
[cloth]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/src/shaders/woven-cloth/WovenCloth.tsx
[warp]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/src/shaders/warp-field/WarpFieldBackground.tsx
[renderer]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/src/shaders/warp-field/warpFieldRenderer.ts
[search]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/src/components/SearchDialog.tsx
[oauth]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/packages/cli/src/oauth.mjs
[install]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/packages/cli/src/install.mjs
[cli]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/packages/cli/src/index.mjs
[audit]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/scripts/audit-public.mjs
[ci]: https://github.com/MengTo/threeui/blob/68802d5428071ada5c20db8094b1649e6bb770ed/.github/workflows/ci.yml

**Attribution:** Meng To / MengTo/threeui. MIT notices must accompany substantial copied code. Preserve bundled OFL font and Three.js MIT notices. External ThreeUI catalog media is not granted this repository’s MIT license; brand imagery does not confer trademark rights.
