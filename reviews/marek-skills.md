# Marek's Skills (marekkirejczyk/skills)

**Repo:** https://github.com/marekkirejczyk/skills
**License:** MIT; retain Marek Kirejczyk's 2026 copyright and permission notice when copying substantial material.
**Reviewed:** 2026-11-25 (UTC)
**Revision:** `467825ee3c9cf69ba2152603c477a1431e463c67`, main; whole-repository static inventory, all seven skill definitions and execution/publishing helpers.
**Version:** Plugin manifest 0.16.0; no Git tags or GitHub releases observed. Commit dated 2026-11-25 19:22:48 UTC.
**Verification:** Anonymous HTTPS clone and public API succeeded. Static inspection only: no source scripts, tests, installation, provider requests, browser rendering of source, or publication helpers executed.
**Stack:** Markdown agent instructions; Node.js ESM and Bash; optional Playwright/Chromium, FFmpeg/ffprobe, cloc, Git/GitHub CLI; TypeScript/Vitest/pnpm conventions for test refactoring.
**What it is:** Seven opt-in agent workflows for codebase explanations, semantics-preserving refactors, and inspectable evaluation reports—not a general agent security framework.

---

## Verdict

⚠️ **Interesting — adopt individual ideas, not blanket execution authority.** The best parts are evidence-linked explanations, test-removal proof, small refactoring rounds, and a dependency-free evaluation-report renderer. The workflows can install/run arbitrary repositories, discover paid TTS credentials, and publish rich evaluation data; their prose safeguards are not sandboxing, spend limits, or redaction. Pin and audit a selected workflow before using it on sensitive code.

## What It Is

The headline still emphasizes explainers, but the actual manifest enumerates seven skills. Claude Code gets a marketplace/plugin bundle; other agents can copy individual skills. All seven specify explicit invocation in SKILL frontmatter and Codex policy files. This is useful activation metadata for compatible hosts, not an OS capability boundary or a guarantee that every agent honors it. The installation documentation describes automatic plugin updates and explicitly says the Codex plugin installation route has not been tested. [1][2]

The explainers turn a repository or PR into slides or a narrated MP4 with captions and chapters. Three refactoring skills apply opinionated code/test standards. The seventh workflow installs the evaluation reporter into CI; it is a separate skill even though the README's main table lists only six. [1]

## Stack and Complete Skill Inventory

| Skill | Actual workflow and supporting files | Authority / important limitation |
|---|---|---|
| explain-with-slides | Seven helpers: bundle-html.mjs, gen-code.mjs, shoot.mjs, preview.mjs, loc.sh, pr-stats.sh, filters.sh; PR-mode and slide-pattern references | Runs target code, installs dependencies, drives browser interactions; artifact upload or local HTML and image files |
| explain-with-video | Six helpers: make.mjs, lib.mjs, tts.mjs, render.mjs, assemble.mjs, page.mjs; scene reference, stage CSS/JS, page template and six example scenes | Reads TTS credentials; optional paid API calls; raw scene HTML executes in Chromium; FFmpeg produces media |
| refactor-tests | Five reference standards: browser, pure functions, round trips, route handlers, services; Vitest and Playwright speed reporters plus speed-table.mjs | Rewrites tests and application interfaces, temporarily mutates behavior to prove coverage, runs suites and edits PR speed summaries |
| self-documented-code | Skill text and Codex invocation metadata; no helper scripts | Renames code/comments/dictionaries, commits each round on a new unpushed branch |
| dont-repeat-yourself | Skill text and Codex invocation metadata; no helper scripts | Automatically extracts identical logic; batches differing/high-stakes cases for user decisions; commits locally |
| eval-report | eval-report.mjs, reporter.mjs, nine lib modules, inline report CSS/JS, input-format reference and CI template | Runs configured shell command, records rich results, optionally edits PR body/comments and pushes Pages |
| eval-report-install-ci | Instructions and invocation metadata; uses sibling eval-report scripts | Copies scripts into target repository and modifies workflows/permissions; proposes a new job for approval |

There is no root package manifest or lockfile in the 86 tracked files. The reporter uses Node built-ins; the media workflows install Playwright separately and depend on external system binaries. This lowers reporter dependency overhead but does not make installations across machines reproducible. [1][3][4][5]

