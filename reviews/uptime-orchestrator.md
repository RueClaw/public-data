# Uptime Orchestrator (uptime-lab/orchestrator)

**Repo:** https://github.com/uptime-lab/orchestrator
**License:** Mixed FCL-1.0-ALv2 / Apache-2.0; the control plane is fair source, not currently OSI open source.
**Reviewed:** 2026-11-25 (UTC)
**Revision:** 261d8516910a036a21fa49525dcd39c8376bcd48 — main and peeled platform-v0.2.1 tag; repository-wide static sampling of server, agent, frontend manifests, signer/deployment documentation and workflows.
**Verification:** Anonymous public GitHub metadata, HTTPS checkout, release/tag resolution, source inspection and public CI job results. No software installed or executed; no hardware, hosted accounts, live service probes or paid calls.
**Stack:** Go, Echo, gRPC, PostgreSQL/GORM, React/TypeScript/Vite, Python EEPROM signer, Docker Compose.
**What it is:** Network boot, recovery and privileged fleet administration for Raspberry Pi 4/5 and Compute Module 4/5—not an AI-agent orchestrator or uptime monitor.

---

## Verdict

⚠️ **Interesting — a credible Pi recovery control plane, but pilot before trusting a fleet.** Signed network recovery that survives a wiped system disk is the useful differentiator. Substantial implementation and successful public CI support taking it seriously; beta qualification gaps, single-backend operation, root-equivalent fleet authority and restrictive server licensing prevent an unconditional deployment recommendation.

## What It Is

Uptime Lab combines adoption, per-device EEPROM preparation, signed HTTP network recovery, OS deployment and ongoing administration. The board initiates outbound gRPC; a local PXE/TFTP server and inbound connections to each board are unnecessary. Wired Ethernet, working DHCP/DNS and reachability of the chosen server still matter. Pi 4/5 and CM4/5 support is a project claim, not a hardware certification from this review. [1]

The network-first bootloader fetches a signed RAM recovery image or falls back to its local drive when recovery is withheld or unreachable. That can repair a corrupted or empty drive, but cannot recover a dead board, failed network, unavailable server or lost signing identity. The recorded six-minute installs and 57/73-second recovery demonstrations are maintainer-reported examples, not independent benchmarks. [1][2]

## Stack

| Layer | Tech |
|---|---|
| Control plane | Go 1.26 toolchain; Echo HTTP API, WebSocket updates, bidirectional gRPC |
| State | PostgreSQL via GORM/pgx; local or configured object storage for images/artifacts |
| Browser | React 19, TypeScript, Vite, TanStack Query/Router, xterm, React Flow |
| Device | Separate Go agent module; root systemd service; Linux command handlers |
| Boot/deployment | EEPROM signer, signed recovery image, Docker Compose and reverse proxy |
| Identity | Password/OIDC, passkeys/TOTP, JWT access tokens, session/step-up services and scoped authorization |

Manifest evidence: [3]. Runtime and deployment evidence: [4][5].

## Key Features

### Recovery and imaging are implemented, not just a diagram

The Linux command handler streams images, invalidates the target's bootability before writing, verifies the digest and checks agent package signatures before installation. This is deliberately destructive reimaging, **not an A/B rollback transaction**: a failed install may leave the old system unusable and require another recovery attempt. Holding boot metadata back is a safety measure against booting a partial image, not a backup. [6]

### Day-two management has real service boundaries

Access entries, scoped utilities, secrets, versioned files, images, node commands and workflow execution have distinct domain/service implementations. The workflow engine includes state settlement, timeouts and tests for redispatch/recovery; node deletion explicitly abandons active execution nodes rather than leaving capacity occupied forever. The agent exposes root terminal and OS/EEPROM/disk/file operations. Feature breadth is substantial, although only representative paths were traced. [7][8]

### Security mechanisms are useful but do not reduce operator authority

JWT middleware pins HS256 and access-token type. Authorization resolves active membership and account/organizational-unit permissions rather than trusting role claims in the JWT. Separate services implement reauthentication, passkeys and two-factor checks. These are meaningful controls, not proof that every endpoint is free of authorization errors. [9]

## Architecture

The backend separates domain models, application services/ports and infrastructure adapters; PostgreSQL is durable state, while streams, terminal admission, several tickets/locks, workflow workers and quotas have process-local components. The supported shape is **one backend replica**. Adding replicas is not a supported availability upgrade: it can split device streams, duplicate workers and weaken admission/credential locking. [4][10]

The Go agent connects to the platform and dispatches privileged handlers. The service explicitly uses root and disables two common systemd restrictions; this is a fleet administration authority, not a sandbox. A separate EEPROM signer holds the installation's recovery-signing identity. Agent release keys are a different trust domain, embedded as verification keys, with detached signatures checked before package installation. Recovery-image production is in a separate repository and hosted deployment tooling is private; neither was reviewed here. [5][6][11]

