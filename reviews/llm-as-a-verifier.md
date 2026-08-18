# LLM-as-a-Verifier (llm-as-a-verifier/llm-as-a-verifier)

**Repo:** https://github.com/llm-as-a-verifier/llm-as-a-verifier
**License:** MIT; permissive reuse with attribution
**Reviewed:** 2026-08-17
**Stack:** Python 3.9+, google-genai, openai, tqdm, optional vLLM
**What it is:** A Python library and benchmark harness for ranking agent trajectories with fine-grained LLM verifier rewards, pairwise comparison, progress tracking, multimodal context, and a cost-reduced probabilistic pivot tournament.

---

## Verdict

⚠️ **Interesting verification framework with one blocking reproduction bug.** The core idea is strong: use token-logprob distributions over fine-grained score tokens instead of a single judge label, then spend comparisons where they matter. The package is young but coherent; however, the default Terminal-Bench 2.0 benchmark config points at a non-existent data path, so `python3 scripts/run.py terminal_bench` loads zero tasks and crashes with `ZeroDivisionError`.

---

## What It Is

LLM-as-a-Verifier is a general-purpose verifier layer for agent outputs. Given a task and multiple candidate trajectories, it asks an LLM to compare candidates under domain-specific criteria, reads the model's logprob distribution over ordered score tokens, turns that distribution into continuous rewards, and selects the best trajectory.

The repo targets three related use cases: best-of-N selection for agent rollouts, direct pairwise comparison of candidates, and progress tracking over trajectory prefixes. It ships built-in benchmark loaders and criteria for Terminal-Bench, SWE-Bench Verified, and MedAgentBench, plus reproduction scripts for a self-verification Terminal-Bench 2.1 experiment.

The implementation is compact enough to study. The public API is `select`, `compare`, `track`, and `ProgressTracker`; the main algorithms live in `fine_grained_reward.py`, `pivot_tournament.py`, and `progress.py`.

## Stack

| Layer | Tech |
|-------|------|
| Library | Python package `llm-verifier` |
| Verifier backends | Gemini via Vertex AI, DeepSeek, OpenAI-compatible servers |
| Optional local backend | vLLM/SGLang-style OpenAI-compatible logprob endpoint |
| Benchmarks | Terminal-Bench, SWE-Bench Verified, MedAgentBench loaders |
| Packaging | setuptools, `pyproject.toml`, typed package marker |
| Tests/CI | No obvious committed automated tests or CI workflows |

## Key Features

### Fine-Grained Reward From Logprobs

The verifier reads probability mass across 20 ordered score tokens and computes an expected reward rather than trusting the sampled score alone. That is the main technical advantage over a plain LLM-as-judge call: uncertainty in the distribution is preserved instead of collapsed.

The OpenAI-compatible path includes a useful prefill trick for vLLM/SGLang-style backends: generate analysis first, then prefill `<score_A>` / `<score_B>` and read the constrained one-token letter distribution.

### Probabilistic Pivot Tournament

Best-of-N selection avoids a full `O(N^2)` round robin. The algorithm samples a ring pass, selects top empirical pivots, compares non-pivots against pivots, then aggregates soft Bradley-Terry wins. For fixed pivot count, comparison cost is roughly linear in candidate count.

That is a pragmatic fit for agent rollouts where each comparison may include two long transcripts and several repeated verifier calls.

### Progress Tracking

`track` scores completed trajectories at checkpoints, while `ProgressTracker` scores one prefix at a time for online monitoring. The online form matters because it prevents the verifier from seeing the future and accidentally crediting early steps for later success.

### Benchmark Criteria Files

Criteria are ordinary Markdown with a ground-truth note and stable criterion IDs. This is a clean, inspectable interface: benchmark-specific judgment policy lives in text files, while scoring and caching stay in code.

## Architecture

The repo is organized around a few clear boundaries:

- `llm_verifier/fine_grained_reward.py` owns backend clients, logprob extraction, token accounting, score caches, multimodal image loading, and pairwise reward prompts.
- `llm_verifier/pivot_tournament.py` is a small pure-Python algorithm module.
- `llm_verifier/progress.py` owns checkpoint prompts and online/offline progress scoring.
- `llm_verifier/loaders.py` translates benchmark trajectory formats into a shared `{problem, trace, reward}` shape.
- `scripts/run.py` handles registry-driven benchmark execution and reports Pass@1, verifier selection, and oracle scores.

The best design choice is that benchmark loaders and criteria are separate. A new benchmark can add a loader and criteria file without changing the scoring primitive.

The weakest operational choice is test posture. There is no obvious `tests/` directory or CI workflow, and a default benchmark command currently fails before any verifier API call because a data directory was renamed or misconfigured.

## Comparison

| Aspect | LLM-as-a-Verifier | Inspect AI | Ori Eval | ART |
|--------|-------------------|------------|----------|-----|
| Primary role | Rank/select agent trajectories with LLM verifier rewards | General eval framework | TypeScript eval workflow and reporting | Reinforcement training for agents |
| Core scoring | Logprob expectation over score tokens | Task-specific scorers | Assertions/judges/cost reports | Learned/LLM reward loops |
| Agent trajectory focus | High | High | Medium-high | High |
| Deployment maturity | Research library, young | Mature framework | Practical CLI workflow | Training framework |
| Main caveat | Reproduction bug and sparse tests | Larger framework surface | OpenRouter/provider coupling | GPU/training complexity |

LLM-as-a-Verifier is narrower than Inspect AI or Ori Eval. That narrowness is useful: if the problem is "choose the best rollout among several long agent attempts," its API is simpler than adopting a full eval platform. It is not a replacement for executable graders, sandboxes, or human approval gates.

## Self-Hosting Notes

Install is straightforward:

```bash
pip install llm-verifier
```

Useful backend paths:

- `DEEPSEEK_API_KEY` uses the hosted DeepSeek verifier path.
- `VERTEX_API_KEY` uses Gemini through Vertex AI because token logprobs are required.
- `OPENAI_BASE_URL=http://localhost:8000/v1` can point at an OpenAI-compatible local server such as vLLM, as long as it returns token logprobs.

Operational caveats:

- Verifier prompts can be huge because each comparison may include two full trajectories.
- Token accounting and prefix-cache warming help, but benchmark runs can still be expensive.
- Image inputs are loaded from paths or URLs and sent to the verifier backend; callers should treat that as data exfiltration unless running a trusted local model.
- Do not rely on the bundled `terminal_bench` command until the data path bug is fixed.

---

**Attribution:** llm-as-a-verifier/llm-as-a-verifier, MIT, https://github.com/llm-as-a-verifier/llm-as-a-verifier
