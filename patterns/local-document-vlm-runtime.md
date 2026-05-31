# Local Document VLM Runtime

**Source:** datalab-to/surya  
**Repo:** https://github.com/datalab-to/surya  
**License:** Apache-2.0 code; model weights under modified AI Pubs OpenRAIL-M  
**Reviewed:** 2026-05-31

## Pattern

Run document OCR, layout, reading order, and table recognition as task-specific predictors over one shared local multimodal inference server. Keep the model server behind an OpenAI-compatible interface, and make lifecycle management explicit: probe, lock, spawn, validate, reuse, and clean up.

## Shape

```text
document input
  -> image/PDF loader
  -> task predictor
       -> prompt/schema selection
       -> shared inference manager
            -> attach to existing OpenAI-compatible server
            -> or spawn vLLM Docker on NVIDIA GPU
            -> or spawn llama.cpp GGUF server on CPU/Apple Silicon
       -> parser/schema normalization
  -> JSON/HTML/geometry output
```

## Why It Works

Document intelligence needs multiple output modes, but it does not necessarily need multiple heavyweight model servers. A shared runtime can amortize model startup and cache costs while predictors preserve task boundaries.

The useful implementation details are:

- backend selection from hardware and explicit env overrides;
- `/health` probing before spawning;
- file locks to prevent concurrent server starts;
- sentinel files so later CLI invocations can reuse a live server;
- model-id validation before attaching to an existing endpoint;
- keep-alive mode for repeated batch commands;
- task-specific prompts and output schemas;
- structured bboxes, polygons, confidence, reading-order, and HTML outputs.

## Implementation Notes

- Use localhost by default for spawned inference servers.
- Allow attaching to a user-managed server with an explicit endpoint variable.
- Separate lightweight preprocessing models from the heavy VLM path when that improves speed.
- Include per-task token budgets and retry handling for malformed or repetitive generations.
- Make table/layout/OCR schemas public and stable enough for downstream callers.
- Keep raw model output available for debugging, but return normalized outputs by default.

## Caveats

The runtime manager is not a security sandbox. Docker GPU containers, mounted model caches, downloaded weights, and local web preview tools still need normal host hardening. Also keep code and model license boundaries explicit; a permissive package license does not make restricted weights unrestricted.

---

**Attribution:** Pattern extracted from datalab-to/surya, Apache-2.0 code and modified OpenRAIL-M model license.
