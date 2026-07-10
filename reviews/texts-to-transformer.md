# Texts to Transformer (Doriandarko/texts-to-transformer)

**Repo:** https://github.com/Doriandarko/texts-to-transformer
**License:** MIT. Safe to fork and adapt with attribution.
**Reviewed:** 2026-07-09
**Stack:** Python 3.11, MLX, NumPy, Typer, tokenizers, SQLite, pytest, Ruff
**What it is:** A local Apple Silicon pipeline for training a tiny decoder-only Transformer from scratch on a user's iMessage history, with privacy-focused extraction, pseudonymization, chronological splits, MLX training, evaluation, export, and terminal-only reply generation.

---

## Verdict

✅ **Deploy candidate for controlled local experiments.** This is a refreshingly honest personal-model project: it does not pretend a 1M-7M parameter model becomes a real assistant, and it puts serious work into read-only data access, pseudonymization, leakage-resistant splits, aggregate-only audits, and no-send inference. Treat the generated datasets, tokenizer, checkpoints, and weights as sensitive private artifacts, but the codebase itself is one of the cleaner local personal-AI training pipelines I have seen.

---

## What It Is

`texts-to-transformer` trains a small language model from scratch on local Messages data. It snapshots `~/Library/Messages/chat.db` read-only, extracts message text, decodes Apple attributed-body payloads, pseudonymizes database identities, redacts obvious URLs/emails/phone numbers, groups messages into conversation sessions, creates chronological train/validation/test splits with guard bands, trains a byte-level BPE tokenizer on the training split only, then trains a custom decoder-only Transformer in MLX.

The project is explicit about the limits. The resulting model may mimic response length, punctuation, slang, rhythm, and common phrases; it will not reliably reason or answer factual questions. The local chat command only prints suggested replies in a terminal and never sends messages.

The main value is not the tiny model architecture by itself. The useful part is the end-to-end privacy boundary around personal text: safe database snapshotting, synthetic-only tests, aggregate reporting, private directory permissions, Git ignore checks, no attachment reads, and an audit command that rechecks the pipeline before treating a run as complete.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Typer |
| Local data source | macOS Messages SQLite database |
| Data processing | Python stdlib SQLite, JSONL, NumPy |
| Tokenizer | Hugging Face `tokenizers` byte-level BPE |
| Model | Custom decoder-only Transformer in MLX |
| Architecture | RMSNorm, RoPE, causal self-attention, SwiGLU, tied embeddings |
| Training | AdamW, warmup + cosine decay, gradient clipping, compiled MLX step |
| Evaluation | Held-out perplexity, unigram baseline, n-gram memorization probe, obvious-PII counts |
| Quality | pytest, Ruff, synthetic SQLite fixtures |

## Key Features

### Privacy-Bounded Data Pipeline

The data boundary is the standout. The snapshotter opens Messages with SQLite `mode=ro`, enables `PRAGMA query_only`, uses SQLite's online backup API, checks `PRAGMA quick_check`, and writes private snapshots under `work/`. Later stages use the copy, not the live database.

The extractor does not select attachment paths or open attachment files. It replaces message, chat, and participant identities with keyed HMAC pseudonyms, then redacts obvious URLs, emails, and phone-number-shaped strings before writing JSONL.

### Leakage-Resistant Dataset Splits

The project builds complete conversation sessions, deduplicates by content hash, orders by time, and creates chronological 90/5/5 train/validation/test splits with seven-day guard bands by default. It also trains the tokenizer only on the training split. That is the right discipline for personal chat data, where random adjacent-message splits would leak heavily.

### From-Scratch MLX Transformer

The model is intentionally small: the included presets are about 1.38M and 6.16M parameters. The implementation is conventional and readable: embeddings, RoPE, pre-norm attention blocks, SwiGLU MLP, tied output embeddings, causal mask, and next-token cross-entropy.

This is not a pretrained-model fine-tune. The README is clear that both tokenizer and model start from zero.

### Aggregate Evaluation and Completion Audit

Evaluation reports validation/test loss, perplexity, `me`-turn loss, a unigram baseline, train n-gram overlap aggregates, and obvious-PII pattern counts in generated samples. It does not persist matched private text.

