# hypr-computer (malik-na/hypr-computer)

**Repo:** https://github.com/malik-na/hypr-computer
**Author:** Naeem Malik (malik-na)
**License:** MIT; retain copyright and permission notice when redistributing substantial portions. External tools retain their own licenses.
**Reviewed:** 2026-11-22 (UTC)
**Revision:** `ac29d4702ffdb52e8496d6c4b97bb4f1ce6e6d5d` (main); entire tracked source tree, especially server, installers, plugin manifests and tests. Plugin manifest version 0.3.0; no public releases or tags returned at retrieval.
**Verification:** Static review plus Python syntax parsing and seven synthetic pure-helper assertions passed in a network-isolated, secret-free sandbox. Upstream pytest suite and desktop integration were not run.
**Stack:** Python 3.11+, MCP Python SDK / FastMCP, uv, Bash, Hyprland, grim, ydotool/uinput, wtype.
**What it is:** A small local stdio MCP adapter that gives an AI client screenshot-based control of an existing Hyprland desktop—not a model, autonomous agent, remote desktop service or macOS automation layer.

---

## Verdict

⚠️ **Interesting — compact Hyprland integration, not a safe unattended desktop boundary.** The coordinate transforms, direct compositor cursor placement and split typing paths are useful, understandable engineering. However, client approval is the only action-consent layer; capture covers all monitors, input reaches the active desktop, and installation persists broad input authority. Consider only a deliberately isolated desktop with explicit client approvals, not a sensitive everyday session.

## What It Is

The client supplies the agent loop and model. This server exposes nine tools: screenshot, click, move, drag, scroll, type_text, key, cursor_position and list_windows. It uses local subprocesses to capture and control a running Hyprland session, including session discovery when started from SSH or tmux. “Omarchy Mac” describes Linux running on Apple hardware, not macOS support. The README reports development on an M3 Max MacBook Pro with Omarchy/Arch Linux ARM; that is upstream testimony, not compatibility independently established here. [1][2]

Image-capable MCP clients can receive a JPEG; actual client/model image support remains a prerequisite. There is no accessibility tree, semantic element selector, per-window input channel, built-in LLM or workflow planner. Extensive client configuration examples are documentation, not proof that every listed integration works. [1]

## Stack

| Layer | Technology / boundary |
|---|---|
| Protocol | FastMCP local stdio; caller owns model and approval UX |
| Runtime | Python >=3.11, inline dependency `mcp>=1.10,<2`, launched by uv |
| Capture | grim JPEG, quality 80, default maximum long edge 1456 pixels |
| Pointer | Hyprland >=0.55 Lua cursor dispatch; ydotool button/wheel events |
| Keyboard | ydotool evdev keycodes, wtype for non-ASCII/non-US typing |
| Installation | Bash, pacman, udev uaccess, modules-load, user systemd service |
| Storage/auth | No application database or application credential store; local process/session permissions |

## Key Features

### Coordinate handling is explicit, but freshness is only advice

`Layout` converts logical monitor rectangles into screenshot coordinates, including scale, negative offsets and rotated outputs. Cursor motion goes through Hyprland rather than accelerated relative mouse motion. These transformations have focused unit tests; our synthetic checks corroborate basic arithmetic. But actions recompute the current layout: no saved screenshot identity, frame token, expiration, target-window binding or changed-screen rejection exists. A layout/focus/content change between capture and click can misdirect input. Coordinates are not bounded to the captured image. [2][3]

### Typing pragmatism, not semantic targeting

ASCII on a US layout uses ydotool; other runs use wtype, prefixed with a Shift tap to address an upstream-reported Chromium first-key issue. Text follows the currently focused window. Shortcuts use physical US-layout keycodes. Argument arrays and `--` before text avoid shell interpolation and option interpretation; this is a useful narrow defense, not protection against an agent deliberately opening a terminal and typing executable commands. [2]

### Session discovery reduces setup friction and weakens explicit targeting

The server copies its environment, finds Wayland sockets, selects a recent live Hyprland instance and assumes the user runtime ydotool socket. This makes non-desktop launch contexts practical, but separate socket-selection heuristics need not identify the same intended session when several are available. There is no interactive session-selection or ownership-confirmation step inside tool execution. [2]

## Architecture

`server.py` is 324 lines: pure layout/key/text helpers, session/subprocess helpers, nine nested FastMCP tools, then a self-check and entry point. Each subprocess has a 30-second timeout and captured output; failures become runtime errors. There is no generic shell-execution tool and no HTTP listener configured in the entry point. Authentication/CORS for a network API are therefore not the relevant boundary: launching the stdio process with access to the desktop is the grant of authority. A downstream network wrapper would require a separate security review. [2]

