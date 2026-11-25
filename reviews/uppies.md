# Uppies (schmayterling/uppies)

**Repo:** https://github.com/schmayterling/uppies
**License:** MIT; preserve copyright and permission notices when reusing code. Icons have additional ISC/MIT/CC0 notices.
**Reviewed:** 2026-11-25 (UTC)
**Revision:** a205b4fc4ceb062814d45dd5553b656438584421 (main; full repository, targeted paths below); no tags or releases at retrieval.
**Verification:** Static source review only; no installation, builds, tests, containers, live service probes or device access. Public GitHub metadata and source retrieval only.
**Stack:** Go 1.27.4, net/http, html/template, embedded assets, SQL databases, Goldmark, Argon2id.
**What it is:** A self-hosted uptime monitor and public status-page publisher, with reusable monitors across projects, incident communication and scoped automation tokens.

---

## Verdict

⚠️ **Interesting — a thoughtful small-team status publisher, not yet a production-monitoring default.** Its reusable monitor/page model, explicit API grants, privacy-aware response models and SQLite upgrade safeguards are substantive implementation, not merely roadmap claims. Pilot the SQLite path if public incident presentation matters; choose a more established alternative when broad integrations, stronger identity controls or assured alert delivery matter most. Missing durable alert delivery, broad administrator authority and limited CI verification keep this short of an unconditional deployment recommendation.

## What It Is

Uppies combines scheduled service checks, a web administration interface and branded public status pages in one server. A monitor belongs to the installation and can be placed on multiple pages, with page-specific ordering, categories and presentation. Public pages show uptime, response-time views, badges, published incident updates and maintenance history. This is not an AI agent, host-metrics collector, browser-testing platform or on-call escalation system. [evidence 1](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/README.md)[evidence 2](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/ROADMAP.md)

The README's concise pitch is supported by the implementation. The roadmap also clearly separates future features: password-protected status pages, two-factor authentication, SSO, multi-location checks, configuration-file management and Uptime Kuma import are not present capabilities. Standalone binary releases, Atom feeds and email subscriptions remain planned. [evidence 2](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/ROADMAP.md)

## Stack

| Layer | Technology and boundary |
|---|---|
| Process | Go executable; starts HTTP server, check engine and optional outbound heartbeat |
| UI | Server-rendered Go templates, embedded CSS/JS/images, Goldmark with restricted rendering |
| Checks | HTTP(S), TCP, DNS host resolution, IPv4 ICMP and inbound push heartbeats |
| Storage | SQLite default; PostgreSQL, MariaDB, embedded Turso SQLite and Turso PostgreSQL adapters |
| Authentication | Argon2id passwords, database-backed hashed session tokens, hashed scoped API bearer tokens |
| Notifications | HTTP webhooks, Discord, Slack and SMTP email |
| Packaging | Non-root distroless container; Compose; separate patched Turso PostgreSQL build |

Sources: manifests, entry point, routing and backend implementation. [evidence 3](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/cmd/uppies/main.go)[evidence 4](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/check/check.go)[evidence 5](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/server.go)

## Key Features

### One monitor, several public pages

Monitor placements are separate from monitor ownership. A shared service can appear on several project pages without duplicated checking, and a placement can be excluded from that page's overall status. Custom domains, branding, per-page history windows and SVG/PNG badges are implemented. These are presentation boundaries, not separate tenants or authorization domains. [evidence 6](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/public.go)

### Checks with explicit semantics

HTTP checks perform GET, accept 2xx after normal client redirects and optionally search a literal keyword in at most 1 MiB of body. DNS checks require at least one resolved address, rather than asserting arbitrary DNS records. Ping is IPv4 via an unprivileged datagram socket and depends on OS ping-group permissions. Push monitoring ignores a job until its first report, then allows a ten-second grace interval. TLS expiry warnings use 14/7/3/1-day thresholds. [evidence 4](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/check/check.go)[evidence 7](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/engine/engine.go)

Maintenance skips checks and alert transitions for covered monitors. Failure/recovery thresholds reduce flapping; confirmed transitions can produce draft incidents and follow published incident state. A new push job that never reports is not a reliable missing-job alarm until initialized. [evidence 7](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/engine/engine.go)[evidence 8](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/store/incidents_test.go)

### API automation with meaningful limits

API v1 covers pages/layouts, monitors, alert channels, incidents and maintenance. Each route checks an exact grant against a live token on every request; expiry and revocation take effect immediately on the next request. JSON bodies are bounded to 64 KiB, unknown fields are rejected, pagination is bounded and API errors avoid printing potentially credential-bearing database messages. Tokens cannot substitute a browser session, and browser sessions do not authenticate the API. [evidence 9](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/API.md)

