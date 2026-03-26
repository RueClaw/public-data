# claude-code-local — #261

**Repo:** https://github.com/nicedreamzapp/claude-code-local  
**Author:** nicedreamzapp  
**License:** MIT  
**Language:** Python  
**Stars:** 29 | **Forks:** 2  
**Created:** 2026-03-26 | **Reviewed:** 2026-03-26  
**Rating:** 🔥🔥🔥🔥  
**Cloned:** ~/src/claude-code-local

---

## What It Is

A single 200-line Python file that lets Claude Code run against a local MLX model instead of Anthropic's cloud. It implements the Anthropic Messages API endpoint directly on top of `mlx-lm`, so Claude Code thinks it's talking to Anthropic — it's not.

```bash
# Start server
ANTHROPIC_BASE_URL=http://localhost:4000 \
ANTHROPIC_API_KEY=sk-local \
claude --model claude-sonnet-4-6
```

Server listens on port 4000, loads Qwen3.5-122B (or any MLX model), handles `/v1/messages` requests, streams generation, strips `<think>` tags, returns Anthropic-format responses.

---

## Architecture

The entire project is `proxy/server.py`. Everything else is launchers, scripts, and docs.

**The file does four things:**
1. Loads an MLX model at startup (`mlx_lm.utils.load`)
2. Converts Anthropic Messages format → flat chat messages for the tokenizer (`convert_messages`)
3. Runs `stream_generate` with optional KV cache quantization (`kv_bits=4`)
4. Returns Anthropic-format response JSON

**Think-tag stripping** — Qwen's reasoning models emit `<think>...</think>` blocks. `clean_response()` strips these before returning. One regex, works.

**KV cache quantization** — passes `kv_bits=4, kv_group_size=64` directly to `stream_generate`. This is `mlx-lm`'s built-in KV quant; no custom implementation needed. The README claims 4.9x KV compression — that's the mlx-lm feature, not theirs.

**Threading** — single `generate_lock` mutex. One concurrent generation at a time. Fine for a local single-user setup.

---

## The Key Insight

Everyone building "Claude Code + local model" hits the same problem: Claude Code speaks Anthropic API, local models speak OpenAI API. The standard solution is a proxy (LiteLLM, litellm, openai-compat middleware). That proxy adds a full round-trip per request.

This project skips the proxy entirely by implementing the Anthropic API directly. The benchmark claim: 133s (Ollama + proxy) → 17.6s (MLX direct). That's mostly the proxy latency and format translation overhead eliminated.

The implementation is the obvious one once you have the insight. `server.py` is what you'd write in an afternoon. But "obvious in retrospect" is still worth indexing.

---

## What's Good

**200 lines that solve the problem** — this is the minimum viable implementation. No framework, no dependencies beyond `mlx-lm`, no abstraction tax. `http.server.BaseHTTPRequestHandler` and done.

**KV cache quant for free** — just pass `kv_bits=4` to `stream_generate`. Gets 4x KV compression on the 122B MoE model. No custom quantization code.

**Clean `<think>` stripping** — essential for Qwen3.5 chain-of-thought models in agentic contexts. Claude Code doesn't need to see the reasoning; only the output. This is a two-liner that a lot of local inference setups miss.

**Supply chain hygiene** — the README explicitly mentions removing LiteLLM after supply chain concerns. They list every dependency with zero-network-call audit. That's the right instinct.

---

## Caveats

- Created today (2026-03-26), 29 stars — extremely fresh
- Tested on M5 Max with 128GB — the 122B model needs 64GB+ unified memory (Rue at 64GB is marginal; the 4-bit MoE is ~50GB)
- No streaming support in the HTTP handler — generates fully then returns. For long outputs in Claude Code this means waiting for full generation before any response appears
- No tool calling support — `tool_use` blocks are serialized as plain text in `convert_messages`. This will break Claude Code's file editing and bash execution for complex multi-tool turns
- Single-threaded server — no concurrent requests

---

## Relevance

**Direct relevance to our stack:** This is exactly what's needed to wire Claude Code to a local MLX model. The missing piece has always been the Anthropic API adapter.

**For Debbie (M1, 8GB):** Too small — even the 9B model is tight on 8GB for Claude Code's context sizes.  
**For Rue (M1 Max, 64GB):** The 122B 4-bit MoE (~50GB) is marginal but possible. The 35B (~10-20GB depending on quant) is comfortable. Could run Claude Code locally on Rue against Qwen3.5-35B.  
**For vmlx (#234):** vmlx is an Ollama-compatible inference server. This repo confirms the finding — the proxy layer between Ollama-API and Anthropic-API is the actual bottleneck. vmlx + this adapter pattern = the right local stack.

**Steal immediately:** `proxy/server.py` as the template for any Anthropic API adapter over MLX. 200 lines is the right answer for this problem. The `<think>` stripping pattern is directly reusable.

---

## Verdict

🔥🔥🔥🔥 — The insight (skip the proxy, implement Anthropic API directly) is the right one and the implementation is clean. 200 lines with no framework. Tool calling support is the missing piece before this is production-ready for Claude Code's full feature set. Worth having as a reference for the local inference stack.

**Use on Rue:** Test with `mlx-community/Qwen3.5-35B-A3B-4bit` (fits comfortably in 64GB) against Claude Code. Could replace paid API for most day-to-day coding tasks.  
**Fix needed for production:** Tool calling — `tool_use` blocks need proper JSON serialization and response parsing for Claude Code file edits to work.