## Security, Privacy and Egress

- **Authority:** platform operators and anyone controlling its host/database/secrets can control adopted devices as root. Device adoption is a transfer of trust, including arbitrary scripts, disk erasure, filesystem writes and login configuration—not merely monitoring permission. [5]
- **Transport:** signed HTTP boot protects recovery authenticity, not confidentiality or availability. Serial-only boot paths disclose the recovery target state to someone knowing the serial. Leave the unauthenticated boot-request failsafe disabled on internet-exposed systems. Local-network mode permits plaintext web/device traffic; do not treat a LAN as inherently confidential. With externally terminated gRPC TLS, the server trusts the declaration that a proxy actually provides TLS. PROXY-protocol-off mode retains a global preauthentication cap but cannot enforce a meaningful per-source cap behind that proxy. [1][10]
- **Secrets:** AES-256-GCM with random nonce and fallback keys supports encryption/rotation at rest. It is not protection from the host operator, and the input key is SHA-256-derived rather than password-hardened; use high-entropy generated key material. Image backups can contain entire device disks and their credentials. [12][13]
- **Documented credential exposure:** a literal reusable Tailscale utility key is readable by scoped node viewers. The documented workaround is a variable reference or short-lived/single-use key; the implementation refuses references flagged sensitive, so do not assume arbitrary sensitive-secret injection is supported. Reference-derived payloads have separate redaction handling. This known tradeoff matters in a mixed-trust account. [10][14]
- **Browser boundaries:** CORS is configurable, with wildcard origins in the fallback branch; WebSocket origin policy is independently constructed. Bearer authentication means wildcard CORS alone is not evidence of an authentication bypass. Validate production origins and proxy settings rather than relying on the toggle name. [15]
- **Data/egress:** the control plane holds device identity, hardware/status reports, command history, users, secrets, files and images. Devices talk to the chosen platform; optional Tailscale/ZeroTier and software installation add vendor/package endpoints. Self-hosting still involves release/container/package retrieval, optional OIDC/SMTP/object storage and certificate issuance. SECURITY.md says there is no version check that phones home; that is a bounded project statement, not an independently measured absence of all telemetry. No packet capture or hosted privacy-policy audit was performed. [1][3][5][16]

## Persistence, Recovery, Deletion and Rollback

Back up the database **and** image/object storage **and** encryption/signing keys. Losing the EEPROM private key can require physical reflashing of each board; restoring encrypted database rows without the encryption key does not restore their contents. Keep keys separately escrowed and rehearse restoration. The backup guide reports empty-host restoration, but explicitly says device reconnection to a restored server and restoration during key rotation have not been exercised. [13]

Schema-version guards refuse older software against a newer database. Roll back by restoring the pre-upgrade backup or roll forward; changing a container tag alone is not sufficient. Agent downgrades have an explicit override path, distinct from normal updates. The install guide says a schema-changing upgrade has not yet been exercised. [2]

Node deletion, uninstalling the agent and changing EEPROM trust are different actions. Forced deletion can request credential removal, but it is best-effort; an offline board retains its local identity until acted upon. Uninstall does not undo the EEPROM configuration. Moving servers requires adoption and bootloader changes, not merely deleting a database row. Tombstones and boot-path state need deliberate cleanup. [2][8]

Audit retention defaults to one year; ordinary command retention defaults to unlimited. The retention service runs hourly in bounded batches. Account/device deletion should not be equated with secure erasure of off-host backups, full-disk images, or external object storage. Establish an explicit retention/decommissioning policy. [17]

## Maturity, Supply Chain and Verification

