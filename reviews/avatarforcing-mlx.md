# AvatarForcing MLX (johnrobinsn/avatarforcing-mlx)

**Repo:** https://github.com/johnrobinsn/avatarforcing-mlx
**License:** CC BY-NC 4.0 code; model, derivative-weight and input-media rights require separate checks. Not a commercial-use clearance.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** d83df52b1d891cae7d12d68b247af7be6e6def07, main; root documentation, package/configuration, CLI, pipeline, MLX transformer/sampler, decoder rewrites, download/conversion, media handling, tests and comparison script.
**Verification:** Static review only. Anonymous GitHub/API/raw access verified; no installation, source execution, inference, model/media downloads or device access. Tests and performance claims were not reproduced.
**Stack:** Python 3.11–3.12, MLX, PyTorch MPS/Inductor, NumPy, Transformers 4.30.2, safetensors, PyAV, Pillow.
**What it is:** John Robinson's independent Apple Silicon adaptation of AvatarForcing: a portrait and speech become a 512×512 talking-head video, optionally conditioned on a conversation partner's audio and facial motion.

---

## Verdict

⚠️ **Interesting — a carefully explained research port, not yet a production avatar service.** Its strongest contribution is selective acceleration rather than an all-MLX rewrite, backed by unusually concrete numerical-equivalence tests. The reported faster-than-real-time block throughput is promising on one M5 configuration, but is not demonstrated live conversational latency; checkpoint integrity, interrupted-job recovery, licensing and consent remain deployment gates.

## What It Is

This is an inference library and local CLI, not a training stack, voice synthesizer, webcam app or hosted service. It ports the flow transformer and diffusion-forcing sampler while retaining the original motion/audio encoders and motion decoder in PyTorch. Partner conditioning is real code, not just a roadmap item: the sampler supports unconditional, avatar-audio and user-conditioning guidance branches. With no user input, the redundant third branch is removed. [1–4]

The port explicitly disclaims affiliation with the original authors. It targets AvatarForcing revision **507e3046ad539c938e0412ac7a74cf6e3ba2a61c**, names changed and vendored files in NOTICE, and includes tests for their correspondence. It is not a GitHub fork according to public metadata; that does not negate its declared derivative relationship. Upstream authors are Taekyung Ki, Sangwon Jang, Jaehyeong Jo, Jaehong Yoon and Sung Ju Hwang. [5,9]

## Stack

| Layer | Tech / boundary |
|-------|-----------------|
| Motion generation | MLX transformer, rolling attention caches, diffusion-forcing sampler |
| Image/audio encoding | Vendored PyTorch modules, MPS, wav2vec2 |
| Pixel decoding | PyTorch MPS, fp16 default, runtime kernel replacements and torch.compile |
| Media | Pillow and PyAV; mono 16 kHz audio, 25 fps video, 512×512 frames |
| Distribution | Python package 0.1.0, uv.lock; MLX 0.32.4 and torch 2.15.0 in lock |
| Models | Google Drive originals, Hugging Face wav2vec2, local safetensors conversion |
| Service/auth/database | None in this package; embedding applications supply these |

## Key Features

### Selective acceleration with explicit tradeoffs

The transformer uses MLX fast attention and offset-based RoPE; the decoder remains MPS because the author measured MLX high-resolution convolutions as slower. Decoder rewrites replace batch-grouped modulated convolution with shared-weight convolution and modulation, optimize up/downsampling, and cache sampling grids. Algebraic equivalence is not bitwise equality at reduced precision. The pipeline automatically applies the process-global decoder patch; it is not merely an optional fast path when using AvatarPipeline. Compilation can be disabled, but no automatic compile-failure fallback is implemented. [2–4]

### Interactive conditioning and bounded latent context

A 50-frame primer precedes 10-frame blocks with two overlap frames. The transformer has rolling 38-slot self-attention and two-slot cross-attention caches. Offset RoPE avoids the original fixed 1,024-position lookup limit; this is not evidence that unlimited sessions have been endurance-tested. Float64 schedule coefficients are precomputed in NumPy and applied in MLX; the final zero-to-zero no-op denoise step is skipped. [3,4]

### Precision is measured rather than hidden

