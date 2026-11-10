# Typecase (iretonsean/typecase)

**Repo:** https://github.com/iretonsean/typecase
**License:** No project-wide license found. Bundled harfbuzzjs has an MIT notice; that does not license Typecase itself. Do not assume permission to redistribute or adapt the application.
**Reviewed:** 2026-11-10 (UTC)
**Revision:** 082a60ea78944f6e9e116719271a192a84c236fb; whole repository, focused on backend, launcher, installer, frontend, vendored dependency notices, and tests.
**Verification:** Static inspection plus 20 selected synthetic unit tests passed in a secret-free, network-isolated Bubblewrap sandbox. No installation, desktop launch, font installation, live URL probe, or browser E2E execution.
**Stack:** Python standard library HTTP server; vanilla JavaScript/CSS; Chromium app window; Fontconfig; vendored harfbuzzjs/WebAssembly.
**What it is:** A Linux font library, link-based font installer, comparison viewer, and layered typesetting canvas—not a keyboard remapper or text-expansion tool.

## Verdict

⚠️ **Interesting — a cohesive local typography workbench, too early for an unqualified deployment recommendation.** The staged font preview, scoped uninstall, and browser-to-vector workflow are thoughtful. Missing application licensing, same-day public history, nontransactional installation, and export/licensing footguns warrant caution; use established tools for important production work until these are addressed.

## What It Is

Typecase targets Omarchy and other Linux desktop users who want to browse installed fonts, compare two to four families, acquire fonts from public links, and compose a simple page without switching tools. Fontconfig supplies installed family/style metadata. The UI exposes favorites, filters, glyph details, variable axes, and supported OpenType features.

The canvas supports text, path, and path-group layers; transforms, direct point editing, and outlines derived from HarfBuzz shaping. It is a small desktop workflow, not a multiuser font service, cloud design suite, or full font editor. The README's screenshots and feature descriptions are supported by implementation paths, but visual fidelity was not independently exercised.

## Stack

| Layer | Technology |
|---|---|
| Backend | Single Python module, ThreadingHTTPServer, urllib, zipfile, JSON files |
| Frontend | app.js plus layers.js; DOM/SVG/Canvas 2D; no build pipeline |
| Fonts | fc-list, fc-query, fc-cache; custom OpenType/TTC parsing |
| Shaping | Vendored harfbuzzjs 1.6.4 according to VERSION.txt |
| Desktop | Bash launcher, Chromium dedicated profile, desktop entry |
| Storage | state.json, installs.json, repository-local staging cache, browser profile |

## Key Features

### Preview before installation

