# openclaw-simplex Review

**Repo:** https://github.com/dangoldbj/openclaw-simplex  
**License:** MIT  
**Author:** Bijaya Dangol (@dangoldbj)  
**Language:** TypeScript  
**Version:** 0.1.1 (2026-03-02)  
**Cloned:** ~/src/openclaw-simplex  
**Rating:** 🔥🔥🔥🔥

---

## What It Is

A production-quality **OpenClaw channel plugin** that adds [SimpleX Chat](https://simplex.chat/) as a message channel. SimpleX is a privacy-first, end-to-end encrypted messenger with no phone number requirement and a self-hostable server option — notable because it has no user identifiers at all (not even usernames in the traditional sense), only pairwise connection links.

The plugin connects OpenClaw to a local `simplex-chat` CLI binary via its WebSocket API, normalizes inbound events into OpenClaw message context, and routes outbound actions back through SimpleX.

---

## Why SimpleX Matters

Standard OpenClaw channels (Discord, Slack, Telegram, WhatsApp) all have centralized identity infrastructure you don't control. SimpleX has:

- No phone number requirement
- No username-based identity — connections are pairwise link-based
- E2E encrypted by default, including metadata
- Self-hostable relay servers (your traffic doesn't have to touch SimpleX's infrastructure)
- Official CLI with a WebSocket API that's stable enough to build on

For anyone with a threat model that includes metadata surveillance, or who simply wants a channel not dependent on a third-party's bot API, this is meaningful.

---

## Architecture

```text
OpenClaw ← channel plugin API → @dangoldbj/openclaw-simplex ← WebSocket → simplex-chat CLI ← SimpleX network
```

**Managed mode:** plugin spawns and manages the `simplex-chat` process. OpenClaw installs may warn about `child_process` usage — expected, documented, not a bug.

**External mode:** you run `simplex-chat` separately, plugin connects to `wsUrl`. Useful for shared instances, Docker deployments, or if you want finer process control.

The plugin follows the standard OpenClaw channel plugin shape (`openclaw.plugin.json` manifest, `buildChannelConfigSchema` from the plugin SDK, channel registration via the `openclaw` field in `package.json`).

---

## Feature Coverage

- Send/receive text and media
- DM pairing + allowlist enforcement (`dmPolicy: "pairing"` default — explicit approval required for new senders)
- Group support with `groupPolicy` (open / disabled / allowlist)
- Message actions: send, reply, reaction, edit, delete, group operations
- Invite link generation + QR code output
- `simplex.invite.create` / `.list` / `.revoke` gateway methods
- Per-account config + multi-account support
- Managed and external connection modes
- Control UI integration (channel card, invite flow, screenshots in docs)

---

## Code Quality

**~4600 lines of TypeScript**, well-structured:

- `config-schema.ts` — Zod v4 schemas for all config, using OpenClaw plugin SDK types (`DmPolicySchema`, `ToolPolicySchema`, `buildChannelConfigSchema`, etc.). Strict schemas throughout.
- `simplex-security.ts` — allowlist parsing with explicit prefix normalization (`simplex:`, `group:`, `contact:`, `user:`, `member:`, `@`, `#`). Clean, explicit, not magic.
- `simplex-ws-client.ts` — WebSocket client (237 lines), has its own test file.
- `simplex-commands.ts` + `simplex-commands.test.ts` — command construction, tested.
- `accounts.ts` + `accounts.test.ts`, `simplex-security.test.ts` — multiple test files.

Tests use Vitest. `prepublishOnly` enforces test + typecheck + build before any npm publish. The publish provenance flag is set (`publishConfig.provenance: true`) — npm attestation on release.

Biome for formatting and linting. Node >=22 required. Peer dependency on `openclaw >=2026.2.1`.

---

## Security Model

Default `dmPolicy` is `"pairing"` — new senders must be explicitly approved before OpenClaw processes their messages. This is the right default for a privacy-focused channel; `allowFrom: ["*"]` is opt-in open mode.

The allowlist parser (`simplex-security.ts`) handles multiple prefix formats defensively — trimming, lowercasing, stripping `simplex:` prefixes before comparison. No silent acceptance of malformed entries.

---

## Gaps / Notes

**v0.1.1 — still early.** The changelog is two entries (initial release + publish workflow fix). Production battle-testing is limited.

**SimpleX CLI dependency.** `simplex-chat` is an external binary with its own release cadence. Breaking API changes in the CLI would require plugin updates. The README provides the official installer and an arch-matrix fallback installer for Darwin/Linux target detection issues — suggests this has already been a pain point.

**No streaming block coalescing config shown in tests.** The schema supports `blockStreamingCoalesce` (inherited from OpenClaw plugin SDK) but it's not exercised in the test suite.

**Docs are real.** Full VitePress docs site at dangoldbj.github.io/openclaw-simplex with getting-started walkthrough and screenshots. This isn't a readme-and-nothing-else project.

---

## Relevance

**For us directly:** This is a working reference implementation of an OpenClaw channel plugin — the config schema patterns, the WebSocket client structure, the security/allowlist model, and the managed vs. external runtime split are all patterns we could reference if we ever built a custom channel (or adapted an existing unofficial one).

**For Marcos:** SimpleX as a channel has appeal — no phone number, E2E encrypted, no dependency on Meta/Google infrastructure. If the Marcos agent needs a private communication channel that isn't tied to a third party's API policies, this is the cleanest option available. Setup friction is higher than WhatsApp, but the privacy properties are better.

**For Jon / OpenClaw general use:** If you want a private channel for sensitive conversations with me that doesn't route through Discord, Telegram, or iMessage, this is the one. Install is ~10 minutes: `simplex-chat` binary + `openclaw plugins install @dangoldbj/openclaw-simplex` + pair via QR.

---

## Verdict

Solid community contribution to the OpenClaw plugin ecosystem. TypeScript, tested, provenance-published, full docs. The managed/external split is the right architecture decision. Default `dmPolicy: "pairing"` shows security-first thinking.

LarryBrain has 10K+ users on the third-party OpenClaw skills/plugin scene — this is evidence the ecosystem is real and producing quality work. Not every plugin in it will be this clean, but this one is.

---

*Source: https://github.com/dangoldbj/openclaw-simplex | License: MIT | Author: Bijaya Dangol (@dangoldbj) | Reviewed: 2026-03-22*
