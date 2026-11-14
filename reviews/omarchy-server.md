# Omarchy Server (TouchWorkStation/omarchy-server)

**Repo:** https://github.com/TouchWorkStation/omarchy-server
**License:** MIT, copyright 2026 Chris Jordan; retain copyright and permission notices when reusing code. Dependencies, icons, app-store entries and guest operating systems have separate terms.
**Reviewed:** 2026-11-14 (UTC)
**Revision:** 41385a44fceb03e982e93d4ca8048816c489ef12 — main, package version 0.9.13; repository-wide static inspection focused on installation, privileged helper, backend, web gateway, app/VM lifecycle, tests and CI. Commit dated 2026-11-14T19:57:31Z.
**Verification:** Static review only; no source execution, dependency installation, live service probes, images, containers, disks or desktop sessions. Public GitHub CI result checked separately.
**Stack:** Node.js ES modules, Express, ws, YAML; React 18/TypeScript/Vite; rootless Podman/Compose, QEMU/libvirt, wayvnc/noVNC, systemd, Btrfs and optional ZFS.
**What it is:** An independent browser-based home-server control plane for an existing x86-64 Omarchy desktop, with apps, files, virtual machines, storage and remote desktop. It is not an official Omarchy server edition or merely a monitoring dashboard.

## Verdict

⚠️ **Interesting — a coherent home-lab pilot, not yet a primary NAS or internet-facing administration recommendation.** The integration is substantial and includes real defensive work: user-session virtualization, rootless containers, a constrained root helper, authenticated console tickets and scoped setup-script execution. But default HTTP, exceptions to app-port authentication, mutable installation inputs, incomplete rollback/uninstall and storage/configuration edge cases matter much more than the polished desktop metaphor.

Use a spare machine with disposable data first. A successful upstream test run is useful evidence, not proof that hundreds of apps, drive layouts and recovery paths are safe.

## What It Is

The [README](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/README.md) explicitly says the project is independent of Omarchy, which it credits to DHH and its contributors. The normal installer adds a service layer to Arch Linux/Omarchy rather than replacing the desktop. A separate ISO-building tree supplies a guided Arch installer followed by first-boot downloads of this project and Omarchy; that path can erase a selected drive and must not be confused with installing the web app on an existing machine.

The intended operator is a single home-server owner who wants phone/tablet access and a desktop-like browser workspace. The advertised catalog of about 580 apps is an upstream claim about external stores, not 580 implementations bundled or compatibility-tested here. App stores are fetched separately, including Umbrel-format manifests. The UI's Proxmox-style VM panels do not imply Proxmox clustering, HA or its backup ecosystem.

## Stack and Architecture

| Layer | Implementation and authority |
|---|---|
| Browser | React/TypeScript, TanStack Query, noVNC and xterm; mobile screens and draggable desktop windows |
| Web gateway | Express on 0.0.0.0:7780 by default; HTTP and HTTPS on one port; same-origin API, opaque HttpOnly session cookie, method allowlist |
| Backend | omarchyd on loopback :2021; accounts, app gateways, files, VM lifecycle, system and storage procedures |
| Persistence | JSON files, several temp-file/rename writers, in-memory queues and tickets; no external database |
| Containers | docker-compose talking to the user's Podman socket; app catalogs become generated Compose projects |
| Machines | qemu:///session, passt user networking, qcow2 disks and private VNC sockets |
| Privilege bridge | Root-owned helper installed under /usr/local/libexec with a NOPASSWD sudoers entry for that executable |
| Host integration | systemd user services, linger, wayvnc desktop service, desktop launcher and Omarchy/Waybar widget |

The split between an outward-facing gateway and a loopback backend is intelligible. The [gateway](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/server/app.mjs) mediates credentials and restricts RPC names; the [backend](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/omarchyd/server.mjs) composes feature modules. However, several central modules are 1,300–1,500 lines, runtime JavaScript is not covered by the frontend TypeScript check, and many best-effort catch blocks obscure partial failure. This is a high-authority owner console, not tenant isolation: its terminal is the owner's real login shell and its Files root is the real home directory.

## Key Features and Positive Controls

