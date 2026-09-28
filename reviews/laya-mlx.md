# Laya-MLX (mizorewww/laya-mlx)

**Repo:** https://github.com/mizorewww/laya-mlx  
**License:** Apache-2.0, so free reuse with attribution and NOTICE preservation. `NOTICE` credits the upstream Laya project (NandhaKishorM/laya, Convai Innovations, Apache-2.0) for token-sequence construction, question rendering, confidence calculation, presets, email utilities and the language router. The network is reimplemented in MLX. Weights aren't in the repo. They're either the original `convaiinnovations/*` checkpoints or FP16 re-exports under a third-party Hugging Face account (`aac6fef/*`).  
**Reviewed:** 2026-09-28 (commit `0a85951`, v0.2.0 on PyPI, synced to upstream v0.3.5)  
**Stack:** Python 3.11+, Apple MLX 0.32 (Metal), Hugging Face `tokenizers` + `huggingface_hub`, numpy. Optional `rich` terminal Snake demo. Torch/Transformers only as a test reference.  
**What it is:** An independent, inference-only MLX port of Laya, a non-autoregressive "typed decision" model: a ModernBERT/mmBERT encoder plus decision heads. It returns calibrated probabilities for `choice`, ordered `score` and yes/no (`noul`) questions over text, JSON or conversation state in one forward pass. It generates no tokens. Apple Silicon only.

---

## Verdict

📚 **Study. It's a careful, honestly documented port with real parity evidence, and a good template for "port a HF encoder model to MLX." But the speedup over upstream PyTorch-MPS is modest, the README headline latency is older than the raw data now committed, it's Mac-only, and it already trails a fast-moving upstream (v0.3.5 vs v0.3.21).**

What's good:
- **Parity is measured, not asserted.** All three checkpoints match upstream's argmax on 63/63 validation questions in FP32 and FP16 (378 comparisons). Max calibrated-probability error is ≤5e-6 in FP32 and ≤5.4e-3 in FP16, against tolerances set before measuring. On a 256-example AG News sample, predictions agree 256/256 with upstream, at identical accuracy (0.957 / 0.945 / 0.965). Every timing sample, input hash and output hash is committed.
- **Faithful, not fast-and-loose.** Weight loading is `strict=True` with name and shape validation. ModernBERT's global/local attention alternation, the inclusive sliding-window boundary, distinct local/global RoPE bases and first-layer norm quirks are preserved, and unsupported encoders or RoPE scaling fail loudly. It carries upstream v0.3.5's calibration-temperature clamp to `[0.5, 5.0]`. The shipped `choice:11+` bucket was 0.1006, which would make a coin flip look near-certain. Raw values stay available, and a warning is emitted at load.
- **Research docs that say "no".** `ENGINEERING_10X_RESEARCH.md` tried compilation, quantization, head pruning and a hand-written Metal GELU kernel. It found 3–8% gains, and it found that 8/4-bit quantization saves storage but doesn't speed things up. The opt-in `compile`/`pad_to_multiple`/`cache_prompts` path is documented as ~6.5% faster on the Snake loop, no more.
- **Safe-by-default loading:** safetensors only (`mx.load`), `snapshot_download` with an `allow_patterns` allowlist, optional `revision=` pinning, and a subfolder path-traversal guard. There's no `trust_remote_code`, pickle or shell.

What gives pause:
- **Headline numbers don't match the committed raw results.** The README says 13.42 ms / 7.39 ms P50 for one short question. The raw `benchmarks/results/laya*-mlx-float16.json` files, regenerated 2026-09-22 after the upstream sync, show **17.75 ms** (laya) and **10.91 ms** (multilingual). `BENCHMARKS.md` matches the new files, and the README and launch copy still quote the earlier run.
- **The gain over upstream is incremental.** Same machine, same inputs: PyTorch-MPS FP32 is 22.70 ms and MLX FP16 is 17.75 ms for one short question (~1.3×, and part of that is the precision drop). At 50 questions it's 489.5 ms vs 347.2 ms (~1.4×). MLX FP32 is sometimes *slower* than MPS (5- and 10-question laya rows). The real wins are no PyTorch dependency and lower memory, not raw speed.
- **The Snake demo isn't model reasoning.** A Hamiltonian-cycle "safety shield" filters inadmissible moves, and the model gets planner features. The docs say so plainly, but the GIF is the headline.
- **Supply chain:** the convenient `aac6fef/*` FP16 checkpoints come from a pseudonymous account. The repo publishes pinned revisions and file checksums (`hub-publication.json`), so pin them or convert from the original `convaiinnovations/*` weights yourself with `laya-mlx convert`. CI uses tag-pinned actions (`@v4`/`@v5`), not SHAs.
- **Young and hyped:** created 2026-09-19, ~6.5k stars in under 10 days, and the last push was 2026-09-22 while upstream keeps shipping (0.3.21 on 2026-09-27, with abstention, ONNX parity and budget features this port lacks).

