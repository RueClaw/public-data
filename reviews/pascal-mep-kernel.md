# Pascal MEP Kernel (kruschdev/pascal-mep-kernel)

**Repo:** https://github.com/kruschdev/pascal-mep-kernel
**Author:** Kevin Ruschman (@kruschdev)
**License:** MIT; retain the copyright and permission notice when redistributing substantial portions. No engineering warranty.
**Reviewed:** 2026-11-28 (UTC)
**Revision:** eb1fc09037e49153d49ddb95b5f004b1925766d9; default branch main; source commit dated 2026-11-27. Scope: kernel source, tests, package/build configuration, README and specification; sibling plugins and live editor excluded.
**Verification:** Static review only. No installation, source execution, tests, build, live building corpus or engineering certification performed.
**Stack:** TypeScript, ESM, Bun tooling, TypeScript compiler; no declared runtime dependencies.
**What it is:** A spatial interpretation, route-planning and rule-evaluation library for Pascal Editor building-services plugins—not a standalone BIM application, Pascal-language compiler, or validated MEP design solver.

---

## Verdict

📚 **Study: a useful coordination kernel, not a construction-ready engineering authority.** Shared geometry and placement/audit rule reuse address real integration problems. However, missing measurements can produce a clean audit, failed routes can still reserve space, and the bounded geometric search is not a proof of constructability or regulatory compliance. Evaluate behind strict input, endpoint and independent engineering checks before using its output in actual design.

## What It Is

The product is npm package @kruschdev/pascal-mep-kernel, version 0.1.0. It accepts Pascal-shaped scene-node records, derives building anatomy, compiles a discrete graph of routing cavities and evaluates caller-provided declarative constraints. Structural, plumbing, HVAC and electrical plugins are separate repositories; their load calculations, equipment sizing and complete code-rule tables are not established by reviewing this kernel. The README's rendered house and 1,412-node showcase describe that wider ecosystem. [1][2]

Anonymous GitHub API access and an unauthenticated HTTPS clone confirmed a public source. At retrieval, GitHub reported 0 stars, 0 forks, 0 open issues, last push 2026-11-27T18:21:52Z, and no releases or tags. These are discovery metadata, not quality evidence. The public npm registry listed latest 0.1.0, published 2026-11-27T05:50:18.125Z, with tarball SHA-1 60782fd78fe195503b238651b7109d1c9b071b95. The tarball was not downloaded or compared with this later source revision. [12]

## Stack

| Layer | Tech |
|-------|------|
| Public API | TypeScript types; root, types, anatomy, router and rules ESM exports |
| Geometry | Y-oriented prisms, AABBs, polygon/footprint and roof helpers |
| Routing | Discrete cavity graph, constrained A*, shaping and final diagnostics |
| Rules | Nine typed rule variants and placement/audit evaluators |
| State | WeakMap-derived anatomy caches and mutable in-memory occupancy |
| Tooling | Bun build/test, TypeScript declarations, dependency-boundary check |
| Service/UI/database | None in the kernel runtime |

## Key Features

### Shared interpretation reduces cross-trade drift

One anatomy layer resolves stories, walls, openings, footprints and seven roof forms. Local-frame segment/prism tests and SAT-style overlap checks are more precise than relying solely on world-axis bounding boxes. Unit conversions are explicit; meters coexist with named inches/feet fields rather than pretending all engineering quantities share a unit. These are useful building blocks, not a general solid-modeling or finite-element kernel. [3][4]

### One rule table, two projections

Placement thresholds tighten minimums upward and maximums downward using nonnegative margins. This is a sensible way to prevent a generator from using looser thresholds than its auditor. But agreement between two projections of the same incomplete rule table does not independently validate that table, its code edition, jurisdiction, applicability or measurements. Rule IDs and code references are supplied data, not verified regulatory authority. [7]

### Constrained routing plus inspectable diagnostics

Routing modes cover orthogonal paths, open-cavity diagonals, falling drains and non-descending vents. The solver tries a hard-free search, then a degraded diagnostic search, then a synthesized fallback if necessary. It returns paths with collision/opening/roof/void diagnostics and an ok flag; a returned polyline alone is never a success signal. [5][6]

## Architecture

