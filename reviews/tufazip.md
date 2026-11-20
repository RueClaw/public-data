# tufazip v2 (Tufalabs/tufazip)

**Repo:** https://github.com/Tufalabs/tufazip
**Author:** Tommy He; Tufa Labs
**License:** MIT; retain copyright and permission notices, including Bellard and Nayuki component notices. Dataset rights are separate.
**Reviewed:** 2026-11-20 (UTC)
**Revision:** b9d678db3a0f726e117c8cab51927975830395ac (master, commit dated 2026-09-30); repository-wide static review, focused on the v2 launcher, Transformer/codec, checkpoint helpers, arithmetic coder, C preprocessor and dependency metadata.
**Verification:** Static inspection only. No source execution, installation, GPU access, external model/dataset acquisition, compression/decompression run, or benchmark reproduction.
**Stack:** Python, NumPy, PyTorch/CUDA/NCCL, TensorBoard; GCC-built C detokenizer; uv lockfile.
**What it is:** A tightly specified neural text-compression benchmark decoder for one enwik9 artifact, with an underlying experimental online encoder/decoder—not a ZIP replacement or general-purpose archival product.

## Verdict

📚 **Study: compelling adaptive-compression engineering, not practical general-purpose storage.** The interesting part is replaying learning during decoding from a small transmitted quantized prior, with unusually explicit runtime and end-to-end hash gates. The documented job takes roughly a week on two B200s, and the public tree does not establish reproducible offline training, portable decoding, arbitrary-file round trips, or safe handling of hostile checkpoints.

## What It Is

The README identifies v2 as the deterministic decoder for the 100,958,324-byte enwik9-v2.bin stream. It reports an original decoder ZIP of 4,430,029 bytes and a ranked total of 105,388,353 bytes. These are author-reported results, not measurements made for this review. The archive size includes the vocabulary and weights; do not add the vocabulary again to that README total.

The launcher intentionally accepts only the expected payload, vocabulary and weights hashes. The lower-level nn.py retains encoding, experiment controls and alternative-backend options, but some referenced backend/tokenizer modules are absent from this release. The supported surface is much narrower than that experimental CLI suggests. There is no archive-member directory, filename metadata, permissions preservation, encryption, random-access extraction, or ZIP/gzip/zstd interoperability in the inspected format.

## Stack and Architecture

| Layer | Implementation |
|---|---|
| Supported entry point | tufazip validates inputs/runtime, launches two local distributed ranks, verifies tokens, compiles and invokes detokenization, verifies final bytes |
| Probability model | 12-layer Transformer, width 1024, 8 heads, SwiGLU, RoPE, RMS/QK normalization; 4,097-symbol vocabulary, 192-token context |
| Initialization | QPI1 packed quantized prior; metadata, tensor geometry, vocabulary digest, seed and block mapping checks |
| Entropy coding | Rounded/clamped integer frequencies from softmax; 32-bit arithmetic coder with a four-byte big-endian token-count prefix |
| Online adaptation | Batch streams, per-symbol updates and replay over already-coded prefixes, matching encoder/decoder ordering |
| Recovery | Model, optimizers, RNG, coder/bitstream and output positions; fsync plus atomic replacement for latest checkpoint |
| Output | Big-endian 16-bit token stream, then Bellard-derived C vocabulary detokenizer |

