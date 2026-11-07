# Raven (oscar-soirey/Raven)

**Repo:** https://github.com/oscar-soirey/Raven

**Author:** Oscar Soirey

**License:** Apache-2.0; bundled code and fonts have separate terms (MIT/public-domain, zlib, OFL). Preserve LICENSE, NOTICE and applicable component notices.

**Reviewed:** 2026-11-07 (UTC)

**Revision:** 7f4411c376cec8fad2d071d63696b8444ec2640d; repository-wide static review, focused on build/CI, core handles/rendering, XML, filesystem/network helpers, web integration and designer persistence.

**Verification:** Source and public GitHub metadata inspected. No source code, builds, tests, benchmarks, browser processes or installers executed.

**Stack:** C11, CMake, Vulkan, Win32/X11/Wayland/Cocoa, generated language bindings; optional Chromium DevTools integration.

**What it is:** A retained-mode native GUI toolkit and visual XML designer for editors and tools. This is Oscar Soirey's C GUI library, not an AI coding agent, agent-memory product, or another project named Raven.

## Verdict

⚠️ **Interesting — prototype editor interfaces, but do not treat this revision as production-ready.** The architecture offers a coherent C ABI, declarative live-reloaded layouts, docking and rich custom rendering without a heavyweight application framework. However, the exact reviewed revision has a failed Linux test job, its public API/ABI remains unsettled, and its native resource loaders and browser bridge require explicit application trust boundaries. Prefer a pinned, tested prototype with trusted assets over a wholesale toolkit migration.

## What It Is

Raven provides native windows with its own GPU-drawn widgets, not a wrapper around the platform's widget set. Applications create trees through the C API or load XML and bind named actions. The repository also includes a visual designer, theme editor, example applications, a text editor widget, node graphs, tables, docking, localization and accessibility integrations. These are building blocks, not a finished general-purpose IDE.

Its public identity is unambiguous in the README, CMake project and NOTICE. A name-only mention of “Raven” in other tooling documentation is not evidence that it refers to this repository. Existing public review/index entries were checked by canonical owner/repository; no prior matching review was found.

## Stack

| Layer | Implementation |
|---|---|
| API and state | C11, public headers, global library context, typed generational IDs |
| Layout | Retained widget tree, cached measure/arrange, XML expansion and live diff |
| Rendering | Vulkan loaded dynamically; null/custom backends; batched draw instances |
| Concurrency | UI owner thread, ordered render queue, worker jobs, bounded frames in flight |
| Native integration | Win32, Cocoa, X11 and dynamically loaded Wayland libraries |
| Assets | stb_truetype, stb_image, nanosvg, embedded/subset fonts |
| Web | Installed Chromium-family browser, CDP pipes, image frames mapped to widget textures |
| Packaging | Static/shared CMake library; bindings including C++, Rust, Python, Go, C#, Java, Zig and LuaJIT |

## Key Features and Architecture

### A useful separation of responsibilities

The UI thread owns widget mutation and callbacks; paint workers read while the UI thread waits. The renderer receives owned frame packets through an ordered command queue. Large subtrees split into paint chunks at 512 widgets, preserving child order when merging. Back-pressure limits queued frames. This is a meaningful multithreaded implementation, not permission to mutate widgets from arbitrary threads. See [architecture](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/docs/ARCHITECTURE.md), [paint](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/widget/paint.c) and [renderer](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/render/renderer.c).

Typed IDs use 4 type bits, 8 generation bits and 20 index bits. They catch many wrong-type and recently deleted handles. The generation is an incrementing uint8_t, so it wraps after 256 reuses of a slot: the broad documentation claim that deleted IDs remain invalid after reuse is not an unlimited guarantee. This is defensive API bookkeeping, not memory isolation. See [handle implementation](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/core/handle.c) and [layout](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/core/handle.h).

### Declarative editing with real reuse

XML expands declared widgets, conditions, repetitions and includes into a widget tree. The watcher periodically checks files, validates replacements, and tries to retain matching widgets by name/content/position. Bad partial saves are retried before reporting errors. This supports a productive layout-design loop, but it is not transactional storage or a sandbox for arbitrary third-party UI documents. See [components](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/xml/xml_components.c), [loader](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/xml/xml_loader.c) and [watcher](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/xml/xml_watch.c).

### Rich rendering, with qualified performance evidence

