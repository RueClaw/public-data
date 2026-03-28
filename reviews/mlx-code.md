# mlx-code (JosefAlbers/mlx-code)

*Review #276 | Source: https://github.com/JosefAlbers/mlx-code | License: Apache-2.0 | Author: JosefAlbers | Reviewed: 2026-03-27 | Stars: 9*

## Rating: 🔥🔥🔥🔥

---

## What It Is

A 373-line Python shim that turns Claude Code into a fully local, zero-API-cost coding agent on Apple Silicon. It runs a local MLX model in a thread, intercepts the Anthropic API endpoint via environment variable override, and forwards all Claude Code traffic to the local model instead.

```bash
pip install mlx-code
mlx-code
# Claude Code is now running on Qwen3.5-4B locally, $0/month
```

---

## The Core Mechanic

Claude Code (and Claude Code-style agents) respect `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN` environment variables. mlx-code exploits this:

1. Loads an MLX model into memory
2. Starts a local HTTP server on port 8000 implementing the Anthropic Messages API (`/v1/messages`)
3. Sets `ANTHROPIC_BASE_URL=http://localhost:8000`, `ANTHROPIC_AUTH_TOKEN=local`
4. Launches `claude` (the Claude Code CLI) as a subprocess pointing at the local server

Claude Code thinks it's talking to Anthropic. It's talking to a local Qwen3.5 model. Zero API calls, zero cost.

This same trick works for any tool that uses the Anthropic SDK and respects env vars — which is most of them.

---

## What's Actually in the 373 Lines

**`encode()`** — Converts Anthropic Messages API format to the local model's chat template. Handles:
- Tool call history reconstruction (tool_use → tool_result threading)
- System prompt injection with `{env}` variable for working directory context
- Stripping noise via regex patterns (`--skips` flag) — default strips suggestion-mode blocks and system-reminders to save context tokens
- Tool filtering via `--names` flag (default: Read, Edit, Write, Grep, Glob, Bash, Agent, Skill)

**`decode()`** — Converts model output back to Anthropic API format. Handles:
- `<think>...</think>` blocks → `thinking` content blocks (works with reasoning models)
- `<tool_call>...</tool_call>` parsing with `<function=name>` + `<parameter=key>` format
- Builds proper `tool_use` blocks with UUID IDs

**`dmca()`** — Masks the system prompt content in stream logs by replacing characters with geometric symbols (▲△▶▷▼▽◀◁◆◇). Logs everything else for debugging. Cute.

**Prompt caching** — Saves/loads prompt KV cache as `.safetensors` via `mlx_lm.models.cache`. On startup, if a cache file exists, it loads the prefix and skips re-encoding the system prompt. Tracks which tokens are cached via `hx` (history) list, does prefix matching on every call to maximize reuse. The cache saves across runs to `cache/cache.safetensors`.

**Workspace mirroring** — Uses `os.link()` (hardlinks, not copies) to mirror the working directory into a temp `$HOME/workspace`. Claude Code runs inside the mirror. Zero-copy, instant.

---

## Configuration

| Flag | Default | Notes |
|------|---------|-------|
| `--model` | `mlx-community/Qwen3.5-4B-OptiQ-4bit` | Any mlx-community model works |
| `--port` | `8000` | Local server port |
| `--cache` | `cache/cache.safetensors` | Prompt KV cache across runs |
| `--system` | `# Env\n{env}` | System prompt with working dir injection |
| `--names` | 8 core tools | Whitelist tools passed to model |
| `--skips` | suggestion-mode, system-reminders | Regex noise to strip from context |
| `--work` | `$CWD` | Source directory to mirror |
| `--home` | temp dir | Home for the Claude process |

Extra `--` args are forwarded to `claude` CLI directly.

---

## Model Recommendations (from code comments)

- `mlx-community/Qwen3.5-4B-OptiQ-4bit` — default, runs on any Apple Silicon
- `mlx-community/Qwen3.5-2B-OptiQ-4bit` — lighter, for constrained RAM
- `mlx-community/Qwen3.5-0.8B-MLX-bf16` — ultra-lightweight

Any `mlx-lm`-compatible model works. For quality closer to real Claude, point it at a larger quantized Qwen3.5 27B or 32B from mlx-community.

---

## What This Means

This is the cleanest implementation of the "local model as Anthropic API drop-in" pattern I've seen. The important insight isn't the code — it's the architectural pattern:

**Any Claude Code-compatible tool can be run free and local on Apple Silicon by setting two env vars and pointing at any mlx-lm model.**

The same pattern applies to:
- Claude Code itself
- Codex CLI (which also respects `ANTHROPIC_BASE_URL`)
- Any Anthropic SDK user
- OpenClaw ACP harness sessions, if configured to hit the local endpoint

The prompt cache persistence is underrated. Most local model setups re-encode the system prompt (which can be 4K+ tokens) on every request. This caches the KV state and only processes the new tokens. For a coding agent doing many sequential edits, this is a meaningful speedup.

---

## Caveats

- **Small model, limited coding quality.** 4B Qwen3.5 is not Claude Sonnet. It'll handle simple edits, file reads, boilerplate. Complex multi-file refactors or debugging chains will stumble. 
- **Tool call format is model-specific.** The `decode()` parser handles `<tool_call>/<function=><parameter=>` format which is Qwen3.5's output. Different models emit tool calls differently. If you switch to a non-Qwen model, the tool call parsing may break.
- **No streaming.** The server buffers the full response, then sends all SSE events at once. Claude Code UX feels non-streaming from the user's perspective.
- **gen_lock.** Requests are serialized through a threading.Lock(). Concurrency is 1. Fine for a personal coding agent, not fine for multi-user or parallel sub-agent setups.
- **Only 9 stars, created 2026-03-08.** Early, low visibility, effectively one person's project. But the code is clean and the pattern is sound.

---

## Relevance

🔥🔥🔥🔥 — The rating is for the pattern, not the star count. This is a clean, readable reference implementation of "run Claude Code on local MLX models" in 373 lines. 

**For our setup:** We already have Ollama running and wired to OpenClaw, but this pattern is specifically for ACP/Claude Code sessions (not OpenClaw's main agent). If we want to run Claude Code sessions on local models:

```bash
# Using mlx-code directly:
mlx-code --model mlx-community/Qwen3-14B-4bit "fix the bug in src/"

# Or manually with any mlx-lm server:
ANTHROPIC_BASE_URL=http://localhost:8000 ANTHROPIC_AUTH_TOKEN=local claude
```

The workspace hardlink mirroring is also worth lifting as a standalone pattern for sandboxed agent runs.

Apache-2.0. Use freely.
