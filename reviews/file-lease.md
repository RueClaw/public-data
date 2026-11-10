# file-lease (cachix/file-lease)

**Repo:** https://github.com/cachix/file-lease
**License:** Apache-2.0; preserve license/notices and mark redistributed modifications; dependency terms remain separate.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** dd1527b4baebf37a688691a0f879e5c3b8321476 (main; manifest 0.1.0; commit dated 2026-11-09). Scope: library, helper, Linux/macOS backends, protocol, recovery/pooling, tests, manifests, CI and documentation.
**Verification:** Static source review; no build, tests, benchmarks, installs, RAM-disk mounts or runtime fault injection performed. Public GitHub API reports successful CI for this exact SHA; that is upstream evidence, not an independently reproduced result.
**Stack:** Rust 2024 / Rust 1.92+, Unix sockets, Linux memfd/pidfd/mlock, macOS HFS RAM disks/kqueue/IOKit.
**What it is:** Cachix's process-lifetime, memory-backed file delivery library for programs that accept secrets or configuration by pathname. It is **not a file-lock library or a distributed lease service**.

## Verdict

⚠️ **Interesting — a carefully engineered secret-file adapter worth a constrained pilot, not a general security boundary.** Linux seals and locks payload pages before publication; macOS invests heavily in mount identity and orphan recovery. The very young 0.1.0 project has meaningful native CI, but consumers, helper packaging, cleanup latency and same-user exposure must be validated before sensitive deployment.

## What It Is

A Rust launcher sends bytes over an inherited private Unix socket to a separate helper. That helper hosts an ordinary-openable path and watches a selected process. Consumers need neither Rust integration nor inherited descriptors. This is useful for certificate, credential and generated-config arguments where stdin or an API is unavailable.

The word “lease” describes **storage lifetime**, not exclusive ownership of a shared resource. Independent leases allocate independent files; multiple readers are expected. There is no lock acquisition queue, TTL, heartbeat, renewal, fencing token, distributed consensus or network-partition protocol. Internal mutexes and macOS setup-file locks serialize implementation work; they do not provide application-level access control or distributed mutual exclusion.

## Stack

| Layer | Implementation |
|---|---|
| Public API | FileLease, LeasedFile, FileOptions, typed Error/ErrorKind, ProcessInfo |
| Common Unix runtime | libc, rustix, zeroize; inherited UnixStream pairs and helper processes |
| Linux | memmap2, sealed memfd, pidfd, mlock and MADV_DONTDUMP |
| macOS | HFS RAM disks via absolute-path system tools; kqueue, IOKit/Core Foundation, UUID identity, serde JSON metadata, tempfile, wait-timeout |
| Packaging | Matching library plus helper binary, or embedded helper entry point; Cargo.lock and pinned 1.92.0 toolchain |

Evidence: [manifest](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/Cargo.toml), [API](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/lib.rs), [architecture](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/docs/architecture.md).

## Key Features and API Ergonomics

- **Lazy and cloneable:** FileLease::new(pid) stores a PID; first materialization starts the helper. Arc/Mutex serializes clone operations, transport and handoff state. A LeasedFile is only a name: retaining it does not keep storage alive.
- **Explicit lifetime transitions:** release(&file) revokes one known path; final lease drop requests cleanup and waits. handoff() retains existing files for the original owner, while handoff_to(pid) changes the watcher. Handoff prohibits further allocations across all clones, but release remains available. Handoff on a genuinely unused lease is a no-op.
- **Deploy the helper deliberately:** default discovery uses a sibling of the current executable, not PATH. An explicit helper path or early maybe_run_helper() dispatch supports embedding. The binary alone is an internal helper, not a general user-facing CLI.
- **Bounded inputs:** payloads are capped at 64 MiB; suffixes at 80 ASCII alphanumeric/dot/underscore/hyphen bytes. Linux ignores suffix hints. Validation occurs before allocation-frame transmission; incoming frames are checked too.

The version handshake checks the crate version, protocol tag and shared-volumes build distinction before payload delivery. It is compatibility checking, **not executable authentication or a source hash**, and does not distinguish every possible build difference (for example unstable-profiling). Protect the executable and its directory; an attacker-controlled matching helper receives the bytes. See [helper](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/helper.rs), [Unix lifecycle](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/unix.rs), [protocol](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/protocol.rs), [CLI entry](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/bin/file-lease.rs).

