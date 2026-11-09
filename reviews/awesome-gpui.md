# awesome-gpui (zed-industries/awesome-gpui)

**Repo:** https://github.com/zed-industries/awesome-gpui

**Source type:** Curated ecosystem catalog, maintained in a code repository—not the GPUI framework.

**Owner:** Zed Industries and contributors.

**License:** CC0-1.0 for this catalog; linked software, documentation, images and trademarks retain their own terms.

**Reviewed / retrieved:** 2026-11-09 UTC.

**Revision:** `92b6ba71085f8e62a88dc19ea356b0fdb6ab8096` (commit dated 2026-11-09T20:34:11Z). Entire catalog and its generation/validation machinery reviewed.

**Verification:** Static source/document review and bounded public link/metadata checks. No source scripts, linked apps, builds, GUI tests or benchmarks executed.

**Stack:** JSON catalog, generated Markdown, Python 3.11+, uv lockfile, GitHub Actions. Linked ecosystem: Rust/GPUI and several wrappers.

## Verdict

📚 **Study / good discovery reference—not a vetted adoption registry.** This is a useful, unusually well-maintained map of GPUI applications and components. Its structured source and activity badges make discovery efficient, but neither inclusion under Zed's organization nor a green dot establishes quality, compatibility, security or platform parity. Start with current official GPUI examples and GPUI Kit; use the rest as a shortlist for separate evaluation.

The strongest concrete finding is version drift: the listed `longbridge/gpui-component` URL now resolves to **GPUI Kit**, while the official scaffolder still emits an unpinned Git dependency. The catalog helps you find projects; it does not select a coherent set of dependencies for you.

## What it is and who should use it

The opening sentence describes GPUI itself, but this repository contains no UI framework implementation. Its product is a browsable list of projects. Developers evaluating native Rust interfaces, looking for component libraries, or studying application architecture will get more from it than someone expecting a supported SDK or a buildable starter workspace.

The full `projects.json` contains **161 entries with 161 distinct exact project URLs**, all HTTPS, and every project URL appears in the generated README. These are entries, not 161 independent repositories: several libraries are subdirectories of one repository. Nine entry URLs are not GitHub project URLs. The count excludes separate screenshot URLs and links embedded in descriptions.

| Section | Entries | Assessment |
|---|---:|---|
| Apps / Developer Tools | 63 | Dominant segment: editors, database/API clients, terminals and agent workspaces |
| Apps / Productivity | 31 | Notes, file tools, readers and messaging |
| Apps / Media | 15 | Players, recording, editing and launchers |
| Apps / System Utilities | 12 | Monitoring, disk, clipboard and device utilities |
| Apps / Demos & Examples | 3 | Very small explicitly beginner-oriented subset |
| Libraries | 29 | Controls, graphs, plotting, navigation, wrappers and platform layers |
| Tooling | 6 | Scaffolding, inspection, agent instrumentation and cross-runtime tooling |
| Resources | 2 | One community book and one video playlist |

This is broad application discovery but thin pedagogy. The taxonomy mixes polished products, experiments, archived projects, product-only sites with unverified source availability and framework extensions. There are no machine-readable fields for license, tested OS, GPUI revision, accessibility, release/signing status or selection rationale. That omission matters more than whether one more application is missing.

## Curation architecture and maintenance

[Catalog source and schema][list-tree] are the canonical inputs. The schema requires name, category, URL and description, requires an app subcategory, rejects unknown fields, and requires HTTPS URLs. Python scripts sort entries by schema category order and case-folded name, then generate README tables from the template and GitHub metadata. This is substantially easier to maintain than manual star counts.

The PR template tells contributors to edit JSON rather than generated Markdown and validate/sort it. CI checks schema conformance and ordering and rejects README edits in PRs. A daily scheduled workflow and relevant main-branch changes regenerate the README; publication retries are bounded when main advances. The auto-assignment workflow uses `pull_request_target` only for metadata and does not check out PR code. Actions are major-tag references rather than immutable commit pins. These are workflow observations, not evidence that every recent CI run passed.

There is no separate CONTRIBUTING file in the inspected tree and no substantive acceptance rubric beyond this mechanical process. The code of conduct points to Zed's public policy. Maintainer assignment and schema gates improve consistency; they do not substitute for project review.

### What the badges actually measure

