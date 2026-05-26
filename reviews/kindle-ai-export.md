# Kindle AI Export (transitive-bullshit/kindle-ai-export)

**Repo:** https://github.com/transitive-bullshit/kindle-ai-export
**License:** MIT. Code is permissive; exported book content remains subject to copyright, Kindle/Amazon terms, and local law.
**Reviewed:** 2026-05-26
**Stack:** TypeScript, Node 20+, pnpm, Patchright/Playwright, Sharp, OpenAI vision, PDFKit, ffmpeg, OpenAI TTS, Unreal Speech
**What it is:** A local tool that logs into Kindle Web Reader for books the user owns, captures rendered page images, transcribes those images with a vision model, then exports the result as JSON, Markdown, PDF, EPUB via Calibre, or a generated audiobook.

---

## Verdict

⚠️ **Interesting, but personal-use only.** Kindle AI Export is a clever, working pipeline for making owned Kindle books available to personal AI/media workflows without directly parsing DRM formats. The implementation is transparent and passes its format/lint/typecheck gate, but it sits in a legally and operationally sensitive area: account credentials, browser automation against Kindle, copyrighted text extraction, LLM OCR errors, and a stale lockfile with high-severity advisories.

---

## What It Is

Kindle AI Export is a TypeScript command-line project for exporting Kindle books from Kindle Web Reader. It uses a persistent Patchright/Chrome browser profile to sign in, navigates to `read.amazon.com` for a configured ASIN, changes reader settings to a single-column sans-serif layout, captures each rendered content page as a PNG, and stores metadata about pages, table of contents, locations, and book info.

The second stage sends each captured page image to `gpt-4.1-mini` and asks for verbatim OCR. The resulting `content.json` can then be converted into Markdown or PDF, and Calibre can convert the PDF to EPUB. A separate audio exporter splits the content into TTS batches, generates MP3 chunks with OpenAI TTS or Unreal Speech, concatenates them with ffmpeg, and writes ID3 metadata.

The project is explicit that users must own the Kindle book and should not share the resulting exports publicly. That disclaimer matters: this is useful for private accessibility, backup, search, annotation, and AI experiments, but it is not a publishing pipeline.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Node.js >=20, TypeScript ESM |
| Package manager | pnpm 10 |
| Browser automation | Patchright, Playwright, persistent Chrome profile |
| Image handling | Sharp |
| OCR/transcription | OpenAI chat completion with image input, default `gpt-4.1-mini` |
| PDF export | PDFKit |
| EPUB export | Calibre `ebook-convert` documented path |
| Audio export | OpenAI TTS, Unreal Speech, fluent-ffmpeg, node-id3 |
| CLI interaction | `@inquirer/prompts` for 2FA |
| Validation | Prettier, ESLint, TypeScript typecheck in CI |

## Key Features

### Rendered-page capture instead of DRM parsing

The central trick is simple: use the authorized web reader as the renderer, then capture the rendered page images. `src/extract-kindle-book.ts` logs into Kindle Web Reader, waits for the reader image, captures Blob-backed PNGs by monkey-patching `URL.createObjectURL`, downsizes with Sharp, and writes stable page files such as `out/<asin>/pages/<index>-<page>.png`.

This avoids direct AZW/KFX parsing, but it also means the pipeline depends on Kindle Web Reader DOM details and account/session behavior.

### Metadata-aware extraction

The extractor watches Kindle network responses for metadata, reader info, render TAR chunks, `location_map.json`, and `toc.json`. It uses those artifacts to infer content start/end pages, total content pages, table of contents, and Kindle location mappings.

That makes the output more useful than raw OCR because downstream exporters can preserve chapter structure and some Kindle sync-position context.

### Multi-format export

The project emits:

- `metadata.json` with book and navigation data;
- per-page PNGs;
- `content.json` OCR chunks;
- Markdown;
- PDF with a title page and outline;
- EPUB through Calibre conversion;
- MP3 audiobook through TTS and ffmpeg concatenation.

### TTS audiobook pipeline

`src/export-book-audio.ts` groups content by table-of-contents sections, splits text into provider-sized batches, writes per-batch MP3 files, skips existing chunks unless `FORCE=true`, concatenates with ffmpeg, and applies basic ID3 tags.

This is not as polished as a dedicated audiobook generator, but it is practical and resumable enough for personal experiments.

## Architecture

The repo is a set of stage-specific scripts rather than a packaged CLI:

- `src/extract-kindle-book.ts` owns browser login, reader normalization, page capture, metadata extraction, and progress reset.
- `src/transcribe-book-content.ts` turns page screenshots into text chunks with OpenAI vision.
- `src/export-book-markdown.ts` and `src/export-book-pdf.ts` render text plus TOC metadata into document formats.
- `src/export-book-audio.ts` batches text into TTS calls and assembles a final MP3.
- `src/playwright-utils.ts`, `src/types.ts`, and `src/utils.ts` hold parsing, typing, JSONP, TAR extraction, hashing, and formatting helpers.

Quality signals:

- `pnpm install --frozen-lockfile --strict-peer-dependencies` completed.
- `pnpm test` passed format, ESLint, and TypeScript typecheck.
- No unit/integration tests were visible; the test gate is static validation only.
- `pnpm audit --audit-level moderate` reported 31 advisories: 2 low, 10 moderate, 19 high.

## Security & Legal Notes

Use this only for books the user owns and only for private use. Exported book text and audio should not be republished.

Operational risks:

- Amazon credentials are loaded from `.env`; keep the repo and `out/<asin>/data` browser profile private.
- The browser profile likely contains session cookies.
- `extractTar` processes TAR buffers returned by Kindle renderer endpoints; the lockfile currently pins vulnerable `tar@7.5.1`, while patched advisories point to newer versions.
- The extractor uses `bypassCSP: true` and injected browser code. That is appropriate for this local workflow, but it should not be turned into a hosted service casually.
- OCR output is model-generated and can contain transcription errors.

## Comparison

| Aspect | Kindle AI Export | audiblez | Open Notebook | Calibre/Epubor-style conversion |
|--------|------------------|----------|---------------|---------------------------------|
| Input | Kindle Web Reader rendering | EPUB files | Documents/sources | Local ebook files |
| Main method | Browser capture + VLM OCR | EPUB parse + TTS | RAG/research workspace | Format conversion / DRM workflows |
| Output | Text, Markdown, PDF, EPUB, MP3 | Audiobook | Notes, chat, summaries, podcasts | PDF/EPUB/etc. |
| Best fit | Private owned Kindle library experiments | Local audiobook generation | Research over documents | Conventional ebook management |
| Main caveat | Legal/account/copyright sensitivity and OCR cost | EPUB-only input | Heavier app | DRM/tooling friction |

## Self-Hosting Notes

This is a local workstation tool, not a server. Basic setup:

```bash
pnpm install
cp .env.example .env
```

Then set `AMAZON_EMAIL`, `AMAZON_PASSWORD`, `ASIN`, and `OPENAI_API_KEY`. Optional audiobook generation also needs `ffmpeg` and either OpenAI TTS defaults or Unreal Speech credentials.

Before serious use, update dependencies and rerun `pnpm audit`. In particular, address the `tar` advisories because renderer TAR extraction is on the runtime path.

---

**Attribution:** transitive-bullshit/kindle-ai-export, MIT
