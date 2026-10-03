# Whistle (Cactus-Compute/whistle)

**Source:** https://cactuscompute.com/blog/whistle (launch post, 2026-10-02)  
**Weights:** https://huggingface.co/Cactus-Compute/whistle (`whistle.cact` 16.9 MB, plus a 220 MB `checkpoints/whistle.safetensors`)  
**Engine + wrapper:** https://huggingface.co/Cactus-Compute/needle3 (prebuilt native engines) and https://github.com/cactus-compute/needle (Python package `cactus-needle`). Earlier review of the same repo: [needle.md](needle.md)  
**License:** Apache-2.0 for the weights (HF model card) and for the Python package (`LICENSE` in the GitHub repo). You can use it commercially, modify it and redistribute it, as long as you keep the notice. The C++ engine ships only as prebuilt binaries (`libneedle3.so`, `needle`, `libneedle.a`, WASM). Its source isn't in the GitHub repo, and neither is the Whistle training code. So the weights are open, but the runtime that does the work is a binary you have to trust.  
**Reviewed:** 2026-10-03 (GitHub commit `9571a58`, package 3.1.0; HF `whistle` rev `b358dda`, weights 2.0.0; engine wheel 3.1.0 from HF `needle3` rev `c7c415a`)  
**Stack:** Closed C++ CPU engine (SIMD kernels, `.cact` mmap container, 2–4-bit "Cactus Quants"), loaded through a stdlib-only Python `ctypes` wrapper. `huggingface_hub` handles fetching. Optional extras: `soxr` + `sounddevice` for mic/resampling, `openai-whisper` + `moonshine-voice` for the comparison CLI. Training (for Needle) runs on JAX/Flax.  
**What it is:** A 16.9 MB on-device speech-to-text model for 7 languages (en, de, fr, es, it, nl, pl). It handles up to 30 s per pass, returns word timestamps, supports keyword biasing, and can return encoder embeddings. It loads into the same engine as the Needle tool-calling model, so one native call can take audio in and return tool calls.

---

## Verdict

⚠️ **Interesting, and it actually works. I ran it locally on Linux x86_64: a 16.9 MB file transcribed clean English and German correctly, and it returned nothing (rather than a hallucination) on silence and noise. Two things make it a candidate to evaluate rather than to deploy blind: the runtime is a closed binary fetched unpinned from Hugging Face, and the vendor's latency numbers are Apple-M4-Pro numbers that a generic x86 vCPU doesn't come close to.**

What's good:
- **Size-to-quality is real for clean, short commands.** On TTS-generated clips it got English and German almost word-perfect, and the English stayed correct with pink noise mixed in. Word timestamps looked plausible. Silence and white noise came back as empty text with an empty language in about 1 ms, so it never entered the beam search. That's a good property for always-listening devices, where Whisper-family models are known to invent text on silence.
- **One runtime for speech and tool calls.** `needle_load` takes either `.cact` file, and `needle_complete` accepts audio wherever it accepts text, returning `{"function_calls": …, "audio_text": …, "audio_language": …}`. For voice-command devices that collapses the ASR → NLU pipeline into one C call with no transcript plumbing.
- **A small API surface.** The speech C API is just `needle_load` / `needle_transcribe` / `needle_embed` / `needle_last_error`. I drove it from about 20 lines of `ctypes` with no package install.
- **The benchmark write-up is unusually candid.** Missing bars are explained, the AMI vs AMI-IHM mismatch is called out, normalizers are named, and they claim a test/train checksum and speaker-ID overlap check. They also say where Whisper base wins (TED-LIUM, AMI, MLS average).