The legend says “latest commit,” but for a repository-root link the generator uses GitHub's **`pushed_at`**, not a verified latest default-branch code commit. For a subdirectory link it queries the commits endpoint with a path filter, but does not carry the URL's branch/ref into that query. Thus a link to a non-default branch can have activity measured on a different ref. Repository stars are reused for subdirectory entries; they are not votes for that component. Archived status takes precedence; non-GitHub entries get N/A; API failures become unavailable rather than disappearing.

The 30-/90-day thresholds are useful triage but not a maintenance assessment. A documentation push can make something green; a stable complete example can be dormant without being broken. The renderer does not check arbitrary product websites or screenshot availability, and successful repository metadata retrieval does not prove that a linked subdirectory exists or builds. The generator warns on metadata failures but can still publish a degraded table.

Public GitHub metadata retrieved on the review date reported **1,648 stars, 143 forks, six open issues/PRs, not archived, and last push 2026-11-09T20:34:13Z**. The open-items sample consisted of six addition PRs (#163, #165, #166, #168, #169, #170), not six confirmed defects. The releases query returned an empty list. A catalog does not need binary releases. These figures are time-sensitive popularity/activity context, not a quality score.

## Coverage, biases and missing decision information

- **Developer-workflow skew:** 63 of 124 application entries are developer tools. Agent terminals and database clients recur heavily. This reflects the visible contributor ecosystem, not a measured census of all GPUI usage.
- **Discoverability bias:** GitHub projects have rich stars/activity signals; product-only sites do not. The fire marker privileges popularity, while alphabetical ordering at least avoids a pure popularity ranking.
- **Learning gap:** only two resources and three demo entries; no guided sequence linking state, focus, input methods, accessibility, async work, testing and packaging. The official site supplies a better starting spine.
- **Compatibility gap:** no dependency compatibility matrix. A tutorial targeting GPUI 0.2, a moving Zed Git revision and GPUI Kit's snapshot packages are not automatically interchangeable.
- **Evidence gap:** descriptions such as “fastest,” “secure,” “cross-platform,” “zero runtime overhead” or “production ready” are project claims. The list provides no common benchmark, threat model, accessibility audit or release qualification supporting them.
- **Lifecycle gap:** archived projects remain useful history and are honestly labeled, but novice readers need explicit replacement/learning-only guidance. The Codux entry does point to a successor, a helpful pattern to expand.

A better catalog would add tested platform/revision, license and release links, a last-human-checked date, and a concise reason for inclusion. These are recommendations, not features claimed to exist.

## Bounded link verification and practical shortlist

The sample was chosen by role, not star ranking: upstream framework/application, primary component library, official scaffolder, one book, one small app and one larger custom-rendered utility. All six sampled repository endpoints were publicly retrievable (five shallow HTTPS clones plus pinned Zed files). The official site returned HTTP 200 and redirected `www.gpui.rs` to `gpui.rs`. No exhaustive HTTP sweep, screenshot check, video review or downstream dependency audit was performed.

| Use | Pick and selection rationale | Evidence and caveat |
|---|---|---|
| Learn current fundamentals | [Official GPUI site](https://gpui.rs/) → README, contexts, key dispatch and examples | Closest to the evolving upstream API. Read examples at the same revision as your dependency, rather than combining snippets from different dates. |
| Learn vocabulary | [GPUI Book](https://github.com/MatinAniss/gpui-book) | Clear sampled Entity/Context explanations and a structured contents page. Last sampled commit is October 2025; README explicitly declines contributions/PRs. Several contents entries have empty destinations (Canvas, List, paint phases, etc.). No license file found: read and cite, do not assume permission to redistribute its prose/code. Supplement, not authoritative current manual. |
| Build ordinary controls | [GPUI Kit](https://github.com/longbridge/gpui-kit), listed as gpui-component | Best first component candidate in this sample: behavior/base, styled components and optional JS shell are separated; exact upstream snapshot dependencies and real accessibility-oriented tests are visible. Evaluate its added abstraction and API churn. |
| Study a compact app | [gpui-todos](https://github.com/duanebester/gpui-todos) | Small modules for input, state, theme, assets and view; useful to trace actions and global state. Manifest uses GPUI 0.2; sampled main has macOS-oriented keybindings. No license file or manifest license found. Learning reference, not a licensed cross-platform starter recommendation. |
| Study a substantial app | [Zed](https://github.com/zed-industries/zed) | Upstream application explains why entities, actions, custom elements and async execution exist. Large scope and application-specific coupling make it a reference, not a minimal template. GPUI's Apache license does not make Zed's GPL application code permissively reusable. |
| Study custom visualization and packaging | [disktree](https://github.com/tobi/disktree) | Inspectable split between UI-free core, GPUI app, scanner and packaging. README documents Linux/macOS/Windows distribution and filesystem limitations. Good architecture specimen, but deletion/SSH authority makes it inappropriate as a casual “try every app” exercise. No removals, scans, installers or SSH operations were run. |
| Scaffold cautiously | [create-gpui-app](https://github.com/zed-industries/create-gpui-app) | MIT, minimal app/workspace layouts, official organization. Sampled latest commit is April 2025; template specifies a Git GPUI dependency without `rev`. Treat as readable scaffolding and reconcile with current official platform initialization—not a reproducibility guarantee. |

### Concrete component drift

GitHub resolves the listed `longbridge/gpui-component` repository to `longbridge/gpui-kit`. At the sampled SHA, the README advertises the `gpui-kit = "0.7"` usage line, while the workspace declares its packages as **0.9.1** and pins `gpui-pre` platform/macro companions to **=0.3.12**. Comments explicitly warn that snapshots can change APIs and that floating them previously broke consumers. This is source-level version evidence, not a claim that the latest published release equals the workspace version.

The sampled checkbox implementation contains accessible-role handling and tests inspecting the accessibility role. That supports “there is implemented accessibility work,” not “all controls are accessible on all platforms.” Claims of 120 FPS, hundreds of thousands of table rows, or 200K-line editing were not benchmarked. Optional GPUI Fast and JavaScript extension hosting expand the dependency/trust surface and were not separately audited.

## GPUI reality check: framework evidence, not catalog promises

Official source was sampled at **f0d896f2c18a543335eb155f729d36b624695591**. Its [GPUI README][gpui-readme] explicitly says **pre-1.0 with frequent breaking changes**; the crate manifest declares version 0.2.2 and Apache-2.0. The version in a main-branch manifest is not proof of what a particular registry release contains.

### Architecture and rendering

Entities own state; views implement `Render`; elements provide lower-level layout/prepaint/paint control. Contexts mediate state access and updates; actions map input to logical operations; an integrated executor supports async work. This is a hybrid retained-state/declarative-frame architecture, not a DOM or a collection of OS-native widgets. CSS/Tailwind-inspired method names do not imply browser CSS compatibility.

The current [platform constructor][platform] selects macOS, Windows, Linux/FreeBSD, iOS and WebAssembly implementations. The README documents Metal on macOS, Wayland/X11 on Linux/FreeBSD, and Win32/DirectWrite on Windows. Sampled platform manifests connect Linux to `gpui_wgpu` and Windows to Direct3D 11 APIs; the wgpu renderer contains a WebGL shader path. Do not repeat obsolete blanket claims that GPUI is macOS-only or that every backend uses one renderer. Equally, platform branches and community mobile entries are not proof that every widget, IME, driver, release package or assistive technology has equivalent support. Android/OpenHarmony list entries need their own platform-layer evaluation; the inspected default platform constructor is not an Android support matrix.

### Accessibility is present, but application work remains

The upstream [accessibility guide][a11y] documents AccessKit integration, roles, stable global element IDs, synthetic children and assistive actions. It explicitly warns that repeated IDs can silently drop nodes in release builds and that nodes without a role are not reported. An application's custom canvas/editor cannot become accessible merely by rendering with GPUI. Test focus, screen-reader semantics, action dispatch, contrast, zoom, reduced motion and IME on each shipping platform. No screen-reader or hardware testing was done here.

### Distribution and licensing

A successful Rust build is not a distributable product. Qualify platform runtime dependencies, GPU/driver compatibility, assets/fonts, signing/notarization, installer/update behavior and crash diagnostics. Disktree's README, for example, describes separate per-OS artifacts and caveats around unsigned macOS builds and helper packaging; these are documentation observations, not independently validated binaries.

The catalog's CC0 dedication covers its own rights only and expressly does not clear third-party rights. GPUI is Apache-2.0; sampled GPUI Kit software is Apache-2.0 with an additional CC BY 4.0 offer for specified documentation; create-gpui-app and disktree have MIT texts. Zed's README describes primarily GPL-3.0-or-later application source with Apache components where marked. The book and todos sample lack an explicit license. Follow the actual file/component terms and preserve applicable notices; inclusion does not grant reuse permission.

## Fit versus maintained alternatives

These are architecture choices, not comparative performance results. Alternative documentation was checked on 2026-11-09; no alternative was built or audited.

| Requirement | Sensible direction | Tradeoff |
|---|---|---|
| Rust-native, highly customized editor/tool UI; willing to own upgrades | GPUI, with GPUI Kit if standard controls fit | Strong control over rendering/state; pre-1.0 churn and release qualification remain yours |
| Rust application with explicit message/update state flow | [Iced](https://github.com/iced-rs/iced) | Elm-style architecture, built-in widgets and wgpu/tiny-skia renderer options including software fallback; its README also calls it experimental, so not an automatic stable-API escape |
| Immediate-mode tools, inspectors or embedding UI in a rendering engine | [egui/eframe](https://github.com/emilk/egui) | Direct immediate-mode model and documented native/web integrations; different UI/layout model, not a GPUI component substitute |
| Conventional desktop product with established controls and accessibility guidance | [Qt 6](https://doc.qt.io/qt-6/accessible.html) | Documented Widgets/Quick keyboard and accessibility facilities; C++/QML integration and module-specific open-source/commercial license compliance, rather than a Rust-first GPUI stack |

Choose GPUI because its state/rendering model and available components match the product—not because multiple list descriptions say “blazing fast.” Before committing to it, build a separately authorized small qualification app covering a large list, complex text input, keyboard navigation, accessibility, background work and a packaged binary on each target OS. This review did not perform that exercise.

## Evidence ledger and verification limits

All revisions below were retrieved publicly on 2026-11-09 UTC. Mutable web/API observations are date-stamped rather than presented as immutable snapshots.

| Source | Exact revision | Inspected scope |
|---|---|---|
| awesome-gpui | 92b6ba71085f8e62a88dc19ea356b0fdb6ab8096 | Entire README/catalog, LICENSE, schema, template, PR template, code-of-conduct pointer, Python scripts, manifests/lockfile inventory and three workflows |
| zed-industries/zed | f0d896f2c18a543335eb155f729d36b624695591 | GPUI README/manifest/crate-root, contexts/key-dispatch documents, accessibility guide, platform constructor/manifests, renderer excerpt and root licensing section; not entire Zed |
| longbridge/gpui-kit (redirect from gpui-component) | 0a2a64339c1821e9914e4c19603c0e543f618f7d | README, workspace manifest/pins, license documents, checkbox accessibility/test excerpts |
| zed-industries/create-gpui-app | 63fbe214da83c5409f6845147d793d595b12e2c5 | README, MIT license, template inventory and default Cargo template |
| MatinAniss/gpui-book | 664b8127b29a8c7291e68cd2f99fc12a8c2fc382 | README/contribution policy, contents, Entity/Context chapters and license-file absence |
| duanebester/gpui-todos | d721babd4ffc5e599bd89ed89f03004afb1149d9 | README, manifest, main/module layout and license-file absence |
| tobi/disktree | 9b18b272ca3c5a145f6ff58eaf89dc4d311eeaea | Full README, MIT license, workspace manifest and directory/package layout; no safety audit of removal implementation |

Checks performed: JSON parsed successfully; 161 distinct exact URLs; all HTTPS; all catalog URLs represented in README; five sampled linked clones succeeded; official source files and site were public; repository redirect confirmed through GitHub API. Schema/order CI was **read, not executed**. No build/test success is asserted for any linked project. The shallow clones do not establish full historical cadence. Release binaries, security claims, arbitrary website links, screenshots, mobile/WebAssembly behavior and comparative performance remain unverified.

**Bottom line:** bookmark this as a living map. Learn from current upstream, shortlist GPUI Kit for components, study small examples with revision/license caution, and qualify apps independently. Nothing here endorses installing the entire list.

**Attribution:** Zed Industries and awesome-gpui contributors (CC0-1.0); linked authors retain their own rights. This review is independent analysis, not an upstream endorsement.

[list-tree]: https://github.com/zed-industries/awesome-gpui/tree/92b6ba71085f8e62a88dc19ea356b0fdb6ab8096
[gpui-readme]: https://github.com/zed-industries/zed/blob/f0d896f2c18a543335eb155f729d36b624695591/crates/gpui/README.md
[platform]: https://github.com/zed-industries/zed/blob/f0d896f2c18a543335eb155f729d36b624695591/crates/gpui_platform/src/gpui_platform.rs
[a11y]: https://github.com/zed-industries/zed/blob/f0d896f2c18a543335eb155f729d36b624695591/crates/gpui/src/_accessibility.rs
