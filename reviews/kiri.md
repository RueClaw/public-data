# Kiri (libracoder/kiri)

**Repo:** https://github.com/libracoder/kiri
**License:** Apache-2.0 core; bundled component notices and GPL-2.0-only guest kernel; name/logo excluded from the source license.
**Reviewed:** 2026-11-14 (UTC)
**Revision:** 8318b8d7683202bd3d438b1baf788fa8526fa52b; repository-wide static sampling of host daemon/API, guest runtime, registry/storage, networking, sharing, diagnostics, updates, packaging, tests and CI.
**Verification:** Static review only. No source execution, builds, installs, container/VM launches, device access, account login, tunnel creation or benchmark reproduction.
**Stack:** Rust 2024, Linux namespaces/cgroups/overlayfs/seccomp, Apple Virtualization.framework, WSL2, rustls/ureq, platform UI with embedded web content.
**What it is:** A Docker Engine API-compatible local container runtime and desktop application, with its own Rust guest runtime rather than dockerd/containerd/runc, plus optional hosted public tunnels.

---

## Verdict

⚠️ **Interesting — pilot for trusted development, not yet a default hostile-workload boundary.** Kiri has a substantive implementation, unusually attentive local access controls and an ambitious low-overhead architecture. Its custom isolation policy, very young public history, durability caveats and weaker Windows update authenticity require qualification before replacing a mature engine or entrusting important state.

## What It Is

Kiri targets developers who want Docker CLI, Compose and buildx workflows without the resource footprint of a full desktop engine stack. macOS runs one small Linux VM; Windows bridges a local named pipe into WSL2; Linux runs directly against the host kernel. These are materially different security boundaries, not three interchangeable packaging variants.

The source also implements Kubernetes through k3s, Linux development machines, image/volume/container import, local HTTPS names, USB integration and Kiri Share. Share is an optional authenticated client of a hosted edge, not evidence that the runtime needs a cloud account for normal local containers. Its presence also means “local runtime” must not be read as “no possible network disclosure.”

## Stack

| Layer | Implementation |
|---|---|
| Control plane | Rust CLI, daemon, Docker HTTP API and desktop UI |
| macOS virtualization | objc2 bindings to Virtualization.framework, virtiofs and vsock |
| Windows | Native named-pipe frontend and WSL2 Linux engine |
| Container execution | Custom PID 1 agent, clone3, namespaces, cgroups, overlayfs, pivot_root, capabilities, seccomp |
| Images | Registry HTTP client, content-addressed blobs, Docker archive save/load |
| Networking | rtnetlink/nf_tables, port relay, DNS, local TLS router |
| Optional external service | Kiri Share TLS connection to edge.runkiri.com; public runkiri.cloud URLs |

## Key Features and Architecture

The daemon owns container metadata and the VM connection; the guest agent owns execution and multiplexes process lifecycle, output and networking. Removing intermediate daemons/shims can plausibly reduce short-process overhead, but shifts compatibility and security maintenance onto Kiri's own implementation. Read [docs/development.md](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/docs/development.md), [crates/kiri/src/daemon/engine.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/daemon/engine.rs) and [crates/kiri-init/src/linux/container.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri-init/src/linux/container.rs).

Docker interoperability is real implementation work, not just shell aliases: there are image archive handlers, container execution/inspection/logs, network and volume APIs, plus Testcontainers-oriented checks. However, compatibility is an evolving surface. At this revision buildx uses a BuildKit container; the documented docker-container-driver restriction on build-time host-gateway remains. [docs/features.md](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/docs/features.md) and [tests/testcontainers-api.py](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/tests/testcontainers-api.py) are more useful acceptance inputs than the broad “your tools just work” headline.

### Performance claims: narrow, author-reported evidence

README reports 2.55 ms for an Alpine true create/run/remove lifecycle through the API and about 80× versus Docker Desktop. [bench/results.json](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/bench/results.json) specifies a median of 30 runs after five warm-ups, an Apple Silicon Mac/macOS 27.0.1, and distinguishes measured figures from design targets. Its update date is October 24, preceding the reviewed November revision. This is not a general application-throughput, build-time or production-density result, nor an independently reproduced comparison. The development guide says raw benchmark output lives outside this repository. The PR speed workflow compares base/head on the same runner and takes thresholds from the base script, a useful anti-regression design, but not validation of the desktop competitor headline.

## Security and Authority Boundaries

### Local access is deliberately restricted, but grants engine authority

The Unix API socket begins at mode 0600; Linux group operation changes it to 0660. The Linux access gate uses SO_PEERCRED and current group membership, with roughly two-second rechecks that close existing streams when membership is revoked. POSIX ACLs permit newly added members without re-login; the connection gate prevents stale ACLs from becoming permanent access. This is a notably thoughtful control ([crates/kiri/src/daemon/mod.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/daemon/mod.rs), [crates/kiri/src/daemon/access.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/daemon/access.rs)).

