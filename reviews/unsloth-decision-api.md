# Unsloth Decision API: local Laya behind a Jev-compatible endpoint (unsloth.ai docs + unslothai/unsloth Studio)

**Source:** https://unsloth.ai/docs/models/decision-laya (Unsloth docs, "Run and Serve Decision Models Locally with Unsloth: Laya + Jev API")
**Backing repo:** https://github.com/unslothai/unsloth, `studio/backend/routes/systemone.py`, `core/systemone/`, `utils/systemone_settings.py`, `vendor/laya/`
**License:** Split. The Unsloth core library is Apache-2.0, but everything under `studio/` carries `SPDX-License-Identifier: AGPL-3.0-only` (`studio/LICENSE.AGPL-3.0`). That covers the Decision API route, runtime and settings, so you can read and learn from them, but copying them into a network service brings AGPL obligations. The vendored `laya` 0.3.5 package is Apache-2.0 (`LICENSE.laya`, byte-identical to the PyPI wheel). The Laya weights (`convaiinnovations/laya` on Hugging Face) are pulled at runtime and aren't in the repo.
**Reviewed:** 2026-09-29 (unslothai/unsloth commit `3617ea6`, latest release `v0.1.900-beta`; upstream Laya at v0.3.22)
**Stack:** FastAPI route + FastMCP tool inside Unsloth Studio. The vendored pure-Python `laya` runs over torch/transformers/safetensors/huggingface_hub/numpy. Device paths are CPU (the default), CUDA/XPU, MPS, and MLX via `unsloth_zoo.mlx.decision`. The model is served at `POST /v1/systemone` and exposed as an MCP `decide` tool at `/mcp/decisions`.
**What it is:** Unsloth Studio (the desktop/web app) can now serve Laya, an open typed-decision encoder model, through a request/response shape that mimics TypeSafe's hosted "Jev" System One API. Existing `typesafe-sdk` clients switch over by changing `TYPESAFE_BASE_URL` to `localhost:8888`.

---

## Verdict

✅ **Act on this, if you already run or are willing to run Unsloth Studio and want Jev-style typed decisions offline. This is the lowest-friction way to get Laya behind a Jev-compatible API, and the server code is more careful than the docs page lets on. Don't treat it as a drop-in Jev clone: confidence semantics differ, the vendored Laya is 17 patch releases behind upstream, and weights download unpinned.**

What's good:
- **Real Jev wire compatibility.** `model` aliases `default`, `laya`, `jev-latest`, `jev-preview` and `openjev-latest` all resolve to the configured checkpoint (`catalog.DEFAULT_ALIASES`). Responses carry an `x-typesafe-request-id` header and the same `noul`/`choice`/`score` answer shapes. The limits in the docs (64 questions, 255 options per choice, 10 score levels) are the constants the route enforces. The route also caps state at 200k characters and a single question at 20k.
- **Refuses what it can't honor.** Unknown top-level fields (for example OpenJev's `images` extension) return a 400 instead of being silently dropped, because dropping them would answer a different question. A state that overflows the context window returns a 422 instead of a quietly truncated answer.
- **Careful keyless mode.** "Keyless API access" is off by default. When it's on, the `inference` scope lists routes one by one (`/v1/systemone` and `/mcp/decisions` are in it), and admission refuses anything with an `Origin` header, a cross-site `Sec-Fetch-Site`, a non-literal `Host` (a DNS-rebinding guard), IPv4-mapped/unspecified host literals, Colab/public-tunnel launches, and installs with managed accounts. A keyless caller can't switch to a non-default Laya checkpoint, which would trigger a download.
- **Vendored, hash-checked runtime.** `vendor/laya_manifest.json` pins the wheel sha256 plus per-file hashes. It's loaded by file path so a stray `pip install laya` can't shadow it, and it never `pip install`s at runtime. Downloads use `snapshot_download` with an `allow_patterns` allowlist (config, `model.safetensors`, `encoder/`, `tokenizer/`), so they're safetensors only, with no `trust_remote_code` and no pickle.
- **Operational fallbacks that match the docs.** CUDA/MPS/MLX OOM moves the model to CPU and retries. FP16 overflow (non-finite logits) re-runs in FP32. Requests queue behind a bounded semaphore (8 pending), so a burst can't starve Studio's other sync routes. A load failure backs off for 60 s instead of hammering the Hub. Today's commit (`1bf9702`) forwards large GPU requests in token-budgeted chunks. CPU still runs a single forward, because the code notes chunking was 5× slower there.

