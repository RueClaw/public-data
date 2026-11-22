# wland (pithings/wland)

**Repo:** https://github.com/pithings/wland
**Author:** Pooya Parsa (pi0), pithings
**License:** MPL-2.0 for marked Zig sources and their binaries; MIT for the remainder; protocol XML retains upstream licenses. Not a blanket choice of either license.
**Reviewed:** 2026-11-22 (UTC)
**Revision:** `12e0e1de7d0b540b93611dfbcf603d3f792e8bd5`, main; commit dated 2026-11-21T22:50:35Z. Scope: README/license, core, relay, TypeScript SDK, demo/dev integration, Docker, build/release workflows and representative tests.
**Release observed:** v0.1.0-261121-6b1a8a2, published 2026-11-21; distinct from the reviewed main revision. Package manifest version 0.1.0.
**Verification:** Static source review only. No source execution, installation, builds, runtime tests, desktop access, live service probing or performance measurements.
**Stack:** Zig 0.16, WebAssembly, TypeScript, Linux Unix sockets/SCM_RIGHTS, WebSocket or byte streams; optional React/Vite demo.
**What it is:** A Wayland compositor running in a browser or headless JavaScript engine, coupled to a native Linux relay for real applications—not a Wi-Fi/network manager.

---

## Verdict

⚠️ **Interesting — a compelling embeddable compositor, not a hardened remote desktop service.** The split between native file-descriptor handling and a DOM-free WASM compositor is unusually useful for browser-hosted Linux apps and controlled automation. Authentication, application isolation and durable sessions are deliberately outside the implementation; automatic Chromium sandbox disabling and unauthenticated desktop takeover make direct host or network deployment a poor default.

## What It Is

Unmodified Linux Wayland clients connect to a new Wayland Unix socket. The native `wlandr` relay retains file descriptors and transports protocol messages, clipboard pipes and pixel updates to the JavaScript/WASM engine. The browser is the compositor, not simply a video viewer. It draws individual surfaces, routes input and manages windows. X11 applications optionally use xwayland-satellite.

The SDK separates engine, view, input and window manager. A headless API offers typing, clicking and screenshots without a DOM, making this relevant to fixture-driven GUI testing and automation. This does not sandbox the applications being controlled. The static web demo is different again: its sample apps, relay and shared-memory model can all run in the tab; that is not evidence that arbitrary native Linux programs run in a browser without a Linux execution environment. [E1–E4]

## Stack

| Layer | Implementation |
|---|---|
| Compositor | Zig core compiled to freestanding wasm32; object/wire handling and protocol-generated definitions |
| Native relay | Zig Linux executable, Unix sockets and file-descriptor passing; static x64/arm64 releases |
| Transport | Shared STREAM framing over WebSocket or inherited fd, Unix socket, vsock |
| Presentation | TypeScript engine/view/input/wm; Canvas/WebGL; Node headless screenshots |
| Pixel path | Changed rectangles plus LZ4 copy path; procfd/kwshm handle integrations; experimental DMA-BUF readback |
| Demo | React, Vite, Tailwind; in-tab sample clients and development-only host source |
| Storage/auth | No desktop-state database or built-in login; local runtime files, binary cache and app-owned storage |

## Key Features

### Real protocol, reusable composition

The engine handles protocol state without a DOM; browser presentation and input sit above it. STREAM is shared between native and WASM sides rather than separately reinvented. Handle-backed presentation avoids shipping pixels when the embedding environment can supply access to shared memory. That requires a trusted integration providing buffer open/read/close capabilities, not arbitrary browser filesystem access. [E2–E4]

### Useful testing surface, bounded compatibility

There are fixtures for drawing, input, clipboard and files; Node tests cover the engine, stream links, handles, server lifecycle and headless behavior. This is materially more than a screenshot-only demo. README limits include Chromium-only testing, US key layout, unsupported viewport cropping, no host-page drag-and-drop, experimental GPU readback and incomplete X11/window-decoration behavior. The approximately 65 kB gzipped and up-to-120-FPS figures are author claims, not reproduced measurements. [E1, E9]

