# Dynoxide (nubo-db/dynoxide)

**Repo:** https://github.com/nubo-db/dynoxide
**License:** MIT OR Apache-2.0
**Reviewed:** 2026-06-20
**Stack:** Rust 2024, SQLite/rusqlite, Axum, Tokio, rmcp, SQLCipher feature flags, wasm-bindgen, @sqlite.org/sqlite-wasm, Node test harness, Playwright, GitHub Actions
**What it is:** A fast, embeddable DynamoDB emulator backed by SQLite, available as a native binary, Docker image, Rust library, browser/WASM engine preview, GitHub Action, and MCP server for coding agents.

---

## Verdict

✅ **Deploy candidate.** Dynoxide is a serious replacement candidate for DynamoDB Local in local development, CI, and Rust test suites. The most valuable parts are its embedded mode, conformance-driven compatibility work, MCP server, small static Docker image, and unusually clear security posture for agent-facing local tooling.

The caveats are mostly scope-related: it is not a production DynamoDB replacement, the WASM backend is explicitly preview, and some cloud-only DynamoDB features are intentionally out of scope.

---

## What It Is

Dynoxide implements a DynamoDB-compatible local engine over SQLite. It can run as:

- a local HTTP server that accepts the DynamoDB JSON API
- an embedded Rust library via `Database::memory()` or file-backed databases
- an MCP server exposing DynamoDB operations as agent tools
- a small Docker image intended as a drop-in test fixture
- a browser/WASM engine preview backed by SQLite OPFS
- a GitHub Action for CI test setup

The core pitch is simple: DynamoDB Local is slow and JVM-heavy, while Dynoxide starts in milliseconds and can be used without Docker, a JVM, or a port at all.

## Maturity

GitHub metadata at review time:

- Stars: 47
- Forks: 4
- Open issues: 5
- Latest release: v0.10.0, published 2026-05-29
- Latest reviewed commit: `9a5101191b370778877c53d4de9fdbd4d087fdfd`
- Security policy: present

The project is young but unusually disciplined for its age. It has a changelog, dual license, release workflows, benchmark automation, conformance docs, CI across feature combinations, cargo-deny, Docker smoke tests, browser engine tests, and explicit security documentation.

## Architecture

Dynoxide is organized around a core `Database` API over a storage backend. The native backend is SQLite through rusqlite; the newer 0.10.x line introduced a `StorageBackend` trait so native and WASM backends can share action-handler logic.

Key areas:

| Area | Role |
|------|------|
| `src/actions/` | DynamoDB operation handlers |
| `src/storage.rs` | Native SQLite storage, schema, metadata, hash/index helpers |
| `src/storage_backend/` | Backend trait and SQL builder layer |
| `src/server.rs` | Axum DynamoDB-compatible HTTP API |
| `src/mcp/` | MCP stdio and Streamable HTTP transports |
| `src/partiql/` | PartiQL parser/executor |
| `src/expressions/` | Condition, key condition, projection, and update expression handling |
| `src/streams.rs`, `src/ttl.rs` | DynamoDB Streams and TTL emulation |
| `src/wasm_api.rs` | Operation-level API for the browser/WASM engine |
| `js/` | Engine client and SQLite-WASM bridge tests |
| `benchmarks/` | Comparative benchmark harness |

The design is more than a thin HTTP shim. It models DynamoDB details such as expression grammar, GSI/LSI behavior, pagination cursors, consumed capacity envelopes, transactions, PartiQL, streams, TTL, tags, and AWS-shaped validation errors.

## Standout Features

### Embedded Test Database

For Rust consumers, `Database::memory()` gives each test an isolated in-memory DynamoDB-compatible database without a server, Docker container, or table-name prefixing. That is the cleanest use case: fast integration tests with real-ish DynamoDB behavior and no test infrastructure.

### Conformance-First Compatibility

The README and docs point to an external `dynamodb-conformance` suite that compares Dynoxide, DynamoDB Local, dynalite, and real AWS DynamoDB. This is the right way to build an emulator: compatibility claims are backed by a shared suite rather than README assertions.

