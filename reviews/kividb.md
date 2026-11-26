# KiviDB (kividbio/kividb)

**Repo:** https://github.com/kividbio/kividb
**License:** AGPL-3.0-only; copyleft and modified-network-service source obligations apply. Commercial licensing is offered separately.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** `0c4139a904c2f4500ba99b25569179379142c0b6`, master; repository-wide static survey, with targeted inspection of server dispatch, sharded storage, transactions, AOF, backup, ACL, parser and update-check code.
**Verification:** Static review only. No installation, source execution, tests, benchmark reproduction, deployment or live database probing. Anonymous GitHub API access and public HTTPS clone succeeded.
**Stack:** Rust 2024 / Rust 1.89 minimum, Tokio, Linux io_uring, parking_lot, rustls; optional vendored Lua 5.4; native Zstandard.
**What it is:** A multithreaded, Redis-protocol in-memory database combining familiar data structures with full-text/vector search, JSON and time series.

---

## Verdict

⚠️ **Interesting — a credible evaluation candidate, not an automatic production replacement.** KiviDB has unusually substantial compatibility documentation, regression harnesses and explicit recovery machinery for a young project. Its strongest pitch is multicore throughput plus built-in search; its decisive caveats are exact-command compatibility, bespoke persistence and migration paths, and a default AOF acknowledgment escape hatch under prolonged disk delay. Start with reconstructible caches and a workload-specific qualification, not irreplaceable records or correctness-critical queues on faith.

## What It Is

KiviDB speaks RESP2 and RESP3 and aims at Redis 8.10 behavior. It serves keys from an in-memory sharded store rather than embedding Redis or an on-disk database. The same server supplies FT.* search, FLAT/HNSW vectors, JSON, streams, probabilistic types and time series. There is no need to load a separate search module, but MODULE LOAD itself is unsupported. Lua and TLS require the appropriate build variants. [E1], [E2]

The reviewed master is **not the latest stable binary**. The public release API listed v1.2.2 (2026-11-12), v1.2.1 and v1.2.0; Cargo.toml still says 1.2.1, while documentation describes forthcoming 1.3 behavior. Therefore every code finding below is about the pinned SHA, not a promise about a v1.2.2 container. The pinned commit was committed 2026-11-26T20:19:16Z. At retrieval, GitHub reported 1,559 stars, 144 forks and creation on 2026-10-16; this is activity context, not reliability evidence. [E1], [E13]

## Stack

| Layer | Technology and boundary |
|---|---|
| Serving | Rust executable; Tokio and Linux io_uring server paths |
| Storage | Shared, lock-sharded in-memory store; custom entry/table and packed collection representations |
| Concurrency | parking_lot shard locks; command gate, write gate and write ordering; tag-scoped script locks |
| Persistence | Native KDB snapshots, optional AOF, online base/incremental/manifest backup |
| Search | Built-in text/tag/numeric and FLAT/HNSW vector indexing |
| Auth / encryption | ACL and requirepass; rustls TLS optional at build time |
| Native/dependency surface | Cargo.lock; Zstandard C library; optional mlua/vendored Lua and patched C formatting; optional mimalloc |

## Key Features

### 1. Multicore serving with an explicit atomicity design

src/main.rs wires the server, persistence, replication and background services; src/server.rs and src/server_uring.rs are separate transport loops. The store hashes byte keys into a power-of-two shard set, normally eight shards per available core; in cluster mode it derives the shard from the cluster slot. One hot key or hash tag therefore does not scale like uniformly distributed independent keys. This is shared sharded state, not a claim that all operations are lock-free. [E3]

Every normal command enters a shared command gate. EXEC and general scripts take it exclusively, so another client cannot observe intermediate commands. Fast, eligible same-tag Lua scripts may instead hold the shared gate and a tag lock; first runs and untagged/multi-tag scripts take the conservative path. WATCH checks happen within the protected execution region, and the code also serializes watched EXECs. Transaction propagation groups frame multi-write results with MULTI/EXEC for replicas and AOF. [E4]

This is Redis-style atomic execution, **not SQL-style rollback**: the generic EXEC path iterates queued commands and appends each response rather than constructing an undo log. Queue-time rejection is distinct from a runtime command error. A slow global transaction or script stalls other clients; throughput results for independent GETs do not characterize that workload. The repository documents earlier atomicity defects and names concurrent balance-transfer, WATCH and replica tests; those historical bugs should not be presented as confirmed current vulnerabilities. The complex gates, duplicate transport loops and unsafe storage operations still merit race, sanitizer and fault-injection validation. [E3], [E4]

