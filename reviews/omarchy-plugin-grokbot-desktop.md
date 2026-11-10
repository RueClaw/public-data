# Agent Desktop (tcballard/omarchy-plugin-grokbot-desktop)

**Repo:** https://github.com/tcballard/omarchy-plugin-grokbot-desktop
**Author:** Tom Ballard (tcballard)
**License:** MIT; retain copyright and permission notices. Bundled Inter fonts use SIL OFL 1.1; Open Bot Avatar has its own retained MIT notice.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** 94def6267026bad4257dcd9cd7b7d834fc1f5f35; main snapshot, manifest version 0.3.1; QML UI, Python providers/helpers, protocols, CI and lifecycle documentation.
**Verification:** Static source review; no repository tests or application executed. Public GitHub Actions reports success for this exact SHA. No installation, desktop interaction, accounts, provider calls or live compatibility probes.
**Stack:** QML/Qt Quick, Quickshell/Omarchy shell, Python 3, Hyprland/Wayland; Node.js for development checks.
**What it is:** A floating chat companion that connects existing agents to an Omarchy desktop—not a standalone model, a Grok subscription, or a general screen-operating agent.

---

## Verdict

⚠️ **Interesting — thoughtfully hardened desktop plumbing, but not a universal agent safety boundary.** The provider protocol, private stdin/IPC transport, deliberate cancellation semantics and geometry-only avatars are useful work. Try it only with a narrowly trusted agent setup on a disposable compatible desktop first: the current 0.3.1 Hermes experience and install/upgrade/removal acceptance remain explicitly pending, and ordinary chat inherits downstream agent authority rather than enforcing a tool sandbox.

## What It Is

The product is now **Agent Desktop**. The canonical repository still uses the Grokbot name; README says the rename is pending. The plugin ID and legacy configuration names deliberately remain stable. Roster sync imports appearance and identity from a locally signed-in Grok Bot cache; it does not connect replies. Actual replies require a configured webhook routine and return route, a local coding-agent CLI, or the experimental Hermes adapter. Local-agent mode speaks in the selected bot's name, not through that bot's actual cloud session. [README](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/README.md), [manifest](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/manifest.json).

The UI offers per-bot conversations/drafts, attachments, optional dictation, unread cues, cancellation, Markdown replies and custom avatars. Hermes adds streaming, history, approvals and questions on the standard backend. The opt-in daemon is a separate experimental path, not simply a more capable default. The latest public release observed was v0.3.0 (published 2026-11-10); reviewed main declares 0.3.1. README retains older status paragraphs, so pin a revision rather than conflating marketplace, release and main.

## Stack

| Layer | Technology and boundary |
|---|---|
| Desktop | Main.qml service inside omarchy-shell; Qt Quick Shapes and WlrLayershell |
| Dispatch | Python JSON-lines Provider API over private subprocess pipes |
| GrokBot | Per-ask worker; HTTPS webhook or installed CLI |
| Hermes | Installed Hermes Python environment, PyYAML, websockets and internal gateway modules |
| State | Standard backend QML memory; optional daemon Python memory; Hermes can import provider history |
| Integration | Hyprland cursor/socket events, optional evdev mouse input, wl-paste, file chooser and external dictation tools |
| Checks | Node 22, Python tests, Ruff, PySide6 offscreen rendering and syntax-only qmllint in CI |

## Key Features

### Useful provider separation, with substantial state complexity

Main.qml launches a compatibility client, which starts a provider process; GrokBot starts its transport worker, while Hermes attaches to existing Bot Chat sessions. Provider framing and request/session tracking separate presentation from adapters. The daemon ports conversation state to Python. This is maintainable in concept, but Main.qml is 4,012 lines and conversation behavior exists in both QML and Python, increasing parity and recovery testing needs. [Architecture](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/ARCHITECTURE.md), [protocol](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/agent_desktop/protocol.py), [state](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/agent_desktop/state.py).

### Better privacy transport, not a secret-proof execution environment

