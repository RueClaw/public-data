# HyprGlass (hyprnux/hyprglass)

**Repo:** https://github.com/hyprnux/hyprglass
**License:** BSD-3-Clause root; MIT notice in the Wayland protocol XML. Preserve applicable notices and the non-endorsement condition; dependencies retain their own terms.
**Reviewed:** 2026-11-09 (UTC)
**Revision:** 317ed8c1b06be00990ccdca02bf9ade936f47f13 (main; whole repository, focused inspection of rendering, configuration, lifecycle, protocol helper and workflows).
**Source updated:** Commit 2026-11-03; latest public release v1.1.1 published 2026-11-03.
**Verification:** Static source review and unauthenticated GitHub metadata. No build, installation, plugin loading, compositor interaction, GPU benchmarks or upstream tests run.
**Stack:** C++23, C11, GLSL ES 3.00, Hyprland internal APIs, Wayland server, Lua, Make.
**What it is:** An in-process Hyprland compositor plugin drawing Liquid Glass-inspired effects behind translucent windows, optionally layers and participating subsurfaces. Not a theme installer or a standalone compositor.

---

## Verdict

⚠️ **Interesting — pilot on a pinned, recoverable Hyprland session.** Real rendering, damage tracking, diagnostics and unload defenses make this much more than a screenshot demo. Internal compositor hooks, no checked-in automated test suite, unmeasured GPU costs and an open HDR report prevent a blanket daily-driver recommendation. Prefer native Hyprland blur if frosted transparency is all you need.

## What It Is

HyprGlass models a pane as a rounded convex slab: sample the backdrop, blur it, displace texture coordinates near its edge, separate RGB samples, then add tint, Fresnel glow and specular highlights. Presets are artistic approximations, not demonstrated physically accurate optics or parity with Apple's implementation.

Window glass sits below the application surface, so opaque applications can hide it. Opaque-window skipping defaults on. Layer and subsurface support default off; layers can use alpha masks, requested blur regions, rounded shapes or generated contours. Per-window tags, layer namespaces, inherited presets and light/dark overrides provide fine-grained control. See [README](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/README.md), [presets](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/BuiltInPresets.hpp) and [shaders](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/Shaders.hpp).

## Stack

| Layer | Technology and constraints |
|---|---|
| Host | Linux Hyprland; native plugin using unstable internal APIs |
| Renderer | GL/GLES framebuffers, GLSL ES 3.00; no Vulkan/CPU fallback inspected |
| Configuration | Hyprland Lua; type checks, bounded table copying and preset inheritance |
| Hints | ext-background-effect-v1 and project-specific hyprglass_item_v1 Wayland protocol |
| Build | C++23/C compilers, Make, pkg-config, Hyprland development headers, pixman, libdrm, Wayland server/scanner and transitive host dependencies |
| Packaging | hyprpm source build or release shared library; no server, database or account |

## Architecture and key features

1. [main.cpp](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/main.cpp) checks compatibility, registers render/window/monitor/config listeners, attaches decorations and hooks renderLayer and CRenderPass::add. Hook failures disable affected features.
2. [GlassDecoration](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/GlassDecoration.cpp) queues bottom-layer render-pass elements. [GlassRenderer](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/GlassRenderer.cpp) copies padded backdrop regions, runs horizontal/vertical Gaussian passes and composites glass. Core paths assume GL framebuffer types.
3. [GlassLayerSurface](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/GlassLayerSurface.cpp) redirects foreground rendering into a temporary framebuffer, then combines it with masked glass. Subsurface passes wrap a participating client surface draw similarly.
4. [BackgroundDamageObserver](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/BackgroundDamageObserver.cpp), scene generations and render-order fingerprints invalidate caches. Deferred resampling avoids incompletely redrawn backgrounds. X-ray uses wallpaper snapshots; frost adds overlap-sensitive blur; contour computes a distance field around irregular alpha outlines.
5. [ItemHints](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/ItemHints.cpp) loads an embedded C helper through memfd/dlopen with RTLD_NODELETE. Resident Wayland request implementations let old objects become inert on unload instead of pointing into unmapped plugin code. Callbacks into the plugin are cleared first.

The helper is a useful lifecycle pattern, but deliberately remains resident until compositor exit. Reloading does not replace every loaded component; a helper ABI mismatch disables hints and may require a session restart.

## Compatibility and GPU requirements

**Choose the source line, not just the newest version.** main follows hyprland-git; stable hyprland-X.Y branches follow release lines. The checked-in .hyprland-version says 0.57.1, but is not a guarantee arbitrary 0.57.1 installations can load this main build. [hyprpm.toml](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/hyprpm.toml) maps exact host release commits to plugin revisions; its newest explicit entry here maps Hyprland 0.57.0 to HyprGlass v1.1.1. Unmatched commits fall through to main.