What gives pause:
- **Confidence isn't Jev's.** The docs say so, and the code confirms it: `noul` confidence is `max(p, 1-p)`, and choice/score use Laya's `confidence_from_probs`. Any Jev thresholds you tuned must be re-tuned on `probabilities`.
- **Vendored Laya 0.3.5 vs upstream 0.3.22.** Upstream shipped abstention, ONNX parity, calibration-path loading and budget diagnostics after 0.3.5. The vendored copy is deliberately frozen (the runtime reaches into `Agent._to_internal` and `laya.common.collate_items`), so upstream fixes arrive only when Unsloth re-vendors. It does include 0.3.5's calibration-temperature clamp (`[0.5, 5.0]`, NaN/inf → 1.0), and the runtime applies it to both the global and per-option-count temperatures.
- **Unpinned weights.** `snapshot_download("convaiinnovations/laya", ...)` passes no `revision=`, so every fresh install pulls the current `main` of a fast-moving model repo. That's a reproducibility and supply-chain gap next to the hash-pinned code. Offline mode and local checkpoint directories (`UNSLOTH_SYSTEMONE_MODEL=/path`) are available if you need to pin.
- **Option-label trimming.** The heads share a fixed `head_max_len` (192 tokens by default). The docs admit that past ~20 described options the labels get trimmed, and options that overflow entirely raise an error. Large taxonomies need a shortlist step first.
- **A heavy host for a 678 MB model.** You're running all of Unsloth Studio (training, chat, MCP, RAG, tunnels) to serve one encoder. If you just want a Laya endpoint, upstream `laya` has its own serve mode, and `laya-mlx` covers Macs.
- **Vendor performance claims are unverified.** "Well under a second on most CPUs" and the 10–20 s first load are Unsloth's numbers. Nothing here was benchmarked.

---

## What It Is

Laya is a non-autoregressive "System 1" decision model: a ModernBERT (English) or mmBERT (multilingual) encoder with decision heads. It reads a state plus typed questions and returns probabilities in one forward pass, with no generated tokens. TypeSafe's hosted Jev is the commercial model that popularized this API shape. Unsloth's page positions Laya as "an open Jev alternative" and shows Studio serving it:

1. Settings → API → **Decision API** → **Serve requests** downloads the default checkpoint (`laya-multilingual`, 678 MB).
2. Authenticate with a Studio API key (`sk-unsloth-…`), or turn on keyless inference for localhost/private LAN.
3. `POST /v1/systemone` with `{model, state, questions}`. `state` can be a string or any JSON.

The docs show a real-time "packing list" demo updating as the user types, and a support-ticket example that routes the team, detects a refund request and scores urgency in one call.

## Stack

| Layer | Detail |
|---|---|
| HTTP | FastAPI `APIRouter`, Pydantic request models (`extra="forbid"` on questions, extras rejected on the request) |
| MCP | FastMCP server "Unsloth Decisions", single `decide` tool, hidden from `list_tools` when the API is off, Studio auth wrapped around the ASGI app |
| Runtime | `core/systemone/laya_runtime.py` (1,243 lines): lazy background load, bounded admission, head-sequence cache (1,024 entries), prefix tokenization for long states, chunked GPU forwards |
| Model code | Vendored `laya` 0.3.5 (Apache-2.0), 9 files hash-pinned |
| Checkpoints | `laya-multilingual` (mmBERT-base, 1,024 ctx), `laya-english` (ModernBERT-large, 512 ctx), `laya-typed-decisions` (English fine-tune on invoices/security incidents/customer service/agent traces, 1,024 ctx), or a local directory |
| Devices | CPU default. GPU opt-in (CUDA/XPU after an allocation probe, MPS, MLX if `unsloth_zoo.mlx.decision` imports) |
| Config | Owner-level settings DB. Env overrides `UNSLOTH_SYSTEMONE_DISABLE`, `_MODEL`, `_DEVICE`, `_SUBFOLDER` |