## Architecture

App → Unix socket/FD passing → native relay → STREAM → WASM engine → view/input/window manager.

The relay owns the kernel-facing boundary: shared-memory files, clipboard pipes, socket lifecycle and optional GPU resources. The engine owns session/compositor state. WebSocket writes are serialized; takeover shuts down a stalled connection without waiting indefinitely for its write lock. One attached engine owns the session; new connections replace it. [E2, E5, E6]

There are sensible local correctness mechanisms: socket-name locks, checks before replacing a live socket, normal/signal cleanup, and tests for hostile STREAM lengths. Byte-stream record framing caps records at 256 MiB. These do not establish a hostile-client security boundary. The WebSocket reader independently accumulates fragmented payloads in an expanding array without an explicit aggregate message-size cap, and HTTP accepts spawn detached threads without an evident connection quota in that loop. Treat resource exhaustion as a static concern, not a demonstrated exploit. Default native builds use ReleaseFast, while WASM uses ReleaseSmall; these are not the safety-checking Debug configuration. [E5–E7, E9]

## Security, Permissions and Execution Boundaries

- **Desktop access is authority.** HTTP defaults to loopback, but there is no login, token, user separation or built-in TLS. A caller reaching the relay can take over the desktop, observe content and inject input. A terminal/file manager makes that equivalent in practice to powerful actions under the app user's permissions—not a restricted viewing session. Docker listens on all container interfaces; the README's basic published-port example exposes it on all host interfaces. [E1, E5, E8]
- **Origin checks are not authentication.** The native server compares the authority portion of Origin with Host; absent Origin is allowed for non-browser clients. This blocks an ordinary unrelated browser origin, but does not authenticate arbitrary clients, and the README explicitly excludes DNS rebinding and other local users. Upgrade handling is not explicitly restricted to the /ws pathname, so protecting only that path at a reverse proxy is insufficient: protect the entire service and WebSocket upgrades. [E5]
- **Native apps keep native privileges.** Node helpers inherit most of the parent environment and launch executables with spawn; they establish display variables and optionally dbus-run-session, not namespaces, seccomp or a per-app permission gate. They may inherit credentials and an existing session bus. A private, verified runtime directory matters; startServer falls back to a fixed temporary-directory name and mkdir does not validate an existing directory's ownership. [E3]
- **Chromium sandbox disabling extends beyond Docker.** runApp appends --no-sandbox to Chromium/Chrome command names, and the shell launcher does likewise. Docker also configures this flag and suppresses the warning. Its non-root UID 1000 is good but is not a replacement for Chromium's internal sandbox. Avoid sensitive profiles, host mounts and untrusted browsing in this configuration. [E3, E8]
- **Development includes a command runner.** Vite's /__wlandr/run accepts a whitespace-split command and calls runApp. It checks matching Origin/Host and loopback by default; WLANDR_RUN_REMOTE=1 relaxes the peer restriction. The launcher list is convenience UI, not an allowlist. This is development-only, not the packaged production HTTP API, but exposing it grants substantial execution authority. [E4]
- **Keep web roots curated.** Static serving rejects paths containing '..' and limits each file read to 64 MiB, but uses filesystem reads rather than a realpath/symlink confinement check. A configured web root must contain only intended public assets, including its symlink targets. [E5]

## Credentials, Privacy and Egress

No application account or API key is required by the core. The reviewed SDK loads its WASM asset and opens the configured relay link; no telemetry or model-provider integration was found in those paths. This is a scoped source observation, not a packet capture or a guarantee about dependencies or hosted infrastructure. Pixels, key events and clipboard transfers cross that link; plain HTTP/WS provides no transport confidentiality. Apps can independently access files, profiles, credentials and networks permitted by their environment. [E1–E4]