Windows rejects remote named-pipe clients, grants the current user/SYSTEM/administrators, refuses to serve if descriptor creation fails, and requests identification rather than impersonation on client connections ([crates/kiri-win/src/pipe.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri-win/src/pipe.rs)). These controls are not per-container RBAC. On Linux the service is root-run and the kiri group is explicitly root-equivalent because members can mount arbitrary host paths ([contrib/linux/kiri.service](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/contrib/linux/kiri.service)). There is no human approval step for each Docker API mutation; granting socket access is the major authorization decision.

### A custom sandbox policy, not Docker's identical policy

The guest sets namespaces, mount isolation, capabilities and a seccomp filter. The default filter is a **denylist**, unlike Docker's allowlist: unlisted new syscalls are generally allowed. Capability choices relax it, and no-new-privileges is enabled only when requested. Even privileged/seccomp-unconfined execution retains a smaller boundary filter that rejects vsock and io_uring, an intentional protection for the host transport. The filter also uses SECCOMP_FILTER_FLAG_SPEC_ALLOW for performance; that is an explicit mitigation tradeoff, not proof of an escape. See [crates/kiri-init/src/linux/seccomp.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri-init/src/linux/seccomp.rs) and container.rs.

Do not equate a VM with protection from all authorized host access: writable shared directories, explicit bind mounts, SSH-agent forwarding and USB passthrough cross it by design. On native Linux there is no extra VM kernel boundary. This review did not audit all unsafe/FFI paths or demonstrate an escape; the practical conclusion is to use trusted development workloads and separately validate hostile-code isolation.

### Network exposure and local CA

Publishing a port without a host address maps to all IPv4 and available IPv6 interfaces, not loopback-only ([crates/kiri/src/daemon/ports.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/daemon/ports.rs)). Explicitly bind development services to loopback unless LAN exposure is intended. This is separate from the restricted engine socket.

The local CA includes permitted DNS subtrees for kiri.local/kiri.localhost and exclusions for all IP SANs. Its key lives in a private directory; macOS trust installation asks for administrator approval. CA format migration replaces older keys missing the IP restriction. These are good defenses, but client trust-store/name-constraint behavior was not tested here ([crates/kiri/src/daemon/tls.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/daemon/tls.rs)). Installing a CA or persistent socket helper is a meaningful host change, not a prerequisite this review performed.

## Credentials, Data Flows and Costs

Registry credentials arrive from Docker clients; token caches are scoped by registry/repository/actions and a credential fingerprint, avoiding anonymous/authenticated cache reuse ([crates/kiri-image/src/registry.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri-image/src/registry.rs)). Registry traffic, image pulls/pushes, builds and container applications still contact their configured services. Registry quotas, bandwidth, disk and CPU/RAM are real costs; no LLM provider or model download is inherent in Kiri.

Kiri Share uses GitHub device login through the edge, stores a bearer token in a local JSON config (Unix temporary file mode 0600 plus sync/rename), and sends traffic through the hosted edge. The protocol exposes device/account information and local computer identification; public URLs expose the target service. The binary's embedded build-key attestation distinguishes official builds but is not a substitute for user authorization or a hardware-kept secret. The edge implementation, server retention/deletion guarantees and current pricing were not established from this checkout. Source APIs expose plan limits for tunnels and reserved names: do not infer unlimited free service from marketing. See [crates/kiri/src/share.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/share.rs) and [crates/kiri-share-proto/src/attest.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri-share-proto/src/attest.rs).

Share logout clears local token/login fields; the inspected function does not request remote token revocation or delete the retained device identifier. Stopping a share closes the client tunnel, not necessarily every server-side record. Do not expose an unauthenticated admin service merely because the tunnel itself uses TLS.

Diagnostics use local rotated logs and pattern redaction. Crash uploads require crashReports=true; report construction reduces sensitive fields. Pattern redaction is not a guarantee that arbitrary application/error text contains no secrets. Container output logs are a distinct data surface, not automatically sanitized application output ([crates/kiri/src/diag/mod.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/diag/mod.rs), [crates/kiri/src/diag/report.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/diag/report.rs)).

## Persistence, Retention and Recovery

Images/blobs, writable container data, named volumes and host bind mounts have different lifecycles. Container metadata records include the saved specification; treat environment-based secrets and filesystem copies as sensitive. Container logs default to 10 MiB × three files per container, removed with the container; attached auto-remove workloads use a small memory ring. Buffered log writes are not fsynced, so power-loss durability is not assured ([crates/kiri/src/daemon/logfile.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/daemon/logfile.rs)).

