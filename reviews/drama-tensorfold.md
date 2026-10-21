# drama-tensorfold (plotarmordev/drama-tensorfold)

**Repo:** https://github.com/plotarmordev/drama-tensorfold
**License:** Apache-2.0 code; separately downloaded weights and codec use Fish Audio Community License v1.0 (FACL), not Apache-2.0.
**Reviewed:** 2026-10-21 (UTC)
**Revision:** 44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a; whole recipe repository, selected core engine patches, benchmark and qualification code and published results. Underlying TensorFold was not built or exhaustively audited.
**Verification:** Static source review and patch-checksum verification only. No source programs, model inference, GPU tests, deployments or downloads of weights were run.
**Stack:** Zig 0.17.0, CUDA 13/cuBLASLt, Python 3.12 tooling, Bash, Linux user systemd; NVIDIA GB10 target.
**What it is:** A pinned patch series and evaluation recipe for running Fish Audio Drama 3 text-to-speech on TensorFold's native CUDA engine, with local WAV/PCM serving and voice cloning. It is not a tensor-compression library or a new trained speech model.

## Verdict

⚠️ **Interesting — a technically serious GB10 experiment, not a qualified production replacement.** The strongest material is the explicit numerical failure ledger, streaming implementation and carefully scoped native-kernel optimization. Reported speed gains are useful leads, but current accuracy still misses gates, original benchmark captures are absent, and model licensing materially restricts commercialization and hosted speech generation.

## What It Is

The repository distributes 59 patches rather than a standalone engine checkout. Its build script clones TensorFold at a fixed revision, applies the series and builds native serving plus selected oracle binaries. The pinned reference is SGLang-Omni, not another model: this is an implementation comparison of Drama 3 with the same checkpoint. Intended users are GB10/DGX Spark owners and inference engineers willing to evaluate a rapidly evolving port. [Build and identities](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/scripts/build-engine.sh), [source pins](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/recipe/sources.json), [patch map](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/engine/patches/README.md).

Public GitHub metadata checked on the review date: created October 16, 2026; last push October 21, 2026 at 06:19:36 UTC; 82 stars, 4 forks, no open issues and no published releases. These are a young project's activity indicators, not evidence of quality.

## Stack

| Layer | Technology and boundary |
|---|---|
| Native engine | TensorFold at c7137bb31a7dad924fb541a7068422127b9a94b2 plus 59 patches |
| Reference runtime | SGLang-Omni ab095ef9e779e56af33b6ed2c863645c9903372d |
| Checkpoint | fishaudio/drama-3 e0a9218aa48888270f06ef1ed9ea67622c0e17d2; 41,474,674,072 weight/codec bytes |
| Kernels | Zig host orchestration, CUDA, BF16/FP8 operations, cuBLASLt; GB10 sm_121 optimization |
| Serving | OpenAI-style audio route, mono PCM16 at 44.1 kHz, WAV or chunked raw PCM |
| Evaluation | Python standard-library benchmark tools; NumPy/Torch/reference environment for numerical qualification |
| Optional voice preparation | NumPy, soundfile; optional locally supplied Whisper model for transcription |

The source commits and model hashes are pinned, but this is not a complete locked, portable environment. Toolchain, CUDA/library versions, GPU shape and the reference runtime's dependencies remain operational dependencies.

## Key Features

### Native speech pipeline, not an API wrapper

Patch 0002 implements a 40-layer hybrid backbone: 30 Gated DeltaNet layers and 10 gated full-attention layers, with 256-expert top-8 block-FP8 MoE and a shared expert. It uses chunked GDN prefill, recurrent decode, Q/K normalization, partial NeoX RoPE and dynamic 1×128 FP8 activation quantization. Stored weights are not requantized. Patch 0003 adds a 13-layer temporal tower producing ten codebook values per frame; its sampler applies temperature, nucleus selection over the vocabulary, then top-k. Patch 0004 decodes codes through a native codec. [Backbone](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/engine/patches/0002-drama-the-Drama-3-text-backbone-on-CUDA.patch), [tower](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/engine/patches/0003-drama-the-temporal-codebook-tower.patch), [codec](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/engine/patches/0004-drama-the-speech-codec-with-codec.pth-read-without-P.patch).

