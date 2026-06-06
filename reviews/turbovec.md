# TurboVec (RyanCodrai/turbovec)

**Repo:** https://github.com/RyanCodrai/turbovec  
**License:** MIT, permissive for use, modification, and extraction with attribution  
**Reviewed:** 2026-06-06  
**Stack:** Rust, PyO3/maturin, NumPy, Rayon, faer, SIMD intrinsics, Python integration wrappers  
**What it is:** A local vector index built around Google's TurboQuant method, with Rust and Python APIs for compressing high-dimensional embeddings to 2-4 bits per coordinate while preserving search quality.

---

## Verdict

✅ **Deploy candidate for local/private RAG indexes where memory pressure matters.** TurboVec is unusually credible for a young vector-search repo: the core idea is math-backed, the implementation has real SIMD work, filtering is handled inside the search kernel, and the latest release is dominated by correctness fixes rather than demo polish. I would still benchmark it against the target embedding distribution and hardware before replacing FAISS/Qdrant/Milvus in a production path.

---

## What It Is

TurboVec is an approximate nearest-neighbor/vector index for embeddings. Instead of storing every vector as float32, it normalizes vectors, rotates them into a predictable coordinate distribution, quantizes each coordinate with Lloyd-Max buckets, packs the codes into 2-4 bits, and searches directly over the packed representation.

The README's practical pitch is simple: a 10M-document, 1536-dimensional float32 corpus is about 31 GB; TurboVec says the same corpus fits around 4 GB at 2-bit while searching faster than FAISS FastScan on several reported ARM and x86 configurations. The repo includes benchmark scripts and saved result JSONs for recall, compression, and speed.

The library exposes both a positional `TurboQuantIndex` and an `IdMapIndex` with stable external `u64` IDs. The Python package wraps those with NumPy-facing APIs and optional LangChain, LlamaIndex, Haystack, and Agno integration modules.

## Stack

| Layer | Tech |
|-------|------|
| Core library | Rust 2021 crate, version 0.8.0 |
| Python package | PyO3, maturin, NumPy, package version 0.7.0 |
| Search kernels | NEON on ARM, AVX-512BW and AVX2 on x86, scalar fallback |
| Parallelism/math | Rayon, faer, ndarray, statrs, rand |
| Persistence | Custom `.tv` and `.tvim` binary formats, current format v3 |
| Integrations | LangChain, LlamaIndex, Haystack, Agno |
| CI/tests | GitHub Actions across Ubuntu, macOS, Windows; Rust tests and Python wheel/integration tests |

## Key Features

### TurboQuant-Style Compression

TurboVec implements a data-oblivious quantization path based on random rotation plus Lloyd-Max scalar quantization. It does not need a separate training phase or codebook fitting pass in the FAISS PQ sense; vectors can be added online.

The repo adds TQ+ calibration on the first add: per-coordinate shift/scale values are fitted from empirical 5/95% quantiles and frozen for subsequent vectors. That is a sensible compromise between fully training-free operation and real-world finite-dimensional embedding drift.

### Kernel-Level Filtering

Filtering is not bolted on after search. `TurboQuantIndex.search_with_mask` and `IdMapIndex.search_with_allowlist` convert allowed slots into a packed mask and skip blocks without allowed candidates before scoring. That matters for hybrid retrieval, ACL filtering, tenant isolation, and time-windowed search: the returned top-k comes from the allowed set, not from over-fetch-and-drop.

### Stable IDs and O(1) Deletes

`IdMapIndex` wraps the positional index with a bidirectional `u64 <-> slot` table. Deletes use swap-remove semantics, then repair the moved ID mapping. This is the right shape for document stores that need stable external IDs without preserving insertion order.

### Framework Integrations

The Python package includes reference-style vector stores for LangChain, LlamaIndex, Haystack, and Agno. These are not just README snippets; they live in the package, have persistence behavior, and are covered by integration tests in CI.

## Architecture

The core is split into focused Rust modules:

- `turbovec/src/encode.rs` handles normalization, rotation, TQ+ calibration, quantization, and scale calculation.
- `turbovec/src/search.rs` holds the query calibration, LUT construction, SIMD scoring kernels, mask skipping, and heap top-k.
- `turbovec/src/pack.rs` repacks codes into blocked layouts for SIMD search.
- `turbovec/src/id_map.rs` layers stable IDs and O(1) removal on the positional index.
- `turbovec/src/io.rs` owns `.tv` and `.tvim` versioned serialization.

The strongest engineering signal is the test suite around the risky state transitions: lazy dimension commitment, add-after-load, add-after-search cache invalidation, swap-remove, allowlists, all-false masks, invalid input values, v2/v3 format compatibility, and concurrent search.

Local verification for this review ran:

```bash
cargo test -p turbovec --release
```

Result: 132 Rust tests plus 2 doc tests passed. The build produced three non-failing compiler warnings in `search.rs` for unused variables/dead scalar fallback code on the local target.

## Comparison

| Aspect | TurboVec | FAISS PQ/FastScan | Qdrant/Milvus/Chroma |
|--------|----------|-------------------|----------------------|
| Primary role | Embedded compressed vector index | Mature vector search library | Full vector database/service stack |
| Training requirement | Online, no separate train phase | PQ commonly uses training/codebooks | Varies by backend/index |
| Memory story | 2-4 bit per coordinate packed codes | Strong but configuration-dependent | Often stores more metadata/service overhead |
| Filtering | Kernel mask/allowlist support | Filtering support depends on wrapper/index use | Usually strong metadata filtering |
| Maturity | Young, fast-moving, alpha Python classifier | Very mature | Mature operational systems |
| Best fit | Local/private RAG, embedded document stores, memory-constrained search | High-performance native search baselines | Multi-user service, metadata, ops, replication |

TurboVec is not a drop-in replacement for a vector database. It is closer to a compact local index primitive. That is a useful niche: it can sit inside a local application, edge workload, or private retrieval stack where running a full vector service is unnecessary.

## Self-Hosting Notes

Python install:

```bash
pip install turbovec
```

Rust install:

```bash
cargo add turbovec
```

For source builds, the Python package uses maturin. On Linux, the Rust crate links BLAS/OpenBLAS through the build path; the CI installs `libopenblas-dev` before tests. x86 builds target an AVX2 baseline with runtime dispatch to AVX-512BW when available.

Operational cautions:

- Benchmark on the target embedding model and dimensionality before trusting the README speed/recall claims.
- Keep full-precision embeddings elsewhere if the application needs MMR or reranking over raw candidate embeddings.
- Treat `.tv`/`.tvim` format compatibility as a real migration surface; v3 is backward-compatible with v2, but older readers cannot load newer files.
- The Python package is marked alpha despite the strong internal test posture.

---

**Attribution:** RyanCodrai/turbovec, MIT. Review based on repository source, README, changelog, docs, GitHub metadata, and local Rust test execution on 2026-06-06.
