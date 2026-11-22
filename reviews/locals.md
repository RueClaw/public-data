# Locals (Generated-Computers/Locals)

**Repo:** https://github.com/Generated-Computers/Locals
**License:** Apache-2.0; retain license/NOTICE and applicable third-party notices. Model weights and integrated agents have separate terms.
**Reviewed:** 2026-11-22 (UTC)
**Revision:** `40be24966d08938c6236cb146f9691930264141d` (main; repository-wide static review, focused on serving, runtime, agent execution, persistence, packaging and tests). Commit dated 2026-11-22 02:41:52 UTC.
**Release:** package metadata 0.2.2; latest observed tag `v0.2.2` points to `97b3ddc19b2858c44ce5e589aa43bbf156fc91cf`; changelog has 0.2.3 unreleased. GitHub Releases API returned no releases. This review is of main, not the tagged package.
**Verification:** static inspection only; no source execution, dependencies installed, model downloads, hardware access, inference, network service probes or benchmark reproduction. Public GitHub metadata and CI status checked separately.
**Stack:** Python ≥3.11, Apple MLX/mlx-lm, custom Metal kernels, NumPy, outlines-core, llguidance, Hugging Face Hub; optional OpenCode and other agent clients.
**What it is:** an Apple-silicon local inference server optimized for concurrent tool-using agents, with OpenAI/Anthropic/Ollama interfaces and additional coding-agent orchestration—not merely a chat UI or a generic agent sandbox.

---

## Verdict

⚠️ **Interesting — credible performance engineering, but local inference is not confidential agent isolation.** Continuous batching, model-specific kernels, constrained output and reusable prompt state form a substantive implementation. Evaluate it for a single trusted Mac and trusted projects; do not expose it as an authenticated multi-user service or treat its write confinement as protection against secret reads and network exfiltration. The speed results remain author measurements, not independently reproduced findings.

## What It Is

Generated Computers, with Arip Asadulaev named in package metadata and NOTICE, builds Locals for developers running several coding assistants against one model on their own Mac. The default server listens on loopback port 8321. Existing clients can use compatible API dialects; `locals code` configures/launches OpenCode, while `locals run` implements its own plan/parallel-candidate/check/repair workflow. `locals solve` instead races OpenCode sessions. These commands have different execution boundaries. [S1–S4]

The README connects the project to Asadulaev’s paper, “Breaking the Space Barrier and its Application to Language Model Inference.” This review verifies implementation mechanisms, not the paper’s mathematical novelty or proof. New model support, including Flint, LFM3, Qwenputer and Inkling, expands the source considerably; those model-specific quality and speed claims were not validated here. [S1, S3]

## Stack

| Layer | Implementation |
|---|---|
| HTTP/API | Python standard-library HTTP handler; API translation, streaming, request guards |
| Scheduling | `BatchService`, one worker/model engine; `HybridBatchEngine` continuous batching and mixed prefill |
| Compute | MLX/mlx-lm with fused projections, quantized small-batch matmuls, attention/recurrent/model-specific Metal kernels |
| Structured generation | JSON-schema/regex grammar, token automata, GPU masks, forced spans and budget-aware closing |
| State | RAM prefix cache; safetensors + JSON token snapshots on disk; CLI configuration, logs and run artifacts |
| Agents | Python harness and shell checks; optional external OpenCode process/integrations |

## Key Features

### Batched agent inference rather than universal acceleration

The author’s M2 Pro 16 GB/Qwen3.5-4B table reports 271 versus 87 aggregate tokens/s at eight concurrent requests (3.1×), but 64 versus 61 at one request. Measurement notes distinguish in-process fixed-length decoding from HTTP benchmarks and disclose warmups, concurrency, software versions and shorter-than-default InferenceX runs. These are useful reproduction details, not independent validation. Aggregate throughput is not per-agent speed, latency, task success or a promise for other chips, quantizations and workloads. Prompt-heavy workloads and untuned formats gain less. [S1, S5]

### Structured output with real constraints—and limits

Grammar compilation, token masking and forced spans support valid JSON/tool-call formatting; token budgets reserve room for valid endings. These are implementation-backed features, not proof that every arbitrary schema or model response works. `Runtime` explicitly refuses cyclic recursive schemas for the server, and grammar patterns can be unsupported. Well-typed tool arguments can still request harmful or incorrect actions: syntax constraints are not permission checks or semantic correctness. [S6]

### Parallel candidates selected by checks

The harness plans parts, runs multiple candidates in copied projects, selects combinations and repairs failures. File ownership and protected tests reduce accidental interference. A passing project check is a useful selection oracle but only as good as its coverage. Importantly, `Run._finish` also writes back when **no check exists**, after preserving overwritten originals; the README’s “project changed only when tests pass” is therefore too absolute. [S1, S7]

## Architecture

