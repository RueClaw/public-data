# Anatomy (wheresryan22/anatomy)

**Repo:** https://github.com/wheresryan22/anatomy
**License:** MIT; see license details below for reuse obligations.
**Reviewed:** 2026-10-12 (UTC)
**Revision:** `689dcf966e63d92be10a5d593c6e19e10acd4422`
**Scope:** root documentation, kit, scripts, tests, examples and CI
**Verification:** Static source review only. No source code, installs, tests, builds, generated pages or benchmarks executed. Any upstream CI result is separately attributed.
**Stack:** Node.js · SVG · WebGL · optional React
**What it is:** Agent authoring workflow and geometry toolkit for interactive mechanical illustrations.

---

## Verdict

⚠️ **Interesting.** Interesting for carefully supervised visual-authoring pilots. The kit and regression work are substantial, but geometry checks are sampled and generated JavaScript plus browser inspection require real isolation.

## Update Notes

Checked 2026-10-12 UTC. Previous review dated 2026-10-11 recorded no exact revision. This refresh changes Deploy candidate to Interesting, corrects absolute geometry-proof language, documents active-content/browser trust boundaries and current regression coverage, and does not reuse historical local build timings as verification of this SHA. Exact source deltas cannot be reconstructed from the prior unpinned review.

## What It Is

Agent authoring workflow and geometry toolkit for interactive mechanical illustrations. World-shape recording, painter ordering, tubes, lathe geometry and shared-camera WebGL support a distinctive illustration workflow.

## Stack

| Layer | Technology |
|---|---|
| Implementation | Node.js · SVG · WebGL · optional React |
| Reviewed boundary | root documentation, kit, scripts, tests, examples and CI |

## Key Features

### More than a prompt

World-shape recording, painter ordering, tubes, lathe geometry and shared-camera WebGL support a distinctive illustration workflow.

### Audits are bounded evidence

Finite states, recorded shapes and tolerances constrain what a passing geometry audit establishes. It is not a continuous-time or engineering proof.

### Treat generated pages as code

Capture and drive tools intentionally execute active content with local-file capabilities. Use disposable secret-free execution and review generated markup.

## Architecture, Evidence and Security

