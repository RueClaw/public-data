# Lastbook (Immortal-Protocols/lastbook)

**Repo:** https://github.com/Immortal-Protocols/lastbook
**License:** MIT original code/documentation; GPL-covered bundled components and separately licensed library/model/map content.
**Reviewed:** 2026-11-17 (UTC)
**Revision:** `b7300c70129058918af34bacf692916eab654ecc` (main; desktop engine, bridge, setup, retrieval, packaging, tests and documentation; iPad documentation sampled, not a full Swift audit).
**Verification:** Static source review only. No application/tests/builds executed; no installers, packs, models or datasets downloaded; no device access or live service probes.
**Stack:** Python, SQLite/FTS5, plain JavaScript/CSS, native WebKit/WebView2 shells, libzim/PDFium, optional llama.cpp and Windows ONNX retrieval.
**What it is:** An offline survival and rebuilding reference library with guides, manuals, videos, encyclopedias, maps and source-linked local AI—not a permanent-storage protocol or encrypted notebook.

## Verdict

⚠️ **Interesting — useful offline-library engineering; pilot as a reference aid, not a sole emergency authority.** The native no-listening-port bridge, bounded read-only AI tools and defensive pack downloader are substantial implementations. But the repository is extremely young, the actual library is outside it, citation checks do not verify answers, and recovery/privacy claims need qualification. Keep independently readable backups and verify important advice against authoritative, current sources.

## What It Is

Lastbook is maintained by Immortal-Protocols, with original-code copyright credited to Lastbook contributors. Its canonical repository describes an offline knowledge library for survival and rebuilding. The desktop sidebar combines Videos, Map and Chat; structured topic guides lead readers to particular pages and explicitly record gaps and source limitations.

The source tree is the application and its builders, not the promised hundreds of gigabytes of reference material. Library packs, map databases, model weights, release manifests and signing material are absent. Consequently this review can assess routing and safety machinery, but not pack completeness, redistribution permissions item by item, medical/engineering accuracy, or real-world offline usefulness. The app can use a pre-existing data folder or pack ZIP, making downloads optional when someone already has a compatible copy. [E1, E2]

## Stack and Architecture

| Layer | Implementation |
|---|---|
| Desktop | Python entry point and platform-specific Cocoa/WebKit, WinForms/WebView2 and GTK/WebKitGTK shells |
| Transport | In-memory HTTP-shaped handler bridge; custom URL handling, streaming/buffering and bounded work lanes |
| Library | Catalog JSON, ordinary media/documents, ZIM archives, SQLite FTS5/BM25 and map/address databases |
| Retrieval | Keyword search; optional local BGE ONNX embeddings, SQLite chunk metadata and append-only float16 vectors, reciprocal-rank fusion |
| Generation | Optional pinned Gemma GGUF via a pipe-only llama.cpp runner; source/server code also supports a loopback OpenAI-style endpoint |
| UI/state | Plain local HTML/CSS/JS; chat history in webview/browser localStorage; filesystem settings, caches and logs |
| Distribution | PyInstaller on Mac/Windows, Ubuntu package on Linux; separate Swift iPad preview |

`app/main.py` selects the data root before importing the engine, applies pending setup work, initializes `server.py`, and hands its handler to the platform bridge without calling the network server. `server.py` separately supports browser/LAN serving. This reuse is elegant, but desktop and server security claims must not be conflated. The 2,163-line server also mixes library routing, map geometry, searches and HTTP policy; that is convenient reuse rather than strongly separated services. [E3, E4]

## Key Features and Evidence

### Guides with traceable limits

The topic schema organizes urgent choices, preparation, learning routes and warnings. References use catalog IDs and one-based PDF file pages; missing pack content is filtered out before display. This is more useful than a raw directory dump. It is not proof that every guide paraphrase is correct: the cited documents were not downloaded or checked here. Geographic detail is primarily US/state-oriented; additional regional proposals in docs are not equivalent to shipped global datasets. [E2, E4]

### Bounded local retrieval and AI

Retrieval preserves document/page or video-time provenance. Optional semantic search is incremental and local; release requirements omit ONNX on Mac and Linux, so Windows has a richer retrieval path. The assistant starts with retrieval, exposes library/map reading tools rather than a shell or arbitrary URL fetch, limits tool rounds to two, bounds message/context sizes, and checks returned citation IDs against sources actually consulted. Local model prompt rendering distinguishes template tokens from plain document text. [E5]

