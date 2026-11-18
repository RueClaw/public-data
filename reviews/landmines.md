# Landmines (interfere-inc/landmines)

**Repo:** https://github.com/interfere-inc/landmines
**License:** MIT, copyright 2026 Interfere, Inc.; preserve copyright and permission notices when reusing code. Dependency terms are separate.
**Reviewed:** 2026-11-18 (UTC)
**Revision:** 92084b12872103b0f9245c0325ab571df00a574b; whole repository, implementation focus on packages/landmines.
**Verification:** Static inspection only; no installation, build, tests or source execution. Public GitHub CI reports success for this SHA, not independently reproduced.
**Stack:** TypeScript, Oxlint JS plugins, Babel, oxc-resolver, Zod; Bun/Turbo/tsdown/Vitest tooling.
**What it is:** Ten opinionated JavaScript/TypeScript lint rules encouraging real implementations, event-based test synchronization, and explicit project conventions. Not a prompt-injection trap, agent sandbox, testing service or AI model.

## Verdict

⚠️ **Interesting — pilot selected testing rules, not the whole recommended preset blindly.** Actionable diagnostics and exact-count legacy allowances turn useful testing policies into executable feedback. But syntax checks cannot make tests truthful, and several implementation details weaken the headline promises. Comment, type and directory rules are team preferences rather than universally safer code.

## What It Is

Interfere packages four independently selectable Oxlint plugins: testing (five rules), style (one), structure (three), and types (one). The recommended JSON enables all ten as errors, including rules internally classified as suggestions. Oxlint loads JavaScript plugins, walks source syntax and returns diagnostics to editors, CI or coding agents. No LLM is involved. [README][readme]; [preset][preset].

The README claims production use at Interfere and says it “makes the honest path the only one that lints.” Production use is an author claim, not independently verified evidence. The implementation enforces selected patterns, not behavioral correctness, coverage quality or adversarial resistance. Passing lint cannot establish that assertions test the right thing or that a test has no external side effects.

## Stack and Architecture

| Layer | Implementation |
|---|---|
| Package | @interfere/landmines 0.1.0; four ESM subpath exports and recommended JSON |
| Runtime | Node >=22.18; peer Oxlint >=1.81 |
| Rules | @oxlint/plugins definePlugin/defineRule; AST visitors and lexical scope helpers |
| Cross-file analysis | oxc-resolver plus Babel parsing of test companions |
| Validation | Zod configuration and package-manifest schemas |
| Build/tests | Bun 1.4.3, Turbo, tsdown ESM/declarations; Vitest invoking Oxlint |

The 2,356-line no-test-doubles rule is considerably more than a name regex: it includes scope/alias handling, framework replacement methods, protected browser globals, saved-and-restored monkey patches, Cloudflare bindings, Hono request bindings, Playwright static responses and raw Response recognition. It permits observation-only spying while rejecting known replacement behavior. That breadth creates a large framework-specific maintenance surface. Core visitor paths and representative helpers were inspected, not every branch formally verified. [Implementation][doubles].

Structure analysis resolves imports within the enclosing package, traverses companion files with visited sets, skips type-only imports and infers implementation ownership. It assumes a conventional src layout; unresolved/ambiguous ownership or companion syntax errors can yield no location diagnostic. It reads rather than executes imported application source. Package-exports separately reads the nearest package.json and rejects selected broad source export targets. These are architectural heuristics, not module-access security controls. [Owner analysis][owner]; [colocation][structure]; [exports rule][exports].

## Key Features and Concrete Limitations

### Actionable feedback and a useful count ratchet

Messages propose alternatives: await an operation or handler signal, retain real dependency implementations, intercept network boundaries with MSW. Per-file allowances require exact violation counts: fewer gives a stale-entry diagnostic, equality passes, more reports violations. Paths match exactly or by suffix, so use unambiguous package-relative entries. This is a count baseline, not a fingerprint: swapping one violation for another can keep the count unchanged. An editable allowance is not protected policy. [Allowlist][allowlist].

The README names three allowlisted rules, but no-unsignaled-poll also uses this mechanism. no-flake-masking applies its allowance to timeouts, not retries; retry reports are unconditional. It detects timeout syntax, not an actual numeric increase from a previous/default value, making enforcement broader than “raised timeouts” suggests. [Flake rule][flake]; [poll rule][poll].

