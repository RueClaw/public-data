# Lalamo (trymirai/lalamo)

**Repo:** https://github.com/trymirai/lalamo
**License:** MIT. Permissive reuse with attribution; converted model artifacts still inherit their source model licenses.
**Reviewed:** 2026-06-09
**Stack:** Python 3.12+, JAX, Equinox, Optax, Orbax Checkpoint, Hugging Face Hub, tokenizers, safetensors, Typer, pytest, ruff, pyrefly
**What it is:** Lalamo is Mirai's model adaptation and conversion toolchain for preparing Hugging Face and related model checkpoints for on-device inference in the Uzu engine.

---

## Verdict

⚠️ **Interesting companion to Uzu, not a standalone deploy target.** Lalamo is the toolchain side of Mirai's local inference stack: model specs, checkpoint import, quantization/compression, sharding, coherence tests, and export to Uzu-compatible artifacts. It is useful if you want to study or operate the Uzu ecosystem, but most teams would consume its output through Uzu rather than integrate Lalamo directly.

---

## What It Is

Lalamo converts source model repositories into artifacts that Uzu can load. The quick-start surface is intentionally small: list supported models, then run `lalamo convert MODEL_REPO`, with optional model pull and TTS playback flows.

Under the hood, it is a JAX model-import and export framework. It defines model specs for many model families, maps foreign Hugging Face configs into Lalamo/Uzu configs, loads tokenizer/config/weights, handles quantized layouts such as MLX/AWQ-style formats, supports language/classifier/TTS models, and writes model artifacts with `model.safetensors`, `config.json`, and `tokenizer.json`.

The repo is closely coupled to Uzu. Uzu's README points developers at Lalamo for converting models, and Lalamo's README describes itself as tooling for adapting LLMs to Uzu on-device inference.

## Stack

| Layer | Tech |
|-------|------|
| Runtime | Python 3.12+, JAX |
| Model modules | Equinox, jaxtyping, JAX NumPy |
| Optimization | Optax, custom compression/preconditioning code |
| Checkpointing | Orbax Checkpoint, safetensors |
| Model sources | Hugging Face Hub, tokenizers |
| CLI | Typer, Rich, Click |
| Optional TTS/audio | soundfile, PyAudio, fish-speech extras |
| Optional server | FastAPI, Uvicorn |
| Quality gates | pytest, ruff, pyrefly, tox, CI model/coherence tests |

## Key Features

### Declarative model specs

Supported models are encoded as `ModelSpec` objects with vendor, family, name, size, origin, foreign config type, tokenizer/config mappings, chat template overrides, generation config, output parser regex, and role naming. This keeps model support explicit instead of scattering per-model special cases across the converter.

### Conversion pipeline for Uzu artifacts

The main conversion flow resolves source files, loads foreign config/tokenizer/weights, instantiates Lalamo model structures, imports weights into those structures, then saves a runtime directory containing `model.safetensors`, `config.json`, and `tokenizer.json`.

That is the useful boundary: source-model formats can churn, while the runtime consumes a stable artifact format.

### Quantization and compression support

The code includes int quantization, MLX quantized layouts, hybrid compression, low-rank support, Lloyd-Max codebook data, Hadamard/incoherence processing, packing utilities, and distortion estimation data. Lalamo is not just downloading checkpoints; it is doing toolchain work to make them fit an on-device runtime.

### Broad model-family coverage

The registry includes Llama, Qwen, Gemma, GPT-OSS, DeepSeek distills, LiquidAI LFM, Mistral/Codestral, Reka, Polaris, EssentialAI, Nanbeige, Bonsai, Llamba, classifiers, and TTS models such as Fish Audio and NanoCodec-related paths. The test tier file shows canonical/core/standard/extra model groups.

### Heavyweight CI for model conversion quality

CI includes unit tests, ruff, pyrefly, lock checks, model generation/tracer tests, audio model tests, CLI tests, prerelease coherence tests, pull-smoke backward compatibility tests, release publishing, and nightly user-install checks across CPU/GPU runners. The latest observed release is `v0.13.1`, published 2026-06-07.

## Architecture

Lalamo is organized around a few clear layers:

- `lalamo/model_import/model_spec.py` defines model specs and config maps.
- `lalamo/model_import/model_specs/*` enumerates supported model families.
- `lalamo/model_import/common.py` resolves source files, tokenizers, chat templates, configs, weights, and builds Lalamo model objects.
- `lalamo/model.py`, `exportable.py`, and `safetensors.py` define the saved runtime artifact.
- `lalamo/compressed/*` handles quantization/compression formats.
- `lalamo/modules/*` implements model blocks, attention, MLPs, token mixers, audio, classifiers, and decoders.
- `lalamo/main.py` and `commands.py` expose CLI conversion, pull, chat, classify, and audio flows.

The design is closer to a compiler toolchain than an app. Model specs are the frontend, import/load/quantization is the middle end, and Uzu-compatible artifact export is the backend.

## Comparison

| Aspect | Lalamo | Uzu | llama.cpp conversion scripts | MLX-LM conversion |
|--------|--------|-----|------------------------------|------------------|
| Role | Convert/adapt models for Uzu | Run models in apps and server mode | Convert models to GGUF/runtime formats | Convert/use models in MLX ecosystem |
| Primary language | Python/JAX | Rust/Metal | Python/C++ ecosystem | Python/MLX |
| Best fit | Toolchain for Uzu artifacts | Embedded local inference runtime | Broad local inference compatibility | Apple ML experimentation |
| Model support style | Declarative `ModelSpec` registry | Remote/local runtime model registry | Script and format-driven | MLX model conventions |
| Main caveat | Heavy dependencies and source-model license complexity | Runtime/network defaults need audit | Many separate scripts and runtime assumptions | Mostly Apple/Python-centered |

## Self-Hosting Notes

Basic conversion:

```bash
uv run lalamo list-models
uv run lalamo convert Qwen/Qwen3-0.6B
```

Expect heavyweight dependencies. JAX, optional CUDA extras, large Hugging Face downloads, and model-family-specific test paths make this more of a build/conversion workstation tool than a lightweight service.

Security and operations notes:

- Treat source model repos and tokenizer/config files as untrusted inputs.
- Track source model licenses separately from Lalamo's MIT code license.
- The remote preconverted-model registry fetches from `https://sdk.trymirai.com/api/v1/fetch/models`.
- The pull path validates registry filenames against path traversal before writing files, which is a good sign.
- Third-party Lalamo plugins are loaded through Python entry points; only enable plugins from trusted packages.

Local validation performed for this review: `python3 -m compileall -q lalamo tests` passed on the cloned source.

---

**Attribution:** trymirai/lalamo, MIT License.
