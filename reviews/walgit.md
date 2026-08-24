# walgit (tobi/walgit)

**Repo:** https://github.com/tobi/walgit
**License:** MIT; permissive reuse with attribution
**Reviewed:** 2026-08-24
**Stack:** Rust, Tokio, Axum, gitoxide/gix, S3/GCS object stores, Protobuf, React/Vite
**What it is:** A share-nothing Git hosting server that treats an object-store bucket as the repository source of truth. It serves smart HTTP Git, bundle-uri clones, LFS, web browsing, JSON APIs, policy, events, and maintenance from disposable cache instances.

---

## Verdict

✅ **Deploy candidate for serious infrastructure experiments, not casual production yet.** walgit is a unusually complete first public release: the core design is crisp, the Rust crate boundaries are coherent, the documentation explains the invariants, and the fast Rust lib/bin test tier passed locally. The big caveat is maturity: it is a one-commit public repo released yesterday, so anyone using it should pilot it against non-critical repositories before trusting it as the only Git host.

---

## What It Is

walgit is a Git server built around the architecture described in Cursor's "Git at any scale": writes become immutable pack/log objects in S3 or GCS, and visibility is controlled by a compare-and-swap manifest. Any server instance pointed at the same bucket can serve the same repositories; local disk is only cache.

The target workload is the hard part of Git hosting: large repositories with huge packfiles, many refs, and machines that cannot hold the full repository locally. walgit addresses that by splitting reads into levels: refs from the WAL, serving from the pack parts that fit, remote range reads for large bases, and bundle-uri for moving clone bytes directly from bucket/CDN to client.

This is not trying to replace GitHub as a collaboration product. It deliberately omits issues, CI, reviews, and merge queues. It is a storage and protocol layer: smart HTTP v0/v2, receive-pack, upload-pack, LFS, bundle lists, per-repo push policy, event webhooks, a browsing UI, and operational commands.

## Stack

| Layer | Tech |
|-------|------|
| Server | Rust 2024, Tokio, Axum, Hyper/Tower |
| Git protocol | Upstream `git`, gitoxide/gix, smart HTTP v0/v2, receive-pack/upload-pack |
| Coordination | Object-store CAS, leases, immutable log segments, Protobuf manifests |
| Storage | S3/S3-compatible stores, GCS, in-memory store for tests |
| Clone acceleration | Git bundle-uri, static bundle lists, range/static object serving, optional nginx `X-Accel-Redirect` |
| Auth | none/token/OIDC, bearer/basic git credentials, browser-issued access tokens |
| Web | React, Vite, TypeScript, embedded static assets, JSON API/SDK |
| Testing | Rust unit/integration tests, e2e shell tests, store contract tests, simulation tests |

## Key Features

### Object Store As Source Of Truth

The core model is clean: repository state lives in `manifest.pb`, immutable `log/<seq>.pb` entries, content-addressed packs under `wal/`, checkpoints, bundles, policies, LFS objects, and event cursors. A push uploads objects first and becomes visible only when the manifest CAS succeeds.

That gives the system a useful failure model. A server crash loses cache warmth, not repository state. Compaction, bundle creation, fsck, and event delivery are WAL readers rather than hidden write-path side effects.

### Bundle-URI First Clone Path

walgit treats clone bytes as static objects. Weekly full bundles, daily/hourly incrementals, catch-up lists, blobless families, range requests, and optional edge offload are all first-class. The docs are refreshingly concrete about why this matters: a Git server should not proxy tens of gigabytes of monorepo base packs when a bucket or CDN can serve them directly.

### Explicit Sync Levels

The repo distinguishes refs-level reads, serve-level reads, full materialization, and object-level remote reading. This is the right abstraction for machines smaller than the repositories they serve. Ref advertisements and web refs can be fast without pulling pack data; expensive object work happens only where placement allows it.

### Push Policy And Auth Are Real, Not Afterthoughts

The policy language is intentionally small: named rules, explicit matching, protected refs, groups, bypasses, fail-closed parsing, and clear semantics for overlap. Auth supports loopback experiments, static tokens, and OIDC, with validation rules such as OIDC requiring no anonymous read and a real allowlist.

### Strong Operator Documentation

The strongest artifact may be `AGENTS.md`, `GOAL.md`, and the docs directory. They encode the invariants, cost model, integrity checks, bundle design, event semantics, and contribution rules in enough detail that a reviewer can tell what the system is trying to protect.

## Architecture

The workspace is split into focused Rust crates:

- `walgit-proto` defines the WAL schema and object-store key layout.
- `walgit-store` abstracts S3, GCS, memory stores, CAS, range reads, compose, and leases.
- `walgit-git` handles local bare repositories, refs, pack ingest, connectivity, and protocol helpers.
- `walgit-wal` owns repository handles, sync levels, publish, checkpoints, remote reads, tasks, and log reading.
- `walgit-bundle` plans and renders bundle-uri outputs.
- `walgit-server` exposes smart HTTP, LFS, bundles, auth, policy, web/API, events, telemetry, and maintenance loops.
- `walgit-cli` provides serve/import/mirror/compact/bundle/wal/config/repo commands.

The most important architecture choice is that coordination is object-store-native. There is no database, queue, or node registry. The manifest CAS is the linearization point; immutable objects are written before visibility; readers revalidate against the manifest; long maintenance work publishes back through the WAL.

## Comparison

| Aspect | walgit | Conventional Git Host | Cursor Continuity Design |
|--------|--------|-----------------------|--------------------------|
| Source of truth | Object-store WAL and CAS manifest | Local repositories plus database/replication | Object-store WAL |
| Server state | Disposable cache | Usually durable local repo storage | Disposable cache |
| Clone strategy | Static bundle-uri plus remainder fetch | Server-generated pack negotiation | Static/bucket-oriented |
| Scope | Git protocol/storage layer | Full collaboration platform | Architecture pattern, not OSS implementation |
| Maturity | Fresh public implementation | Mature products vary | Production-proven idea, external design |

walgit is best read as a practical open implementation of the Continuity-style Git storage pattern, with extra attention to small-instance operation. Compared with a full forge such as GitLab or Gitea, it is narrower but architecturally more interesting for elastic Git hosting.

## Self-Hosting Notes

Start with the standalone config against a local S3-compatible store. The README documents `just dev-store`, `walgit.standalone.toml`, Docker/Podman, Nix, and nginx fronting. For anything beyond loopback, do not run `auth.mode = "none"`; use static tokens or OIDC, set real secrets through environment variables, and keep bucket credentials scoped.

Operationally, treat the object bucket as production data. Enable versioning/retention according to your recovery policy, monitor the maintainer tasks, and run the e2e/store contract tests against the exact S3-compatible backend you plan to use. The local fast Rust lib/bin tier passed in this review: 182 passed, 1 ignored, with a build warning that the real web UI was not built before embedding.

The repo is very young. The design and tests are much more serious than a typical same-day release, but production adoption should wait for more multi-environment soak, tagged releases, upgrade notes, and real-world failure reports.

---

**Attribution:** tobi/walgit, MIT