A request enters `server.py`, which checks headers/body, renders messages, chooses model-native output constraints and looks for cached prefixes. `service.py` schedules jobs onto `hybrid_batch.py`; mixed prefill interleaves new prompt work with running decode rows. `runtime.py`, fused layers and Metal kernels perform local computation. Finished states return to caches. The harness talks to this server as a client; ordinary inference does not itself execute arbitrary client tool calls, although the separate agent commands do execute programs, and optional Qwenputer has its own internal computation tools. [S2–S4, S6, S7]

### Authentication, browser access and exposure

- The inference listener defaults to `127.0.0.1`. API-key strings in client examples are placeholders, **not enforced user authentication** in the inspected request gate. Host/Origin checks are useful browser/DNS-rebinding defenses, not identity or tenant isolation. Native local processes can send requests without an Origin. [S1, S2]
- `_origin_ok` permits loopback origins and specified desktop-app schemes; `LOCALS_ORIGINS` can extend it or allow all. `_host_ok` permits loopback/local/private names and addresses, is bypassed for non-loopback bindings, and has its own wildcard override. Broadening the bind or putting it behind a proxy requires a separate authenticated/TLS boundary; do not infer safety from CORS. [S2]
- The handler has request-size limits (64 MiB), bounded body reads, chunk/decompression checks, and constrained template switches. These reduce obvious abuse but do not establish comprehensive denial-of-service resistance. [S2]

### Execution, credentials and privacy

The main `run`/`solve` shell helper conditionally uses macOS `sandbox-exec`. Its profile starts with **allow default**, then denies writes outside the attempt and allowed temporary/cache/package-manager directories. Reads, network access and inherited environment remain broadly available. A malicious project, test or model-generated command may therefore read accessible secrets and transmit them despite being unable to overwrite the original project. Confinement is skipped when `sandbox-exec` is unavailable or `LOCALS_NO_SANDBOX` is nonempty. [S8]

At this SHA, `run_check` does pass `confine=cwd`: the agent documentation’s statements that checks are never confined are stale. Conversely, the legacy `locals-agents` Python runner calls `run_shell` without confinement; Python `-I` is import/environment isolation, not an OS security sandbox. Keep these entry points distinct. `locals code` runs OpenCode directly in the real project. Headless OpenCode permission handling can auto-approve requests (with explicit external-directory/doom-loop refusals); this is not equivalent to human review of every operation. [S8, S9]

“Nothing leaves your computer” is defensible only as a narrowed claim about the local inference path. Installation fetches packages/installers, missing models come from Hugging Face, optional agents have their own behavior, and executed commands retain network capability. Gated models may use Hugging Face credentials (`HF_TOKEN` or cached login); shell subprocesses inherit environment rather than receiving a minimal secret-free environment. No hosted inference fee or mandatory cloud inference backend was found in the reviewed core, but that does not prove a network-silent deployment. No traffic capture was performed. [S8–S10]

### Persistence and recovery

Prompt persistence defaults on with a 4 GiB limit. `DiskPromptCache` writes safetensors and token-ID JSON using temporary files, file flushes and renames; model/dtype/weight fingerprints separate incompatible states, old entries are pruned and failed loads discarded. The directory is mode 0700 and main snapshot files 0600. Those are access controls, **not encryption**: token IDs can reveal prompt text, and Inkling conversation checkpoints can retain more than system prompts. Debug request dumps additionally contain full requests. Disabling future caching does not erase existing data. [S2, S11]

CLI state includes background-process PID/log/config data; stale PID validation checks process identity before treating it as a server. Harness failures preserve candidate output; write-back checks for concurrent project edits and symlinks, stages temporary files, then renames. Its own comment acknowledges a crash between renames can leave a partial multi-file update: this is not a transactional repository rollback or a demonstrated durable resume system. Successful tests do not undo external side effects of agent commands. [S7, S9, S11]

## Maturity, Tests and Supply Chain

Public metadata observed 2026-11-22: 548 stars, 43 forks, 7 open issue/PR items, last pushed 2026-11-22 04:51:30 UTC. Popularity and push timestamps are not quality evidence. The package labels itself Beta. There are 75 `test_*.py` files including end-to-end tests; the test README still says 39, another documentation-drift signal. [S12]

