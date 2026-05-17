# Local-NotebookLM (Goekdeniz-Guelmez/Local-NotebookLM)

**Repo:** https://github.com/Goekdeniz-Guelmez/Local-NotebookLM
**License:** Apache-2.0; permissive reuse with attribution and patent grant.
**Reviewed:** 2026-05-17
**Stack:** Python, PyPDF2, OpenAI-compatible APIs, FastAPI/Uvicorn, Gradio, numpy, soundfile, Docker
**What it is:** Local-NotebookLM is a local-first PDF-to-audio tool. It extracts content from PDFs, asks an LLM to write an audio transcript, optimizes that transcript for TTS, and renders the result through a local or compatible speech endpoint.

---

## Verdict

⚠️ **Interesting local document-to-audio app, but keep it local unless hardened.** The core idea is useful and the implementation is small enough to understand quickly: PDF extraction, transcript generation, TTS preparation, audio rendering, plus CLI/API/UI wrappers. The repo is best treated as a personal/local tool today. The FastAPI and Gradio surfaces accept user-controlled paths and uploads without production-grade controls.

---

## What It Is

Local-NotebookLM positions itself as a local version of NotebookLM's audio generation workflow. Instead of building a full notebook/research system, it focuses on one practical output: turn a PDF into podcast-style or custom audio.

The app supports multiple LLM provider modes through OpenAI-compatible clients, including OpenAI, Groq, LM Studio, Ollama, and Azure. Its default local path pairs Ollama for text generation with a Kokoro-compatible TTS server. It can be used through a Python API, command line script, FastAPI server, Gradio web UI, or Docker image.

## Stack

| Layer | Tech |
|-------|------|
| Package | Python package, pyproject.toml, setup.py |
| PDF input | PyPDF2, optional extracted image payloads for VLM mode |
| LLM access | OpenAI Python client against hosted or local compatible APIs |
| TTS/audio | OpenAI-compatible speech endpoint, numpy, soundfile |
| Interfaces | CLI, FastAPI, Gradio |
| Container | Dockerfile with ffmpeg and selectable Gradio/API mode |
| Quality | No visible test suite; publish workflow only |

## Key Features

### PDF-to-Audio Pipeline

The central processor extracts PDF text, optionally pulls page images for VLM-style context, chunks the source material, generates a transcript, improves it for speech, then creates WAV audio segments and concatenates them.

### Flexible Output Controls

The CLI and UI expose language, style, length, number of speakers, output format, model, provider endpoint, and custom preferences. This makes it more useful than a one-off demo script.

### Local-First Provider Model

The defaults are aimed at local Ollama and Kokoro-style TTS endpoints, while still allowing hosted services. That is the right shape for private document workflows where source PDFs should not leave the machine unless the user chooses a hosted provider.

### Multiple Surfaces

The repository includes:

- local_notebooklm/processor.py — core pipeline.
- local_notebooklm/make_audio.py — CLI wrapper.
- local_notebooklm/server.py — FastAPI async job API.
- local_notebooklm/web_ui.py — Gradio UI.
- Dockerfile — container entrypoint for UI or API mode.

## Security and Maturity Notes

- Public repo metadata at review time: 897 stars, 113 forks, public, pushed 2026-05-08.
- GitHub API did not report a license, but the repo contains an Apache-2.0 LICENSE and pyproject declares Apache-2.0.
- Latest checked commit: 478ee37e856d3b5067cc591741c59cea2a828253, version bump to 2.0.1.
- Quick secret scan found only dummy local API key placeholders such as "not-needed".
- Syntax verification passed with python3 -m compileall local_notebooklm.
- No tests directory or normal CI test workflow was visible during review.
- Dependencies are broad and mostly unpinned in requirements.txt.

## Concerns

### API Should Not Be Internet-Facing As-Is

The FastAPI server exposes PDF upload and audio generation without authentication, rate limiting, explicit upload size controls, or strong content validation. That is acceptable for trusted localhost use, but risky on a LAN or public host.

### User-Controlled Output Paths

Both the API and Gradio UI accept output_dir from the caller and pass it into the processor, which creates directories and writes transcripts/audio there. A local desktop tool can reasonably expose output location, but a server should constrain writes to a controlled workspace.

### Uploaded Filename Handling

The API builds temporary upload paths using the raw uploaded filename. The UUID prefix helps avoid collisions, but filename components should still be sanitized or ignored. Generated safe filenames are simpler and more defensible.

### Runtime Version Drift

pyproject.toml requires Python >=3.12, setup.py declares >=3.9, and the Dockerfile uses python:3.11-slim. That kind of mismatch creates confusing install and support behavior.

### Release Workflow Exposure

The PyPI publish workflow appears focused on publishing and includes environment printing. Even with GitHub secret masking, release pipelines should avoid dumping environment state and should run tests/lint before publishing.

## Best Use

Use this as a local personal tool or as a reference implementation for PDF-to-audio workflows. Before using it as a shared service, add auth, upload limits, path confinement, safer temp-file handling, dependency pinning, and a small test suite around the processor and server edge cases.

---

**Attribution:** Goekdeniz-Guelmez/Local-NotebookLM, Apache-2.0 License.
