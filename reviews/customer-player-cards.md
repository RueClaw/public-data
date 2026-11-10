# Customer Player Cards (jonzobrist/customer-player-cards)

**Repo:** https://github.com/jonzobrist/customer-player-cards
**License:** MIT; preserve copyright and permission notices on substantial reuse.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** 6ff4c1e657e944b91d11fd38295d140b8ff38b8f; whole repository, emphasizing authored mockup code, build files, docs and backend specification.
**Verification:** Static review only. Anonymous GitHub page/API confirmed public availability before acquisition. No source execution, installs, builds, provider calls or live security probes.
**Stack:** Implemented: React 18.3.1, TypeScript 5.6.3, esbuild 0.24.0, standalone HTML. Proposed: Fastify, Postgres 16, Redis 7, SSE and Salesforce/incident-tool adapters.
**What it is:** A customer-success dashboard concept, fictional-data interactive mockup and agent-build specification—not a working CRM integration.

---

## Verdict

📚 **Study — a useful design brief, not a production customer dashboard.** It connects commercial health, incident impact, SLA urgency and audience-specific next actions through a coherent visual vocabulary. Authentication, server authorization, ingestion, persistence and recovery remain requirements; even the mock risk logic and accessibility behavior do not fully match the specification.

Use it for stakeholder interviews and UI exploration with fictional data. Do not insert real records into the current HTML and assume the audience selector protects them.

## What It Is

Five styles—trading card, scoreboard, RPG sheet, wallet stack and roster heatmap—present fictional customer status for six audiences: executives, account teams, service owners, leaders, engineers and support. Long-term health is distinct from immediate risk. Glance, detail and drill-in form a sensible progressive-disclosure model.

The README explicitly calls this a concept/specification repository. Inspection agrees: imported constants feed React components; local state controls customer, audience, sort and label choices. The build embeds React and application JavaScript into a single HTML file. The theme hook's name does not imply an AI service: it returns local color/font tokens. [1][2]

## Stack

| Layer | Actually present | Proposed, not implemented |
|---|---|---|
| UI | React/React DOM, strict TypeScript, inline styles/SVG | Vite or Next.js, Tailwind, Framer Motion, Radix UI |
| Build | esbuild, npm lockfile, generated HTML | Application/service workspace |
| Backend | None | Fastify API and ingest workers |
| Data | Fictional constants bundled into HTML | Postgres snapshots/history; Redis cache/Streams |
| Access | No login or protected records | OIDC groups, record permissions, field allowlists |
| Live updates | Visual pulse timer, not live data | CDC, webhooks, SSE |

## Key Features

- **Concrete design alternatives:** roster sorting, customer selection and audience previews make the brief useful for interviews rather than just aspirational prose.
- **Explainability-first scoring:** five weighted components, explicit override rules and link confidence are a good starting specification. The weights are heuristics, not validated churn predictions.
- **Redundant visual signals:** glyphs, text and color differentiate risk. Plain-label switching reduces the RPG metaphor's learning cost.
- **Integration discipline on paper:** explicit incident links precede tenant/service matching; time proximity alone is disallowed. Secrets-manager storage, signed webhooks, read-only access, freshness indicators and mocked tests are specified, not implemented. [3][4][5]

## Architecture and Implementation Gaps

### Current implementation

The main.tsx entry point renders all styles and passes the same full customer object into AudienceCard. Most presentation and fixtures live in components.tsx; prompts.ts duplicates specification text and audience metadata. This is convenient for a concept, not a production domain boundary. The build inlines a minified bundle and escapes closing script sequences. [2][6]

### Risk rules are only partially implemented

The riskOf function computes the weighted rounded sum plus an optional floor of 80. It lacks the documented breached-SLA floor of 70, executive-escalation increment, general input validation and final cap for arbitrary inputs. The caller infers the floor from any SEV1 plus a top P1 case rather than verifying the required explicit case/incident link. Components are prefilled examples rather than computed from source signals. Extra roster tiles have manually assigned scores, including a breach-labeled tile below the documented breach floor. These are mock/spec inconsistencies, not vulnerabilities in a nonexistent production risk service. [2][4]

Before adopting the scorer, implement one shared pure package; validate finite inputs/ranges; define missing and stale signals, rounding and override order; test every boundary; and calibrate against outcomes. Keep commercial importance and operational urgency inspectable independently.

### Accessibility is a target, not certification

