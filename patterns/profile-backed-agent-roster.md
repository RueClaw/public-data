# Profile-Backed Agent Roster

**Source:** NousResearch/Hermes-Bot-Mode
**Repo:** https://github.com/NousResearch/Hermes-Bot-Mode
**License:** MIT
**Reviewed:** 2026-08-15

## Pattern

Represent "bots" or named teammates as UI projections over an existing agent-profile system, rather than creating a parallel bot runtime.

```text
agent profile = identity, memory, skills, credentials, model config
roster row    = display title, avatar, preview, activity, actions
canonical chat = pinned session id stored in profile/plugin metadata
routine       = scheduler job scoped to the profile and tagged by bot name
handoff       = normal CLI/RPC message into the target profile's canonical chat
```

## Why It Matters

Multi-agent interfaces often go wrong by inventing a second identity layer. The UI creates "bots," but the underlying runtime still thinks in users, sessions, tools, and credentials. That produces drift: settings live in one place, chats in another, scheduled jobs in another, and handoffs become hard to audit.

A profile-backed roster keeps one authority. The profile owns durable capability and history; the roster makes those profiles usable as named teammates.

## Core Pieces

- **Profile as identity:** every bot maps one-to-one to an existing profile/account/runtime identity.
- **Metadata overlay:** display name, avatar, pet, and pinned chat are presentation data, not a separate capability record.
- **Canonical chat pin:** opening a bot resumes one stored relationship chat instead of selecting the latest session by recency.
- **Scoped scheduler:** recurring jobs run under the bot profile, with a readable namespace tag as fallback and audit clue.
- **Agent-readable handoff protocol:** bot-to-bot messages use ordinary runtime commands plus explicit attribution.
- **Feature detection:** desktop, CLI, and gateway builds may not ship together, so advanced RPCs must be probed and degraded.

## Safety Notes

Do not let the roster hide authority boundaries. A profile may have credentials, skills, tools, and memory that another profile does not. Creation, duplication, deletion, model pinning, MCP setup, and routine scheduling should use the same confirmation and permission expectations as the underlying profile system.

If a handoff is implemented as a CLI command, quote arguments structurally and keep message text out of shell interpolation. If the recipient chat is missing, recover through an explicit create/rename path rather than silently opening a random recent session.

## Good Fit

- Local desktop agent apps with existing profile/session primitives.
- Single-operator multi-agent workspaces.
- Agent systems where named assistants need persistent memory and scheduled work.
- Plugin architectures where new UI should avoid core patches.

## Poor Fit

- Hosted multi-tenant systems without profile-level auth and isolation.
- Ephemeral chat tools where identity and history are intentionally disposable.
- Systems where bot-to-bot messaging needs real-time interrupts, delivery receipts, or durable queues.

---

**Attribution:** Pattern extracted from NousResearch/Hermes-Bot-Mode, MIT, https://github.com/NousResearch/Hermes-Bot-Mode
