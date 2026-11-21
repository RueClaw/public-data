# Plannotator (backnotprop/plannotator)

**Repo:** https://github.com/backnotprop/plannotator
**License:** MIT OR Apache-2.0 for project code; bundled dependencies/assets retain their own terms. Preserve applicable notices; Apache adds express patent terms.
**Reviewed:** 2026-11-21 (UTC)
**Revision:** `6128f5f117ae2896a10c269bda3653231a0d3e4f`, main snapshot, committed 2026-11-21. Scope: root manifests/licenses, CLI/hooks, shared server/config/storage/crypto, Inbox and OpenClaw integration, sharing, HTML viewer, installer and CI; representative modules, not every route.
**Release:** Latest public release observed: v0.29.1, published 2026-11-19; tag points to e44c3b93590f97bf4365915ddbbfff487c11c6ec. The reviewed main commit is newer; package version alone does not identify its behavior.
**Verification:** Static source review and unauthenticated public GitHub metadata. No installation, source execution, tests, model calls, accounts or live application probes.
**Stack:** TypeScript, Bun, React, Vite, agent SDKs/MCP, file-backed persistence; optional Cloudflare services.
**What it is:** A local browser review and feedback layer for coding agents, now including an asynchronous multi-agent Inbox, document/HTML annotation, code and guided reviews—not merely a plan-approval dialog.

---

## Verdict

⚠️ **Interesting: a strong human-feedback surface, not an execution security boundary.** The annotation-to-agent loop and durable recovery records solve real workflow problems. Pilot it locally with explicit permission, retention and egress choices; do not equate approving a plan with constraining subsequent commands, or “local” with “never communicates externally.” The current product's breadth makes a blanket deployment recommendation premature on static evidence alone.

## What It Is

Plannotator turns plans, documents, agent messages, diffs and HTML artifacts into interactive review surfaces. Traditional plan hooks wait for a review decision; newer adapters can keep the agent session non-blocking. Inbox is a persistent process that accepts messages/questions and routes a person's answer back to the originating agent. These are different workflows: Inbox explicitly lets agents keep working, rather than globally stopping all activity until approval.

The repository also contains a share portal, hosted-service implementations, editor integrations, AI-assisted reviews and agent-launch facilities. Those expand the authority and operational footprint beyond an offline Markdown viewer. README product claims were checked against representative implementation paths, not treated as proof of end-to-end compatibility. [1–3]

## Stack

| Layer | Technology / role |
|---|---|
| Local runtime | Bun servers; compiled CLI; some adapter-specific/runtime mirrors |
| UI | React/Vite; shared editor/UI and review-editor packages; diff rendering via @pierre/diffs |
| Integration | Claude hooks/modules, OpenCode/Pi and other adapters; MCP; OpenClaw Inbox plugin |
| Data | Markdown history, JSON/JSONL records, drafts and session registry; no mandatory central database for local review |
| Optional services | Paste/share, relay, feedback and telemetry services; Cloudflare deployment paths |
| Dependencies | Claude agent SDK, OpenCode SDK, MCP/ACP SDKs, marked, DOMPurify; Bun lockfile, patched and vendored packages |

## Key Features

### Precise feedback instead of another chat paragraph

Inline annotations, version comparison, diff comments and guided review chapters preserve the context a plain chat response loses. Feedback goes back through the relevant host adapter. This is useful UX, but the model still interprets the returned text; imported/team/agent annotations are not an independent policy engine. [1–3, 7]

### Approval semantics: narrowly scoped, host-dependent

The classic Claude hook matches **ExitPlanMode**. On approval it emits a PermissionRequest allow decision, echoes the reviewed plan in updatedInput and can emit a session-level setMode permission update. Denial returns a deny decision plus feedback. The module integration adds non-blocking review and checks the reviewed plan on subsequent exit attempts. Thus “approve” can affect the host's permission mode; it is not necessarily a harmless UI acknowledgment. [2]

