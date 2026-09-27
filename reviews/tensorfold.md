# TensorFold (ashhart/TensorFold)

**Repo:** https://github.com/ashhart/TensorFold  
**License:** MIT. Reusable with attribution. Parts are adapted from mlx-lm (MIT), Hugging Face transformers (Apache-2.0, license text shipped in `LICENSES/`), z-lab/dflash (MIT, vendored unmodified), and ExLlamaV3's EXL3 format (MIT). Model weights keep their own licenses. The optional GLM DFlash2 drafter is CC BY-NC-ND 4.0, so non-commercial only.  
**Reviewed:** 2026-09-27 (commit `bb4b4a3`, v0.3.4.1)  
**Stack:** Python 3.11+, MLX / mlx-lm with custom Metal kernels (macOS), PyTorch + Triton + CUDA C++ kernels (Linux/NVIDIA), stdlib `http.server`, Hugging Face Hub  
**What it is:** A local LLM server behind an OpenAI-compatible endpoint. It uses speculative decoding (DFlash2 draft models, MTP heads, n-gram/context drafts) with per-family kernels written so that drafted output is **byte-identical** to one-token-at-a-time decoding. It runs on Apple Silicon (M1–M5) and on NVIDIA GPUs, with DGX Spark as the main CUDA target, including 2-node tensor parallel.

---

## Verdict

📚 **Study, and ⚠️ worth trying if you run one of its exact checkpoints.** The core idea is well thought out and well documented. Sampling uses hash-seeded Gumbel-max per position, and the kernels are row-invariant, so a verify pass over N drafted rows gives each row the same bits as a one-row step. Draft acceptance then becomes plain equality, and speculation changes speed only, never text. That property is rare, and it's valuable for reproducible agent runs and eval replays. As a deployment target, though, it's very early: a single author, versions 0.3.2 through 0.3.4.1 all cut within one day, no CI, no API auth, and support for four model families pinned to specific (mostly third-party-converted) checkpoints. The speed tables are the author's own measurements, and I haven't reproduced them.

---

## What It Is

`tensorfold serve <hf-repo>` downloads a checkpoint, picks a model-family package from `config.json`, loads it with that family's Metal or CUDA kernels, and serves `/v1/chat/completions` and `/v1/completions` on `127.0.0.1:8080`.

```bash
pip install git+https://github.com/ashhart/TensorFold.git
tensorfold serve Vontra/NVIDIA-Nemotron-3.5-Lightning-30B-A3B-MLX-4bit --context 65536
```

Supported families (tested checkpoints):

| Family | Checkpoint | Mac | CUDA |
|---|---|---|---|
| Nemotron 3.5 Lightning 30B-A3B | `Vontra/...-MLX-4bit` (+ MTP head) | 32 GB+ | no CUDA engine yet |
| Qwen3.8-27B | `Vontra/Qwen3.8-27B-MLX-4bit` + `z-lab/Qwen3.8-27B-DFlash2` | 32 GB+, fastest on M5 | 1 or 2 Sparks |
| Qwen3.8 Flash Next | `Vontra/...-MLX-4bit-MTP` (113 GB) | 192 GB+ | 1 or 2 Sparks |
| GLM-5.3-Flash | MLX 4-bit, experimental EXL3 | no | 2 Sparks |

`tensorfold info MODEL` classifies an arbitrary checkpoint from `config.json` alone. Unsupported formats (NVFP4, GPTQ, AWQ) are refused before anything downloads.

## Stack

| Layer | Tech |
|-------|------|
| CLI | `cli.py`: `serve`, `pull`, `models`, `info`, `update` |
| HTTP | stdlib `BaseHTTPRequestHandler` (`server/http.py`, `cuda/server.py`) |
| Engine | `engine/lane_engine.py` (lane batching/verify), `lane_family.py`, exact sampling, prefix snapshots, tool-call drafting |
| Mac kernels | `kernels/qwen/dense/v1` (lane qmm/attention/GDN, row-exact matvec, simdgroup matmul), `kernels/qwen/flash_next/v1`, `kernels/nemotron/lightning/v1`, inline Metal via MLX |
| CUDA kernels | `families/<name>/cuda/`: Triton + `.cu` sources built on first use with the container's nvcc; NCCL for 2-node TP |
| Drafters | DFlash2 (vendored z-lab MLX model plus a PyTorch port), MTP heads, n-gram/context drafts |
| Size | ~40k lines of Python across 198 files, 53 test files (~8.5k lines) |

## Key Features