These are valuable boundaries, not factual verification. Final checks establish that a citation key and page are eligible, not that a sentence follows from them. Retrieved text is inserted into model context, including system-role search context; semantic prompt injection and hallucination remain possible even without executable tools. Streamed answer text can precede final citation validation. For medical, water-treatment, structural or electrical decisions, read the underlying source and seek qualified help rather than treating a numbered citation as certification.

### Downloads engineered for interruptions

The downloader rejects URL credentials, non-HTTPS schemes and non-443 product ports; restricts initial/redirect hosts; ignores system proxies; uses a bundled CA-root set; checks size and SHA-256; and resumes partial files with explicit Range/ETag handling. ZIP intake rejects unsafe paths, links, case collisions and unacceptable sizes before unpacking. Existing bundled manifest entries retain pinned addresses/hashes when remote metadata is merged. These are concrete strengths. [E6]

The trust is still publisher/TLS-based: the inspected manifest flow has no independent signed-manifest verification. Remote metadata can add new IDs, and trusted roots are CA roots, not exact server public-key pins. Root/host changes can also make future downloads fail until software is refreshed. `Download.run()` accepts an already finished destination of the expected size without rehashing it on that fast path; repair/model checks are separate, so “every file is always reverified” would overstate the implementation.

## Security, Privacy and Authority

**Desktop bridge:** POSTs require a fresh launch-specific secret key as well as allowed origin/content type. The top frame receives the key; saved pages do not. URL/frame policy, bounded lanes, body caps and constrained request headers reduce hostile-document authority. Library responses get no-script CSP/sandbox rules; saved-page rewrites improve legibility but explicitly rely on CSP for security. Content paths are allowlisted and real-file checks constrain traversal. This is considerably stronger than merely hiding a localhost port. It does not sandbox all native PDF, ZIM, media or model parsers against malformed files. [E3, E4]

**Network claim caveats:** Opening setup itself starts a small manifest fetch; pressing Start is not the only trigger, despite the README's simplified “two uses” wording. More importantly, `assistant.py` contains a loopback model fallback and status requests when the local runner is unavailable; `app/main.py` enables local AI but does not remove that fallback, and the inspected Linux build copies the module. The URL is limited to loopback, redirects/proxies are blocked, and this does not create an internet listener. Still, a separately running local model gateway could receive questions and relay them elsewhere: “no cloud credentials in Lastbook” is not proof of that gateway's privacy. Packaged-binary behavior was not verified. [E3, E5, E6, E10]

**Server/LAN mode:** Default bind is loopback. Explicit LAN mode binds all IPv4 interfaces and uses one persistent random access key, exchanged from a URL into an HttpOnly/SameSite cookie. It is plain HTTP, with no TLS and no individual users/roles or tenant isolation. Loopback clients bypass the LAN key; setup and update routes additionally require loopback. Host and Origin checks help browser attacks, but are not local-process authentication. Shared LAN users share engine/model authority and capacity; an access link is a bearer credential, not end-to-end encryption. Do not expose this mode to the internet or an untrusted LAN. [E4]

**At rest:** No application encryption/key-management system for chats, library files, caches or logs was identified. LocalStorage, data folders and exported Markdown are plaintext from the application's perspective. Windows-created install folders receive explicit ACLs; Unix creation follows filesystem permissions/umask. Use OS account isolation and disk encryption as appropriate. Logs can contain operational paths and requests; the app rotates its log at 5 MiB with three backups. Absence of telemetry is a design claim supported by controls, not a packet-capture result from this review. [E3, E7]

## Durability, Retention, Export and Recovery

| State | Persistence and implications |
|---|---|
| Library/maps/model | Ordinary data-root files; portable by copying a compatible complete tree, not dependent on an account or perpetual service |
| Setup | Partial downloads, job/pending records, staging folder and old-library directories support pause/resume and rollback |
| Chat | Kept by default in localStorage, up to 60 chats; persistence errors are swallowed, so quota failure can look successful |
| Export/delete | Chat exports Markdown with source links; history can be disabled or all chats deleted; exports and backups are separate retained copies |
| Search derivatives | SQLite metadata and vectors; interrupted vector tail is reconciled to committed chunk rows; inactive historical rows are not secure erasure |
| Device/browser state | Webview profile and settings locations vary by platform; copying only library-data is not a full user-state backup |

