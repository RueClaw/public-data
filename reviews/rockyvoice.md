# RockyVoice (Lagunaswift/RockyVoice)

**Repo:** https://github.com/Lagunaswift/RockyVoice
**License:** MIT for repo code; character and bundled voice-sample rights are separate fan-project concerns
**Reviewed:** 2026-06-11
**Stack:** Claude skill Markdown, Node.js, Express, Hume AI TTS, Server-Sent Events, Web Audio API, static HTML/CSS/JavaScript
**What it is:** A playful Claude persona skill plus local voice app that makes Claude answer in a Rocky-inspired voice from Andy Weir's *Project Hail Mary*, optionally speaking responses through Hume TTS.

---

## Verdict

🔧 **Harvest the interaction pattern, not the persona wholesale.** RockyVoice is tiny, charming, and technically straightforward: one persona skill, one local Express server, a Hume streaming TTS bridge, and a browser waveform UI. The useful reusable pieces are the explicit off-switch, safety-clarity override, local hook-to-TTS bridge, and speech-cleaning pipeline. The big caveat is rights: MIT covers the repo code, but the named fictional character and bundled voice sample make this a fan project, not a clean production asset.

---

## What It Is

RockyVoice has two parts. The text side is a Claude skill at `rocky-voice/SKILL.md` that forces all output into a specific fictional-character voice until the user explicitly turns it off. The voice side is a local web app under `rocky-tts/` that sends cleaned assistant responses to Hume's TTS API, streams PCM chunks back over Server-Sent Events, and plays them in a browser with a sci-fi waveform UI.

The README gives both manual and automatic paths. Manual use runs the web app and lets the user paste text. Automatic use adds Claude Code hooks: `SessionStart` launches the local server and `Stop` posts the assistant's final response to `http://localhost:3333/api/hook`.

The repo is very new and intentionally lightweight: no tests, no CI, no package publishing, and no auth layer. It is best understood as a fun local assistant mod and a reference for persona-plus-voice experiments.

## Stack

| Layer | Tech |
|-------|------|
| Persona | Claude skill Markdown with YAML front matter |
| Installer | Bash script copying `SKILL.md` into Claude skills |
| Voice server | Node.js, Express |
| TTS provider | Hume AI streaming TTS API |
| Browser transport | Server-Sent Events plus static Express assets |
| Audio playback | Web Audio API, PCM chunks |
| UI | Single static HTML file with canvas waveform/spectrum visualization |
| Config | `.env` via `dotenv` |

## Key Features

### Persistent Persona Skill With Explicit Exit

The skill is designed to govern the whole conversation, not just one answer. It includes explicit stop phrases and a "normal mode" escape hatch, which is important for any strong persona skill.

### Safety-Clarity Override

The strongest prompt-design detail is the safety override: when exact wording matters, the persona should drop broken grammar and give precise warnings, commands, and numbers. That is the right invariant for playful style layers over real technical work.

### Local Claude Hook to Voice Server

The README shows a practical Claude Code hook setup. `SessionStart` starts the local server, and `Stop` posts responses to `/api/hook`. That is a simple pattern for turning agent output into side-channel audio without changing the agent's core workflow.

### Streaming TTS Bridge

`server.js` calls Hume's streaming endpoint, splits long text under provider limits, forwards PCM chunks to connected browsers via SSE, and keeps the latest generation id as prosody context. It also strips Markdown tables, code blocks, URLs, and inline code before speech.

### Browser Audio Console

The frontend is a single static page with an audio unlock screen, SSE client, Web Audio playback queue, and waveform/spectrum canvas visuals. It is more polished than the repo size suggests.

## Architecture

The runtime path is compact:

1. Claude emits a response.
2. Claude Code `Stop` hook posts hook JSON to `/api/hook`.
3. Server logs the hook payload to `hook-log.jsonl`.
4. Server extracts `assistant_message` or `last_assistant_message`.
5. `cleanForSpeech` removes Markdown/code/table/URL noise.
6. `streamSynthesize` sends split utterances to Hume.
7. Audio chunks are broadcast to browser clients over SSE.
8. The browser decodes PCM chunks and schedules playback with Web Audio.

The main security boundary is local-only assumption. The Express app has no authentication, no origin check, and no CSRF protection. That is acceptable for a local toy if bound only to trusted localhost use, but it should not be exposed on a network.

## Validation

Local checks performed:

- `bash -n install.sh` passed.
- `npm ci` passed in `rocky-tts/`.
- `npm audit --omit=dev` reported 0 vulnerabilities across 70 audited packages.
- `node --check server.js` passed.
- Startup smoke with `PORT=3334 timeout 2s node server.js` launched successfully using the stock fallback voice path.
- Lightweight secret scan found only placeholder/config variable names, not committed live secrets.

No automated tests or CI were present.

## Comparison

| Aspect | RockyVoice | caveman | generic TTS hook |
|--------|------------|---------|------------------|
| Main focus | Fictional-character persona plus voice playback | Token-compressed persona style | Audio side-channel for agent output |
| Best idea | Persona off-switch plus safety-clarity rule | Small mouth, big brain compression | Hook output to local speech server |
| Runtime | Claude skill + local Hume TTS web app | Skill-only pattern | Usually provider-specific |
| Production fit | Low, because fan-project rights and local-only security | Depends on use case | Depends on auth and provider policy |

## Self-Hosting Notes

Use it locally only. Do not expose the Express server beyond localhost without adding authentication, origin checks, request limits, and log hygiene.

Be careful with the bundled voice sample and character framing. For private fan use, it is clear what the repo is doing. For public, commercial, client, or workplace use, replace the character and voice sample with assets you own or have licensed.

For a cleaner reusable version, keep the mechanics and swap in:

- an original persona;
- an owned or licensed voice;
- a generic TTS provider abstraction;
- configurable hook payload parsing;
- explicit log retention controls.

---

**Attribution:** Lagunaswift/RockyVoice, MIT License. Rocky is a character from Andy Weir's *Project Hail Mary*; this reviewed repo identifies itself as a fan project.