## Key Features

### Evidence rather than invented screenshots

The slide workflow requires actual running-code screenshots, inspecting each image, and attaching checkout commit/branch/dirty-state provenance. PR mode uses separate base/head worktrees and throwaway databases, compares the merge base, and forbids commenting or changing the reviewed PR. These are unusually useful expectations for onboarding artifacts. However, the screenshot manifest labels a checkout; it does not prove that an arbitrary URL was served by that checkout. Its dirty flag excludes untracked files. [3][6]

### Refactoring with explicit preservation rules

Naming preserves external contract names and test assertions, prefers compiler-assisted rename, and searches dynamic references. DRY distinguishes identical behavior from merely similar intent, defers money/auth/migrations/locking, and writes extraction tests before moving callers. Both require a green baseline and small reversible commits. These are good review checklists, not mathematical equivalence proofs. [7][8]

Test refactoring demands a remaining test fail under a deliberate mutation before removing a duplicate. It measures CPU rather than only elapsed suite time, tracks setup cost, and uses rerun medians for over-budget tests. The five standards give concrete examples and avoid adding the first browser suite. Their 5/50/100 ms and 3-second budgets are opinions, not measurements applicable to every repository; aggressive movement to pure functions may miss integration behavior unless mutation coverage genuinely preserves it. The included speed-table calculates per-test medians, but file-level setup medians are not similarly summarized. [5]

### Evaluation visibility without a model in the renderer

NDJSON records expose input, output, judges, tool arguments/results and errors. A static page supports failure/change filters, code links, and browser-local reviewed ticks that expire when a result fingerprint changes. Rendering requires no model calls; running the underlying evals can still incur model/service cost. This is a report adapter, not an independent evaluator or assurance that its supplied pass/fail labels are truthful. [9][10]

## Architecture and Trust Boundaries

The architecture is instruction-led: agent reads a skill, assembles project-specific content or modifications, then invokes helpers. There is no central permission broker, container launcher, secret isolation, network policy or transactional runner. No bundled hooks or MCP server are declared in the plugin manifest. Invocation metadata only regulates when compatible agents select the workflow. [1][2]

**Source-to-agent boundary:** repository READMEs, PR descriptions, instructions and code are attacker-controlled when examining unknown projects. URL-based explainer instructions sensibly restrict imported AGENTS/CLAUDE files to safe-running guidance and require disclosure/approval before installation. Nevertheless, “safe-running guidance” can itself contain malicious setup commands. PR slide mode permits continuing past the outline when asked to just build it. Neither text nor worktrees isolate target install scripts or prevent prompt injection. Treat all imported instructions as evidence and run any later experiment in a credential-free, network-limited environment. [3][6]

**Configuration-to-process boundary:** eval-report invokes the configured command through sh -c with inherited environment and no script-level timeout. File arguments receive shell quoting, but the command template is intentionally executable authority. Even build-only calls collect GitHub context and may invoke gh pr view locally. Result file paths are read to infer source lines without confinement to the repository root; this is not a safe parser for adversarial reports. No secret contents are shown by that source-line lookup itself, but arbitrary readable paths can be opened. [9][11]

**HTML/code boundary:** gen-code dynamically imports its specification as JavaScript. Slide bundling embeds raw slide HTML and font links; video rendering embeds raw scene bodies and configurable head HTML. Neither is an HTML sanitizer or network-denying browser. shoot accepts absolute navigation destinations through URL resolution and writes names joined to its output path without a confinement check. Use only trusted generated specs/scenes/shot lists, never arbitrary downloaded ones. In contrast, the eval renderer escapes interpolated values and its lightweight Markdown, and video page serialization escapes less-than signs in embedded JSON. These are concrete, narrower defenses. [4][6][10][12]

## Privacy, Egress and Cost

