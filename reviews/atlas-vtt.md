# Atlas VTT (atlas-vtt/atlas-vtt)

**Repo:** https://github.com/atlas-vtt/atlas-vtt (moved from `ByteMirror/atlas-vtt`; the old URL redirects)  
**License:** AGPL-3.0-only, with a section-7 exception that allows combining it with Obsidian. You can study it, run it, and document its patterns, but a modified version you distribute or serve over a network has to ship its full source under the AGPL. Releases up to 0.1.6 were PolyForm Noncommercial. Icons are from game-icons.net (CC BY 3.0) and the starter class tokens are CC BY 4.0. Libraries are listed in a 125 KB `THIRD_PARTY_NOTICES.md`.  
**Reviewed:** 2026-10-03 (commit `08d79da`, release 0.5.0, 0.5.1-beta.0 tagged)  
**Stack:** TypeScript Obsidian plugin (desktop only, Obsidian ≥ 1.8.7). PixiJS v8 + pixi-viewport for the map canvas, React 19 + Radix + framer-motion for the UI, zustand + immer + zundo for state and undo, three.js for 3D dice, howler for audio, jszip for collection export. Vite build, Vitest (unit + Playwright GPU projects). There's also a small Python stdlib issue-reporting service.  
**What it is:** An offline, system-agnostic virtual tabletop that runs inside an Obsidian vault. It has battle maps with square/hex grids (with auto-detection), tokens, fog of war, experimental dynamic lighting with walls and doors, dice, initiative, a separate player window for a second screen, and Obsidian notes pinned to the map. Everything is stored as files in the vault.

---

## Verdict

✅ **Deploy candidate, for GMs who already run their campaign in Obsidian and play in person or share a screen. It's unusually disciplined for a 13-day-old public repo. There's no networked multiplayer, though, so it doesn't replace Foundry or Owlbear Rodeo for remote groups.**

What's good:
- **Data ownership is real.** Scenes are `.atlasmap` files, and asset metadata lives in `atlas-vtt/.atlas-data/` inside the vault. A reconciler (`AssetService.reconcileWithVault`) keeps the index in sync with renames, moves and deletes made outside Obsidian (file manager, sync, git). That last part is what makes "it's just files" true in practice.
- **Serious geometry.** Hex grids use axial coordinates with cube rounding. Grid auto-detection is a propose → fit → verify pipeline (power spectrum, then edge-profile lattice search, then robust least squares with Tukey weights, then a chance-corrected support score with a manual fallback). Universal VTT imports (`.dd2vtt`/`.uvtt`/`.df2vtt`) bring in walls, doors and lights.
- **Untrusted input is handled carefully.** The UVTT parser is pure, reads only own properties, has hard limits (150 MB, 20k walls, 2k lights, 4,096 cells a side) and sniffs the image type from bytes. The only dynamic-code path (`new Function` for Fantasy Statblocks layout callbacks) sits in one documented file with a stated trust boundary.
- **Good engineering hygiene.** About 4,250 test cases in 601 test files, including 78 GPU tests that run in real Chromium. Every GitHub Action is SHA-pinned, CI permissions are scoped, release builds carry provenance attestation, and the lint gate matches Obsidian's community-directory scan.

What gives pause:
- **Local play only.** The "player view" is a second Obsidian window for a second monitor or a screen share. The code has no WebRTC or WebSocket transport.
- **One person wrote nearly all of it.** One contributor accounts for 136 of the listed commits. There's a 157 KB `CLAUDE.md` of design rules, and the maintainer runs Claude Code PR reviews. That's not a problem in itself, but the bus factor is 1 and the code grows fast (≈122k lines of non-test TS/TSX plus 24k lines of SCSS).
- **Young.** It went public on 2026-09-20 and four minor releases came out in about two weeks. There are 105 open issues and dynamic lighting is still marked experimental.

## What It Is

Atlas VTT is the author's bachelor's-thesis project. It turns an Obsidian vault into a VTT workspace. You import a map image, align a grid (by hand or with auto-detect), drop tokens from collections, reveal fog as the party explores, and push a player-safe view to a second window. Markdown notes, or other Atlas maps, can be pinned to points or linked to whole hexes, then read and edited in a floating panel without leaving the map. Creature notes can be linked through the optional Fantasy Statblocks plugin, and dice notation like `2d8+2` in statblocks becomes clickable rolls.

It's system-agnostic, with presets per collection (game-system presets include Cairn and Draw Steel), per-collection dice rules (crit rules, exploding dice), initiative rules, and up to six token resources (HP-style bars).

## Stack

| Layer | Choice |
|-------|--------|
| Host | Obsidian desktop plugin (Electron), `isDesktopOnly: true` |
| Rendering | PixiJS v8 (its own copy; Obsidian ships v7 globally), pixi-viewport, pixi-filters |
| UI | React 19.1, Radix primitives, framer-motion, lucide icons, SCSS (older code uses Tailwind 3, scoped) |
| State | zustand 5 + immer, zundo for undo/redo, a custom EventBus |
| 3D | three.js (dice) |
| Audio | howler |
| Storage | Vault files: `.atlasmap` scenes, JSON records per collection folder, hidden `.atlas-data` index and thumbnails |
| Image pipeline | Web workers started from a blob URL, 1 GiB decode budget, WebP output, maps capped at 8192 px a side |
| Tests | Vitest 4 (`unit` project with jsdom, `gpu` project via Playwright Chromium) |
| Side service | Python stdlib HTTP + SQLite issue reporter behind a reverse proxy |

