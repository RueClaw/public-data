# keepsync (progrium/keepsync)

**Repo:** https://github.com/progrium/keepsync
**Author:** Jeff Lindsay (progrium)
**License:** MIT core; vendored Syncthing MPL-2.0; embedded dependencies and separate ZeroFS have additional terms.
**Reviewed:** 2026-11-17 (UTC)
**Revision:** `ecc2111b804eb6559d2f5bfa4c9ea89195571367` (main; whole-repository static review, focused on CLI, keeper, registry, archive, restore, gateway, hook, and recovery implementations). Commit dated 2026-11-17T00:05:36Z.
**Verification:** Static inspection only. No builds, tests, installs, external binaries, bucket operations, peer connections, or user-file synchronization performed.
**Stack:** Go 1.27.2; embedded patched Syncthing, Perkeep, tailcat/WireGuard; ZeroFS 2.3.7 subprocess; S3-compatible storage; age recovery kits.
**What it is:** A personal multi-device file-sync system with a separately managed permanent archive and optional eviction of old working files—not a complete filesystem backup.

## Verdict

⚠️ **Interesting: a thoughtfully integrated sync/archive prototype, not yet a sole backup.** The recovery-set durability gate is unusually careful: expiry checks content plus the signed metadata needed to find it again. But “every version forever” is narrower than the headline, there is a documented metadata-preserving-edit data-loss case, and the two-day-old public repository has no published releases or visible Actions runs. Pilot only on disposable copies, keep expiry and hooks off initially, and retain an independent tested backup.

## What It Is

One always-on server owns the archive, signing identity, bucket connection, and node registry. Nodes run embedded Syncthing and exchange working files directly over tailcat. A server outage therefore need not stop already-configured sync; archiving, expiry, and membership changes wait. A machine can run both roles.

A kept folder links its sync identity to a Perkeep root through `.keepsync`. Up to two assigned keepers walk regular files every five minutes. Defaults wait 48 hours after modification, with a seven-day max-defer policy; expiry is disabled unless configured. This is settled-version capture, **not every save**: an edit or deletion inside the grace window may never reach the archive. The max-defer tracking map is not persisted across keeper restarts. [1] [2] [3]

## Stack and Architecture

| Layer | Implementation and consequence |
|---|---|
| CLI/control | `cmd/keepsync`; local JSON-over-HTTP Unix control sockets, mode 0600 |
| Working-set sync | Pruned Syncthing v2.1.7 source with three documented patches; discovery, native relays, NAT handling and usage reporting disabled in favor of tailcat |
| Transport | Key-approved tailcat connections, direct where possible and DERP fallback; no Tailscale account/control plane required |
| Coordination | Registry membership/policies; locally atomic JSON state, mirrored into ZeroFS for later flush |
| Archive | Embedded Perkeep content-addressed blobs, signed permanodes/claims, rebuildable index, version-vector attributes |
| Bucket bridge | Separate pinned ZeroFS process, normally userspace 9P with no mount/root; encryption/compression delegated to ZeroFS |
| Recovery | age-encrypted ZIP containing identities, configuration, bucket credentials, encryption password, registry fallback and binaries |

`internal/api` supplies interfaces and test doubles. This separates keeper policy from sync/transport/storage and makes failure cases testable. The server serializes archive claims, creates file/directory permanodes, and uses multi-claims for related attribute updates. This is not an application-consistent snapshot across an entire directory. [2] [4] [5]

**Store mode** keeps a full local blob archive and asynchronously replicates it to ZeroFS; **cache mode** makes ZeroFS the primary blob store and keeps only the index/cache locally. The latter saves local disk but increases dependence on the bucket and flush/retry path. “One Go binary” does not mean a single-process deployment: ZeroFS is downloaded or supplied separately and supervised. [1] [6]

## Key Features and Actual Synchronization Semantics

### Ordering and conflict preservation

Keepers consult Syncthing local/global state before claiming or expiring a file; archive claims record its version vector rather than relying exclusively on mtime. Comparable vectors help prevent a stale offline node from rolling the archive backward. Concurrent/missing-vector cases fall back to mtime ordering; `keeper/version.go` also falls back when FileState lookup fails. This is useful causality integration, not a general distributed transaction guarantee. [3] [4]

