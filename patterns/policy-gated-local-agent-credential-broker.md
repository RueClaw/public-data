# Policy-Gated Local Agent Credential Broker

**Source:** https://github.com/asimons81/hermes-vault
**License:** MIT
**Reviewed:** 2026-05-24
**Category:** Credential handling, agent security, local-first infrastructure

---

## Pattern

Put a local credential broker between agents and secrets. The broker owns policy decisions, verification, audit records, TTL-limited environment materialization, and raw-secret restrictions. Agents should not discover credentials by searching dotfiles, scraping shell history, or asking for re-authentication before the credential state has been verified.

The important split is:

- **Vault:** encrypted local persistence and credential metadata.
- **Policy engine:** normalized agent/service/action capabilities and TTL ceilings.
- **Broker:** the only path from agent request to usable credential material.
- **Verifier:** provider-specific checks before declaring a credential invalid.
- **Operator surfaces:** CLI, MCP, and dashboard responses that avoid raw secret display unless policy explicitly permits it.

## Why It Matters

Agent systems often fail at the credential boundary. They either overreach by reading arbitrary local files, or they underreach by claiming a missing/invalid credential and asking a human to re-authenticate. A broker makes that boundary explicit.

A useful broker can answer:

- Which services can this agent list?
- Can this agent read metadata for this credential?
- Can this agent get short-lived env vars?
- Can this agent verify or rotate the credential?
- Is raw secret access ever permitted?
- Was this decision audited?
- Is a re-auth recommendation based on verification rather than guesswork?

## Implementation Notes

Use service/action policy rather than a flat allowlist. A single service grant should not automatically imply list, env materialization, verify, rotate, import, and raw-read rights.

Prefer ephemeral env materialization as the default operational path. The calling tool gets a bounded environment mapping for a short TTL; it does not get a general-purpose secret export unless policy explicitly allows it.

Keep metadata paths safe. MCP resources, dashboards, and inventory commands should return service names, aliases, status, expiry, tags, notes, verification state, and policy findings, not encrypted payloads or token responses.

Treat OAuth refresh as a rotation-like mutation. It should require explicit action permission, audit records, and sanitized metadata.

## Adaptation Checklist

- Define stable agent identities and do not rely on caller-supplied identity when a host can be bound at launch.
- Store secrets encrypted at rest, but do not treat encryption as sufficient; enforce policy at use time.
- Make dry-runs available for import, maintenance, backup verification, restore, and OAuth refresh.
- Redact logs, exceptions, reports, UI responses, and screenshots.
- Add tests that assert raw token values do not appear in failure messages.
- Warn when a tool is pointed at temporary/demo runtime state while a populated default vault exists.

## Caveats

This pattern is local-first. For multi-user or remote production environments, add identity federation, server-side audit retention, network boundary controls, backup policy, and administrative recovery workflows.

Also watch filesystem portability. Repositories that contain path names differing only by case can break or degrade on default macOS and Windows filesystems.

---

**Attribution:** asimons81/hermes-vault, MIT