At retrieval GitHub reported 6 stars, 0 forks and 5 open issues (GitHub's aggregate includes pull requests), with last push 2026-11-25T11:10:13Z. These are a snapshot, not quality metrics. Latest published platform release was **platform-v0.2.1**, 2026-11-25T11:14:00Z; its annotated tag peels to the reviewed SHA. The commit timestamp is 2026-11-25T11:06:45Z. [18]

The source contains 709 Go test files at this revision, Go checksums and a frontend pnpm lockfile. CI defines build/vet/tests, PostgreSQL integration checks, frontend checks, signer and installer tests, with commit-pinned Actions. Jobs are gated by PUBLIC_CI_ENABLED; merely seeing workflow files would not establish execution. Here the public CI run for the reviewed SHA reported **backend, agent, frontend, installer and EEPROM-signer jobs all successful**. Publication guard and platform release workflows also reported success. This review did not rerun them or audit complete logs, and a successful build is not proof of hardware recovery. [19]

Scheduled vulnerability scanning is configured but no security-scan conclusion is asserted here. Community Compose uses version tags for platform images and mutable PostgreSQL/Traefik tags; kiosk images are also tag-based. Lockfiles, detached package signatures and workflow pinning improve provenance, but do not make every consumed artifact immutable or independently reproducible. Release image digests, SBOM contents, signatures and hardware-token custody were not independently verified. [4][10][11][20]

The installer guide explicitly leaves bring-your-own proxy, SD provisioning, mail/OIDC, schema-changing upgrades and non-uid-1000 first users unexercised. Support is latest-release-only without backports; self-hosters receive no advance security notification before publication. Plan monitoring and upgrades accordingly. [2][5]

## License and Costs

Agent, protocol and tools are Apache-2.0; most server/frontend/signer/docs content is FCL-1.0-ALv2, with detailed exceptions in LICENSE/REUSE.toml. FCL forbids competing commercial use and circumvention of protected device-entitlement functionality; each version gets Apache-2.0 rights on its second anniversary. Do not describe the entire current platform as unrestricted open source. Preserve notices, check component licensing, and respect separate trademarks. No code was extracted for reuse in this review. [21]

Self-hosting is free for 25 devices per server across accounts; hosted free allowance is 10 devices per account. Larger installations need entitlement/subscription arrangements; the README says subscriptions are not yet on sale and gives no numeric paid price. Budget for server memory/disk, image bandwidth, backups, hardware and operational time. There is no LLM/API-token cost inherent to this application. The README says admitted devices continue working when entitlement expires, while new admission waits. [1][22]

## Comparison

These are architectural alternatives, not fresh comparative benchmarks or pricing audits.

| Approach | Better fit | Tradeoff versus Orchestrator |
|---|---|---|
| [Ansible](https://github.com/ansible/ansible) plus SSH | Existing bootable Linux fleets and declarative administration | Needs reachability/working OS; does not itself supply this signed Pi recovery boot chain |
| [Mender](https://github.com/mendersoftware/mender) | Managed OTA updates with an explicit rollback design | Different image/partition workflow; A/B recovery is not recovery from an entirely wiped disk |
| [Raspberry Pi network boot](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#network-booting) | Small controlled labs wanting minimal control-plane machinery | More manual provisioning/management; no equivalent integrated scoped UI and fleet workflow engine |

## Self-Hosting Notes

Pilot on expendable wired Pi hardware with a stable server name, one backend, production TLS and a tested proxy. The documented baseline is an x86-64/arm64 Debian/Ubuntu server with 4 GB RAM plus image storage; internet deployment needs ports 80/443/50051. Do not execute the convenience installer without reviewing its host-level effects. [1][2][4]

Before production: test wiped-drive recovery, interrupted writes, server loss/restore with an actual device, upgrade rollback, credential revocation and offline decommissioning. Avoid literal reusable utility keys, pin artifact digests where feasible, escrow signing/encryption keys, and validate every enabled external integration. A limited pilot is justified; broad unattended deployment is not established by this static review.

## Evidence

All repository links below are pinned to the reviewed commit. Documentation statements are distinguished above from code inspection and external CI observations.


[1]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/README.md
[2]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/docs/INSTALL.md
[3]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/frontend/package.json
[4]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/docker-compose.community.yml
[5]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/SECURITY.md
[6]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/agent/pkg/application/handlers/command_handler_linux.go
[7]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/backend/pkg/webapp/application/services/workflow_execution/engine.go
[8]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/backend/pkg/webapp/application/services/workflow_execution/abandon.go
[9]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/backend/pkg/webapp/infrastructure/http_server/middleware/authz.go
[10]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/docs/SECURITY-ACCEPTANCES.md
[11]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/docs/ARTIFACT-SIGNING.md
[12]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/backend/pkg/webapp/infrastructure/crypto/aes.go
[13]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/docs/BACKUP-RESTORE.md
[14]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/backend/pkg/webapp/application/services/utility/param_refs.go
[15]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/backend/pkg/webapp/infrastructure/http_server/server.go
[16]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/agent/pkg/application/handlers/utility_tailscale_linux.go
[17]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/backend/pkg/webapp/application/services/retention/service.go
[18]: https://github.com/uptime-lab/orchestrator/releases/tag/platform-v0.2.1
[19]: https://github.com/uptime-lab/orchestrator/actions/runs/45601396468
[20]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/.github/workflows/security.yml
[21]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/LICENSE
[22]: https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/docs/ENTITLEMENT.md

Additional implementation evidence: [JWT middleware](https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/backend/pkg/webapp/infrastructure/http_server/middleware/jwt_auth.go), [root service](https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/agent/orchestrator-agent.service), [CI definition](https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/.github/workflows/ci.yml), [backend manifest](https://github.com/uptime-lab/orchestrator/blob/261d8516910a036a21fa49525dcd39c8376bcd48/backend/go.mod).

**Attribution:** Uptime Lab and uptime-lab/orchestrator contributors. Mixed FCL-1.0-ALv2 / Apache-2.0; independent review, no endorsement implied.
