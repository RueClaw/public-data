# Modern Web Guidance (GoogleChrome/modern-web-guidance)

**Repo:** https://github.com/GoogleChrome/modern-web-guidance
**Source type:** Published agent-skill/web-guidance distribution, not the development repository.
**Author:** GoogleChrome; stated stewardship includes Chrome, Edge, Firefox, MDN and the web community.
**License:** Apache-2.0 software; README specifies CC BY 4.0 documentation/guide content, including credited MDN and standards material. Preserve applicable notices/attribution.
**Reviewed / retrieved:** 2026-11-14 UTC
**Revision:** 4dd968349e54ca45a05dd5c818fb035c9054b022 (v1.0.0; 2026-11-10), README, manifests, both skills, representative generated guides and extension references.
**Supporting implementation:** [GoogleChrome/modern-web-guidance-src](https://github.com/GoogleChrome/modern-web-guidance-src) at 5e5cd33a7738f21281e3027732bcbd58cfa82bf1 (2026-11-14 UTC). This newer snapshot is not asserted to be byte-identical to the v1.0.0 npm package.
**Verification:** Static source review and public documentation cross-checks. No source execution, installations, browser/device testing, model downloads or paid evaluations.
**Stack:** Markdown; Node.js CLI; TypeScript search/build/scanner/evaluation tools; Playwright; generated browser compatibility data.

## Verdict

⚠️ **Interesting — useful modern-platform reference, not an unquestioned coding policy.** Focused retrieval, concrete fallbacks and inspectable evaluations are materially better than a generic “use modern CSS” prompt. Pilot the main guidance selectively with pinned tooling and an explicit browser policy. Correct the extension pack’s origin/CSP and permission advice before security-sensitive use; default-on query telemetry and mutable installation paths also need deliberate approval.

## What it is

Modern Web Guidance counters coding models’ preference for old JavaScript workarounds by retrieving task-specific native-platform recipes. The README advertises 203 use cases and 250 features; the checkout contains 209 Markdown files under the main guide tree, so the headline is not a literal file count. Coverage includes CSS/layout, components, forms, accessibility, performance, security/privacy, built-in AI and web components. A separately selectable Chrome Extensions skill covers Manifest V3 and store preparation.

This repository is explicitly a **publish target**. Contributions, implementation, source guides, tests and evaluations live in the -src repository. The Git distribution omits executable bundles: its manifest names skills/modern-web-guidance/modern-web.mjs, but that file is absent. The supporting publication script intentionally excludes JS/TS/binary artifacts from Git; the skill instead invokes npm. Cloning this repository is not a runnable CLI installation. [1][2]

## Architecture and agent workflow

| Layer | Observed design | Consequence |
|---|---|---|
| Routing | Search before client-side tasks; excludes backend/tooling | Broad mandatory language must remain subordinate to project scope/approvals |
| Retrieval | Short English capability queries; compact IDs/descriptions | Limits context load; weak results get one rephrase, then list/continue |
| Search | Local static embeddings plus BM25 and reciprocal-rank fusion | Ordinary search needs no hosted inference in inspected implementation; build-time embeddings are separate |
| Large output | Retrieval over 9.5 KB spills to temporary Markdown | Useful truncation defense if the consumer finishes reading |
| Compatibility | web-features/MDN-derived prose, dates and Baseline settings | Better than model memory; not a target-browser acceptance test |
| Modernization | Static local scanner, guide IDs and keep/drop rubrics | Findings are leads; documented coverage is roughly 20% |
| Experimental APIs | Origin Trial/volatile metadata gated by project opt-in | Helpful convention, not isolation from a file-capable agent |

The skill distinguishes feature fixes from broad modernization, warns against forcing unrequested features, and says not to remove legitimate fallbacks merely to get zero scanner findings. It asks for guide-backed explanations, SSR guards and per-instance IDs. Casting new attributes to any or raising a bundler target to esnext are escape hatches, however, not compatibility checks. English-oriented retrieval and finite vocabulary are practical limits. [3][4]

The newer implementation rejects detected agent environments/noninteractive stdin for experimental opt-in commands and requires human confirmation. Retrieval respects explicit opt-out. Conversely, the baseline: limited banner tells agents to skip all compatibility fallbacks in a guide. That is appropriate only for an intentionally restricted runtime, not arbitrary public-web audiences. [4]

## Technical accuracy and interoperability

### Strong progressive enhancement, with dated boundaries

The drawer guide distinguishes modal dialog from sidebar-capable popover, supplies naming/focus/inert handling, respects reduced motion and separately treats scroll timelines, initial scroll position and registered-property fallbacks. The scheduler guide includes a timer fallback. Sanitization guidance covers native/fallback configuration parity, mutation XSS and Trusted Types. These are substantive details. [5][6][7]

Compatibility must stay dated and capability-specific:

- The drawer guide calls scroll-driven animations **Newly available since 2026-10-27**. The independently fetched Web Features Explorer agrees, with **2029-04-27** expected for Widely Available. Newly available does not mean older customer browsers support it.
- Scheduler is **Limited**, supported in Chrome/Edge 129 and Firefox 142, not Safari. The Explorer independently agreed on review day.
- Guides separately label scroll-initial-target, Speculation Rules, Sanitizer and LanguageModel. Do not flatten that into “all modern browsers.” LanguageModel’s Chrome 148 claim is source-reported here, not independently device-tested.
- The encryption guide leads with hybrid post-quantum KEMs while listing Web Cryptography’s broad Baseline date of 2017-09-19. That does not establish support for encapsulateKey, new key formats or SubtleCrypto.supports. The guide provides detection and a classical fallback, but X25519 is not post-quantum equivalent. Authenticate recipient keys and negotiated suites; this is not a complete audited end-to-end protocol. [8]

Origin trials, volatile/single-engine APIs and emerging proposals require explicit product decisions even when search finds a guide. Define minimum versions, test precise capabilities and run the real cross-engine matrix. A snapshot is not an evergreen guarantee. [9]

### Accessibility and performance

The error-announcement guide covers delayed validation, preserved descriptions, one polite live region, failed-submit focus and reset handling. AI guidance includes named download progress, output language and session cleanup. Native controls and automated role checks still do not establish WCAG compliance: keyboard, zoom, forced colors, touch and actual screen readers remain acceptance work. [10][16]

A concrete counterexample is the privacy guide’s video façade: an image with a click listener is used as the play control, without button semantics or keyboard activation. It also fetches a YouTube thumbnail before the click. The façade defers the iframe, **not all third-party contact**. Use a named button and a first-party/approved thumbnail where pre-consent egress matters. [11]

Yielding long work is sensible, but checking a 50 ms deadline after processItem cannot bound one expensive item or guarantee an INP/frame-time outcome. Measure actual workloads and consider smaller units/workers. Speculation advice discusses stale content, bandwidth/server costs, logout/cart exclusions and prefetch before prerender. Its all-link examples require those exclusions; ignored unsupported rules provide graceful degradation, not universal operational safety. [6][12]

### Security: correct the extension pack before relying on it

**Incorrect isolation claim:** the CSP reference says blob URLs and srcdoc create separate origins and bypass extension CSP; the main extension skill repeats the blob claim. The shown alternatives do not establish sandboxing. MDN documents unsandboxed srcdoc as same-origin with its parent, while blob URLs contain their creator’s origin. Neither is an automatic security boundary or generic CSP bypass. Use explicitly sandboxed execution with restricted communication/egress. The supplied sandbox receiver also executes event.data.js without checking source or message shape. This is a static documentation finding, not an exploit demonstrated against a running extension. [13][14]

**Overbroad permission advice:** the skill/reference say tab.url and tab.title require tabs permission. Chrome’s documentation explicitly permits matching host permissions; activeTab supplies temporary host permission after eligible invocation. A side-panel button does not mint that grant, but that differs from saying existing grants cannot be used there. The reference’s proposed fix shows all_urls while saying to scope hosts. Prefer narrow host, temporary or optional permissions. [15]

**Persisted state is not a lock:** the recording example separately awaits a storage read and writes starting. Concurrent handlers can both read idle before either write finishes. The counter example is also non-atomic read-modify-write. Persistence across suspension does not supply serialization, exclusive admission or reconciliation with a real capture resource. These examples do not prove race-free capture. [3]

### Privacy and vendor framing

Data minimization, scoped permissions, session-cookie flags, audits and deletion controls are sound themes. But age buckets are not differential privacy, Clear-Site-Data is not server-side session revocation, and local inference does not “ensure user privacy” for the entire app. The AI guide suggests Vertex AI Gemini as a remote fallback: moving local processing to cloud changes disclosure, consent, retention, credentials and cost. Do not silently cross that boundary. [11][16]

Multi-vendor stewardship and MDN/web-features inputs temper Chrome bias, but do not erase incentives toward native adoption, Chrome-only capabilities and Google-hosted examples. AI guidance even suggests artificial 1–2 second delays to make output seem more trustworthy: UX advice, not measured reliability, and no substitute for honest uncertainty or responsiveness. [16]

## Installation, updates, dependencies and data flow

Search is local, but the inspected telemetry logger is **enabled by default**. It records query text, returned guide IDs/similarities, agent, OS, versions, latency bucket and success; retrieval records guide IDs. A detached Node watchdog posts to Google Clearcut. DISABLE_TELEMETRY=1 or true disables this logger; optional file logging has a separate gate. “Raw user prompts are not collected” is narrower than “no sensitive information leaves”: generated queries can reveal task details, and the logger has no query redaction. Keep queries generic and choose opt-out before first use. [17]

The skill invokes npx -y modern-web-guidance@latest. Its skill-version argument identifies freshness, **not an executable pin**. Install delegates to separately fetched npx skills add; update/remove also use that external installer. Plugin auto-update and the documented Grok trust flag add trust decisions. Wildcard approval for all MWG subcommands also covers configuration/install operations, not only search. Pin reviewed artifacts and scope command permissions. The external installer and npm/Git build equivalence were not audited. [3][18]

The source tree has a pnpm lockfile and more dependencies than published manifests suggest: Playwright, TypeScript/esbuild, parsers, browser datasets, cloud/storage and model/agent tools. Its postinstall deletes enumerated stale build/cache directories. Embedding generation/evaluation runners can call paid providers/agents; none is necessary to read Markdown. No dependency vulnerability audit or npm integrity verification was performed. [19]

## Evidence, tests and maturity

v1.0.0 was published 2026-11-10. Public metadata showed 11,363 stars and 397 forks on review day; issue reporting goes to the source repository. Popularity is not safety evidence. The supporting snapshot has 156 tracked test.ts files, separate guide graders and SHA-pinned CI actions. CI defines frozen-lockfile install, build/typecheck/lint/unit checks, publication dry-run, retrieval benchmarks and browser-backed checks. These are inspected definitions, **not tests run here or proof of green latest CI**. [1][20]

The README’s Nov 8 snapshot reports unguided → guided assertion pass rates of 58% → 94% for Antigravity, 54% → 82% for Codex and 57% → 88% for Claude Code: project-reported **+36/+28/+31 percentage points**, not independently reproduced results or fully correct-app percentages. Task/assertion totals differ across agents.

The public dashboard says pass rate is checks passed/checks run, paired infrastructure errors/timeouts before grading are excluded, and automated accessibility checks are not a full WCAG audit. Methodology was accessible; numeric cards required JavaScript and were not independently loaded in this static review. [21]

The scheduler grader includes runtime checks and an absent-scheduler test, but also a synthetic clock, patched yield/timer functions and an explicit scheduler.yield expectation. This can reward the chosen recipe rather than all valid performance solutions. The shared fixture launches Chromium; simulated missing APIs are not Firefox/Safari testing. Golden/base calibration is valuable regression protection, not independent held-out validation of the authors’ preferred design. [22]

## Alternatives and practical adoption

| Option | Best use | Trade-off |
|---|---|---|
| MWG | Compact task-specific agent recipes | Uneven assertions, mutable tool path, telemetry |
| [MDN](https://developer.mozilla.org/) + [Web Features Explorer](https://web-platform-dx.github.io/web-features-explorer/) | API contracts and dated interoperability | More manual synthesis |
| [WAI ARIA APG](https://www.w3.org/WAI/ARIA/apg/) + assistive-tech tests | Accessible widget behavior | Requires real implementation/user verification |
| [web.dev](https://web.dev/) + lab/field measurement | Performance diagnosis and education | Less compact; workload-dependent |
| [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/) + Chrome docs | Security boundaries and permissions | Less novelty-driven; preferable for high-stakes decisions |

Adopt a narrow main-skill pilot, record browser policy, pin tooling, decide telemetry, retrieve relevant guides and test native/fallback paths. Keep a functional baseline without optional visual/AI features. Cross-check security examples and explicitly approve local-to-cloud transitions. No server/database needs self-hosting for the guidance; offline Markdown is the lowest-risk path.

## Verification limits

Representative, not exhaustive: both skills/manifests; drawer, scheduler, speculation, error-announcement, privacy, sanitizer, encryption and LanguageModel; extension CSP/permissions; newer CLI/retrieval/search/telemetry/gates/build/CI and scheduler grader. No repository instructions were adopted. No source tests, browser matrix, screen readers, installs or model evaluations ran. Only the two noted compatibility records and origin/permission semantics were independently checked; other version claims remain source-reported. Development source is newer than the distribution; npm artifacts were not acquired/attested.

## Sources

Repository links are revision-pinned; external documents fetched 2026-11-14 UTC.

1. [README](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/README.md), [release](https://github.com/GoogleChrome/modern-web-guidance/releases/tag/v1.0.0).
2. [Manifest](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/package.json), [publication filters](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/build/publish-skills.ts).
3. [Main skill](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/modern-web-guidance/SKILL.md), [extension skill](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/chrome-extensions/SKILL.md).
4. [Retrieval](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/rag/retrieve.ts), [opt-in](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/cli/set-allow-gate.ts), [search](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/rag/search.ts).
5. [Drawer](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/modern-web-guidance/guides/ui-components/navigation-drawer.md).
6. [Scheduler](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/modern-web-guidance/guides/performance/break-up-long-tasks.md).
7. [Sanitizer](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/modern-web-guidance/guides/security/sanitize-untrusted-html.md).
8. [Encryption](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/modern-web-guidance/guides/security/client-side-encryption.md).
9. [Scroll timelines](https://web-platform-dx.github.io/web-features-explorer/features/scroll-driven-animations/), [Scheduler](https://web-platform-dx.github.io/web-features-explorer/features/scheduler/).
10. [Error announcements](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/modern-web-guidance/guides/accessibility/accessible-error-announcement.md).
11. [Privacy](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/modern-web-guidance/guides/privacy/privacy.md).
12. [Speculation](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/modern-web-guidance/guides/performance/improve-next-page-load-performance.md).
13. [CSP](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/chrome-extensions/references/extensions/csp-sandbox.md).
14. [MDN srcdoc](https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement/srcdoc#security_considerations), [blob origins](https://developer.mozilla.org/en-US/docs/Web/URI/Reference/Schemes/blob).
15. [Permissions](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/chrome-extensions/references/extensions/permissions.md), [Chrome Tabs](https://developer.chrome.com/docs/extensions/reference/api/tabs#permissions).
16. [LanguageModel](https://github.com/GoogleChrome/modern-web-guidance/blob/4dd968349e54ca45a05dd5c818fb035c9054b022/skills/modern-web-guidance/guides/built-in-ai/language-model.md).
17. [Telemetry](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/cli/telemetry/clearcut-logger.ts), [sender](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/cli/telemetry/watchdog/clearcut-sender.ts), [file logging](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/rag/logger.ts).
18. [CLI](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/cli/modern-web.ts).
19. [Dependencies](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/package.json), [postinstall](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/core/postinstall.ts), [search architecture](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/rag/README.md).
20. [CI](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/.github/workflows/ci.yml), [metadata](https://api.github.com/repos/GoogleChrome/modern-web-guidance).
21. [Dashboard](https://googlechrome.github.io/modern-web-guidance-src/).
22. [Grader](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/guides/performance/break-up-long-tasks/grader.ts), [fixture](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/grading/test-fixture.ts), [harness](https://github.com/GoogleChrome/modern-web-guidance-src/blob/5e5cd33a7738f21281e3027732bcbd58cfa82bf1/src/harness/README.md).

---

**Attribution:** GoogleChrome/modern-web-guidance and GoogleChrome/modern-web-guidance-src. Apache-2.0 software; CC BY 4.0 guide documentation as declared, including credited MDN/standards material. Independent analysis, not upstream endorsement.
