# MinerU (opendatalab/MinerU)

**Repo:** https://github.com/opendatalab/MinerU  
**License:** MinerU Open Source License, Apache-2.0 plus commercial thresholds and online-service attribution requirements  
**Reviewed:** 2026-06-24  
**Stack:** Python, FastAPI, Click, Docker, PyTorch, Transformers, ONNX Runtime, vLLM, LMDeploy, MLX, pypdfium2, Office XML parsers  
**What it is:** MinerU converts PDFs, images, DOCX, PPTX, and XLSX into LLM-ready Markdown, JSON, intermediate layout data, tables, formulas, and visual debugging artifacts.

---

## Verdict

✅ **Deploy candidate for private document parsing and RAG ingestion.** MinerU is active, broad, and operationally serious: local CLI, FastAPI, Gradio, Docker, async tasks, router-based multi-worker deployment, multiple inference backends, and native Office parsing. The caveats are the custom license, model/runtime weight, and the need to benchmark extraction quality on representative documents before trusting output in production workflows.

---

## What It Is

MinerU is a document parsing engine for turning messy documents into structured machine-readable artifacts. It handles text PDFs, scanned PDFs, images, DOCX, PPTX, and XLSX; extracts reading-order Markdown, content lists, tables as HTML, formulas as LaTeX, layout visualizations, OCR spans, and middle JSON for secondary development.

The project has grown beyond a single converter. Current releases include a `pipeline` backend, a VLM backend, and a hybrid backend. It also ships a CLI, `mineru-api`, `mineru-router`, `mineru-gradio`, OpenAI-compatible VLM server commands, Docker deployment files, model-download tooling, and integrations aimed at RAG and agent workflows.

The repo is very active: about 68.7k stars, 5.8k forks, latest release `mineru-3.4.0-released` on 2026-06-18, and a push on 2026-06-22. The 3.x line added native Office parsing, async task APIs, router-based multi-GPU deployment, hybrid effort modes, PP-OCRv6 upgrades, cache-aware model download, and a move away from the old AGPL licensing posture.

## Stack

| Layer | Tech |
|-------|------|
| Language | Python 3.10-3.13 |
| API | FastAPI, Uvicorn, multipart uploads, async task endpoints |
| CLI | Click, package scripts for `mineru`, `mineru-api`, `mineru-router`, VLM servers, Gradio |
| Document inputs | pypdfium2, pypdf, pdftext, Pillow, OpenCV, python-docx, openpyxl, mammoth, pypptx-with-oxml, lxml |
| ML runtime | PyTorch, Transformers, ONNX Runtime, safetensors, ModelsScope, Hugging Face Hub |
| Inference backends | pipeline, VLM engine, hybrid engine, vLLM, LMDeploy, MLX, OpenAI-compatible HTTP client modes |
| UI | Gradio |
| Deployment | Docker, Compose, GPU profiles for API/router/OpenAI-compatible server/Gradio |
| Tests | pytest e2e around pipeline parsing and content assertions |

## Key Features

### Multi-Format Document Parsing

MinerU supports PDFs, images, DOCX, PPTX, and XLSX. The 3.x releases made native Office parsing a first-class feature instead of requiring everything to be converted to PDF first. That matters for throughput and fidelity, especially with slides, spreadsheets, and text-heavy Word documents.

### Multiple Parsing Backends

The public backend choices are `pipeline`, `vlm-engine`, `hybrid-engine`, `vlm-http-client`, and `hybrid-http-client`. The default is the hybrid engine, with `medium` and `high` effort levels. Medium trades off some image analysis for speed; high preserves the fuller visual analysis path.

### API, Tasks, and Router

`mineru-api` exposes synchronous `/file_parse` and asynchronous `/tasks` flows. `mineru-router` can aggregate local or upstream API workers, track queue/processing/completed/failed counts, assign work by load, and expose compatible endpoints. That makes MinerU more deployable than a pure batch CLI.

### Structured Outputs for Downstream Systems

MinerU writes Markdown plus structured JSON artifacts: content lists, middle JSON, model inference outputs, layout PDFs, span PDFs, extracted images, and multimodal Markdown. This is the right shape for RAG ingestion because downstream systems can preserve page geometry, visual blocks, tables, formulas, and debug evidence instead of flattening everything into plain text.

### Public-Bind HTTP Client Guard

The API and router include an explicit policy for caller-supplied remote inference endpoints. When bound to `0.0.0.0` or `::`, MinerU disables `*-http-client` backends and `server_url` by default unless the operator starts with `--allow-public-http-client`. The code calls out the SSRF/internal network probing risk directly.

That is a good self-hosted API pattern: a useful advanced feature remains available for trusted deployments, but the dangerous combination is blocked by default when the service is publicly exposed.

## Architecture

The codebase is organized around a few clear boundaries:

- `mineru/cli/` contains the user-facing client, FastAPI service, router, backend option validation, output path logic, Gradio app, model download commands, and public HTTP-client policy.
- `mineru/backend/` contains pipeline, VLM, and hybrid analysis paths.
- `mineru/model/` contains Office converters, OCR, layout, formula recognition, table recognition, and VLM server helpers.
- `mineru/data/` contains file/S3/multi-bucket IO abstractions.
- `mineru/utils/` contains PDF/image/language/OCR/table/config helpers.

The most interesting design choice is not one algorithm. It is the service shape: local batch CLI, API service, task queue, router, local worker spawning, remote inference client modes, and structured output generation all point at the same parsing capability.

## Comparison

| Aspect | MinerU | Surya | Stirling PDF |
|--------|--------|-------|--------------|
| Main job | Convert documents into Markdown/JSON for LLM/RAG workflows | OCR/layout/table recognition with document VLM outputs | Broad PDF manipulation/conversion platform |
| Inputs | PDF, images, DOCX, PPTX, XLSX | Mostly images/PDF pages | PDFs and many conversion inputs |
| Runtime | Python service plus ML backends and Office parsers | Python document VLM/OCR stack | Java/Spring app plus many external PDF tools |
| Outputs | Markdown, content JSON, middle JSON, visual debug PDFs, images | OCR/layout/table JSON/HTML/geometry | Modified PDFs, converted files, OCR outputs |
| Deployment | CLI, API, router, Gradio, Docker | CLI/API-style local model runtime | Self-hosted web app/desktop/API |
| Best fit | RAG/document ingestion pipeline | OCR/layout component | PDF workstation/service |

## Self-Hosting Notes

MinerU is not a tiny utility. Expect model downloads, GPU/runtime choices, Docker image selection, and per-backend tuning. The docs explicitly warn that Docker acceleration is Linux/WSL2-oriented and not recommended for macOS acceleration; Apple Silicon users should look at the MLX path instead.

For a private deployment:

- bind APIs to localhost or put them behind real auth and network controls;
- leave `--allow-public-http-client` off unless callers are fully trusted;
- set upload/page/task limits appropriate to the host;
- pin model source and model cache for repeatability;
- preserve structured outputs and visual debug files while evaluating quality;
- benchmark on representative documents before making MinerU the only ingestion path.

---

**Attribution:** opendatalab/MinerU, MinerU Open Source License, https://github.com/opendatalab/MinerU