The source's strongest durability wording is too absolute. `install.switch()` first moves models/address indexes into staging, then renames the old target aside and the new library into place. Ordinary rename errors have restoration logic, but these are **multiple filesystem mutations**, not one atomic transaction. The pending record is marked switched only afterward. A process/power interruption between renames and journal update can therefore leave a layout that requires manual recovery; no crash-window proof was run here. Failure of the old-target rename can also occur after carry-over already moved personal files. [E7]

Furthermore `is_library()` checks existence of `library-data/catalog.json`, not successful parsing or all engine startup operations. `apply_pending()` uses that test for its rollback decision; a later `server.init()` failure is not equivalent to that check. The happy-path rollback restores carried-over files, but a retained old folder is not necessarily a self-contained backup because models/indexes may have moved out of it. Do not equate “old folder retained” with complete disaster recovery.

Recommended operational practice—not a tested built-in feature—is to stop the app, back up the complete data root plus platform settings/webview state, retain original installers and pack manifests, and test restoration on a spare offline machine. Prefer explicit Markdown exports for conversations, since browser storage is origin/profile-bound and not a cross-platform interchange format. Exported source URLs still depend on compatible local serving and library IDs. No complete automated cross-platform backup/restore or chat-import workflow was established in this review. Removing the Linux package intentionally leaves downloaded data and settings; deleting chat history is not a wipe of exports, profiles, logs or old libraries. [E1, E7]

“Offline” means independence after preparation—not permanence, replication, bit-rot repair, guaranteed future OS compatibility or correctness of historical information.

## Providers, Costs and Deployment Fit

There is no mandatory SaaS login, API key or per-token provider bill in the inspected local workflow. Setup downloads from Lastbook infrastructure and Hugging Face; operators still pay for bandwidth, disk capacity, backup media, power and capable hardware. The pinned optional GGUF is 16,947,541,728 bytes (about 17 GB); the README estimates about 18 GB for model/context plus reserve. Actual fit is measured through the runner, not guaranteed by a marketing RAM number. Keep a usable keyword-only library when AI is unavailable. No inference latency or fit tests were performed. [E1, E5]

README release claims are Mac 1.1.10 (Apple Silicon/macOS 14+), Windows 1.1.8 (64-bit Windows 10+) and Ubuntu 1.1.9 (24.04 x86_64). Linux testing is described as WSL2/CPU; native GPU and other distributions are not qualified. Builds install pinned direct Python dependencies and compile/package native components. Version pins are useful, but the displayed requirements are not a full hash-locked transitive dependency closure. Build scripts have real output deletion/copy/install behavior; inspect and build only in a disposable environment. Signing claims, installer signatures, binary-to-source correspondence and vulnerability status were not independently checked. Update checking reports availability; it does not automatically install software. [E1, E8]

The iPad tree is explicitly a development preview, not an App Store/TestFlight release. Its documentation reports one physical M1/16-GB iPad AI test, no ZIM reader yet, missing downloadable H.264 compatibility packs, and untested end-to-end Medium/All installs. It shares data formats, not full feature parity; it was not audited here as a second complete implementation. [E9]

## License, Tests and Maturity

MIT covers Lastbook's original code/docs with notice preservation. Distributed bundles include python-libzim/libzim and other GPL-covered components; shipping a binary bundle is not simply an MIT-only redistribution. The notices distinguish checked package licenses from upstream assertions. The enormous library, map data and model artifacts retain their own terms, absent from this checkout; no permission to redistribute everything follows from the root LICENSE. No source code was extracted for republication. [E8]

At retrieval on 2026-11-17, unauthenticated GitHub metadata reported 734 stars, 80 forks and 31 open issues/PRs combined; repository creation was 2026-11-12, last push 2026-11-17 04:32 UTC. The reviewed commit has that same UTC timestamp. The releases API returned an empty list, consistent with website-hosted release claims rather than proving no releases exist. Popularity over five days is not field reliability.