### Exactness as a contract
Each token is `argmax(logit/T + g(seed, position, token))` over the top-k/top-p set, where `g` is Gumbel noise from a hash. That's an exact sample that depends only on the row's logits and its position. The kernels are written so a row's arithmetic doesn't depend on how many rows share the pass, and a load-time check disables drafting when the installed MLX/GPU combination breaks that. For example, on M5 with MLX 0.32.2, Nemotron falls back to serial decoding. Clients can send `"draft": false` to get the serial reference and diff it. The default seed is a hash of the prompt, so the same conversation gets the same reply.

### Row-invariant kernels on every Apple GPU
Metal 4 tensor units (M5) drive the fast lane kernels. M1–M4 get a separate row-exact 4-bit matvec and simdgroup matmul, which verify windows of 2–8 rows, and a per-round draft count chosen from measured costs and live acceptance. The recipe book (`docs/recipes/README.md`) covers the "three ways to make projections row-invariant" and a "traps we hit" section. For anyone doing deterministic inference, this is the most useful document in the repo.

### Grid-aligned prompt caching
In 0.3.4.1, prompts prefill through MLX's own forward in chunks on a fixed 2,048-token grid, and caches are kept only at grid points. A resumed conversation re-prefills from the last grid point, so it gets the same bits as the same conversation sent fresh. The system block is snapshotted to disk and reused across sessions and restarts.

### CUDA / DGX Spark engines
These read the same MLX 4-bit checkpoints, run inside NVIDIA's PyTorch container, and split over two Sparks via `--tp 2 --rank R --master HOST`. The author reports 1.6–3.1× over vLLM with MTP=3 on the same OpenAI client. GLM greedy requests measure the MTP head against DFlash2 and keep whichever commits more tokens per millisecond.

### Agent-oriented details
Thinking budget (`--thinking-budget`), tool-call argument normalisation for chat templates, tool requests that draft as many tokens as pay, `priority: "background"` requests that yield to interactive traffic, and a `RUNBOOK.md` written for AI agents to do the install themselves.

## Architecture

```
cli.py serve → hub.py (HF download, family detection, checkpoint checks)
  → families/<name>/ (forward pass, draft heads, KERNEL_PACKAGE)  ── Mac: kernels/<family>/v1 (Metal via MLX)
                                                                   └ CUDA: families/<name>/cuda (Triton + .cu, NCCL)
  → engine/lane_engine.py (draft → multi-row verify → equality accept) + exact_sampling + prefix_snapshots
  → server/http.py + app.py (request queue, caches, streaming)  |  cuda/server.py (ThreadingHTTPServer)
```

Kernel packages are versioned (`.../v1`) and named by each family, so a kernel rewrite can live next to the old one. The code is dense and heavily commented with the reasoning behind numerics choices. Commit messages read like changelogs and include per-chip tok/s. Docs lag the code in places: README still carries a "known limit" about cache-dependent last bits, which the 0.3.4.1 commit says the new grid prefill removes.

## Security

- Binds `127.0.0.1:8080` by default. **There is no authentication at all**: no API key option, no Host/Origin checks. `--host 0.0.0.0`, which the DGX Spark instructions use, exposes an unauthenticated completion endpoint to the network. A local page could also reach it via DNS rebinding.
- The HTTP layer trusts `Content-Length` with no body size cap. That's fine on localhost, but it's another reason not to expose the server directly.
- `TENSORFOLD_REQUEST_LOG=path` appends every full request body to disk (opt-in, off by default). The DFlash drafter has an opt-in `pickle.dump` trace for offline studies. Both only write, and nothing is unpickled.
- `serve` makes one request a day to the GitHub releases API (opt out with `--no-update-check` or `TENSORFOLD_NO_UPDATE_CHECK=1`). `tensorfold update` runs `pip install --upgrade git+https://github.com/ashhart/TensorFold.git@<tag>`, which trusts whatever the tag points to. Pin a commit if that matters to you.
- The tested checkpoints come from a third-party conversion namespace (`Vontra`), not the original model vendors. Weights are safetensors (no pickle), but you're trusting that converter's fidelity.
- No hardcoded secrets in a grep scan. No `shell=True`, `os.system`, or Python `eval`/`exec`. Every `eval(` hit is `mx.eval` (MLX graph evaluation). `subprocess` is used only in `update.py`, with list arguments.
- No `.github/` directory, so no CI and no action-pinning surface.

## Maturity

- GitHub: 457 stars, 40 forks, 25 open issues. Created 2026-06-19; last push 2026-09-27. One contributor (18 commits). Releases v0.3.2, v0.3.3, v0.3.4 and v0.3.4.1 all landed within about 13 hours on 2026-09-26/27. The 0.3.4 commit calls itself a "work-in-progress snapshot".
- `pyproject.toml` says Development Status 3 (Alpha). `mlx-lm` is pinned `<0.32` because the code builds on its model classes and caches, so expect breakage when mlx-lm moves.
- Tests: 53 files, including GPU kernel oracle tests (skipped without an M5 or an NVIDIA GPU) and a `tests/cuda/` suite. There's no CI to run any of them.

