# OpenOats (yazinsai/OpenOats)

**Rating:** 🔥🔥🔥🔥🔥  
**License:** MIT  
**Source:** https://github.com/yazinsai/OpenOats  
**Reviewed:** 2026-03-20  
**Author:** yazinsai (same as OpenGranola, #218)

## What It Is

Real-time meeting copilot for Apple Silicon. Transcribes both sides of a call locally, searches your notes, and surfaces suggestions from your own knowledge base — only when they're genuinely useful. Hidden from screen sharing. Fully offline-capable.

**Stack:** Swift 6.2, macOS 15+, Apple Silicon only.

## How It Differs From OpenGranola (#218)

OpenGranola (same author) surfaces talking points broadly. OpenOats has a much more sophisticated **suggestion pipeline** with explicit gate scoring and a design philosophy of aggressive abstention. OpenOats is the production-grade successor.

## Transcription Backends

Three options:
- **WhisperKit** — most battle-tested, runs via MLX
- **Parakeet** — Apple/NVIDIA model, faster
- **Qwen3** — via Ollama

Local speech model ~600 MB, downloaded on first run.

## The Suggestion Pipeline (5 Stages)

This is the crown jewel. Every "THEM" utterance runs through:

### Stage 1 — Heuristic Pre-Filter
- Min 8 words, 30 chars
- 90-second cooldown between suggestions
- Filler ratio >60% → skip (detects "yeah", "um", "basically", etc.)
- Jaccard similarity dedup against last 3 utterances (>0.8 → skip)

### Stage 2 — Trigger Detection
Pattern-matched, not LLM. Seven trigger kinds:
- `explicitQuestion` (contains `?`, starts with `what/how/why/should/could`) — confidence 0.80
- `decisionPoint` ("should we", "let's go with", "option a or") — 0.75
- `disagreement` ("but ", "however", "i disagree") — 0.65
- `assumption` ("i think", "i assume", "probably") — 0.60
- Domain signals: `customerProblem`, `distributionGoToMarket`, `productScope`, `prioritization` — 0.55

If no trigger → abort. No LLM call.

### Stage 3 — Conversation State Update (LLM)
Structured JSON state maintained throughout the call:
```json
{
  "currentTopic": "string",
  "shortSummary": "string (2-4 sentences max)",
  "openQuestions": ["string"],
  "activeTensions": ["string"],
  "recentDecisions": ["string"],
  "themGoals": ["string"]
}
```
Only updated when `needsStateUpdate` is true. State persists; arrays capped at 3-4 items.

### Stage 4 — Multi-Query KB Retrieval
Queries built from: utterance text + currentTopic + shortSummary + top open question. Up to 5 chunks retrieved, min relevance score 0.35 to proceed.

### Stage 5 — Surfacing Gate (LLM) + Thresholds
Gate prompt instructs the model to **"optimize aggressively for abstention"**. Five scores must ALL clear thresholds:

| Signal | Threshold |
|--------|-----------|
| relevance | 0.72 |
| helpfulness | 0.75 |
| timing | 0.70 |
| novelty | 0.65 |
| confidence | 0.75 |

"One strong suggestion is better than four weak ones." Gate explicitly penalizes: generic advice, advice obvious from conversation, weak KB matches, interruptions during unfinished ideation.

Also tracks last 3 shown suggestion angles (string prefix) for duplicate suppression.

### Stage 5b — Generation
If gate passes: generates structured output:
```json
{
  "headline": "≤10 words",
  "coachingLine": "one actionable sentence",
  "evidenceLine": "source reference or key quote"
}
```
Rendered as: `• headline\n> coaching line\n> evidence line`

## Knowledge Base

Point at any folder of `.md` or `.txt` files. Chunked, embedded, cached to disk with SHA-256 fingerprinting (re-indexes only when content changes). Works with Obsidian vaults directly.

**Embedding providers:**
- Voyage AI (cloud)
- Ollama (`nomic-embed-text`)
- Any OpenAI-compatible `/v1/embeddings` endpoint (llama.cpp, LiteLLM, vLLM, llamaswap)

## LLM Providers

- OpenRouter (GPT-4o, Claude, Gemini)
- Ollama (Qwen3, Llama, Mistral — fully local)
- MLX server (Apple Silicon inference)

## Privacy Design

- Audio never leaves the Mac
- Screen sharing: window hidden by default
- Fully offline mode: Ollama LLM + Ollama embeddings + local Whisper/Parakeet
- Sessions auto-saved as plain text transcripts + structured JSON logs

## What's Notable

**The abstention philosophy is the insight.** Most meeting copilots flood you with suggestions and train you to ignore them. OpenOats inverts this — the gate is biased toward silence, with multiple explicit scoring barriers. The result is that when a suggestion does appear, you pay attention.

**Trigger detection before LLM.** Pattern-matching filters run first, zero cost. LLM only called if a trigger fires and KB retrieval succeeds. This is the right architecture for real-time.

**Conversation state as structured JSON** (not free-text) means the gate prompt gets stable, parseable context across steps instead of a dumped transcript.

## Relevance

- Directly usable: point at the shared Obsidian vault or Marcos agent notes, use during calls with doctors/family/team
- Pattern reference: the 5-stage pipeline with pre-LLM filters is clean architecture for any "interrupt with suggestion" agent
- Marcos use case: could surface medication timing, symptom tracking prompts, or talking points during doctor appointments — knowledge base is just the Parkinson's research vault
- The `SuggestionEngine.swift` is worth studying as a reference for "when to speak" logic

## Install

```bash
brew tap yazinsai/openoats https://github.com/yazinsai/OpenOats
brew install --cask yazinsai/openoats/openoats
```

Or build from source: `./scripts/build_swift_app.sh`