## Architecture and Precise Guarantees

### Linux: immutable file pages, temporary names

The helper creates an anonymous memfd, sets mode 0400, sizes it, maps it read-only, applies MADV_DONTDUMP and locks the zero-filled pages **before** writing secret bytes. It then seals WRITE/GROW/SHRINK/SEAL and returns /proc/&lt;helper-pid&gt;/fd/&lt;fd&gt;. A failed mlock fails allocation rather than falling back to pageable storage or a disk file. Empty payloads require no mapping.

Release closes the hosted descriptor and unmaps/unlocks its pages. The allocator advances descriptor numbers and temporarily reserves retired numbers during subsequent creation, specifically preventing an old revoked path from capturing an intermediate allocation descriptor. This is a thoughtful regression-driven fix. It also means **cumulative allocations**, not only concurrent live files, consume the descriptor-number namespace; start new leases for refresh batches.

The non-reuse guarantee is scoped to a live helper. A textual proc path is not a permanent globally unique capability: after helper exit, eventual PID/descriptor reuse elsewhere can give the same string a different meaning. Never persist/reopen stale paths as identity tokens. Source: [Linux implementation and tests](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/linux.rs).

### Ownership, PID reuse and races

Linux opens a pidfd before helper launch, pinning process identity for monitoring once captured. macOS records process birth time and verifies it before and after initial kqueue registration. A PID supplied at construction may already refer to an unrelated reused process by first allocation; the README explicitly acknowledges this. ProcessInfo is discovery metadata, not an atomic identity capability.

handoff_to takes a **numeric PID**, not a birth-time or pidfd capability supplied by the caller. In particular its macOS path calls watch_owner directly, without the startup birth-time comparison. It watches whichever process registration resolves to, so do not generalize startup protection into a guarantee against stale caller-supplied handoff PIDs. Both old and new owners should remain alive through successful handoff. The next watcher starts before cancellation/join of the old one; an old owner's concurrent exit can still win cleanup. A successful call is not a promise that the new owner remains alive afterward.

There is no clock-based expiry or stale-time heuristic. Process-exit notifications drive cleanup; a hung or stopped-but-live owner can retain files indefinitely. Instant-based timeouts bound selected startup/tool/recovery waits, not lease duration. Evidence: [Keeper::spawn, HANDOFF and OwnerWatch](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/unix.rs), [macOS watcher](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/macos.rs).

### Crash, cancellation and restart behavior

Without handoff, controller EOF leads to cleanup; with handoff, EOF leaves the helper waiting for the selected owner. Normal final drop waits for helper termination. Owner exit triggers storage cleanup and helper exit; SIGKILL of the Linux helper lets the kernel close its descriptors. Rust panic unwinding can drop the final lease, but aborts rely on process/channel behavior. There is no async cancellation API or public cleanup-result-returning close method.

**Do not read the ten-second startup deadline as a universal deadline.** After readiness, the socket timeout is restored; allocation/release/handoff use blocking IO, and non-handed-off Drop calls child.wait() without an overall timeout. A stopped or wedged helper can therefore stall a caller or destructor. macOS setup additionally has a 120-second readiness loop, while individual volume tools have ten-second deadlines. No runtime hang reproduction was attempted.

There is no persisted payload or resumable lease object after application restart. New leases create fresh resources; macOS journals help remove leftovers, not recover secret bytes into a new API session. The current Keeper is not automatically respawned following transport failure; a new lease is the practical recovery unit. [Lifecycle](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/unix.rs), [startup](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/helper.rs), [setup](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/macos/setup.rs).

### macOS: guarded ordinary paths, different security properties

The backend attaches a 64 MiB RAM disk, formats HFS and mounts with owners,noexec,nosuid,nodev,nobrowse. A 0700 root contains payloads created with openat CREATE|EXCL|NOFOLLOW relative to a pinned validated directory, initially 0600 and then 0400. Before allocation/release it validates mounted filesystem/device identity, owner, private root permissions and flags, preventing an absent/replaced mount from silently redirecting payload writes into its disk-backed mountpoint.