## Key Features

### Maps and grids
- Square and hex grids (pointy and flat), with the same size convention as Foundry and Owlbear (flat-to-flat), so a size-1 token is the same diameter on either.
- Auto-detection proposes from the spectrum, fits by averaging the image along each candidate cell edge (so faint lines add up), and only accepts grids whose support clears a threshold on the *weakest* edge direction. Below that, it falls back to manual alignment.
- Hex numbering (`0304` column-row or sequential) is drawn as mip-free BitmapText.
- Maps over 8192 px are scaled down, and the card says so.

### Tokens, encounters, initiative
- Collections hold tokens, encounters, player groups, characters and statblocks as files in per-collection folders. Moving an asset between collections moves its files.
- Initiative supports sides and per-collection rules. Combatants are added explicitly.
- Token art comes from a crop/frame editor and batch imports, with conversion running in parallel in workers.

### Fog, lighting, player view
- Fog of war with an "explored memory". Dynamic lighting (walls, doors, lights) is experimental and off by default.
- UVTT import maps the file's walls, doors and lights onto the scene's grid. Open portals are treated as windows. With baked lighting, lights are imported switched off.
- The player view is a separate window that hides GM-only layers.

### Notes on the map
- Pin a note or another map to a point, or link a note to a hex so it stays put when the grid is realigned.
- Note previews use a detached Obsidian leaf, so you get full editing without disturbing the workspace.

### Quality-of-life
- Undo/redo where one gesture is one step (`beginHistoryTransaction`/`endHistoryTransaction` around drags).
- Customisable map hotkeys that work on any keyboard layout, a music player that plays vault audio, widgets (counters/timers) scoped per scene or per collection, and an in-app changelog.

## Architecture

`main.ts` registers the views (`atlas-view`, `dashboard-view`, `player-view`). `src/app/` is split by domain (grid, pixi, fog, lighting, initiative, dice3d, import, services, stores, react). A `PixiRendererOrchestrator` drives specialised renderers (`TokenRenderer`, `FogOfWarRenderer`, `TokenUIRenderer`, …) that subscribe to store slices. Undo works for free because renderers react to the `objects` reference changing.

The repo's own rule is "files under 200–300 lines". 53 of 1,094 source files are over 300, and the biggest are `TokenRenderer.ts` (2,019), `storeFactory.ts` (1,598) and `AssetService.ts` (1,543). That's typical drift for a fast-moving codebase, not a red flag.

The `CLAUDE.md` is effectively the architecture document. It covers hex geometry, vault reconciliation, undo semantics, widget scoping, the image worker pool, UVTT import and UI design tokens (concentric radii, panel motion), in enough depth that it doubles as a design spec.

## Security

- **No secrets in the repo.** A grep for `sk-`, `AKIA` and `ghp_` patterns found nothing. The plugin holds no GitHub credential. The issue reporter reads its token from systemd `CREDENTIALS_DIRECTORY`.
- **Dynamic code:** a single `new Function` in `statblock/layoutCallbacks.ts` that runs Fantasy Statblocks layout callbacks. These come only from that plugin's stored layouts, never from note content or map files. `PRIVACY.md` warns that imported community layouts are trusted code. No `eval`, `innerHTML =`, `dangerouslySetInnerHTML` or `child_process` showed up in `src/`.
- **Network:** offline by default, with no telemetry. It only goes online to fetch remote images you explicitly reference, and for the opt-in "Submit report". That posts to a reporting endpoint run by the author, which files a public GitHub issue for you.
- **Issue reporter service** (`services/issue-reporter`, ~230 LOC):
  - Strict field validation and length caps. `@` mentions are neutralised so it can't be used as an anonymous notification relay.
  - Request IDs must be UUIDv4. Duplicates are caught with a SQLite `BEGIN IMMEDIATE` plus a content digest, and an uncertain GitHub response is never re-posted automatically.
  - Rate limits are 3 per client per hour and 100 globally per day. Clients are keyed by a daily-rotating HMAC of the IP, with IPv6 collapsed to /64, and no raw IPs are stored.
  - It binds to loopback, has a 16-connection semaphore and disables access logs.
  - It trusts the right-most `X-Forwarded-For`, which is correct only behind the documented single proxy (Traefik).
  - Unverified risk: the target repo is hard-coded as `ByteMirror/atlas-vtt`, which now returns a 301 to the transferred repo. Python's `urllib` won't replay a POST across a 307/308. If GitHub answers the authenticated create-issue call with a redirect, submissions will fail as "could not be confirmed". That's worth updating to the new path either way.
