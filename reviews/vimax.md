# ViMax

**Source:** https://github.com/HKUDS/ViMax  
**Reviewed:** 2026-05-23  
**License:** MIT  
**Verdict:** 📚 Study

ViMax is a Python orchestration repo for agentic video generation. It does not ship a video model; instead, it turns an idea, script, or novel into staged production artifacts and calls external LLM, image, and video providers to generate the final media.

## What It Is

The repository frames video generation as a production pipeline with specialist agents for screenwriting, character extraction, character portraits, scene/event extraction, storyboarding, camera/shot planning, reference image selection, provider-backed image/video generation, and MoviePy composition.

The useful part is the workflow shape. ViMax decomposes a fuzzy creative request into cached intermediates: story text, script JSON, character registry, portrait files, scene/event structures, frame plans, generated images, generated clips, and a final composed video.

## Architecture

- `main_idea2video.py` and `main_script2video.py` are entrypoints.
- `pipelines/` wires Idea2Video and Script2Video flows.
- `agents/` contains the specialist LLM roles.
- `interfaces/` defines media/story objects.
- `tools/` wraps image/video/render providers.
- `utils/` handles provider presets, retries, rate limits, image/video helpers, and timing.
- `configs/` contains provider examples for Google/OpenRouter/Veo and MiniMax.

Provider support is intentionally pluggable. The render backend instantiates configured image and video generator classes, while chat model config can resolve provider aliases such as MiniMax into OpenAI-compatible LangChain initialization arguments.

## Good Patterns

- Pipeline stages are durable: expensive outputs are written under `working_dir` and reused when present.
- Creative work is typed into production artifacts rather than left as loose prose.
- Chat, image, and video provider configuration are separated.
- Per-service rate-limit settings and retry hooks exist.
- MiniMax tests verify provider resolution and config loading without live API calls.

## Caveats

This is not a deploy candidate as-is.

- End-to-end generation requires external paid APIs and was not run.
- The repo does not include its own video model or offline inference path.
- Tests are small and mostly cover provider/config plumbing, not the media pipeline.
- `uv sync` initially picked Python 3.14 and failed because `tiktoken`'s PyO3 dependency supports only through Python 3.13; pinning Python 3.12 fixed install.
- `pyproject.toml` has rough metadata, `readme = "README.md"` while the file is `readme.md`, and a nonstandard-looking `[[index]]` block.
- `pip-audit` reported 45 known vulnerabilities across 13 packages in the resolved environment.
- Generated-media policy controls are thin for likeness, copyright/style, adult content, or downstream disclosure.
- The default example prompt in `main_idea2video.py` is a poor first impression for a general-purpose demo.

## Verification

Checked at commit `2d953d44f52b891a2d2e878aa75a8ef92ef625ed`.

- `python3 -m compileall -q agents interfaces pipelines tools utils tests main_idea2video.py main_script2video.py` passed.
- `uv sync --python /opt/homebrew/bin/python3.12 --all-extras --dev` passed.
- `.venv/bin/python -m pytest -q` passed after installing `pytest`: 38 passed.
- `pip-audit` reported 45 known vulnerabilities in 13 packages.

## Reuse

The reusable idea is the staged production system: convert loose input into typed production documents, persist expensive intermediates, isolate provider adapters behind config, enforce rate limits and retries per provider, and make intermediate artifacts inspectable before final composition.

See also: [agentic-video-production-pipeline.md](../patterns/agentic-video-production-pipeline.md).

