# SIMD Pretokenization Cache Pipeline

**Source:** [marcelroed/gigatoken](https://github.com/marcelroed/gigatoken)
**License:** MIT
**Extracted:** 2026-07-25

## Problem

Language-model data pipelines often treat tokenization as a library call wrapped by Python loops: read documents, split records, call a tokenizer, collect lists, and serialize results. That puts overhead in the wrong places. Regex pretokenization, Python object churn, repeated short string work, thread handoffs, and per-document allocations can dominate the actual BPE merge work.

## Pattern

Treat tokenization as one native pipeline:

```text
file/bytes source
  -> native document-boundary scanner
  -> family-specific SIMD/state-machine pretokenizer
  -> repeated-pretoken cache
  -> BPE merge engine with cache-friendly pair lookup
  -> flat ragged or padded output buffers
```

The key move is to optimize the whole path, not just the inner BPE loop. A fast tokenizer that still asks Python to split a corpus and marshal millions of tiny lists leaves too much throughput behind.

## Why It Works

Pretokenization has high repetition and strong tokenizer-family structure. Common short pieces recur constantly, and many production tokenizer regexes can be represented as specialized scanners rather than interpreted general-purpose regex passes.

Once input reading, boundary finding, pretokenization, and output assembly all live in the native layer, the runtime can:

- mmap uncompressed inputs and decompress compressed inputs once
- split work at document-safe boundaries
- release the host-language runtime lock during parallel work
- keep worker-local caches hot across batches
- reuse cached token IDs for frequent pretokens
- assemble flat buffers rather than nested object graphs
- avoid oversubscribing thread pools inside multiprocessing workers

## Minimal Version

```text
TokenizerWorker
  pretoken_cache: fixed-size short-token cache
  pair_rank_table: dense fast path plus fallback hash table

encode_files(source):
  load file as mmap or owned decompressed bytes
  detect format: text, JSONL, parquet
  cut chunks at document boundaries
  encode chunks in worker pool
  return one flat token buffer plus offsets
```

## Implementation Notes

- Start by supporting the tokenizer families that dominate your workloads.
- Keep a scalar fallback for Unicode and rare edge cases.
- Make compatibility deviations explicit. Reject unsupported wrapper behavior rather than silently returning almost-compatible results.
- Put parity tests against the canonical tokenizer at the center of the project.
- Benchmark whole-pipeline throughput, not only encode calls on pre-split strings.
- Detect forked or multiprocessing worker processes before using a global native thread pool.
- Be conservative with unsafe code: keep invariants close to the code and test boundary conditions heavily.
- Return columnar/ragged buffers when possible; nested per-document lists should be a compatibility layer, not the core representation.

## Good Fits

- pretraining corpus tokenization
- high-volume token counting
- repeated tokenizer use over JSONL, text, Parquet, gzip, or zstd corpora
- Python APIs backed by Rust/C++ native extensions
- systems where tokenizer family coverage is narrower than "every tokenizer ever"

## Poor Fits

- small interactive workloads
- model families whose tokenizers cannot be specialized safely
- product surfaces requiring exact support for every compatibility-library edge case
- teams without appetite for native-code release engineering

## Safety and Operations

This pattern moves complexity into native code. That can be the right trade, but only if correctness evidence is strong. Require parity tests against the reference tokenizer, exercise Unicode and special-token cases, benchmark on real corpus shapes, and publish source-build requirements clearly.

---

**Attribution:** marcelroed/gigatoken, MIT License.
