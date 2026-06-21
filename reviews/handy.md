# Handy (cjpais/Handy)

**Repo:** https://github.com/cjpais/Handy
**License:** MIT - permissive license, fine to fork, adapt, and extract from with attribution
**Reviewed:** 2026-06-20
**Stack:** Rust, Tauri 2, React, TypeScript, Tailwind CSS, whisper-rs/transcribe-rs, ONNX, SQLite
**What it is:** Handy is a cross-platform desktop speech-to-text app that records from a global shortcut, transcribes locally, and pastes the result into the active application. It aims to be a free, private, forkable alternative to closed dictation tools.

---

## Update Notes

Checked on 2026-06-20 against `bc6a41e418dda66a1f8d0b123e6a83880a66b6a1` (`0.8.3`). The verdict remains the same, but the model matrix is broader than the first pass captured: the current code includes Whisper, Parakeet, Moonshine, SenseVoice, GigaAM, Canary, and Cohere engine paths through `transcribe-rs`. GitHub metadata at check time: about 24.4k stars, 2.1k forks, 94 open issues, and a push on 2026-06-20 UTC.

---

## Verdict

✅ **Deploy candidate for local dictation, with Linux and model-stability caveats.** Handy has the right product shape: local-first, one main job, signed releases, cross-platform builds, and a codebase that is much more inspectable than most desktop AI utilities. The weak spots are exactly where desktop speech apps tend to hurt: Wayland input, overlay focus behavior, GPU/model crashes on some configurations, and still-thin test coverage around the real transcription path.

---

## What It Is

Handy turns a configurable keyboard shortcut into system-wide dictation. Press the shortcut, speak, release or toggle, and the app runs local speech recognition before pasting the text into whatever field had focus. The core path is intentionally simple and privacy-oriented: microphone input is captured locally, silence is filtered with VAD, transcription runs on local Whisper or Parakeet-family models, and the result can be pasted without sending audio to a cloud service.

The project is explicitly positioned as a forkable foundation, not just a packaged app. That shows in the README, the CLI control flags, the Raycast integration, the manual model installation path, the Linux display-server notes, and the active maintainer notes about refactoring settings and Tauri command organization. As of check-in, GitHub reports roughly 24.4k stars, 2.1k forks, 94 open issues, and a push on 2026-06-20 UTC.

---

## Stack

| Layer | Tech |
|-------|------|
| Desktop shell | Tauri 2 |
| Backend | Rust |
| Frontend | React 18, TypeScript, Tailwind CSS, Vite |
| Speech inference | `transcribe-rs`, Whisper, Parakeet, Moonshine, SenseVoice, GigaAM, Canary, Cohere, ONNX, whisper.cpp features |
| Audio | `cpal`, `rubato`, `hound`, `vad-rs`, Silero VAD resource |
| State | Tauri store, bundled SQLite via `rusqlite` |
| Shortcuts/input | Tauri global shortcut, `handy-keys`, `rdev`, `enigo`, platform command helpers |
| Updates/releases | Tauri updater with minisign-style signatures, GitHub Actions matrix builds |
| Packaging | macOS, Windows, Linux AppImage/deb/rpm, Homebrew/winget community paths |

## Key Features

### Local, Model-Selectable Transcription

Handy supports multiple local model families instead of hard-coding one Whisper build. The model manager tracks model IDs, filenames, download URLs, SHA-256 hashes, size, engine type, language support, translation support, and whether a model is custom. That is the right model-management shape for a consumer-facing local AI app: users can pick speed versus accuracy, and the app can still reason about capabilities.

The README currently highlights Whisper Small/Medium/Turbo/Large and Parakeet V3. The code already exposes more engines, including Moonshine, SenseVoice, GigaAM, Canary, and Cohere model variants, which makes Handy more of a local ASR runtime shell than a single-model wrapper.

### System-Wide Control Surface

The app is usable without keeping its window in front. It has global shortcuts, push-to-talk, tray state, CLI flags for controlling an already-running instance, and Unix signal support for Linux window managers. That matters more than a pretty settings UI for this category of app: dictation has to work from the user's current application.

The CLI flags are especially practical:

```bash
handy --toggle-transcription
handy --toggle-post-process
handy --cancel
handy --start-hidden --no-tray
```

### Post-Processing Without Making Cloud Mandatory

Handy includes optional transcript post-processing through provider settings, structured-output support when available, custom base URLs, and Apple Intelligence on supported Apple Silicon systems. This is useful, but it changes the privacy story. The core transcription path is local; post-processing can be local or remote depending on provider configuration.

The code makes a good effort to avoid accidental secret disclosure: API keys are stored in settings but custom debug formatting redacts values, and there are explicit tests for that redaction behavior.

### Honest Platform Notes

The Linux notes are unusually candid. Handy documents the need for `xdotool`, `wtype`, or `dotool`, calls out Wayland limitations, explains overlay focus failure modes, and gives workarounds for `gtk-layer-shell` and WebKit DMA-BUF rendering issues. This is not polish, but it is useful operational maturity.

## Architecture

The main architectural strength is that Handy treats transcription as a lifecycle, not a button callback. `TranscriptionCoordinator` serializes shortcut, signal, cancel, and processing-finished events through a single worker thread with explicit `Idle`, `Recording`, and `Processing` states. That is the correct defense against double-presses, key repeat, overlapping signal handlers, and async paste/transcription races.

The backend is organized around managers: model, audio, transcription, history, settings, tray, overlay, and platform helpers. The frontend is a settings and status UI rather than the center of the app. Most of the real behavior lives in Rust, which is appropriate for a desktop tool that needs microphones, keyboard hooks, local files, native permissions, and platform packaging.

There are still signs of fast-growing app complexity. The README itself says settings and Tauri commands need cleanup. The Tauri config allows the asset protocol over a broad `**` scope, and the app has an explicit external-script paste mode. Those are not automatically vulnerabilities in a local desktop app, but they are surfaces worth keeping narrow and clearly user-controlled.

## Comparison

| Aspect | Handy | Commercial dictation apps | MacWhisper/whisper.cpp wrappers |
|--------|-------|---------------------------|---------------------------------|
| Privacy model | Local by default, optional LLM post-processing | Often cloud-backed or opaque | Usually local |
| Primary workflow | Shortcut-to-active-field dictation | Shortcut-to-active-field dictation | Often file/audio transcription first |
| Extensibility | MIT source, Rust/Tauri, CLI flags, model manager | Limited | Varies, often CLI-first |
| Cross-platform | macOS, Windows, Linux x64, growing ARM paths | Often macOS-first | CLI is broad, desktop UX varies |
| Maturity risk | Active, many users, many issues | Productized support | Depends on wrapper |
| Linux support | Real but caveated | Often weak | CLI strong, desktop integration weak |

Handy's niche is not "best ASR model" or "most polished paid dictation app." Its niche is an inspectable, hackable, local desktop dictation foundation with real distribution momentum.

## Self-Hosting Notes

This is a desktop app, not a service. For normal use, install a release from GitHub or the project site. On macOS, Homebrew cask is available; on Windows, winget is available, though the README notes those package channels are not maintained by Handy's developers.

For source builds, the repo uses Bun, Vite, Tauri 2, Rust, and platform-specific native dependencies. Linux needs WebKitGTK and audio/input libraries; Wayland users should expect extra setup for text insertion. Models are downloaded into the app data directory, and the README documents manual installation for restricted networks.

The updater is configured with signed artifacts and a public key in `src-tauri/tauri.conf.json`. That is a good baseline for a desktop app distributing binaries through GitHub releases.

---

**Attribution:** cjpais/Handy, MIT License