### Streaming with explicit failure semantics

Incremental codec decoding retains causal context and writes only newly available output rows. This aims at chunk/whole byte identity, not merely perceptual similarity. Speech replies report stop, length or silence; non-stop streamed finishes use trailers. The single engine slot returns 503 when busy, so this is not evidence of multi-user throughput. A 10-second -40 dBFS guard cuts stalled/sustained low-level output; it does not make the model finish missing speech. Consumers must inspect finish metadata, including trailers, rather than treating HTTP 200 as successful narration. [Incremental codec](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/engine/patches/0013-drama-incremental-codec-decode-bit-identical-to-the-.patch), [current contract](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/README.md).

### Optimizations with limited, explicit invariants

The series stages weights, fuses glue operations, specializes one-row GEMV, uses a stable radix sampler and programmatic dependent launch. Patch 0029 gates its custom tower GEMV on GB10/cuBLASLt version and per-projection initialization probes, falling back to cuBLASLt if qualification does not succeed. This is a good compatibility pattern; finite probes are not proof for every future input. Maintainer-reported byte identity covers 46 normal replies across the speed patches, not equivalence to SGLang-Omni and not every later change. [GEMV qualification](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/engine/patches/0029-drama-the-tower-s-one-row-projections-on-drama_tower.patch), [speed ledger](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/results/speed-stages.json).

## Architecture and Correctness

The numerical issue is substantive. Patch 0040 changes attention from per-key/warp accumulation to the reference's absolute 64-key tiles, approximate exponentiation, division and fused multiply-add schedule. This improves the 182-token text fixture, while a voice-reference prompt does not similarly improve. Decode deliberately shares the native arithmetic rather than reproducing the reference's split-KV decode kernel. Bitwise identity across native chunk sizes is a different property from reference fidelity. [Attention implementation](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/engine/patches/0040-drama-backbone-attention-runs-the-reference-s-64-key.patch).

Latest reported backbone values are relative L2 **0.0528** against a ≤0.05 gate, all-row cosine **0.99860** against ≥0.999 and last-row cosine **0.99809** against ≥0.999. Semantic KL improves to 0.0062 and top-30 overlap to 0.933, both passing. One-frame codec SNR remains **33.086 dB** versus 40 dB; a tower top-1 differs at tied logits; long-05 fails to reach natural end of speech. The latest backbone measurements must not be confused with older failures retained in qualification.json. [Current ledger](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/results/README.md), [post-0040 results](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/results/backbone-attention-tiles.json).

The revised worst-row cosine threshold (0.995 → 0.8712518909203973) is explicitly derived from the reference's own co-batching variance before native re-scoring. That is preferable to silently tuning a gate to native, but it rests on one 182-token fixture, eight two-request views, eager execution and one run. It permits appreciable isolated-row error; it is not a universal fidelity guarantee. The reference's row-shape-dependent arithmetic explains why exact parity under a row-invariance requirement can fail, not why every native discrepancy is harmless. [Method and limitations](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/qualification/README.md).

Voice preparation uses empirical timbre clustering, not a robust speaker-identification system. The project documents missed close-timbre/band-limited mixtures and false rejections when one speaker changes timbre. Multi-reference voices and long-form history improve conditioning, but segment joins can reset prosody by a reported 2–5 semitones. Native voice-encoder semantic codes differ from the reference on 2.46–2.95% of three tested clips. These small studies do not establish arbitrary-speaker or multilingual equivalence. [Voice and long-form documentation](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/README.md).

## Benchmark Claims and Evidence