Suffix validation excludes separators; monotonically increasing file counters avoid name reuse within a volume. This is not Linux-style immutable sealing: the same filesystem owner can chmod, modify, delete or replace files. Normal consumers only receive the path after writing/permission changes complete, but creation is not an atomic rename publication against a hostile same-user directory observer. The private-user boundary, not secrecy of a predictable filename, is the assumption.

Default pooling shares volumes among overlapping leases in one process with the matching helper path. Per-scope path sets reject cross-scope release requests. Only ENOSPC causes spillover, with at most one new volume per request; filesystem overhead means a full 64 MiB payload may not fit. Released space is reused and surplus empty volumes are detached, retaining at most one empty volume. Total pool growth has no fixed cap. A scope helper crash normally affects that scope; a manager crash, or unrevocable scope cleanup that deliberately exits the manager, affects the entire pool. Disable shared-volumes consistently in library/helper for separate-volume failure domains; Cargo feature unification can re-enable it.

Sources: [payload operations](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/macos/storage.rs), [root validation/setup](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/macos/setup.rs), [pool manager and scope checks](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/volume_pool.rs).

### Recovery, atomicity and durability

Each macOS setup worker remains an independent guardian. It monitors the manager/keeper, retries cleanup up to three times, and leaves metadata for later startup recovery if cleanup or both processes fail. This is not guaranteed immediate cleanup after every multi-process failure, and there is no installed recovery daemon. Startup recovery shares a five-second budget; individual OS calls may exceed it.

Recovery uses UUID drive-key registration, device-node identity and mount checks to avoid detaching a recycled disk number. Unknown/in-flight attachments are conservatively retained. A setup.lock file coordinates cooperating setup/recovery actors, including tools inheriting the open lock through stdout; it is **advisory internal coordination**, not protection from a malicious process under the same user. No TTL-based lock stealing occurs.

lease.json is written to a temporary file, synced, persisted over the target and followed by directory sync: a real attempt at crash-consistent metadata, not a transactional guarantee covering all OS attachment operations. Payloads intentionally have no durable-on-disk persistence guarantee. Metadata and cleanup diagnostics do touch the normal filesystem, so “memory-backed payloads” is not “no filesystem writes whatsoever.” See [recovery](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/macos/recovery.rs), [registry identity](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/macos_registry.rs), [bounded tools](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/command.rs).

## Security and Operational Boundaries

1. **Owner means cleanup trigger, not exclusive reader.** OS UID/proc visibility restrictions protect access; the selected PID is not an ACL. Authorized same-user processes and privileged administrators are outside the isolation guarantee. The private socket controls helper operations, not all reads of the resulting path.
2. **Revocation is not erasure.** Open descriptors, mappings and copied consumer bytes can outlive pathname revocation. Source/transport/consumer buffers are not locked; helper receive vectors use Zeroizing, but this does not erase every copy. Linux locking lasts only while its helper mapping survives; macOS adds no memory-lock guarantee. Hibernation and diagnostic capture remain concerns.
3. **Trusted executable and filesystem namespace required.** Sibling-helper discovery prevents PATH substitution, not tampering with that sibling or its parents. macOS NOFOLLOW and pinned-root checks are strong local safeguards, not a complete defense against hostile same-UID namespace mutation. The metadata root comes from HOME, checks its final directory, then canonicalizes it; it is not an arbitrary untrusted-path sandbox.
4. **Local only.** Linux requires usable memfd/seals/pidfd/mlock and accessible proc-fd paths; pidfd_open implies a sufficiently recent kernel (introduced in Linux 5.3). Container PID/mount namespaces, proc access policy and memory-lock limits can break usability. macOS depends on native tools, HFS support and IOKit tagging. Windows and other OS allocations are Unsupported.
5. **Not an NFS/SMB lease.** Payload backends are local kernel storage. A network-mounted HOME may put macOS metadata/locks on a network filesystem, but no cross-host recovery/lock correctness is established; prefer local private metadata. Exporting the path does not create distributed safety.
6. **Qualify the actual reader.** Applications that canonicalize proc-fd paths to the deleted memfd backing name can fail; upstream specifically calls out PHP opens. Test reopen behavior, namespace visibility and suffix expectations before adopting.

## Tests, CI, Maturity and Performance Evidence