Metadata saving writes a temporary JSON file then renames it, but the inspected save path does not fsync file/directory and logs write failures rather than returning them to the caller. Startup treats malformed records as an empty set and logs the problem. Restart policies restore eligible containers, but this is not live restore or a transactional backup ([crates/kiri/src/daemon/engine.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/daemon/engine.rs), load/save).

Docker image save/load, container export and the import facility provide useful migration pieces; **an image archive is not a volume/database backup**. No complete integrated backup-and-restore guarantee was established. Quiesce databases, export their data, preserve volumes and metadata together, protect any host bind data separately, and test restoration before moving irreplaceable workloads. Prune/remove operations are destructive; stopping a container alone does not erase persisted data. Diagnostic exports, filesystem backups and hosted Share records have independent retention.

## Install, Updates, Licensing and Maturity

A Cargo.lock and explicit CLI SHA-256 pins are positives. The build system also assembles a custom kernel, initramfs, disk image, Docker tooling and platform installers; building is not a harmless dependency-only operation. CI speed builds use the mutable rust:1-alpine image and package downloads, so locked Rust dependencies do not make the whole build hermetic ([crates/kiri/src/cli_pins.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/cli_pins.rs), [xtask/src/main.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/xtask/src/main.rs), [.github/workflows/perf.yml](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/.github/workflows/perf.yml)).

**Update authenticity is platform-dependent.** macOS verifies the archive hash, app signing identity, notarization and expected version, stages on the same volume and retains the old app through replacement. Windows verifies HTTPS-feed SHA-256 plus MSI product/platform/version metadata, but explicitly says the MSI is unsigned and cannot pin a signing identity. A hash from the same compromised feed is not an independent signature. Linux reads version information and relies on package replacement rather than this Mac updater. The README's broad signature language needs this qualification ([crates/kiri/src/update.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri/src/update.rs), [crates/kiri-win/src/update.rs](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/crates/kiri-win/src/update.rs)).

Public GitHub metadata retrieved November 14: repository created November 2, last push November 14, 3,656 stars, 182 forks and 64 open issue/PR items. Latest published GitHub release was v0.2.0 on November 10; the reviewed main SHA is newer and is not asserted to be that release. Popularity and a release do not establish container-runtime hardening.

The tree includes substantial e2e, Linux, WSL, IPv6, USB, kernel, lifecycle and Testcontainers checks, plus inline Rust tests. Checked-in workflows cover SHA-pinned CodeQL, UI/translation tests and PR performance comparisons. Their existence is evidence of engineering effort, **not a claim that this SHA passed all platform tests**. No tests or CI run outcomes were independently executed/verified. Security policy supports the latest release and private vulnerability reports ([SECURITY.md](https://github.com/libracoder/kiri/blob/8318b8d7683202bd3d438b1baf788fa8526fa52b/SECURITY.md)).

Apache-2.0 permits core reuse subject to its conditions and notices. NOTICE documents mixed dependencies and the separate GPL-2.0-only guest kernel/source offer; distribution obligations survive bundling. The project excludes its name/logo from the source-license grant. No code extraction was needed for this review.

## Comparison

| Choice | Better fit | Tradeoff against Kiri |
|---|---|---|
| Docker Engine / Docker Desktop | Established API behavior and broad ecosystem | Larger conventional stack; Desktop licensing and platform terms need checking |
| Podman | Rootless-first workflows and explicit user isolation | Docker API/Compose behavior is not identical; still qualify platform integration |
| Colima / Lima | Open VM-based development with conventional engines on macOS | More layering/configuration, less integrated native product |
| OrbStack | Polished Mac container/VM integration | Proprietary product and its terms; author benchmarks are not independent comparisons |

## Practical Adoption Gate

Use a pinned release in a disposable development environment first. Check the exact Compose/buildx/Testcontainers features you need, host port bindings, filesystem/SSH-agent sharing, privileged-container policy and Windows update provenance. Keep public tunnels and crash upload off unless intentionally needed. Back up and restore real volume data, exercise engine restart/power-loss scenarios, and compare representative builds and services rather than only Alpine true. For untrusted multi-tenant execution or important production data, retain a mature, separately hardened runtime until Kiri's boundary and recovery behavior have been independently qualified.

**Verification limits:** Public source and public GitHub metadata only; shallow checkout, targeted static analysis, no full dependency advisory audit, binary attestation, kernel audit, live service probe or runtime test. HTML/artifact validation is separate from testing Kiri itself.

---

**Attribution:** libracoder/kiri and contributors; Apache-2.0 core, NOTICE and separate kernel/component terms. [Repository metadata](https://api.github.com/repos/libracoder/kiri) · [Latest release](https://github.com/libracoder/kiri/releases/tag/v0.2.0).
