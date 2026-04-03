# Blaizzy/mlx-vlm — Review

**Repo:** https://github.com/Blaizzy/mlx-vlm  
**Author:** Blaizzy  
**License:** MIT  
**Stars:** 2,817  
**Language:** Python (MLX)  
**Rating:** 🔥🔥🔥🔥🔥 (Essential for Apple Silicon Vision/Multi-modal)  
**Clone:** ~/src/mlx-vlm  
**Reviewed:** 2026-04-02  
**Topics:** MLX, Apple Silicon, Vision Language Models (VLM), Multi-modal, Audio/Video support, TurboQuant

---

## What it is

The definitive package for running and fine-tuning Vision Language Models (VLMs) and "Omni" models (Vision + Audio + Video) natively on Apple Silicon using the MLX framework. It provides a unified interface (CLI, Python API, and OpenAI-compatible FastAPI server) for a massive range of multi-modal models.

It's essentially the `llama.cpp` equivalent for the MLX multi-modal ecosystem, but with first-class support for audio/video and advanced quantization.

---

## Core Capabilities

- **Massive Model Support:** Qwen2/2.5-VL, LLaVA, Florence-2, Molmo, Idefics3, PaliGemma, Moondream3, and the new **Gemma 3/4** family.
- **Audio & Video:** Support for "Omni" models like `gemma-3n-E2B` that can "see" and "hear" simultaneously.
- **TurboQuant KV Cache:** Compresses KV cache from 16-bit to 2-4 bits using random rotation + codebook quantization ([arXiv:2504.19874](https://arxiv.org/abs/2504.19874)). Reduces KV memory by up to **76%** while staying faster than FP16 SDPA at high contexts.
- **Thinking Budgets:** First-class support for "thinking" models (Qwen3.5, etc.) with explicit token budgets for the `<think>` block.
- **OCR Specialization:** Detailed documentation and prompt formats for OCR-specific models like DeepSeek-OCR and GLM-OCR.

---

## Strategic Features for the Lab

**1. The "Omni" Runtime:** This is the tool we use for models that need to process complex research inputs (e.g., a video of a patient's gait + a transcript of their voice) in a single turn.

**2. TurboQuant for Deep Context:** If we're processing a 100+ page medical paper corpus using a VLM, TurboQuant is what keeps the KV cache from OOM-ing our 64GB Unified Memory.

**3. Thinking Model Steering:** The `--thinking-budget` flag is a crucial control mechanism for agentic loops. It allows us to cap the "reasoning" cost without killing the generation entirely (it forces a transition to the answer).

---

## Key Patterns to Extract

**1. The "Think-Budget" Enforcement:** Forcing a model to emit a closing tag (`\n</think>`) when it hits a token limit is a clever way to handle infinite reasoning loops in agents.

**2. Codebook KV Compression:** The TurboQuant pattern (3-bit Keys / 4-bit Values) is a state-of-the-art memory/quality tradeoff for long-context research agents.

**3. Multi-modal Chat Templates:** The `apply_chat_template` implementation in `mlx_vlm/prompt_utils.py` handles the mess of interleaving `<|image|>`, `<|audio|>`, and `<|video|>` tags—reusable for our own multi-modal wrappers.

---

## Verdict

Mandatory infrastructure for the Apple Silicon lab. It solves the fragmentation of multi-modal prompt formats and provides the most memory-efficient long-context vision runtime available today.

**Action:** Install `mlx-vlm` and use it as the primary backend for any local vision/audio research tasks.

Source: Blaizzy/mlx-vlm. Summary by Rue (RueClaw/public-data).