The default is fp32 flow with fp16 decoding, not aggressive bf16 everywhere. PERF reports default frame SSIM means 0.9987 on the upstream sample and 0.9975 on a second six-second clip; bf16 flow falls to 0.976 on the latter. These are author-reported reference-fidelity measurements, not independently established realism, lip-sync, identity preservation or fairness results. [2,7]

## Architecture

Portrait → MPS motion encoder/reference features; speech → MPS wav2vec2/audio projection; optional partner audio/video → corresponding conditioning; MLX sampler → motion latents; MPS decoder → RGB; PyAV → MP4. Cross-framework bridges use CPU/NumPy conversions rather than demonstrating a zero-copy pipeline. Reference encoding warms and compiles the decoder before steady-state timing begins. [3,6]

The model tree mirrors upstream parameter names. Conversion extracts flow weights, splits packed attention projections and drops the checkpoint's mask buffers because upstream inference copies parameters only and reconstructs those masks. This is a substantive compatibility detail, not an interchangeable generic checkpoint converter. Missing parameters are checked and PyTorch loads use weights_only=True; the converted artifact is safetensors. Neither mechanism authenticates its publisher or bytes. [4,8]

### Throughput is not response latency

PERF's machine is a **base M5 MacBook Pro, 32 GB, macOS 26.6**, at 25 fps, 512×512, nfe=10. It reports approximately **210–235 ms per 400 ms video block** (1.7–1.9× real time), about 58–65 ms flow and 150–165 ms decoding. Reported allocator memory is about 0.8 GB MLX plus 4.7 GB MPS. These are source claims on one configuration, not a minimum system-RAM specification. No M1–M4, 8/16 GB or Intel-Mac benchmark matrix is supplied. Apple Silicon is the stated platform; the package's MLX dependency is Darwin/arm64-specific, and the pipeline defaults to MPS. [1–3,10]

The code synchronizes MLX evaluation and MPS before recording steady block timing, a good methodological detail. But those timings exclude model loading, reference setup/compilation, audio/user feature extraction, media encoding and display/network delay. Primer timing is not included in StreamStats; its yielded total_ms is zero. The CLI loads all speech and optional partner video first, collects all output frames in memory, then writes the MP4. Its printed generation wall time also excludes earlier feature work and final file encoding. Therefore “end to end” in PERF should be read as warm synthesis-block timing, not file-to-file or microphone-to-display latency. [2,3,6]

The primer consumes up to two seconds of conditioning (padding shorter inputs), then synthesis proceeds in 0.4-second blocks. A live integrator must handle capture/lookahead, startup, buffering, backpressure, presentation and synchronization. The bench command measures only flow on synthetic features, discards three warmup blocks and defaults to 20 measured iterations. The 15.8-second performance example and roughly 10% background-load variation are disclosed, but no repeated-run distribution, thermal endurance or cold-start latency is published. The comparison with two RTX Pro 6000 GPUs lacks enough matched pipeline details to establish a hardware ranking. [2,3,6]

### Numerical parity: valuable but narrowly scoped

Strict tests use MLX **CPU** fp32, not the deployment GPU, because the author reports larger M5 GPU fp32 matrix-multiply error. Module comparisons are around 1e-5; the sampling test accepts **1e-3 × max(1, reference maximum magnitude)** per block. Thus the README's blanket “full sampling loop ~1e-5” is stronger than the actual sampling-test acceptance criterion and PERF's description. Tests cover a primer plus four streaming blocks and both guidance modes; this is not long-session certification. [1,2,7]

The frame comparison script shares the computed audio features and identical noise between paths, uses an original CPU-fp32 sampler plus original MPS-fp32 decoder as reference, and calculates channel-averaged uint8 SSIM with an 11×11 Gaussian window. It tests talking-only frame parity: no user-conditioning inputs are exposed there, although latent tests do cover interactive mode. The second clip is not identified sufficiently for exact independent recreation. No perceptual user study, diverse-face corpus, synchronization metric or long-run quality analysis was found in this port. [7]

## Security, Privacy and Rights

### Local computation, external acquisition

