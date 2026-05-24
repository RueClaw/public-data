# ComfyUI-LTXVideo (Lightricks/ComfyUI-LTXVideo)

**Repo:** https://github.com/Lightricks/ComfyUI-LTXVideo
**License:** LTX-2 Community License - source/model use is subject to custom use restrictions and commercial-license triggers
**Reviewed:** 2026-05-24
**Stack:** Python, ComfyUI custom nodes, PyTorch, diffusers, transformers, Hugging Face Hub, safetensors, CUDA/ComfyUI video workflows
**What it is:** Official Lightricks ComfyUI extension nodes and example workflows for LTX-2 video generation, including LTX-2.3 text/image/video workflows, IC-LoRA controls, HDR, lipdub, motion tracking, low-VRAM loaders, Q8 patching, and prompt/text-encoder helpers.

---

## Verdict

⚠️ **Interesting and useful for LTX-2 ComfyUI operators, but not a general-purpose code harvest.** This is the official workflow/node companion for LTX-2 in ComfyUI, so it is valuable if you are already running LTX-2 locally. The caveats are substantial: the license is a custom LTX-2 Community License rather than permissive OSS, workflows require very large model assets and 32GB+ VRAM, there is no visible test/CI suite, and one API text-encoding node deserializes a remote API response with Python pickle.

---

## What It Is

ComfyUI-LTXVideo is a custom-node pack for running LTX-2 video-generation workflows in ComfyUI. LTX-2 itself is built into ComfyUI core, while this repository provides extra nodes, workflow graphs, web UI helpers, and model-specific utilities for the newer and more advanced LTX-2 flows.

The repository is workflow-heavy. It ships example workflows for LTX-2.3 single-stage text/image-to-video, two-stage distilled pipelines with spatial/temporal upsampling, IC-LoRA union control, motion tracking, HDR output, and lipdub. Older LTX-2.0 workflows remain present for text-to-video, image-to-video, video detailer, and IC-LoRA flows.

This is not a standalone video-generation app. It assumes ComfyUI, CUDA hardware, a large set of LTX/Gemma/LoRA/upscaler model files, and a working ComfyUI custom-node environment.

## Stack

| Layer | Tech |
|-------|------|
| Host app | ComfyUI custom nodes |
| Runtime | Python, PyTorch, ComfyUI APIs |
| Model ecosystem | LTX-2 / LTX-2.3, Gemma 3 text encoder, IC-LoRA models |
| Dependencies | diffusers, transformers[timm], huggingface_hub, kornia, einops, ninja |
| Assets | safetensors checkpoints, latent upscalers, LoRAs, Gemma text encoder files |
| UI extensions | JavaScript widgets for guider parameters and sparse-track editing |
| Hardware posture | CUDA GPU, README recommends 32GB+ VRAM and 100GB+ disk |

## Key Features

### LTX-2.3 Workflow Pack

The strongest value is the curated workflow set. It covers single-stage T2V/I2V, two-stage upsampling, IC-LoRA union control, motion tracking, HDR, and lipdub. These workflows encode a lot of practical graph knowledge that would be tedious to reconstruct manually.

### IC-LoRA Control Nodes

The repository includes nodes for adding video IC-LoRA guides, advanced guide strength, loading LoRA-only model patches, reference-audio tokens, and sparse motion tracks. This gives ComfyUI users a path into control-conditioned LTX-2 generation beyond simple prompting.

### Low-VRAM Sequencing

The low-VRAM loader nodes add dependency inputs to force model-loading order. That is a pragmatic ComfyUI graph trick: by serializing heavy loader steps, workflows can lower peak VRAM pressure even if the final generation still needs a large GPU.

### HDR and Lipdub Workflows

HDR IC-LoRA support includes LogC3 decode/postprocess and optional EXR export. Lipdub support combines video/audio latents and reference audio tokens to regenerate speech/lip motion while preserving speaker context. These are advanced model-specific workflows, not generic ComfyUI utilities.

### Prompt and Text-Encoding Helpers

The repo includes local Gemma encoder utilities, prompt enhancer nodes that can download Hugging Face models, and an API text-encoding node for LTX Video. These are useful but need careful trust boundaries because they can involve remote model code, external API calls, or both.

## Architecture

Node registration is split between explicit static mappings in __init__.py and a decorator-based registry in nodes_registry.py. The static mapping keeps ComfyUI-Manager aware of node names, while decorators let newer nodes self-register with display-name formatting and experimental/deprecated labels.

Most modules are single-purpose ComfyUI nodes or helpers:

- low_vram_loaders.py wraps heavy loaders with dependency inputs for sequential loading.
- iclora.py adds IC-LoRA guide, LoRA loading, and audio-reference-token nodes.
- hdr.py handles HDR decode/postprocess and optional EXR export.
- sparse_tracks.py adds a sparse-track editor and GPU track renderer.
- easy_samplers.py, looping_sampler.py, and tiled_sampler.py provide sampler variants.
- gemma_encoder.py, gemma_api_conditioning.py, and prompt-enhancer modules handle text conditioning and prompt expansion.
- web/js/ extends the ComfyUI frontend for advanced controls.

The design is tightly coupled to ComfyUI internals and LTX-2 model implementation details. That is appropriate for a model-specific node pack, but it means reuse outside ComfyUI would be expensive.

## Comparison

| Aspect | ComfyUI-LTXVideo | Generic ComfyUI node pack | Standalone video app |
|--------|------------------|---------------------------|----------------------|
| Target | LTX-2/LTX-2.3 power users | Mixed model workflows | End-user video generation |
| UX | Workflow JSON and custom nodes | Custom nodes | App UI |
| Model coupling | Very high | Varies | Hidden behind app |
| Deployment weight | Heavy: ComfyUI, CUDA, model assets | Varies | Usually packaged/cloud |
| Reuse value | Workflow patterns and node ideas | Node implementations | Product workflow |

This is best treated as official LTX-2 ComfyUI enablement rather than a reusable library.

## Self-Hosting Notes

The README recommends installing through ComfyUI Manager by searching for "LTXVideo." Manual use requires placing the node pack under ComfyUI/custom_nodes/ComfyUI-LTXVideo/ and downloading required checkpoints into ComfyUI model folders.

Operational requirements are high: the README calls for a CUDA GPU with 32GB+ VRAM and 100GB+ disk. LTX-2.3 workflows require checkpoints, spatial/temporal upscalers, distilled LoRA files, Gemma text-encoder files, and optional IC-LoRA/camera-control LoRAs.

Security and trust notes:

- GemmaAPITextEncode sends prompt text and model metadata to https://api.ltx.video.
- That node deserializes the response with pickle.load, so it should be treated as a trusted first-party API path only.
- Prompt enhancer loading uses Hugging Face downloads and trust_remote_code=True for the image captioner path.
- No obvious live secrets were found in a lightweight keyword scan; workflow api_key fields appear to be empty schema/widget fields.

Verification performed:

- Cloned with Git LFS filters disabled because git-lfs is not installed locally; media/model pointer files were inspected without downloading LFS blobs.
- python3 -m compileall -q . passed.
- No test files or GitHub Actions workflows were found in the shallow checkout.
- Full ComfyUI runtime validation was not run because it requires ComfyUI, large model downloads, CUDA hardware, and optional Git LFS assets.

---

**Attribution:** Lightricks/ComfyUI-LTXVideo, LTX-2 Community License