Labeled glyphs, focus styling and initial reduced-motion detection are present. Custom button-like cards handle Enter but not Space; radio-like audience controls lack arrow-key navigation. Reduced motion stops the pulse at mount but does not implement the specified double border or observe later preference changes. No supplied axe/Playwright tests or verified contrast/responsive results establish the documented accessibility targets. Static SLA strings are not a live countdown. [2][7]

## Customer Data, Privacy and Security

### Actual collection, storage, export and retention

The mounted mockup contains no customer import/upload, network fetch, authentication flow, analytics client, database or browser-storage use in the inspected authored code. Records are explicitly labeled fictional; no individual records are reproduced here. UI selections exist in React memory and reset on reload. Bundled data persists in the HTML and copies or browser caches.

There is no implemented CSV/PDF export, deletion workflow or retention engine. A prompt-copy component exists in source but is not exported/mounted by this page; it is not customer export functionality. Ordinary screenshots, browser printing and copying can retain displayed content. Sharing a real-data HTML variant would share the entire dataset, regardless of selected audience. [1][2][6]

### Authentication, authorization and tenant boundaries

No login, server, record-level enforcement or tenant isolation exists today. The engineer preview omits commercial fields from its selected presentation, **not** from the browser payload: the full object is passed to it, and commercial views remain on the same page. Text claiming those fields are “not sent” describes the intended system, not the mock boundary. This is acceptable for fictional fixtures but must not become the production security design. [2]

The proposed service specifies OIDC group mapping, a Salesforce read-only integration user, server-side field filtering, per-user queries where exact sharing rules must apply, masked wall displays and audits. Still needed: deny unauthorized requested views; enforce record access on detail, timeline, event and SSE routes; use permission-aware caches; handle stream revocation; define export controls and organization isolation. An operational tenant identifier for incident correlation is not an authorization boundary. [3][5][8]

### Input, rendering and upload security

Authored components render strings through React JSX rather than raw HTML. No application dangerouslySetInnerHTML, eval or raw-HTML injection path was found; there is no upload surface to assess. This narrow finding is not a complete XSS/dependency audit. Future case text, external runbook/dashboard URLs and webhook fields require type/size validation, safe URL schemes and rendering rules. Production ingress needs replay protection, request limits, rate limiting and explicit CORS/session policy; no implementation is available to verify. [2][5]

### Planned sensitive-data lifecycle

The proposed model copies commercial figures, opportunity/renewal data, contact/owner identity, case subjects/timelines, sentiment, SLA state, tenant mappings and incident context into new stores. Read-only source access does not remove the governance burden of those copies.

The docs specify **90-day audit retention**, not comprehensive customer-data retention. Snapshot/history, cache, replay/dead-letter payload and backup lifetimes and deletion processes remain unspecified in the reviewed design. Regional residency is mentioned, not enforced. Define minimization, source-deletion propagation, backup expiry, encryption/key ownership and access reviews before real ingestion. Stable account IDs in logs still need protection; omitting names does not make IDs anonymous. [3][5][8]

## Credentials, Network Flows and Costs

The current mockup requires no API key/account and makes no Salesforce, AI/model or other provider runtime calls in the inspected application. Rebuilding downloads npm dependencies. The screenshot helper requires Chrome/Chromium and invokes it with --no-sandbox; it was not executed and should not be used for untrusted browsing. [6]

The planned integration uses Salesforce OAuth JWT bearer credentials in a secrets manager, a dedicated read-only user, REST/Composite or Bulk backfill, Pub/Sub CDC and SLA polling. PagerDuty, ServiceNow, status/monitoring webhooks, optional alerts and telemetry introduce more trust boundaries. Source API entitlements and quotas, polling/event volumes, database/cache hosting and telemetry retention determine cost; there is no validated cost model. The 20%-of-daily-Salesforce-allowance budget is a design target, not measured compliance. Generated summaries are a later roadmap item, not an embedded LLM feature. [3][5][8]

## Persistence and Recovery

The mockup has no mutable customer store to recover: reload reconstructs fixtures and resets UI state. Stored CDC replay IDs, nightly resync, deduplication, backoff and dead-letter queues are sensible future requirements. They do not prove gap-free/exactly-once recovery: replay expiry, ordering, transactional publication, resync reconciliation, migration rollback and database restores still need implementation and tests. No deployable Compose stack, migrations or restore runbook is supplied. [3][5]

## Maturity, License and Verification