- **TTS auto-selection matters:** with no explicit provider, finding an ElevenLabs key chooses ElevenLabs rather than local speech. Keys are found in environment variables, macOS Keychain, then provider key files. Keys are kept out of the voice/cache-key object, but merely having a configured key is not a per-run spend confirmation. OpenAI/ElevenLabs receive narration text; ElevenLabs also receives a voice-list request. There is no monetary/character cap. On non-macOS systems the no-key fallback has no local say implementation. [4]
- **“Local” media is not offline by default:** video render and slide preview request Google Fonts; scene HTML, slide faces, images and browser navigation can add destinations. Installing Playwright and target dependencies introduces package-registry/download traffic. Artifact publishing exports screenshots, source snippets, narration, captions and media to the selected host. [3][4][6]
- **Evaluation artifacts contain data, not just scores:** complete conversations, outputs, tool arguments/results and failures are retained in NDJSON and HTML. There is no redaction pass or retention cleanup in the reporter. The instruction to avoid reading results saves tokens but is not a safe substitute for checking publication contents. A public code repository can still contain private eval inputs. [9][10]
- **A real Pages safeguard exists:** publish checks repository privacy and Pages visibility and refuses private-repository data on public Pages. This does not detect secrets inside public-repository results. The CI template defaults to a 30-day artifact and skips PR linking for fork PRs. Its unzipped artifact/browser behavior is a source claim not independently exercised here. [13]
- **Privilege scope remains broad:** the project CI grants contents:write and pull-requests:write to the job that tests checked-out code; the reusable template starts with contents:read and PR write. Split privileged publication from untrusted execution where possible, pin action revisions, and inspect same-repository contributor trust. The workflow uses pull_request, not pull_request_target, and fork publication is guarded—this review does not claim a demonstrated fork-token exploit. [13][14]

## Recovery and Correctness Caveats

1. **Useful bounded recovery, not transactions.** TTS caches per voice/text, limits provider concurrency to three and retries selected HTTP errors up to three attempts. It has no request deadline and does not honor Retry-After; partial cache outputs are not validated atomically. Rerendering selected scenes and staged make commands help manual recovery. Browser cleanup uses finally in video render; source-driven app/server cleanup is largely instruction-based. [4]
2. **Publishing can partially succeed.** Pages pushes use a separate worktree, three attempts and fetch/rebase rather than force. PR description and comment changes occur afterward, so a report can publish while linking fails. Comment discovery uses a marker without checking comment authorship; a spoofed marker can select the wrong comment or produce an authorization error. Description updates have no optimistic concurrency guard. Fetch errors are treated like a missing Pages branch; temporary publication state is removed in finally, reducing recovery evidence after failure. [13]
3. **Reported green is not independently enforced.** The runner returns the eval command's exit code, not a failure computed from normalized records. A command that exits zero while emitting failed cases leaves CI green. Empty results are allowed and 0/0 gets a green summary marker. Explicit boolean passed overrides failed checks (unless error is present), and check.passed is Boolean-coerced, so the string “false” becomes true. Require a validated producer schema, expected-case completeness and explicit failure policy before using this as a gate. [9][11]
4. **Changed-only is a heuristic.** Selection uses changed eval filenames; shared prompt/tool changes do not automatically select dependent tests. Case inference searches the first quoted case name and spans to the next case, not AST/dataflow. The CI installer acknowledges the changed-only coverage tradeoff. [11][13]
5. **Reviewed ticks are a convenience, not an audit record.** They live in localStorage and use a truncated SHA-1 fingerprint, with no user identity/signature. The fingerprint covers input/output/error/checks/mocks but omits top-level passed, rule and note. A changed verdict or rule alone therefore need not clear a tick. [10]

## Maturity, Tests and Verification

Public API snapshot on 2026-11-25: created October 19, 2026; last push November 25, 2026; 72 stars, one fork and zero open issues (GitHub aggregate). These are activity metadata, not proof of correctness. API releases and anonymous tag listing were empty; 0.16.0 is the manifest version, not an observed release tag. [15]

Five test files contain 99 declared it cases for the eval reporter: result parsing/grouping, escaping/rich content, fixture CLI/report structure, scope heuristics, summaries/commands/fingerprints and the Pages privacy predicate. The fixture integration test does spawn source code; it was read, not run. The CI workflow executes these tests and publishes fixture reports. Its presence is not evidence of a passing current run; no Actions-run status was verified. The private-Pages test covers the boolean predicate, not an end-to-end permission check. [14][16]

