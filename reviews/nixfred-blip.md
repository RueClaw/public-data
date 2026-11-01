# Blip (nixfred/blip)

**Repo:** https://github.com/nixfred/blip
**License:** MIT, copyright Fred Nix; retain notices when reusing code. Vendored development tooling has its own MIT notice.
**Reviewed:** 2026-11-01 (UTC)
**Revision:** `045582e896b64109005a1b01e84832d3fd87715e`, whole repository with emphasis on client, bridge, installer and privacy boundaries. Manifest version 2.6.2; reviewed main is newer than the September release.
**Verification:** Static source and public metadata review only. No installation, tests, desktop sessions, sends, private databases, or user data accessed. No runtime security exploit or performance benchmark performed.
**Stack:** QML/Quickshell, TypeScript/Bun, Python, Bash, OpenSSH, macOS Messages/AppleScript/Accessibility, read-only SQLite.
**What it is:** An Omarchy-native iMessage client whose transport and account authority remain on a Mac you own. This is nixfred's messaging bridge, not the BLIP vision-language model or another same-named application.

---

## Verdict

⚠️ **Interesting — a credible specialist client, with consequential trust and retention tradeoffs.** The SSH confinement, read-state reconciliation and explicit synthetic tests are stronger than a simple AppleScript wrapper. Pilot it only if you already operate an always-available Mac and accept the permission footprint; disable automatic link previews for sensitive use, preserve sent-media originals, and validate your exact macOS/Omarchy combination before relying on it.

## What It Is

Blip integrates a bar badge, popout and separate Messages-style window into Omarchy. The Mac reads its Messages database and performs sends through Messages.app; Linux renders conversations and invokes bridge tools over SSH. It does not implement Apple's protocol, replace the Apple account, or work without the Mac. SMS/RCS depend on the Apple-side forwarding/account setup.

Conversation search, rich attachments, group identities, contact review/export/creation, notification allowlists and optional OTP autofill are substantive features. Edit/unsend, native threaded-reply sending and typing indicators are not supplied. Experimental tapbacks have narrower text/DM and OS-version limitations. The README's screenshots use fictional fixtures, a useful privacy-conscious documentation technique. [README](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/README.md)

## Stack

| Layer | Technology and boundary |
|---|---|
| Desktop | Quickshell/QML within Omarchy/Hyprland, not a portable web or generic Linux application |
| Client logic | Bun TypeScript helpers; collector builds the thread/unread model, thread loader decorates bubbles |
| Transport | OpenSSH multiplexing; dedicated restricted key; optional local Python Unix-socket accelerator |
| Mac reader | Python SQLite connections with mode=ro; Messages and Contacts data stay authoritative on Mac |
| Actions | AppleScript and optional Accessibility; native address-book helper for new contacts |
| State | Private JSON metadata, media/avatar/link caches, runtime contact exports and drafts |
| Dependencies | OS tools rather than a conventional npm application: Bun, jq, SSH, libnotify, clipboard/open helpers; optional socat, zenity, Hunspell, media tools and accessibility packages |

## Key Features

### Metadata-only unread reconciliation

The collector separates the seen watermark from read marks and persists an unread ledger rather than relying on a moving recent-message window. Read intentions are retained and reconciled against Mac state; newer inbound activity can invalidate an old retry. This is a meaningful correctness design, not just a cosmetic badge. Groups are addressed by their actual chat GUID instead of the most recent speaker. [collector.ts](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/collector.ts), [read-sync.ts](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/read-sync.ts), [thread.ts](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/thread.ts)

### Restricted transport, not a restricted account

The Mac forced-command dispatcher shlex-splits requests and execs only named tools, without an arbitrary shell. The dedicated key uses its own ControlMaster socket and disables agent identity substitution. The optional accelerator has owner/mode checks, same-UID peer credentials, bounded queues and deadlines; its Mac serve channel allowlists read-only commands and failures fall back to one-shot SSH. These are concrete, inspectable controls. [dispatcher](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/bridge/mac/blip-dispatch), [shim](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/bridge/linux/blip-shim), [daemon](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/bridge/linux/blip-bridged), [reader](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/bridge/mac/imsg)

### Deliberate exports and action verification

