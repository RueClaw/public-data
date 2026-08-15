# Hermes Bot Mode (NousResearch/Hermes-Bot-Mode)

**Repo:** https://github.com/NousResearch/Hermes-Bot-Mode
**License:** MIT; permissive reuse with attribution and license preservation
**Reviewed:** 2026-08-15
**Stack:** Hermes desktop plugin SDK, JavaScript/React, Hermes gateway RPCs, Hermes profiles, sessions, cron, CLI handoffs
**What it is:** A Hermes desktop plugin that turns existing Hermes profiles into a roster of named agents with their own chats, avatars, routines, profile settings, and bot-to-bot messaging protocol.

---

## Verdict

✅ **Deploy candidate for active Hermes desktop users.** Hermes Bot Mode is not a separate agent runtime; it is a thin but thoughtful product layer over Hermes profiles, sessions, cron, and CLI handoffs. The design is good because it reuses the host's identity and storage primitives instead of inventing a parallel bot database, and the current source-level test suite passed locally. The main caveat is runtime coupling: it needs a recent Hermes desktop/gateway build, and parts of the README have drifted from the implementation around the canonical handoff chat name.

---

## What It Is

Hermes Bot Mode adds a Bots pane to Hermes Desktop. Each row represents a Hermes profile, rendered as a named bot with display metadata, avatar/pet styling, latest-session preview, unread/activity hints, context menu actions, and a canonical chat.

The plugin's strongest move is treating "bot" as presentation, not infrastructure. A bot is still a normal profile under `~/.hermes/profiles/<name>/`, with its own memory, skills, credentials, model settings, and chat history. Creation and editing ride `profiles.*` gateway RPCs; scheduled work rides Hermes cron; chat navigation rides sessions; bot-to-bot delivery rides normal `hermes -p <profile> chat ...` CLI commands.

This makes it a good fit for a single operator who wants multiple persistent local agents without maintaining a separate orchestrator. It is less useful outside Hermes Desktop, and it should not be mistaken for a hosted multi-user agent platform.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Hermes desktop plugin, single `plugin.js` |
| UI | React hooks/components from `@hermes/plugin-sdk` |
| Identity | Hermes profiles via `profiles.list`, `profiles.create`, `profiles.describe`, `profiles.configure` |
| Sessions | `session.create`, `session.list`, `session.set_hidden`, `host.openSession` |
| Scheduling | Hermes cron via `cron.manage`, namespaced job names |
| Media | Local SVG/geometric avatars, uploaded images, `profiles.set_asset`, optional `image.generate` |
| Handoffs | Composer middleware plus CLI instructions into canonical bot chats |
| Tests | Node `--test` source/regression tests, no package manifest |

## Key Features

### Profile-Backed Agent Roster

The roster polls `profiles.list`, then overlays local/server UI metadata such as display title, avatar, pet, and pinned canonical chat. That is the right boundary: Hermes remains the source of truth for agent identity and capability, while the plugin owns only presentation and workflow affordances.

### Canonical Bot Chat

Each bot gets one persistent "Bot Chat" pinned in metadata. Opening a bot goes to that stored session rather than whichever session happened to be most recent. The code handles first open, double-click creation races, missing/stale pins, hidden session preference, and recovery when the stored row vanishes.

That solves a common multi-agent UX failure: a named assistant should feel like a continuing relationship, not like an accidental scratchpad chosen by recency.

### Advanced Profile Editing

The New Agent and Edit Profile flows expose profile-level configuration without leaving the Bots pane: clone from an existing profile, custom SOUL.md, skill/toolset controls, MCP setup, model pinning, inherit/clear behavior, avatar assets, and safe delete/duplicate flows.

The plugin feature-detects newer lifecycle/RPC surfaces and keeps fallbacks for older gateways, which is exactly what desktop plugin code needs when the app, gateway, and CLI can ship independently.

### Scoped Routines

The Routines pane stores jobs as `[bot:<name>] <routine>` and forwards `{ profile }` to `cron.manage` where supported. Older gateways that ignore the profile scope still have a tag-based fallback. The code also pauses older delegated routine prompts that match a legacy unsafe wrapper before allowing them to run again.

### Bot-To-Bot Messaging Protocol

Bot creation injects a reusable "Messaging other agents" protocol into the bot's SOUL.md, including the canonical CLI handoff command and attribution prefix. Composer middleware recognizes `@bot` mentions in prose, ignores code blocks, validates names against the live roster, and appends a handoff instruction for the active agent to dispatch.

This is not live interrupt delivery. It is a structured, agent-readable handoff convention over ordinary Hermes commands, which is a reasonable first version.

## Architecture

The project is deliberately small:

- `plugin.js` contains the full plugin.
- `README.md` documents install, behavior, screenshots, and requirements.
- `tests/*.test.mjs` are Node source/regression tests that parse `plugin.js` and assert important behaviors.

The implementation relies on three durable anchors:

1. Hermes profiles are the identity and capability boundary.
2. Canonical chat pins in metadata are the relationship boundary.
3. Cron profile scope plus `[bot:]` job names are the scheduled-work boundary.

That is a cleaner shape than a separate local database. It means bot state follows Hermes primitives and degrades with them rather than creating a second source of truth.

The main documentation drift found during review: README text says bot-to-bot messages use a persistent "Agent Inbox" and shows `hermes -p <bot> chat -c "Agent Inbox" -q "..."`, while the current implementation and top-of-file comments use canonical "Bot Chat" with `--in ~ -c "Bot Chat"` and `-Q`. Operators should trust the implementation or check the current README before relying on old commands.

## Comparison

| Aspect | Hermes Bot Mode | Awesome Hermes Agent | Hermes Agent Control Room |
|--------|-----------------|----------------------|---------------------------|
| Primary shape | Desktop plugin over live Hermes profiles | Ecosystem catalog | Ops template/control-room docs |
| Runtime | Hermes Desktop + gateway RPCs | None | Optional scripts/templates |
| Best use | Daily local multi-agent UX | Discovery and landscape mapping | Day-two operations and runbooks |
| Strongest pattern | Profile-backed roster with canonical chats | Categorized ecosystem map | Sidecar governance/control room |
| Main caveat | Coupled to recent Hermes desktop/gateway surfaces | Editorial, not verified | Root-centric bootstrap, not app UX |

## Self-Hosting Notes

Install it where Hermes Desktop runs, not on a remote gateway host:

```bash
git clone https://github.com/NousResearch/Hermes-Bot-Mode ~/.hermes/desktop-plugins/hermes-bots
```

Then reload desktop plugins or restart the app. A recent Hermes build is expected for the richer `profiles.*`, `image.generate`, profile-scoped cron, profile assets, and hidden-session surfaces. The plugin has graceful fallbacks, but the full experience depends on those RPCs.

Local verification on 2026-08-15:

```bash
node --test /tmp/hermes-bot-mode/tests/*.test.mjs
```

Result: `61 passed`.

---

**Attribution:** NousResearch/Hermes-Bot-Mode, MIT, https://github.com/NousResearch/Hermes-Bot-Mode