The inspected CLI/pipeline has no hosted inference endpoint, upload client, telemetry or listener. Ordinary inference uses local weights and supplied media. Initial model acquisition contacts Google Drive and Hugging Face; optional face-cropping dependencies may acquire their own detector assets. This is a code-path assessment, not a network capture or guarantee about every dependency. AvatarVoice is linked as a separate full-chat application and is outside this review; its privacy posture cannot be inferred from this library. [1,3,6,8]

Inputs, generated faces, voice recordings and MP4s remain sensitive local artifacts. There is no consent ledger, retention policy, access control or watermark/provenance enforcement. Obtain explicit permission for portrait likeness, supplied voice/performance and partner audio/video; disclose synthetic output and avoid impersonation. Audio drives motion here—it does not synthesize or clone a voice—but an externally cloned recording still needs the relevant permissions. A hosted wrapper would need authenticated sessions, bounded uploads, protected storage, retention/deletion and egress rules; none is supplied. [3,6]

### Download integrity and recovery are weak

The downloader hardcodes Drive file IDs but supplies no expected cryptographic digests; Hugging Face snapshot_download has no pinned revision. Presence of config.json alone stands in for a complete wav2vec2 download. Existing checkpoint and converted files are trusted based on existence, with no manifest tying conversion to the source hash/version. Interrupted or replaced files can therefore be skipped on a retry; --force/manual replacement exists, but the wrapper does not implement atomic validation/promotion or a verified repair protocol. Library-level download behavior is not a substitute for a package-level integrity contract. [8]

Do not expose the media loader directly to untrusted requests: PyAV accepts media paths, inputs are decoded in full, and there are no explicit duration/size budgets in the loader. The CLI truncates partner frames only after loading them. Validate local-only paths, constrain parser resources and isolate workloads before turning this into a service. [6]

### Code, weights and data have different rights

The port LICENSE and pinned upstream LICENSE.md are CC BY-NC 4.0. Attribution, notices and change identification matter; this is not a permissive commercial software license. NOTICE credits FLOAT and LIA and identifies wav2vec2 as Apache-2.0. FLOAT's pinned README states CC BY-NC-ND 4.0 and research-only use; the motion-autoencoder lineage raises a real derivatives/redistribution question that the port's NC badge cannot resolve. Obtain rights-holder clarification before distributing converted/derived weights or deploying commercially. This review is not a legal determination. [5,9,11]

The repository distributes no model weights. That reduces redistribution exposure but does not establish downstream permission. Upstream says its sample image was generated with Gemini and the audio comes from RealTalk; this is provenance, not a documented consent or reuse grant for every sample, training subject or output. The reviewed material does not provide an auditable training-data/likeness-consent inventory. No sample media was acquired or reproduced for this review. [8,9]

## Persistence, Recovery and Maturity

Model files persist locally; sampler caches, reference embeddings and stream progress are in-memory. Each stream resets the sampler. No durable job checkpoint, resumable output, crash-recovery journal or transactional output promotion is implemented. The CLI's all-frames list costs roughly **1.1 GiB/minute** for RGB uint8 512×512 at 25 fps, before concatenation duplication, inputs and model memory. Bounded KV memory therefore does not mean bounded total CLI memory. A consumer can process yielded blocks incrementally, but must build its own writer/recovery path. [3,6,8]

Thread-local MLX streams require pipeline creation/use on the same thread. Global decoder monkey-patching and mutable reference/cache state deserve care in concurrent applications. No multi-tenant scheduler or concurrency safety contract is supplied. [1,3,4]

Anonymous metadata on the review date showed **9 stars, 2 forks, 0 open issues**, last push **2026-11-19T19:54:11Z**. The package says 0.1.0; GitHub returned no releases and the tag listing was empty. There is no .github workflow directory in the reviewed tree. Tests exist for masks/RoPE, attention/modules, cached forward passes, sampling, vendored provenance and decoder rewrites; fixtures skip reference/weight-dependent checks when prerequisites are absent. A green run without checking skips could overstate coverage. No inference tests were run here, and popularity is not a reliability signal. [7,10,12]

## Comparison