The server is largely stateless. `drag` attempts button release in `finally`, which is a good exception-path precaution, but cannot guarantee release after abrupt process death or a failing release subprocess. There is no transaction log, action idempotency, undo, durable task checkpoint, input watchdog or server-enforced human takeover switch. Concurrent client actions and human activity have no explicit application-level arbitration. Click counts have a lower bound but no upper bound; scroll amounts and text size are not operationally capped. Per-subprocess timeout is not a whole-tool budget. [2]

## Permissions, Consent and Security

- **Install consent is not action consent.** The installer prints a plan and prompts (default yes); `--yes` skips it. README instructions ask agents to obtain permission first, but prose is not enforcement. The server has no per-action confirmation, per-app allowlist, sensitive-window masking or read-only mode. Client tool-approval settings are decisive. [1][4]
- **Persistent input authority is broad.** System setup installs packages, writes an active-seat uaccess rule for `/dev/uinput`, persists module loading, loads the module, reloads/triggers udev and enables the ydotool user service. This is not an application-scoped permission or a portal-mediated capture/input consent session. It need not make the server root, but it gives the authorized desktop user powerful virtual input capability. The two fixed `/etc` files are overwritten rather than merged. [5]
- **Visible content is untrusted.** Screenshots and window titles may contain prompt injection. No source-side instruction/content isolation or policy engine mediates the agent response. The server cannot distinguish harmless typing from financial, destructive or credential-bearing UI actions. [2]
- **Local execution still matters.** Helper executables are resolved through inherited PATH and receive an inherited environment. Do not confuse lack of shell interpolation with a sandbox or minimal privilege. No executable integrity check or environment secret scrubbing is present. [2]

## Privacy, Credentials and Egress

Capture includes every monitor, with no selectable-region or redaction option. JPEGs use a temporary file, are read into memory, and normally unlink on context exit; abnormal termination may leave a temporary file. Returned image bytes and window titles leave the server through MCP. Client/model providers may store or transmit them: the absence of a direct HTTP client in this server does **not** mean end-to-end local privacy. `list_windows` enumerates Hyprland clients with workspace, application class, title and geometry, not just the focused window. [2]

No explicit clipboard read/write API, telemetry sender, secret vault, credential extraction routine or persistent screenshot database appears in the reviewed code. UI shortcuts can nevertheless paste clipboard contents or expose secrets onscreen. Typed text is passed as subprocess arguments, creating possible exposure through process inspection; captured subprocess errors may flow back to the client. The server inherits the launching process environment. Do not type secrets through this interface merely because it has no credential field. [2]

The advertised “read-only” `--check` does not click/type, but **does capture a real screenshot** into a temporary file and queries session/input metadata. It is not privacy-neutral. We did not run it. Installation/update also contacts package/repository infrastructure, and uv resolves/downloads Python dependencies; client model egress is a separate boundary. [2][4][5]

## Installation, Updates and Removal

This is an assessment, not an installation recommendation. The README advertises a mutable hosted curl-to-shell bootstrap without an explicit URL scheme; it is not a pinned, authenticated release artifact recipe. The hosted bootstrap itself was not acquired or executed. The checked-in installer clones the current default branch, pulls existing checkouts with `--ff-only`, or downloads a main-branch archive without a checksum/signature gate. An existing checkout is updated without verifying its origin first. There is no dependency lockfile: the MCP SDK is range-constrained, not reproducibly pinned. Version 0.3.0 in plugin metadata is not evidence of a tagged or signed release. [1][4][6]

Positive details: config updates preserve unrelated JSON keys; existing configs get `.bak-hypr-computer` backups; replacement uses a temporary file and rename; non-plain JSON is refused rather than silently stripped. Codex registration skips an existing named block rather than reconciling a stale path. Backups use a fixed name and can be overwritten. Newly created replacement files use ordinary process umask rather than explicitly preserving restrictive file modes; if a client config contains credentials, review resulting permissions and backup handling. This is a code-level risk, not a demonstrated leak. [4]

Installation is not transactional: system changes can remain after self-check or client-registration failure. Some client failures are reported as manual setup warnings. No uninstaller or automatic rollback is included. Removal needs deliberate reversal of client entries/plugin registration, the installed checkout, applicable ydotool service enablement, uinput rules/module-loading changes and optional packages/caches/backups; shared dependencies and pre-existing rules must not be blindly deleted. [4][5]

## Maturity and Verification