### strict-msw does not guarantee network denial

Its strict() helper accepts any inline onUnhandledRequest function without checking whether it throws or fails. The accepted fixture suite explicitly includes a handler that only appends the request URL to an array. Passing the rule therefore does not establish that an unhandled request fails or egress is blocked. Detection also follows selected local named imports/factories, not every wrapper or namespace pattern. Enforce test egress separately. [Rule][msw]; [accepted fixtures][mswtests].

Public [issue #9](https://github.com/interfere-inc/landmines/issues/9) reports MSW 3 onUnhandledFrame compatibility problems. The checked implementation recognizes only onUnhandledRequest; the reporter's upstream API-version claim was not independently tested here. Verify your installed MSW version rather than copying diagnostics uncritically.

### Timer and polling heuristics have meaningful gaps

Any recognized vi.useFakeTimers() call sets a file-wide boolean; Program:exit then suppresses all collected fixed-sleep violations. It does not track timer restoration, execution order or whether another test still sleeps in real time. Detection otherwise targets selected awaited expressions in recognized test/hook bodies, not arbitrary helpers. This is a static finding, not an executed exploit. [Sleep rule][sleep].

no-unsignaled-poll recognizes expect.poll and vi.waitFor with selected simple callback shapes and recorder-like property names. It does not cover vi.waitUntil at this revision. Complex callbacks can fall outside detection, while length/size naming substitutes for recorder identity. These are understandable heuristics, not synchronization analysis. [Poll rule][poll].

### Recommended directory conventions disagree

The README and colocated-tests accept a local tests/ directory; the owner helper accepts test, tests and __tests__. But test-file-names reports tests and __tests__ anywhere beneath the package. The recommended preset enables both rules, so acceptable colocation can still fail naming enforcement. Use singular test or settle the policy explicitly. [Naming][names]; [owner helper][owner]; [README][readme].

### Comment and return-type bans are optional opinions

no-comments preserves recognized tool directives, single-line WARNING comments and selected public API TSDoc. License-header recognition specifically includes SPDX and @license markers; do not assume every plain copyright/license block is exempt, and never delete legally required notices to satisfy lint. no-explicit-return-types exempts predicates and never but otherwise rejects annotated implementations. Explicit contracts and durable rationale comments can be beneficial; neither ban establishes better defect detection. The inspected rule definitions expose no autofix. [Comments][comments]; [return types][types].

## Security, Privacy and Operational Boundaries

- **Authority:** JavaScript plugins execute with the linter process's privileges. Landmines supplies no sandbox or consent boundary. Inspected production rule paths read source, companions and manifests; no hosted listener, authentication layer, credential store, model client or telemetry transport was found. This observation is scoped to inspected source, not every dependency or registry artifact.
- **Untrusted inputs:** Resolution, parsing, manifest validation and configurable regular expressions are input-processing boundaries. Invalid manifests can throw; complex graphs/regexes can consume resources. Same-package filtering is an ownership heuristic, not OS confinement. Lint untrusted projects in a secret-free bounded environment, including other project plugins/configuration.
- **Real dependencies need consent:** Recommendations to use actual implementations do not authorize production databases, accounts, devices or network calls. Integration tests require disposable services, synthetic data, egress policy and explicit permission. MSW lint checks do not provide those controls.
- **Data/cost:** No provider account, model, dataset or token spend is required. Costs are local/CI compute and maintenance; installation contacts package registries. Integration tests inspired by the advice may incur separate service charges. An external coding agent consuming lint output has its own provider data policy.
- **Retention/export/recovery:** No database, cloud sync, retention setting or backup subsystem is present. Oxlint diagnostics may persist as paths/snippets in editor, CI or agent logs under those systems' policies. Config and allowances are project files; export is ordinary linter output and recovery is version-control rollback of configuration/dependency changes. Inspected production rules do not rewrite application files.

## Dependencies, Installation and Updates

Five exact direct runtime dependencies are declared: @babel/parser 8.0.4, @babel/types 8.0.4, @oxlint/plugins 1.81.0, oxc-resolver 11.24.2 and zod 4.6.6. A Bun lockfile is committed. Pinning aids reproducibility, not vulnerability assurance; native resolver/linter components and transitive packages remain supply-chain risks. The broad Oxlint peer range is not proof of future compatibility. [Manifest][manifest].

No install/postinstall script is declared in the package manifest. tsdown builds ESM/declarations and explicitly suppresses an experimental TypeScript 7 API warning. A development clean script deletes designated cache/build/node_modules directories; it is unnecessary for evaluation. No repository scripts were run.

CI uses SHA-pinned actions, a frozen install, then format, lint, types, build and tests with read-only contents permission. Release jobs separate selection/versioning/packing/publishing, disable checkout credential persistence, ignore install scripts and grant id-token write to publishing; package metadata requests provenance. Release runs separately from CI and does not visibly depend on its check job, so branch protection and registry trust settings still matter and were not audited. Published package contents/attestations were not downloaded or verified. [CI][ci]; [release][release].

## Tests, Evidence and Maturity

The repository was created 2026-10-28. Public metadata retrieved 2026-11-18 showed 302 stars, 2 forks and 7 open issues/PRs combined; latest reported push was 2026-11-17. Release @interfere/landmines@0.1.0 was published 2026-11-17. These are activity indicators, not safety guarantees.

All ten rules have dedicated test files, plus helper tests. Tests create temporary source fixtures, invoke actual Oxlint subprocesses, check output/status and clean up temporary directories. This is stronger integration evidence than mocked visitor tests alone; especially substantial fixture suites cover no-test-doubles and colocation. The [public CI run for the reviewed SHA](https://github.com/interfere-inc/landmines/actions/runs/44166848006) reports success. No tests were executed independently; install compatibility, runtime speed, memory use and cross-platform behavior were not measured. [Harness][harness].

No controlled study showing fewer agent-generated defects, representative precision/recall corpus, or performance benchmark methodology was found in the inspected repository. Fixtures demonstrate intended cases, not the universal “honest path” claim. Counterexamples above are reasoned from code, not presented as executed reproductions.

## Comparison and Practical Adoption

| Option | Best fit | Tradeoff |
|---|---|---|
| Selected Landmines rules | Oxlint teams wanting real-implementation/event-driven test policy | Useful diagnostics and count baseline; young framework-specific heuristics |
| ESLint with Vitest/Jest plugins | Existing ESLint teams needing conventional framework checks | Broader conventional test linting, not the same no-replacement policy |
| anti-slop | Complementary type-level coding-agent constraints | Different patterns; README recommendation, not independently reviewed here |
| Isolation plus integration/contract tests | Actual side-effect control and behavioral evidence | More infrastructure, establishes properties lint cannot |

Use a pinned project-local trial and select testing rules individually. Measure false positives against your framework/version mix; leave style/types off unless explicitly desired. Preserve legitimate integration-test budgets and readable failure bounds rather than deleting timeouts blindly. Protect lint policy from casual agent edits, review suppression comments, and retain independent behavioral checks. No server deployment or credentials are required for Landmines itself.

**Bottom line:** worthwhile engineering policy encoded as tooling, with good fixture-based tests and a useful adoption pattern. Not an assurance system for honest agents, safe networking or correct tests.

## Sources and Attribution

Implementation links are pinned to the reviewed SHA. Activity/release/issue observations are time-sensitive [public GitHub metadata](https://api.github.com/repos/interfere-inc/landmines); [release listing](https://github.com/interfere-inc/landmines/releases). Attribution: Interfere, Inc., interfere-inc/landmines, [MIT license][license]. No code was extracted.

[readme]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/README.md
[license]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/LICENSE
[preset]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/configs/recommended.json
[doubles]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/no-test-doubles.ts
[owner]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/lib/test-owner.ts
[structure]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/colocated-tests.ts
[exports]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/package-exports.ts
[allowlist]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/lib/allowlist.ts
[flake]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/no-flake-masking.ts
[poll]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/no-unsignaled-poll.ts
[msw]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/strict-msw.ts
[mswtests]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/strict-msw.test.ts
[sleep]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/no-fixed-sleep.ts
[names]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/test-file-names.ts
[comments]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/no-comments.ts
[types]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/no-explicit-return-types.ts
[manifest]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/package.json
[ci]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/.github/workflows/ci.yml
[release]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/.github/workflows/release.yml
[harness]: https://github.com/interfere-inc/landmines/blob/92084b12872103b0f9245c0325ab571df00a574b/packages/landmines/src/rules/rule.test-utils.ts