The reviewed tree includes regression coverage for concurrent clones, per-file release, failed/successful handoff, SIGKILL, closed stdio, old-helper rejection, PATH avoidance, protocol truncation/oversize, Linux memlock exhaustion and descriptor reuse. macOS tests exercise missing/replaced mounts, weakened permissions, interrupted setup, guardians, recovery budgets, reused device numbers, pool isolation and capacity. These are substantive tests, not just API smoke checks: [core tests](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/lib.rs), [integration tests](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/tests/helper.rs), [macOS regressions](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/src/macos/tests.rs).

[CI configuration](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/.github/workflows/ci.yml) runs Ubuntu, macOS 15 and macOS 26, default/no-default/all-feature tests, clippy and formatting; Linux additionally checks docs/package creation. Actions are SHA-pinned and checkout disables persisted credentials. [Exact-SHA run 42662217961](https://github.com/cachix/file-lease/actions/runs/42662217961) was completed/success in the public API on the review date. Logs and artifacts were not independently audited or rerun, and no dependency vulnerability scan was performed.

Public repository metadata on 2026-11-10: created November 6, last push November 9, 28 stars, 0 forks, 0 open issues/PRs reported by the aggregate counter. The manifest/changelog say 0.1.0, dated November 9; the GitHub releases endpoint returned no releases. That does not establish whether crates.io publication occurred. These signals indicate a very young public project, not proven deployment maturity. Attribution is Cachix; the reviewed release-preparation commit is by Domen Kožar.

[Performance documentation](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/docs/performance.md) links native diagnostic runs and honestly reports tradeoffs: historical cold macOS setup around 209–290 ms; a pooled-overlap experiment reduced macOS 26 sequential joins from 263.68 to 6.64 ms, without making cold setup free. Later preflight/reclamation results trade faster allocation/teardown for some longer drops. These are author-reported synthetic measurements on earlier revisions, not independently reproduced performance for this SHA or universal throughput/memory claims.

## Comparison

| Alternative | Prefer it when | Tradeoff versus file-lease |
|---|---|---|
| stdin / anonymous pipe | Consumer already supports streaming input | Simpler, no reopenable pathname; caller still manages process lifetime and copies |
| tempfile on a deliberately selected filesystem | Ordinary temporary-file semantics suffice | Less helper/OS complexity; disk avoidance, crash cleanup and RAM policy are your responsibility |
| memfd / memfile / memfd_path | Linux-only and you can manage descriptors/lifetimes | Smaller primitive; file-lease adds independent path hosting, owner monitoring and handoff |
| systemd service credentials | Linux service-manager lifecycle already owns the workload | Integrates with service supervision; not the same portable Rust embedding API |
| flock / application locking or a distributed coordinator | You need exclusion, leader ownership or fencing | Different problem entirely; file-lease supplies none of these protocols |

See upstream's [alternatives](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/docs/architecture.md#alternatives), [tempfile](https://crates.io/crates/tempfile), [memfd](https://crates.io/crates/memfd), and [systemd credentials](https://systemd.io/CREDENTIALS/). Alternatives were compared by purpose, not benchmarked or audited here.

## Adoption Notes

This is a library/helper deployment, not a hosted service. Pilot with synthetic payloads and the exact target reader first. Ship a trusted matching helper (or embed it), budget Linux locked pages and cumulative descriptor use, select a live owner deliberately, and complete handoff before launcher exit/exec. Keep metadata local/private on macOS and choose pooling versus separate volumes by failure-domain needs. Put synchronous allocation/cleanup off latency-sensitive async/UI threads and plan for hung-helper supervision. Do not treat this as credential rotation, reader authentication, secure erasure, a secret vault or distributed locking.

**Bottom line:** the interesting reusable engineering is identity-checked resource recovery and process-bound file presentation. Adopt only after consumer and crash-path qualification; for exclusive leases or strong same-user isolation, choose another design.

---

**Attribution:** [cachix/file-lease](https://github.com/cachix/file-lease), Apache-2.0. Original analysis; no source code extracted. [License](https://github.com/cachix/file-lease/blob/dd1527b4baebf37a688691a0f879e5c3b8321476/LICENSE). Public metadata: [repository API](https://api.github.com/repos/cachix/file-lease), [releases API](https://api.github.com/repos/cachix/file-lease/releases).
