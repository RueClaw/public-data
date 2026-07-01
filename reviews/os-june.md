# June (open-software-network/os-june)

**Repo:** https://github.com/open-software-network/os-june  
**License:** MIT - permissive reuse with attribution  
**Reviewed:** 2026-06-30  
**Stack:** Tauri 2, Rust, React, TypeScript, SQLite, Axum, Hermes, CPAL, Vite  
**What it is:** A private desktop AI assistant for meeting notes, dictation, and local agent work, with a Rust/Tauri desktop app plus a separate confidential June API backend for model calls.

---

## Verdict

✅ **Deploy candidate if you want to study or build a serious desktop assistant, not just a chat wrapper.** June has a coherent product thesis: record spoken work, turn it into notes or inserted text, then continue the work through a local Hermes agent runtime. The implementation is ambitious and unusually complete for an open source desktop app, but the surface area is broad enough that maintenance, polish, and platform parity will be the hard parts.

---

## What It Is

June combines three product shapes that are usually separate: meeting notes, dictation, and a local agent workspace. It records microphone or microphone-plus-system audio, stores audio locally, generates editable meeting notes, cleans up dictation and pastes it into the active app, and runs a Hermes-based agent runtime for local file work, research, drafts, routines, and tool use.

The privacy architecture is more concrete than the average "local-first" README. App state, recordings, transcripts, agent sessions, and memory live on the user's machine by default. Provider keys are kept out of the desktop app and live in June API, which is designed to run as a TEE-attested backend with private model routing. That still is not equivalent to purely offline inference, but the repo has real machinery behind the claim: pinned images, attestation docs, `/verify`, digest-record deploy tags, server-side provider routing, and careful request validation.

The main tradeoff is scope. This repo contains a desktop app, meeting recorder, system-audio capture, dictation helper, local agent runtime, Hermes admin console, skills/tools management, routines, account/billing integration, updater/release workflows, and June API deployment. That is impressive, but every one of those areas has its own support burden.

## Stack

| Layer | Tech |
|-------|------|
| Desktop shell | Tauri 2, Rust |
| Frontend | React 18, TypeScript, Vite, TipTap, Framer Motion |
| Local storage | SQLite migrations and Rust repositories |
| Audio | CPAL, WAV writers, macOS system-audio helper, live preview tap |
| Dictation | Native helper process, global shortcuts, HUD, cleanup model call |
| Agent runtime | Hermes agent bridge, local MCP scripts, sandbox/unrestricted modes |
| Backend API | Rust workspace with Axum-style routing, services, providers, config crates |
| Model providers | June API proxy, Venice, OpenAI, configurable pricing/model catalog |
| Deployment | Docker, GHCR, Phala TEE deployment, GitHub Actions release pipelines |
| CI | Frontend lint/tests, Tauri Rust tests, June API fmt/clippy/tests, release workflows |

## Key Features

### Saved-Audio-First Meeting Notes

The strongest architecture choice is that saved local audio remains the source of truth. Live transcript preview is treated as optional UI state; final transcript and notes are generated from validated saved audio. That avoids a common failure mode in realtime transcription products where a partial UI stream becomes the only record.

The repo documents this in `docs/adr/0002-live-transcript-preview-strategy.md`, and the implementation follows through in `src-tauri/src/audio/capture.rs`, `src-tauri/src/audio/recovery.rs`, and the processing pipeline.

### Conversation-Aware Capture

June supports microphone-only and microphone-plus-system recording, with separate source lanes for user and system audio. The SQLite migrations include source modes and transcript-turn uniqueness, so the app can represent a conversation without pretending it solved general speaker diarization.

### Dictation Into Any App

The dictation path is closer to Superwhisper or Wispr Flow than to a normal meeting-note app. It has configurable push-to-talk/toggle shortcuts, a HUD, microphone selection, transcription context, cleanup style, and paste-back behavior. That makes June useful outside its own editor.

### Local Hermes Agent Runtime

The Hermes bridge is a major subsystem. It pins a Hermes source commit, installs and manages the runtime, exposes local context and web MCP scripts, syncs config, manages skills/toolsets, proxies provider calls, exposes admin surfaces, and supports sandboxed versus unrestricted modes. The typed Hermes control-plane layer is a good design boundary: raw gateway frames are classified into June-specific events, unsupported events stay visible, and sensitive payloads are sanitized.

