# Local Model Release Matrix

**Source:** openbmb/MiniCPM5-1B  
**Repo:** https://huggingface.co/openbmb/MiniCPM5-1B  
**License:** Apache-2.0  
**Reviewed:** 2026-05-31

## Pattern

Package a local language model as a release family, not a single checkpoint. Include the base/instruct variants, the common local-runtime formats, the chat template, the recommended serving paths, and the fine-tuning guides in one navigable release surface.

## Shape

```text
model family
  -> base checkpoint
  -> SFT/checkpoint-before-RL
  -> final post-trained checkpoint
  -> GGUF quantizations for llama.cpp/Ollama/LM Studio
  -> MLX or platform-specific local build
  -> runtime cookbooks
  -> fine-tuning cookbooks
  -> chat template and tool-call parser guidance
```

## Why It Works

Local model adoption fails when the artifact is technically available but operationally vague. A complete release matrix lets users pick the artifact that matches their hardware and runtime:

- BF16 or FP16 for GPU/server inference;
- GGUF for llama.cpp, Ollama, and desktop runtimes;
- MLX or equivalent for Apple Silicon;
- base and SFT checkpoints for research and fine-tuning;
- final post-trained checkpoint for direct use;
- explicit chat template and sampling modes;
- backend-specific tool-calling notes.

This also makes evaluation cleaner. Reviewers can separate questions about the model's raw quality from questions about packaging, runtime compatibility, quantization, and prompt formatting.

## Implementation Notes

- Keep the main model architecture standard when possible, so mainstream inference engines can load it without custom code.
- Publish config and chat-template details with the model, not only in a blog post.
- Include recommended sampling settings for different modes.
- Put tool-call formatting and parser requirements in the card.
- Link to backend-specific deployment docs for the exact model family.
- Maintain sibling releases for quantized and platform-specific formats.

## Caveats

The release matrix does not prove model quality. Long context, tool calls, reasoning modes, and quantized builds all need target-hardware evaluation. Treat the matrix as a usability pattern, not as a benchmark.

---

**Attribution:** Pattern extracted from openbmb/MiniCPM5-1B, Apache-2.0.
