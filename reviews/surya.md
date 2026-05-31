# Surya (datalab-to/surya)

**Repo:** https://github.com/datalab-to/surya  
**License:** Apache-2.0 code; modified AI Pubs OpenRAIL-M model license with use and commercial restrictions  
**Reviewed:** 2026-05-31  
**Stack:** Python 3.10+, PyTorch, Transformers, Pydantic, OpenAI-compatible inference, vLLM, llama.cpp, GGUF, pypdfium2, OpenCV, Streamlit, uv  
**What it is:** A document-intelligence toolkit for OCR, layout analysis, reading order, and table recognition across 90+ languages.

---

## Verdict

✅ **Deploy candidate for local document-intelligence experiments, with model-license review before commercial use.** Surya is a serious OCR/layout stack: mature docs, 20k GitHub stars, a unified 650M document VLM, CPU/Apple Silicon and NVIDIA GPU inference paths, structured outputs, and a small test suite wired into CI. The main caveat is licensing: the code is Apache-2.0, but the model weights are under a modified OpenRAIL-M license with explicit commercial restrictions.

---

## What It Is

Surya is Datalab's open document OCR and analysis package. Version `0.20.0` ships command-line tools and Python APIs for text-line detection, full-page OCR, layout detection, reading order, and table recognition. The current Surya 2 architecture routes layout, OCR, and table recognition through one vision-language model, while text-line detection and OCR-error detection remain separate PyTorch models.

The README claims an 83.3 score on `olmOCR-bench`, 87.2% on Datalab's internal 91-language benchmark, and 5.35 pages/s on an RTX 5090 through vLLM. Those numbers are strong, but they should be treated as upstream claims until reproduced on target documents and hardware.

## Stack

| Layer | Tech |
|-------|------|
| Package | `surya-ocr` Python package, version `0.20.0` |
| Core models | Surya OCR 2 VLM, text detection model, OCR-error model |
| Runtime | PyTorch, Transformers, OpenAI Python client |
| Inference backends | vLLM Docker server on NVIDIA GPUs; llama.cpp `llama-server` with GGUF on CPU/Apple Silicon |
| Inputs | Images and PDFs through Pillow and pypdfium2 |
| Outputs | JSON schemas, polygons/bboxes, HTML for OCR/math/tables, annotated images |
| CLI | `surya_detect`, `surya_ocr`, `surya_layout`, `surya_table`, `surya_gui`, `surya_screenshot` |
| Dev tooling | uv, pytest, GitHub Actions |

## Key Features

### Unified Document VLM

Surya 2 uses one VLM for layout, OCR, and table recognition. The model is prompted to emit either layout JSON or page/table HTML depending on the task. That avoids stitching together many unrelated OCR components while still preserving specialized outputs.

### OpenAI-Compatible Local Serving

The inference manager speaks to vLLM or llama.cpp through OpenAI-style chat completions. On NVIDIA hardware it can spawn a `vllm/vllm-openai` Docker container. On CPU or Apple Silicon it can download GGUF files and spawn `llama-server`. Users can also attach to an existing OpenAI-compatible endpoint with `SURYA_INFERENCE_URL`.

### Operational Server Lifecycle

The backend manager probes `/health`, uses a cache sentinel and file lock, reuses existing servers, can keep spawned servers alive across CLI calls, and validates the reported model id before attaching. That is a useful pattern for expensive local model processes.

### Structured Document Outputs

OCR output includes blocks, canonical layout labels, raw labels, reading order, HTML, polygons, bboxes, confidence, skipped/error flags, and page image bounds. Layout outputs include token-count estimates that shape later decode budgets. Table recognition can output geometric cells or full HTML.

### Practical Benchmark and Hardware Notes

The README provides concrete throughput numbers, vLLM settings, llama.cpp notes, multilingual breakdowns, and reproduction guidance using `olmOCR-bench`. It is unusually clear about hardware tradeoffs.

## Security and Operational Notes

The security posture is mostly what I expect from a local ML tool: no hardcoded real secrets found in a quick scan, local default inference host is `127.0.0.1`, and externally hosted inference can be opt-in through `SURYA_INFERENCE_URL`.

The risky surfaces are operational:

- vLLM spawning runs Docker with NVIDIA runtime, GPU selection, `--ipc=host`, a mounted Hugging Face cache, and exposed local port mapping.
- llama.cpp spawning downloads model and multimodal projector files from Hugging Face when local paths are not provided.
- legacy text detection and OCR-error models download from Datalab's model host.
- `surya_screenshot` starts a Flask app on `0.0.0.0:8504`, so do not run it on a shared host without network controls.
- the Streamlit/HTML rendering paths pull KaTeX assets from CDNs.

None of that is unusual, but it means this should be treated as a local document processing runtime, not a sandbox.

## Verification

Local verification on macOS/Apple Silicon:

- `git clone --depth 1` succeeded at commit `4d531586768e76974c8821eb338606005b95de04`.
- `uv sync --frozen --group dev` succeeded with Python 3.11.
- `uv run python -m compileall -q surya tests` passed.
- `uv run pytest --collect-only -q` collected 6 tests successfully.

I did not run full model-backed OCR tests because they download/start model backends and require either llama.cpp GGUF runtime or vLLM/GPU capacity. The repository's own GitHub Actions runs unit tests on Linux, Windows, and a T4 GPU runner, plus CLI script tests on a T4 runner.

## Caveats

- The code and weights have different licenses. The model license is not a normal permissive open-source license.
- Model use is restricted for organizations above stated revenue/funding thresholds and for competing products.
- Benchmark claims need document-specific reproduction.
- Apple Silicon throughput in the README is much lower than RTX 5090 throughput.
- The project has 144 open GitHub issues at review time, which is not alarming for a 20k-star ML repo but does mean edge cases are still active.

## Best Reusable Pattern

The strongest reusable pattern is the local document-intelligence VLM pipeline: keep document parsing behind task-specific predictors, but route heavy multimodal generation through a shared OpenAI-compatible local inference manager with health probes, file locks, sentinels, model-id validation, backend-specific spawn paths, and structured output schemas.

Extracted as `public-data/patterns/local-document-vlm-runtime.md`.

---

**Attribution:** datalab-to/surya, code Apache-2.0, model weights under modified AI Pubs OpenRAIL-M, https://github.com/datalab-to/surya
