# Biscotti (lucasgelfond/biscotti)

**Repo:** https://github.com/lucasgelfond/biscotti
**License:** MIT, copyright 2026 Lucas Gelfond; preserve copyright and permission notices when reusing code. Bundled desktop components and artwork have separate terms.
**Reviewed:** 2026-11-21 (UTC)
**Revision:** b68629c7211593c6f1a85ff04b3e8038a77ffbcc (main); repository-wide static review, emphasizing core, connectors, VM/network configuration, installer and tests. Commit dated 2026-11-03 UTC. Package version 0.1.19; latest observed tag v0.1.19 points to 11fcb97ab71add5c269385ea9a1452e0a54a45c3, not the reviewed commit. Public GitHub releases API returned no releases.
**Verification:** Static source/configuration inspection only. No installation, source execution, test suite, model calls, account connection, VM boot, hardware access or live security probes.
**Stack:** TypeScript/Node, Pi agent harness, encrypted SQLite/Drizzle/FTS5, MCP, Docker, NixOS, Firecracker/KVM, Cua desktop, Swift installer, Spectrum/Photon iMessage.
**What it is:** A self-hosted personal iMessage agent that delegates browser, desktop and coding errands to disposable Linux VMs, with a host-side credential and permission gate.

---

## Verdict

📚 **Study — compelling separation of credentials from agents, not a blanket safe-autonomy boundary.** The actual architecture is more careful than a shell-enabled chatbot: a networkless main agent, per-task VM isolation, owner-only messaging and brokered credentials. But permission policy deliberately allows some external writes without approval, generic MCP configuration can redirect a saved token, and public artifacts plus traces create additional privacy boundaries. Study the design; do not grant broad personal-account access before hardening and adversarial testing.

## What It Is

Lucas Gelfond describes a lightweight, Instinct-inspired assistant built around existing agent and sandbox primitives, initially daily-driven on a Raspberry Pi. Its purpose is personal assistance over iMessage—not a cookie utility or standalone password manager. The README's weekend-build and daily-use statements are author reports, not independent reliability evidence. [E1]

One continuing main conversation can search memories, inspect connected services, schedule future prompts and dispatch tasks. Task VMs have a browser, desktop, shell and internet; they receive a task-specific goal rather than the main conversation. Google, GitHub and remote MCP connectors run on the trusted gate. Optional plugins add embeddings, tracing, HTML pages and access to a separate Mac desktop. [E2–E9]

## Stack

| Layer | Implementation |
|---|---|
| Main agent | Pi session; built-in tools, skills, context files and arbitrary extensions disabled; MCP through a Unix-socket relay |
| Trusted broker | TypeScript gate, connector plugins, owner approvals and OpenAI-compatible model proxy |
| Persistence | SQLite3 Multiple Ciphers, Drizzle migrations, transcript/memory FTS5, stored wakes and vault |
| Task execution | Firecracker snapshot restore, per-slot network namespaces, Cua/XFCE/Chromium, task Pi process |
| Deployment | NixOS modules, Docker Compose, KVM; Lima nested virtualization on supported Macs; AWS configuration |
| Messaging/UI | Spectrum/Photon iMessage; Swift setup app; optional Tailscale-served interfaces |

## Key Features

### Real credential separation

The production Compose agent service is non-root, read-only, capability-dropped and networkless. It sees only the shared socket, not the database or environment-file secrets. The gate holds API keys, database access and plugins; socket permissions are set to 0600. Task gate listeners check peer address and Host. These are concrete isolation mechanisms, although their runtime effectiveness was not tested. The VM service still needs KVM, tun and elevated namespace-management capabilities; the gate itself uses host networking. [E2, E3]

### Disposable errands and controlled secret filling

Tasks restore a fresh snapshot, report results and stop their VM; the pool warms another instance. Default task timeout is 30 minutes, coding tasks 90 minutes, with a separate idle timeout. Comments mention three slots but the code defaults to two unless configured: capacity should be checked from deployment settings, not prose. Secure-fill asks about the destination site, checks focused frame/site again before each field, and types via DevTools instead of putting values into a model response. Consent is reused for the same task/entry/site for up to 15 minutes. This is destination consent, not confirmation of each purchase or submission. [E4, E5]