Prompts use stdin rather than command arguments. Webhook keys are refused when their files are symlinks, non-regular, oversized or group/world-readable/writable. Redirects are disabled; reserved header names and control characters are rejected. Helpers constrain output, deadlines and process cleanup. Private sockets check ownership/peer UID, and private reply/dictation paths fail rather than retrying via argv. These protect against common accidental exposure and other local users, not code running under the same UID. Error output can still put a secret on screen; the security document acknowledges this. The key reader uses lstat followed by open, not an atomic no-follow descriptor check, so it is not a same-user race defense. [Transport](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/agent_desktop/transport.py#L179-L442), [security](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/SECURITY.md).

### A genuinely more restricted avatar workflow

Avatar generation is separate from chat: describe, generate, preview, explicitly Apply. The helper uses an empty temporary working directory, bounded inputs/outputs and a 180-second timeout. Claude disables built-in tools/MCP/hooks; Grok uses an empty tool list and deny-all rule; Codex requests read-only operation with shell/image tools, apps, search, MCP and hooks disabled. The renderer consumes validated geometry JSON rather than model-written executable code. Actual CLI-version enforcement and provider behavior were not live-tested. [Generator](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/bin/agent-desktop-avatar), [renderer](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/qml/openbotavatar.js).

## Architecture and Security Boundaries

### Desktop capture, input and clipboard

This is a layer-shell chat UI, not a bundled screenshot-and-click computer-use loop. The reviewed runtime paths do not implement autonomous screen capture. The cursor helper reads Hyprland positions and optionally mouse event nodes, emitting left-button state and discarding other events. Access normally requires input-group membership; granting that group is much broader than the helper's current BTN_LEFT filter. Do not add broad raw-input access just for cosmetic cross-monitor dragging without accepting that system-wide consequence. Without it, dragging stops at the edge. [Cursor helper](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/bin/grokbot-cursor).

Clipboard image reads occur through attachment actions. Up to four regular files, 25 MiB each, are copied into a private runtime attachment directory with 0600 files; old copies are pruned and runtime storage normally clears at logout. This is staging, not an agent filesystem sandbox. Optional voice-watch can read recent backend transcript files and clipboard text during a short post-recording window, and matching wake phrases dispatch immediately. The wtype wrapper types nonmatching or failed-route text into the focused application; dictation backends retain their own privacy and focus risks. These are opt-in integrations, not always-on clipboard surveillance by the base companion. [Attachments](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/bin/grokbot-attach), [voice watcher](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/bin/grokbot-voice-watch), [router](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/bin/grokbot-dictation-route).

### Consequential actions and prompt injection

Ordinary agent chat uses commands such as codex exec --skip-git-repo-check or claude -p without the special avatar tool restrictions. HOME, selected credential variables and provider configuration remain available. A custom command is executable user configuration, not a declarative safe tool. No common plugin-level approval policy prevents filesystem edits, shell execution or network effects by every downstream agent. Attachments, dictated text, roster names and provider content must be considered untrusted input; model-facing persona instructions are not injection isolation. Restrict agent tools and workspace authority in the provider itself before using the companion for sensitive work. [Agent dispatch and environment](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/agent_desktop/transport.py#L574-L649).

Hermes offers real in-bubble approval responses with session/generation checks, advertised-choice validation and rejected-answer retention; unsupported prompts require Hermes itself. That is useful UI plumbing, not proof that every consequential tool call requires approval. Hermes authority comes from its existing Bot Chat session. Rendering escapes source markup, suppresses remote images and filters links to HTTPS or localhost HTTP; links still require a click. These controls reduce markup/executable-link risks but do not prevent persuasive malicious text or risky permitted links. [Hermes approvals](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/agent_desktop/hermes.py#L280-L303), [Markdown renderer](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/qml/markdown.js).

### Accounts, network, privacy and cost

The plugin does not establish a new universal account system. Grok roster import reads local app cache schemas; it is not an OAuth integration. Webhook setup prompts privately for a sender key and sends a test ask before saving. The URL is user-configured HTTPS (or localhost HTTP), not restricted to one vendor; HTTPS private-network destinations are not blocked. Treat the endpoint and proxy configuration as trusted destinations. The payload includes prompt, bot ID/name, host label, ask correlation and an absolute local return-helper path. These reveal more than just question text to the webhook operator. Redirect rejection prevents forwarding auth via a redirect but does not make a chosen endpoint safe. [Webhook body](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/agent_desktop/transport.py#L261-L289), [setup](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/bin/grokbot-connect).

Local coding agents may call remote models and retain their own logs/history. The outer ask environment forwards a set of provider credentials; transport narrows variables for built-in local-agent children but retains HOME access. Avatar generation explicitly resolves supported Omarchy account homes. Hermes imports installed runtime modules, obtains a session ticket and may ensure its gateway is running; its configured Python/source paths are trusted executable dependencies, not inert data. This review neither read nor used an actual account. [Environment](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/Main.qml#L2117-L2141), [Hermes runtime](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/agent_desktop/hermes.py#L77-L113), [gateway](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/agent_desktop/hermes_gateway.py#L328-L372).

The MIT plugin is free software, not free inference. Chat, webhook routines, optional voice backends and avatar generation can use metered or subscription services. No plugin-level monetary budget or token-spend cap was found in the inspected dispatch paths. Limits on time, prompt size and output bytes are not billing limits. Stopping a webhook ask stops local waiting; already-accepted remote work may continue and cost money.

## Persistence, Recovery and Lifecycle

Standard conversations/drafts are shell-session memory, not durable storage; imported Hermes history comes from an external persistent provider. The daemon also loses held conversations on exit, and repeated startup failures fall back to standard mode. Webhook replies correlate to pending asks, expire after ten minutes, and depend on an independently arranged return path; submitting successfully does not prove the response can reach the desktop. Hermes reconnects with backoff and reattaches after event gaps. None of these paths establish exactly-once remote side effects. [Architecture](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/ARCHITECTURE.md), [gateway reconnect](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/agent_desktop/hermes_gateway.py#L296-L372).

Installation is delegated to Omarchy's plugin manager; this repository does not provide an independent cross-platform installer. The documented add command follows the repository, so it is not a reproducible reviewed-SHA pin by itself. The UI merges its own settings through updateEntryInline. grokbot-connect preserves unrelated JSON fields and attempts rollback of settings/key writes when setup fails. That is configuration rollback, not rollback of the test request already sent to a remote bot. Provider settings use an atomic writer; optional Voxtype hook installation refuses an existing post-process configuration rather than blindly replacing it. [Connect implementation](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/bin/grokbot-connect), [provider writer](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/bin/agent-desktop-config), [voice integration](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/bin/grokbot-voice-watch).

The documented remove operation deletes the plugin checkout and shell entry, but deliberately leaves legacy configuration, roster and webhook secrets. Optional desktop-file copies, launcher helpers and user-added bindings need separate cleanup. Also audit the separate agent-desktop.json provider configuration and any opt-in dictation hook: removal documentation does not promise those are reverted. Runtime layer rules disappear on Hyprland reload. Back up relevant configuration and record the prior version before upgrades; there is no verified transactional upgrade/downgrade mechanism here. Retained settings aid recovery but retained credentials require conscious revocation/deletion when decommissioning.

## Compatibility and Maturity

Target: Omarchy 4/Quattro on Linux/Hyprland with its Quickshell types and shell APIs. Stable-shell IPC fallback exists, but private dictation requires newer ShellIpc support and a private runtime socket. The cursor helper specifically expects a /run/user/numeric-id runtime path. This is not a generic GNOME/KDE/X11, macOS or Windows desktop client. Layer rules, multi-output surfaces, clipboard/file chooser and voice integrations make platform-version testing essential.

At retrieval, GitHub metadata reported 27 stars, 8 forks and 4 open items (including pull requests), creation 2026-10-27 and last push 2026-11-10. This is a young, rapidly changing project; popularity is not safety evidence. Open PRs #36 and #37 propose OpenBot integration, not functionality established in this reviewed SHA. [Public repository metadata](https://api.github.com/repos/tcballard/omarchy-plugin-grokbot-desktop), [open work](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/pulls).

The test inventory is substantial: provider protocol, daemon state, cursor, dictation privacy, transport errors, connection rollback, roster sync, Markdown and native offscreen Qt tests. CI pins action SHAs and Python tool versions, uses read-only default permissions, and explicitly calls QML checking syntax-only because Omarchy/Quickshell types are absent. A separate release workflow checks an expected main SHA/version, runs tests and produces source manifests/SBOM and draft releases. These are useful safeguards, not a substitute for live compositor/provider testing. [CI](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/.github/workflows/ci.yml), [release workflow](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/.github/workflows/release.yml), [exact-SHA successful run](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/actions/runs/42774839054).

The 0.3.1 acceptance record is explicitly pending-live: real Hermes streaming/history/approvals plus install, upgrade, removal and daemon smoke checks remain pending. Its portable evidence names an earlier input SHA; the public Actions result separately confirms a successful run at the reviewed SHA. We inspected source and public metadata only, did not reproduce tests, and did not inspect every dependency or validate downstream providers' security. Historical screenshots/owner acceptance are source claims, not independent current-version proof. [Acceptance record](https://github.com/tcballard/omarchy-plugin-grokbot-desktop/blob/94def6267026bad4257dcd9cd7b7d834fc1f5f35/docs/ACCEPTANCE-v0.3.1.json).

## Comparison

| Option | Prefer it when | Tradeoff |
|---|---|---|
| Agent Desktop | Multiple bot identities, floating replies and custom avatars matter | More desktop state, integration and permission boundaries |
| Existing agent CLI or provider desktop UI | You need its native approvals, history, diagnostics and account controls | Less ambient desktop presence; no unified companion |
| [Clippy for Omarchy](https://github.com/jankeesvw/omarchy-clippy) / [Clanky](https://github.com/rdoupe/omarchy-clanky) | You primarily want the companion interaction pattern | Cited inspirations, not assumed provider-feature equivalents |
| [Hermes Blob](https://github.com/Yani3rt/omarchy-plugin-hermes-blob) | You want to study the Hermes-specific bridge lineage | Separate integration to evaluate; no safety equivalence claimed |

## Self-Hosting Notes

Use an existing trusted compatible Omarchy environment and already-installed agents; this is not a model server. Prefer the standard backend until daemon acceptance is demonstrated. Start with manual prompts, no raw-input group expansion and no global wake router. Verify chat tool restrictions, callback delivery, cancellation behavior and account selection with nonsensitive disposable data. Keep webhook secrets private, understand the destination's retention/cost policy, and do not treat local UI history clearing as provider-data deletion. Live validation and provider setup were deliberately not performed for this review.

---

**Attribution:** Tom Ballard / tcballard/omarchy-plugin-grokbot-desktop, MIT. Open Bot Avatar: Dominik Scholz, retained MIT notice; Inter: SIL OFL 1.1. Credits distinguish original code, measured Grok Bot shapes and third-party media; do not assume the repository MIT grant transfers rights to every depicted brand or wallpaper. No source assets or code were republished here.
