# Cloudflare Computer (cloudflare/computer)

**Repo:** https://github.com/cloudflare/computer  
**License:** MIT  
**Reviewed:** 2026-08-07  
**Commit reviewed:** `8758b51c8891c211dddd1903d2ee2d12a75ac7ff`  
**Stack:** TypeScript, Cloudflare Workers, Durable Objects SQLite, Dynamic Workers, Cloudflare Containers, FUSE, capnweb, just-bash, isomorphic-git, AI SDK tools  
**What it is:** A preview Cloudflare package that gives agents a persistent Durable Object-backed workspace filesystem and one runtime API that can execute against Worker shell, Worker JavaScript, or container backends.

---

## Verdict

⚠️ **Interesting and architecturally sharp, but still preview infrastructure.** Cloudflare Computer is one of the clearest attempts to make an agent workspace a first-class platform primitive: durable files, runtime routing, git, AI SDK tools, assets, artifacts, observability, and container sync all live behind one `Workspace` facade. The README is explicit that APIs are unstable and not production-ready, so this is better treated as a serious design reference or experimental substrate than a default dependency today.

---

## What It Is

Cloudflare Computer gives a Cloudflare Durable Object a durable virtual filesystem backed by the DO's SQLite storage. Code can use `workspace.fs` like a small async filesystem, then run commands or modules against the same files through `workspace.runtime.exec()`.

The notable part is the backend split. The same workspace can route execution to a full Linux container running `computerd`, a Dynamic Worker shell powered by `just-bash`, or a Dynamic Worker JavaScript module runtime. That lets a caller pick between fast lightweight isolate work and heavier real-userland execution without changing the filesystem API.

The target user is anyone building agents on Cloudflare Workers who needs a persistent working directory, controlled execution, and shareable artifacts without standing up a separate VM or storage service.

## Stack

| Layer | Tech |
|-------|------|
| Host runtime | Cloudflare Workers, Durable Objects, DO SQLite |
| Workspace facade | TypeScript package `@cloudflare/computer` |
| Filesystem core | `@cloudflare/dofs`, SQLite schema, content-addressed chunks, VFS provider |
| RPC/sync | `@cloudflare/computer-rpc`, capnweb, WebSocket sessions |
| Container execution | Cloudflare Containers, `computerd`, FUSE mount |
| Isolate shell | Dynamic Workers, Worker Loader, `just-bash` command groups |
| Isolate JavaScript | Dynamic Worker module runtime with Workspace-backed `node:fs/promises` |
| Agent tools | AI SDK `read`, `write`, `edit`, `ls`, optional `exec` and `publish` |
| Git/artifacts | `isomorphic-git`, R2 presigned assets, Cloudflare Artifacts |
| Test/CI | Vitest, Cloudflare Workers test pool, Biome, GitHub Actions |

## Key Features

### Durable Workspace Filesystem

`@cloudflare/dofs` is the storage foundation. It implements filesystem primitives over Durable Object SQLite, including reads, writes, directory listing, stat, grep, symlinks, watches, garbage collection, and sync building blocks. The README calls out a roughly 10 GB per-workspace limit because the filesystem shares DO storage.

This is the core value: an agent can keep a working directory close to the Worker without pretending object storage is a POSIX filesystem.

### One Runtime Surface, Three Execution Backends

`workspace.runtime.exec(source, { backend })` is the single entry point. For command backends, `source` is shell syntax. For the JavaScript backend, `source` is an ECMAScript module with structured input and return values.

The three shipped backends cover useful tradeoffs:

- Container backend: full Linux userland, real binaries, real network, slower cold path, sync bracket around execution.
- Worker shell backend: fast, no container, no second store, limited command set.
- Worker JavaScript backend: structured module execution, durable relative imports, Workspace-backed filesystem, trusted `ws:git` and `ws:artifacts` modules.

### Agent Tool Layer

`@cloudflare/computer/tools` wraps the workspace as AI SDK tools: `read`, `write`, `edit`, `ls`, optional `exec`, and optional `publish`. The tool design has practical guardrails: read caps, write caps, edit diff previews, fixed tool names, readonly mode, and backend descriptions that help a model choose the cheapest runtime.

The `exec` tool is still an authority boundary. The docs correctly frame it as opt-in and recommend `readonly: true` when inspection-only agents should not mutate files or run commands.

### Git, Assets, and Artifacts

Git is an opt-in subpath backed by `isomorphic-git`, so consumers that do not need git avoid pulling that graph into the default package. Assets can publish workspace files to R2 with presigned URLs, and Artifacts provide a session-scoped facade over Cloudflare Artifacts.

That combination points at a complete agent loop: create files, run tools, commit or publish outputs, and keep the whole session scoped.

## Architecture

The monorepo is cleanly split:

- `packages/dofs` owns the SQLite-backed VFS and sync primitives.
- `packages/rpc` owns capnweb wire interfaces and sync drivers.
- `packages/computerd` owns the in-container FUSE daemon and exec runner.
- `packages/computer` owns the public Workspace facade, backend routing, tools, git, assets, artifacts, and observability hooks.
- `examples/` demonstrates container, worker-shell, worker-javascript, Think-agent, tutorial, assets, artifacts, and runtime-comparison use cases.

The design pattern worth studying is the authoritative-host-store model. The Durable Object owns the canonical filesystem; runtimes either call back into that store directly or synchronize around execution. That keeps workspace state durable and platform-native while allowing different execution substrates.

The code also has good lifecycle details: lazy backend connections, per-backend mutation queues, retry scheduling for failed post-command pulls, stub disposal guidance, heartbeat handling for container RPC sessions, and span-style observability hooks.

## Comparison

| Aspect | Cloudflare Computer | VM/container sandbox systems | Plain object storage |
|--------|---------------------|------------------------------|----------------------|
| State model | Durable Object SQLite filesystem | Usually local disk plus sync/export | Object/blob API, not filesystem-native |
| Execution | Pluggable Worker shell, Worker JS, or container | Usually one container/VM runtime | None |
| Agent fit | First-class tools, git, artifacts, runtime API | Depends on wrapper code | Requires custom workspace layer |
| Operational shape | Cloudflare-native, preview APIs | More portable but more infrastructure | Simple storage, weak runtime story |
| Main caveat | New, unstable, Cloudflare-specific | Heavier lifecycle and isolation management | Poor fit for code-agent workflows |

## Self-Hosting Notes

This is not a generic self-hosted service. It is a Cloudflare Workers/DO/Containers library. Consumers need `nodejs_compat`; Worker shell and Worker JavaScript backends need the `experimental` flag plus a Worker Loader binding; the container backend needs a Cloudflare Container running `computerd`.

The container FUSE path has real performance tradeoffs. The published benchmark says metadata-heavy operations can beat ext4, but large sequential I/O is much slower. A full `npm install` of `cloudflare/sandbox-sdk` took 124.7s on computerd FUSE versus 63.9s on ext4 and 34.3s on tmpfs.

Security posture is mostly about how the host wires it. Public gateways must validate backend choices server-side, use readonly tools for inspection-only agents, and treat environment variables, git credentials, command execution, and artifact sharing as explicit authority boundaries.

---

**Attribution:** cloudflare/computer, MIT, https://github.com/cloudflare/computer