Syncthing chooses a winning file and creates a `.sync-conflict-*` copy for the other. Keepsync archives those copies as ordinary files. Optional hooks run on one designated node, with original/conflict paths and an ancestor file; an explicit flag distinguishes an exact base from a guess. Identical conflict copies are deduplicated. An unkept folder’s automatic hook runner has no failover. [7]

### Deletes, renames, and expiry are different

A confirmed Syncthing deletion produces an archive “gone” mark, not physical blob deletion. Mere absence from a walk does not imply deletion. Renames become a new path plus a gone old path rather than a stable rename operation; previously kept old-name history remains accessible. Ordinary restore skips intentional deletions and old names, includes expired files, and accepts `--deleted` for the former. `unkeep` stops uploads and expiry but does not erase the archive. Leaving a folder keeps local files; rejoining a nonempty directory requires `--merge`, and can resurrect files deleted elsewhere while absent. [1] [3] [8]

Expiry uses **file mtime**, not arrival time. Imported old-dated files may disappear from every synced node soon after being archived and confirmed durable. Restoring into an expiring folder can cause immediate re-expiry; use a separate destination. There is no built-in purge/garbage collection, so permanent retention has storage-cost and erasure-policy consequences. [2]

### Durability is more than an upload receipt

Before eviction, the keeper re-hashes content, verifies the archive ref, and asks whether the file plus its naming claims/permanodes are durable. The server traverses schema dependencies, including content chunks and signing public-key dependencies, tracks their presence before a flush, and advances a watermark only after successful ZeroFS flush. It detects ZeroFS restarts during flush. Server/flush failure pauses expiry rather than deleting optimistically. [3] [6]

In store mode, restart handling re-copies locally retained blobs that a failed ZeroFS instance lost. In cache mode, keepers retry unconfirmed content with exponential backoff while that exact local file remains available. Signed claims have a local stash for re-upload. These are meaningful recovery mechanisms, but an upload/claim is not yet bucket durability; modified/deleted local files can no longer supply their prior bytes. The retry maps are in memory, not a durable per-version content spool. [3] [6]

## Important Data-Loss and Restore Limits

1. **Documented loss with preserved size and mtime.** A tag editor can change bytes without either changing. Syncthing and the keeper may miss the edit. Although expiry hashes on the edited node, another node can expire the old copy and propagate a deletion that removes the invisible edit. The specification explicitly acknowledges this. Disable metadata-preserving editing or touch changed files; an independent backup remains necessary. [Edge cases] [2]
2. **Hook pre-archive is not a durability barrier.** `runConflict` calls `KeepNow` and checks errors, but does not wait for `Durable` before executing a destructive hook. It also does not require both paths to appear in `Report.Kept` (a path can be classified lagging). The blanket claim that any hook action can always be undone is too strong, particularly if a cache-mode server loses unflushed bytes after the hook deletes its source. This is a static control-flow finding, not a reproduced crash. [3] [7]
3. **Not a full filesystem image.** Only regular files are kept: symlinks and empty directories are skipped. Restore preserves file permission bits and mtime, not a demonstrated complete ACL/xattr/ownership/hard-link backup contract. No cross-file quiescing or database snapshot mechanism was found. [2] [3] [8]
4. **Restore’s unchanged check is size+mtime, not content.** Even `--force` reaches that early return first; same-metadata corruption can be skipped. Restore writes a temporary file then renames it, protecting against partial content downloads, but does not fsync the restored file/directory. Its lexical destination-prefix check does not reject existing symlink ancestors, and its no-force existence check is not an atomic no-clobber commit. Restore into a fresh, trusted, non-concurrently-written directory and verify hashes separately. These last filesystem concerns are static findings, not exploit demonstrations. [8]
5. **Check-then-delete is not writer exclusion.** Expiry rechecks type, size and mtime before `os.Remove`, but there is no lock against arbitrary concurrent application writes or a hash-bound atomic unlink. Strong practical guards should not be read as proof against all races. [3]

## Security, Permissions, and Privacy

**Trust the approved-device set as one personal administrative domain.** Registry calls check membership for archive paths/claims, but an approved node can join an existing folder without a separate owner approval. Any folder member can request claims or keep-policy changes; keeper assignment is not a hostile-member authorization boundary. Gateway `read` opens the **whole archive**, including folders never joined or already left; default `blobs` can fetch any known ref. This is not multi-tenant isolation or end-to-end encryption against the server. [2] [9]