### 2. Persistence with important, explicit qualifications

A checkpoint captures a snapshot cut under the write gate and starts a new AOF delta. Recovery uses snapshot generation/fingerprint metadata, retains an old AOF during turnover, validates the old-log endpoint before applying a new log, and drops an incomplete trailing transaction as a whole. The code and documentation contain substantial crash-recovery logic rather than only a SAVE command. Corruption before the tail is documented to fail startup; obsolete or mismatched logs can be kept aside for diagnosis. [E5]

The most important distinction is acknowledgment policy:

- AOF is optional; Redis-style save scheduling is accepted with a warning but has no effect. Configure persistence deliberately.
- With everysec, acknowledgments normally wait for the record to reach the operating-system page cache, **not stable media**. Power loss can lose the unsynced window; “one second” is a normal-policy target, not a hard storage-stall bound.
- src/aof.rs::written uses a **five-second timeout**, then sends the reply and increments aof_acks_before_write if the disk has not caught up. A subsequent process crash can therefore lose acknowledged writes. Alert on this counter, not just AOF-enabled status.
- With appendfsync always, that timeout does **not** release the reply: the loop continues waiting for sync; the documented write/sync-failure policy is to stop the server. The source distinguishes this correctly. It trades availability and latency for a stronger local durability contract.
- aof-ack-after-write no deliberately relaxes everysec acknowledgment to queueing. Replicas sync their stream every second irrespective of the primary-style always setting; local durability is not failover durability. [E5]

Do not turn the project's “zero acknowledged writes lost” test report into a universal guarantee. Asynchronous replication can promote a node missing acknowledged writes; replication acknowledgments, local fsync and application-level consistency are different contracts. WAITAOF's documented replica result is zero, not distributed durable quorum confirmation. [E4], [E5], [E9]

### 3. A usable backup API, but a nontrivial exit path

BACKUP START captures BASE and attaches a write-stream tap at the same cut; BACKUP SEAL finalizes INCR and the manifest. Restore uses the manifest and represents the seal point, not merely the start point. The implementation has explicit phases and syncs the incremental file; the documented preload path fails rather than starting empty when the target is unreadable. HNSW graphs are rebuilt, so include rebuild latency and memory in recovery objectives. Keep all manifest-referenced files together, test restore independently, and do not copy a changing snapshot/AOF pair opportunistically. [E6]

KiviDB reads several Redis RDB forms, but Redis/Valkey cannot generally read its native dumps or replicate from it. Moving back generally requires logical key-by-key migration, with type-specific exceptions. Valkey 9.2 RDB version 81 is documented unsupported; Redis search definitions require recreation on import. Compression adds another downgrade boundary: compressed snapshots are not readable by 1.2. Older-version AOF interactions have documented double-application hazards. “Drop-in client protocol” must not be confused with “drop-in storage format.” [E2], [E5]

## Architecture

The critical path is RESP parsing → connection authentication/ACL state → command/transaction dispatch → command gate and key/shard locking → mutation → ordered replication/AOF side effects → acknowledgment. A separate write gate makes snapshot boundaries consistent without requiring reads to stop for the whole disk write. Replication and backups share the ordered write stream. Search indexes and specialized collections add their own lifecycle and recovery concerns. [E3], [E4], [E5], [E6]

The implementation is optimization-heavy: custom packed storage and unsafe operations, fast SET transaction paths, global restriction counters and per-thread command-gate slots. Those can be sensible performance techniques but are additional proof obligations; Rust alone is not evidence of memory safety for all paths. The ACL code explicitly refreshes connected-client restrictions with ACL_EPOCH, and restricted users are excluded from the EXEC fast path so commands are checked again when executed. This is a useful concrete security design, not an assertion that the whole ACL implementation was audited. [E3], [E7]

## Security, Auth and Privacy