The renderer uses instanced primitives, clipping and batching; glass adds offscreen scene copies and blur passes. The README reports 12,000-widget CPU layout/repaint numbers from a two-core VM and explicitly says parallel paint helped little there. It also reports about 250 ms for a glass frame on software Vulkan and says GPU cost was not measured. These are upstream measurements, not reproduced results or proof of fast glass rendering on target hardware. The approximately 1.3 MB shared-library claim likewise excludes the system graphics stack and optional browser. See [performance section](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/README.md#performance).

## Security, Execution and Privacy Boundaries

### Native code has the application's authority

Raven runs inside the caller, with its filesystem, environment and desktop permissions. There is no account service, authentication layer, tenant isolation or permission broker to configure. CORS is not an authorization boundary for this native library. Native callbacks, custom widgets and render callbacks are application code.

XML includes, fonts and images resolve local paths; the resolver accepts absolute paths and searches configured/document directories. It is not a directory-confinement mechanism. Feed trusted project assets or impose an application-level resource policy. Font-table checks, malformed-font tests and SVG guards are positive hardening signals, but the C parsers/decoders still process attacker-controlled bytes in-process. No independent fuzzing or memory-safety assurance was performed. See [font validation](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/render/font_raster.c), [font tests](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/tests/test_fonts.c), [third-party notes](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/THIRD_PARTY.md).

### Network access is not limited to the web view

XML image URLs reach asynchronous texture fetching. On Unix, the downloader launches curl through execlp (argument vector, not a shell), permits HTTP/HTTPS and redirects, and sets five redirects, a 20-second limit and a 32 MiB download cap. Windows uses WinHTTP and a byte cap. No private-address/loopback denylist or application origin allowlist was found in these paths. Untrusted XML or image URLs can therefore cause requests from the application host, including internal destinations; protocol and byte limits are not SSRF protection.

The Unix invocation does not disable curl's default config file and inherits the environment/PATH. Proxy settings, curl configuration and executable discovery can affect network behavior. This is an extra runtime dependency and credential/configuration boundary beyond “C11, no dependency.” Native dialogs can also spawn zenity/kdialog; URL opening delegates to the OS. See [download implementation](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/core/fs.c#L515-L654), [texture worker](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/render/texture.c), [XML images](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/xml/xml_loader.c) and [dialogs](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/widgets/dialogs.c).

### Browser bridge: useful, but more authority than a picture suggests

The web view controls an installed Chromium-family browser over pipes rather than opening a default TCP debugging port. It uses a separate temporary profile by default and normally keeps Chromium's own sandbox. However:

- Root on Unix or the mere presence of RAVEN_WEB_NO_SANDBOX adds --no-sandbox; even a value of “0” is present. CI explicitly uses this override. Do not copy it into untrusted-content deployments.
- Browser background-network suppression is a set of flags, not an egress firewall. Pages still fetch scripts, images and other resources. Safe-browsing-related features are disabled; “only the sites shown” is not a universal privacy guarantee across browser versions.
- The message bridge forwards ravenPostMessage payloads to a host callback without an origin/execution-context authorization check in that dispatch. A host that maps messages to privileged actions must validate origin/navigation and message schema itself. JavaScript dialogs are automatically accepted; they are not user approval prompts.
- Browser path/arguments are configurable; the Unix child inherits the environment through execv. Persistent profiles are opt-in, and password-store/basic plus mock-keychain switches mean this is not a promise of OS-keychain-protected session storage.
- Debug protocol tracing can expose page content. On unexpected browser exit a log is copied outside the temporary profile; therefore “nothing kept” is too broad. Cleanup also cannot guarantee deletion after a hard application crash.

See [browser startup/cleanup](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/web/src/web_browser.c), [process boundary](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/web/src/web_posix.c), [message dispatch](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/web/src/web_view.c#L580-L620) and [web documentation](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/docs/WEB.md). No actual browser/network trace was run in this review.

**Important documentation drift:** docs/WEB.md describes a separate optional library. At this revision RAVEN_BUILD_WEB defaults ON and its sources are compiled into raven; raven::web is a compatibility interface target. A browser is started when web views are used, not merely because the feature is compiled. Disable the feature explicitly if unnecessary. See [root options](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/CMakeLists.txt) and [web CMake](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/web/CMakeLists.txt).

## Persistence and Recovery

The designer saves XML, themes, translations and recent/settings data; docking layouts serialize separately. The checked file-write helper opens the target with wb, writes and closes it. It does not implement temporary-file replacement, fsync or a journal. A successful save API result is not a power-loss durability guarantee; interruption can truncate an existing file. Keep project files under version control/backups. See [file writes](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/core/fs.c), [XML save](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/src/xml/xml_dom.c#L452-L468) and [designer save paths](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/tools/designer/main.c).

Hot reload retries incomplete parses and tries to preserve widget state, which is useful recovery from ordinary editing, not crash recovery. Browser crashes are reported to views and stop the browser; the inspected code is not a durable workflow/session restart system. Persistent browser profiles change retention and credential responsibilities and should never point at a user's ordinary browser profile.

## Tests, CI and Maturity

Public metadata at review time: 2,064 stars, 95 forks and 12 open issues/PRs; repository created 2026-10-09, last pushed 2026-11-07. Latest published release checked was [v0.2.2, 2026-11-06](https://github.com/oscar-soirey/Raven/releases/tag/v0.2.2). These are activity signals, not quality measurements, and this review covers the exact main-branch SHA above rather than assuming release parity.

The repository has substantial headless tests for widgets, XML, memory, threading, fonts, themes, editing and more. Wayland tests implement a small compositor; rendering tests can skip without a Vulkan driver; web tests can skip browser-dependent portions. CI builds Linux/macOS/Windows static and shared variants, but runs its test suite on Linux only. The roadmap explicitly lists Windows/macOS test execution, CI fuzzing, API/ABI versioning and returned-pointer lifetime documentation as unfinished.

**Current evidence is not green:** [Build run 42399389852](https://github.com/oscar-soirey/Raven/actions/runs/42399389852) for the reviewed SHA concluded failure. Its [Linux tests job](https://github.com/oscar-soirey/Raven/actions/runs/42399389852/job/128483665897) built successfully but failed the Test step. This review did not retrieve the individual failing assertion/log, so it does not assign a cause. A successful Pages deployment is unrelated to library test correctness. Workflow presence must not be summarized as “tests pass.”

Open reports include [Windows screenshot backdrops](https://github.com/oscar-soirey/Raven/issues/53), [macOS Odin binding runtime lookup](https://github.com/oscar-soirey/Raven/issues/40) and [animation responsiveness](https://github.com/oscar-soirey/Raven/issues/20). These are user reports, not independently reproduced defects. docs/WEB.md says its Windows browser path had never been run; platform compilation does not establish runtime browser compatibility.

Full OpenType shaping and input methods on Windows/macOS/Wayland remain roadmap gaps; X11 XIM support and some Arabic/bidirectional support do not equal complete international text support. See [roadmap](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/ROADMAP.md), [test registration](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/tests/CMakeLists.txt) and [workflow](https://github.com/oscar-soirey/Raven/blob/7f4411c376cec8fad2d071d63696b8444ec2640d/.github/workflows/build.yml).

## Comparison

| Option | Where it fits better | Tradeoff against Raven |
|---|---|---|
| [Dear ImGui](https://github.com/ocornut/imgui) | Mature immediate-mode debug/editor tooling | Different programming model; Raven emphasizes retained XML design and styled application widgets |
| [Nuklear](https://github.com/Immediate-Mode-UI/Nuklear) | Small C immediate-mode UI integrated into an existing renderer | More host integration work; less of Raven's designer/docking/application package |
| [Qt](https://code.qt.io/cgit/qt/) | Broad production desktop applications, text and platform integration | Larger framework and more complex licensing/deployment choices; stronger established ecosystem |
| [GTK](https://gitlab.gnome.org/GNOME/gtk) | Established C-based desktop toolkit and accessibility/text stack | Different styling/platform focus; Raven offers a compact custom-rendered editor-oriented approach |

These are architectural alternatives, not a head-to-head benchmark performed here. Raven's differentiator is the combination of C ABI, retained XML, visual tools and rich renderer—not simply “smaller than a browser,” since web views start a full browser anyway.

## Self-Hosting / Integration Notes

There is no service to self-host. Native integration needs CMake 3.16+, a C11 compiler, platform development headers, and a suitable Vulkan runtime for the default renderer (MoltenVK on macOS). If Vulkan headers are absent, CMake downloads Khronos headers at tag v1.3.290 by default; for reproducible/offline builds supply vetted headers and disable fetching. Wayland libraries are dynamically loaded; Linux still builds with X11 headers in the normal configuration. URL textures additionally need curl on Unix. Browser views require a compatible installed Chromium-family executable and image decoding.

For evaluation, pin the SHA, resolve the failing test job, disable unused web/network-capable features where possible, use trusted assets, and verify the target platform's IME, accessibility, input, display scaling, GPU/glass cost and binding ABI. Run sanitizers and malformed-input tests before accepting external documents. A null-platform/null-backend test build is useful for logic but cannot validate actual desktop rendering or browser sandboxing. No installation or deployment was performed for this review.

## Verification Limits

Static inspection is not a security audit. Selected implementation paths and tests were read, not every function. No fresh benchmark, memory-pressure exercise, render screenshot, browser isolation test, credential inspection or power-loss test was run. Upstream sanitizer/performance claims remain upstream claims. Release packages and every language binding were not independently validated. No source code or assets were extracted for redistribution.

---

**Attribution:** Oscar Soirey / [oscar-soirey/Raven](https://github.com/oscar-soirey/Raven), Apache-2.0; see repository NOTICE and THIRD_PARTY.md for component terms.