## Public metadata snapshot
GitHub public API at approximately 04:50 UTC: 3,822 stars, 300 forks, created 2026-10-08T10:12:49Z, pushed 2026-10-12T01:05:12Z; not archived. Repository open_issues_count=4 includes PRs: open PRs #44 (Antigravity), #43 (Figure time estimate), #42 (capture bounding-box refresh), and issue #41 (estimated time incorrect). Popularity is not quality evidence.
Latest release: [v1.0.0](https://github.com/wheresryan22/anatomy/releases/tag/v1.0.0), published 2026-10-10T15:44:31Z, target dbf697a527bbf7d358668e1557cb1e35ff725d46, older than reviewed main.
Exact reviewed SHA CI: [run 38190514881](https://github.com/wheresryan22/anatomy/actions/runs/38190514881), created 2026-10-12T01:05:15Z, completed/success reported by GitHub API. This is upstream CI status, not tests independently run here. The newest overall run belongs to a different PR and says action_required; do not confuse it with reviewed-SHA CI.
Metadata endpoint: https://api.github.com/repos/wheresryan22/anatomy

## What it is / architecture
An Agent Skill, not an application server, model provider or agent orchestration framework. SKILL.md provides an opinionated design/build/inspect process; generated diagrams are recognizable physical mechanisms rather than box-and-arrow diagrams. JS/TS geometry creates projected SVG, four-tone shading, rounded solids, turned profiles, tubes, and painter ordering. Node build scripts emit self-contained HTML/SVG with inlined styles and runtime; React path separates static server art from client animation hooks. Optional WebGL canvases are sandwiched between back/front SVG with a shared camera; optional turn runtime reprojects moving parts. Audits consume recorded world shapes and route metadata; Chrome scripts capture/drive rendered pages via CDP. Eight examples provide working source and committed HTML for framework-free examples.
Evidence: [workflow](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/SKILL.md#L54-L77), [kit/module map](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/SKILL.md#L79-L104), [SVG/WebGL layering](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/SKILL.md#L124-L133), [README architecture](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/README.md#L239-L280).
Runtime requirements: Node 20.10+, Chrome/Chromium for checks, React 18+ only for React output. No dependency manifest; standalone kit relies on Node/browser primitives. “Zero dependencies” does not mean zero environment/tool dependencies: install CLI is separate, CI installs React, ReactDOM, TypeScript and esbuild. [Requirements](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/README.md#L285-L302), [CI dependencies](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/.github/workflows/ci.yml#L28-L33).

## Five principal findings

1. **Strong reusable workflow and geometry checking, not just a prompt.** One conceptual model drives visible motion and numeric readouts, while shapes are recorded alongside drawing and fed into a depth solver. This is a useful guard against fake-but-plausible generated illustrations. React animation writes refs rather than re-rendering each frame; static/live separation is a valuable pattern to reuse. Evidence: [truth/model and geometry workflow](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/SKILL.md#L63-L70), [settle and audit](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/kit/audit.mjs#L1870-L1899), [React animation loop](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/kit/react/live.tsx#L59-L103).

2. **Browser verification is a privileged trust boundary, not a safe renderer for arbitrary content.** capture accepts HTTP(S)/file targets and launches headless Chrome using a temporary profile, file-to-file access and unsafe SwiftShader; drive intentionally evaluates supplied JS. This is documented, not a demonstrated exploit. Generated or user-supplied pages can execute active JS and make network requests; a disposable Chrome profile is not filesystem/network isolation. Keep browser checks in a disposable secret-free sandbox with restricted egress and filesystem, and never expose drive as an unrestricted service. README's option to use Codex danger-full-access should not become a default. Evidence: [explicit security warning](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/SECURITY.md#L3-L11), [capture launch](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/scripts/capture.mjs#L94-L123), [drive launch](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/scripts/drive.mjs#L111-L128), [eval action](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/scripts/drive.mjs#L225-L241), [sandbox advice](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/README.md#L155-L177).

3. **SVG/HTML builders assume trusted authored inputs; they are not sanitizers.** Text/title and many attribute values are escaped, but raw body/inner markup, some geometry paths, face-text attributes and page theme are interpolated. groupSvg accepts arbitrary attribute names, so escaping values alone does not forbid event-handler attributes. Correct for an authoring library, unsafe if an application forwards untrusted JSON or generated snippets directly into published active HTML. Validate numeric/enumerated options, sanitize permitted SVG where feasible, review generated source, and isolate generated pages on an appropriate origin/CSP. No XSS exploit was executed; this is a direct static trust-boundary observation. Evidence: [escaping and raw solid paths](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/kit/iso-kit.mjs#L410-L434), [raw attribute/markup interfaces](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/kit/iso-kit.mjs#L525-L558).

4. **“Proves the geometry” overstates what sampled checks establish.** The audit is substantial: clearance, mounting, overlap, support and depth checks. But motion is replayed at finite states and surfaces/routes use finite sample spacing plus tolerances; correctness depends on accurate recorded shapes and exclusions. A passing audit does not prove continuous-time nonintersection, engineering correctness, accessibility, or faithful semantics. The audit hook is opt-in --audit, and CI rebuilds examples without that flag; full geometry/orbit audits are not made mandatory by the visible CI workflow. Evidence: [sampling/tolerance parameters](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/kit/audit.mjs#L870-L870), [sampled surface grid](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/kit/audit.mjs#L1619-L1641), [state generation / checks / opt-in hook](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/kit/audit.mjs#L1859-L1911), [CI build commands](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/.github/workflows/ci.yml#L35-L71).

5. **Real regression investment, but narrow compatibility evidence and young operational maturity.** Found 32 .test.mjs files covering geometry, clipping, browser navigation, capture, line ends, React DOM and 3D ownership. Sample tests use genuine assertions and browser fixtures, not merely import smoke checks. CI uses macos-latest and Node 22, fixed direct test dependency versions with --ignore-scripts, and fails if committed example output changes. No lockfile, OS/Node/React compatibility matrix or broad visual/performance gate was found. Beta 3D costs and Figure/Hero/Epic budgets are explicit; estimated authoring time is disputed in current issue/PRs. This makes it better for deliberate polished explainers than low-latency bulk generation. Evidence: [clearance tests](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/scripts/audit-clearance-envelope.test.mjs#L1-L39), [negative navigation tests](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/scripts/navigation.test.mjs#L35-L55), [native React DOM test](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/scripts/react-readout-first-write.test.mjs#L15-L37), [CI](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/.github/workflows/ci.yml#L16-L33), [byte-identical output gate](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/.github/workflows/ci.yml#L67-L71), [cost tiers](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/SKILL.md#L58-L62), [beta limits](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/README.md#L294-L302).

## License and reuse
Actual [LICENSE](https://github.com/wheresryan22/anatomy/blob/689dcf966e63d92be10a5d593c6e19e10acd4422/LICENSE#L1-L21) is MIT, copyright (c) 2026 Ryan. Commercial use/modification/distribution permitted, with copyright and permission notice included in copies or substantial portions; no warranty. Copying the kit into generated React/HTML projects still requires retaining applicable notices. The README's “source you own” wording is not a waiver of MIT notice obligations for copied kit code. No separate license was identified for repository subtrees in this review. Third-party assets supplied by a future user need their own provenance review.


## Comparison

Mermaid and Excalidraw suit simpler diagrams; Three.js/React Three Fiber suit substantial true 3D; isolated Playwright plus SVG offers conventional browser verification. These are fit comparisons, not separately benchmarked or audited alternatives.

## Self-Hosting Notes

Node 20.10+ and Chrome/Chromium for verification; React is optional. Keep generation/build/browser execution isolated, run full applicable audits, inspect both themes and reduced motion, and preserve MIT notices in copied kit code.

## Verification and Limitations

Public unauthenticated source acquisition and static inspection at the exact revision above. No runtime, exploit, performance, model-quality, dependency-vulnerability or distribution-provenance verification was performed. Review is sampled, not exhaustive; absence of an observed problem is not a security guarantee. Public metadata is a 2026-10-12 snapshot and not evidence of quality.

---

**Attribution:** [wheresryan22/anatomy](https://github.com/wheresryan22/anatomy), MIT. Source claims and upstream status are distinguished from this review’s static findings.