However, grants apply across the installation, not to a particular project. Any administrator can edit or revoke tokens. Repeating create/append requests can duplicate records: the documented API has no idempotency-key contract. [evidence 9](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/API.md)

## Architecture

The entry point opens/migrates storage, constructs the check engine and web server, then starts both. The engine maintains one goroutine per active monitor, caps concurrent active checks at 32 and introduces startup jitter. Configuration reload cancels and reconstructs monitor loops; interrupted checks are not recorded as target failures. Results and rollups are stored, while notification deliveries run asynchronously. Embedded UI assets avoid a separate Node/frontend build. [evidence 3](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/cmd/uppies/main.go)[evidence 7](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/engine/engine.go)

The code is organized along useful boundaries: check performs one probe; health advances outage state; engine schedules and dispatches; store owns SQL and migrations; web handles browser/API/public surfaces. Explicit typed response projections and focused tests are stronger signals than the repository's popularity. [evidence 4](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/check/check.go)[evidence 7](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/engine/engine.go)[evidence 9](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/API.md)[evidence 10](https://github.com/schmayterling/uppies/tree/a205b4fc4ceb062814d45dd5553b656438584421/internal)

**Important availability gap:** the main select waits for process cancellation or HTTP server exit, but does not select on engineDone. If the engine exits early because loading monitors fails, the HTTP server can keep serving; /healthz always returns 204 without checking engine or database health. This is a static control-flow finding, not a reproduced failure. An outbound heartbeat is useful, but a heartbeat from the same still-running process is not proof that checks are advancing. [evidence 3](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/cmd/uppies/main.go)[evidence 5](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/server.go)[evidence 7](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/engine/engine.go)

## Security, authority and privacy