- The reviewed SHA is the initial concept commit dated **2026-11-10**. Public metadata that day reported **0 stars, 0 forks**, last push **13:12:35 UTC**. These indicate age, not quality.
- CHANGELOG.md labels the material 0.1.0, but the public releases endpoint returned an empty list. A changelog label is not proof of an available GitHub release. [9]
- **Application CI is parked.** The file is in .github/ci-pending/, not .github/workflows/. It would lint docs, check links, typecheck/rebuild the mockup and validate HTML when activated. Unit/integration/accessibility jobs are commented placeholders. Public Actions metadata showed Dependabot activity, not proof these application checks ran. [10]
- The manifest offers build/typecheck/screenshot scripts but no test script; no test suite was found. Strict TypeScript, pinned versions and a lockfile help reproducibility but do not validate runtime behavior. Dependabot is configured, and a public dependency-update PR was visible. No vulnerability advisory audit or fresh build was performed. [6]
- MIT terms were inspected. Preserve project and third-party notices on redistribution. The build uses legalComments: "none", so audit bundled dependency notices rather than assuming the standalone file is a complete license-notice package. No source components were extracted. [6][11]

**Limits:** Anonymous acquisition, tracked-file inventory, authored-code inspection, targeted network/storage/raw-HTML searches and spec/code comparison only. No source execution, build, typecheck, tests, browser rendering, screen-reader checks, provider integration, recovery tests, exhaustive secret/history audit or deployment. The checkout was shallow; findings concern this revision, not all history.

## Comparison and Existing Options

| Option | Fit | Tradeoff |
|---|---|---|
| This concept | Interviews and exploration of incident-driven customer cards | No operational backend or access controls |
| Existing Salesforce dashboards/account pages | Start with already-authorized CRM data/sharing | Cross-tool correlation and custom presentation still need work; assess within existing entitlement |
| [Grafana OSS](https://github.com/grafana/grafana) | Established operational dashboards | Customer model, joins and commercial-data authorization remain custom |
| [Apache Superset](https://github.com/apache/superset) | Analytics over a governed warehouse | ETL, authorization and low-latency incident workflows remain separate work |

These are architectural comparisons, not hands-on benchmarks or purchase recommendations. First assess an existing dashboard plus a small governed customer/service mapping. A bespoke ingestion and authorization platform is much larger than the card UI.

## Self-Hosting Notes

For a **fictional-data demo**, the checked-in mockups/index.html is intended to open directly in a JavaScript-enabled browser without a build or runtime network dependency. Node/npm are needed only to rebuild; documented commands are npm ci, npm run typecheck and npm run build in mockups/. None was run here.

There is no production server to self-host. A real pilot requires a supported runtime/dependency baseline, source permissions, validated mappings, authenticated per-record/per-field APIs and streams, retention policy, tested risk logic, recovery procedures and activated CI. Revisit the proposed Node 20 baseline against supported runtimes instead of copying it mechanically.

## Evidence

Source links pin the reviewed SHA; API metadata was retrieved 2026-11-10.

1. [README/scope](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/README.md)
2. [Components](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/mockups/src/components.tsx), [entry point](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/mockups/src/main.tsx), [theme shim](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/mockups/src/shim.tsx)
3. [Data model](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/docs/data-model.md)
4. [Risk requirements](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/docs/risk-score.md)
5. [Backend specification—not backend code](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/prompts/backend.md)
6. [Manifest](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/mockups/package.json), [build](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/mockups/build.mjs), [screenshot helper](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/mockups/screenshot.mjs), [mockup README](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/mockups/README.md)
7. [Visual/accessibility rules](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/docs/visual-rules.md)
8. [Audience policy](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/docs/audience-views.md), [build plan](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/docs/build-plan.md), [security/telemetry requirements](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/AGENTS.md)
9. [Changelog](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/CHANGELOG.md), [repository metadata](https://api.github.com/repos/jonzobrist/customer-player-cards), [releases](https://api.github.com/repos/jonzobrist/customer-player-cards/releases)
10. [Pending CI explanation](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/.github/ci-pending/README.md), [workflow](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/.github/ci-pending/ci.yml), [Actions metadata](https://api.github.com/repos/jonzobrist/customer-player-cards/actions/runs?per_page=1)
11. [License](https://github.com/jonzobrist/customer-player-cards/blob/6ff4c1e657e944b91d11fd38295d140b8ff38b8f/LICENSE)

---

**Attribution:** Jon Zobrist / jonzobrist/customer-player-cards, MIT. Independent static review; design requirements are distinguished from implemented behavior.