Attachment saving pins destination directory descriptors, uses exclusive staging and hard-link publication, and numbers collisions rather than overwriting files. Contact creation is distinct from contact review; source documentation describes duplicate checking and native API readback rather than direct database editing. Read/tapback actions distinguish a click from verified state. These controls reduce common data-loss and false-success problems without proving every platform interaction works. [save-attachment.ts](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/save-attachment.ts), [contact-save](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/bridge/mac/contact-save), [imsg-read](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/bridge/mac/imsg-read)

## Architecture

BarWidget owns refresh/watch behavior and the shared model; BlipView and window/panel components display it. TypeScript helpers handle collection, search, send state, media fetching and display transformation. Mac helpers remain separately executable behind the forced-command entry point. The persistent bridge is an optimization, not a new cloud service: two pooled SSH channels amortize Python and database startup while binary attachments and mutations keep separate paths.

This separation supports pure logic tests and mocked transport tests. It also creates a large compatibility surface across QML, Bun, Python, shells, Apple database schemas and localized UI automation. The 2,672-line collector and 2,800-line-class Mac reader are substantial modules, not a tiny glue script. The vendored bridge records its upstream origin and Blip-specific deviations in [BRIDGE-VERSION](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/bridge/BRIDGE-VERSION).

## Security, Privacy and Execution Boundaries

- **The Mac and Linux user account are trusted.** Full Disk Access is granted to sshd-keygen-wrapper, not exclusively to the Blip key. Other shell-capable keys on that account inherit broad access. The restricted key still intentionally reads messages and invokes send/contact actions. The client automation switch is not a defense against another process running as the same user. If the dedicated key is absent, the shim falls back to ordinary SSH authority; verify confinement, do not assume it. [SECURITY](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/docs/SECURITY.md), [shim](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/bridge/linux/blip-shim)
- **No hosted Blip relay does not mean no outbound web requests.** Automatic link cards default on, directly contacting linked sites from Linux when conversations are opened. The implementation accepts HTTP as well as HTTPS, sends no configured cookies, executes no page JavaScript, limits redirects/body sizes, and rejects many private addresses. However, safeUrl resolves a hostname separately from fetch(current): the validated IP is not pinned to the connection. That leaves a DNS-rebinding/validation-to-use gap in the intended SSRF defense. This is a static design finding, not a reproduced exploit. Use link_previews=off or an enforceable public-only egress boundary. [linkpreview.ts](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/linkpreview.ts)
- **Message-body minimization is useful, not zero sensitive storage.** Normal send bodies use stdin and state snapshots retain metadata rather than text. Attachments, preview titles/descriptions, contacts summaries and explicit exports remain sensitive; the notification daemon may retain previews. A clicked URL reaches the browser, and allowlisted toast previews can appear in process arguments. The absolute README slogan that text never touches argv/disk needs these qualifications. [PRIVACY](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/docs/PRIVACY.md)
- **Optional automation adds real powers.** Read pushes can emit read receipts and select a Mac conversation; tapbacks use Accessibility; OTP autofill injects into a focused field. Origin checks and single-use/deadline logic help, but application-supplied accessibility labels are not authentication. Enable features individually and test with synthetic/non-sensitive inputs. An unlocked gateway and auto-login guidance also have physical-security costs; retaining disk encryption and accepting manual unlock is a legitimate safer tradeoff. [OTP policy](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/otp-policy.ts), [desktop adapter](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/otp-desktop.py)
- **The advertised audit is project-reported.** docs/SECURITY.md describes a Codex audit and later multi-lens reviews. The fixes are useful evidence, but neither token counts nor an audit label establish independent assurance of the current revision.

## Data Preservation and Installation

Read-only SQLite avoids directly corrupting Messages history, and muting/filtering in the client is not deletion. Nevertheless, Blip is not a backup. Mac file sending deliberately retains staging files because Messages may leave attachment records pointing at them. keep_sent limits that store to 200 MiB and removes older directories; its failure fallback deletes staging. Consequently older sent media that depends on that retained copy can become unavailable. The README's uninstall instruction to remove the entire Mac Blip directory also removes this retained media. Export important originals and inspect dependencies before cleanup; “never writes chat.db” is not equivalent to “cannot lose attachment availability.” [imsg-send, keep_sent/gc_outbox](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/bridge/mac/imsg-send), [README removal section](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/README.md)