The web demo persists theme/source preferences in localStorage and has an explicit code-copy action using the browser clipboard. Internal Wayland clipboard support should not be confused with unrestricted permission to read the user's system clipboard. The public demo was not opened. Package/build/image acquisition involves npm, GitHub/GHCR, Debian and Zig distribution infrastructure; runtime egress of arbitrary apps is not constrained by wland. [E4, E8, E10]

## Persistence and Recovery

Reload, link loss or takeover destroys compositor state and closes app connections; most apps exit. Reconnecting creates a fresh engine rather than restoring the previous desktop. Docker watches the relay's detach log and restarts configured apps after a disconnect, including apps previously closed by the user. That is relaunch, not recovery of unsaved documents. App-owned disk state can persist according to the containing filesystem, but the demo's --rm lifecycle has no durable-volume arrangement. [E1, E6, E8]

Socket claims recover stale files under locking and avoid knowingly stealing a live compositor socket. startRelay creates a private temporary runtime directory and cleans it up on close/exit. The shipped native binary is unpacked into a content-named cache through write-and-rename, with a private temporary fallback. Existing cached executables are reused without rehashing their contents; this protects against partial writes/version confusion, not compromise by an actor already able to modify the user's cache. [E3, E7]

## Supply Chain and License

The root package has no declared runtime npm dependencies; build dependencies include obuild and TypeScript, while the demo has its own React/Vite stack and lockfiles. A committed WASM binary enables demo builds without Zig; this review did not reproduce it or compare it with source-generated bytes. Builds execute the repository's build hooks and native toolchain. [E10]

Release workflow actions are commit-pinned, dependencies use a frozen pnpm lockfile, and the workflow configures OIDC trusted npm publishing with provenance. Those are positives, not independent verification of npm attestations. Docker verifies the downloaded Zig archive with architecture-specific checksums, but base images use mutable tags, apt packages are unpinned, and pnpm is selected by major version. Release/image outputs were not downloaded or audited. [E8, E10]

The license split is by file/component: MPL-2.0 governs marked Zig sources and corresponding binaries, while other code is MIT and protocol XML retains upstream terms. Distributing modified MPL-covered files or binaries carries covered-source availability and notice obligations; MIT permits broad reuse with notices. This is not permission to relicense the whole project as MIT. No source components were extracted. [E11]

## Maturity and Evidence

Public GitHub metadata at retrieval reported 47 stars, 4 forks, zero open issues, repository creation on 2026-07-07 and last push on 2026-11-21. These are a dated discovery snapshot, not evidence of security or a long operating history. The releases endpoint showed v0.1.0-261121-6b1a8a2. The Actions listing returned one successful Release run at 6b1a8a2da49d35252a4cbf47f32f0c7c1e522ed0, not at this review's HEAD. [E12]

The current release workflow runs npm test (native Zig tests, smoke script, TypeScript checks, Node tests). Its triggers are release tags/manual invocation, not an every-PR gate. The image workflow is manual and smoke-tests HTTP/page/WASM availability, not full GUI security. Source tests demonstrate intended coverage; none were run here, and the observed earlier successful workflow does not prove the current revision passes. No fuzzing campaign, independent audit, cross-browser matrix or sustained deployment evidence was established. [E9, E10, E12]

## Comparison