Evidence: [fixed configuration/model](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/nn.py#L38-L69), [prior reader and validation](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/nn.py#L339-L640), [input/output format](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/nn.py#L1135-L1216), [online loop](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/nn.py#L1430-L1515), [launcher](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/tufazip#L103-L136).

### Learning is part of decoding

At each position the model supplies probabilities before the new target is learned. Decoding recovers that target, broadcasts it to ranks, and makes the same optimizer updates. Periodic retraining uses the previously coded prefix, not an unavailable future suffix ([retrain](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/nn.py#L1254-L1335)). This is a valid conceptual route to adaptive lossless coding. It also makes numerical behavior, optimizer state, RNG and collective ordering part of the file-format contract, not merely performance details.

### Explicit checks are a strength, not a portability proof

The launcher pins Python 3.12.3, NumPy 2.4.6, PyTorch 2.12.0+cu130, TensorBoard 2.20.0, CUDA 13.0 and cuDNN 9.20, exactly two visible NVIDIA B200s and x86-64. It sets deterministic environment variables; nn.py enables deterministic algorithms. Input hashes, the 570,405,660-byte intermediate-token hash, and the final 1,000,000,000-byte raw-output hash are checked. A successful supported invocation therefore checks byte identity against a fixed expected digest; this review did not observe such an invocation. These safeguards do not prove cross-driver/kernel/hardware reproducibility or arbitrary-file round trips. Evidence: [runtime/hash gates](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/tufazip#L15-L66), [verification sequence](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/tufazip#L111-L136).

## Correctness and Security Boundaries

- **Corrupt supported payloads fail early.** Size and SHA-256 are checked before expensive decoding. Intermediate verification protects the C detokenizer from a divergent decoded stream; final verification catches raw-output errors. Hashes are integrity identifiers, not an independent signature or protection against a modified checkout.
- **The raw codec is not a hostile-file parser.** Direct nn.py decoding reads a four-byte length without an exact-header-length check, allocates an int64 array from it, and lacks a general decompression budget. A maximum 32-bit count implies roughly 34.4 GB for that array alone per rank. Arithmetic EOF is intentionally treated as zero padding, not automatically rejected as truncation. This is normal arithmetic-coder termination behavior but requires an outer length/integrity contract. The supported launcher supplies one; direct use bypasses it. See [allocation](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/nn.py#L1157-L1199) and [EOF handling](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/arithmetic_coder.py#L253-L261).
- **Weights have structural checks but no general resource policy.** The reader validates magic/version, names, shapes, bit widths, byte counts, truncation and trailing bytes. Metadata length, tensor element totals and aggregate allocations are not subject to explicit application caps before parsing/unpacking. Trusted hash-pinned bundled weights are a different threat model from arbitrary QPI1 input ([reader](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/nn.py#L359-L440)).
- **Checkpoints are executable trust.** load_checkpoint uses torch.load(..., weights_only=False). A supplied or attacker-writable state directory can execute pickle payloads before configuration/prior checks run. This is not an attack through the hash-validated compressed payload itself. Never resume third-party state; isolate state from other users. See [loader](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/checkpoint_utils.py#L131-L135) and [resume validation order](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/nn.py#L1099-L1134).
- **Destination paths can destroy existing files.** Paths are resolved and subprocess arguments use lists rather than a shell, but there is no no-clobber flag, output/input alias rejection, exclusive creation, or atomic final-output promotion. The detokenizer opens the chosen output with wb. A caller can overwrite an existing destination—or even choose the payload path as output—and failures can leave partial output. State paths and symlinks must be trusted; there are no archive-entry paths to sanitize. See [launcher paths](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/tufazip#L111-L134) and [C output open](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/preprocess.c#L1028-L1037).
- **Recovery is thoughtful but not a transactional filesystem.** Atomic checkpoint replacement and fsync reduce torn-checkpoint risk; resume checks configuration, input size, world size and prior/vocabulary identity and truncates output to the saved position. DONE skips decoding but the launcher still hashes the intermediate. No state-directory lock prevents concurrent jobs sharing the same paths. Final output is not atomically replaced, and graceful stopping waits for a block boundary rather than providing an immediate budget cutoff.

These are static observations, not exploit demonstrations or an exhaustive audit. Use a dedicated unprivileged workspace with trusted immutable inputs, private state and disposable output paths if independently reproducing the benchmark.

## Performance, Fairness and Reproducibility

| Item | Evidence and interpretation |
|---|---|
| Dataset | Single fixed 1 GB enwik9 corpus; no multi-corpus generalization evidence in this tree |
| Compressed stream | Author reports 100,958,324 bytes: 10.0958% of input, about 0.807667 bits per original byte |
| Ranked total | Author reports 105,388,353 bytes including original decoder ZIP: 10.5388%, about 0.843107 bits per byte |
| Compression | Approximately 631,548 seconds excluding offline training: 7.31 days |
| Decompression | Approximately 645,748 seconds: 7.47 days; roughly 1,549 original bytes/second averaged over the reported time |
| Hardware | Two NVIDIA B200 GPUs, Linux x86-64 and pinned runtime; no independently measured energy, peak RAM/VRAM or full dollar cost |
| Baselines | No same-machine baseline suite, repeated-run variance or speed/ratio frontier in the repository |

Derived percentages/times above are arithmetic on README claims, not new benchmarks. The [Large Text Compression Benchmark](https://www.mattmahoney.net/dc/text.html) history independently lists tufazip 0.1.0 on September 8 and v2 on September 30, 2026. That corroborates its benchmark context, not an independent reproduction of these timings, current rank or hardware fairness.

Charging transmitted weights and vocabulary is important: a strong prior is not free decoder knowledge. Conversely, a ranked decoder ZIP is not the full deployed footprint of CUDA, PyTorch, drivers, optimizer state and checkpoints. The README explicitly describes the original verified archive; do not assume re-zipping this later public tree yields identical bytes. nn.py distinguishes modeled cross-entropy estimates from actual compressed-file sizes, a useful methodological detail ([final accounting](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/nn.py#L1610-L1720)).

Offline Cycle2 training data/procedure and complete training-to-packed-prior production are not furnished as a reproducible pipeline in this release. Consequently, prior training cost, tuning expenditure and training/evaluation overlap cannot be independently assessed from the tree. That is not proof of an invalid compression result: decoding a fully transmitted prior is different from claiming held-out model generalization. It does limit scientific and economic comparisons. The payload itself is not tracked and the README provides an expected hash rather than a direct artifact-download recipe; no release assets were available in the public releases API at review time.

## Installation, Network and Privacy

The README prescribes frozen uv resolution and an exact interpreter; the manifest alone permits Python >=3.10 and broad minimum dependency versions, so following only pyproject.toml is insufficient for deterministic decoding. The lockfile includes artifact hashes and a large native CUDA/PyTorch dependency chain. GCC compiles preprocess.c during the supported invocation; the compiler/system stack is not fully pinned by uv. No dependency installation, vulnerability audit or runtime compatibility test was performed.

There is no model-provider API, cloud account, telemetry uploader or paid endpoint in the inspected decoding path. TensorBoard writes local run logs; torchrun/NCCL use process coordination/network facilities for the local two-GPU job. Package installation needs registries unless pre-provisioned, so “local decoding” does not imply a network-free setup process. Costs are hardware time, power, disk and potentially GPU rental, not per-token provider charges. Treat decoded text, local logs and checkpoint state as retained data. There is no updater here; pin source and lockfile together and revalidate hashes/runtime after changes.

## License, Tests and Maturity

The root [MIT license](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/LICENSE) credits Tommy He. [NOTICE](https://github.com/Tufalabs/tufazip/blob/b9d678db3a0f726e117c8cab51927975830395ac/NOTICE) attributes Fabrice Bellard's NNCP preprocessor and Project Nayuki's arithmetic coder; their notices remain relevant when reusing those components. No separate weights license was found in this small root-licensed tree; this is not a clearance opinion on training data or enwik9/Wikipedia content.

At retrieval, public GitHub metadata reported 123 stars, 5 forks, zero open issues, creation on 2026-09-03 and last push on 2026-09-30. Tags and releases were empty. These are a time-stamped popularity/activity snapshot, not evidence of correctness. The tracked tree has no dedicated test suite or CI workflows. Runtime hashes and stop-after-blocks instrumentation are valuable acceptance hooks, not a substitute for automated round-trip, malformed-input, restart and portability tests. No tests were run for this review.

## Comparison and Practical Fit

| Need | Better starting point | Tradeoff |
|---|---|---|
| Everyday fast storage/transfer | [Zstandard](https://github.com/facebook/zstd) | Portable established codec and speed/ratio controls; not competing here for the smallest specialized enwik9 total |
| Widely supported file archives | [7-Zip](https://www.7-zip.org/) / xz plus tar | Ordinary CPU workflows and archive conventions; different ratio/compute objective |
| Study neural adaptive compression | [NNCP](https://bellard.org/nncp/) | Direct conceptual/preprocessing lineage; still evaluate runtime and benchmark conditions |
| Study high-ratio text context mixing | [cmix](https://github.com/byronknoll/cmix) | Relevant research comparison, not a claim of equal hardware, speed or ranking |

Choose tufazip to study transmitted priors, synchronized online adaptation and exact-artifact verification, or to reproduce this specific benchmark with the necessary hardware and provenance. Do not select it for backups, untrusted-upload decompression or long-lived portable archives without substantially broader format documentation, tests, resource limits, safe checkpoint handling and overwrite protection.

## Verification Limits and Next Evidence

This review inspected public source and metadata, not the compressed payload or a GPU run. It did not reproduce the original decoder ZIP, offline training, timing, power usage, arbitrary-file encoding, interrupted-run equivalence or cross-runtime byte identity. Useful next evidence would be a publicly retrievable payload/archive with hashes, a complete prior-production recipe and data accounting, small CPU-safe round-trip/corruption tests, and a logged clean two-B200 decode plus interrupted/resumed equivalence check. None was simulated here.

**Attribution:** Tommy He / Tufalabs/tufazip; MIT, with Bellard and Nayuki notices. Analysis references public code and documentation at the pinned revision; no source code extracted.
