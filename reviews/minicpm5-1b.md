# MiniCPM5-1B (openbmb/MiniCPM5-1B)

**Repo:** https://huggingface.co/openbmb/MiniCPM5-1B  
**License:** Apache-2.0; permissive model weights and repository materials with attribution/license preservation  
**Reviewed:** 2026-05-31  
**Stack:** Transformers `LlamaForCausalLM`, BF16 safetensors, GGUF, MLX/4-bit, vLLM, SGLang, llama.cpp, Ollama, LM Studio  
**What it is:** A 1.08B-parameter dense text-generation model from OpenBMB aimed at on-device, edge, and local-agent use, with 131k context, hybrid Think/No-Think chat modes, and XML-style tool calling.

---

## Verdict

⚠️ **Interesting compact local-agent model, worth benchmarking before adoption.** The packaging is unusually practical: Apache-2.0 weights, standard Llama architecture, BF16/GGUF/MLX variants, deployment cookbooks, and tool-calling guidance. The catch is that the strongest quality claims are still model-card claims; treat it as a strong candidate for local evaluation, not as a proven replacement for larger local models.

---

## What It Is

MiniCPM5-1B is the first model in OpenBMB's MiniCPM5 series. It targets small local assistants, coding agents, tool-use workflows, and resource-constrained deployments where a 1B-class model is preferred over a larger local checkpoint.

The model card emphasizes three useful properties: 1.08B dense parameters, a 131,072-token context window, and a chat template that can switch between fast No-Think mode and deliberate Think mode with the same checkpoint. Hugging Face metadata reports 36,730 downloads, 647 likes, Apache-2.0 licensing, and a last modification date of 2026-05-26 at review time.

OpenBMB also publishes adjacent formats: a BF16 final checkpoint, SFT-only and base checkpoints, GGUF builds for llama.cpp/Ollama/LM Studio, and an MLX 4-bit build for Apple Silicon. That artifact spread matters more than the benchmark graphic: it makes the model easy to actually test across common local inference paths.

## Stack

| Layer | Tech |
|-------|------|
| Architecture | `LlamaForCausalLM`, 24 layers, hidden size 1536, 16 Q heads / 2 KV heads |
| Parameters | 1,080,632,832 total; 679,552,512 non-embedding |
| Context | 131,072 tokens via model config |
| Release formats | BF16 safetensors, GGUF F16/Q8/Q4, MLX 4-bit |
| Runtime targets | Transformers, vLLM, SGLang, llama.cpp, Ollama, LM Studio, MLX |
| Tool calling | XML-style function calls; SGLang `minicpm5` parser recommended |
| Training data | Ultra-FineWeb, Ultra-FineWeb-L3, UltraData-Math, UltraData-SFT-2605 |
| Languages | English and Chinese metadata |

## Key Features

### Standard Architecture

The model uses `LlamaForCausalLM`, which lowers adoption friction. There is no custom model-code fork required for the main BF16 checkpoint, and the card gives direct commands for vLLM, SGLang, and Transformers.

### Hybrid Think / No-Think Template

The chat template supports `enable_thinking=True` and `enable_thinking=False`. That is a useful interface for local agents: run quick low-latency turns by default, then switch to a more deliberate mode for planning, code, or tool-use tasks.

### Tool-Calling Orientation

MiniCPM5-1B emits XML-style function calls. The card recommends SGLang for tool calling because its `minicpm5` parser can convert that format to OpenAI-compatible tool calls. That makes it more agent-oriented than a generic tiny chat model, but tool-call reliability still needs local evaluation.

### Deployment Matrix

OpenBMB provides linked deployment and fine-tuning cookbooks plus Agent Skill files for multiple backends. This is a good release pattern: a small model is much more usable when users can choose BF16, GGUF, or MLX and get backend-specific instructions.

## Architecture

This is a model artifact rather than an application. The important architecture is in the release package:

- one standard Transformers checkpoint;
- sibling base, SFT, GGUF, and MLX variants;
- a chat template with thinking control and XML tool calls;
- deployment guides for common inference servers and desktop runtimes;
- fine-tuning guides for TRL/PEFT, LLaMA-Factory, ms-swift, Unsloth, and XTuner.

The most reusable idea is the packaging discipline: release the model in the formats people actually run, and ship the prompt/template/runtime details as part of the artifact rather than leaving them implicit.

## Comparison

| Aspect | MiniCPM5-1B | Qwen small thinking models | Larger local GGUF models |
|--------|-------------|----------------------------|--------------------------|
| Size | 1.08B dense | 0.6B-1B class | 7B-30B+ |
| Strength | On-device agent/tool workflow candidate | Strong baseline family | Better raw capability |
| Deployment | BF16, GGUF, MLX, mainstream runtimes | Broad ecosystem | More memory/latency cost |
| Evidence | Strong model-card claims; needs local eval | Varies by release | Often better community eval coverage |
| Best fit | Fast local assistant, edge tool caller, fallback model | Small-model baselines | Primary local reasoning/coding model |

## Self-Hosting Notes

For Apple Silicon or CPU-first testing, start with the GGUF or MLX release rather than the BF16 checkpoint. For server-style tool calling, SGLang is the most explicitly supported path because of its MiniCPM5 tool-call parser. For generic OpenAI-compatible serving, vLLM is documented.

Do not assume the 131k context is useful at full length without workload-specific testing. Long-context metadata is not the same as retrieval quality, instruction stability, or attention to late-context details. Also run your own evals for tool-call formatting, refusal/safety behavior, hallucination, and latency on target hardware before putting it into an agent loop.

---

**Attribution:** openbmb/MiniCPM5-1B, Apache-2.0, https://huggingface.co/openbmb/MiniCPM5-1B