- **Do not expose the raw service publicly.** The bare executable defaults to an all-interface listener on port 6380; package defaults are loopback. Protected mode normally refuses remote unauthenticated access, but an explicitly configured bind address disables that protective condition. Binding to all interfaces explicitly is not a substitute for authentication. Use narrowly scoped ACL users, firewall isolation and TLS; replication and cluster traffic need their own TLS configuration. [E1], [E7]
- **TLS is not in every binary.** Select tls/full builds intentionally; ordinary password authentication over plaintext transport does not protect credentials on the wire. Keep administrative configuration, backup, monitoring and scripting capabilities away from untrusted clients. [E1], [E7]
- **Input bounds exist, but do not equal abuse resistance.** The client parser distinguishes incomplete from invalid input and defines limits including 512 MiB bulk arguments, 1 GiB requests and smaller unauthenticated request bounds. Resource budgets, connection/output limits and adversarial payload testing remain necessary. [E7]
- **Startup network access is on by default in release builds.** Actual src/update_check.rs defaults to GitHub's latest-release URL, with a version-bearing User-Agent; a Cargo comment still names kividb.io. Prefer implementation over that stale comment. The request exposes normal network metadata such as source IP and version; no database payload upload was found in this module. Disable it with update-check no or KIVIDB_NO_UPDATE_CHECK=1 in restricted environments. It is skipped in debug/CI contexts. [E8]
- Treat persisted data, backups and logs as sensitive; configure host/storage access and encryption externally. This review did not establish an at-rest encryption feature or perform a secret, dependency-vulnerability or network-attack audit. A SECURITY.md reporting policy exists, but is not a security certification.

## Benchmarks and Reproduction Quality

The README's **21.24 million GET/s** is a maintainer-reported KiviDB 1.2.0 result: 32 AWS Graviton3 bare-metal cores, a separate load generator, 100-byte values, ten million keys, pipeline 16, 30-second runs, mean of two rounds, **persistence off**. It is not a measurement of the reviewed master, durability-enabled operation, or ordinary request/response application latency. The same table puts Dragonfly ahead without pipelining and Garnet ahead on pipelined SET. [E9]

Reproduction materials are stronger than a marketing chart: the repository contains a versioned Azure suite with harnesses, raw JSON result trees, engine flags, hardware, multiple rounds, latency percentiles, client/NIC bottleneck disclosures, recall measurements and failover/soak reports. The core README identifies source refs and follow-up rc8/rc10 runs, although some introductory “code that ships” wording refers to different release candidates. Resolve the exact per-run ref rather than treating all 1.2.0 tables as one experiment. Some raw assets are excluded from later source archives, so use the Git tree. [E9]

Still missing from this review: independent reruns, statistical reanalysis, a pinned acquisition of the separate bare-metal benchmark repository, and matching production distributions. Compare at equal persistence, replication, TLS, memory budgets, pipeline depth and durability semantics; test skewed hot keys, long scripts, large objects, search recall, failover and sustained disk stalls. Public open issue #1015 reports lower unpipelined throughput at 48 connections; it is an unverified user report here, consistent with why a single headline cannot select a database. [E13]

## Tests, CI and Maturity

The repository contains Rust transaction/replication/backup tests, Python E2E and client compatibility suites, a Redis compatibility harness, and versioned regression/soak material. CI specifies formatting, Clippy, compiled nextest archives/shards and compatibility checks. Security workflows scan Cargo.lock and published image variants with Trivy, failing on fixable high/critical findings; this does not cover unknown or unfixed vulnerabilities. [E10], [E11]

The compatibility report is refreshingly specific about limitations: the earlier “passed tests” count covered only eleven units before timeout; the new harness isolates units and gates unexpected failures against a known-failures list. The published 1,892-pass/31-fail table is explicitly from older Redis 8.0 testing, **not a fresh pass count for this SHA**. External-server tags skip many persistence, replication and cluster tests. Separate KiviDB suites help, but a green compatibility job cannot establish complete equivalence. [E10]

The anonymous check-runs API returned no runs for the exact merge SHA when queried. CI is primarily PR/manual triggered; this is not proof that no PR tests ran, but there is no independently verified green result for this revision in this review. The active issues/PRs and roughly six-week public repository age argue for caution despite the breadth of implementation. [E13]

## Dependencies and Licensing

LICENSE, NOTICE and Cargo.toml agree on **AGPL-3.0-only**. Ordinary network client use is distinct from incorporating database code; distributing or providing a modified network service needs a specific compliance review. The owner also offers commercial terms and asks contributors to accept a CLA. NOTICE preserves Lua, Valkey-derived command metadata and Zstandard notices. No source code was extracted into this review collection. [E12]

Cargo.lock improves dependency reproducibility, but release and feature selection matter. Optional Lua is 5.4, not Redis's 5.1; documented arithmetic/string differences can affect generated keys. Native C, crypto and allocator dependencies expand the build/supply-chain surface. Workflow action tags are not universally pinned to immutable commits. No SBOM completeness or current advisory clearance was established. [E1], [E2], [E11], [E12]

## Comparison

