# Shadow (ghostwright/shadow)

**Rating:** 🔥🔥🔥🔥🔥  
**License:** MIT  
**Source:** https://github.com/ghostwright/shadow  
**Reviewed:** 2026-03-21  
**Companion:** [Ghost OS](ghost-os.md) (action layer; Shadow is the observation layer)

## What It Is

Personal intelligence engine for macOS. Captures 14 modalities of everything your Mac does — all local, all on-device, zero cloud dependency. Turns raw behavioral signals into structured episodes, semantic search, and proactive suggestions. Trains its own vision grounding models on your actual usage.

*"Your computer was paying attention the whole time."*

## The 14 Modalities (All Timestamped, All Local)

| Modality | Mechanism | Notes |
|----------|-----------|-------|
| Screen | ScreenCaptureKit, H.265 hardware, fragmented MP4 | Per-display, sleep/wake recovery, hot-plug |
| Keystrokes + mouse | CGEventTap with AX enrichment at click point | Sub-ms latency; passwords excluded pre-storage |
| Accessibility tree | AXUIElement, full diff-aware snapshots | Full semantic structure of every UI element |
| Microphone | AVFoundation, mic-triggered | Starts on voice activity; 30s silence timeout — no silent recording |
| System audio | ScreenCaptureKit | |
| Clipboard | NSPasteboard | Source + destination app tracked |
| File changes | FSEvents | |
| Git commits | FSEvents on .git | |
| Terminal commands | CGEventTap in terminal apps | Exit codes included |
| Search queries | AX tree + browser integration | |
| Notifications | NSUserNotificationCenter | |
| Calendar events | EventKit | |
| Browser URLs | AX tree + browser AX API | |
| System context | NSWorkspace, display info | App switches, sleep/wake |

**Why 14 modalities matter:** Each multiplies the others. Screenshot alone = what was on screen. Add keystrokes = what they typed. Add AX tree = what every element was and what was clicked. Add clipboard = what they deemed worth keeping. Add git = what was produced. Add terminal = what succeeded and failed. Combinatorial, not additive.

## Architecture

```
Shadow (macOS menu bar app, Swift + Rust)
│
├── Capture (Swift, Apple-native APIs)
│   ├── ScreenCaptureKit    per-display H.265, fragmented MP4, sleep/wake recovery
│   ├── CGEventTap          keystrokes, mouse, scroll, AX enrichment, undo detection
│   ├── AXUIElement         accessibility tree, browser URLs, window titles
│   ├── AVFoundation        mic-triggered audio, system audio via SCK
│   ├── FSEvents            file system + git directory monitoring
│   └── NSWorkspace         app switches, sleep/wake, display hot-plug
│
├── Storage (Rust via UniFFI)
│   ├── MessagePack event log (zstd compressed, hourly rotation)
│   ├── Tantivy full-text search
│   ├── CLIP vector embeddings (cosine similarity)
│   ├── SQLite timeline index (WAL mode)
│   └── 3-tier retention (hot/warm/cold, configurable cap)
│
├── Intelligence (Swift + on-device models, all Apple Silicon)
│   ├── MobileCLIP-S2       image embeddings (CoreML, Neural Engine)
│   ├── WhisperKit          transcription, word-level timestamps, speaker attribution
│   ├── Qwen 7B / 32B       fast tasks / deep reasoning (MLX, KV-cache session reuse)
│   ├── Qwen2.5-VL-7B       vision understanding (MLX)
│   ├── ShowUI-2B + LoRA    UI grounding, fine-tuned on YOUR actual clicks
│   ├── nomic-embed         text embeddings
│   ├── Episode engine      activity boundary detection + LLM summarization
│   ├── Proactive heartbeat fast 10min / deep 30min, push suggestions
│   ├── Agent runtime       26 tools, streaming UI, task decomposition
│   └── Mimicry             procedure learning, safety gates, undo support
│
└── UI (SwiftUI)
    ├── Menu bar            status, mini timeline, pause/resume
    ├── Search overlay      Option+Space, CLIP + Tantivy hybrid
    ├── Timeline            multi-track scrubber (video + app + audio waveform)
    ├── Proactive overlay   suggestions inbox, trust feedback
    └── Settings
```