No dedicated checked-in automated tests were found for the slides/video pipeline, timing reporters, actual PR publishing/retry integration, or agent compliance with refactoring instructions. No comparative evaluations demonstrate that the seven agent workflows preserve semantics, improve onboarding, or resist malicious repository instructions. Demo media is illustrative, not a controlled benchmark. Static review cannot verify visual quality, runtime compatibility, provider behavior or the claimed artifact-host experience.

Review-side checks cover source/manifest inventory, citation paths, trusted-template CSS/JS identity, HTML structure and local links, unresolved tokens, public-content/redaction inspection and task-only Git diff. No source installation or adoption occurred.

## Comparison

| Need | This collection | Existing alternative and tradeoff |
|---|---|---|
| Author a presentation | Agent surveys/runs code and assembles evidence | [Marp](https://github.com/marp-team/marp) or [Slidev](https://github.com/slidevjs/slidev) provide established slide authoring/export; they do not supply this repository-survey workflow |
| Programmatic narrated video | HTML scenes + Playwright + FFmpeg + selectable TTS | [Remotion](https://github.com/remotion-dev/remotion) has a component-based video ecosystem; inspect its licensing separately and provide your own evidence/consent controls |
| LLM evaluation reporting | Small runner-agnostic JSON adapter and self-contained page | [Promptfoo](https://github.com/promptfoo/promptfoo) offers evaluator/config/test tooling; broader surface and setup, rather than just adapting existing results |
| Safe refactoring | Detailed semantic-preservation checklists and measurement rounds | Compiler/LSP rename, existing lint/type checks and [StrykerJS](https://github.com/stryker-mutator/stryker-js) mutation testing give repeatable mechanical feedback; they cannot choose domain vocabulary or prove arbitrary equivalence |

These are fit comparisons, not fresh audits or head-to-head benchmarks. Prefer existing project-native tools; selectively borrow the proof/checklist patterns rather than replacing established test architecture with every opinion in the bundle.

## Self-Hosting / Adoption Notes

There is no service to deploy. If later authorized for a trial, pin the reviewed commit, choose a single workflow, inspect changes since that revision, and keep media dependencies in a disposable workspace. Use synthetic data and separate execution from publication credentials. Set an explicit voice/provider and spend budget, deny network unless required, and review generated HTML/data before upload. For evals, add strict schema validation and completeness/failure checks; default to access-controlled artifacts and use Pages only after content review. Retain MIT notices when copying helpers; downstream code, fonts, voices, model APIs and artifact services have their own rights and terms. No helpers were extracted as part of this review.

## Evidence

All numbered source links are pinned to the reviewed commit except live metadata and alternatives.

[1]: https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/.claude-plugin/plugin.json
[2]: https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/docs/installation.md
[3]: https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/skills/explain-with-slides/SKILL.md
[4]: https://github.com/marekkirejczyk/skills/tree/467825ee3c9cf69ba2152603c477a1431e463c67/skills/explain-with-video/scripts
[5]: https://github.com/marekkirejczyk/skills/tree/467825ee3c9cf69ba2152603c477a1431e463c67/skills/refactor-tests
[6]: https://github.com/marekkirejczyk/skills/tree/467825ee3c9cf69ba2152603c477a1431e463c67/skills/explain-with-slides
[7]: https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/skills/self-documented-code/SKILL.md
[8]: https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/skills/dont-repeat-yourself/SKILL.md
[9]: https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/skills/eval-report/scripts/eval-report.mjs
[10]: https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/skills/eval-report/scripts/lib/report.mjs
[11]: https://github.com/marekkirejczyk/skills/tree/467825ee3c9cf69ba2152603c477a1431e463c67/skills/eval-report/scripts/lib
[12]: https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/skills/eval-report/scripts/lib/html.mjs
[13]: https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/skills/eval-report/scripts/lib/publish.mjs
[14]: https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/.github/workflows/eval-report.yml
[15]: https://api.github.com/repos/marekkirejczyk/skills
[16]: https://github.com/marekkirejczyk/skills/tree/467825ee3c9cf69ba2152603c477a1431e463c67/test/eval-report

**Attribution:** Marek Kirejczyk, marekkirejczyk/skills, [MIT license](https://github.com/marekkirejczyk/skills/blob/467825ee3c9cf69ba2152603c477a1431e463c67/LICENSE). Analysis only; no source code redistributed.