The public [tests workflow run for the reviewed SHA](https://github.com/Generated-Computers/Locals/actions/runs/44977285031) reported success. The workflow uses macOS 15 with Python 3.11–3.14, installs a tokenizer, runs `not model` tests and builds/imports the wheel. Full model tests require cached weights; end-to-end tests are opt-in. Missing model/tokenizer fixtures can skip tests, so this result is not proof of benchmark parity or all integrations. No tests were executed for this review. [S12]

An `uv.lock` exists, but the convenience installer installs the latest package with `uv tool install --force`, not an immutable locked environment. It may first execute uv’s fetched installer and modify shell PATH. OpenCode installation asks interactively, pins a requested version, but executes a fetched installer script. Several dependency ranges have no upper bound; CI actions are referenced by version tags rather than immutable SHAs. Release configuration gates builds on tests and uses PyPI trusted publishing, a positive credential-management design—not a verification of the published wheel’s provenance or equivalence to this main SHA. Review and pin the full artifact/dependency/model chain before adoption. [S9, S10, S12]

## Comparison

These are fit comparisons, not independently benchmarked rankings:

| Alternative | Prefer it when | Locals tradeoff |
|---|---|---|
| [mlx-lm](https://github.com/ml-explore/mlx-lm) | You want the upstream MLX model/runtime baseline | Locals layers batching, caching, grammar and custom-kernel complexity on top |
| [llama.cpp](https://github.com/ggml-org/llama.cpp) | Cross-platform/GGUF portability matters | Locals is Apple-silicon/MLX-focused; GGUF is not its normal serving format |
| [Ollama](https://github.com/ollama/ollama) | Familiar model distribution and client ecosystem matter most | API compatibility does not make model storage interchangeable; Locals adds specialized concurrent-agent paths |
| [oMLX](https://github.com/jundot/omlx) | You are comparing Apple-local serving and tiered cache designs | Locals credits oMLX’s cold-tier idea in its Inkling checkpoint changelog; compare actual workloads rather than marketing ratios |

## Self-Hosting Notes

This is a local Mac application/server, not a ready hardened hosted service. The documented target is Apple silicon M1+ and macOS 14+; 16 GB is recommended, with smaller models for 8 GB. Default weights are roughly 2.8 GB; bigger models and conversion paths can require tens of gigabytes and substantially more working memory/disk. GPU memory, electricity, disk writes and idle kernel tuning are real costs. There is no required software subscription in the reviewed source, but external agents/providers and model terms can introduce separate costs or restrictions. [S1, S9, S10]

For a future authorized evaluation, prefer a pinned version/model, trusted project content, a disposable OS/account boundary without secrets, controlled egress and explicit checks before write-back. Keep loopback binding and avoid wildcard Origin/Host overrides. Inspect retained prompts, logs and failed-run copies under a deliberate retention policy. No installation, adoption or configuration change was performed here.

## Evidence and Limitations

All source links below pin the reviewed SHA; public API metadata is a point-in-time observation. Static findings identify design boundaries, not demonstrated exploits. No benchmark, third-party model quality claim, mathematical proof, sandbox bypass, complete dependency audit, or all-client compatibility claim was independently validated.

- **S1 — Overview and license:** [README.md](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/README.md), [LICENSE](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/LICENSE), [NOTICE](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/NOTICE), [THIRD_PARTY_NOTICES.md](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/THIRD_PARTY_NOTICES.md).
- **S2 — HTTP boundaries:** [locals/server.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/server.py).
- **S3 — Package map:** [locals/README.md](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/README.md), [pyproject.toml](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/pyproject.toml).
- **S4 — Scheduling:** [locals/service.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/service.py), [locals/hybrid_batch.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/hybrid_batch.py), [locals/mixed.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/mixed.py).
- **S5 — Measurements:** [docs/measurements/README.md](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/docs/measurements/README.md), [docs/benchmarks/README.md](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/docs/benchmarks/README.md).
- **S6 — Constraints:** [locals/runtime.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/runtime.py), [locals/grammar.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/grammar.py), [locals/budget.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/budget.py), [locals/forced.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/forced.py).
- **S7 — Orchestration:** [locals/harness.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/harness.py), [locals/plan.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/plan.py), [docs/agents/README.md](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/docs/agents/README.md).
- **S8 — Execution:** [locals/solve.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/solve.py), [locals/agents.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/agents.py).
- **S9 — CLI:** [locals/app.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/app.py).
- **S10 — Installation:** [install.sh](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/install.sh), [pyproject.toml](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/pyproject.toml), [uv.lock](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/uv.lock).
- **S11 — Persistence:** [locals/hybrid_batch.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/hybrid_batch.py), [locals/service.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/locals/service.py), [CHANGELOG.md](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/CHANGELOG.md).
- **S12 — Tests and releases:** [tests/README.md](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/tests/README.md), [tests/conftest.py](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/tests/conftest.py), [.github/workflows/tests.yml](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/.github/workflows/tests.yml), [.github/workflows/release.yml](https://github.com/Generated-Computers/Locals/blob/40be24966d08938c6236cb146f9691930264141d/.github/workflows/release.yml).

**Public metadata:** [repository](https://api.github.com/repos/Generated-Computers/Locals), [tags](https://api.github.com/repos/Generated-Computers/Locals/tags), [releases](https://api.github.com/repos/Generated-Computers/Locals/releases).

---

**Attribution:** Generated Computers / Arip Asadulaev, Apache-2.0 with applicable third-party notices. Analysis only; no implementation code or model weights redistributed.