### Validation on 2026-09-27

Linux x86_64, no GPU, Python 3.13, with numpy / huggingface-hub / tokenizers / safetensors / jinja2 / pytest (no MLX, no torch):

```text
pytest -q --ignore=tests/cuda --ignore=tests/test_alternating_kv.py --ignore=tests/test_dflash_tree_search.py
```

- **129 passed, 4 failed, 28 skipped.**
- 17 modules skip cleanly via `importorskip("mlx.core")`. Two modules (`test_alternating_kv.py`, `test_dflash_tree_search.py`) import MLX unguarded and fail collection on Linux, so they were excluded.
- All 4 failures are platform-only. Two need `mlx` inside the test body (`test_exact_sampling::test_nucleus_without_top_k...`, `test_hub_and_checks::test_every_family_names_an_importable_kernel_version`). One needs `torch` (`test_serve_finishes_a_config_only_cache_before_loading` routes to the CUDA engine on Linux). One expects a Mac-only context-window error but gets "Nemotron has no CUDA engine yet" because `--backend auto` picks CUDA off macOS (`test_context_override_cannot_exceed_model_window`). The tests assume a Mac host.
- Passing areas include the OpenAI compat layer, streaming, tool-call normalisation, tool drafting, n-gram drafting, lane-engine scheduling with fakes, update logic, and CUDA CLI argument handling.

Byte-identity claims and speed numbers were **not** reproduced. Doing that needs Apple Silicon or NVIDIA hardware and the checkpoints.

## Comparison

| Aspect | TensorFold | Splash | mlx-lm server | vLLM (DGX Spark) |
|---|---|---|---|---|
| Platform | Apple M1–M5 + NVIDIA (CUDA) | Apple M3+ only | Apple Silicon | NVIDIA (and more) |
| Model breadth | 4 families, specific checkpoints | 2 families | Broad | Very broad |
| Speculation | DFlash2 + MTP + n-gram, output byte-identical to serial | DFlash2, standard acceptance | Optional draft | MTP/EAGLE, stochastic acceptance |
| Determinism | Seeded, draft-invariant by design | Per-lane RNG | Basic seeding | Not draft-invariant |
| API | OpenAI Chat + legacy Completions | OpenAI Chat/Responses + Anthropic | OpenAI-ish | OpenAI (broad) |
| Auth | None | Optional key, Host/Origin checks | None | Optional key |
| Multi-node | 2-Spark TP over NCCL | No | No | Yes |
| Maturity | Alpha, single author, no CI | Young but CI'd, multi-contributor | Mature | Mature |

TensorFold's differentiator is exactness under speculation, plus the fact that it covers both Mac and Spark from one codebase. It is weaker than Splash on API surface, auth, and engineering process.

## Self-Hosting Notes

- Mac: Python 3.11+, 32 GB+ for the 27B/Nemotron checkpoints, 192 GB+ for Flash Next. The fastest 27B kernels need an M5-generation GPU. If Nemotron drafting shows as disabled on an M5, pin `mlx==0.31.2`.
- NVIDIA: run inside `nvcr.io/nvidia/pytorch:26.07-py3` with `--network host`. For 2-node TP, add `--device /dev/infiniband --ulimit memlock=-1 --cap-add IPC_LOCK` and set `NCCL_SOCKET_IFNAME`/`NCCL_IB_HCA` if needed.
- Don't use `--host 0.0.0.0` on a shared network without a reverse proxy that adds auth and TLS.
- Pin a commit or tag rather than following `main`. Releases are frequent and self-described as work in progress.
- Check model licenses per checkpoint, especially the non-commercial GLM DFlash2 drafter.

## Reusable Patterns

- **Hash-seeded Gumbel-max sampling per (seed, position, token).** An exact top-k/top-p sample that makes the sampled token a pure function of that row's logits. This lets speculative acceptance become an equality check.
- **Row-invariant verify kernels plus a load-time self-check** that multi-row forwards reproduce one-row steps. Drafting is turned off automatically when the check fails, instead of silently returning different text.
- **`"draft": false` as a built-in serial reference**, so users can diff drafted and serial output themselves.
- **Grid-aligned prefix caches** (fixed 2,048-token boundaries), so resumed conversations are bit-identical to fresh ones.
- **Versioned per-family kernel packages** (`kernels/<family>/<variant>/v1`) named from the family module.
- **An agent-targeted runbook** (`RUNBOOK.md`) that gives install → pull → serve → a check request as explicit steps.

---

**Attribution:** ashhart/TensorFold, MIT (with mlx-lm MIT, transformers Apache-2.0, z-lab/dflash MIT and ExLlamaV3-format portions as noted in THIRD_PARTY_NOTICES)