The gateway is deliberately loopback-only, has a random file-backed token, uses constant-time password comparison, checks Host and Origin, strips client authorization/cookies before proxying, and restricts methods to read-oriented operations. The server independently filters Perkeep operations; nodes cannot directly sign or remove archive blobs through that interface. Control sockets and secret config files use owner-only permissions. Good boundaries, but processes running as that same OS user remain trusted. [9] [10]

Bucket credentials and the ZeroFS encryption password live in server TOML, protected by permissions rather than encrypted locally. ZeroFS receives them through environment variables rather than generated TOML. The age kit contains enough authority to decrypt the archive and impersonate the server; safeguard its passphrase separately, and treat recovered binaries as executable trusted material. Encryption at rest in the bucket does not protect plaintext files/indexes on compromised nodes or the archive host. [11]

Hooks are **unsandboxed executables**, inherit `os.Environ()`, and send stdout/stderr into logs. A timeout/process-group kill is lifecycle control, not filesystem/network confinement. An LLM hook can send file contents to its chosen provider; no LLM integration is required by the core. Place executable hooks outside writable synced directories, avoid secrets in inherited environments, and review their logging/egress. [7]

Tailcat’s public DERP rendezvous/relays and the selected bucket are network dependencies even without public inbound ports. Encryption is not metadata anonymity: endpoints, timing, traffic volume and bucket operations still have observers. Syncthing usage reporting and generated ZeroFS telemetry are disabled. The custom tailcat key derivation and upstream cryptographic/storage implementations were not independently audited here. [2] [5] [11]

## Persistence, Recovery, Retention, and Export

The registry saves locally before publishing changes, but its mirror failure is logged rather than failing the save. Disaster recovery therefore uses the last flushed mirror or the kit fallback—not necessarily the latest approvals/revocations/policies. Recheck membership after recovery, especially if an old kit could restore access for a removed node. Local atomic rename is useful but does not make all related stores one transaction. [12]

Recovery rebuilds the index from bucket blobs, checks hashes, and refuses existing destination identity/config files. A drill uses a separate bucket copy and can compare a baseline. ZeroFS is single-writer: recovering against a bucket while the old writer is still alive is unsafe. Cache mode does not provide a second complete local copy; store mode does, but neither automatically provides an independent immutable/offline backup. Bucket deletion, credentials compromise, lifecycle rules, key loss and retention mistakes remain outside the expiry gate. [1] [11]

Export is reasonably open: ordinary Perkeep blobs/claims, `restore`, `pk-get`, `pk-mount`, and historical `--at` views. However, the S3 bucket is a ZeroFS filesystem representation, not a directly browsable tree of original files. You need the compatible ZeroFS implementation/password plus Perkeep interpretation. `--at` uses **server archival claim time**, not edit time, so it cannot reconstruct versions that grace never captured. No built-in physical purge exists; exclusion rules stop future capture, not erase already archived sensitive material. [1] [2]

## Build, Platform, Update, and License Risks

The manifest requires Go 1.27.2 and pins many modules, including recent pseudo-versions of Perkeep/tailcat/Tailscale. The local Syncthing `replace` means clone-and-build, not ordinary `go install ...@version`. Its pruned vendored copy omits upstream tests and needs patch reapplication on update. A large transitive dependency graph remains despite the single CLI. No dependency vulnerability audit or reproducible build was performed. [5]

ZeroFS auto-downloads are pinned to v2.3.7 with tarball and per-binary SHA-256 checks, a positive supply-chain control. **Explicit/PATH binaries take precedence**, though, and pin mismatches are warnings rather than fatal. Thus an installed different ZeroFS can bypass the tested-version assumption. Format/layout migrations need deliberate rehearsal; existing diskpacked archives require a mount mode, whereas new 9P archives use files-per-blob. [1] [13]

The pinned binary matrix includes Linux amd64/arm64, macOS amd64/arm64, and FreeBSD amd64. Default 9P requires neither FUSE nor root; FUSE/v9fs modes are Linux-specific and v9fs requires root. Linux has parent-death handling for ZeroFS; other platforms rely on startup stale-process cleanup. This matrix is not cross-platform test proof, and Windows is not a qualified server target here. [1] [13]