The `audit` command rechecks readiness across snapshot integrity, extraction accounting, privacy audit, split isolation, tokenizer/train alignment, lint/format/tests, final artifact completeness, model hashes, private permissions, ignored private files, and fresh-process CLI inference.

## Architecture

The repository is organized as a clean local pipeline:

```text
src/imessage_mlx/data/      snapshot, schema inspection, extraction, redaction, sessions, splits
src/imessage_mlx/model/     decoder-only Transformer implementation
src/imessage_mlx/tokenizer/ byte-level BPE tokenizer training
src/imessage_mlx/train.py   MLX training loop
src/imessage_mlx/evaluate.py held-out evaluation and memorization checks
src/imessage_mlx/export.py  inference-only artifact export
src/imessage_mlx/generate.py terminal reply generation
tests/                      synthetic-only pytest coverage
```

The design is strongest where it refuses to shortcut privacy and data leakage. The code distinguishes live database access, private derived artifacts, aggregate reports, train-only tokenizer data, model selection from local token counts, and terminal-only generation.

## Comparison

| Aspect | Texts to Transformer | Handy | June | OpenHuman |
|--------|----------------------|-------|------|-----------|
| Primary job | Train a tiny personal text model locally | Local speech-to-text dictation | Desktop spoken-work assistant | Personal AI desktop harness |
| Data type | Private chat text | Microphone audio | Audio, notes, sessions, agent state | Memory, files, integrations |
| Inference | Local MLX toy/personal style model | Local ASR models | Local app plus hosted/private model routing | Mixed local/app integrations |
| Privacy posture | Strong local-only pipeline, sensitive artifacts remain private | Strong offline dictation posture | Strong local-state design plus API boundary | Broad and riskier integration surface |
| Best pattern | Privacy-bounded personal-text training pipeline | Desktop recording lifecycle | Saved-audio source of truth | Local memory/prompt-injection gates |

Compared with Handy and June, this is narrower and lower-level: no desktop app, no message sending, no general assistant shell. Compared with OpenHuman-style personal assistant projects, it is much more disciplined about avoiding broad integrations and keeping the generated model clearly scoped.

## Self-Hosting Notes

This is a local-only tool rather than a service. Requirements are specific:

- Apple Silicon Mac.
- macOS 14+.
- Python 3.11.
- MLX 0.32.0.
- Terminal or runner app with Full Disk Access.
- FileVault or equivalent disk protection strongly recommended for `work/` and `outputs/`.

Basic flow:

```bash
uv sync
uv run imessage-mlx doctor
uv run imessage-mlx snapshot --config configs/data.yaml
uv run imessage-mlx prepare --config configs/data.yaml
uv run imessage-mlx privacy-audit
uv run imessage-mlx train-tokenizer --train work/splits/train.jsonl --output outputs/tokenizer
uv run imessage-mlx corpus-stats --splits work/splits --tokenizer outputs/tokenizer --output work/tokens
uv run imessage-mlx train --config configs/model-1m.yaml --data work/tokens --tokenizer outputs/tokenizer --output outputs/runs/my-model
uv run imessage-mlx evaluate --checkpoint outputs/runs/my-model/best --data work/tokens --output outputs/evaluation.json
uv run imessage-mlx export --checkpoint outputs/runs/my-model/best --metrics outputs/evaluation.json --output outputs/final
uv run imessage-mlx chat --model outputs/final
```

Do not upload or share `work/`, `outputs/`, tokenizers, checkpoints, generated samples, or final weights trained on private messages.

## Verification

Passed locally on a fresh checkout:

```text
uv run ruff check .          # passed
uv run ruff format --check . # passed
uv run pytest -q             # 19 passed
git diff --check             # passed
git ls-files work outputs    # printed nothing
```

Notes:

- `uv` warns that `tool.uv.dev-dependencies` is deprecated in favor of `dependency-groups.dev`.
- Tests use synthetic fixtures; I did not run against a real Messages database or perform a full private training run.

---

**Attribution:** Doriandarko/texts-to-transformer, MIT License
