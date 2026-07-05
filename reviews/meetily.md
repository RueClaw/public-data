# Meetily (Zackriya-Solutions/meetily)

**Repo:** https://github.com/Zackriya-Solutions/meetily  
**License:** MIT - permissive license, fine to fork, adapt, and extract from with attribution  
**Reviewed:** 2026-07-04  
**Stack:** Rust, Tauri 2, Next.js 14, React, TypeScript, SQLite, whisper-rs, ONNX Runtime, Parakeet, Ollama/OpenAI-compatible summary providers  
**What it is:** Meetily is a local-first desktop meeting assistant for recording, transcribing, importing, re-transcribing, and summarizing meetings without making cloud processing mandatory.

---

## Verdict

✅ **Deploy candidate for personal local meeting notes, with security-surface and release-polish caveats.** Meetily has the right core shape for privacy-sensitive meeting capture: Tauri desktop shell, local SQLite, local audio files, Whisper and Parakeet transcription, import/retranscription workflows, and local Ollama or bundled summary models. The project is not as hardened as its privacy marketing implies, mainly because the Tauri permission surface is broad, API keys are stored in app SQLite rather than an OS keychain, and model downloads rely on size/shape validation rather than cryptographic hashes.

---

## What It Is

Meetily records microphone and optional system audio, transcribes it locally, stores meeting artifacts on disk, and generates structured summaries from the transcript. The current supported app is a self-contained Tauri desktop application: Next.js renders the UI, Rust handles native audio, model management, local persistence, notifications, and summary orchestration, and SQLite stores meeting metadata, transcript segments, summaries, settings, and provider keys.

The repository still carries a legacy Python/FastAPI backend, Docker compose files, and whisper-server scripts, but `backend/README.md` clearly marks that path as archived and unsupported. The live product path is `frontend/src` plus `frontend/src-tauri`.

The project has real adoption signals: GitHub reported about 15.4k stars, 1.7k forks, 236 open issues, and a latest release `v0.4.0` published on 2026-06-05. It is active, but not quiet: this is a fast-moving desktop AI app with a large native command surface and plenty of platform-specific complexity.

## Stack

| Layer | Tech |
|-------|------|
| Desktop shell | Tauri 2, Rust |
| Frontend | Next.js 14, React 18, TypeScript, Tailwind, Radix UI, BlockNote/Remirror |
| Local storage | SQLite via `sqlx`, app data folders, JSON transcript/metadata files |
| Audio capture | `cpal`, system-audio paths, `rubato`, `realfft`, `ebur128`, RNNoise-style noise suppression |
| Transcription | `whisper-rs`, Parakeet ONNX models through `ort`, VAD chunking |
| Summaries | Ollama, OpenAI, Claude, Groq, OpenRouter, custom OpenAI-compatible endpoints, bundled local summary models |
| Packaging | Tauri bundles for macOS, Windows, Linux; updater artifacts and GitHub releases |
| Legacy backend | Archived Python/FastAPI, Docker, standalone whisper-server scripts |

## Key Features

### Local Transcription With Two Model Families

Meetily supports both Whisper and Parakeet. Whisper models are cataloged centrally from tiny through large-v3 and quantized variants, while Parakeet uses ONNX encoder/decoder/preprocessor/vocabulary bundles with int8 v2/v3 model choices. The app stores models under the app data directory and exposes download/load/delete commands through Tauri.

The useful part is not just "it runs Whisper." The repository has lifecycle handling around model loading, active downloads, cancellation, corrupted model detection, and unloading after batch import/retranscription. That matters for a desktop app where a user may record live, import a long file, and switch models without restarting.

### Import, Re-Transcription, and Crash Recovery

The import path validates audio files, extracts duration from metadata before falling back to full decode, caps file size at 20 GB, runs VAD, transcribes chunks, and creates a normal meeting record. The retranscription path scans stored meeting folders for common audio filenames and lets users rerun transcription with different language/model settings.