[HyprlandIdentity](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/HyprlandIdentity.hpp) accepts identical commits, or a shared major/minor release line for release-channel builds. [LoadGuard](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/LoadGuard.cpp) also compares dependency-version suffixes. main requires commit matching when a usable build hash exists. Missing identity can yield “unknown,” not rejection. These checks reduce mismatch risk but do not guarantee all ABI safety: the dynamic loader and initial API calls must still work. Do not use the unsupported version-check bypass as a compatibility fix.

The current docs/config are Lua-native for Hyprland 0.57; older hyprlang installations need matching older source and documentation. Other compositors, X11, macOS and Windows are not targets. No qualified Intel/AMD/NVIDIA model/driver matrix or numeric VRAM minimum was found. The concrete requirements are the host's GL path and shader support, not a named GPU brand. [Contour](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/Contour.cpp) checks GLES 3.2 or GL_EXT_color_buffer_float for half-float fields, with alpha-mask fallback. Timers additionally require GL_EXT_disjoint_timer_query. [Open issue #101](https://github.com/hyprnux/hyprglass/issues/101) reports over-bright semitransparent layers on an HDR/colour-managed monitor; not reproduced here.

## Performance: mechanisms, not measured guarantees

Actual optimizations include opaque-window skipping, cached sampled/blurred backdrops, capped live resampling (30 Hz default), reduced sampling resolution for stronger blur, shader variants, paired bilinear Gaussian taps and folded blur passes. [Diagnostics](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/Diagnostics.cpp) exposes cache hits/misses/deferred work, megapixels, contour rebuilds and optional GPU stage timers. Debug modes separate render-pass hint cost from GL pipeline cost. These are measurement tools, not benchmark results.

The README's “static scenes stay free” should mean avoiding resampling, not zero total compositor/GPU work: cached glass still needs composition/bookkeeping when drawn. Blur-folding's “identical look” is an intended perceptual result, not proven pixel equivalence. The implementation preserves a Gaussian variance relationship but uses capped finite kernels and sampled textures; no image/numerical regression suite establishes equality.

Cost grows with glass area, resolution/scale, background activity and effects. Self-sampling reblurs busy application content. Forced layer resampling ignores the cap and is explicitly expensive. X-ray retains a monitor-sized framebuffer, larger with HDR, expiring after 600 rendered frames without use—not necessarily ten seconds of idle wall time. Frost and contour add textures/passes. No reproducible hardware-labelled frame-time, power or battery benchmark suite was found. Before adoption, compare disabled/native-blur/glass modes under idle, video, dragging, mixed-scale monitors and lock/unlock; measure frame-time tails and power, not just cache counters.

## Desktop authority, privacy and input boundaries

**Loading this library trusts native code inside the compositor.** There is no plugin sandbox or portal consent boundary; bugs can affect the whole graphical session. It samples framebuffer content and reads window/layer metadata. No telemetry, credential collection, network client/listener or screenshot-to-disk path was found in inspected runtime source. This is a scoped static finding, not proof of vulnerability absence. Downloads/package repositories are a separate build/update network boundary.

The Wayland extension supplies preset/shape hints, not pixel readback, arbitrary shaders, paths or shell commands. It uses client-associated Wayland objects, caps preset storage, rejects duplicate active items per surface, falls back for invalid extents and clamps negative radii. No additional app allowlist in the helper bind path or explicit per-client object quota was identified; lifecycle/resource-pressure fuzz tests would be valuable. CORS/web authentication do not apply to this local protocol.

Lock handling mirrors Hyprland's above-lock layer selection to avoid injecting glass without a foreground surface over the lockscreen. This is a positive code-level safeguard, **not experimentally verified lockscreen privacy**. Validate the exact lockscreen, screen-sharing and overview-plugin combination before sensitive use. Item diagnostics include window addresses/classes, monitor names and presets; inspect/redact before posting bug reports.

A static protocol-contract discrepancy deserves a regression test: [XML](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/protocols/hyprglass-item-v1.xml) says destroying an item retains committed hints until the next surface commit; [item_resource_destroy](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/src/item-helper/helper.c) immediately removes/frees the item and lookup subsequently finds none. The next redraw may lose hints before the documented commit boundary. This is a source-level observation, not a reproduced failure or claimed exploit.

## Installation, update, removal and recovery

[Makefile](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/Makefile) builds local shared objects and offers clean, but does not install packages or rewrite desktop config. hyprpm is recommended upstream; manual loading or a persistent Lua load line are alternatives. A prebuilt binary must match architecture, Hyprland and dependencies. Release automation builds on Arch Linux, not a demonstrated multi-architecture matrix. Release assets were not executed or independently reproduced here.