The public barrel exposes three layers: scene interpretation → cavity graph/search → caller-supplied rule evaluation. Compilation memoizes by the input object identity and lazily caches per-level derived geometry. Occupancy tracks obstacles and reservations separately, so callers must share the intended occupancy instance and enforce trade ordering themselves. Calling createOccupancyGrid again creates a fresh grid, not a persistent global reservation service. [3][8]

### Numerical and engineering validity

- **Discrete, bounded search:** graph compilation targets 580 vertices and caps station selection at 24 per wall; the constrained search retains at most 16 Pareto labels per state. Pruning trades completeness for bounded work: a failed search does not prove no feasible route exists, and global shortest-path optimality should not be assumed. [5][6]
- **Approximate enclosure checks:** the footprint implementation combines polygons/half-edge faces with a 16-ray fallback. Its general segment-inside check samples at a nominal 0.35 m step with a 64-step cap. Narrow excluded regions between samples are a geometric validation risk; this is not a continuous proof for arbitrary models. [4]
- **Permissive invalid-input handling:** the route entry sanitizes nonfinite endpoint components to zero and nonfinite run dimensions/clearance to zero. This avoids NaN propagation but can silently alter a requested route or shrink its safety envelope. Validate finite values, physical ranges and scene units before entry, rather than treating finite output as correct input handling. [6]
- **Gravity endpoint concern:** when available head is insufficient, gravity shaping can continue falling beyond the supplied target elevation. The final gravity audit checks terminal elevation only in the sufficient-head branch. Static control-flow inspection therefore identifies a possible route/target mismatch without a dedicated failure flag; an independent endpoint-equality and per-segment slope check is required. This was not reproduced by execution. [6, lines 1510–1664 and 2075–2102]
- **No physical-system certification:** clearance and routing heuristics do not establish structural load capacity, pressure losses, thermal loads, electrical ampacity, fabrication tolerances or legal code compliance. Require domain solvers, correct project inputs and qualified review separately.

### Clean audit can mean missing evidence

Working-space width/depth/height checks only run when those measurements are supplied and finite. Fixture keepouts return no violations if nearFixtures is absent. A targeted candidate missing these measurements can therefore receive legal: true; an empty active rule list can produce an audit pass. validateRuleTable is separate from evaluation and is not invoked automatically by the public evaluators. Add mandatory measurement completeness and rule applicability gates, and distinguish “unknown/not evaluated” from “passed.” [7, lines 211–214, 488–565, 978–1074]

The audit summary's ok means zero error-severity violations, whereas placement legal requires zero violations of any severity. Consumers must not conflate these contracts. [7]

### Persistence and recovery

There is no database, journal, durable reservation log, collaboration lock or scene-save service in this package. The host owns persistence and reproducibility: store scene revision, rule edition, solver options and accepted paths, then rebuild anatomy/occupancy after restart. Use immutable scene snapshots; mutating the same node-map identity can leave cached geometry stale. Readonly types and shallow freezes are not a general deep immutability guarantee. [3][8]

**Important reservation trap:** finalization calculates ok, but reserveOnCommit reserves any path with at least two points without conditioning on that result. A rejected diagnostic route can occupy space and influence later routing. Prefer no automatic reservation, reserve only after independent acceptance, or explicitly unreserve the returned reservation ID on rejection/rollback. Reservation deletion exists, but atomic multi-route commit/undo is the host's responsibility. [6, lines 2130–2150][8, lines 1298–1390]

### Security and privacy

The inspected runtime is an in-process library with no observed network client, credential store, auth layer, HTTP listener, database or telemetry integration. No CORS or login configuration is needed at this layer. That limits direct data egress; it does not certify the separate editor, plugins or media tooling. Package scripts use filesystem/build tools, and the build can fall back to bunx for a compiler, so static source purity must not be confused with a sandboxed installation. [2][9]

Treat imported building models and external rule data as untrusted. TypeScript types are not runtime validation; bound scene sizes, coordinate magnitudes, polygon complexity and allowed rule shapes before computation. Occupancy clash checks scan the obstacle list, so resource usage is model-dependent despite “grid” naming. If exposed via a service, add authentication, quotas and isolation in that host. Building layouts may be sensitive: the kernel does not provide access control, encryption or retention policy. [8]

## Evidence, Tests and Maturity