- **One interface for several real subsystems.** App installs, dependent apps, lifecycle/logs, VM disk/network/console management, home-folder browsing/trash, SMB, SMART and pool management are implemented rather than just illustrated.
- **Useful credential separation.** [Accounts](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/omarchyd/accounts.mjs) use salted scrypt hashes and timing-safe comparisons, serialized per-account password checks with increasing delays, random tokens and TOTP replay tracking. Device sessions can be revoked; a password change clears backend sessions. TOTP replay state is in memory, so the once-only claim does not survive a backend restart within the same time step.
- **Console admission.** Backend tickets are single-use and expire after 30 seconds. VM and desktop VNC endpoints use private Unix sockets rather than public VNC ports; the web WebSocket bridge checks Origin. Remote desktop sign-in requires the owner password again.
- **Setup-script confinement.** App exports.sh runs through bubblewrap with an isolated network namespace, read-only system files, a clean environment, an app-only writable bind and a 15-second timeout. New installs get app-scoped derived secrets rather than the master derivation key. This sandbox applies to setup exports, not to arbitrary runtime app behavior.
- **Explicit resource safety intent.** The helper allowlists verbs and argument shapes, uses argv rather than interpolated command shells, checks candidate drives, and mounts managed Btrfs pools nosuid,nodev. VM monitor commands are allowlisted to exclude host-file/execution features.

## Installation, Update and Removal: Actual Effects

The [installer](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/install.sh) must start as a normal user, but “not with sudo” does **not** mean unprivileged installation. It installs missing Arch packages with sudo, potentially adds subordinate UID/GID ranges, enables the user Podman socket, installs the root helper and sudoers rule, enables lingering, rewrites its three user-service files, starts the services and can create temporary 2 GiB swap for low-memory builds. It adds a launcher and initially offers the top-bar widget automatically.

It allows TCP 7780, TCP/UDP 40000–49999 for future VM forwards, and TCP 7800–7899 for relays through UFW when available. Rules are not restricted to a trusted subnet. Runtime app/SMB operations open more ports. The normal installer does not configure host SSH or install a new SSH authentication system. Cloud-init guests, separately, enable SSH password authentication and accept validated public keys.

The optional --zfs path is much more invasive: it can remove an archzfs repository stanza, run Omarchy/system upgrades, install kernel headers or a matching kernel, build AUR zfs-utils/zfs-dkms noninteractively, load the module and enable ZFS services. Kernel/OpenZFS compatibility remains operational work, not a solved appliance property.

### Pinning and preservation

- The documented curl-to-shell installation fetches main, then clones/fetches main again. No signed-release or exact-commit verification gates the execution. The re-run installer uses git reset --hard in its app checkout, losing local source edits.
- package-lock.json and npm ci constrain npm dependency resolution, but scripts/deps.mjs invokes npm ci with lifecycle scripts enabled. This is not a hermetic build; Arch packages, AUR inputs, catalogs and container images add independent trust roots.
- [The web updater](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/omarchyd/updater.mjs) compares remote package versions, fetches/reset-builds in place, then schedules service restart. It does not bind the selected version/check result to an immutable commit. Root-helper/package changes are reported as a need to rerun the installer; web update does not apply them.
- On a caught update failure it attempts the previous Git revision and rebuild. Restoration errors are swallowed, yet the message says “nothing changed.” That is best-effort code rollback, not a verified transactional rollback of packages, data, running services or app migrations. A restart failure after scheduling also lacks a health-gated automatic rollback.
- Existing container registry config is left alone; the widget merges its own entry and creates a backup; managed fstab lines are selectively replaced. In contrast, generated service units and project-owned helper/sudoers files are overwritten. There is no universal before-state journal.

