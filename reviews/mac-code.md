# mac-code — #259

**Repo:** https://github.com/walter-grace/mac-code  
**Author:** walter-grace  
**License:** MIT (implied — no explicit LICENSE file; README has no license section)  
**Language:** Python  
**Stars:** 104 | **Forks:** 7  
**Created:** 2026-03-23 | **Reviewed:** 2026-03-25  
**Rating:** 🔥🔥🔥🔥  
**Cloned:** ~/src/mac-code

---

## What It Is

Local AI coding agent for Apple Silicon. "Claude Code, but free." Runs Qwen3.5-35B via llama.cpp (SSD paging) or Qwen3.5-9B via MLX. ~$0/month after hardware.

The headline claim: 35B MoE model (10.6 GB at IQ2_M) on a 16GB Mac mini M4 via macOS SSD flash-paging, hitting 30 tok/s. The 9B on MLX gets 64K context with persistent KV cache via TurboQuant + Cloudflare R2 sync.

```bash
# 35B via llama.cpp (SSD paging)
llama-server --model ~/models/Qwen3.5-35B-A3B-UD-IQ2_M.gguf \
  --ctx-size 12288 --cache-type-k q4_0 --cache-type-v q4_0
python3 agent.py

# 9B via MLX (64K context, persistent KV)
python3 mlx/mlx_engine.py
python3 agent.py
```

---

## Architecture

~4400 lines of Python across two backends.

### Core Agent (`agent.py`)

**Intent routing via LLM classification** — the central trick for making low-bpw models work:

```
user query → classify_intent() → one word: "search" / "shell" / "chat"
     search → rewrite query → DuckDuckGo → answer with results
     shell  → generate_shell_command() → subprocess → answer with output  
     chat   → stream directly
```

Two fast `llm_call()` hops (classify + generate) instead of one complex structured output call. Benchmarked 8/8 correct at 2.6 bpw where JSON function calling fails entirely. This is the engineering insight — route first, then generate the appropriate output for that path.

Self-improvement loop: every interaction logged to `~/.mac-code/logs/interactions-YYYY-MM-DD.jsonl` with `/good`/`/bad` grading. `/improve` shows stats. RLHF training data accumulation built in from day one.

### MLX Backend (`mlx/`)

Four research modules:

**`turboquant.py`** — KV cache compression inspired by Google's TurboQuant. Per-group asymmetric min-max quantization at 2/3/4-bit. PolarQuant variant quantizes direction (angle) separately from magnitude — exploits the insight that attention cares about direction more than magnitude. Result: 26.6 MB → 6.5 MB at 0.993 cosine similarity.

**`tiered_cache.py`** — Hot/warm/cold KV cache tiers: GPU memory → SSD (~0.1ms reads) → Cloudflare R2 (~50ms reads, free first 10GB, no egress fees).

**`r2_store.py`** — R2 client for context persistence. Process a codebase once, save KV cache, resume next session in 0.0003s (SSD load) or 1.5s (R2 download). Cross-device shared context.

**`paged_inference.py`** — MLX paged attention for SSD overflow.

---

## What's Good

**Text-routing trick for broken instruction following at low bpw** — this is genuinely useful and transferable. When a model can't reliably produce structured JSON output at ultra-low quantization, decompose into: (1) cheap classification call for a single token, then (2) a generation call appropriate to the classified type. Much more reliable than trying to get the whole pipeline from one call. Works at 2.6 bpw where JSON breaks.

**KV cache quantization research** — the TurboQuant implementation is a working PolarQuant/group-quant demo in ~276 lines of MLX. The tiered cache architecture (GPU → SSD → R2) is a solid reference for anyone building persistent local agents.

**64K context on 9B via KV quant** — the `--cache-type-k q4_0 --cache-type-v q4_0` llama.cpp flags alone are worth knowing: take context from 32K to 64K on the 9B with no quality loss. Single config flag, zero code.

**Self-improvement logging** — all interactions JSONL-logged with grade labels. `/good`/`/bad` rating commands. This is how you accumulate fine-tuning data without a pipeline.

---

## Caveats

- No explicit LICENSE file (README claims MIT intent but no file). Treat as "no explicit license" — use for educational/non-commercial.
- 2 days old, 104 stars — very fresh, trust the benchmarks cautiously
- SSD paging at 30 tok/s is real but write-amplification on the SSD is non-trivial at scale
- TurboQuant benchmarks are self-reported; the 0.993 cosine similarity number is for a specific test, not general validation
- R2 sync is a cool architecture but introduces cloud dependency for what's advertised as a local tool

---

## Relevance to Our Stack

**vmlx** (#234) is our current "ship this weekend" item for local MLX inference. mac-code is a different angle: it's the agent layer on top of llama.cpp/MLX, not the inference server itself. These compose cleanly — vmlx as the inference backend, mac-code patterns for the agent routing layer.

**Direct wins to extract:**
- KV cache quantization flags for llama.cpp (`--cache-type-k q4_0 --cache-type-v q4_0`) — already useful for our Debbie/Rue setups
- Text-routing intent classification pattern — applicable to any agent running at low quant
- TurboQuant module — directly applicable to the MLX stack if we push context persistence

**Parkinson's agent (Marcos):** The persistent KV cache + R2 sync architecture is interesting for continuity of care context — load the patient's full history once, persist it, resume cross-session without re-processing. Worth watching.

---

## Verdict

🔥🔥🔥🔥 — The text-routing trick for low-bpw models and the KV cache tiering architecture are the two transferable insights. The llama.cpp KV quantization flags alone are worth the review. Very new project with self-reported benchmarks, but the core ideas are sound and demonstrated.

**Steal immediately:** `--cache-type-k q4_0 --cache-type-v q4_0` llama.cpp flags. Text-routing intent classification pattern.  
**Watch:** TurboQuant as persistent context infrastructure for the Marcos agent.  
**Note:** No explicit LICENSE file — educational use only until clarified.