| Option | Prefer it when | Tradeoff versus wland |
|---|---|---|
| [waypipe](https://gitlab.freedesktop.org/mstoeckl/waypipe) | Forward native Wayland applications over an SSH-based workflow | Native client/compositor rather than an embeddable browser compositor |
| [noVNC](https://github.com/novnc/noVNC) + a VNC server | Browser access to an existing remote desktop | Different server-rendered/VNC architecture; authentication and persistence depend on the server and gateway |
| [Apache Guacamole](https://guacamole.apache.org/) | An established browser remote-access gateway with authentication integration | Heavier service stack, rather than a small in-page compositor SDK |
| wland | Controlled browser embeddings and headless GUI experiments | Small compositional architecture, but external security boundary and disposable sessions |

These are architectural alternatives, not benchmarked substitutes or blanket security endorsements.

## Self-Hosting Notes

Do not adopt the all-interface demo command as a secure deployment recipe. For a separately authorized evaluation, use an isolated disposable Linux environment, loopback-only publication, no sensitive mounts/profiles/environment, and a private runtime directory. Remote use needs externally enforced authentication, encrypted transport and whole-service access control. Reconsider the Chromium flags before real browsing. Keep developer host launch endpoints off untrusted networks, and plan for session loss rather than promising reconnect continuity.

Before promotion: reproduce builds and attestations, test the exact revision offline in isolation, add resource ceilings, validate proxy upgrade handling and DNS-rebinding defenses, establish a deliberate browser/application sandbox policy, and verify required app/browser behavior. No deployment was performed as part of this review.

## Evidence and Verification Limits

All source links below are pinned to the reviewed commit. Review was static and selective, not a complete memory-safety audit. No source tests, binary reproducibility checks, GUI tests, exploit attempts or live probes were executed. Public GitHub metadata was retrieved unauthenticated on 2026-11-22 UTC; mutable metadata can change.

- **E1:** [README.md](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/README.md)
- **E2:** [core/src/compositor.zig](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/core/src/compositor.zig); [core/src/stream.zig](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/core/src/stream.zig); [protocol/STREAM.md](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/protocol/STREAM.md); [lib/engine.ts](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/lib/engine.ts)
- **E3:** [lib/index.ts](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/lib/index.ts); [lib/headless.ts](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/lib/headless.ts); [tools/wland-run](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/tools/wland-run)
- **E4:** [web/vite-wlandr.ts](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/web/vite-wlandr.ts); [web/src/session/sources.ts](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/web/src/session/sources.ts); [web/src/session/session.ts](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/web/src/session/session.ts); [web/src/App.tsx](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/web/src/App.tsx); [web/src/apps/code.ts](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/web/src/apps/code.ts)
- **E5:** [server/src/server.zig](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/server/src/server.zig); [server/src/ws_link.zig](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/server/src/ws_link.zig)
- **E6:** [server/src/relay.zig](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/server/src/relay.zig)
- **E7:** [server/src/socket.zig](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/server/src/socket.zig)
- **E8:** [docker/Dockerfile](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/docker/Dockerfile); [docker/entrypoint.sh](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/docker/entrypoint.sh)
- **E9:** [test/engine.test.ts](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/test/engine.test.ts); [test/server.test.ts](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/test/server.test.ts); [test/fixture/main.zig](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/test/fixture/main.zig); [build.zig](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/build.zig); [core/src/stream.zig](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/core/src/stream.zig)
- **E10:** [package.json](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/package.json); [build.config.ts](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/build.config.ts); [.github/workflows/release.yml](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/.github/workflows/release.yml); [.github/workflows/image.yml](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/.github/workflows/image.yml); [web/package.json](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/web/package.json)
- **E11:** [LICENSE](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/LICENSE); [protocol/wayland.xml](https://github.com/pithings/wland/blob/12e0e1de7d0b540b93611dfbcf603d3f792e8bd5/protocol/wayland.xml)
- **E12:** [Repository metadata](https://api.github.com/repos/pithings/wland), [releases](https://api.github.com/repos/pithings/wland/releases), [Actions listing](https://api.github.com/repos/pithings/wland/actions/runs?per_page=3), [observed successful Release run](https://github.com/pithings/wland/actions/runs/44953104084).

---

**Attribution:** pithings/wland, Pooya Parsa; MPL-2.0 and MIT by component, upstream protocol notices retained. Independent review; no upstream endorsement implied.
