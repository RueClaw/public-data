# Rendered-Page OCR Export Pipeline

**Source:** https://github.com/transitive-bullshit/kindle-ai-export
**Author:** Travis Fischer
**License:** MIT for code; exported source content remains governed by its own copyright and service terms
**Extracted:** 2026-05-26
**Type:** Architecture pattern

## Pattern

When a user has authorized access to content through an interactive reader but no clean machine-readable export, treat the reader as the renderer of record. Capture page images from the rendered UI, transcribe them with OCR or a vision model, preserve navigation metadata, and convert the result into private, user-controlled formats.

This pattern is useful for personal accessibility workflows, private search/indexing, document backup, offline reading experiments, and AI-assisted reading tools. It should not be used to republish copyrighted material or bypass access controls for content the user does not own or have permission to access.

## Core Shape

1. **Authenticate through the normal UI.** Use the user's authorized account/session rather than scraping unauthorized endpoints.
2. **Normalize reader settings.** Choose stable font, layout, column count, scale, and viewport settings to reduce OCR variability.
3. **Capture rendered pages.** Save one image per logical page using stable filenames that include page/index information.
4. **Persist source metadata.** Store title, authors, content version, table of contents, page/location maps, and source identifiers separately from OCR text.
5. **Transcribe page images.** Run OCR or a vision model on each page image, with retries and per-page error reporting.
6. **Stitch by structure.** Reconstruct chapters or sections using table-of-contents and page metadata rather than concatenating blindly.
7. **Export into private formats.** Generate JSON, Markdown, PDF, EPUB, audio, embeddings, or notes for personal use.
8. **Keep intermediates.** Preserve screenshots, OCR chunks, metadata, and generated media so the pipeline can resume and mistakes can be corrected.

## Why It Works

Some content systems render high-quality pages but do not expose convenient export APIs. Capturing the rendered page lets the existing app handle fonts, layout, pagination, glyph mapping, and access checks. The pipeline then turns visible user-accessible content into artifacts that are easier to search, annotate, listen to, or transform.

The key is to keep provenance clear. Page images and metadata let humans review OCR errors, trace generated text back to a source page, and regenerate outputs when the model or settings improve.

## Useful Design Details

- Use a persistent browser profile for accounts that require login or 2FA.
- Treat browser profile directories as secrets because they may contain cookies.
- Capture only the rendered content region, not full browser chrome.
- Use a deterministic page naming scheme such as `<index>-<page>.png`.
- Write metadata early and update it incrementally so interrupted runs can resume.
- Preserve both page numbers and source-specific location IDs where available.
- Batch TTS or OCR by durable chunks and skip already generated outputs on reruns.
- Hash generation settings and content when writing derived media directories.

## When To Use

Use this pattern for:

- private accessibility conversions,
- personal document/media transformation,
- rendered-only document viewers,
- long-form reading workflows,
- tools that need exact page-level provenance.

## Cautions

- Respect copyright, account terms, and access restrictions.
- Do not publish extracted content without rights.
- Do not run this as a shared hosted service without explicit legal and security review.
- OCR and vision models can make subtle transcription mistakes.
- Browser automation against third-party readers is brittle and may break when the UI changes.
- Any pipeline that extracts archives or renderer payloads should keep dependencies patched and restrict extraction paths.

## Attribution

This pattern is derived from `transitive-bullshit/kindle-ai-export`, especially `src/extract-kindle-book.ts`, `src/transcribe-book-content.ts`, `src/export-book-pdf.ts`, `src/export-book-markdown.ts`, and `src/export-book-audio.ts`.