| Aspect | AvatarForcing MLX | Original AvatarForcing | FLOAT |
|--------|------------------|-----------------------|-------|
| Best fit | Apple Silicon research/prototyping | Canonical interactive-avatar research baseline | Audio-driven talking-portrait research baseline |
| Implementation | MLX flow + MPS encoding/decoding | Original PyTorch implementation | Upstream motion-autoencoder lineage; Linux A100/V100 tests documented |
| Interactive scope | Partner voice and facial-motion conditioning ported | Original interaction method | Not a drop-in guarantee of equivalent interaction behavior |
| Evidence | Author M5 timing and reference tests | Original paper/code; abstract claims ~500 ms latency | Separate project/evaluation, not a matched benchmark here |
| Rights | NC code plus separate model/derivative constraints | CC BY-NC 4.0 | README NC-ND/research restrictions |

Use the original implementation when validating algorithmic behavior; use this port when Apple Silicon is the actual deployment target. FLOAT is a useful lineage/comparison reference, not automatically a safer-license substitute. If conversational responsiveness matters more than photorealistic identity, a consented rigged 2D/3D avatar is another architectural option: less identity synthesis, but different asset and animation work. No alternatives were executed or benchmarked. [9,11]

## Self-Hosting Notes

- Start with a controlled, consented non-commercial experiment on the documented M5/32 GB class; measure lower-memory/older hardware rather than promising support.
- Pin source, dependency lock and independently verified checkpoint hashes/revisions. Audit all expected model files, not just directory/config existence.
- Keep fp32 flow until a representative lip-sync/identity/temporal-quality evaluation justifies lower precision. Measure startup and sustained interactive latency separately from warm block throughput.
- Use bounded input durations and incremental output, isolate the pipeline per execution context, and implement interruption cleanup/resumption before long sessions.
- Preserve attribution and clarify model/data rights before sharing weights or serving others. A commercial product needs separate permission, not just an MLX port.

## Evidence and Verification Limits

All numbered code citations below are pinned to the reviewed revision; upstream and FLOAT citations use their stated exact revisions. Public API metadata is a mutable observation dated above. Static inspection establishes implementation structure, not operational performance, checkpoint authenticity, copyright clearance or absence of vulnerabilities. No dependencies/source programs/tests were executed, and no model, audio, video or image assets were downloaded. Review artifacts were checked separately for template integrity, markup, links, provenance and public-only content.

1. [README](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/README.md).
2. [Performance and accuracy](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/docs/PERF.md).
3. [Pipeline](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/src/avatarforcing_mlx/pipeline.py).
4. [Flow transformer](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/src/avatarforcing_mlx/flow_transformer.py), [sampler](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/src/avatarforcing_mlx/sampler.py), [decoder rewrites](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/src/avatarforcing_mlx/decoder_fast.py).
5. [NOTICE](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/NOTICE), [LICENSE](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/LICENSE).
6. [CLI](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/src/avatarforcing_mlx/cli.py), [media](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/src/avatarforcing_mlx/media.py).
7. [Tests](https://github.com/johnrobinsn/avatarforcing-mlx/tree/d83df52b1d891cae7d12d68b247af7be6e6def07/tests), [frame comparison](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/scripts/compare_reference.py).
8. [Weights acquisition/conversion](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/src/avatarforcing_mlx/weights.py).
9. [Pinned original README](https://github.com/TaekyungKi/AvatarForcing/blob/507e3046ad539c938e0412ac7a74cf6e3ba2a61c/README.md), [original license](https://github.com/TaekyungKi/AvatarForcing/blob/507e3046ad539c938e0412ac7a74cf6e3ba2a61c/LICENSE.md), [port reference-fetch pin](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/scripts/fetch_upstream.sh).
10. [Package manifest](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/pyproject.toml), [dependency lock](https://github.com/johnrobinsn/avatarforcing-mlx/blob/d83df52b1d891cae7d12d68b247af7be6e6def07/uv.lock).
11. [FLOAT README and licensing](https://github.com/deepbrainai-research/float/blob/3b5b2dfc3e65df26e7fbba17d9adb3f43747851c/README.md).
12. [Public repository metadata](https://api.github.com/repos/johnrobinsn/avatarforcing-mlx), [releases](https://api.github.com/repos/johnrobinsn/avatarforcing-mlx/releases).

---

**Attribution:** John Robinson / johnrobinsn/avatarforcing-mlx, CC BY-NC 4.0; original AvatarForcing authors credited above. This review contains independent analysis, not redistributed code or model/media assets.
