# Privacy-Bounded Personal Text Model Pipeline

**Source:** [Doriandarko/texts-to-transformer](https://github.com/Doriandarko/texts-to-transformer)
**License:** MIT
**Extracted:** 2026-07-09

## Pattern

When training or evaluating a local model on private communications, make the privacy boundary a pipeline property rather than a README promise.

The useful shape:

```text
live private database
  -> read-only consistent snapshot
  -> schema inspection
  -> text extraction with attachment exclusion
  -> keyed pseudonymization
  -> obvious-PII redaction
  -> conversation sessionization
  -> chronological deduped train/validation/test split with guard bands
  -> train-only tokenizer
  -> local training
  -> aggregate-only evaluation and memorization checks
  -> inference-only export
  -> no-send local generation
```

## Review Gates

Good gates for this class of project:

- Live data is opened read-only and copied with a consistent snapshot mechanism.
- Later pipeline stages never touch the live source.
- Raw identifiers are replaced before dataset files are written.
- Attachment paths and attachment bodies are not selected unless explicitly needed.
- Obvious URLs, email addresses, and phone numbers are redacted by default.
- Splits are chronological, deduplicated, and separated by guard bands.
- The tokenizer is trained only on the training split.
- Evaluation reports aggregate counts and metrics, not matched private text.
- Memorization probes exist and do not persist private matches.
- Private artifacts are ignored by Git and stored with restrictive permissions.
- Generated text is a local suggestion; sending or external upload is a separate explicit action.

## Why It Matters

Personal text models can leak even after pseudonymization. Tokenizers, checkpoints, evaluation prompts, generated samples, and final weights can all retain private content. The safest implementation treats every derived artifact as sensitive and makes every command prove it has not crossed the boundary.

The pattern is also useful beyond chat data: email corpora, notes, transcripts, support tickets, document collections, and other private text workflows should use the same gates before local model training or retrieval experiments.

## Implementation Notes

Useful implementation details from the source:

- Use SQLite read-only URI mode plus `PRAGMA query_only` for live database access.
- Use a private snapshot directory, temporary file, atomic replace, restrictive permissions, hash manifest, and `PRAGMA quick_check`.
- Use keyed HMAC pseudonyms rather than stable raw IDs.
- Keep privacy audit reports aggregate-only.
- Add a final audit command that rechecks data, model, test, artifact, permission, and Git-ignore evidence.

---

**Attribution:** Pattern distilled from `src/imessage_mlx/data/`, `src/imessage_mlx/evaluate.py`, `src/imessage_mlx/audit.py`, and docs in [Doriandarko/texts-to-transformer](https://github.com/Doriandarko/texts-to-transformer), MIT License.