What gives pause:
- **The binary trust boundary.** "Source is on GitHub" refers to the Python wrapper and the Needle trainer. The engine that parses audio and model files is a downloaded `.so`/executable. `fetch.py` calls `hf_hub_download` with no `revision=` pin and no hash check against a value shipped in the package. The engine version selects only the *filename*, so whoever controls the HF repo controls the code you load.
- **The latency claims are hardware-specific.** The vendor reports 11.1 ms TTFT and 1,319 tok/s decode at 10 s of audio on an M4 Pro. On this host (4 shared x86_64 vCPUs) I measured about 600 ms TTFT and about 200 tok/s for a 5.3 s clip, and about 1.9 s TTFT for 16.7 s. That's still well faster than real time, but it's 50–100× off the headline. Benchmark on your own target silicon.
- **One language per clip.** Language is a single decoder token, so code-switched audio breaks: a German sentence spliced between two English ones came out as phonetic English gibberish. Forcing `language="en"` on German audio produced a German/English mix.
- **Telemetry is on by default** in the Python package. It sends anonymous event counts, versions, OS/arch and a random install ID to a Supabase endpoint, with no prompts or audio. Opt out with `NEEDLE_TELEMETRY=0` or `DO_NOT_TRACK=1` (`CI` also disables it). The native `libneedle3.so` I inspected imports no socket or getenv symbols, so the engine itself appears offline.
- **WER numbers are vendor-reported.** I didn't reproduce LibriSpeech/FLEURS etc. The baselines are the authors' published figures, not re-runs on the same harness.

## What It Is

Cactus Compute's launch post presents Whistle as a sibling to Needle, their tiny function-calling model. It does three things on the device:

1. **Transcription:** 16 kHz mono, up to 30 s per pass, 7 languages, with auto language detection or a forced language.
2. **Word timestamps:** start, end and probability per word, aligned from the decoder's cross-attention.
3. **Speech embedding:** encoder output, one 512-wide row per 80 ms frame, with no decode.

Keyword biasing takes a newline-separated list of phrases. An Aho-Corasick automaton runs alongside the 5-beam search and raises the log-probability of those phrases as they match. That's meant for names and product vocabulary.

## Stack

| Layer | Tech |
|---|---|
| Model | Encoder–decoder ASR: conv stem + 8 "Simple Attention" encoder blocks, 8 laddered decoder blocks with gated cross-attention |
| Quantisation | "Cactus Quants", 2–4 bit, group size 128, in a `.cact` container |
| Runtime | Prebuilt C++ engine (`needle3` 3.1.0), 17 platform targets incl. Android, iOS, watchOS, RISC-V, MIPS, WASM, WASI component |
| Python | `cactus-needle` 3.1.0, `ctypes` binding, only `huggingface_hub` as a hard dependency |
| Distribution | Hugging Face repos for weights/engines, PyPI for the wrapper, GHCR (cosign-signed) for the WASI component |

## Key Features

### Architecture (from the post and model card)
- Front end: 80-bin log-mel (25 ms window, 10 ms hop), band-limited to 250–3500 Hz and normalised per channel. 30 s gives 3,000 frames, and three stride-2 conv halvings bring that to 375 frames at 80 ms each.
- Encoder: 8 non-causal blocks shared with Needle (4 multi-lane hyper-connection residual lanes, a "Monarch Hadamard" MLP in place of the FFN).
- Decoder: width 512, GQA 8q:2kv, 3-tap causal conv on Q/K/V, engram n-gram lookups at layers 3 and 7. Each layer gets one extra gated cross-attention, `x ← x + σ(g)·softmax(qKᵀ/√d)V`. Cross K/V are projected once per clip and shared across all 5 beams.
- **Laddered decoder:** every depth from 2 layers up was trained as its own model, and `--audio-depth N` picks one at load. The encoder always runs all 8 blocks.
- Vocab: 8,192 pieces plus 7 language tokens. Output is capped at 320 tokens.

### Silence gate
The engine checks the clip's loudness range before decoding and returns an empty transcript below a threshold. I verified this on 3 s of digital silence and 3 s of ±0.3 white noise: both came back empty in about 1 ms. It isn't a VAD, though. It won't trim silence inside speech.

### Speech + tools in one call
`needle --model needle3.cact --model whistle.cact --tools tools.json --audio clip.wav` returns tool calls plus `audio_text` / `audio_language`. I didn't test this combined path.

### Tooling
`needle whistle playground` (mic REPL with `/language`, `/keywords`, `/timestamps`, `/file`) and `needle whistle compare` (Whistle vs Whisper tiny/base vs Moonshine tiny v2 on the same clip, with timing).

