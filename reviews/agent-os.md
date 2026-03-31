# agent-os — Review

**Repo:** https://github.com/rivet-dev/agent-os  
**Author:** Rivet (rivet.dev)  
**License:** Apache-2.0  
**Stars:** ~1,366  
**Rating:** 🔥🔥🔥🔥🔥  
**Cloned:** ~/src/agent-os  
**Reviewed:** 2026-03-31

---

## What it is

An in-process operating system for running AI coding agents at near-zero overhead. Not a wrapper around Docker or E2B — a full virtual kernel implemented in JavaScript (called secure-exec) with three execution runtimes mounted inside it:

- **WASM**: POSIX utilities (coreutils, grep, sed, bash, 20+ tools) compiled to WebAssembly
- **V8 isolates**: Sandboxed JavaScript/TypeScript — agent code runs here
- **Pyodide**: Python via CPython-to-WASM, kernel-backed I/O

The result: agents run in ~6ms cold start, ~131MB memory per agent vs 1GB+ for container sandboxes.

### Benchmarks (from README, March 2026)

- **Cold start p50:** 4.8ms vs E2B 440ms (92x faster)
- **Memory:** ~131MB full Pi agent vs ~1GB Daytona minimum
- **Cost/sec on AWS ARM:** ~$0.0000032 vs sandbox ~$0.0000190 (6x cheaper)

---

## Architecture highlights

**The kernel** manages a virtual filesystem (JuiceFS-inspired chunked VFS), process table with full POSIX semantics (PIDs, process groups, signals, zombies, waitpid), pipes/PTYs with line discipline, and a virtual network stack. External connections delegate to a host network adapter. Everything else stays in the kernel — no host processes, no Docker, no VMs.

**Deny-by-default permissions** across four domains: filesystem, network, child_process, environment. Each domain is a function returning `{allow, reason}`. You opt in to what you need.

**ACP integration** — sessions communicate over the Agent Communication Protocol (ACP) via JSON-RPC. Agents are packaged as ACP adapters. Current agents: Pi (OpenClaw), OpenCode, Codex (in progress), Claude Code/Amp (planned).

**Host tools** — define JavaScript functions on the host that agents invoke as CLI commands inside the VM. Agents see them as executables; host sees them as async functions. No network hop, no auth dance.

**Pluggable filesystem backends** — S3, Google Drive, SQLite, host directories, or custom `FsBlockStore` implementations. Mount at any VFS path.

**Built-in orchestration primitives:**
- Cron jobs
- Webhooks (external events into agent sessions)
- Queues (serialize agent work)
- Multiplayer (multiple clients observe/collaborate on one agent)
- Agent-to-agent delegation via host tools
- Durable workflows with retries + resumable execution

---

## What makes this different

Most "agent sandboxes" are wrappers around existing container tech — you rent a VM that boots in ~500ms and pay for a full compute instance per agent. agentOS embeds the execution environment directly in your backend process:

```ts
const vm = await AgentOs.create({ software: [common, pi] });
const { sessionId } = await vm.createSession("pi", { env: { ... } });
await vm.prompt(sessionId, "Build a hello world app");
```

That's it. No Docker daemon, no SSH, no network round trip to a sandbox provider.

The kernel is `@secure-exec/core` (separate package, closed-source or separate repo), and agentOS wraps it with the higher-level agent API. The secure-exec package implements the actual kernel primitives.

---

## Registry

Pre-built packages at the agentOS registry:
- **Agent adapters:** pi, pi-cli, opencode (codex/claude-code/amp planned)
- **WASM software:** coreutils, grep, sed, gawk, find, fd, ripgrep, jq, yq, sqlite3, curl, wget, git (planned), make (planned), 22 packages total
- **Filesystem drivers:** S3, Google Drive
- **Tools:** sandbox extension (E2B/Daytona integration for heavy workloads)

Software packages use date-based versioning (`0.0.YYMMDDHHmmss`), published separately from the TypeScript core.

---

## Relevance to us

**Direct:**
- Pi (OpenClaw) is a first-class supported agent — we could embed agentOS as the execution layer for any workflow requiring code execution
- The host tools pattern is elegant for integrating agent actions with existing backend code — relevant to VOS (persona execution) and any agentic pipeline we build
- Multiplayer observation mode is interesting for human-in-the-loop workflows
- Durable workflows + cron baked in means you could replace custom orchestration glue

**Marcos/patient agent:**
- Isolated Python/JS execution at 6ms cold start means we could give the agent a safe sandbox for running scripts (medication calculations, schedule generation) without infrastructure overhead
- The webhook + queue primitives map well to the async voice interaction model

**Architecture pattern:**
The `kernel → runtime drivers → VFS + process table + network` model is worth studying as a reference for any in-process execution environment. The JuiceFS-inspired chunked VFS design is particularly clean.

---

## Caveats

- `@secure-exec/core` is not in this repo — it's a dependency. The actual kernel isolation guarantees depend on code you can't inspect here.
- Pi/OpenClaw integration is listed as "coming soon" for Claude Code/Amp alongside it — may lag.
- 1,366 stars suggests early but growing traction. The benchmarks are credible but self-reported.
- No license issues: Apache-2.0, clean for any use.

---

## Bottom line

This is the sandbox-replacement story that E2B and Daytona haven't told. If you need agents to execute code in your backend, agentOS gives you 92x faster cold starts at a fraction of the cost with better security defaults — as an npm package. The architecture is genuinely novel and well-executed.

Watch it. Consider it as the execution layer if we ever need code-running agents embedded in a service.

**Files worth reading:**
- `CLAUDE.md` — detailed architecture doc (unusually good internal docs)
- `packages/core/src/agent-os.ts` — 1,210-line main API surface
- `packages/core/src/session.ts` — ACP session lifecycle

Source: Apache-2.0, rivet-dev/agent-os