Root MIT grants reuse with its notice; it does not erase MPL-2.0 obligations for modified Syncthing files or Apache/BSD dependency notices. Separate ZeroFS is AGPL-3.0 (or separately commercially licensed); subprocess separation does not waive distribution obligations for that binary, including inside kits. The specification explicitly lists third-party release notices as unfinished packaging. No upstream code was extracted for this review. [2] [5] [14]

## Maturity and Evidence

Anonymous GitHub metadata checked 2026-11-17: repository created 2026-11-15; last push 2026-11-17T00:05:38Z; 20 stars, 1 fork, 0 open issues. Releases API returned an empty list; Actions runs returned total_count 0, and no `.github` workflow directory was found at this revision. These are a snapshot, not quality scores. [15]

There are substantive unit/regression tests for policy, gone marks, clock ordering, permissions, restart durability, joins/leaves, gateway scopes, 9P, conflict hooks, and recovery. The e2e harness covers a server and three nodes, but requires real ZeroFS/MinIO binaries and otherwise skips. The spec’s “all steps pass” is author-reported, not independently confirmed. Its benchmark uses 500 random blobs totaling 26.7 MiB with local MinIO; that does not establish WAN performance or large real-folder restore times, which the spec explicitly leaves unmeasured. [2] [16]

## Comparison

| Option | Prefer it when | Tradeoff against keepsync |
|---|---|---|
| [Syncthing](https://syncthing.net/) plus [restic](https://restic.net/) or [Kopia](https://kopia.io/) | Reliable working-set sync and independently scheduled, verified snapshots matter most | Two systems and separate retention policies; no integrated archive-before-eviction contract |
| [Perkeep](https://perkeep.org/) directly | Permanent content-addressed personal archiving and its tooling are the main goal | More assembly/configuration; no keepsync keeper election and sync-expiry integration |
| keepsync | Exploring a unified hot working set plus permanent cold archive across trusted personal devices | Very new integration; destructive expiry, partial capture semantics, shared trust and recovery-kit operations need qualification |

These are architectural alternatives, not side-by-side performance measurements. Restic/Kopia are backup systems, not substitutes for live multi-writer synchronization.

## Practical Evaluation Plan

Use a pinned revision and disposable duplicate files first; leave expiry and hooks disabled. Verify capture, delete/rename/conflict behavior, offline rejoin, size+mtime-preserving edits, and independent checksum restores. Exercise store and cache failure paths separately, and drill recovery from a bucket copy with the original server isolated. Validate quotas/costs, local disk growth, secrets/kit custody, and removal of revoked nodes from recovered membership. Only consider expiry after those tests pass, with a second independent backup still available. No deployment or drill was carried out in this review.

## Evidence Map

All implementation links are pinned to the reviewed commit.

[1]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/README.md
[2]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/docs/spec.md
[3]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/keeper/keeper.go
[4]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/pkserver/signer.go
[5]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/third_party/syncthing/KEEPSYNC.md
[6]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/pkserver/durability.go
[7]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/node/conflicts.go
[8]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/node/restore.go
[9]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/registry/server.go
[10]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/gateway/gateway.go
[11]: https://github.com/progrium/keepsync/tree/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/kit
[12]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/server/store.go
[13]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/zerofs/pin.go
[14]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/LICENSE
[15]: https://api.github.com/repos/progrium/keepsync
[16]: https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/test/e2e/harness_test.go

**Additional implementation evidence:** [keeper version fallback](https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/keeper/version.go), [hook environment/execution](https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/hook/hook.go), [node scopes](https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/pkserver/scope.go), [Go manifest](https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/go.mod), [ZeroFS configuration](https://github.com/progrium/keepsync/blob/ecc2111b804eb6559d2f5bfa4c9ea89195571367/internal/zerofs/config.go), [releases](https://api.github.com/repos/progrium/keepsync/releases), [Actions](https://api.github.com/repos/progrium/keepsync/actions/runs).

**Attribution:** progrium/keepsync by Jeff Lindsay; MIT core with the component terms described above. Independent static analysis; no claim of security certification or verified production durability.