## Intelligence Stack (All On-Device)

**Search:** Hybrid CLIP visual embeddings + Tantivy full-text + timeline. "When was I looking at that chart?" returns results by semantic meaning.

**Qwen KV-cache session reuse:** First-token latency drops from 14s to under 1s across multi-turn conversations by reusing cached KV states.

**Proactive heartbeat:** Two-tier analysis (fast every 10min, deep every 30min), pushes to overlay inbox. Generates real suggestions from your actual state: "Your commit is still pending." "150 context switches in 2 hours." Not canned templates.

**ShowUI-2B + LoRA fine-tuning:** Grounding oracle cascades: AX exact match (free, instant) → AX fuzzy match → ShowUI-2B → cloud vision. 70-80% of interactions resolved by AX path. LoRA training generates grounding data from your actual clicks and fine-tunes ShowUI to your specific apps.

**Mimicry:** Watches you perform tasks (CGEventTap + AX enrichment), synthesizes replayable procedures with safety gates (pre-action checks, post-action verification, undo manager). Ghost OS executes the actions; Mimicry knows when to trigger them.

## Storage

- 200-600 MB/day
- 512 GB Mac = 6-12 months
- Hot (7 days): full video + audio
- Warm (8-30 days): keyframes + transcripts only
- Cold (31+ days): search indices only
- Transcripts never deleted until source audio fully transcribed
- Configurable storage cap

## Training Data Value

Every captured user action: `(screenshot + AX tree, action, new screenshot + AX tree)` — the exact `(state, action, next_state)` format for behavioral cloning.

- 25,000-40,000 actions per user per day
- Undo detection → automatic negative examples
- Episode boundaries → goal annotations
- Real multi-app workflows vs. scripted sandbox benchmarks

Cited study: 312 real human trajectories outperform Claude 3.7 Sonnet at computer use. Shadow generates that data continuously from normal usage.

## Privacy

- No telemetry, no account, no cloud dependency
- Passwords detected + excluded at CGEventTap level before reaching storage
- Pause recording, exclude apps, delete any time range
- Cloud LLM (Claude, GPT) opt-in with your own API key
- Open source — read the code, don't trust the policy

## Building

Non-trivial build: Swift + Rust (UniFFI bridge), XcodeGen, Python for CLIP model provisioning. Not yet homebrew.

```bash
./scripts/build-rust.sh           # Rust storage engine + Swift bindings
pip3 install huggingface_hub open_clip_torch
python3 scripts/provision-clip-models.py  # ~190 MB CLIP models
cd Shadow && xcodegen generate && cd ..
xcodebuild -project Shadow/Shadow.xcodeproj -scheme Shadow -configuration Debug build
```

Requirements: Apple Silicon M1+, macOS 14+, Xcode 16.4+, Rust, Python 3.8+, XcodeGen  
**Qwen 32B requires 48 GB+ RAM** (M1 Max 64GB ✓)

## Ghost OS Integration

Shadow = observation layer. Ghost OS = action layer. They're designed to compose:
- Shadow's Mimicry system learns procedures; Ghost OS replays them
- Shadow provides the behavioral context; Ghost OS provides the 29 AX/vision/action tools
- Both MIT, same maintainer

## Missing Piece (Contribution Opportunity)

MCP server to expose Shadow's captured context to any AI agent — listed as an explicit desired contribution. Once built, OpenClaw could query "what was the user doing in the last hour?" directly.

## vs. Screenpipe

Screenpipe is the closest prior art (3-4 modalities, screenshots + OCR + audio). Shadow: 14 modalities, full AX tree, episode generation, proactive heartbeat, on-device LLMs, LoRA fine-tuning, Mimicry workflow replay. Categorically different scope.