### Agent-Facing MCP Server

Dynoxide exposes 34 MCP tools covering tables, items, batch operations, query/scan, transactions, PartiQL, TTL, tags, streams, snapshots, and database info. The server can run over stdio or Streamable HTTP.

The MCP design has practical agent safeguards:

- read-only mode
- query/scan item and byte limits
- snapshots and auto-snapshot before `delete_table`
- optional OneTable data model context
- bearer auth for HTTP transport
- Host and Origin allowlists

That combination makes it useful for agent experiments against local DynamoDB-shaped data without handing an agent a production endpoint.

### Small Static Container

The Docker image is `FROM scratch`, exposes the DynamoDB port by default, and documents MCP as opt-in. It is positioned correctly as a test fixture rather than a production database product.

### Browser/WASM Engine Preview

The WASM path is not the main production surface, but it is interesting: the project is moving toward a packaged browser engine backed by official SQLite WASM over OPFS, with a versioned worker RPC contract and TypeScript client.

## Verification

Local checks on 2026-06-20:

```sh
cargo test
npm ci
npm test
npm audit --audit-level moderate
```

Results:

- `cargo test` passed across unit, integration, and doc tests.
- `npm ci` passed.
- `npm test` passed: 34 Node tests.
- `npm audit --audit-level moderate` reported 0 vulnerabilities.

The first `npm test` run failed before `npm ci` because `@sqlite.org/sqlite-wasm` was not installed in `node_modules`; after installing from the lockfile, the JS suite passed.

## Security Notes

The security posture is better than average for local agent tooling. The MCP HTTP transport now requires bearer-token auth; loopback binds auto-generate a persisted token, non-loopback binds require an explicit token, and `--no-auth` is limited to loopback. The project also documents DNS rebinding and Origin/Host checks.

There was a prior MCP HTTP DNS rebinding/CSRF advisory in 0.9.x, fixed by upgrading `rmcp` and adding explicit checks. Current code depends on `rmcp` 1.6.0 and has tests around auth, Host, Origin, and non-loopback behavior.

The plain DynamoDB HTTP server intentionally behaves like a local emulator and includes permissive CORS when an Origin is present. That is acceptable for a local test database, but users should not expose it as a real database service.

Docker runs as root by default to match DynamoDB Local convenience, but non-root operation is documented.

## Limitations

- Not intended for production DynamoDB replacement.
- Cloud-only DynamoDB features are intentionally out of scope: backups, global tables, Kinesis integration, capacity management, import/export service operations, and similar infrastructure APIs.
- SQLite is strongly consistent, so it cannot model DynamoDB eventual consistency.
- Streams use a single-shard model.
- Transaction contention errors are not emulated.
- The WASM backend is preview and is not run against the same conformance suite as native.
- Legacy pre-2015 DynamoDB API parameters are only partially supported.

## Comparison

| Aspect | Dynoxide | DynamoDB Local | LocalStack DynamoDB | dynalite |
|--------|----------|----------------|---------------------|----------|
| Runtime | Native Rust | JVM | Docker + Python/Java stack | Node.js |
| Storage | SQLite | SQLite | DynamoDB Local internally | LevelDB |
| Embedded Rust mode | Yes | No | No | No |
| MCP server | Yes | No | No | No |
| Browser/WASM path | Preview | No | No | No |
| Best fit | Tests, CI, local agents | AWS-official local tests | Multi-service AWS emulation | Lightweight JS-local emulation |

## Who Should Use It

Good fit:

- Rust projects that use DynamoDB and want fast integration tests.
- CI suites currently paying DynamoDB Local startup cost.
- Agent workflows that need a disposable DynamoDB-shaped database.
- Local-first apps that want DynamoDB-compatible semantics for tests.
- Browser experiments that can tolerate a preview engine.

Poor fit:

- Production databases.
- Systems needing exact DynamoDB capacity, throttling, replication, backup, or global-table behavior.
- Security-sensitive deployments that would expose the plain DynamoDB HTTP endpoint on a network.

---

**Attribution:** nubo-db/dynoxide, MIT OR Apache-2.0