The setup script preserves non-owned configuration keys, appends an SSH block rather than replacing the whole file, and backs up displaced non-shim executables. It still mutates SSH authorization, installs helpers on both hosts and rewrites owned config values. Its config write is direct rather than a transactional rollback system. Review a pinned revision and back up relevant configuration first. Plugin installation follows main; updating Linux alone does not necessarily refresh the Mac helpers. No installer was run for this review. [blip-setup](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/scripts/blip-setup)

## Tests, Claims and Maturity

The committed Ubuntu CI runs Bun tests, synthetic QML badge checks, Python syntax checks, numerous bridge regression suites, and shellcheck. Tests explicitly cover read verification, scheduling, attachment MIME, conversation clustering, socket trust, deadlines, quoting and contact creation. This is meaningful breadth. It is not a macOS integration matrix: real TCC grants, AppleScript behavior, Accessibility focus and Messages delivery still need live qualification. Bun is selected as latest and actions are version-tagged rather than immutable SHA-pinned. No tests or dependency audit were run here. [CI](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/.github/workflows/ci.yml)

The Bun preload redirects XDG cache/config directories but does not replace HOME, while some helpers compute paths directly from HOME. That preload alone is not a secret-free sandbox. Future tests should run with an isolated home, no host credentials and no real SSH/desktop endpoints. [test-setup.ts](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/test-setup.ts), [collector.ts](https://github.com/nixfred/blip/blob/045582e896b64109005a1b01e84832d3fd87715e/collector.ts)

Public API snapshot on 2026-11-01: created 2026-08-31, last push 2026-10-31, 186 stars, 44 forks and 5 open items in GitHub's combined issues counter. Latest listed release was v2.6.2 on 2026-09-26, with no uploaded binary assets. These indicate an active young project, not reliability proof. Open issue #132 documents macOS 27 pin/mute breakage; the reviewed commit specifically fixes mute state/toggle handling, so the issue should not be treated as proof that all reported behavior still fails. [metadata](https://api.github.com/repos/nixfred/blip), [release](https://github.com/nixfred/blip/releases/tag/v2.6.2), [issue](https://github.com/nixfred/blip/issues/132)

README claims such as approximately two-second push, warm SSH timings and 312 passing tests were not reproduced. Documentation lags in places: pinned conversations are described as read-only while newer action helpers include pin operations, and contact-scan/cache bounds differ between older and appended privacy sections. Prefer implementation and revision-specific tests to headline claims.

## Comparison

| Option | Best fit | Tradeoff |
|---|---|---|
| Blip | Omarchy desktop with an existing Mac and SSH operations experience | Native integration, no Blip cloud relay; narrow desktop stack and Apple UI/schema coupling |
| BlueBubbles | Broader messaging-client ecosystem and server-oriented deployment | Evaluate basic versus private-API modes separately; Blip's blanket “wants SIP off” comparison is too broad to adopt without qualification |
| AirMessage web | Browser-based access rather than an Omarchy widget | Its public README describes a WebSocket proxy and Firebase/Sentry configuration; a different service and trust model |
| Apple Messages on the Mac/iPhone | Maximum first-party compatibility | Requires using the Apple device rather than a native Linux workflow |

Alternative references: [BlueBubbles server docs](https://docs.bluebubbles.app/server/), [AirMessage web source](https://github.com/airmessage/airmessage-web). Alternatives were not installed or comprehensively audited. AirMessage's main website failed certificate validation during this review; its public source README was accessible.

## Self-Hosting Notes

This is a two-device personal client, not a multi-tenant web service. Documented baseline is macOS 13+ with a logged-in Messages session, SSH and one-time permissions, plus Omarchy/Hyprland and the listed Linux tools. Sleep, logout, screen lock, TCC changes and macOS upgrades affect different features differently. Do not solve every failure by weakening system protections. Restrict SSH reachability, inventory other account keys, keep the dedicated key confined, start with previews and optional automation disabled, and confirm intended recipients and delivery/read outcomes on your own test account before normal use.

## Verification Limits

Public HTTPS source acquisition and exact commit identity were verified; the prior public reviews/index were searched and no matching review found. Source analysis and artifact validation were performed; application execution, test results, performance, endpoint isolation, GUI rendering, send reliability and backup/restore behavior are unverified. This review is not an exhaustive vulnerability assessment or a promise of Apple-platform compatibility.

---

**Attribution:** [nixfred/blip](https://github.com/nixfred/blip), Fred Nix and contributors, MIT. Analysis only; no source code extracted.
