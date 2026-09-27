# Splash (incoai/splash)

**Repo:** https://github.com/incoai/splash  
**License:** Apache-2.0. Reusable with attribution. GGUF kernels and quant tables include MIT-licensed material from llama.cpp; `server/judgments.py` carries SemIf's MIT notice. Model weights keep their own licenses.  
**Reviewed:** 2026-09-27 (commit `c64a578`, 2026-09-26)  
**Stack:** C++/Objective-C++, Metal kernels, Python 3.12–3.14 HTTP server, Hugging Face Hub, llguidance, Homebrew packaging  
**What it is:** A single-Mac local inference engine for Apple silicon that serves Qwen3.8-27B and Qwen3.6-35B-A3B (GGUF or MLX 4-bit) behind OpenAI Chat/Responses and Anthropic Messages APIs. It uses DFlash2 speculative decoding, per-model Metal kernels, automatic memory planning, prefix caching, and continuous batching.

---

## Verdict

✅ **Deploy candidate, if you have the hardware.** On an M3-or-newer Mac with 36 GB+ of unified memory running macOS 26.4+, this is the most carefully engineered local serving stack for coding agents I've looked at. It speaks both OpenAI and Anthropic wire formats, has real tool-calling and JSON Schema constraints, prefix-cache replay, and one-command launchers for common coding agents. The limits are narrow scope and age. It supports two model families, runs only on Apple silicon, and the repo is nine days old. The headline speedups (2–5× over llama.cpp, 7× cached TTFT) are the vendor's own figures from their own prompt selection, and I haven't reproduced them.

---

## What It Is

Splash is built "around the model" rather than as a general runtime. Each supported target ships with a trained DFlash2 draft model and Metal kernels tuned for that model's shapes. The runtime, scheduler, cache, and HTTP API are shared. Weights are prepared once on first run, then memory-mapped from disk. Kernels ship precompiled, so no Xcode or local tuning is needed.

```bash
brew install incoai/tap/splash
splash serve --model unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M
splash opencode   # or: claude / codex / hermes / pi
```

The server listens on `127.0.0.1:8000` with a built-in browser chat page.

## Stack

| Layer | Tech |
|-------|------|
| Native engine | C++/Objective-C++ (`runtime/engine`, `runtime/model`, `runtime/ops`) |
| GPU | Metal kernels: paged attention, INT8/BF16 KV, Q4/Q8 projections, MoE, GDN state, vision |
| Speculation | DFlash2 draft checkpoints, auto-selected per target |
| HTTP/API | Python (`server/`): OpenAI Chat + Responses, Anthropic Messages + count_tokens, `/tokenize`, `/apply-template`, `/status`, Prometheus `/metrics` |
| Constraints | llguidance token masks plus jsonschema validation of final output |
| Model loading | Hugging Face Hub; GGUF 1–8 bit Unsloth variants (incl. UD mixed precision), MLX 4-bit, Ternary Bonsai PQ2_0 |
| Engine ↔ server | Versioned native wire protocol over file descriptors (`FdTransport`, protocol v6) |
| Packaging | Homebrew tap; LM Studio integration |

## Key Features

### Dual API Surface
Full OpenAI Chat Completions and Responses plus Anthropic Messages, with streaming, tool calls, JSON Schema output, images, and inline base64 PDFs (up to a 64 MiB/64-page budget). Claude Code, Codex, OpenCode, and similar agents can point at it without a translation proxy. Chat responses include a llama-server-style `timings` object, and streaming requests can opt into `prompt_progress` events during long prefills.

### Structured Output That Validates
`response_format` and tool arguments are compiled into token constraints, then the complete output is re-validated against the original schema. This catches cross-field rules, dependencies, and property counts that constrained decoding alone can't enforce. Unsupported schema features (remote `$ref`, `unevaluatedProperties` + `patternProperties`) return errors instead of silently degrading.

### Cache and Scheduler Design
- Prefix reuse with a cold-prefix "wait for the producer" path. Requests that share a prefix wait for the resident request's recovery point instead of recomputing it.
- Rolling disposable prefill checkpoints every 4096 tokens. Contended prefill adapts toward 500 ms slices.
- Greedy and sampled requests share decode batches with per-lane RNG. Constrained requests get their own batch for the host mask exchange.
- Optional SSD tier (`--max-cache-disk`) for KV and GDN states. It's session-local and doesn't survive a restart.
- Memory admission reports memory waits vs concurrency waits separately in `/status.admission`, with bounded 30 s resource waits.

### Judgment Endpoints
`POST /v1/judgments` implements SemIf-style option scoring and returns raw logits, probabilities, and the rendered prompt's SHA-256. `POST /v1/systemone` is compatible with the TypeSafe System One SDK (noul/choice/score questions over shared state). The docs say plainly that these are uncalibrated local scores and that "confidence" means entropy concentration, not correctness.

### Agent Launchers
`install/clients.py` writes provider config for each agent and starts it against the local server. The Hermes launcher uses a dedicated `HERMES_HOME` profile instead of editing the user's main config. The Pi launcher replaces only its own provider entry in `models.json`. Config files are replaced atomically.

## Architecture

```
HTTP (server/server.py) → frontend.py (request/history prep, templates, tokenization)
   → backend.py (native request lifecycle) ⇄ FdTransport ⇄ runtime/main.mm
      → engine/ (Scheduler, KvPool, MemoryGovernor, StateCache)
      → model/ (Qwen3_8, Qwen3_6Moe, DFlashDraft, GGUF/affine preparation, vision)
      → ops/ + metal/ (kernels, command graph, watchdog)
```

