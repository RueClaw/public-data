# Per-Method Versioned RPC Compatibility

**Source:** traycerai/traycer  
**Repo:** https://github.com/traycerai/traycer  
**License:** Apache-2.0  
**Reviewed:** 2026-07-04  

## Pattern

When a desktop client, CLI, and local host ship independently, treat the RPC boundary as a negotiated product contract instead of a shared implementation detail.

Define each RPC method with its own `{ major, minor }` schema version. Minor versions must be additive within a major line. Major versions represent breaking changes. The newer side owns compatibility work by walking explicit upgrade paths within a major line or explicit downgrade bridges across major lines.

## Why It Works

Most local-agent apps either assume all components are upgraded together or fail with vague daemon/client mismatch errors. Traycer's design lets the client and host exchange a manifest during WebSocket session setup, check every method for compatibility, choose the on-wire schema version for a specific call, and transform request/response payloads at the boundary.

That is heavier than a single `apiVersion` integer, but it localizes drift. One method can evolve without forcing every other method into a new global protocol version.

## Implementation Shape

- Put schema contracts in a shared protocol package.
- Store each method as a registry of major lines and minor versions.
- Validate invariants at registry creation:
  - `latestMinor` is installed and is the highest minor in the line.
  - contract method/version fields match the registry key.
  - each non-initial version has an upgrade path from the previous installed version.
  - cross-major downgrades originate from the latest source major and target older majors.
  - minor changes are additive; breaking schema changes require a major.
- During connection setup, exchange method manifests.
- For each call, compute the on-wire version from the caller and host canonical versions.
- Transform requests and responses at the transport layer, not inside application handlers.
- Return structured incompatibility errors with per-method details and upgrade guidance.

## Good Fit

Use this for:

- Desktop app plus local daemon/host architectures.
- Agent workspaces where a GUI, CLI, and background runtime update separately.
- Local-first apps that need graceful compatibility across app auto-updates.
- WebSocket or stream RPC systems where schema drift should fail early and specifically.

Avoid it for small single-process tools. The ceremony only pays for itself once independent release cadence is real.

## Source Pointers

- `protocol/src/framework/versioned-rpc.ts` — registry helpers and validation rules.
- `protocol/src/framework/compatibility-checker.ts` — manifest compatibility oracle.
- `clients/shared/host-transport/ws-rpc-client.ts` — client-side negotiation and on-wire transform flow.
- `protocol/src/host/agent/gui/contracts.ts` — example method evolution with v2 to v1 downgrade behavior.

---

**Attribution:** traycerai/traycer, Apache-2.0