Back up configuration and merge a guarded plugin-specific block; do not replace a whole config. There are **runtime side effects**: window glass turns shadows on and sets no_blur at the direct-property-set priority. Unload withdraws its setting rather than snapshotting a pre-existing value at that same priority, so runtime property ownership can conflict. Exit does not explicitly restore the prior shadow setting; reload preserved user config after removing/disabling the load path. Layer blur management also changes rendering behavior while active.

Upstream documents hyprpm update, plugin unload and hyprpm disable; there is no dedicated full uninstaller. Remove only the chosen installation's startup entry and owned binary, preserving unrelated settings. Unload cleans listeners, hooks, decorations, GPU state and callbacks, but the helper stays resident; restarting the compositor is the strongest reset after helper changes or unexplained corruption.

For a session that will not start, use a separate text console/recovery session to disable the plugin startup entry and restore known-good config. Do not depend on hyprctl responding before compositor startup finishes. Top-level synchronous commands in Lua can deadlock during plugin-induced config reload. The README's systemctl --user revert troubleshooting suggestion is broader than deleting one temporary timeout drop-in and can discard other overrides: preserve existing units/drop-ins and undo only the diagnostic change. No such changes were made here.

“Loaded” can mean paused: plugin list gives the compatibility/duplicate reason while hyprglass status may not exist. Once active, inspect status and configerrors. Shader failures stay disabled until reload; missing hooks selectively disable layers/items. Keep guards enabled, rebuild after host upgrades and retain a known-good rollback pair.

## Maturity, licenses and supply chain

Public API snapshot: 350 stars, 49 forks, nine open issue/PR objects (not nine confirmed bugs), created 2026-02-16, last pushed 2026-11-03. v1.1.1 fixes video/GPU backdrop refresh; v1.1.0 addresses stale backgrounds, transforms and animation issues. This shows maintenance and an evolving rendering surface—not universal stability.

[CI](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/.github/workflows/ci.yml) builds stable-branch PRs against Arch's Hyprland and main against Chaotic-AUR hyprland-git. A wrong stable line generates a warning rather than proving that older line builds. A [sampled successful CI run](https://github.com/hyprnux/hyprglass/actions/runs/42476575671) targets the reviewed SHA. Checks cover compilation and commit messages, not automated rendering/protocol/lockscreen/GPU correctness. No tracked test directory or test target was found. No upstream tests or build were run here.

Actions use mutable version tags and rolling Arch/container/package inputs. [Release automation](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/.github/workflows/release.yml) downloads a versioned changelog tool without an accompanying checksum check in that step; no signing/attestation step was identified. These are reproducibility/supply-chain hardening opportunities, not evidence of compromise.

[Root BSD-3-Clause](https://github.com/hyprnux/hyprglass/blob/317ed8c1b06be00990ccdca02bf9ade936f47f13/LICENSE) names Jeremy Trufier; protocol XML carries an MIT grant for contributors. Retain applicable notices when redistributing. Hyprland/Wayland/graphics dependencies retain separate obligations. No upstream code or artwork was extracted.

## Comparison

| Option | Best fit | Tradeoff |
|---|---|---|
| HyprGlass | Refraction, edge optics and client-hinted shapes on Hyprland | Native-plugin ABI, extra rendering and recovery burden |
| Hyprland native blur/opacity | Ordinary frosted transparency without another native plugin | Not the complete lens/refraction/preset system |
| App-owned translucent styling | A controlled bar/widget/application | Narrow scope; cannot generally sample arbitrary desktop content itself; compositor blur may still be needed |
| KDE/KWin built-in blur | Standard translucency for existing Plasma users | Different desktop/compositor, not an effect-parity Hyprland replacement |

These are functional alternatives, not benchmark rankings. Native blur is the least additional machinery for the common case; HyprGlass earns its complexity when the optical effects are the requirement.

## Verification and limits

Inspected public documentation/tree, license, build/manager metadata, shaders/rendering, cache/damage paths, configuration, load/unload guards, protocol/helper and workflows. Public accessibility was verified without account authentication. Existing reviews and repository index were searched; no prior same-source review was found. Artifact validation covers Markdown/HTML/index consistency and standalone markup, not compositor behavior.

No host desktop data, user config or private files were used. No installation, config mutation, plugin loading, model downloads or paid API calls. Driver support, fidelity, frame pacing, power, lockscreen behavior, protocol destruction timing and full removal recovery remain experimentally unverified. This is not a security audit or dependency endorsement.

---

**Attribution:** hyprnux/hyprglass; Jeremy Trufier and contributors. BSD-3-Clause root; MIT protocol notice.