This does **not** prove the later implementation matches the plan, stop tools outside this hook, enforce all agents' permissions identically, require CI, or authorize/complete a merge. A review decision and an actual forge action are separate flows. Use the host's permissions, OS isolation, repository checks and review rules for those guarantees. No bypass of a deployed system was tested.

### OpenClaw support is an Inbox bridge, not universal approval interception

The shipped plugin exposes plannotator_inbox to the owner's eligible local/private sessions; its documentation and tests exclude groups/channels and other senders. Replies become a new turn in the same chat, waiting if busy; after a conversation reset they follow the chat's new conversation. It requires a same-machine Inbox and declares OpenClaw >=2026.11.5-beta.1 compatibility. Installing it does not add a general gate around every OpenClaw tool. [3]

## Architecture

### Review surface, host adapter, storage

The CLI in apps/hook/server dispatches modes. packages/server implements plan/review/annotate and long-lived Inbox HTTP services; packages/shared/core contain reusable policies, models and persistence, while editor/UI packages implement the browser side. Pi includes generated shared copies, creating a parity/packaging concern alongside the benefit of shared behavior. The server resolves decisions back into the host's protocol; Inbox uses a file-backed record stream and connection bridges instead. [1–3, 7]

### Permissions and execution

This is privileged local software: it reads project files and diffs, writes history/configuration, invokes VCS and agent processes, and can perform explicit forge actions. AI-assisted review is not simply rendering text and may consume an existing provider account's quota. The Claude review-job implementation restricts tools, uses dontAsk, avoids loading project/local Claude settings and excludes unrelated MCP servers. It also explicitly warns that textual command allow/deny rules are **not containment**. Its default sandbox setting defers to the user's Claude sandbox configuration, rather than ensuring an OS sandbox exists; an opt-out can disable that sandbox for the job. Other adapters require their own analysis. [8]

### Server, authentication and origin boundaries

- Ordinary plan/review/annotate servers bind 127.0.0.1 locally, but **remote mode binds 0.0.0.0**. Remote mode can arise from SSH environment detection as well as an explicit setting. Default local port is random; remote default is 19432. A public/display URL is not an authentication mechanism. [4]
- Host allowlists and state-changing Origin/Sec-Fetch-Site checks are meaningful browser/DNS-rebinding defenses. The write guard intentionally permits clients with no Origin, and explicitly named proxy origins have allowances. These are **not user authentication** and do not stop an arbitrary non-browser client that can reach an exposed listener. Avoid bare public/LAN exposure; use an authenticated transport and restrictive network access. [4]
- Inbox is different: it binds loopback regardless of those remote settings. Its bridge/control routes require a registry bearer token and no Origin; MCP refuses browser origins; window writes use origin checks and a serverSession nonce. Optional tailnet/device paths have separate owner/pairing gates. This remains a single-user trust model, not multi-tenant RBAC; a nonce also protects stale tabs, not against a compromised local account. The optional remote/device paths were not exercised. [5]
- Raw HTML is active content: the viewer's default srcdoc sandbox allows scripts/modals but excludes same-origin. Live-app mode is a distinct path, unsandboxed by default. Do not generalize Markdown sanitation or an opaque-origin frame into a guarantee that arbitrary rendered content cannot use the network. [6]

### Sharing, retention and privacy

Small shares encode compressed content in the URL fragment: compression is not encryption. Large shares encrypt locally with AES-256-GCM, a fresh 256-bit key and 12-byte IV, then upload ciphertext; the decryption key stays in the full link's fragment. The paste handler defaults to a seven-day TTL and 5 MiB limit. Anyone with the full link can read it, and the recipient/hosting page's JavaScript gets access to fragment contents. Link copies in chats, browser history or backups outlive any server expiry. This is not identity-controlled sharing or guaranteed revocation. PLANNOTATOR_SHARE=disabled disables the documented sharing path. [9]

Guide sharing has its own contract: encrypted by default, with an explicit public option that stores plaintext and enables public metadata. Do not apply paste-service TTL assumptions to every guide/workspace/relay path. Hosted deletion, backups, operational logs and enforcement of expiry were not independently verified. [10]