Public unauthenticated GitHub metadata on 2026-11-22 reported creation on 2026-11-21, last push 2026-11-22 00:57:00 UTC, one star, zero forks and zero open issues/PRs in the aggregate counter. Releases and tags endpoints returned empty arrays. The reviewed commit is dated 2026-11-22 00:56:58 UTC. These are a very early project snapshot, not reliability metrics. The source clone was shallow; historical development breadth was not established. [7]

The tracked tree contains 11 pytest test functions (13 cases including parametrization) for layout conversion, chord parsing/order, text splitting, keyboard detection and UTF-8 environment handling. No CI workflow, installer tests or live MCP/desktop integration tests are tracked. Upstream hardware/version claims and the Chromium workaround were not reproduced. [3]

**Actually run:** Python AST parsing plus seven reviewer-authored assertions for HiDPI forward/reverse conversion, chord parsing, release order, text argument delimiter, non-US typing command selection and multi-monitor geometry. All passed inside a network-isolated sandbox with a cleared environment, synthetic runtime directory, no home/session sockets and no host desktop devices. Only pure helpers were called; no source subprocess, capture, installer or MCP startup ran. These checks are not the upstream pytest suite (pytest was unavailable and was not installed), and do not validate actual input delivery, capture accuracy, focus races, SDK compatibility or cross-client behavior.

## Comparison

| Option | Prefer when | Tradeoff |
|---|---|---|
| hypr-computer | An MCP agent needs basic control of an explicitly disposable Hyprland session | Small adapter, but whole-desktop authority and visual targeting |
| Direct [grim](https://gitlab.freedesktop.org/emersion/grim), [ydotool](https://github.com/ReimuNotMoe/ydotool), [wtype](https://github.com/atx/wtype) | A deterministic, narrow script suffices | Avoids model/tool-loop complexity; still requires careful device/session permissions |
| [Playwright](https://github.com/microsoft/playwright) | The task is confined to a browser | DOM/locator-oriented automation and dedicated browser contexts; not general desktop control |
| Portal-mediated remote-desktop/screencast designs | Explicit compositor-mediated session consent is required | Different integration and compositor support; not supplied by this repo |

The useful pattern to study is the separation of coordinate transforms and text-command construction from desktop I/O. Before broader adoption, prioritize explicit session/target selection, stale-frame rejection, input bounds and serialization, approval/human-takeover integration, privacy-conscious capture, reproducible dependencies and tested install/uninstall behavior. Alternatives above are scope comparisons, not tested drop-in replacements.

## Evidence

All code citations pin the reviewed SHA. Public metadata is mutable and was retrieved 2026-11-22 UTC.

1. [README: purpose, client requirements, limitations, upstream platform/version claims](https://github.com/malik-na/hypr-computer/blob/ac29d4702ffdb52e8496d6c4b97bb4f1ce6e6d5d/README.md).
2. [server.py: layout/text helpers L50–130, session/subprocess L136–175, tools L181–271, self-check L274–324](https://github.com/malik-na/hypr-computer/blob/ac29d4702ffdb52e8496d6c4b97bb4f1ce6e6d5d/server.py).
3. [tests/test_server.py: complete helper test scope](https://github.com/malik-na/hypr-computer/blob/ac29d4702ffdb52e8496d6c4b97bb4f1ce6e6d5d/tests/test_server.py).
4. [install.sh: download/update, configuration backups and registration](https://github.com/malik-na/hypr-computer/blob/ac29d4702ffdb52e8496d6c4b97bb4f1ce6e6d5d/install.sh).
5. [scripts/install-system.sh: persistent device/service changes](https://github.com/malik-na/hypr-computer/blob/ac29d4702ffdb52e8496d6c4b97bb4f1ce6e6d5d/scripts/install-system.sh).
6. [Plugin version/license metadata](https://github.com/malik-na/hypr-computer/blob/ac29d4702ffdb52e8496d6c4b97bb4f1ce6e6d5d/.claude-plugin/plugin.json), [MIT license](https://github.com/malik-na/hypr-computer/blob/ac29d4702ffdb52e8496d6c4b97bb4f1ce6e6d5d/LICENSE). Dependencies are separately licensed (including AGPL ydotool); MIT here does not relicense those components.
7. [Public repository metadata](https://api.github.com/repos/malik-na/hypr-computer), [releases](https://api.github.com/repos/malik-na/hypr-computer/releases), [tags](https://api.github.com/repos/malik-na/hypr-computer/tags).

---

**Attribution:** Naeem Malik / malik-na/hypr-computer, MIT. This review contains independent analysis, not redistributed implementation code.