## Architecture

The Python side is thin. `needle/agent/whistle.py` (365 lines) has a pure-stdlib WAV reader (8/16/24/32-bit, downmix to mono, `soxr` only when the rate isn't 16 kHz), a sample marshaller that accepts paths, bytes, `array('f')`, numpy or lists, and a `Whistle` class that reads the whole `.cact` into memory and hands it to `needle_load`. There's one loaded model per process, the class is explicitly not thread-safe, and the default result buffer is 256 KB. `fetch.py` maps engine generations to HF repos and pinned version strings, then pulls wheels/platform folders from the HF repo's `main`.

The rest of the repo is Needle: a JAX/Flax architecture (`model/architecture.py`, about 1.1k lines), LoRA finetune, quantise/export to `.cact`, a local playground HTTP server, a hosted fine-tuning client (`platform.py`), and simulated tool environments. None of the Whistle training, data pipeline or engine kernels are public. The [`.cact` format post](https://cactuscompute.com/blog/cact-format) and the "Porting Needle" guide document the container well enough to write your own runtime, but nobody has done that for Whistle yet.

## Security

- **Native code from a mutable remote.** `fetch_library` / `download_platform` / `fetch_weights` call `hf_hub_download` without `revision=`, and there's no checksum in the package. Pin the HF commit yourself (download once, vendor the `.so` and `.cact`, verify sha256) for anything you ship. The WASI component is the exception: it's pushed to GHCR and signed and verified with keyless cosign in CI.
- **Pickle is gone.** The earlier Needle review flagged pickle checkpoints. The current code is `.safetensors`-only, and `tests/test_run.py` has regression tests that write a malicious pickle disguised as `.safetensors` and assert it never deserialises.
- **Playground server** binds `127.0.0.1` by default (`--host` overrides).
- **Hosted fine-tuning** sends `NEEDLE_API_KEY` as a Bearer token to `cactuscompute.com/v1`. Nothing is hardcoded. A grep for `sk-`/`AKIA`/`ghp_`/`shell=True`/`os.system`/`eval(` in the repo found nothing.
- **CI:** both workflows default to `permissions: contents: read` and elevate per job (`contents: write` + `id-token` for release, `packages: write` for the component). Actions are tag-pinned (`@v4`, `@v5`, `@release/v1`), not SHA-pinned. PyPI publishing uses trusted publishing (`id-token: write`).
- **Telemetry:** see Verdict. It's documented, off under `DO_NOT_TRACK`/`CI`, and fire-and-forget on a daemon thread. On first send it writes `~/.cactus_needle/telemetry_id`.

## Maturity

- GitHub `cactus-compute/needle`: about 13.1k stars, 886 forks, 30 open issues, created 2026-02-24, last push 2026-10-02. A daily release train publishes to PyPI after `pytest -m "not slow"` and checks that every pinned engine wheel exists on HF before publishing.
- Whistle landed in PR #163 on 2026-10-01. The HF `whistle` repo had 70 downloads when reviewed. It's one day old.
- Tests: 183 `test_` functions across 18 files, 22 of them in `tests/test_whistle.py` (WAV parsing, sample marshalling, CLI paths, compare harness with stubbed models).
- Small rough edge: `./setup` installs `.[train,whistle]`, but `pyproject.toml` defines no `whistle` extra (the speech extra is called `mic`).
- License changed from MIT (at the time of the July Needle review) to Apache-2.0.

### Validation on 2026-10-03

Host: Linux x86_64, 4 shared vCPUs, Python 3.13 stdlib. Package installs (`uv pip install`) were blocked in this environment, so the pytest suite was **not run**. Instead I exercised the shipped engine directly:

- Downloaded `whistle.cact` (16,919,407 B, sha256 `b6e02f04…`) and `cactus_needle-3.1.0-py3-none-manylinux2014_x86_64.whl` from HF, and extracted `libneedle3.so` (1.56 MB).
- Loaded it with `ctypes` using the repo's own `whistle.py` helpers (`_read_wav`, `_samples`). `needle_load` returned 0 in 50 ms.
- Test audio: OpenAI TTS clips converted to 16 kHz mono with ffmpeg.

| Clip | Result | TTFT / decode (engine-reported) |
|---|---|---|
| EN, 5.3 s "Turn off the kitchen lights and set an alarm for seven thirty tomorrow morning." | `Turn off the kitchen lights, and set an alarm for seven thirty to morrow morning.` (lang `en`) | 619 ms / 202 tok/s |
| DE, 6.2 s "Bitte schalte das Licht im Wohnzimmer aus und spiel etwas ruhige Musik." | `…aus und spielt etwas ruhige Musik.` (lang `de`, one inflection off) | 702 ms / 203 tok/s |
| EN + pink noise (amp 0.08) | `…set an alarm for 7.30 tomorrow morning.` (correct) | 590 ms / 193 tok/s |
| EN+DE+EN, 16.7 s | English parts correct. German part came out as `BITTER'S SHALL TO DAS LIGHT IMVONSIMA…` (single language token) | 1,870 ms / 190 tok/s |
| DE forced `language="en"` | `Bitte schalte das Licht im Wonzima aus, und spielen etwas rouge music.` | 740 ms / 208 tok/s |
| 3 s silence / 3 s white noise | `""`, language `""` | ~1 ms wall |
| `word_timestamps=True` on EN | per-word start/end/probability, monotonic, 0.95–0.99 probs | — |
| `needle_embed` on 5.3 s | 33,792 floats = 66 frames × 512 | — |

I didn't reproduce the WER benchmarks, the M4 Pro latency figures, keyword biasing, `--audio-depth`, or the combined Needle+Whistle tool-call path. TTS audio is easier than real speech, so treat these results as a smoke test, not as accuracy evidence.

## Comparison

| | Whistle | Whisper base (multilingual) | Moonshine tiny v2 | Vosk small models |
|---|---|---|---|---|
| Size | 16.9 MB | 145 MB fp32 | 42 MB int8 | ~40–50 MB per language |
| Languages | 7 (one per clip) | ~99 | English | one per model |
| Runtime | closed C++ engine, 17 targets incl. MCU-class/WASM | PyTorch / whisper.cpp (open) | ONNX / own runtime (open) | Kaldi (open) |
| Silence handling | hard gate → empty output | known hallucination on silence | — | VAD-driven |
| Word timestamps | yes | yes | — | yes |
| Built-in tool calling | yes (with Needle) | no | no | no |
| Weights license | Apache-2.0 | MIT | MIT | Apache-2.0 |

whisper.cpp with a quantised `tiny`/`base` model is the obvious open-runtime alternative. Whistle's pitch is a much smaller file and a fused speech-to-tool-call path, and the cost is a closed engine.

## Self-Hosting Notes

- Minimal path with no dependencies: download a platform folder (`needle download linux-x86_64`) plus `whistle.cact`, then run `./needle --model whistle.cact --audio clip.wav`. Or `dlopen` the shared library and call the 4-function C API.
- Pin and checksum the engine and weights yourself, and vendor them. Don't let production devices pull from HF `main`.
- Set `NEEDLE_TELEMETRY=0` (or `DO_NOT_TRACK=1`) if you use the Python package.
- Feed ≤30 s 16 kHz mono chunks. For long audio, put your own VAD and segmenter in front, and segment by language if users code-switch.
- Measure TTFT on your actual target CPU. The published numbers come from Apple silicon.

## Reusable Patterns

- **Silence gate before decode:** a cheap loudness-range check that short-circuits to an empty result. It's an easy fix for ASR hallucination on silence in any encoder-decoder stack.
- **Cross-attention K/V computed once per clip and shared by every beam**, so beam width costs decoder caches, not encoder passes.
- **Keyword biasing via Aho-Corasick alongside beam search,** instead of retraining or prompt-prefixing.
- **"Laddered" depth training,** where every decoder depth is a valid model, so one file serves several device classes.
- **Release gate:** refuse to publish a package that pins a binary artifact that isn't uploaded yet (`unpublished_engine_wheels()` in the release workflow).

---

**Attribution:** Cactus-Compute/whistle and cactus-compute/needle, Apache-2.0