| Claim | Published measurement | Interpretation |
|---|---|---|
| Faster generation | Warm RTF 0.939 reference vs 0.634 native, approximately 1.48× | One GB10, 24 English texts, concurrency 1, 3 warm passes; outputs have different lengths |
| Lower whole latency | 7.93 s vs 4.89 s p50, approximately 1.62× | Not the same generated audio; RTF is the better duration-normalized comparison |
| Faster first audio | 0.521 s vs 0.141 s p50, approximately 3.7× | Stream latency, not total completion or perceived quality |
| Faster startup | 254.1 s vs 6.4 s | One start each, reused caches and different admission/page-cache conditions; not disk-cold benchmark evidence |
| Current attention change | RTF 0.642–0.650 → 0.682 in a same-session capture | About 5% cost; headline speed table predates this accuracy change |

The benchmark includes failures in denominators and discloses clipped replies (six reference, three native). The reference continued despite a supplementary admission refusal; the current runner now stops on that condition. The reported startup ratio is therefore particularly confounded. A cutoff-free cohort of 19 items is useful supplementary analysis, not a replacement for the full workload. [Protocol/results](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/results/before-after-02/README.md), [benchmark tools](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/bench/README.md).

The public evidence consists of curated JSON summaries, not raw audio, per-request original samples or server logs. This review checked the implementation and published numbers, not the claimed independent review or the experiments themselves. Re-running provided tools could produce new evidence, but the curated repository omits the codec gate, its streaming verifier, tower full-context and real-input replay tools/fixtures. A one-rater, five-pair listening preference (one unblinded pair) is not a credible quality superiority result. [Evidence availability](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/results/README.md), [omitted qualification tools](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/qualification/README.md).

Two static tooling weaknesses deserve repair before treating green output as a gate:
- **compare_gate.py derives the expected passes/items from NEW**, rather than requiring the complete baseline/corpus set. An entire omitted normal item or pass can escape coverage checks; hash/status equality also does not independently require successful normal replies. It compares recorded hashes, not rehashed audio files. This does not prove the published captures were incomplete, but makes the generic identity gate weaker than its name suggests. [Code](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/bench/compare_gate.py).
- **rescore-native.py returns 0 even when its report says passed=false.** A shell pipeline relying only on exit status could wrongly treat numerical failure as successful qualification; consumers must parse the report. [Code](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/qualification/rescore-native.py).

## Security, Privacy and Licensing

The launcher defaults to loopback, clears inherited environment variables, uses HF offline mode, a shared GPU lock, memory admission, allocator limits, cgroup MemoryMax and a low-memory abort monitor. These are useful resource controls, **not a secret-free security sandbox**: HOME remains available and there is no filesystem/network isolation in the shown systemd command. Extra server flags and direct engine launches still require operator review. Do not expose the example unchanged as a public service; this review did not audit all upstream authentication, CORS or HTTP parser behavior. [Launcher](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/recipe/pilot.py).

Speech input is validated for JSON shape, fields, UTF-8, length (4096 codepoints) and prompt limits. The codec loader implements a restricted tensor-state pickle VM that rejects unknown globals/opcodes rather than executing arbitrary Python, including an explicit test rejecting os.system. This reduces an important deserialization hazard, but is not an exhaustive archive-parser security audit. Use only pinned, checksum-verified checkpoints and a dedicated build directory. The build script sources its upstream settings and invokes downloaded build code; a clean environment alone does not make arbitrary sources safe. [Route validation](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/engine/patches/0007-server-POST-v1-audio-speech.patch), [codec loader](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/engine/patches/0004-drama-the-speech-codec-with-codec.pth-read-without-P.patch).

Text, generated audio, voice references and benchmark capture bodies are sensitive local data. Voice files require an ownership/consent source annotation, but it is self-attestation, not consent verification. Git-ignoring clips and voices does not encrypt or delete them. Establish access controls, retention and consent handling separately; do not upload private captures as benchmark evidence.

