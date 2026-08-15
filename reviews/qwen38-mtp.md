# Qwen3.8 MTP (sudoingX/qwen38-mtp)

**Repo:** https://github.com/sudoingX/qwen38-mtp  
**License:** Apache-2.0; permissive reuse with attribution and license preservation  
**Reviewed:** 2026-08-15  
**Stack:** llama.cpp, Qwen3.8-27B GGUF, Python stdlib benchmark client, Bash launch script  
**What it is:** A minimal benchmark-and-recipe repo showing that Qwen3.8-27B GGUF files already contain multi-token-prediction tensors and can use llama.cpp draft-MTP speculative decoding for materially faster decode on 24GB GPUs.

---

## Verdict

🔧 **Harvest the recipe and benchmark method, but verify locally before treating the numbers as portable.** The repo is tiny, but the core claim is practical: adding `--spec-type draft-mtp --spec-draft-n-max 2 --parallel 1` to a current llama.cpp server can improve Qwen3.8-27B decode throughput by roughly one third on the author's tested hardware. The evidence is better than a casual screenshot because it includes paired A/B commands, a streaming probe, prompt set, acceptance ranges, and community rows, but it is still a young day-one benchmark with narrow hardware coverage.

---

## What It Is

`qwen38-mtp` is not a model, serving engine, or application. It is a short public note plus two helper files: `serve_mtp.sh`, which launches `llama-server` with the MTP flags, and `probe.py`, which measures generated-token throughput against a live OpenAI-compatible llama.cpp endpoint.

The central observation is that Qwen3.8-27B GGUF files from Unsloth include `blk.*.nextn.*` tensors for Qwen's multi-token-prediction head. llama.cpp's draft-MTP support can use that built-in head for speculative decoding: draft a small number of tokens, verify them with the main model, and keep the accepted drafts at lower cost than full forward passes.

The README reports paired live-server measurements, not `llama-bench` microbenchmarks. The initial rows claim RTX 3090 24GB improving from 31.0 to 41.3 tok/s and RTX 5090 mobile 24GB improving from 36.7 to 50.9 tok/s with `n-max=2`. Community rows add RTX A6000 Ada and RX 7900 XTX measurements, including a deeper `n-max` sweep for the A6000.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | llama.cpp `llama-server` |
| Model target | Unsloth Qwen3.8-27B GGUF, especially `Q4_K_M` for 24GB cards |
| Acceleration | llama.cpp draft-MTP speculative decoding |
| Benchmark client | Python stdlib `urllib.request`, streaming `/v1/chat/completions` |
| Launch helper | Bash wrapper around `llama-server` |
| Hardware evidence | RTX 3090 24GB, RTX 5090 mobile 24GB, RTX A6000 Ada 48GB, RX 7900 XTX 24GB |

## Key Features

### One-Flag Decode Speedup

The useful payload is the exact llama.cpp flag set:

```bash
--spec-type draft-mtp --spec-draft-n-max 2 --parallel 1
```

That is unusually low-friction for a serving-speed improvement. No separate draft model, conversion step, model patch, or custom build is required if the installed llama.cpp build already supports draft-MTP and the GGUF contains the MTP tensors.

### Practical VRAM Recipe

The launch command pairs MTP with quantized KV cache flags:

```bash
llama-server -m Qwen3.8-27B-Q4_K_M.gguf \
  -c 131072 -ngl 999 -fa 1 \
  --cache-type-k q4_0 --cache-type-v q4_0 \
  --spec-type draft-mtp --spec-draft-n-max 2 --parallel 1
```

The README notes that q4 KV cache is what keeps large context practical beside roughly 17GB of weights on 24GB GPUs. That operational detail matters as much as the speculative decoding flag: a fast recipe that does not fit memory is not useful.

### Paired Streaming Probe

`probe.py` sends three fixed prompts through `/v1/chat/completions`, discards a warmup, counts streamed `content` and `reasoning_content` deltas, and reports median tokens per second across three runs per prompt. It is intentionally small enough to inspect in one sitting.

The method is not a full benchmark suite, but it avoids one common mistake: comparing unrelated server configurations. The repo's instruction is to run the same live server setup twice, once baseline and once with the MTP flags.

### `n-max` Tuning Notes

The README's `n-max` sweep is useful because it does not pretend deeper drafting is always better. On the 5090 mobile, `n-max=2` wins for mixed workloads; code prompts can keep improving at 3 or 4, while prose falls as acceptance decays. On the A6000, more headroom shifts the mixed peak to `n-max=4`.

That is the right conclusion shape: speculative decoding is workload- and hardware-sensitive, so acceptance rate and prompt mix need to be measured together.

## Architecture

There is almost no architecture in the repo by design:

- README contains the method, numbers, caveats, and community table.
- `serve_mtp.sh` launches localhost `llama-server` with the measured 24GB-card config.
- `probe.py` is a dependency-free streaming client for the OpenAI-compatible endpoint.

The interesting architecture is upstream: Qwen stores next-token-plus-future-token prediction heads in model weights, GGUF quantization preserves those tensors, and llama.cpp's draft-MTP path can use the embedded head as the draft model. This is cleaner than the common speculative-decoding setup that requires a separate small model.

## Comparison

| Aspect | qwen38-mtp | time-to-first-token | Tool Eval Bench |
|--------|------------|---------------------|-----------------|
| Primary value | Specific llama.cpp/Qwen3.8 speed recipe | Broad inference-serving curriculum and benchmark hygiene | Behavioral benchmark for tool-calling endpoints |
| Output | Flags, probe, reported numbers | Roadmap/checklists | Test harness and reports |
| Best use | Try a low-effort local decode-speed win | Learn and structure serving work | Gate models before agent use |
| Main caveat | Narrow, self-reported early measurements | No runnable service code | Does not measure raw decode speed by default |

This belongs next to inference-serving benchmark notes rather than application repos. It is a sharp operational recipe, not a platform.

## Self-Hosting Notes

Use a fresh llama.cpp build that includes draft-MTP support. Launch baseline and MTP variants with the same model file, context length, KV cache type, GPU offload, sampler settings, driver state, and thermal conditions. Keep `--parallel 1`; the README says draft-MTP currently requires single-slot serving.

For 24GB GPUs, start with `Q4_K_M`, `-c 131072`, `--cache-type-k q4_0`, `--cache-type-v q4_0`, and `--spec-draft-n-max 2`. For larger GPUs or code-heavy sessions, sweep `n-max` instead of assuming 2 remains optimal.

Do not compare one-off runs. Run paired A/B measurements, report token lengths, prompt mix, exact llama.cpp version, GPU/driver details, acceptance rate, and medians across repeated prompts.

---

**Attribution:** sudoingX/qwen38-mtp, Apache-2.0, https://github.com/sudoingX/qwen38-mtp
