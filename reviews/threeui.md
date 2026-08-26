# ThreeUI Community (MengTo/threeui)

**Repo:** https://github.com/MengTo/threeui
**License:** MIT for application code, Community component code, and ThreeUI-authored Community imagery; bundled fonts remain OFL-1.1; bundled Three.js runtime remains MIT
**Reviewed:** 2026-08-26
**Stack:** TypeScript, React, Three.js, Vite, raw WebGL, HTML iframe renderers, Node test runner, npm package publishing
**What it is:** Open-source Community edition of a polished interactive UI component catalog, with React package exports, complete component source, required assets, live docs, and a separate authenticated CLI path for Pro source installs.

---

## Verdict

✅ **Deploy candidate for visual prototypes and Three.js-heavy UI sections.** ThreeUI is not a generic design system; it is a curated library of high-polish animated components, shader backgrounds, landing-page frames, buttons, text effects, and UI specimens. The repo is fresh but impressively packaged: the build passed locally, npm audit is clean, and the Community/Pro boundary has real automated checks.

---

## What It Is

ThreeUI Community is the open-source, login-free slice of ThreeUI. It ships the public web catalog, a published React package (`@designcodeio/threeui`), complete Community component source, required assets, source-code data for the in-site code tab, and static runtime documents for some iframe-hosted effects.

The project is explicitly split from a private main repository. A sync script copies the shared shell, filters Pro and Beta surfaces, rewrites media URLs, removes restricted font assets, generates the Community catalog, and writes a sync report. The public repo then proves that boundary through tests and build audits.

The result is useful when the goal is an eye-catching WebGL/CSS/HTML effect quickly, not when the goal is a quiet enterprise app shell. Some components are full-page authored scenes; others are smaller CTAs, buttons, brand marks, loaders, backgrounds, typography effects, and interactive studies.

## Stack

| Layer | Tech |
|-------|------|
| Frontend | React 19 dev app, React 18-19 peer range for package consumers |
| Graphics | Three.js, raw WebGL, Canvas 2D, iframe-hosted authored HTML |
| Build | Vite 7, TypeScript 5.9 |
| Package | Public ESM npm package with component subpath exports and CSS/assets export |
| Tests | Node test runner, Vite SSR loading inside boundary tests |
| Release | GitHub Actions, npm trusted publishing with provenance |
| CLI | Node 20+ OAuth PKCE installer for entitled Pro component source |

## Key Features

### Community Component Package

The root package publishes `@designcodeio/threeui` with ESM entry points, type declarations, shared CSS, asset exports, and per-component subpath imports. The generated `src/index.ts` exports 100+ component entry points derived from the Community catalog.

### Boundary-Audited Public Edition

The strongest engineering work is the public/private split. Tests assert that Pro/Beta components are absent, Community variants and controls match the sync report, public source hashes match, restricted fonts are removed, auth/checkout runtime is absent, and build output has no source maps, private paths, auth runtime, commerce runtime, or private-host links.

### Authenticated Pro CLI

The Pro path is not smuggled into the public package. `@designcodeio/threeui-cli` uses OAuth with PKCE, stores refreshable auth in a user config path with owner-only file mode, validates component IDs, rejects unsafe paths, and refuses to overwrite changed project files unless `--force` is supplied.

### Source-Faithful Implementation Guides

Several catalog entries have generated skill-style implementation guides that tell an agent or developer to copy exact source, preserve renderer behavior, keep assets at expected paths, and verify resize, mobile, reduced motion, visibility, teardown, and console health.

## Architecture

ThreeUI has three related surfaces:

- The public catalog app in `src/`, with browse/search/docs/source tabs.
- The package component source in `src/shaders/` and generated exports in `src/package-components/`.
- The Pro installer CLI in `packages/cli/`.

The release flow is unusually disciplined for a design-component repo. `scripts/sync-community-from-main.mjs` creates the public subset, `scripts/public-boundary.test.mjs` locks the expected public surface, `scripts/audit-public.mjs` scans the fresh tree for obvious sensitive material, `scripts/audit-build.mjs` checks production output, and `scripts/package-install-smoke.mjs` verifies anonymous package installation.

One caveat: the README's included-count summary appears stale against the checked-in `public/community-sync-report.json`. The README says 50 Community parent components and 111 routes; the sync report currently says 43 Community parents and 104 routes. The build/test suite uses the report and passes, so this looks like documentation drift rather than package breakage.

## Comparison

| Aspect | ThreeUI | tldraw | diagram-design | html-anything |
|--------|---------|--------|----------------|---------------|
| Primary use | High-polish animated UI components and scenes | Infinite-canvas SDK | Diagram generation skill/workflow | Local agentic HTML editor |
| Runtime | React, Three.js, raw WebGL, iframe HTML | React canvas/editor SDK | HTML/SVG/Mermaid/draw.io outputs | HTML preview/export app |
| Reuse model | npm package plus copyable source guides | SDK integration | Prompted artifact workflow | Local editing tool |
| Caveat | Visual-heavy, not a broad design system | License/product surface complexity | Not a component library | More tool than library |

## Self-Hosting Notes

Local validation on 2026-08-26:

- `npm ci`: passed, 0 vulnerabilities.
- `npm run build`: passed, including 25 tests, typecheck, public audit, site build, build audit, library build, and asset copy.
- `npm run smoke:package`: passed anonymous install smoke test for `designcodeio-threeui-1.1.0.tgz`.
- `npm audit --omit=dev --json`: 0 production vulnerabilities.

Operational caveats:

- Some site chunks are large after minification, including heavy visual/Three.js scenes. Use subpath imports and lazy loading rather than importing the whole library casually.
- Some Community HTML scenes reference public CDN libraries or ThreeUI-managed media endpoints; the repo's own asset docs are clear that external catalog media is not redistributed under this repo's MIT license.
- There are no GitHub Releases yet; npm is the real distribution channel.

---

**Attribution:** MengTo/threeui, MIT plus documented third-party asset/font notices
