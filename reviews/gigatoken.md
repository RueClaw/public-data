# Gigatoken (marcelroed/gigatoken)

**Repo:** https://github.com/marcelroed/gigatoken
**License:** MIT, suitable for reuse with attribution.
**Reviewed:** 2026-07-25
**Stack:** Rust, PyO3/maturin, Python, Rayon, portable SIMD, memmap2, Arrow/Parquet, Hugging Face Tokenizers, tiktoken
**What it is:** A high-throughput tokenizer engine for language-model data pipelines, with Hugging Face and tiktoken compatibility wrappers plus a faster native file-oriented API.

---

## Verdict

✅ **Deploy candidate for tokenization-heavy research and data-pipeline pilots.** Gigatoken is unusually serious performance work: custom SIMD pretokenizers, persistent pretoken caches, Rust-side file loading/chunking, Python object churn avoidance, broad tokenizer parity tests, wheel workflows, and clear benchmark caveats. I would reproduce its claims on the exact corpora and tokenizer families in use, and I would prefer published wheels over local source builds unless the host has nightly Rust.

---

## What It Is

Gigatoken is a Rust/Python tokenizer package aimed at making language-model dataset tokenization much faster than conventional Python-facing tokenizers. The README positions it as roughly 1000x faster than Hugging Face Tokenizers in some file-oriented benchmarks, with GB/s throughput on large multi-core machines.

It has three use modes:

1. **Hugging Face compatibility:** wrap an existing tokenizer with `gt.Tokenizer(hf_tokenizer).as_hf()`.
2. **tiktoken compatibility:** wrap a tiktoken encoding with `gt.Tokenizer(tiktokenizer).as_tiktoken()`.
3. **Native Gigatoken API:** load from a Hugging Face repo/path or model file, then encode strings, batches, or files directly.

The native API is the important one. It lets Rust read text, JSONL, Parquet, gzip, and zstd sources, split documents at boundaries, mmap uncompressed files, decompress compressed files into memory, encode across Rayon workers, and return one flat ragged token buffer instead of one Python object graph per document.

## Why It Is Fast

The core idea is to move both tokenization and input handling out of Python:

- family-specific pretokenizers replace regex-driven scanning with hand-written SIMD/state-machine scanners
- repeated short pretokens are cached in an open-addressed cache with cache-line-aware probing
- BPE merge lookup uses dense tables for common byte/early-token pairs and a flat hash table for the rest
- batch and file APIs release the GIL and keep worker-local caches warm
- file sources avoid pre-splitting corpora in Python
- padded/truncated compatibility outputs can be assembled in Rust in one pass

The code is performance-tuned in ways that are rare in tokenizer repos. It uses 2 MiB alignment, huge-page hints where available, explicit prefetching, unsafe hot paths with safety comments, byte-region chunking, and fork-aware multiprocessing defaults to avoid Rayon deadlocks and oversubscription.

## Compatibility

Gigatoken deliberately distinguishes "drop-in enough" from "identical in every corner." The Hugging Face adapter implements common fast-tokenizer methods, padding, truncation, NumPy/PyTorch tensor returns, special-token accessors, conversion helpers, and decode paths. It rejects unsupported sequence-pair and pre-tokenized-input paths rather than silently diverging.

The tiktoken adapter implements ordinary and batch encode/decode methods, vocab helpers, special-token checks, and single-token conversions. One semantic difference is explicit: Gigatoken always recognizes special tokens while encoding, so paths that would encode a special token as ordinary text raise instead of matching tiktoken's exact behavior.

## Benchmark Posture

The README publishes benchmark tables for:

- dual AMD EPYC 9565 servers, with GPT-2 at 24.53 GB/s and many BPE families around 19-24 GB/s
- Apple M4 Max, with GPT-2 at 8.79 GB/s and many BPE families around 5.5-7.8 GB/s
- Ryzen 7 9800X3D, with GPT-2 at 6.27 GB/s and many BPE families around 4-6 GB/s

SentencePiece-family models are much slower than the best BPE paths, typically a few GB/s in the published tables. The README also gives a useful caveat: comparisons against Hugging Face and tiktoken use smaller pre-split subsets, while Gigatoken encodes the whole file and finds document boundaries itself. That is fair for pipeline throughput, but teams should still benchmark their own corpus shape, separator behavior, tokenizer family, and output format.

## Testing and CI

The test suite is broad for a young performance library. I found 29 Python test files and 186 test functions covering encode behavior, file sources, JSONL, Parquet, Hugging Face loading, tiktoken loading, compatibility adapters, SentencePiece conversion, Kimi config dispatch, multiprocessing behavior, and BPE training comparisons.

CI builds Python wheels across Linux, musllinux, Windows, and macOS targets using maturin, with tag publishing to PyPI and artifact attestation. A manual release workflow builds x86_64/aarch64 Linux and Windows wheels using nightly Rust and smoke-tests wheels on Python 3.10 through 3.14 where supported.

## Caveats

- Source builds currently require unstable Rust/Cargo support; local `cargo check` failed on this machine because stable Cargo did not support the required `profile-rustflags` feature.
- WordPiece is unsupported.
- SentencePiece-based tokenization is documented as less optimized.
- Windows is documented as lightly tested, with WSL recommended.
- The high-performance internals are unsafe/SIMD-heavy, so correctness depends heavily on the parity tests and fuzz-like coverage over edge cases.
- The compatibility wrappers intentionally reject some Hugging Face/tiktoken behaviors rather than emulate every edge case.
- File sinks are not implemented yet, so very large output workflows may still need careful memory planning.

## Best Fits

- large-scale LM pretraining or continued-pretraining data pipelines
- repeated token-counting and corpus-preparation jobs
- environments already using Hugging Face or tiktoken but bottlenecked on tokenization
- Rust/Python shops comfortable with native wheels and SIMD-heavy dependencies
- research runs where encoding speed changes iteration time materially

## Poor Fits

- apps needing every Hugging Face tokenizer behavior, including sequence pairs and pre-tokenized inputs
- WordPiece-heavy model families
- environments that must build from source on stable Rust only
- small interactive workloads where tokenizer speed is not a meaningful bottleneck
- deployments that cannot tolerate young native-code dependencies

## Extracted Pattern

Extracted to `patterns/simd-pretokenization-cache-pipeline.md`.

The reusable pattern is to treat tokenization as a whole data path, not just an encode function: move document loading, boundary finding, SIMD pretokenization, repeated-pretoken caching, BPE merge lookup, and output assembly into one native pipeline.

## Verification

Local review on 2026-07-25:

- Reviewed README, `Cargo.toml`, `pyproject.toml`, license, contributing policy, Python API, Hugging Face and tiktoken compatibility wrappers, multiprocessing defaults, Rust bindings, BPE core, pretoken cache, family-specific pretokenizers, input/file-source code, tests, benchmarks, profiling notes, and GitHub Actions.
- GitHub metadata showed MIT license, 3,314 stars, 156 forks, 11 open issues, and latest commit `34a1599` (`Bump minor version to 0.10.0`) on 2026-07-25.
- `gh release list` returned no GitHub releases, but package workflows target PyPI/wheel artifacts.
- Recent GitHub Actions history visible through `gh run list` only showed cancelled PR runs for an older encode-pipeline branch.
- Local `cargo check` could not run because the installed stable Cargo does not support the repo's required unstable `profile-rustflags` feature. `rustup` and `maturin` were not installed locally.

---

**Attribution:** marcelroed/gigatoken, MIT License.