Local history also matters: plans are saved on arrival, before approval; annotate history copies reviewed file contents. Decision snapshots, drafts and feedback archives are separate stores, so disabling planSave is not a global retention-off switch. Annotate and feedback history have separate controls. Submitted feedback is archived before draft deletion, retaining the draft on write failure; direct reviews posted to a forge are documented as an exception to local feedback archival. There is no universal seven-day local retention promise. Protect/back up the data directory and explicitly delete/purge unwanted history. [7]

**Default-on telemetry is a material caveat.** Release builds schedule an anonymous daily ping per tool (up to five tool categories), carrying version, install-age bucket, tool, first-of-day flag and favicon choice. The implementation/documentation describes no persistent user ID or content payload; the service code aggregates counts. NO_ANON_PING=1 is the documented opt-out, not a Settings toggle. The server necessarily receives network metadata; deployed logging behavior was not audited. Sharing, relay, optional AI/provider requests, update checks and remote Git checks add distinct egress paths. “No account needed for local review” is not “offline by default.” [11]

### Persistence and recovery

Inbox's authoritative local log is per-project append-only JSONL. Full record snapshots append as lines; unreadable torn lines are skipped and separated before the next write. Deletions rewrite files via temporary file/rename and preserve a sequence floor so consumers do not reuse cursor positions. SSE cursors and drafts support reconnect/recovery. These are good engineering choices, not proof of fsync-level power-loss durability, exactly-once downstream agent execution or a tamper-evident compliance ledger. Recovery behavior was read, not fault-injected. [7, 12]

## Dependencies, Installation and License

The advertised shell installer is executable code, not a passive download. It can install binaries and wire agent-specific hooks/configuration/skills; it has explicit minimal and integration-skip options. It supports pinned versions and SHA-256 checks. SLSA/GitHub attestation verification is available but **opt-in, default off**; matching a checksum fetched from the same release origin is weaker than verifying provenance. Inspect and pin the installer itself as well as the binary, and use its verification path where possible. No installer was run. [13]

The source has a Bun lockfile, dependency overrides, local patches and vendored tarballs. Root postinstall runs a viewer-manifest synchronization script. These are reproducibility inputs and supply-chain review surfaces, not assurances that transitive packages are safe. Native/runtime additions and optional adapters increase the trusted set. This review did not install packages, scan a resolved SBOM or verify release signatures/binary-source equivalence. [1, 13]

Both LICENSE-MIT and LICENSE-APACHE are present and package manifests say MIT OR Apache-2.0; GitHub's single Apache classification is incomplete. Choose and comply with the applicable project license; third-party UI/assets/vendor notices remain separate. No source code was extracted into this review. [14]

## Maturity and Verification Evidence

Public metadata on the review date showed 14,097 stars, 1,403 forks and 236 open issues/PRs combined, with activity the same day. Those are snapshots, not quality metrics. The tree contains 2,683 .test.ts/.test.tsx files (file count, **not executed test cases**) plus browser/E2E workflows. CI includes type/package checks, sharded tests, browser/mobile/security and platform-specific paths; the main Test workflow uses frozen-lockfile installation and pinned action SHAs. SECURITY.md supports only the latest release. [15]

At inspection, workflows attached to the exact reviewed SHA were still queued/pending (Test pending; Security Scanning and Mobile contract queued; Deploy skipped). **No green-build claim is made for this SHA.** No upstream test suite, UI, installer, exploit scenario, remote feature, provider or durability test was run. This is a representative static assessment of a large, rapidly evolving codebase, not a full security audit or all-integrations certification.

## Comparison

| Option | Prefer it when | Tradeoff |
|---|---|---|
| Plannotator | Rich local document/diff/HTML annotation and feedback across multiple agent hosts matter | More local authority, persistence and optional service surfaces to configure |
| Host-native plan/permission dialogs | A narrow plan or tool decision is enough | Less annotation/context; host still owns actual execution permissions |
| GitHub/GitLab PR review with protected-branch checks | Team identity, durable code review and merge enforcement are the primary requirement | Does not supply the same live local plan/HTML review workflow |
| Editor comments or plain Markdown feedback | Minimal dependencies and explicit manual handoff are preferred | More copying and weaker structured/version-aware feedback UX |

