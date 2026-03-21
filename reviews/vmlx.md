# vmlx (jjang-ai/vmlx)

**Rating:** 🔥🔥🔥🔥🔥  
**License:** Apache 2.0  
**Source:** https://github.com/jjang-ai/vmlx  
**Reviewed:** 2026-03-21

## What It Is

Full Apple Silicon inference engine — the vLLM of MLX. Local AI server for M-series Macs with OpenAI + Anthropic compatible API. Zero cloud, zero API keys.

```bash
pip install vmlx
vmlx serve mlx-community/Qwen3-8B-4bit
# → http://0.0.0.0:8000 with OpenAI + Anthropic API
```

## Architecture

```
+--------------------------------------------+
|          Desktop App (Electron)             |
|   Chat | Server | Image | Tools | API      |
+--------------------------------------------+
|          Session Manager (TypeScript)       |
|   Process spawn | Health monitor | Tray     |
+--------------------------------------------+
|         vMLX Engine (Python / FastAPI)       |
|  +--------+  +---------+  +-----------+    |
|  |Simple  |  | Batched |  | ImageGen  |    |
|  |Engine  |  | Engine  |  | Engine    |    |
|  +---+----+  +----+----+  +-----+-----+    |
|      |            |              |          |
|  +---+------------+--+    +-----+-----+    |
|  | mlx-lm / mlx-vlm  |    |  mflux    |    |
|  +--------+-----------+    +-----------+    |
|           |                                 |
|  +--------+----------------------------+    |
|  |       MLX Metal GPU Backend          |    |
|  | quantized_matmul | KV cache | SDPA   |    |
|  +--------------------------------------+    |
+--------------------------------------------+
|  L1: Prefix Cache (Memory-Aware / Paged)    |
|  L2: Disk Cache (Persistent / Block Store)  |
|  KV Quant: q4/q8 at storage boundary       |
+--------------------------------------------+
```

## 5-Layer Cache Stack

```
Request → L1 Memory-Aware Prefix Cache (or Paged KV Cache)
               ↓ miss
          L2 Disk Cache (persistent across restarts, SSD)
               ↓ miss
          MLX Inference → float16 KV states
               ↓
          KV Quantization (q4/q8) → store back into L1 + L2
```

- **Prefix Cache:** Reuse KV states for repeated prompts — same system prompt across sessions = near-instant first token
- **Paged Cache:** Block-based KV cache with content-addressable deduplication
- **KV Quantization:** q4/q8 at storage boundary = 2-4x memory savings at serving time
- **Disk Cache:** Persists to SSD across server restarts — research workflows with repeated prompts benefit immediately
- **Block Disk Store:** Per-block persistent cache paired with paged cache

## Serving Features

| Feature | Description |
|---------|-------------|
| Continuous batching | vLLM-style scheduler — not serial like Ollama default |
| Speculative decoding | Small draft model for 20-90% throughput speedup |
| JIT compilation | `mx.compile` Metal kernel fusion (experimental) |
| Hybrid SSM | Mamba/GatedDeltaNet layers handled alongside attention |

## Model Support

| Type | Models |
|------|--------|
| Text LLMs | Qwen 2/2.5/3/3.5, Llama 3/4, Mistral/Mixtral, Gemma 3, Phi-4, DeepSeek, GLM-4, MiniMax, any mlx-lm model |
| Vision LLMs | Qwen-VL, Qwen3.5-VL, Pixtral, InternVL, LLaVA, Gemma 3n |
| MoE | Qwen 3.5 MoE, Mixtral, DeepSeek V2/V3, MiniMax M2.5, Llama 4 |
| Hybrid SSM | Nemotron-H, Jamba, GatedDeltaNet |
| Image Gen | Flux Schnell/Dev, Z-Image Turbo (via mflux) |
| Image Edit | Qwen Image Edit |
| Embeddings | Any mlx-lm compatible embedding model |
| Reranking | Cross-encoder models |
| TTS | Kokoro (via mlx-audio) |
| STT | Whisper (via mlx-audio) |