| Option | Prefer it when | Main tradeoff against KiviDB |
|---|---|---|
| Valkey | Familiar Redis-compatible cache operations and established operational ecosystem matter most | Validate search/module needs separately; KiviDB bundles more data types, but changes storage/recovery semantics |
| Redis | Exact application command/module behavior and existing operational tooling dominate | Benchmark comparable version, deployment and licensing; do not assume a single process is the only scaling option |
| Dragonfly | Multicore cache efficiency is the primary goal | Compare hot-key/transaction behavior, persistence, feature coverage and version-specific license terms |
| Garnet | High-throughput key-value serving is the priority | KiviDB's own comparisons show Garnet winning some write workloads; evaluate data-type/search coverage separately |
| PostgreSQL plus pgvector / a dedicated vector engine | Durable relational constraints or search-specific operations matter more than Redis wire compatibility | Different API and performance envelope; often a better authority store than making a cache replacement carry all correctness obligations |

These are workload-selection alternatives, not independently benchmarked winners in this review.

## Self-Hosting Notes

1. Pin a release/digest and feature variant; do not deploy an unqualified master merely because its docs describe fixes unavailable in stable. Verify artifact provenance, CPU/kernel requirements and container io_uring compatibility.
2. Bind privately, configure ACLs and TLS explicitly, persist the data directory, set memory/connection/output budgets and disable startup egress if necessary.
3. Choose AOF policy to match recovery objectives. Monitor aof_acks_before_write, write/sync errors, disk capacity, replication lag, snapshot memory and search rebuild latency. Provision disk headroom for checkpoint/spill/retained logs.
4. Restore a sealed backup into an isolated node and validate values, TTLs, streams, functions and search behavior. Exercise kill, full disk, torn-tail, restart, partition and failover scenarios; do not infer power-loss safety from a process-kill test.
5. Replay the application's actual commands and Lua scripts, including failures and concurrent WATCH/EXEC use. Qualify the rollback/export path before moving authoritative data.

**Operational fit:** a promising controlled cache/search trial where data can be rebuilt and multicore gains matter. Not yet a justified default swap for financial state, sole-copy application data or critical queues without independent qualification. No deployment was performed.

## Evidence and Limitations

All file links below are pinned to the reviewed source; public API and issue/release metadata are time-sensitive observations from 2026-11-26 UTC. Source claims are identified as such. This was a targeted static inspection, not an exhaustive audit, formal linearizability proof, comprehensive license audit or crash-consistency certification.

[E1]: https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/README.md
[E2]: https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/docs/COMPATIBILITY.md
[E3]: https://github.com/kividbio/kividb/tree/0c4139a904c2f4500ba99b25569179379142c0b6/src/store
[E4]: https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/docs/EXEC_ATOMICITY.md
[E5]: https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/docs/PERSISTENCE.md
[E6]: https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/src/commands/backup.rs
[E7]: https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/src/protected_mode.rs
[E8]: https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/src/update_check.rs
[E9]: https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/benchmarks/1.2.0/README.md
[E10]: https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/docs/REDIS_TEST_SUITE.md
[E11]: https://github.com/kividbio/kividb/tree/0c4139a904c2f4500ba99b25569179379142c0b6/.github/workflows
[E12]: https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/NOTICE
[E13]: https://api.github.com/repos/kividbio/kividb

### Direct implementation and supplementary evidence

- [Transaction dispatch and EXEC loop](https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/src/server.rs#L2393-L3042), [command gate](https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/src/command_gate.rs), [AOF acknowledgment implementation](https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/src/aof.rs#L1404-L1460).
- [ACL epoch and connected-user refresh](https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/src/acl.rs), [client parser bounds](https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/src/resp/parse.rs#L130-L166), [manifest/features](https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/Cargo.toml), [license](https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/LICENSE).
- [Bare-metal method/table](https://github.com/kividbio/kividb/blob/0c4139a904c2f4500ba99b25569179379142c0b6/docs/PERFORMANCE.md), [Azure core harness/results](https://github.com/kividbio/kividb/tree/0c4139a904c2f4500ba99b25569179379142c0b6/benchmarks/1.2.0/core), [v1.2.2 release](https://github.com/kividbio/kividb/releases/tag/v1.2.2), [open throughput report #1015](https://github.com/kividbio/kividb/issues/1015), [remaining parity issue #1004](https://github.com/kividbio/kividb/issues/1004), [exact-SHA check-runs endpoint](https://api.github.com/repos/kividbio/kividb/commits/0c4139a904c2f4500ba99b25569179379142c0b6/check-runs).

---

**Attribution:** kividbio/kividb; KIVIDB PRIVATE LIMITED; AGPL-3.0-only. Analysis is independent; performance and compatibility reports remain upstream claims unless explicitly verified above.