These are workflow alternatives, not freshly benchmarked competing products. Plannotator complements rather than replaces protected branches or host sandboxing.

## Self-Hosting Notes

For an initial evaluation, use a pinned release in a disposable non-sensitive workspace, keep ordinary servers local (explicitly force local mode if needed), and avoid remote exposure. Decide telemetry, sharing, AI, update and Git-remote behavior before supplying private content. Review history/draft/feedback settings independently. Add one host integration at a time and verify deny, approval-mode changes, browser close, restart and stale-tab outcomes against that exact host version.

If remote access is necessary, review the specific authenticated tailnet/proxy/device path rather than forwarding a generic wide listener. Self-hosting the paste service can move ciphertext custody but does not remove full-link access risks or magically disable other egress. No deployment was performed.

## Evidence

All implementation links below pin the reviewed commit; external metadata/release observations are time-sensitive.

1. [README.md](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/README.md); [package.json](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/package.json).
2. [apps/hook/hooks/hooks.json](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/apps/hook/hooks/hooks.json); [apps/hook/server/index.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/apps/hook/server/index.ts); [apps/hook/hooks/mod/register.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/apps/hook/hooks/mod/register.ts).
3. [apps/openclaw-plugin/README.md](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/apps/openclaw-plugin/README.md); [apps/openclaw-plugin/inbox.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/apps/openclaw-plugin/inbox.ts); [apps/openclaw-plugin/inbox.test.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/apps/openclaw-plugin/inbox.test.ts); [apps/openclaw-plugin/package.json](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/apps/openclaw-plugin/package.json).
4. [packages/server/remote.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/server/remote.ts); [packages/server/request-host-guard.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/server/request-host-guard.ts); [packages/server/request-origin-guard.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/server/request-origin-guard.ts); [packages/shared/request-origin.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/shared/request-origin.ts).
5. [packages/server/inbox.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/server/inbox.ts).
6. [packages/ui/components/html-viewer/HtmlViewer.tsx](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/ui/components/html-viewer/HtmlViewer.tsx).
7. [docs/agent-guides/server-and-storage.md](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/docs/agent-guides/server-and-storage.md); [packages/shared/feedback-archive.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/shared/feedback-archive.ts); [packages/shared/storage.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/shared/storage.ts).
8. [packages/server/claude-review.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/server/claude-review.ts); [packages/shared/config.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/shared/config.ts).
9. [packages/core/crypto.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/core/crypto.ts); [packages/ui/utils/sharing.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/ui/utils/sharing.ts); [apps/paste-service/core/handler.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/apps/paste-service/core/handler.ts).
10. [packages/server/guide/guide-share.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/server/guide/guide-share.ts); [docs/agent-guides/server-and-storage.md](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/docs/agent-guides/server-and-storage.md).
11. [packages/shared/daily-ping.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/shared/daily-ping.ts); [apps/telemetry/src/handler.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/apps/telemetry/src/handler.ts); [docs/agent-guides/server-and-storage.md](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/docs/agent-guides/server-and-storage.md).
12. [packages/shared/inbox/store-log/jsonl-log.ts](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/packages/shared/inbox/store-log/jsonl-log.ts).
13. [scripts/install.sh](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/scripts/install.sh); [.github/workflows/release.yml](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/.github/workflows/release.yml).
14. [LICENSE-MIT](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/LICENSE-MIT); [LICENSE-APACHE](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/LICENSE-APACHE).
15. [.github/workflows/test.yml](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/.github/workflows/test.yml); [SECURITY.md](https://github.com/backnotprop/plannotator/blob/6128f5f117ae2896a10c269bda3653231a0d3e4f/SECURITY.md).

**Attribution:** backnotprop and Plannotator contributors; project code MIT OR Apache-2.0. Independent analysis of public sources.