## Tool Calling Parsers (Per-Family, Not Regex)

`vmlx_engine/tool_parsers/` — dedicated parser per model family:  
`qwen` · `llama` · `mistral` · `hermes` · `deepseek` · `glm47` · `minimax` · `nemotron` · `granite` · `functionary` · `xlam` · `kimi` · `step3p5`

Auto-detected via `auto_tool_parser.py`.

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /v1/chat/completions` | OpenAI Chat API (streaming + non-streaming) |
| `POST /v1/messages` | Anthropic Messages API |
| `POST /v1/responses` | OpenAI Responses API |
| `POST /v1/images/generations` | Image generation |
| `POST /v1/images/edits` | Image editing |
| `POST /v1/embeddings` | Text embeddings |
| `POST /v1/rerank` | Document reranking |
| `POST /v1/audio/transcriptions` | Whisper STT |
| `POST /v1/audio/speech` | Kokoro TTS |
| `GET /v1/cache/stats` | Cache statistics |

## JANG Adaptive Quantization (Research Contribution)

Mixed-precision: assigns different bit widths by layer type instead of uniform quantization.

| Profile | Attention | Embeddings | MLP | Avg Bits |
|---------|-----------|------------|-----|----------|
| JANG_2M | 8-bit | 4-bit | 2-bit | ~2.5 |
| JANG_2L | 8-bit | 6-bit | 2-bit | ~2.7 |
| JANG_3M | 8-bit | 3-bit | 3-bit | ~3.2 (recommended) |
| JANG_4M | 8-bit | 4-bit | 4-bit | ~4.2 |
| JANG_6M | 8-bit | 6-bit | 6-bit | ~6.2 |

**MiniMax M2.5 benchmark:** JANG_2L (2-bit, 89GB) = 74% MMLU vs MLX 4-bit (120GB) = 26.5%. Not a rounding error — the insight is that attention layers need precision; MLP layers tolerate aggressive quantization far better than uniform schemes assume.

```bash
pip install vmlx[jang]
vmlx convert my-model --jang-profile JANG_3M
# or with activation-aware calibration:
vmlx convert my-model --jang-profile JANG_2L --calibration-method activations
```

Pre-quantized JANG models: https://huggingface.co/JANGQ-AI

## vs Ollama

| Feature | Ollama | vMLX |
|---------|--------|------|
| Serving | Serial (default) | Continuous batching |
| Prefix cache | No | Yes (L1 + L2 disk) |
| KV quantization | No | q4/q8 |
| Disk cache persistence | No | Yes |
| Speculative decoding | No | Yes |
| Image gen | No | Flux/mflux |
| JANG quantization | No | Yes |
| API compat | OpenAI only | OpenAI + Anthropic |
| Install | Single binary | pip install |

## Usage on M1 Max (64GB)

```bash
uv tool install vmlx

# Serve deepseek-r1:32b with continuous batching and cache
vmlx serve mlx-community/DeepSeek-R1-0528-8bit \
  --continuous-batching \
  --enable-prefix-cache \
  --kv-cache-quantization q8 \
  --enable-disk-cache \
  --reasoning-parser auto

# Or convert qwen3-coder with JANG quantization
vmlx convert /path/to/qwen3-coder-next --jang-profile JANG_3M
vmlx serve ./qwen3-coder-next-JANG_3M --continuous-batching --use-paged-cache
```

Point OpenClaw's Ollama config at port 8000 instead of 11434 — drop-in replacement.

## Desktop App (MLX Studio)

Electron app: Chat tab (history, thinking mode, tool calling, agentic coding), Server tab (model session manager), Image tab (Flux gen + Qwen edit), Tools tab (GGUF→MLX converter, diagnostics), API tab (live endpoint reference). Menu bar shows GPU memory per model.

Download DMG: https://github.com/jjang-ai/mlxstudio/releases/latest
