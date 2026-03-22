# ArcDLP

*Source: https://github.com/archisvaze/arcdlp | License: MIT | Author: Archis | Reviewed: 2026-03-22*

## Rating: 🔥🔥🔥

## One-liner
A polished Electron GUI wrapper for yt-dlp — paste URL, pick quality, download. No frameworks, no nonsense.

## What It Is
Desktop video downloader (macOS/Windows/Linux) that puts a clean UI on yt-dlp. Supports YouTube, Vimeo, Twitter/X, SoundCloud, and the full yt-dlp site catalog (~thousands). Bundles yt-dlp + ffmpeg — zero dependencies for the end user.

**Key features:**
- Single video and playlist downloads
- Quality presets (4K → 240p) + MP3 extraction
- Sequential download queue with per-item progress, retry, cancel
- YouTube sign-in for age-restricted/private content (cookie auth via built-in browser)
- Download history
- System notifications on queue completion
- Light/dark mode, macOS vibrancy

## Architecture
Vanilla JS throughout — intentionally no frameworks. Two runtime dependencies only: `electron-store` (settings/history) and `ffmpeg-static` (bundled ffmpeg). yt-dlp does all the heavy lifting.

```
src/
├── main/
│   ├── main.js       # Electron main process, IPC, window
│   ├── ytdlp.js      # yt-dlp spawn/parse/download
│   ├── queue.js      # Sequential queue with per-item state
│   ├── cookies.js    # YouTube cookie auth, Netscape format export
│   └── updater.js    # GitHub Releases API update checks
└── renderer/
    ├── index.html
    ├── renderer.js   # All UI logic and state
    └── index.css
```

**Playlist approach:** `--flat-playlist --dump-json` streams items one at a time → user selects → queues batch. Smart — doesn't pull full metadata until needed.

**Design principles (from the codebase, not marketing):**
- Keep it simple — 30 lines beats a library
- Resilience first — one failure never kills the queue
- Explicit actions only — no auto-fetch, no auto-retry
- Let yt-dlp do the work — don't compete with it
- Multi-site compatibility — never assume YouTube behavior

## Honest Assessment

**Strengths:**
- Genuinely simple codebase (vanilla JS, minimal deps) — easy to fork and modify
- Solid queue implementation — per-item state machine, failures are isolated
- Good contributor docs — roadmap is honest about what's missing
- Bundles everything — yt-dlp + ffmpeg in the binary, no user setup pain

**Weaknesses:**
- Electron — it's a 200MB binary to wrap a CLI tool. Fine for end users, heavy by principle.
- No subtitles, no SponsorBlock, no rate limiting, no format filtering yet — all on the roadmap but absent
- Queue has no upper bound (known item in their own cleanup list)
- Playlist detection is conservative — YouTube and SoundCloud only

**Known cleanup items (self-documented):**
- `video:fetch` returns 50-200KB raw JSON in production (dev-only oversight)
- Queue `_items` has no cap
- Log type detection is greedy (`includes('complete')` catches "incomplete")

## Relevance
Low for agent/AI work. High for anyone who wants a clean, self-hostable video downloader without the yt-dlp CLI. The codebase is a good template for "simple Electron wrapper over a CLI tool" — the queue.js and ytdlp.js modules are worth stealing as patterns.

**For Marcos (Parkinson's project):** If he needs offline video content (lectures, tutorials), this is the cleanest way to get it. No cloud, no accounts, files stay local.

## License
MIT — take whatever you want.