Ten checked-in Bun test files cover hierarchy/roof interpretation, openings/footprints, occupancy, routing and rule evaluation. Inspected regression cases include rotated-prism padding, cache-key separation, reservation ID collision/rollback, invalid numbers, multi-trade routing, bend budgets and placement/audit boundaries. The purity script builds five public entry points and rejects non-relative imports; the package check script combines typechecking, tests, purity and build. No GitHub Actions workflow was present in the reviewed tree. [9][10]

The README reports 169/169 kernel tests and 135,888 assertions, 582/582 ecosystem tests, and a 246-building corpus with 145 fully clean buildings and zero crashes/NaNs. These are author-reported results, not review-run results. No corresponding corpus runner/dataset and detailed result bundle was found in this repository's tracked tree; the separate plugin suites and live showcase were not independently validated. “Zero audit errors” is especially limited when the same implementation generates and audits geometry. Popularity, rendered videos and assertion counts do not replace independent reference cases. [1][10]

Before adoption: reproduce the pinned build/tests in isolation; add missing-measurement and malformed-rule cases, insufficient-head endpoint tests, failed-route reservation rollback tests, adversarial narrow-void geometry, independent analytic fixtures and multi-scene restart/rebuild checks. Publish versioned corpus inputs and detailed failures, not only totals.

## Comparison

| Need | Existing option | Tradeoff against this kernel |
|------|-----------------|-----------------------------|
| Pascal-specific MEP coordination | Pascal MEP Kernel | Small TS integration surface; host-specific scene semantics and unproven engineering completeness |
| IFC interoperability/geometry and BIM tooling | [IfcOpenShell](https://github.com/IfcOpenShell/IfcOpenShell) | Established IFC-oriented library; not a drop-in Pascal cavity router |
| General parametric CAD/BIM authoring | [FreeCAD](https://github.com/FreeCAD/FreeCAD) | Broader modeling application rather than an embeddable pure-TS rule kernel |
| Whole-building energy simulation | [EnergyPlus](https://github.com/NatLabRockies/EnergyPlus) | Relevant physical modeling evidence for energy/HVAC work; not automatic coordinated routing |

These are complementary scope comparisons, not benchmarked substitutes. None removes the need for jurisdiction-specific rules and professional design verification. Public project metadata was checked; alternative code was not audited.

## Self-Hosting Notes

There is no server to deploy. Integrate the library into a host application only after validating the exact package artifact and its relationship to source. Pin versions and a lockfile; keep build tools isolated, validate inputs, reject unknown measurements, assert route endpoints and geometric constraints, and persist accepted state in the host. Do not interpret the four-trade demo as a turnkey production deployment. MIT permits reuse subject to notice preservation; it supplies no warranty of engineering correctness. [2][11]

## Sources

All source links below are pinned to the reviewed commit; external metadata is a retrieval-time snapshot.

1. [README: scope and reported evidence](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/README.md)
2. [Package manifest](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/package.json)
3. [Anatomy cache and occupancy construction](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/src/anatomy/index.ts)
4. [Footprint geometry](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/src/anatomy/footprint.ts) · [primitive geometry/units](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/src/types.ts)
5. [Cavity graph compiler](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/src/router/cavity-graph.ts)
6. [Search, shaping and reservation](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/src/router/shortest-path.ts)
7. [Rule evaluator](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/src/rules/evaluator.ts) · [rule/candidate schema](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/src/rules/schema.ts)
8. [Occupancy and rollback](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/src/anatomy/occupancy.ts)
9. [Purity gate](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/scripts/check-purity.ts) · [build script](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/scripts/build-dist.ts)
10. [Checked-in tests](https://github.com/kruschdev/pascal-mep-kernel/tree/eb1fc09037e49153d49ddb95b5f004b1925766d9/src/__tests__)
11. [MIT license](https://github.com/kruschdev/pascal-mep-kernel/blob/eb1fc09037e49153d49ddb95b5f004b1925766d9/LICENSE)
12. [Public repository metadata](https://api.github.com/repos/kruschdev/pascal-mep-kernel) · [releases](https://api.github.com/repos/kruschdev/pascal-mep-kernel/releases) · [tags](https://api.github.com/repos/kruschdev/pascal-mep-kernel/tags) · [npm metadata](https://registry.npmjs.org/@kruschdev%2fpascal-mep-kernel)

---

**Attribution:** Kevin Ruschman / kruschdev/pascal-mep-kernel, MIT. Independent static analysis; no source implementation or media extracted.
