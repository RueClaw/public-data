# Local TTS Audiobook Pipeline

**Source:** santinic/audiblez
**Repo:** https://github.com/santinic/audiblez
**License:** MIT
**Reviewed:** 2026-05-18

## Pattern

Convert long-form documents into audiobooks through explicit intermediate stages instead of one opaque generation call:

1. parse the source document
2. extract and normalize readable sections
3. select chapters or content blocks
4. synthesize each chapter into a separate audio file
5. compute chapter durations
6. assemble the final audiobook container with metadata and cover art

The key implementation choice is the chapter-level intermediate file. If a long conversion fails halfway through, completed chapters can be reused, inspected, replaced, or regenerated independently.

## Why It Matters

Long TTS jobs are slow, failure-prone, and hard to evaluate as a single blob. A staged pipeline gives users and agents better control:

- chapter selection can be reviewed before synthesis
- text extraction bugs are visible before audio generation
- generated chapter files can be cached across reruns
- failed chapters can be retried without regenerating the whole book
- final packaging can be swapped without changing synthesis

## Implementation Shape

audiblez demonstrates this with:

- EPUB parsing via ebooklib
- text extraction via BeautifulSoup over document HTML tags
- sentence segmentation via spaCy
- synthesis via Kokoro voice IDs
- per-chapter .wav outputs
- ffprobe duration measurement
- ffmpeg assembly into .m4b with chapter metadata and optional cover art

## Borrowing Guidance

Use this pattern for local-first audio generation, especially when the source material is long enough that reruns are costly.

Keep these constraints:

- Store intermediate files with deterministic names.
- Skip existing chapter outputs only when the input text, voice, speed, and model version match.
- Separate parsing, normalization, synthesis, and packaging modules once the tool grows.
- Preserve source attribution and document metadata in the final container.
- Surface progress by characters, chapters, and estimated remaining time.

**Attribution:** santinic/audiblez, MIT