- **First-admin setup is a deployment boundary.** Setup is unauthenticated while no users exist. The raw executable defaults to all-interface :8080; the supplied Compose files bind the host port to loopback by default. Complete initial setup before exposing a reverse proxy. All signed-in browser accounts are administrators, with no per-project RBAC, MFA or SSO at this revision. [evidence 1](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/README.md)[evidence 2](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/ROADMAP.md)[evidence 3](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/cmd/uppies/main.go)[evidence 11](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/auth.go)
- **Good baseline controls, with proxy assumptions.** Password hashing uses Argon2id (19 MiB, two passes, one thread); sessions are random, SHA-256-hashed in storage, 30-day, HttpOnly and SameSite=Lax. Secure cookies depend on TLS or X-Forwarded-Proto=https. Cross-origin protection, same-origin CSP and nosniff headers are present. The login limiter uses RemoteAddr, not forwarded client addresses: behind one reverse proxy, users can share the same failure bucket. Restrict direct backend access and normalize proxy headers. [evidence 5](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/server.go)[evidence 11](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/auth.go)[evidence 12](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/markdown.go)
- **Monitor-writing permission grants network reach.** HTTP/TCP targets and webhook destinations are syntactically validated but not restricted to public addresses; HTTP clients follow redirects and there is no application-level private-address/metadata denylist. That is useful for internal monitoring but unsafe as an untrusted tenant feature. A compromised admin or suitably scoped write token can cause server-side requests into the server's reachable network. Use dedicated network placement and explicit egress restrictions. No shell-command probe facility or os/exec use was found in the reviewed Go source; this is network authority, not demonstrated arbitrary command execution. [evidence 4](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/check/check.go)[evidence 9](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/API.md)[evidence 13](https://github.com/schmayterling/uppies/tree/a205b4fc4ceb062814d45dd5553b656438584421/internal/alert)
- **Secrets are not uniformly protected at rest.** Passwords, sessions and API tokens are hashed, but monitor targets, push tokens and notification destinations are stored as usable values in the database. API monitor reads omit targets, keywords, raw errors and push credentials; channel reads expose only ID/kind. Those protections also mean the read API is not a complete backup/export. Protect database files, volumes and backups as sensitive material. [evidence 9](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/API.md)[evidence 14](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/api_monitors.go)
- **Outbound alerts are deliberate data sharing.** Generic webhooks include project, monitor, target and error; email includes the target; Slack/Discord send the summary, which can include error text. A keyword failure can include the configured keyword. Do not put secrets into monitored URLs, labels or keyword strings without considering these routes. SMTP upgrades with STARTTLS if offered, but does not require TLS for unauthenticated delivery. [evidence 4](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/check/check.go)[evidence 13](https://github.com/schmayterling/uppies/tree/a205b4fc4ceb062814d45dd5553b656438584421/internal/alert)
- **Push URLs are credentials.** GET and POST /push/{token} accept the path token; POST bypasses browser cross-origin protection intentionally. Reverse-proxy access logs and copied URLs can expose that capability. API credentials belong in Authorization headers instead. [evidence 5](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/server.go)[evidence 9](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/API.md)
- **Public means public.** Hidden listings/noindex and custom domains are not access control. Public monitor detail checks page membership; Markdown rendering escapes raw HTML, rejects dangerous URLs and renders images as links. No external analytics requirement was found in the reviewed runtime paths, but this was not a dynamic traffic audit. [evidence 2](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/ROADMAP.md)[evidence 5](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/server.go)[evidence 6](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/public.go)[evidence 12](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/markdown.go)

## Persistence, recovery and export

SQLite uses WAL, foreign keys, a busy timeout and immediate write transactions. Before upgrading an existing SQLite schema, it writes a VACUUM INTO backup beside the database (unless that version's backup already exists), applies versioned steps and checks foreign keys before commit. A newer unsupported schema is rejected. This is a valuable upgrade safeguard, not scheduled/off-site backup or a demonstrated restore procedure. Other backend migrations follow a different path; do not assume SQLite's backup behavior applies to them. Turso SQLite explicitly requires a separate database from ordinary SQLite. [evidence 15](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/store/store.go)

Raw check results are pruned after 48 hours; rollups remain. Check coverage across long process gaps is capped at two monitor intervals, so the uptime number measures covered time, not all wall-clock availability. Optional visual backfill can color unmeasured days, but labels retain the no-measurement distinction and the numeric percentage is unchanged. Do not use a green historical bar as independent SLA evidence. [evidence 6](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/public.go)[evidence 7](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/engine/engine.go)

Alerts are best-effort: HTTP delivery retries up to three times on network errors, 429 or 5xx with short increasing waits, but no durable outbox/replay is implemented. SMTP has no corresponding retry loop. A crash after saving a transition can lose the alert; retries can duplicate external messages. Shutdown waits for deliveries, yet the alert deadline is one minute while supplied Compose grace is 15 seconds. There is no demonstrated HA scheduler/leader election: multiple instances sharing storage should not be assumed safe. [evidence 3](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/cmd/uppies/main.go)[evidence 7](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/engine/engine.go)[evidence 13](https://github.com/schmayterling/uppies/tree/a205b4fc4ceb062814d45dd5553b656438584421/internal/alert)

Password reset is implemented as a database-access CLI operation that prints a new random password and invalidates sessions. Full recovery still requires a consistent database backup, external SMTP/database configuration and a pinned runnable version. No complete application export/import or cross-backend migration tool was found; API reads intentionally omit configuration secrets. Keep backend-specific backup/restore procedures and test them before upgrades. [evidence 1](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/README.md)[evidence 9](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/API.md)[evidence 15](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/store/store.go)

## Supply chain, licensing and maturity

The project has an actual MIT license credited to ryana may que. THIRD_PARTY.md records Lucide/Feather ISC/MIT material and Simple Icons CC0; trademarks and transitive dependency licenses remain separate. No source code was extracted into this review. [evidence 16](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/THIRD_PARTY.md)

Go dependencies are version-pinned with go.sum. Base container images and the checkout Action are pinned by digest/SHA; the runtime container is non-root and the workflow disables persisted checkout credentials. These are good controls. Compose still defaults to a mutable latest application image. The optional Turso PostgreSQL image builds a checksum-pinned upstream tarball, patches foreign-key behavior and uses unversioned apt package resolution; it adds substantially more maintenance surface than the SQLite recommendation. Its internal-only Compose database network is an important boundary because the example uses passwordless PostgreSQL transport with TLS disabled. [evidence 17](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/.github/workflows/container.yml)

At retrieval, anonymous GitHub metadata reported 38 stars, 2 forks and 2 open issues including a pull request. The last push was 2026-11-25T19:44:48Z; the reviewed commit date is 2026-11-25T19:44:42Z. Releases and tags APIs both returned empty lists, so there is no release version to certify. These are activity observations, not reliability evidence. [evidence 18](https://github.com/schmayterling/uppies/actions/runs/45688221560)

The repository contains 29 Go test files covering checks, state transitions, migrations, API authorization/validation, rendering and privacy. Server-database tests skip when their dedicated test DSNs are absent. The sole checked-in workflow builds and publishes amd64/arm64 containers; it does not run go test, race checks, linting or vulnerability scans. GitHub reported successful Publish container run 45688221560 at the exact reviewed SHA. That establishes a reported publishing-job result, not passing tests, an audited image or reproducible behavior. [evidence 10](https://github.com/schmayterling/uppies/tree/a205b4fc4ceb062814d45dd5553b656438584421/internal)[evidence 17](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/.github/workflows/container.yml)[evidence 18](https://github.com/schmayterling/uppies/actions/runs/45688221560)

An open report, issue #2, concerns duplicate monitor IDs producing a 500 in the incident form. API ID validation rejects duplicates, but the separate browser path should not be assumed covered by that API guard. The report was not reproduced or adjudicated here. [evidence 19](https://github.com/schmayterling/uppies/issues/2)

## Comparison

| Need | Uppies | Alternative |
|---|---|---|
| Branded multi-project status pages with shared monitor placement | Core model; small single-server architecture | Uptime Kuma also documents multiple pages/domains, a broader monitor list, 90+ notification services and 2FA |
| Declarative developer health assertions | UI/API-managed; HTTP keyword and fixed check semantics | Gatus documents condition-based evaluation of status, body, latency and certificates, with configuration-oriented operation |
| Strong identity / reliable paging | Full-admin browser accounts; no MFA/SSO yet; best-effort alerts | Evaluate established identity controls and an independent alerting/on-call system rather than treating a public status publisher as the paging authority |

Alternative descriptions were checked against the public [Uptime Kuma README](https://github.com/louislam/uptime-kuma#readme) and [Gatus README](https://github.com/TwiN/gatus#readme) on the review date; neither was installed or comparatively benchmarked. Prefer an existing alternative over extending Uppies solely to recover basic identity/integration requirements.

## Self-Hosting Notes

For a controlled pilot, prefer the documented SQLite Compose variant rather than the default compose.yaml's custom Turso PostgreSQL service. Pin an image digest or reviewed SHA-tag, keep the database volume durable, finish setup locally, then place it behind HTTPS with trusted Host/X-Forwarded-Proto handling. Restrict administrator access and outbound target networks; account for ICMP permissions without granting broad container privilege. [evidence 1](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/README.md)[evidence 17](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/.github/workflows/container.yml)

Before relying on it: run the test suite in an isolated environment, exercise each intended database/backend, test lost-network and lost-database behavior, restore a backup, verify alert delivery and process-kill recovery, and independently watch the freshness of actual check results. These are recommendations, not actions performed during this review.

## Verification and limitations

Anonymous GitHub API access and public HTTPS source acquisition confirmed source accessibility. Canonical identity was normalized from the submitted .git URL; no matching prior public review or index entry was found, so this is a new review, not a refresh. Scope: README/API/roadmap/license/notices; Go manifest/checksum file; entry point; core check/engine/auth/API/store/public-rendering paths; Docker/Compose/workflow definitions; targeted test inspection.

No source code, dependency installation, build, tests, database, network probe, demo or container was executed. No account, credentials, paid service, private data or device was used to evaluate the application. Test presence is not a pass result. Security findings are static trust-boundary assessments, not a penetration test or exhaustive vulnerability audit. HTML/Markdown publication checks are separate from application validation.

## Evidence

All source-file citations below are pinned to the reviewed commit; metadata links are time-varying observations retrieved on 2026-11-25 UTC.

[1]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/README.md
[2]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/ROADMAP.md
[3]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/cmd/uppies/main.go
[4]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/check/check.go
[5]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/server.go
[6]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/public.go
[7]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/engine/engine.go
[8]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/store/incidents_test.go
[9]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/API.md
[10]: https://github.com/schmayterling/uppies/tree/a205b4fc4ceb062814d45dd5553b656438584421/internal
[11]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/auth.go
[12]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/markdown.go
[13]: https://github.com/schmayterling/uppies/tree/a205b4fc4ceb062814d45dd5553b656438584421/internal/alert
[14]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/api_monitors.go
[15]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/store/store.go
[16]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/THIRD_PARTY.md
[17]: https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/.github/workflows/container.yml
[18]: https://github.com/schmayterling/uppies/actions/runs/45688221560
[19]: https://github.com/schmayterling/uppies/issues/2

Additional implementation evidence: [password hashing](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/password.go), [API enforcement](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/web/api_v1.go), [token persistence](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/store/api_tokens.go), [backend migrations](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/internal/store/backend_schema.go), [container](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/Dockerfile), [SQLite Compose](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/compose.sqlite.yaml), [Turso Compose](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/compose.yaml), [Turso build](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/Dockerfile.tursopg), [manifest](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/go.mod), [license](https://github.com/schmayterling/uppies/blob/a205b4fc4ceb062814d45dd5553b656438584421/LICENSE), [public metadata](https://api.github.com/repos/schmayterling/uppies), [releases](https://api.github.com/repos/schmayterling/uppies/releases), [tags](https://api.github.com/repos/schmayterling/uppies/tags).

---

**Attribution:** schmayterling/uppies; copyright 2026 ryana may que; MIT, with third-party notices. Independent static analysis; no affiliation implied.
