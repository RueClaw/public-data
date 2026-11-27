# RavenTrap, formerly Huginn (ancientswede/Huginn)

**Repo:** https://github.com/ancientswede/Huginn
**License:** AGPL-3.0-or-later; bundled web rules MIT, world map CC BY 4.0. Network-service and redistribution obligations matter.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** 9531ef03d5edec65a59e588642aed634b7d943c3; main and peeled v1.0.0-rc5. Scope: application, honeypot helpers/installers, deployment, tests, workflows and documentation.
**Verification:** Static review only; no source execution, installation, live honeypot probes, accounts or paid calls. Public GitHub metadata and upstream CI results inspected anonymously.
**Stack:** Python standard library, SQLite, embedded HTML/CSS/JavaScript, OpenSSH, Bash, systemd; optional Docker.
**What it is:** A small self-hosted attacker-intelligence dashboard that pulls honeypot logs, groups activity and publishes firewall feeds. This is **not** the Ruby automation platform [huginn/huginn](https://github.com/huginn/huginn).

---

## Verdict

⚠️ **Interesting — a thoughtful isolated-lab candidate, not a turnkey security boundary.** The pull-only collection design, extensive regression tests and explicit recovery machinery are unusually concrete for a young homelab tool. However, root-side export helpers, default network exposure, optional outbound intelligence services and attacker-controlled blocklist inputs demand an operator who understands segmentation. Treat scores, campaign labels and malware families as investigative heuristics, not verified attribution or automatic permission to block production users.

## What It Is

Ancientswede's project is already branded **RavenTrap** in the reviewed README and UI. The repository still resolves anonymously as ancientswede/Huginn; HUGINN_ settings, service names and feeds intentionally retain the old name. The latest inspected release is **v1.0.0-rc5**, a prerelease published 2026-11-23 at 17:40:03 UTC. Its annotated tag object is 4dc2be253c1778ffcfc1863e18db77ae64204fcb, peeling to the reviewed SHA. The source commit is dated 2026-11-23 at 17:35:44 UTC. The release says rc4 was included rather than published separately; the advertised 1.x stability promise is not evidence that a final 1.0 release exists. [E1, E2]

The intended layout is two machines: an internet-facing, independently isolated honeypot running Cowrie, OpenCanary, endlessh and custom traps; and a private dashboard that pulls exports over SSH. It is useful for learning what scanners actually do, replaying fake-shell sessions and building a narrowly scoped local feed. It is not an EDR, a general SIEM or an autonomous incident responder.

Public metadata at review time: **44 stars, 1 fork, 0 open issues**, last pushed 2026-11-23. These are a snapshot, not evidence of safety or broad operational adoption. No previous review matching either this canonical repository or its RavenTrap name was found in the public index/reviews.

## Stack

| Layer | Technology and boundary |
|---|---|
| Web application | 9,603-line app.py; standard-library HTTP server, server-rendered HTML and embedded CSS/JS |
| Storage | SQLite WAL, thread-local connections; compressed session recordings stored separately |
| Collection | OpenSSH client, pinned known-hosts after enrollment, constrained root SSH export on honeypot |
| Sensors | Cowrie, OpenCanary, endlessh, hp-traps; optional Suricata |
| Authentication | One shared password, scrypt hash, hashed session tokens; no multi-user RBAC or SSO found |
| Deployment | Debian scripts/package, hardened systemd service or non-root Docker container |
| Integrations | HTTPS/DNS intelligence providers, optional ntfy and token-protected Prometheus |

## Key Features

### Investigation organized around an address

Attacker pages combine attempted credentials, commands, sessions, captured-file metadata and enrichment. Terminal replay fetches bounded recordings by validated hashes and caches compressed copies. Campaign grouping uses command shapes, SSH fingerprints, web rules and IDS signals. Bait/persona features distinguish interaction with planted material. These mechanisms are present in app.py and helpers; detection precision and resistance to evasion were not measured. [E3, E4]

### Useful feeds, but imperfect evidence

The application generates plain text, nftables, ipset, MikroTik, CSV and C2 feeds, selected by bearer-like tokens embedded in URLs. Score/age filters, manual allow/block flags, IPv6 options, benign-scanner/Tor handling, a default public-resolver exclusion list and a 50,000-address cap provide controls. Manual blocks explicitly override never-block exclusions. C2 promotion requires multiple source attackers, which raises the bar but does not establish independent corroboration. A compromised sensor can still fabricate events for other public addresses. Start with observation, short windows and allowlists, not automatic broad production enforcement. [E3: blocklist_ips, c2_list; E5]

### Static malware triage without transferring payloads

hp-fileinfo reads file bytes on the honeypot, recognizes basic formats/architectures and extracts strings/IOCs; it labels families as guesses. Its inspected limits include an 8 MiB analysis prefix, a 256 MiB full-hash ceiling and an 80-second work budget. Routine exports carry analysis, not malware binaries; manual sample ZIP creation is a separate operator action. This reduces exposure but does not make the hostile-data parser trustworthy by definition, or make string matching equivalent to sandbox analysis. [E4]

## Architecture

The serve entry point initializes/migrates SQLite, then starts collector, optional enrichment and backup threads alongside a bounded threaded HTTP server. Every roughly two minutes the collector pulls a capped SSH export, validates/parses sections, stores and deduplicates events, recomputes summaries, fetches recordings and updates health/notification state. Collections recover by retrying later, not through a durable external queue. The export itself takes bounded recent log windows, so outages or high event volume can lose history that has already fallen out of those windows. [E3: serve, collector_loop, fetch_export; E4: hp-export]

The single-file design avoids framework/build complexity, but couples web routing, SQL, auth, enrichment, classification and UI in nearly ten thousand lines. Many focused tests offset some maintenance risk; they do not remove the burden of reviewing a custom HTTP/auth implementation. The app's standard-library-only claim is credible for Python imports, **not for the complete installed system**: SSH, OS packages, the Python Docker base and separately installed sensor dependency trees remain necessary. [E3, E7]

## Trust, Authentication and Privacy

### Separation is real only when the network enforces it

The dashboard initiates SSH to the honeypot; the honeypot does not need access back to the LAN. The installed SSH key is restricted to hp-export with forwarding disabled. Nevertheless, this is a **root authorized-key forced command**, not a wholly unprivileged read-only service: goodbye and IDS on/off commands change state. hp-export drops privileges before opening attacker-owned logs/recordings/files, validates recording hashes and filters section-marker injections. Those are valuable defenses, not proof that a fully compromised honeypot cannot attack the dashboard through malicious exports. Systemd filesystem sandboxing is not network isolation. [E4, E6]

The supplied installation changes services, SSH configuration and firewall setup with root privileges. Keep the sensor on a separate VM/VLAN with externally enforced LAN/router and IPv6 restrictions; audit required public egress separately. The isolation documentation explicitly warns that port forwarding or a different subnet is insufficient. No isolation was tested in this review. [E6]

### Web defaults require deliberate hardening

The backend defaults to binding all interfaces on HTTP port 8095; Compose publishes the port without a specific host address. There is no native TLS in the inspected server. Use private ingress plus TLS termination, specify allowed hosts and configure trusted proxy addresses narrowly. The normal installer populates HUGINN_ALLOWED_HOSTS, but an empty application setting accepts any Host header. Secure cookies are enabled only when a configured trusted proxy reports HTTPS. Do not expose this UI directly to the internet. [E3: configuration, Handler; E7]

Positive controls include scrypt (N=16384, r=8, p=1), HttpOnly/SameSite=Strict cookies, stored SHA-256 session-token hashes, same-origin checks before POST mutations, per-IP login throttling and bounded simultaneous password verification. Request bodies, total connections and per-address connections have limits; CSP disallows inline scripts and attacker strings are escaped in reviewed rendering paths. No permissive CORS header was found. These are static observations, not a penetration-test result. Shared-password access is administrator-equivalent; there is no per-investigator privilege separation. [E3: login helpers, Handler, SEC_HEADERS, HuginnServer; E8]

SSH collection enforces StrictHostKeyChecking after enrollment. However, Docker's initial ssh-keyscan is automatically trusted before the printed fingerprint is compared; the shell installer prompts, with trust as the default. Verify or pre-provision the host key out of band rather than treating first-use discovery as authentication. [E7: entrypoint and installer]

### “Local” is not “no egress”

| Path | Data leaving and implications |
|---|---|
| Default IP enrichment | Public attacker IPs go to ipwho.is, Shodan InternetDB and GreyNoise; recipients also observe normal network/request metadata |
| DNS intelligence | Team Cymru, DroneBL, Spamhaus, Abusix and optional Project Honey Pot reveal query addresses to DNS infrastructure; http:BL embeds its key in an unencrypted DNS query |
| Malware lookups | Optional MalwareBazaar/VirusTotal send SHA-256 hashes, not files, when configured with keys |
| Tor/update checks | Periodic Tor list and GitHub tag downloads; these still reveal the requesting network to services |
| Optional ntfy | Summaries can include attacker addresses and activity; HTTP endpoints are supported, and public topics need access controls |

**Important switch caveat:** HUGINN_ENRICH=0 prevents starting the enrichment thread, but is not a universal offline switch. collector_loop still invokes MalwareBazaar lookup when a key exists, update checks and notifications independently. Settings credential tests can also initiate calls. Disable each unwanted integration/remove its key, turn off update checks and enforce egress policy if offline operation is required. This follows the actual call graph rather than interpreting “turn it all off” as a global guarantee. Redirect rejection in api_urlopen limits credential forwarding for reviewed HTTPS calls. [E3: serve, collector_loop, mb_lookup, enrich_loop, api_urlopen, notify; E9]

Captured credentials, IPs, session text, feed tokens and integration configuration are sensitive. UI-saved provider keys are stored as ordinary SQLite meta values, not encrypted by an external secret manager. Protect the service account, environment, database, SSH key, volume and backups together. Feed tokens in URL paths can leak through reverse-proxy logs or copied URLs even though app logging redacts feed paths. IP masking and retention reduce some disclosure; they are not anonymization of arbitrary terminal content. [E3, E9]

## Persistence and Recovery

SQLite uses WAL with synchronous=NORMAL, an appropriate local throughput tradeoff but not a promise of zero acknowledged-transaction loss on power failure. The schema and incremental startup migrations live in app.py. Defaults retain 180 days of history and cap repeated decoy events. Retention also deletes orphaned enrichment/recordings and removes identifying examples from first-sighting summaries; manual flags and rotating backups remain. Sensor-captured malware defaults to indefinite retention, separately from dashboard history. [E3: connect, init_db, retention; E10]

Automatic database backups use SQLite's backup API, integrity checks, restricted permissions, compression and atomic replacement; restore requires an exclusive lock, checks the database, retains the previous database and swaps the restored copy. These are strong implementation signals. They are still **same-disk database backups**, not full disaster recovery: session recording files, configuration and SSH identity require a coordinated external backup. Restoring the database loses newer events unless still present in the sensor export, and does not magically restore missing recordings. The update script documents code/database rollback; no restore/update rehearsal was performed here. [E3: backup_db, restore_db; E10]

## Dependencies, License and Supply Chain

The repository's README and source notices identify AGPL-3.0-or-later, with the AGPL v3 text in LICENSE. Preserve notices and provide corresponding source as required when distributing covered work or offering modified versions for remote interaction; the precise obligations are broader than merely adding a footer. The derived Krawl rules have a separate MIT notice, and the simplified world-map data is CC BY 4.0 with attribution requirements. No source code or bundled assets were extracted into this review. [E11]

Default sensor setup clones Cowrie's current branch unless a ref is selected and installs OpenCanary from pip without a version pin. The Docker base and Actions dependencies use mutable tags rather than immutable digests/SHAs. CI checks compatibility against current upstream sensors; that is useful but does not make builds reproducible. Release workflows attach checksums and request build-provenance attestations. Their configuration and successful run status were observed, **not** the cryptographic validity of downloaded release artifacts. [E7, E12]

## Tests, CI and Evidence Quality

A static count found **733 test-method definitions** across tests/, consistent with the README's “700+” claim; that count is not a pass count or coverage figure. Inspected regressions cover retention privacy, redirect credential leakage, blocklist poisoning guardrails, parser nesting, session/auth races and honeypot privilege boundaries. Some tests inspect script strings or mock integrations, so passing them cannot establish real network isolation or complete installation safety. [E8]

CI config includes Python 3.11–3.13 compilation/unit tests/demo generation, historical database upgrades, ShellCheck, a Docker build/start check and upstream sensor-patch checks. The anonymous Actions API reported **success** for the exact source SHA's [Tests run](https://github.com/ancientswede/Huginn/actions/runs/45230113789), [Docker image run](https://github.com/ancientswede/Huginn/actions/runs/45230132549) and [Release files run](https://github.com/ancientswede/Huginn/actions/runs/45230132811). These are upstream results, not tests executed for this review. [E12]

The README openly says Claude wrote code/tests/docs under the maintainer's direction, reports daily personal use and fresh-machine end-to-end checks, and describes AI security reviews rather than a human audit. Those are author claims. We did not independently reproduce them, measure the advertised 1-core/512-MB footprint, assess classification accuracy or validate sustained hostile traffic handling. Development and many security fixes are recent; the release-candidate status warrants a staged pilot rather than production trust. [E1, E2]

## Comparison

| Option | Best fit | Tradeoff versus RavenTrap |
|---|---|---|
| [Cowrie](https://github.com/cowrie/cowrie) alone | Focused SSH/Telnet research and session capture | Fewer orchestration pieces; supply your own history/correlation/dashboard. It is also a RavenTrap sensor, not a wholly separate replacement. |
| [OpenCanary](https://github.com/thinkst/opencanary) alone | Lightweight decoy-service detection and alerting | Simpler detection focus; not the same integrated attacker dossier, replay and campaign workflow. Also used underneath RavenTrap. |
| [T-Pot](https://github.com/telekom-security/tpotce) | A broader multi-honeypot platform and research environment | More breadth and operational machinery; compare its resource/isolation needs before adopting for a small homelab. |
| [huginn/huginn](https://github.com/huginn/huginn) | General event-monitoring automation | A name collision, not a honeypot-intelligence substitute. |

Alternative identities/descriptions were checked against their public repositories; this is a functional comparison, not a head-to-head benchmark or an audit of those alternatives. Choose standalone Cowrie/OpenCanary for a narrower experiment, RavenTrap for a compact integrated view, and investigate T-Pot when breadth justifies additional operations.

## Self-Hosting Notes

1. Use disposable, separate sensor infrastructure and enforce isolation outside the guest; verify LAN, gateway and IPv6 restrictions before any internet forwarding.
2. Keep the dashboard private, terminate TLS, restrict the published interface/port, set allowed hosts and use a narrowly configured trusted proxy.
3. Pin source/image and sensor versions, inspect privileged installers and verify SSH fingerprints independently. Treat the dashboard key's constrained root command as a real trust boundary.
4. Review every outbound integration and its terms; do not mistake ENRICH=0 for offline mode. Protect secrets and copies of captured content.
5. Begin with feeds in observation-only mode; define never-block networks, false-positive handling, expiry and an independent firewall rollback path.
6. Back up database, recordings, configuration and identity off-host, and test restore and upgrade rollback before relying on them.

**Bottom line:** worth a carefully contained homelab evaluation and studying for its constrained pull/export and recovery patterns. Not recommended as an unaudited public dashboard or as unquestioned authority over production firewall policy.

## Evidence and Limitations

All source links below are pinned to the reviewed commit. This is a targeted static inspection, not a complete line-by-line audit. No repository programs, tests, installers, payloads or demos were executed; no accounts or API credentials were supplied. No performance, exploitability, classification-quality or recovery-success claim is independently established.

- **E1:** [README and identity](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/README.md).
- **E2:** [v1.0.0-rc5 release](https://github.com/ancientswede/Huginn/releases/tag/v1.0.0-rc5), [stability promise](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/docs/stability.md).
- **E3:** [Application implementation](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/app.py), with function names cited above for precise navigation.
- **E4:** [Honeypot helpers](https://github.com/ancientswede/Huginn/tree/9531ef03d5edec65a59e588642aed634b7d943c3/honeypot), especially hp-export, hp-fileinfo and hp-add-huginn-key.
- **E5:** [Blocklist documentation](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/docs/blocklists.md).
- **E6:** [Isolation model](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/docs/isolation.md), [sandbox setup](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/honeypot/setup-sandbox.sh).
- **E7:** [Dockerfile](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/Dockerfile), [Compose](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/docker-compose.yml), [container entrypoint](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/docker/entrypoint.sh), [dashboard installer](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/install-huginn.sh), [sensor installer](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/install-honeypot.sh), [systemd unit](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/systemd/huginn.service).
- **E8:** [Regression suite](https://github.com/ancientswede/Huginn/tree/9531ef03d5edec65a59e588642aed634b7d943c3/tests), particularly test_appsec_review.py, test_rc2_review.py and test_backups.py.
- **E9:** [Security and privacy documentation](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/docs/security.md).
- **E10:** [Operations and recovery](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/docs/operations.md).
- **E11:** [License](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/LICENSE), [MIT rules notice](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/static/web-rules.LICENSE), [map attribution](https://github.com/ancientswede/Huginn/blob/9531ef03d5edec65a59e588642aed634b7d943c3/static/world-map.LICENSE.md).
- **E12:** [Workflow definitions](https://github.com/ancientswede/Huginn/tree/9531ef03d5edec65a59e588642aed634b7d943c3/.github/workflows); upstream run links are in the CI section.

---

**Attribution:** Ancientswede / ancientswede/Huginn (RavenTrap), AGPL-3.0-or-later; separately attributed MIT web rules and CC BY 4.0 map data. Independent review; no endorsement implied.