### Confidential API Boundary

June API handles transcription, generation, dictation cleanup, web search/fetch, model catalog, metering, and provider routing. The API side has body limits, JSON depth/string guards, model-kind checks, public URL validation for web fetch, bearer auth, JWKS validation, and secret-redacting config debug output.

## Architecture

The repo is organized as a full product monorepo:

- `src/` contains the React/Tauri frontend, with a large app shell in `src/app/App.tsx` and feature components under `src/components/`.
- `src-tauri/` contains the Rust desktop backend, audio capture, dictation, SQLite repositories, Hermes bridge, OS account integration, menu bar, HUDs, and Tauri commands.
- `june-api/` is a Rust workspace split into `api`, `services`, `providers`, `domain`, `config`, and `app` crates.
- `docs/` includes release, reproducible build, Hermes upgrade, backend, account, and ADR documentation.
- `.github/workflows/` covers desktop CI, API CI, coverage, release, API image build, promotion, watchdog, and repository hygiene.

Two patterns stand out:

1. Capture and processing are decoupled. Audio capture is globally single-instance, but per-note processing queues serialize transcription/generation so later recordings do not race earlier note updates.
2. Hermes event handling has a dedicated typed control-plane package instead of scattering raw JSON-RPC payload reads through the UI.

## Security Notes

The security posture is above average, but there are real caveats.

Strengths:

- Provider keys stay server-side in June API.
- Desktop path containment has tests.
- API body limits and JSON guards are explicit.
- Web fetch rejects private literal IPs and only forwards public HTTP(S) targets.
- Docker base images are digest-pinned and the runtime user is non-root.
- Release workflows pin external GitHub Actions by SHA.
- Repository hygiene checks reject committed env/private key material.

Caveats:

- The macOS Seatbelt write jail is macOS-only. Windows is supported, but the same write jail and credential-read denylist do not apply there.
- The Tauri main renderer has a large native command surface and CSP allows loopback connections. If renderer XSS lands, the blast radius is meaningful.
- The web fetch SSRF defense is thoughtful, but HTTPS domain preflight still has a DNS/time-of-check/time-of-use gap because the upstream fetcher resolves later.
- I did not see automated `cargo audit`, `cargo deny`, npm audit, CodeQL, gitleaks, Trivy, or SBOM generation in CI. The API image build intentionally disables provenance/SBOM for deployment compatibility, which is understandable but still leaves a visibility gap.

## Comparison

| Aspect | June | Granola / Limitless | Superwhisper / Wispr Flow | ChatGPT / Claude Desktop | Raycast AI |
|--------|------|---------------------|----------------------------|---------------------------|------------|
| Primary job | Spoken work to notes, dictation, and agent follow-through | Meeting capture and polished notes | Dictation and text insertion | General assistant/chat | Command palette and workflows |
| Local state | Strong local SQLite/audio/session posture | Less hackable, more managed | Varies by product | Mostly managed/cloud account state | Local app plus service integrations |
| Agent runtime | First-class Hermes runtime | Not the main point | Not the main point | Tool/runtime surfaces are narrower | Workflow-oriented, less session-state-heavy |
| Privacy model | Local-first plus TEE-backed model proxy | Managed service trust | Product-dependent | Provider trust | Product/provider trust |
| Main risk | Scope and platform complexity | Less extensible | Dictation polish bar | Limited local context/control | Less deep native capture |

June is closest to a desktop agent OS: meeting notes and dictation are not side quests, but the Hermes runtime makes it more than a recorder.

## Self-Hosting Notes

Local development is documented and straightforward for a project of this size:

```sh
cp .env.example .env
cp june-api/.env.example june-api/.env
pnpm install
pnpm tauri:dev
```

For the default local setup, provider keys go in `june-api/.env`, not the desktop root `.env`. The app can run in local-dev mode without OS Accounts/billing, using a shared local bearer token between desktop and API.

Production deployment is more involved. The June API path expects container builds, GHCR images, Phala/TEE deployment, digest recording, and a `/verify` chain. That is a serious deployment model, but not a casual one-command self-host.

---

**Attribution:** open-software-network/os-june, MIT License
