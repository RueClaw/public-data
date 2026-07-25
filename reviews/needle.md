# Needle (cactus-compute/needle)

**Repo:** https://github.com/cactus-compute/needle
**License:** MIT, suitable for reuse with attribution.
**Reviewed:** 2026-07-25
**Stack:** Python, JAX, Flax, Optax, SentencePiece, Hugging Face Hub, Gemini data generation, local HTTP UI
**What it is:** A 26M-parameter, 14MB function-calling model and training toolkit aimed at tiny on-device agents.

---

## Verdict

⚠️ **Interesting for on-device function-calling experiments, but not a drop-in agent component yet.** Needle has a sharp target: very small local models that map user requests plus tool schemas into JSON function calls. The architecture and finetune loop are worth studying, and the MIT license/open weights make it easy to experiment. Treat it as research-grade until the benchmark claims are reproduced locally, the checkpoint trust boundary is handled, and the setup/training scripts are sandboxed.

---

## What It Is

Needle is Cactus Compute's tiny tool-calling model. The README describes a 26M parameter "Simple Attention Network" distilled from Gemini 3.1, trained for single-shot function calling, and running in production inside Cactus' on-device runtime. It claims 6000 tokens/sec prefill and 1200 tokens/sec decode in that environment.

The repo includes the model architecture, inference helpers, grammar-constrained decoding, data generation, pretraining/finetuning code, TPU helpers, a CLI, and a local playground UI. The intended workflow is:

1. Define tools.
2. Generate or provide JSONL tool-call examples.
3. Finetune locally or on TPU.
4. Run a tiny model that emits JSON function-call objects.

This is not trying to be a broad conversational model. The project explicitly says larger models such as FunctionGemma, Qwen, Granite, and LFM are better conversational systems. Needle is optimized for tiny-device tool routing.

## Stack

| Layer | Tech |
|-------|------|
| Model | JAX/Flax encoder-decoder Simple Attention Network |
| Tokenizer | SentencePiece BPE, 8192 vocab |
| Inference | Greedy JAX decode with optional JSON/tool constraints |
| Training | Optax, custom Muon optimizer, optional INT4 QAT, W&B logging |
| Data | Hugging Face datasets plus Gemini synthetic data generation |
| UI | Python `ThreadingHTTPServer`, static HTML/JS playground |
| Cloud helpers | GCP TPU VM orchestration via `gcloud` |

## Key Features

### Tiny Function-Call Target

The model is deliberately narrow: produce compact JSON tool calls from a query and a list of tools. That makes the architecture plausible for watches, phones, home devices, local assistants, and other places where a general LLM is too large.

### Attention-Only Encoder-Decoder

The architecture removes feed-forward layers by default and relies on attention/cross-attention for query-to-tool alignment and value copying. The documented production config uses `d_model=512`, 12 encoder layers, 8 decoder layers, grouped-query attention, RoPE, ZCRMSNorm, gated residuals, and tied embeddings/output head.

The rationale is domain-specific: tool calling is mostly retrieval, alignment, and structured assembly, so cross-attention is the primitive the authors want to spend parameters on.

### Constrained Decoding

`needle/model/constrained.py` builds a character-level trie for tool names and argument keys, then masks logits while the generated JSON is inside constrained spans. Values remain unconstrained. This is a good lightweight guardrail: the model still generates naturally, but tool names and argument keys are kept close to the schema.

### Local Finetune Loop

The CLI and playground make custom-tool finetuning a first-class path. The UI can generate examples from a Gemini API key, train for a short run, evaluate base versus finetuned performance, and bundle the resulting checkpoint with train/val/test splits and an eval report.

## Architecture Notes

The core code is compact and readable:

- `needle/model/architecture.py` defines the model blocks, ZCRMSNorm, attention, encoder/decoder layers, segment-aware masks, and contrastive retrieval head.
- `needle/model/run.py` handles checkpoint loading, tokenizer setup, tool-name normalization, greedy generation, and batch generation.
- `needle/model/constrained.py` implements the JSON state machine and constrained token masking.
- `needle/training/finetune.py` implements per-tool splits, quick evaluation, checkpoint download, finetuning, and checkpoint saving.
- `needle/ui/server.py` hosts the playground and finetune flow.
- `needle/utils/tpu.py` wraps GCP TPU lifecycle, sync, setup, train, and delete commands.

The most reusable idea is the narrow end-to-end loop: small model, small schema dialect, synthetic examples, local finetune, constrained decode, and held-out eval.

## Caveats

### Checkpoints Are a Trust Boundary

Needle checkpoints are Python pickle files. `load_checkpoint()` calls `pickle.load()`, and the UI can upload `.pkl` checkpoints before loading them. Pickle is executable input, so only load checkpoints from trusted sources and preferably inside a sandbox.

### Setup Script Has Side Effects

The `setup` script is convenient, but it can run `sudo apt-get`, `sudo modprobe`, and write transparent hugepage settings depending on the environment. It also prompts for W&B credentials. Read it before sourcing it on a shared or sensitive machine.

### Benchmark Claims Need Reproduction

The README reports strong single-shot function-calling results and high Cactus runtime throughput, but I did not run the model or reproduce the benchmark locally. Treat the claims as promising project claims, not independent verification.

### Schema Dialect Is Narrow

The README examples use a flat `parameters` object where each key is an argument. The constrained decoder's docstring mentions JSON Schema-style `parameters.properties`, but the code iterates the immediate `parameters` keys. Standard tool schemas may need conversion before constraints do the intended thing.

### Test Coverage Is Not Obvious

I did not find a committed test suite or CI workflow in the repository snapshot. `python3 -m compileall needle` passed, which catches syntax/import-parse issues, but it is not behavioral validation.

## Good Fits

- on-device personal assistants
- local tool-routing experiments
- tiny model finetuning research
- function-call benchmark comparisons
- constrained decoding patterns
- edge runtime prototyping with Cactus

## Poor Fits

- general chat or reasoning without a larger model
- high-trust automation without independent evals
- loading arbitrary user-supplied checkpoints
- teams that need a stable, heavily tested SDK today
- standard JSON Schema tool definitions without adapter code

## Verification

Local verification on 2026-07-25:

- Reviewed README, model architecture, constrained decoding, CLI, UI server, finetuning, synthetic data generation, TPU helpers, and package metadata.
- `python3 -m compileall needle` passed.
- No `tests/`, `pytest`, or GitHub Actions workflow files were found in the repository snapshot.
- I did not install full JAX dependencies, download weights, run inference, run finetuning, or reproduce benchmark numbers.

---

**Attribution:** cactus-compute/needle, MIT License.