## Key Features

### Three question types
- `noul`: P(yes). Optional criteria may only have the keys `true`/`false`.
- `choice`: a `{label: description}` dict. Returns an argmax label, a per-label probability and a confidence.
- `score`: a 1–10 ordered list, lowest first. Returns the expected level (Σ i·pᵢ), a legend and per-level probabilities.

### Jev migration
`pip install typesafe-sdk`, then set `TYPESAFE_BASE_URL=http://localhost:8888` and `TYPESAFE_API_KEY=sk-unsloth-…`. The SDK's default `jev-latest` maps to whatever checkpoint the Studio owner selected.

### MCP tool
The same decision path is exposed as an MCP tool, so agent clients connected to Studio's MCP endpoint can call `decide(state, questions)` without writing HTTP code. It always uses the configured default checkpoint.

## Architecture

The request flow is: Pydantic validation → `_require_enabled()` (404 if the owner hasn't turned it on) → reject extra fields → `catalog.resolve(model)` → keyless-model guard → per-question validation → `laya_runtime.decide()`.

The runtime doesn't call `laya.Agent.predict` directly. It has its own `_predict` fast path. Each question's head sequence (the instructions and options without the state) is built once and cached by its JSON. The state is tokenized once, into the smallest room left by the longest head, using growing-prefix tokenization so a 200k-character state isn't fully tokenized when only 1k tokens fit. The rows are then spliced and collated into one batch. Calibration and confidence come from vendored `laya.common`. The test suite has a gated parity test (`SYSTEMONE_TEST_LAYA=<snapshot>`) that compares this fast path against `laya.Agent.predict`. It needs downloaded weights, so it doesn't run by default.

Model state is a process-wide singleton behind `_state_lock`/`_run_lock`. Only one checkpoint is resident at a time, and switching evicts the old one and releases memory. Settings are installation-wide and read in owner context, so a managed account's API key sees the owner's switch.

## Security

- **Bind/auth defaults:** the Studio CLI defaults to `--host 127.0.0.1`. `/v1/systemone` depends on `get_current_subject` (a session or API key), so it's authenticated unless the owner opts into keyless.
- **Keyless:** off by default and fail-closed. An unreadable settings DB resolves to off, and a read that races a write is discarded via a generation counter. The admission logic is unusually thorough, with documented browser measurements for `Sec-Fetch-Site`, DNS rebinding, IPv4-mapped loopback and `0.0.0.0`. Server-side tools stay force-disabled for keyless callers unless the owner grants them separately. Note that the docs' suggested toggle ("Keyless API access → Chat and inference") opens *all* inference routes, not just decisions. That includes `/v1/chat/completions`, which is a bigger grant than the Decision API alone.
- **Model loading:** safetensors via an allowlist, no remote code, and a vendored model library with a hash manifest. The weak point is the unpinned Hub revision (see above).
- **Input limits:** state ≤200k chars, question ≤20k chars, ≤64 questions, ≤255 options, ≤10 levels, 8 pending requests, a 20 s load wait and a 30 s run wait. `Retry-After` is set on 503s.
- **CI:** the Studio backend and consolidated test workflows pin every action to a full commit SHA (7 and 6 `uses:` respectively, 0 tag pins). CodeQL, lockfile-audit and security-audit workflows exist.
- No secrets matched in the Decision API files. There's no `shell=True`/`eval` in the route or runtime.

## Maturity

unslothai/unsloth: ~77k stars, 7.1k forks, ~1.16k open issues, created 2023-11, pushed 2026-09-29 (five commits that day, including the Laya chunking change). Releases are `v0.1.x-beta` and ship every few days. Upstream NandhaKishorM/laya is 11 days old (created 2026-09-18), with ~28.6k stars and a release every few days (v0.3.20 on 09-24, v0.3.21 on 09-27, v0.3.22 today). It's a very young model family being integrated fast. The docs page was "last updated 17 hours ago".

### Validation on 2026-09-29

Static only. The Studio backend test suite couldn't run here: installing `fastapi`/`fastmcp`/`pytest` was blocked by this host's package-intelligence gate in unattended mode, and the model parity test needs ~700 MB of weights anyway.

- `git clone --depth=1 https://github.com/unslothai/unsloth` → `3617ea6`.
- Recomputed sha256 for all 9 entries in `vendor/laya_manifest.json`: **9/9 match**, so the vendored Laya really is the unmodified 0.3.5 wheel content.
- `ast.parse` over the route, runtime, catalog, settings, keyless module, the 8 vendored laya modules and the test module: **14/14 parse**.
- Counted **97 test functions** in `studio/backend/tests/test_systemone.py` (2,055 lines). **6** references to `SYSTEMONE_TEST_LAYA` gate the real-weights parity checks. None were executed.
- Confirmed by reading the code: the doc limits (64/255/10), the alias list, CPU default and GPU→CPU OOM fallback, `clamp_temperature` applied at load, and no `revision=` on `snapshot_download`.
- Not reproduced: latency ("well under a second on most CPUs"), 10–20 s cold load, RAM minimums (4 GB/5 GB), and calibration quality.

## Comparison

| | Unsloth Decision API | Upstream `laya` | laya-mlx | TypeSafe Jev (hosted) |
|---|---|---|---|---|
| Runs where | Studio on macOS/Windows/Linux, CPU/GPU/MLX | Anywhere with torch | Apple Silicon only | Vendor cloud |
| API shape | Jev-compatible `/v1/systemone` + MCP | Python `Agent.predict`, own serve | Python/CLI | Native |
| Laya version | 0.3.5 (vendored, frozen) | 0.3.22 | Synced to 0.3.5 | n/a (different model) |
| Weights pinning | No revision pin | User's choice | Pinned revisions + checksums published | n/a |
| Footprint | Whole Studio app | Library | Library | None local |
| License | AGPL-3.0 (Studio code), Apache-2.0 (laya) | Apache-2.0 | Apache-2.0 | Proprietary |
| Data locality | Local | Local | Local | Leaves the machine |

See also: [laya-mlx.md](laya-mlx.md) (MLX port with parity data) and [jev-ecosystem-roundup.md](jev-ecosystem-roundup.md) (projects built on the Jev API, most of which could point at this endpoint).

## Self-Hosting Notes

- Keep the default CPU device unless you've measured a need. The GPU path pins the model in VRAM until you **Unload** it.
- Pin weights yourself. Pre-download a known `convaiinnovations/laya` revision into a directory and set `UNSLOTH_SYSTEMONE_MODEL=/that/dir` (with `UNSLOTH_SYSTEMONE_SUBFOLDER` for multilingual/typed-decisions), or run offline after the first download.
- Prefer an API key over keyless. If you do go keyless, remember the scope covers chat/completions too.
- Re-tune thresholds on `probabilities`, not `confidence`, when migrating from Jev.
- For >20 choice options, shortlist first (vendored `laya.shortlist` exists) or split the question.
- To lock the feature off fleet-wide, set `UNSLOTH_SYSTEMONE_DISABLE=1`, which the UI can't override.

## Reusable Patterns

- **Reject unknown fields on a compatibility API.** When you mimic someone else's API, silently ignoring an extension field changes the question's meaning. Refuse it with a 400 that names the field.
- **Vendor with a hash manifest and file-path import.** You pin the exact code the adapter reaches into, keep a user-installed copy from shadowing it, and a test fails if the manifest drifts.
- **Fail-closed auth toggles with a generation counter.** For settings that remove an auth requirement, a stale or unreadable read must resolve to "closed".
- **Per-question head cache + a single state tokenization.** For encoder "many questions over one document" workloads, build the question sequences once and splice the state in, instead of re-tokenizing per row.

---

**Attribution:** unslothai/unsloth (Studio code AGPL-3.0-only; core Apache-2.0), Unsloth documentation (unsloth.ai/docs); Laya by Convai Innovations / NandhaKishorM/laya, Apache-2.0