### Useful persistent memory and scheduling

Encrypted SQLite stores transcripts, memories, vault entries and scheduled wakes. FTS5 recall can combine plugin rankings using reciprocal-rank fusion. Optional embeddings default to a local service, but the endpoint is configurable. The main conversation reloads its transcript on restart. These features are implemented, not merely roadmap claims. [E2, E6]

## Architecture

Owner iMessage → Spectrum channel filter → gate approval handler/main conversation → gate tools or task VM → model provider/connector/web destination → report back through gate.

The channel accepts text only from the configured owner and rejects outbound echoes and group chats. This relies on provider sender identity; it is not an independently authenticated multi-user application. Approval replies must match a whole-message yes/no vocabulary, questions serialize, and unanswered questions decline after ten minutes. Gate lock symbols are stripped from ordinary agent messages to reduce impersonation. Approval questions truncate after 3,000 characters, so a long approved operation can exceed the visible review text. [E3, E7]

### Permissions and execution: the important gaps

- **Not every write asks.** Google mail sending and event deletion ask; drafts and calendar create/update do not. Event creation with attendees sets sendUpdates=all, so an unapproved create can send invitations. GitHub permits additive operations without asking, uses remote readOnlyHint annotations, and excludes merge tools. Generic MCP uses remote annotations and name heuristics to skip consent for reads/additions. These policies are not equivalent to a local, explicit capability allowlist. [E8]
- **Generic MCP token destination is not bound.** mcp_connect accepts an HTTPS URL, inserts or replaces an existing named server without ctx.ask, and reuses the vault token named for that server on subsequent connection. A model-induced replacement can therefore redirect that credential to a different HTTPS server. There is no visible host allowlist/private-address rejection in this plugin. This is a static data-flow finding, not a demonstrated exploit; it matters precisely because the gate has host networking and credentials. Bind tokens to an approved origin and require confirmation for server changes. [E9]
- **OAuth callback validation needs review.** Generic MCP generates a random state suffix, but its callback selects the server from only the prefix and does not visibly compare a stored full pending state. The SDK's PKCE exchange remains an additional protection; this review does not claim a working account-takeover exploit. Google's separate connector does compare its pending state. [E8, E9]
- **Coding tasks publish externally.** The gate imports a returned Git bundle, checks ancestry, size and changed paths, blocks .github/ changes, then pushes a new branch and opens a PR without a separate approval call. Draft creation can fall back to a normal PR. Blocking workflow-file edits does not prevent existing workflows from executing changed project scripts. A draft PR is not a sandbox, and this path needs repository-specific CI trust analysis. [E10]
- **VM isolation is not internet isolation.** Network rules block private LAN, tailnet and link-local ranges, other host services and IPv6 ingress from slots while permitting public internet. Once a secret is entered into a task browser, page/guest code and the intended website can handle it. The guest has powerful shell/desktop access; firewall rules do not prevent public exfiltration. [E4, E5, E11]

### Credentials, privacy and egress

DB_KEY unlocks the encrypted database; deployment setup generates a random key and protects the environment file with mode 0600. This protects a copied database better than an unencrypted file, but does not protect against a compromised gate/host that can read both. Local plugins execute in the key-holding process and are fully trusted code. [E2, E6, E12]

The claim that no model ever sees a secret is too broad. Scrubbing replaces known vault secret strings of at least six characters, with special handling for card-number separators. Short codes, unsaved chat secrets, transformed/encoded values and secrets visible inside screenshots are not comprehensively removed. Identifying fields such as usernames are intentionally exposed. Model requests and outbound text are scrubbed, but images are sent separately; this is not DLP or an image-redaction system. [E2, E3, E5, E6]

Egress includes the configured model provider, Spectrum/Photon messaging, connected Google/GitHub/MCP services and task browsing. Phoenix can retain prompts, replies and tool traces locally or export them to a configured OTLP endpoint. Gate observers receive raw tool arguments before result scrubbing, so newly supplied vault values can reach tracing hooks. Phoenix's separate volume is not covered by the encrypted main SQLite database. Review provider retention and logs as well as database encryption. [E3, E13]