Live recording uses checkpoint-style saving every 30 seconds before final FFmpeg concat. That is a good practical choice: meeting apps should assume crashes, battery loss, and long recordings. Storing checkpoint artifacts and reconstructing audio is more important than a polished loading spinner.

### Summary Provider Flexibility

Meetily supports local Ollama, a built-in local summary engine, OpenAI, Claude, Groq, OpenRouter, and arbitrary OpenAI-compatible endpoints. The Rust summary service has cancellation tokens, summary caching keyed by transcript/template/model inputs, language detection, and custom templates.

This flexibility is good, but it complicates the privacy promise. Transcription can be local, and summaries can be local, but users can also send transcripts to cloud providers. The UI and docs need to keep that distinction crisp.

### Desktop Product Surface

The app has tray behavior, notification preferences, device monitoring, Bluetooth playback warnings, onboarding, model managers, recording preferences, audio level monitoring, import dialogs, transcript recovery, and update dialogs. That is more complete than a weekend wrapper around whisper.cpp.

## Architecture

Meetily is structured around native Rust modules exposed as Tauri commands:

- `audio/` handles capture, device detection, VAD, import, retranscription, checkpointing, ffmpeg encoding/mixing, and recording state.
- `whisper_engine/` and `parakeet_engine/` manage local ASR models and inference.
- `summary/` handles template-driven summary generation, model routing, cancellation, language handling, and cache metadata.
- `database/` contains SQLite setup, repositories, import helpers, and open-folder commands.
- `frontend/src` is mostly the application shell and controls around those native commands.

The best architectural pattern is that the app treats recordings as durable meeting folders, not just rows in a database. Audio, transcript JSON, metadata, and summaries can survive UI reloads and support recovery/retranscription workflows.

The weakest architectural choice is the size of the renderer-to-native trust boundary. `tauri.conf.json` grants broad filesystem read/write permissions (`fs:read-all`, `fs:write-all`) and exposes a large invoke handler. For a local desktop app this may be acceptable during rapid iteration, but it raises the cost of any renderer XSS or dependency compromise.

## Comparison

| Aspect | Meetily | Handy | June |
|--------|---------|-------|------|
| Primary workflow | Meeting capture, import, transcript, summary | Shortcut-driven dictation into active apps | Meeting notes, dictation, and local agent workspace |
| Privacy model | Local transcription and local summary options, optional cloud providers | Local transcription, optional post-processing | Local state plus managed/TEE API model boundary |
| Local ASR | Whisper and Parakeet | Broad local ASR engine matrix | Local capture with service-backed processing options |
| Meeting artifact model | Durable folders, SQLite, transcript JSON, recovery checkpoints | History/transcription records for dictation | Saved-audio-first notes and processing queues |
| Main strength | Practical self-contained meeting note app | Best shortcut-to-text workflow | Most ambitious full assistant architecture |
| Main risk | Broad Tauri/native surface and model provenance gaps | Platform input/paste edge cases | Scope and operational complexity |

Meetily sits between Handy and June. It is more meeting-specific than Handy and less ambitious than June's desktop-agent runtime. That is a good niche.

## Self-Hosting Notes

This is primarily a desktop application, not a server. Normal users install a release from GitHub. Linux users currently build from source.

Source builds require Rust, Node.js/pnpm, Tauri dependencies, platform audio dependencies, and sometimes GPU SDKs. The build scripts attempt GPU auto-detection for CUDA, ROCm/HIP, Vulkan, OpenBLAS, Metal, and CoreML paths, but the docs are candid that GPU drivers alone are not enough; development SDKs are often required.

Operational caveats:

- The current release is `v0.4.0`.
- The README still contains some historical `meeting-minutes` URLs, so follow current repository links carefully.
- Legacy Docker/FastAPI material exists, but it is archived and should not be treated as the supported deployment path.
- API keys for cloud summary/transcript providers are stored locally in SQLite columns/JSON, not in a platform keychain.
- Model downloads are HTTPS-based and validate expected files/sizes, but I did not see pinned hashes for downloaded ASR model files.

---

**Attribution:** Zackriya-Solutions/meetily, MIT License