The actual Apache-2.0 LICENSE and NOTICE separate repository code from model rights, and retain MIT attribution for flash-linear-attention-derived kernels. Reusing code still requires applicable notices. The pinned [FACL v1.0 text](https://huggingface.co/fishaudio/drama-3/blob/e0a9218aa48888270f06ef1ed9ea67622c0e17d2/LICENSE) grants research/noncommercial use and limited commercial use below USD 500,000 aggregate annual revenue, with additional client conditions. Hosted Services require a separate license regardless of revenue, subject to defined exceptions (including qualifying noncommercial demos, operator-directed finished-output production, and controlled/product-generated content). Attribution, voice rights/consent and model-training restrictions also apply. **Apache-licensed inference code does not make these weights unrestricted open-source assets.** Read the actual terms for a concrete deployment; this is not legal advice. [Notices](https://github.com/plotarmordev/drama-tensorfold/blob/44e7eb9d4cb09c04cf0a4241c5da8e75673e3a5a/NOTICE).

## Tests and Maturity

There are numerous Zig unit/oracle tests embedded in patches, including request validation, nonfinite audio rejection, WAV layout, convolution and weight rounding, pickle-global refusal, streaming and GEMV qualification. There is no checked-in GitHub Actions workflow in this repository; .github contains only a pull-request template. The public repository is five days old at review, with no releases. The 59-patch dependency chain and fast-moving toolchain increase maintenance and upstream-integration cost.

Independent checks performed: public unauthenticated acquisition; exact SHA and dependency pins; local and fresh-remote deduplication; all 59 patch checksums against SHA256SUMS; static inspection of core implementation and gate scripts. **Tests were not run, patches were not built, and reported speed, audio identity, SNR, listening quality and hardware portability were not independently reproduced.** No safe secret-free GPU sandbox was established, so source execution was intentionally avoided.

## Comparison

| Option | Best fit | Tradeoff |
|---|---|---|
| This port | GB10 kernel/streaming investigation; local controlled experiments | Lower reported latency, but unqualified numerics, narrow hardware evidence and patch maintenance |
| [SGLang-Omni](https://github.com/sgl-project/sglang-omni) pinned Drama 3 reference | Behavioral baseline and reference integration | Same model-license restrictions; slower in this workload and itself subject to schedule variance/stalls |
| [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) | Evaluate a much smaller TTS model when memory matters more than Drama 3 compatibility | Different model and voice capabilities; not an equivalence or speed baseline here |
| [Piper](https://github.com/OHF-Voice/piper1-gpl) | Evaluate CPU-oriented local speech with simpler hardware needs | Different voice/expression capabilities; engine and voice-model licenses must be checked separately |

No alternative was installed or benchmarked in this review. Choose based on required voices, rights, latency, hardware and quality rather than assuming the largest model or native implementation wins.

## Self-Hosting Notes

The documented recipe requires Linux user systemd, CUDA 13, Zig 0.17.0, approximately 88 GiB free/available memory at admission and about 39 GiB checkpoint storage alone; the server cgroup cap is 54 GiB. A larger frame cap increases codec buffers (documented roughly 4.75 GiB at 4096 frames). This is not a lightweight desktop dependency. Keep loopback binding, coordinate the lock with every GPU job, verify all hashes and inspect stop/length/silence outcomes. Do not run benchmark scripts on arbitrary endpoints: they send corpus text and save bodies.

For a serious adoption decision, first rerun the complete current-revision benchmark and qualification suite on the intended GPU/library versions, publish sufficient replay artifacts, tighten gate completeness/exit status, and test consented voices, long text, multilingual input and failure behavior. Production approval should require an explicit error/quality budget and license review, not merely beating the reference p50.

---

**Attribution:** plotarmordev/drama-tensorfold, Apache-2.0; TensorFold and SGLang-Omni upstreams; Fish Audio Drama 3 model under FACL v1.0. No weights or source-code extractions are redistributed by this review.