The artifacts plugin writes model-supplied HTML to persistent files and exposes random-name public URLs through Tailscale Funnel. It uses CSP sandboxing, restricted resource loading and noindex, but does not require publish approval, scrub page content, authenticate readers or expire pages. An unguessable URL is a bearer link, not private storage; sensitive content and preview metadata can be shared outside the tailnet. The Mac VNC plugin instead documents tailnet-only, two-hour links and requires Mac Screen Sharing/Screen Recording/Accessibility permissions; it expands the trust boundary beyond disposable VMs. [E14]

### Persistence and recovery

Transcripts, vault, OAuth grants, memories and wakes survive via the database; page files and Phoenix traces live separately. Container restart policies and agent reload support service recovery. Task pool, approval queue, pending vault forms and secure-fill approvals are in memory, not durable transaction journals. A restart does not establish whether an external action completed, and there is no demonstrated exactly-once task replay. [E2–E6, E9, E13, E14]

The scheduler updates lastRun (and may delete one-time wakes) before awaiting delivery, so a crash/failure can lose a reminder. Its asynchronous interval scans are not globally serialized; public issue #72 reports duplicate firing when two wakes overlap a slow turn. This review did not reproduce it. No end-to-end backup/restore proof was found: operators would need the database plus key, settings, page/trace data as appropriate, and an explicit recovery exercise. [E6, E15]

## Supply Chain, License and Costs

There are pnpm, npm and Nix lockfiles, pinned Pi/MCP versions, pinned Cua/noVNC source commits, checksummed Node downloads and a digest-pinned Phoenix image. Conversely, the VM Dockerfile uses an unpinned Debian base tag/apt packages and downloads a versioned cua-spacesd archive without a visible checksum check; Lima's prebuilt image URL has no digest in that configuration. ARM Firecracker uses a hashed patch from the author's fork. Nix's updater checks newest version tags every six hours and rebuilds automatically, extending trust to future upstream changes; the updater does not visibly enforce signed release tags. These are mixed provenance controls, not a reproducible-build attestation. [E12, E16]

MIT permits reuse with notices and warranty disclaimer. The desktop image preserves Cua component notices; noVNC, dependencies and the Unsplash wallpaper retain their own terms. This review extracts no upstream source code. [E1, E16]

Self-hosted does not mean free or local-only: budget for model tokens, Spectrum/Photon service eligibility and pricing, optional search APIs, hardware/storage/electricity or AWS compute, and maintenance. No current provider price quotes or workload-cost measurements were verified. VM timeouts constrain duration, not a total monetary budget; no global spend ceiling was established from the reviewed code.

## Maturity and Verification

Public unauthenticated GitHub metadata on 2026-11-21 showed 49 stars, 4 forks and 5 open issues/PRs; repository creation was 2026-10-17 and last push 2026-11-16. Popularity and activity are not assurance. Main's commit date, package version, tag and last-push timestamp are distinct facts. [E17]

A substantial test tree covers approvals, gates, vault, Google, MCP, tasks, memory, screenshots and more, plus Nix tests and benchmarks. No .github workflow directory was present at this revision. The main Vitest config explicitly uses real models and credentials with long timeouts; tests also use local services. Nothing was installed or run. Upstream benchmark notes report roughly 0.25–0.27-second patched Firecracker snapshot restores on specific Pi hardware; they are author measurements with old path/browser references, not verified current performance guarantees. [E15, E18]

Before adoption: add explicit write policies; bind connector credentials to origins; validate OAuth state; harden public-page consent/retention and trace redaction; test prompt injection, image leakage and restart ambiguity; verify firewall behavior, image provenance, spend caps and backups on a dedicated non-sensitive installation.

## Comparison