---

## What It Is

Laya is a "System 1" decision engine. It takes a state (text, a dict, or a chat transcript) plus typed questions, and runs a bidirectional encoder over each state+question row. Heads then emit:

- `choice`: a distribution over named options (list or `{label: description}` dict),
- `score`: a distribution over ordered rubric levels plus the expected level,
- `noul`: P(true) for a proposition,
- plus an `action.act_probability` from the action head.

This repo reimplements the encoder, decision Transformer, scoring head and action head in MLX. It keeps upstream's prompt formatting, calibration and output schema (four-decimal rounding, token-usage fields). It adds a CLI, a converter, a language `Router`, a shortlist helper for large choice sets and a terminal Snake demo. Training/RLCD stays upstream.

| Checkpoint | Encoder | Params | Context | Use |
|---|---|---:|---:|---|
| `convaiinnovations/laya` | ModernBERT-large | 421M | 512 | English |
| `convaiinnovations/laya-multilingual` | mmBERT-base | 322M | 1,024 | Multilingual |
| `convaiinnovations/laya-typed-decisions` | ModernBERT-large | 421M | 1,024 | Upstream typed-decision workflows |

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python ≥3.11, `mlx>=0.32.2,<0.33` (darwin/arm64 marker only) |
| Tokenization | Hugging Face `tokenizers` (Rust) |
| Weights | safetensors via `huggingface_hub.snapshot_download` (allowlisted files, optional revision) |
| Reference/tests | torch ≥2.14 + transformers ≥5.17 (extra), pinned upstream checkout in `.upstream` |
| Demo | `rich`, Pillow (`laya-snake`) |
| Packaging | hatchling, `uv.lock`, PyPI `laya-mlx` |
| CI | GitHub Actions `macos-26`: ruff lint/format, pytest on CPU (`LAYA_MLX_TEST_DEVICE=cpu`), `python -m build` |

## Key Features

### Typed decisions without decoding
There's no JSON generation and no output tokens. Each question is one row in a batched forward pass, and questions are independent (the port explicitly doesn't claim cross-question hidden-state reuse). `batch_size=16` by default, with larger requests chunked.

### Language router
`Router` picks English vs multilingual checkpoints from script and diacritic heuristics. Unidentified Latin-script languages (Romanian, Polish, Czech, Turkish…) now route to multilingual rather than silently defaulting to English, and `detect_language()` exposes `language_undecided` and `diacritic_rate`. Model lifecycle is guarded by a re-entrant lock, so concurrent threads share one loaded Agent. Inference itself isn't serialized. `max_loaded`, `preload`, `attach` and `unload` are available.

### Shortlisting
Choice labels share a fixed head token budget, so hundreds of labels starve each other. `predict_shortlist` embeds state and labels (by default, mean-pooled from the loaded encoder, with no extra weights), keeps the top-k by cosine similarity, then runs one `predict`. Probabilities are over the kept set only, and the docs say so.

### Converter
`laya-mlx convert` rewrites parameter names and dtype into an MLX checkpoint directory (`model.safetensors`, configs, tokenizer, `mlx_config.json`) and refuses to overwrite existing output. It doesn't quantize or retrain. It also notes that source weights are already FP16, so FP32 export improves arithmetic precision, not weight precision.

## Architecture

```
laya_mlx/
  model.py      ModernBERT encoder + DecisionModel heads in mlx.nn (~250 lines)
  agent.py      resolve_model (Hub/local), strict weight load, collate, predict, calibration
  common.py     question rendering, temperature buckets + clamp, state serialization
  prepared.py   opt-in prompt-prefix cache
  router.py     multi-checkpoint routing + lifecycle lock
  lang.py       script/language heuristics (from upstream)
  shortlist.py  cosine shortlist for large choice sets
  email.py      email cleaning/state helpers (from upstream)
  presets.py    triage question presets (from upstream)
  convert.py    MLX checkpoint export
  snake/        terminal demo, Hamiltonian-cycle shield, replay, benchmark
benchmarks/     fresh-process timing, validation, accuracy, report generator + raw JSON
experiments/    compilation / quantization / Metal kernel studies
```

It's about 3.75k lines of library code. It's small, readable, and the MLX model is compact enough to audit in one sitting.

## Security

- **Scan:** no hardcoded tokens (`sk-`, `hf_`, `ghp_`, `AKIA`). No `shell=True`, `os.system`, `eval`/`exec`, pickle, `torch.load` or `trust_remote_code`. `subprocess` appears only in the benchmark harness (`sysctl`, `git rev-parse` on the pinned upstream checkout), the Snake policy's hardware probe (`sysctl`), the Snake replay's ffmpeg MP4 export (argv lists), and a test.
- **Model loading:** safetensors-only, strict name and shape check, allowlisted download patterns, `revision=` supported, and subfolder `..`/absolute paths rejected.
- **Network:** a download on first load from the Hugging Face Hub, then fully local.
- **CI:** `permissions: contents: read`. Actions are tag-pinned, not SHA-pinned. It checks out the upstream repo at a fixed commit for reference tests.
- **Trust:** the decision is only as good as the checkpoint. Calibrated confidence isn't accuracy, and the README says so.

