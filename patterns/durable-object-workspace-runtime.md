# Durable Object Workspace Runtime

**Source:** cloudflare/computer  
**License:** MIT  
**Reviewed:** 2026-08-07  

## Pattern

Make the durable workspace the authoritative store, then route execution to pluggable runtimes that either operate directly against that store or synchronize around a command boundary.

In Cloudflare Computer, a Durable Object owns a SQLite-backed virtual filesystem. The `Workspace` facade exposes that filesystem and one runtime API:

```ts
using run = await ws.runtime.exec("npm test", {
  backend: "container",
  encoding: "utf8",
});
const result = await run.result();
```

The same workspace can register multiple backend IDs:

- a container backend for full Linux userland;
- a Worker shell backend for fast lightweight commands;
- a Worker JavaScript backend for structured module execution.

## Why It Works

Agents need a working directory more than they need a particular machine. By making workspace state durable first, execution becomes a policy choice:

- cheap isolate for text/file operations;
- structured module runtime for trusted code paths;
- container for heavyweight build and binary work.

The host can describe those backends to the model, set a default, and expose only the execution modes that fit the task. Files stay in one logical workspace instead of scattering across transient sandboxes.

## Implementation Notes

- Keep the host filesystem store authoritative.
- Give each backend a stable ID and a plain-language capability description.
- Serialize mutating sync operations per backend.
- Use a push/exec/pull bracket for runtimes with their own store.
- Let direct-call runtimes use host filesystem capabilities instead of copying state.
- Make command execution opt-in in agent tool sets.
- Provide readonly tool bundles for inspection-only agents.
- Treat backend selection as routing, not authorization; validate it server-side.
- Include lifecycle cleanup for execution handles, stubs, and retained logs.

## Best Fit

This pattern fits agent platforms that need durable files, short-lived execution, multiple runtime costs, and artifact publishing. It is less useful for large monorepo builds, raw high-throughput file processing, or applications that cannot depend on a platform-native durable object/runtime layer.

---

**Attribution:** cloudflare/computer, MIT, https://github.com/cloudflare/computer