**No host-product uninstall command exists at this SHA.** The CLI offers service controls and widget removal, not complete removal of packages, units, sudoers, firewall, linger or storage changes. [Issue #5](https://github.com/TouchWorkStation/omarchy-server/issues/5) and [PR #10](https://github.com/TouchWorkStation/omarchy-server/pull/10) discuss an uninstall command; the PR was open/unmerged when checked. Do not count proposed behavior as shipped. Factory reset is not uninstall: it starts app/VM deletion asynchronously, tolerates deletion errors, then resets accounts.

## Security and Privacy Boundaries

### 1. HTTP remains the default access path

The README and launcher lead with http://. HTTPS is available, but the persisted alwaysHttps policy defaults false, and [wantsUpgrade](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/omarchyd/tls.mjs) targets page navigation rather than refusing every HTTP API call. The [login route](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/server/app.mjs#L575) accepts the password from the browser and forwards it to the backend. Creating the password locally does not mean it never crosses a network: later HTTP login exposes it and session traffic to a network observer.

Use authenticated, verified TLS before logging in remotely. New local certificate authorities carry critical name constraints for home/private names and addresses; that is better than an unrestricted CA, but trusting a downloaded CA still needs an independent fingerprint check. Older authorities are deliberately retained until replacement. CSRF headers, SameSite cookies and Origin checks are worthwhile controls, not encryption.

### 2. “Every app's port is behind sign-in” has important exceptions

For ordinary web apps, Compose rewrites the web port to loopback and a gateway authenticates it. But [openGateways](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/omarchyd/apps.mjs#L498) explicitly opens a host-network app's own port directly when there is no internalPort, and separately creates a protected view gateway. Additional declared openPorts are also opened directly. Passt VM forwarding is not browser-authenticated either. Those services need their **own** authentication and exposure policy. Rootless execution does not turn a directly reachable app into an authenticated one.

Cookies are host-scoped rather than port-scoped. Proxied traffic strips Omarchy cookies, which is good; a directly reached service on the same hostname is a different boundary and should not be assumed to get the same stripping. Treat installed apps as trusted software, not hostile mutually isolated tenants.

### 3. App permission checks are useful, not a complete Compose security model

[appPermissions / whereFor / placeApp](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/omarchyd/apps.mjs) classify mounts, host networking, devices, capabilities and container-socket access, and gate installation on explicit category grants. Updates compare permission **categories**, not exact paths/capabilities. Granting host-files once does not imply a later path change will prompt again.

The mount classifier checks expanded strings without canonical path or symlink resolution, and exempts paths that lexically begin with an allowed app/shared/media directory. Relative traversal or symlink semantics therefore deserve adversarial tests before treating the “never gives an app these folders” statement as enforcement. Permission inspection also precedes execution of exports.sh and final Compose generation, without a comprehensive final normalized-configuration recheck. These are static boundary concerns, not a demonstrated live exploit in this review. Broad container-socket grants intentionally expose the user's container engine; rootless is a reduction in privilege, not a safe boundary around that user's files and services.

### 4. The owner session is equivalent to substantial host access

[Files](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/omarchyd/files.mjs) resolves paths/symlinks inside Home/Trash and hides dotfiles in listings. Hiding is not an authorization boundary: the path resolver does not reject every hidden path, and the [terminal](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/omarchyd/terminal.mjs) intentionally gives the real user shell. A stolen owner session threatens home-directory credentials, application data and desktop access.

The root helper also supports hostname, power and desktop sign-in, not only storage/firewall. Desktop sign-in resets faillock, writes a temporary SDDM autologin drop-in and restarts SDDM when no graphical user session exists, with cleanup in finally. Abrupt process/host failure can bypass normal finally cleanup; startup cleanup helps but is not a transaction. This deliberately substitutes the web owner's authority for an interactive OS login boundary.

### 5. Local-first does not mean no egress or no retained secrets

Accounts, backend device/browser tokens, web sessions, TOTP secrets, app credentials and the TLS CA key are stored locally; sensitive JSON/key files use restrictive modes, not application-level encryption at rest. The master app secret and backups must be protected along with accounts. Updates contact GitHub automatically a minute after start and every six hours. Catalogs, icons/theme previews, container pulls, guest-image downloads and installed apps introduce more egress. No mandatory hosted account or analytics service was identified in the inspected core; this is not a traffic audit.

Linux cloud-init uses password hashes. The [Windows answer-file path](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/omarchyd/machine-media.mjs) instead uses reversible base64 encoding, creates a local administrator and bypasses TPM/Secure Boot/RAM checks. Treat generated answer media as secret-bearing and the guest's licensing/support posture separately; “PlainText=false” is not encryption.

## Storage, Recovery and Backup

[The root helper](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/helper/helper.mjs) checks lsblk and wipefs before formatting and avoids forcing mkfs.btrfs/zpool creation. However, wipefs probe errors are caught as an empty result, so the secondary signature check is not fail-closed. Signatures also cannot prove a disk has no valuable unrecognized data. The blank-drive claim should not replace an external backup and explicit physical-device verification.

Managed fstab edits preserve unrelated lines, but read-modify-write operations have no shared lock or complete rollback ledger. Mount targets below the user-owned Pools directory are not comprehensively realpath/symlink-pinned before root operations. The grow-system helper can change the partition before reaching an unsupported-filesystem error; supported-layer checks should all precede mutation. These deserve offline fault-injection and disposable-machine testing.

Samba preserves a foreign smb.conf by adding an include, but an empty managed share list disables smb.service even if unrelated shares exist. Its generated globals apply when it owns the main file, not necessarily to an existing foreign configuration. The low-ports helper lowers net.ipv4.ip_unprivileged_port_start persistently and only downward: the effect is system-wide, not confined to the requesting container, and app removal does not restore the prior limit.

[VM snapshots and backups](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/omarchyd/machines.mjs#L1150) are real implementations: stopped qcow2 snapshots, live libvirt backup-begin or offline conversion, metadata and restore/clone flows. Snapshots explicitly omit UEFI variables. Backups copy qcow2 disks and settings, exclude seed/answer media, and do not copy NVRAM in the inspected backup loop. Live disk consistency is not proof of guest application/database consistency; no guest quiescing was identified there. The default backup directory is in the same home filesystem, so it is not independent protection against disk loss. Copy it elsewhere and test restore with the actual firmware and guest workloads.

App uninstall runs Compose down --volumes and removes the app directory; it is data deletion, not just hiding an icon. App updates pull and recreate containers without a coordinated data backup/rollback. Factory reset may leave partially removed workloads while clearing login state. There is no demonstrated end-to-end backup/restore of the whole owner console, container data, secrets, host configuration and pools. Pool forget/export preserves on-disk data, but is not a general undo of all host changes.

## Download Provenance

Machine catalogs require HTTPS image URLs plus either a pinned SHA-256 or a publisher SHA-256/SHA-512 checksum listing. Downloads are hashed and mismatches discarded. That detects corruption and mismatch; remote catalogs/checksum lists remain mutable trust inputs, and detached publisher-signature verification was not found in this path. No images were downloaded or booted for this review.

App stores follow Git HEAD, and Compose pulls whatever image reference a listing supplies; the engine does not require immutable digests or verified signatures. The built-in optional Tor helper uses an Alpine version tag and installs tor at runtime. The ISO workflow uses archlinux:latest and version-tagged GitHub Actions, not fully pinned build inputs. Its release-trigger configuration is not evidence that a tested ISO release exists.

## Maturity, Tests and License

Public [repository metadata](https://api.github.com/repos/TouchWorkStation/omarchy-server) on the review date showed creation on 2026-11-12, last push on 2026-11-14, 12 stars and 3 forks. The two open items were one issue and one PR, not two independent bug reports. The releases endpoint returned an empty list. This is a very young public project despite its 0.9.13 version and broad feature surface.

The [Tests workflow](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/.github/workflows/test.yml) runs npm ci, frontend typecheck, build and node --test on Ubuntu/Node 22; [run 43634891271](https://github.com/TouchWorkStation/omarchy-server/actions/runs/43634891271) reported success for the exact reviewed SHA. Test files cover accounts/throttling, file bounds, app permissions, VM media/lifecycle, storage with fake command/filesystem adapters, updater rollback, sessions and TLS/security. The catalog workflow checks links, not guest boot correctness. CI uses tag-pinned Actions and the ISO job is privileged. No independent local test pass, vulnerability audit, performance measurement or real-storage validation is claimed here.

The root [MIT license](https://github.com/TouchWorkStation/omarchy-server/blob/41385a44fceb03e982e93d4ca8048816c489ef12/LICENSE) permits reuse with its notice. The external app catalog, Dashboard Icons, npm packages/fonts, hypervisor/filesystem tools and guest OS licenses remain separate. No source components were extracted into this review library.

## Comparison

| Alternative | Prefer it when | Tradeoff against this project |
|---|---|---|
| [Cockpit](https://cockpit-project.org/) with appropriate modules | You want conventional Linux host administration and explicit OS/service boundaries | Less of a single Omarchy-themed app-store desktop; broader established admin ecosystem |
| [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) | The machine is primarily a dedicated virtualization host | Not an overlay for the daily Omarchy desktop; substantially different deployment and recovery model |
| [OpenMediaVault](https://www.openmediavault.org/) | Storage and NAS administration are the primary purpose | Dedicated NAS-oriented base rather than desktop-sharing convenience |
| [CasaOS](https://github.com/IceWhaleTech/CasaOS) / [Umbrel](https://github.com/getumbrel/umbrel) | Browser app-appliance experience is the main goal | Compare current platform, license and container privilege requirements; do not assume catalog interchange means equal isolation |

These are fit comparisons, not fresh security audits of the alternatives. Related public reviews: [Wayshare](wayshare.md) for a narrower remote-desktop scope and [Arcane](arcane.md) for a container-focused control plane.

## Practical Adoption Gate

Before considering a non-disposable deployment: require encrypted verified access, inventory every directly exposed app/VM/SMB port, keep trusted stores only, preserve host configuration and secrets offline, and test both restoration and removal on a spare machine. Prioritize final-Compose permission validation, canonical mount confinement, fail-closed disk checks, honest rollback reporting and complete uninstall before adding more catalog breadth. Do not expose the owner shell/desktop console directly to the public internet on the strength of the README's security bullets.

**Bottom line:** unusually integrated and worth studying or piloting, but the recovery and authority boundaries are not yet strong enough to make it the sole home for irreplaceable data.

---
**Attribution:** TouchWorkStation/omarchy-server; Chris Jordan and contributors; MIT. Omarchy is a separate project. All findings are tied to the revision above; later fixes and the pending uninstall PR may change this assessment.