The tree contains meaningful unittest suites for setup interruption/ZIP guards, bridge boundaries, data-root selection, update checks, address/topic search and shipped content, plus platform UI/integration helpers. There is no checked-in `.github/workflows` directory at this revision. Some tests require real libraries, local HTTPS fixtures, platform tooling or device-driving scripts. None was run under this task's restrictions; there is no independent passing count or CI-success claim here. The reviewed recovery tests do not justify a universal power-loss guarantee. [E10]

## Comparison

| Option | Prefer it when | Lastbook's distinction/tradeoff |
|---|---|---|
| [Kiwix](https://kiwix.org/) | You primarily need portable offline encyclopedias/ZIM access | Lastbook adds curated urgent guides, mixed media, maps and optional source-linked chat, with a larger bespoke application surface |
| [Internet-in-a-Box](https://internet-in-a-box.org/) | You want a community/shared offline content appliance | Lastbook emphasizes a single native desktop and optional simple LAN sharing rather than a broad appliance ecosystem |
| [Organic Maps](https://organicmaps.app/) | You principally need a dedicated offline map/navigation app | Lastbook integrates reference/map/resource lookup; do not assume equivalent navigation, current conditions or global detail |
| Plain PDFs/videos plus verified backups | Longevity and independently readable reference copies matter most | Less integrated discovery, but less dependence on one app, model runtime and browser profile |

These are category comparisons, not head-to-head benchmarks. For emergency preparation, combine independently readable authoritative documents and backups with Lastbook's discovery interface; do not replace them with AI answers.

## Verification Limits and Next Acceptance Gates

This review checked source, tests-as-text, manifests/build scripts and public GitHub metadata. It did not run the program, install dependencies, inspect release binaries, acquire the real corpus, evaluate model quality, validate map freshness, audit all native dependencies or examine the full iPad implementation.

Before relying on it: demonstrate a fully disconnected cold start with your actual pack; verify a sample of safety-critical source/page references; test full backup restoration and chat exports; inject failures at each carry-over/rename/journal boundary in an isolated synthetic fixture; and verify the exact installed binary's network behavior and signature. For LAN use, establish a trusted network and an explicit access-key rotation procedure. These are proposed acceptance gates, not completed tests.

## Source Evidence

All source links below are pinned to the reviewed SHA.

- **E1 — Identity, scope and release claims:** [README](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/README.md).
- **E2 — Guide contract:** [content/SCHEMA.md](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/content/SCHEMA.md), [topics](https://github.com/Immortal-Protocols/lastbook/tree/b7300c70129058918af34bacf692916eab654ecc/content/topics).
- **E3 — Desktop and bridge:** [app/main.py](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/app/main.py), [app/bridge.py](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/app/bridge.py).
- **E4 — HTTP, library/map and content boundaries:** [server.py](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/server.py), [engine/saved_pages.py](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/engine/saved_pages.py).
- **E5 — Retrieval and model flow:** [retrieval.py](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/retrieval.py), [assistant.py](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/assistant.py), [llm_local.py](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/llm_local.py).
- **E6 — Acquisition trust:** [download.py](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/engine/setup/download.py), [manifest.py](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/engine/setup/manifest.py).
- **E7 — Durability:** [install.py](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/engine/setup/install.py), [setup API](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/engine/setup/api.py), [chat.js](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/web/chat.js).
- **E8 — Dependencies and rights:** [LICENSE](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/LICENSE), [third-party notices](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/THIRD_PARTY_NOTICES.md), [packaging](https://github.com/Immortal-Protocols/lastbook/tree/b7300c70129058918af34bacf692916eab654ecc/packaging).
- **E9 — iPad status:** [mobile/ipad/README.md](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/mobile/ipad/README.md).
- **E10 — Tests and Linux packaging:** [app/tests](https://github.com/Immortal-Protocols/lastbook/tree/b7300c70129058918af34bacf692916eab654ecc/app/tests), [Linux builder](https://github.com/Immortal-Protocols/lastbook/blob/b7300c70129058918af34bacf692916eab654ecc/packaging/linux/build_app_linux.sh). [Repository metadata](https://api.github.com/repos/Immortal-Protocols/lastbook), [releases metadata](https://api.github.com/repos/Immortal-Protocols/lastbook/releases).

---
**Attribution:** Immortal-Protocols/lastbook and Lastbook contributors; MIT original code/documentation, separate component/content terms. Independent analysis; not an endorsement or safety certification.