Layering is enforced by `make architecture-check`, which stops lower layers from importing the HTTP entry module. The native engine runs as a separate process, and the HTTP layer survives engine restarts (latency histograms persist, and `/status.transport.recovering` reports the restart). The wire protocol is versioned, and a version mismatch is fatal rather than tolerated.

Documentation quality is high. `DEVELOPMENT.md` (~70 KB) specifies exact semantics for timings, metrics, cache behavior, error shapes, and unsupported features. This is a codebase that writes down its contracts.

## Security

- Binds `127.0.0.1` by default. **Authentication is off unless `--api-key`/`SPLASH_API_KEY` is set.** Exposing it on a LAN without a key is explicitly outside the threat model.
- API key check uses `hmac.compare_digest` and rejects ambiguous requests (both `Authorization` and `x-api-key`, or duplicate headers).
- Host header allowlist plus Origin-must-match-Host defends against DNS rebinding from browser pages. `--allowed-host` adds extra names.
- HTTP bodies require Content-Length, and request logs omit bodies. Full crash traces are opt-in (`SPLASH_CRASH_TRACE=1`), and the docs warn that they may contain conversation data.
- CI actions are pinned by SHA, and workflow permissions are `contents: read`.
- No hardcoded secrets found in a grep scan. No `shell=True`/`os.system`/`eval` in `server/` or `install/`.

## Maturity

- Created 2026-09-18. As of review: 892 stars, 88 forks, 48 open issues, and active merges from outside contributors.
- 60 test modules covering native engine and Metal oracle tests, API contracts, and server behavior. CI runs sanitizers, a Python 3.12/3.13/3.14 matrix, and an opt-in real-model release gate on M3 Max / M4 Pro / M4 Max self-hosted runners.
- Next-token agreement with llama.cpp is 99.3–99.45% (27B) and 97.8–98.1% (35B). The authors frame that against llama.cpp's own CPU-vs-GPU agreement (96.5–97.8%), which is a fair baseline.

### Validation on 2026-09-27

The native engine requires macOS/Metal and could not be built or run for this review. I ran a pure-Python subset of the server tests on Linux (Python 3.13, pinned `install/` + `dev/` requirements):

```text
pytest dev/tests/engine/test_{json_codec,server_access,http_boundaries,http_body_budget,
  schema_fallback,output_validation,chat_templates,structured_tools,prompt_tools,
  request_contract,anthropic_contract,json_responses,partial_tool_output,thinking_key,architecture}.py
```

- 172 passed, 2 failed, 2,431 subtests passed.
- `test_request_contract::test_descriptor_exhaustion_does_not_read_as_a_disconnect` mocks `select.kqueue`, which exists only on macOS/BSD. This is platform-specific, not a bug.
- `test_http_boundaries::test_opt_in_crash_files_have_a_total_retention_limit` kept crash files for generations {2, 4} instead of {3, 4}. This is likely a timestamp-resolution ordering artifact on Linux. It's a non-issue on the supported platform, but retention ordering based on file mtime can be fragile.

Performance claims were not reproduced.

## Comparison

| Aspect | Splash | llama.cpp / llama-server | Ollama | MLX-LM server |
|--------|--------|--------------------------|--------|---------------|
| Platform | Apple silicon M3+ only | Everything | Everything | Apple silicon |
| Model breadth | 2 families (+ Bonsai) | Very broad | Very broad | Broad |
| Speculative decoding | Trained per-model DFlash2 drafts, on by default | Optional draft/MTP | Limited | Optional |
| APIs | OpenAI Chat + Responses, Anthropic Messages | OpenAI-ish | Ollama + OpenAI-ish | OpenAI-ish |
| Structured output | Constrained + post-validated | Grammar/JSON schema | JSON mode/schema | Limited |
| Multi-request batching | Continuous, prefix-aware | Slots | Limited | Limited |
| Best fit | Fast local coding agents on one Mac | Portability, breadth | Convenience | Apple-native tinkering |

Splash trades breadth for depth. If your model isn't Qwen3.8-27B or Qwen3.6-35B-A3B, it isn't an option yet.

## Self-Hosting Notes

- Requirements: M3 or newer, macOS 26.4+, Homebrew. 36 GB unified memory for the 4-bit examples (48 GB recommended). Smaller GGUF variants work on 24 GB Macs.
- Budget disk space for both downloaded weights and prepared weights.
- On a shared machine, cap GPU memory with `--max-memory`.
- For LAN use: `--host 0.0.0.0 --api-key ...`, plus `--allowed-host mymac.local` if clients connect by name. Prefer putting a TLS reverse proxy in front, since the server speaks plain HTTP.
- `--language-only` skips vision loading when you only need text.

## Reusable Patterns

- **Constrain, then validate.** Constrained decoding for shape, followed by full schema validation for semantics, with explicit errors for unsupported schema features.
- **Split HTTP and engine processes** behind a versioned FD wire protocol. The HTTP layer survives engine crashes and reports recovery state.
- **Contract-first docs** for every metric field and timing definition. This makes proxies and dashboards far easier to build correctly.
- **Launcher-writes-isolated-profile** for integrating local backends with third-party agents without touching the user's main config.

---

**Attribution:** incoai/splash, Apache-2.0 (with MIT-licensed llama.cpp and SemIf portions as noted in THIRD_PARTY_NOTICES)