| Alternative | Better fit / tradeoff |
|---|---|
| [OpenClaw](https://github.com/openclaw/openclaw) | Broader personal-assistant platform to compare for channel/tool integration; evaluate its own configured permissions and isolation rather than assuming equivalence. Biscotti is narrower and iMessage-centered. |
| [Pi](https://github.com/badlogic/pi-mono) | Agent-harness building block rather than a turnkey iMessage broker; Biscotti adds deployment, owner messaging, connectors and VM orchestration around a Pi-derived dependency. |
| [Cua](https://github.com/trycua/cua) | Desktop/computer-use infrastructure; relevant when isolated UI work is the core need rather than a persistent personal assistant. Biscotti already builds on its components. |
| Native mail/calendar automation | Prefer deterministic rules or explicit manual actions when broad model access to personal accounts is unnecessary. Less autonomy, fewer credential and prompt-injection boundaries. |

These are architectural comparisons, not installation tests or a security ranking of the alternatives.

## Self-Hosting Notes

This is a host/VM stack, not merely a Node service. KVM, networking namespaces, snapshot/image lifecycle, Tailscale and channel/model credentials are operational prerequisites. Supported-Mac instructions require nested virtualization; optional Mac VNC is a separate real-desktop permission grant. Keep the gate and state on a dedicated host, minimize plugins and account scopes, and do not turn on public artifacts or automatic upgrades without understanding their policy. No deployment was performed for this review.

## Evidence

All source links below pin the reviewed commit. Public metadata is mutable and was retrieved 2026-11-21. Findings above are independent static analysis unless explicitly attributed to the author or an issue.

- **E1:** [README.md](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/README.md), [LICENSE](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/LICENSE)
- **E2:** [core/src/biscotti.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/src/biscotti.ts), [core/src/agent.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/src/agent.ts), [core/src/main.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/src/main.ts), [core/host/compose.yaml](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/host/compose.yaml)
- **E3:** [core/src/gate.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/src/gate.ts), [core/src/http.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/src/http.ts)
- **E4:** [core/src/tasks.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/src/tasks.ts), [core/src/vms-main.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/src/vms-main.ts)
- **E5:** [plugins/secure-fill/index.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/plugins/secure-fill/index.ts)
- **E6:** [core/src/memory.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/src/memory.ts), [core/src/schema.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/src/schema.ts), [core/src/vault.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/src/vault.ts), [core/src/crons.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/src/crons.ts), [plugins/embedding/index.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/plugins/embedding/index.ts)
- **E7:** [plugins/channels/spectrum/index.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/plugins/channels/spectrum/index.ts)
- **E8:** [plugins/google/index.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/plugins/google/index.ts), [plugins/github/index.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/plugins/github/index.ts)
- **E9:** [plugins/mcp/index.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/plugins/mcp/index.ts)
- **E10:** [plugins/github/code.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/plugins/github/code.ts)
- **E11:** [nix/net.nix](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/nix/net.nix)
- **E12:** [nix/setup.nix](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/nix/setup.nix), [nix/biscotti.nix](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/nix/biscotti.nix)
- **E13:** [plugins/phoenix/index.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/plugins/phoenix/index.ts), [plugins/phoenix/compose.yaml](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/plugins/phoenix/compose.yaml)
- **E14:** [plugins/artifacts/index.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/plugins/artifacts/index.ts), [plugins/mac-vnc/README.md](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/plugins/mac-vnc/README.md)
- **E15:** [tests/crons.test.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/tests/crons.test.ts); [issue #72](https://github.com/lucasgelfond/biscotti/issues/72) (not reproduced)
- **E16:** [core/vm/Dockerfile](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/core/vm/Dockerfile), [installer/local/lima.yaml](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/installer/local/lima.yaml), [nix/update.nix](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/nix/update.nix), [pnpm-lock.yaml](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/pnpm-lock.yaml), [flake.lock](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/flake.lock)
- **E17:** [package.json](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/package.json); [public metadata](https://api.github.com/repos/lucasgelfond/biscotti), [releases](https://api.github.com/repos/lucasgelfond/biscotti/releases), [tags](https://github.com/lucasgelfond/biscotti/tags)
- **E18:** [tests/vitest.config.ts](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/tests/vitest.config.ts), [tests/bench/RESULTS.md](https://github.com/lucasgelfond/biscotti/blob/b68629c7211593c6f1a85ff04b3e8038a77ffbcc/tests/bench/RESULTS.md)

**Attribution:** Lucas Gelfond / lucasgelfond/biscotti, MIT. Analysis based exclusively on public source.