## Maturity

~6.5k stars and 512 forks; 20 open issues. Five commits over 2026-09-19 → 2026-09-22, then quiet. Beta classifier, v0.2.0 on PyPI. Tests: 67 test functions across 6 files (a tiny random ModernBERT for model and runtime tests, plus direct comparisons against Transformers and the pinned upstream head). Checkpoint GPU validation and benchmarks are local-only (M3 Max), not in CI.

### Validation on 2026-09-28

Host: Linux x86_64. MLX has no Metal backend here, and this environment's package-install gate blocked installing MLX's Linux CPU wheel, so **no model, runtime, shortlist or converter tests ran and no latency or parity claims were reproduced.**

- Pure-Python subset with an import-only `mlx` stub (numpy/tokenizers/pytest from an existing venv), `pytest --noconftest tests/test_email.py tests/test_router.py tests/test_snake.py`: **99 passed, 1 error**. The error is `test_agent_clamps_shipped_temperatures_and_keeps_raw`, which needs the MLX `tiny_checkpoint` fixture and was expected to fail under the stub. The passing tests cover email cleaning, language detection and routing, temperature clamping and bucket logic, and Snake game and Hamiltonian-cycle logic. They never execute tensor math.
- I read the committed raw benchmark JSON directly. `laya-mlx-float16.json` (created 2026-09-22) gives one short question end-to-end P50 **17.75 ms** (P95 21.45) and forward P50 15.82 ms. `laya-torch-mps-float32.json` gives 22.70 ms end-to-end. That matches `BENCHMARKS.md` and contradicts the README's 13.42 ms headline, which is from an earlier (2026-09-19) run cited in `PERFORMANCE_RESEARCH.md`.

## Comparison

| | Laya-MLX | Upstream Laya (PyTorch) | Hosted typed-decision APIs (e.g. TypeSafe Jev) | Small LLM + constrained JSON |
|---|---|---|---|---|
| Platform | Apple Silicon only | CPU/CUDA/MPS, ONNX | Any (HTTP) | Any |
| Output | Calibrated probabilities, no tokens | Same (+ abstention, budgets in 0.3.x) | Probabilities | Sampled tokens; probabilities need logprob tricks |
| Latency (1 short Q, M3 Max) | 17.75 ms FP16 (committed raw) | 22.70 ms MPS FP32 | Network-bound | Tens to hundreds of ms |
| Dependencies | mlx, tokenizers, hf-hub | torch, transformers | API key | Inference server |
| Features | Inference + convert + router + shortlist | Training/RLCD, more surfaces | Vendor-defined | General |

Related: the `keel` review covers a coding-agent workspace that uses Laya locally (via Core ML) as a route selector, and the Jev ecosystem roundup covers the hosted "System One" alternative.

## Self-Hosting Notes

- `pip install laya-mlx` on macOS 14+ / Apple Silicon / Python ≥3.11. First load downloads ~0.6–0.8 GB of FP16 weights. The peak MLX allocation is ~0.7–0.95 GiB for one short question and ~1.5–1.8 GiB for 10 full-context questions.
- For reproducibility and supply-chain hygiene, load with `revision=<sha>` or run `laya-mlx convert --model convaiinnovations/laya` from the original weights, not the third-party `aac6fef/*` mirror.
- `dtype="float32"` gives near-exact upstream agreement. FP16 is the default.
- Use `Router(max_loaded=2)` on memory-constrained Macs. Leave `compile`/`cache_prompts` off unless you've measured your own workload.
- On Linux or NVIDIA, use upstream Laya (PyTorch/ONNX). This port brings nothing there.

## Reusable Patterns

- **Parity-first port methodology:** pin the upstream commit, run every backend in a fresh process with identical input hashes, commit every timing sample and output hash, set tolerances *before* measuring, and separate fidelity ("matches upstream") from accuracy ("is right"). It's a clean recipe for any PyTorch→MLX/ONNX/Core ML port.
- **Calibration clamp with raw passthrough:** clamp learned temperature buckets to a sane range, keep the raw values accessible, and warn at load naming the clamped buckets.
- **Shortlist-then-decide:** a cosine prefilter to fit large label sets into a fixed head budget, reporting which labels survived.
- **Shielded demo labelling:** when a safety layer overrides model output, show the original distribution, mark the overridden action, and count interventions.

---

**Attribution:** mizorewww/laya-mlx, Apache-2.0 (derived from NandhaKishorM/laya, Apache-2.0)
