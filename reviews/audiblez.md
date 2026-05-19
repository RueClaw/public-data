# audiblez (santinic/audiblez)

**Repo:** https://github.com/santinic/audiblez
**License:** MIT. Permissive license; code and patterns can be reused with attribution.
**Reviewed:** 2026-05-18
**Stack:** Python, Kokoro TTS, ebooklib, BeautifulSoup, spaCy, soundfile, NumPy, ffmpeg/ffprobe, wxPython GUI
**What it is:** audiblez converts EPUB books into chaptered .m4b audiobooks using the Kokoro-82M text-to-speech model, with both CLI and GUI entry points.

---

## Verdict

⚠️ **Useful local audiobook utility with a clean pipeline, but not a general document-audio platform.** The project is practical, popular, permissively licensed, and focused on a real workflow: EPUB in, chapter WAVs plus final M4B out. The implementation is small and readable, but it depends on heavyweight local prerequisites and has rough edges around packaging, chapter heuristics, and broader input formats.

---

## What It Is

audiblez is a Python package for generating audiobooks from .epub files. It reads EPUB metadata and document sections, extracts readable text from HTML tags, chooses likely chapters, generates speech with Kokoro voices, writes chapter-level WAV files, and then uses ffmpeg/ffprobe to assemble a chaptered .m4b audiobook with optional cover art.

The README emphasizes local usage: install ffmpeg and espeak-ng, install audiblez from pip, then run audiblez book.epub -v af_sky. Version 4 adds a wxPython graphical interface, CUDA support, and multilingual Kokoro voice coverage.

This is not trying to be NotebookLM, a podcast generator, or a hosted audio service. Its value is narrower: a local, scriptable EPUB-to-audiobook converter that can use modern small TTS models.

## Stack

| Layer | Tech |
|-------|------|
| CLI | Python argparse |
| GUI | wxPython, Pillow |
| EPUB parsing | ebooklib, BeautifulSoup/lxml |
| Text segmentation | spaCy xx_ent_wiki_sm plus sentencizer |
| TTS | Kokoro 0.9.4, voice-code driven language selection |
| Audio IO | soundfile, NumPy |
| Packaging | Poetry-core, PyPI console scripts |
| Assembly | ffmpeg, ffprobe, M4B metadata chapters |
| CI | GitHub Actions install-and-convert checks on Linux and Windows |

## Key Features

### Local EPUB-to-M4B Pipeline

The core flow is intentionally simple:

1. read EPUB metadata and cover art
2. extract text from document chapters
3. select likely content chapters or let the user pick
4. generate one WAV per chapter
5. write chapter metadata with ffprobe durations
6. assemble a final .m4b with ffmpeg

That chapter-level intermediate format is the best design decision. It makes long conversions more debuggable and partially resumable because existing chapter WAV files are skipped on reruns.

### Kokoro Voice Coverage

The project uses Kokoro voices across American English, British English, Spanish, French, Hindi, Italian, Japanese, Brazilian Portuguese, and Mandarin Chinese. The language is inferred from the first character of the selected voice code, which keeps the CLI simple but couples voice naming directly to runtime behavior.

### CLI and GUI Surfaces

The CLI is enough for batch conversion and automation. The GUI adds EPUB opening, chapter preview/editing, voice selection, progress updates, and output-folder selection. The GUI is not architecturally fancy, but it makes the tool usable for non-terminal workflows.

### Real End-to-End CI

The GitHub workflows do more than run import checks. They install system dependencies, install the package, download a test EPUB, run conversion, and check that an .m4b is produced. That is exactly the kind of smoke test audio conversion projects need.

## Architecture

The repository is compact:

- audiblez/core.py contains EPUB parsing, chapter selection, Kokoro generation, WAV concatenation, M4B assembly, and helper functions.
- audiblez/cli.py exposes the command-line entry point.
- audiblez/ui.py wraps the same core flow in a wxPython interface with progress events.
- audiblez/voices.py lists voice IDs and language labels.
- test/ contains chapter-detection and conversion-oriented tests.
- .github/workflows/ runs pip-install and clone-install smoke tests.

The main tradeoff is that the core module owns many responsibilities at once. For a small utility this is acceptable; for a larger audio production system, the EPUB parser, text normalizer, synthesis runner, and ffmpeg packager should become separate modules with clearer contracts.

## Comparison

| Aspect | audiblez | Local NotebookLM-style tools | Cloud TTS workflows |
|--------|----------|------------------------------|---------------------|
| Primary input | EPUB | Usually PDF/docs/URLs | Any text/API input |
| Output | Chaptered M4B audiobook | Summaries, audio discussions, podcasts | Raw audio or app-specific assets |
| Runtime | Local Python + ffmpeg + Kokoro | Local app stacks vary | Hosted provider APIs |
| Best fit | Personal audiobook generation | Document study/listening | Production TTS integration |
| Privacy | Local by default | Usually local if self-hosted | Depends on provider |

## Self-Hosting Notes

This is a desktop/local tool rather than a server. Operational requirements are:

- Python 3.10 to 3.12 according to package metadata
- ffmpeg and ffprobe for M4B assembly and metadata
- espeak-ng for phonemizer/Kokoro support
- PyTorch and Kokoro dependencies
- optional CUDA for much faster synthesis
- optional pillow and wxpython for the GUI

The README reports about 5 minutes for a 160k-character book on a Colab T4 GPU and roughly 1 hour on an M2 MacBook Pro CPU. That is a useful expectation-setter: CPU conversion works, but this is still a long-running batch job.

---

**Attribution:** santinic/audiblez, MIT