- **CI:**
  - Every action is pinned to a commit SHA, `persist-credentials: false` is set where it matters, and top-level permissions are scoped (`{}` on PR review).
  - The `/review` workflow is gated on the maintainer's numeric account ID. It runs Claude Code with read-only tools, a deny list on `/proc`, `/home` and `/etc`, no hooks and no MCP, and PR code is never executed.
  - The CLA workflow uses `pull_request_target` with `contents: write` through the pinned contributor-assistant action. That's the standard pattern, but it's a high-privilege trigger to keep an eye on.

## Maturity

- 446 stars, 45 forks and 105 open issues as of 2026-10-03. Created on GitHub 2026-09-20, last push 2026-10-03. The copyright line says 2025–2026, so private development came first.
- Releases 0.4.0 → 0.5.0 between 2026-09-28 and 2026-10-02, with a beta channel through BRAT. It's listed in Obsidian's community plugin directory.
- Code size: ~95k LOC `.ts` + 27k `.tsx` (non-test), 24k SCSS, and ~73k LOC of tests.
- The changelog is generated from fragments and checked in CI. Several outside contributors are credited in 0.5.0.

### Validation on 2026-10-03

- `git clone --depth=1` at `08d79da`, plus GitHub API metadata (stars, releases, contributors, languages).
- `python3 -m unittest discover -s services/issue-reporter` gave **10 tests, all passed** (Python 3.13). These cover dedup across restarts, rate limiting with no raw IP in the database, the oversize/invalid-category rejection, and the HTTP adapter.
- **Not run:** the Vitest unit and GPU suites, the typecheck and the build. `npm ci` isn't available in this environment. The test count (~4,257 `it`/`test` calls in 601 files) comes from a static count, not a run.
- Security greps (secret patterns, dynamic code, DOM injection, child processes) are covered above. Reading the GitHub endpoint for `ByteMirror/atlas-vtt` returns a 301 to the new repository ID.
- I didn't load the plugin in Obsidian, so UI and feature claims come from the README, the changelog and the code.

## Comparison

| | Atlas VTT | Foundry VTT | Owlbear Rodeo | Dungeon Revealer | Obsidian Initiative Tracker / Leaflet |
|---|---|---|---|---|---|
| Model | Obsidian plugin, offline | Self-hosted server, paid license | Hosted web app | Self-hosted Node web app | Obsidian plugins |
| Remote players | No (second window only) | Yes | Yes | Yes (browser) | No |
| Data | Vault files | Server DB + files | Vendor cloud | Server files | Vault files |
| Grids / auto-align | Square + hex, auto-detect | Square + hex, manual | Square + hex | Fog-focused | Leaflet maps, no tactical grid |
| Lighting / walls | Experimental, UVTT import | Mature | Via extensions | No | No |
| Notes integration | Native (pins, hex links, inline edit) | Journals | Minimal | No | Native |
| License | AGPL-3.0 | Proprietary | Proprietary | MIT | MIT |

If your prep already lives in Obsidian and the table is physical (TV or projector plus a GM laptop), Atlas is the most integrated option. If you need online play, it isn't a contender yet.

## Self-Hosting Notes

- Install it from Obsidian's Community plugins (desktop only), or put `main.js`, `manifest.json` and `styles.css` from a release into `.obsidian/plugins/atlas-vtt/`. Betas come through BRAT.
- Everything goes into an `atlas-vtt/` folder in the vault, plus a hidden `.atlas-data/`. Vault sync tools and git work because the reconciler handles moves made outside Obsidian. Images are converted to WebP, so the vault stays reasonably small.
- Remote image URLs are fetched when used. To stay fully offline, keep assets in the vault.
- The issue reporter is optional and talks to the author's server. Use "Copy report" if you'd rather not send anything.
- Building from source needs Node 22. Note that `npm run build` copies the output into local test vaults if they exist.

## Reusable Patterns

- **Grid detection as propose → fit → verify.** Let the spectrum only *propose*, fit by profiling candidate edges (one vote per edge so heavy ink can't dominate), and solve size and offset jointly with least squares (it's linear because every grid point is `origin + size × lattice coordinate`). Then accept based on chance-corrected support in the *weakest* direction. This works for any "find the lattice in a noisy image" problem.
- **Files-first app state with a reconciler.** Run a debounced check one second after the vault goes quiet. It reads the disk first, then mutates the index synchronously, and relinks moved files by name and relative path. New files are written under an exclusive lock, so the reconciler never adopts them twice.
- **One gesture = one undo step.** Wrap pointer-down → pointer-up in a history transaction, with an explicit abandon path for cancelled gestures.
- **Anonymous issue reporting without leaking a token.** Use a tiny relay with UUID request IDs, a content-digest dedup, no automatic re-post on an uncertain response, a daily-rotating HMAC on the IP for rate limiting, and neutralised mentions.
- **Safe LLM PR review in Actions.** Trigger on maintainer comments only (matched by numeric ID). Give the model a snapshot plus diff with read-only tools, a deny list on `/proc` and home, and structured JSON output that a trusted script from the default branch validates before posting.

---

**Attribution:** atlas-vtt/atlas-vtt (Fabian Urbanek), AGPL-3.0-only
