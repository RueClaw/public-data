# reader3 (karpathy/reader3)

*Review #292 | Source: https://github.com/karpathy/reader3 | License: MIT (stated in README; no file) | Author: Andrej Karpathy | Reviewed: 2026-03-30 | Stars: 3,415*

## Rating: 🔥🔥🔥

---

## What It Is

A self-hosted EPUB reader for reading books alongside an LLM. Created by Andrej Karpathy, explicitly described as "90% vibe coded" as a proof of concept. Python, FastAPI, ~350 lines total. Karpathy explicitly states he will not support or extend it — it's shared for inspiration.

---

## The Concept

Karpathy's workflow: get EPUB from Project Gutenberg, open in reader3, copy-paste chapter text to an LLM, read and discuss together. The reader is designed to make that copy-paste step trivial — one chapter at a time, clean text extracted, everything rendered simply.

The README links to a [tweet](https://x.com/karpathy/status/1990577951671509438) elaborating on reading with LLMs as a practice. The repo is the tooling for that workflow, not a product.

---

## Architecture

Two files plus templates:

**`reader3.py`** — EPUB parser/processor (~250 lines):
- Reads EPUB via `ebooklib`, parses TOC recursively (handles `Link`, `Section`, and tuple forms)
- Extracts and rewrites image paths, sanitizes HTML (strips scripts, styles, iframes, comments)
- Extracts plain text per chapter (`extract_plain_text()`) for LLM/search context
- Serializes everything to a `Book` dataclass, pickled to `<bookname>_data/book.pkl`
- Fallback TOC construction from spine when TOC is missing

Data structures:
```python
@dataclass class Book:
    metadata: BookMetadata     # title, authors, language, publisher, etc.
    spine: List[ChapterContent]  # physical files in reading order
    toc: List[TOCEntry]          # navigation tree (hierarchical)
    images: Dict[str, str]       # original_path → local_path
    source_file: str
    processed_at: str
    version: str = "3.0"

@dataclass class ChapterContent:
    id, href, title, content   # cleaned HTML with rewritten img srcs
    text                       # plain text for LLM context
    order                      # linear reading index
```

**`server.py`** — FastAPI web server (~110 lines):
- `GET /` → library view (scans for `*_data/book.pkl` directories)
- `GET /read/{book_id}/{chapter_index}` → chapter reader
- `GET /read/{book_id}/images/{image_name}` → image serving (path-sanitized)
- `@lru_cache(maxsize=10)` on book loading — no re-reads per session
- Jinja2 templates (`library.html`, `reader.html`)

**Usage:**
```bash
uv run reader3.py dracula.epub   # processes → dracula_data/book.pkl
uv run server.py                  # serves at localhost:8123
```

Multiple books: just process multiple EPUBs. Library page shows all `*_data` directories automatically.

---

## What's Interesting Here

This isn't technically novel — it's a minimal EPUB reader. What's interesting is *why* Karpathy built it and what it reveals about his reading workflow.

**The plain-text extraction is deliberate.** Each `ChapterContent` stores both `content` (cleaned HTML for display) and `text` (plain text via `get_text(separator=' ')` + whitespace collapse). The `text` field exists specifically for LLM context, named as such in the code comments. The reader is built around the assumption that you'll be feeding chapter text to an LLM.

**The scope is intentional.** 350 lines, no accounts, no sync, no highlights, no bookmarks. Local pickle files. The philosophy is "make it easy to add and delete books by adding and deleting folders." No state to maintain, no database to migrate.

**The vibe-coded ethos.** Karpathy's README line: "Code is ephemeral now and libraries are over, ask your LLM to change it in whatever way you like." He's demonstrating a posture toward software development, not just sharing a tool. The implication: start from a working minimal thing and let an LLM shape it for your needs, rather than depending on a maintained library.

---

## Caveats

- No LICENSE file (README says MIT).
- No support — Karpathy said explicitly.
- Pickle-based storage: fine for local use, security risk if `book.pkl` origin is untrusted.
- No mobile support noted, no search, no highlights, no sync.
- Python-only. No npm install, no Docker image — just `uv run`.

---

## Relevance

**For Marcos:** The plain-text extraction pattern is useful for the Parkinson's agent. If Marcos has books (medical references, etc.) in EPUB format, reader3's EPUB → plain text pipeline is already written and handles TOC, spine ordering, and image path rewriting. Could be adapted as an ingestion tool for a RAG system.

**For the Obsidian vault / content ingestion:** reader3's `extract_plain_text()` is a solid EPUB → text function worth lifting. Handles encoding errors (`errors='ignore'`), HTML comment removal, script/style stripping, whitespace normalization — all the ugly edge cases in EPUB content.

**As a workflow artifact:** More interesting as a demonstration of Karpathy's reading practice than as deployable software. Reading books with LLMs chapter-by-chapter as a study technique — the tool exists to reduce friction on that workflow.

---

## Verdict

🔥🔥🔥 — Not a production tool, explicitly not intended to be. A clean 350-line demonstration of a useful workflow (EPUB → LLM-assisted reading) with good extraction code worth lifting. The `ChapterContent.text` field and the `extract_plain_text()` function are the most immediately reusable parts. Karpathy's "code is ephemeral, modify it yourself" framing is as notable as the code. MIT. Cloned to `~/src/reader3`.