GitHub repository/folder/file links, Google Fonts family names/links, and direct TTF/OTF/TTC/ZIP links become temporary staging collections. Files must pass a font magic check and fc-query before preview; family-name collisions are surfaced. Selected files are copied into a new user-font collection. Duplicate detection is by family name, not content hash or license equivalence. Google Fonts requests resolve through the public google/fonts GitHub repository, not an authenticated Google integration. [Backend evidence](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase.py#L464-L828)

### Typography plus editable outlines

The frontend probes font features and axes, supports shared comparison text, and maintains up to 200 in-memory canvas snapshots. Outlining uses local HarfBuzz WASM, browser line measurements, and a custom direction-run heuristic. This is a useful bridge from text composition to editable glyph paths, but not evidence of complete Unicode bidirectional-layout equivalence across every script. [Canvas](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/static/app.js#L334-L398), [outlines](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/static/layers.js#L750-L880)

### Portable exports have different tradeoffs

JSON saves the document model, not a bundled font package; reopening on another machine can substitute an available family. PNG is rasterized at 2× artboard dimensions. SVG embeds complete used font/face bytes as base64 rather than subsetting or checking embedding restrictions. This improves portability but can disclose or redistribute commercially licensed font programs. Outlining removes the live-text font dependency but is not a blanket exemption from the font license. Exported artwork and JSON contain the user's text. [Export implementation](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/static/app.js#L614-L739)

## Architecture

The launcher selects a local port, starts the Python process, opens Chromium in app mode with a dedicated profile, and attempts to stop its child when the window/browser exits. Python serves the static frontend, allowlisted font bytes, and JSON APIs. Fetch jobs run on daemon threads; jobs and previews live in process-global dictionaries. State updates use a lock and temporary-file replacement. No database, account backend, API key, AI service, telemetry client, or arbitrary shell-command API was found in the reviewed application paths.

External processes are invoked with argument lists rather than interpolated shell commands in the Python backend. The small codebase is easy to trace, though the frontend shares global state and packs substantial parsing, geometry, persistence, and UI logic into two large files. [Launcher](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase), [backend](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase.py)

## Security, Permissions, and Network Boundaries

- **Local, not authenticated:** The server binds 127.0.0.1, checks Host, checks Origin and Sec-Fetch-Site on API/font routes, requires JSON POSTs, and caps request bodies at 10 MiB. These are meaningful browser cross-site defenses. Requests without Origin/Fetch metadata are accepted; there is no token or OS-user authentication. Other local processes able to reach the port can read state and invoke operations. Do not expose it through a proxy or broaden its bind address. [HTTP boundary](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase.py#L839-L1010)
- **Restricted file access:** Font endpoints require exact normalized allowlisted paths discovered through Fontconfig/staging. Uninstall resolves the collection directory, verifies files remain within it, refuses symlink files, and removes recorded files rather than indiscriminately deleting a collection. Useful protections, not a sandbox for the whole app. [Allowlist](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase.py#L160-L171), [uninstall](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase.py#L802-L828)
- **Outbound downloads are explicit:** Public-IP DNS validation applies before downloads and redirects, with a 400 MiB download ceiling and ZIP limits of 60 MiB/file and 500 MiB unpacked. However validation and urllib connection perform separate resolution; addresses are not pinned, leaving a DNS-rebinding/TOCTOU gap in the intended public-only boundary. HTTP is permitted, and no artifact signature or checksum verification is performed. This is static analysis, not a demonstrated live exploit. [Download checks](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase.py#L482-L554), [ZIP handling](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase.py#L623-L667)
- **Preview already parses untrusted fonts:** fc-query handles downloaded bytes before the final install click, followed by browser and WASM font parsing. Magic checks are not malware validation. Keep Chromium and Fontconfig current; use trusted font sources.
- **Resource limits are incomplete:** Each fetch creates a thread/job without a global concurrency, job-retention, or cumulative-stage quota. Direct-file downloads use the 400 MiB ceiling, not the ZIP per-file limit. Multiple requests can exhaust memory/disk despite individual caps. Imported JSON is parsed before sanitization; large artboards and many layers can be expensive.
- **Credentials/privacy:** No accounts or credential store are required. Source URLs are retained verbatim in installation records; avoid token-bearing URLs. Download servers see the request/IP and Typecase user agent. The README's “nothing is loaded from the internet at run time” accurately describes bundled UI/shaping assets, not the font-download workflow. It is not a network-free application in installer use.

## Data Handling, Recovery, and Retention

State and installation records default to the user's local Typecase data directory; fonts live in the user's Typecase font collection directory; staged downloads default to the source checkout's .cache/staging. Chromium maintains a separate persistent profile. Files are ordinary local data, with permissions inherited from the user's environment rather than application encryption or a documented retention policy.

Successful installs and explicit cancels remove staged directories; startup clears the staging root. Failed/abandoned fetches can leave files until a later startup. Completed jobs remain in memory until exit. Install records retain source URLs, dates, families, and absolute font paths. Corrupt JSON is renamed with a .bad timestamp, preserving a recovery copy; writes use os.replace but no fsync or versioned backup. These damaged copies have no automatic retention limit. [State](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase.py#L283-L331), [staging lifecycle](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase.py#L670-L800), [startup](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase.py#L994-L1010)

Installation copies fonts and runs fc-cache before recording ownership. A copy/cache exception or crash can leave partially installed fonts without an install record; there is no rollback transaction. Uninstall removes files before persisting the revised ledger. Back up both data JSON files and font collections, not just the canvas. Autosave is debounced and ignores request failures, so manual JSON exports remain advisable; browser closure is not proof that the last save persisted. In-memory undo is not crash recovery. [Install ordering](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase.py#L756-L828), [autosave](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/static/app.js#L385-L398)

Font acquisition also drops non-font archive files, including license/readme notices; the Google Fonts fetcher selects only font files. Preserve source licensing material separately before distributing fonts or font-bearing SVGs.

## Platform, Installation, and Updates

The README names Python 3, Chromium, and Fontconfig. The actual launcher additionally invokes common Linux shell tools including curl, readlink, sha1sum, cut, seq, and sed; it hardcodes /usr/bin/python3. There is no declared minimum Chromium/Python compatibility matrix. Omarchy is a target, not a required framework.

install.sh writes a per-user launcher symlink, desktop file, and icon, and changes script executable bits. It does not install OS dependencies or request root. It can overwrite an existing launcher/menu entry at those names. The launcher remains tied to the source checkout: moving/deleting it breaks the link. There is no signed release channel, pinned application updater, packaged dependency resolution, or uninstall script. Updating the checkout changes the executed code; review and pin revisions. Launcher PID files are checked for process existence rather than full process identity, so stale/reused PID behavior deserves hardening. [Installer](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/install.sh), [launcher](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/typecase)

## License, Dependencies, Tests, and Maturity

No root LICENSE or application-wide grant was present; GitHub metadata reports license null. The MIT notice under static/vendor/harfbuzz applies to that component. The vendor version file identifies harfbuzzjs 1.6.4, but no reproducible vendoring recipe, dependency lockfile, or upstream-byte verification was established. This review does not certify the WASM supply chain or vulnerability status. [Vendor notice](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/static/vendor/harfbuzz/LICENSE), [version](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/static/vendor/harfbuzz/VERSION.txt)

Public GitHub metadata retrieved 2026-11-10 reports creation at 06:50:02Z, last push 06:50:08Z, 2 stars, 0 forks, and 0 open issues; releases endpoint returned an empty array. No checked-in CI workflow was found. This is an extremely new public project, not a maintenance track record. Shallow acquisition does not establish historical development depth. [Metadata](https://api.github.com/repos/iretonsean/typecase), [releases](https://api.github.com/repos/iretonsean/typecase/releases)

**Executed:** 20 tests from ParseSource, Allowlist, StateFiles, ZipLimits, and GoogleLinkTests, all passed. They used disposable synthetic state/ZIP fixtures in a cleared-environment Bubblewrap sandbox without network or host home access. One test emitted an unclosed-file ResourceWarning, not a test failure. An initial sandbox mount setup failed before any tests ran; the disposable-copy invocation succeeded.

**Not executed:** Full unit suite, font parsing against host fonts, install/uninstall integration, HTTP/browser security checks, rendering/outlining/export fidelity, and CDP E2E. The supplied E2E driver expects a separate Chromium debugging session and performs a live GitHub font fetch, so it was outside this review's execution scope. Existing tests are useful evidence of intent, not independent proof that all workflows pass. No install/config/desktop changes, accounts, model downloads, or paid calls were made. [Unit tests](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/test_typecase.py), [E2E driver](https://github.com/iretonsean/typecase/blob/082a60ea78944f6e9e116719271a192a84c236fb/tests/e2e-drive.mjs)

## Comparison

| Need | Typecase | Established alternative |
|---|---|---|
| Browse/manage Linux fonts | Combined library, preview downloads, scoped uninstall | [Font Manager](https://github.com/FontManager/font-manager): dedicated Linux font-management project |
| Vector typography and editable outlines | Small integrated page canvas with custom tools | [Inkscape](https://inkscape.org/): broader vector-editing and interchange workflow |
| Multipage publication/layout | Basic single-artboard composition | [Scribus](https://www.scribus.net/): dedicated desktop publishing |
| Edit actual font designs/tables | Inspects and consumes fonts; not a font authoring system | [FontForge](https://fontforge.org/): dedicated font editor |

These are workflow comparisons, not benchmark results or fresh audits of the alternatives. Typecase's advantage is cohesion and a small inspectable implementation; its downside is newly public, unlicensed application code and a much narrower reliability/compatibility record.

## Adoption Gate

Before relying on it: obtain a clear application license; test fonts/export fidelity on the intended platform; preserve font license notices; harden install rollback and autosave error reporting; pin validated download addresses and add global resource limits; and establish repeatable CI/release provenance. For now, study or evaluate with disposable documents and trusted, appropriately licensed fonts—not irreplaceable production work.

---

**Attribution:** iretonsean/typecase. Application license not specified; bundled harfbuzzjs MIT notice retained upstream. Analysis cites public source at the exact reviewed revision; no application code extracted.
