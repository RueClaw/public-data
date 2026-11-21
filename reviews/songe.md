# Songe (sous-labs/songe)

**Repo:** https://github.com/sous-labs/songe
**License:** Apache-2.0; permissive reuse with license/notice obligations and patent terms. Model weights and bundled OFL fonts have separate terms.
**Reviewed:** 2026-11-21 (UTC)
**Revision:** e806a187c018455c217fbed57632ff1b8bfdd3d9 (main); package version 0.1.0a13. Scope: README, design/contracts, manifests, CI, proxy/API, storage, learning/gating, backends, artifacts, integrations and representative tests.
**Verification:** Static review plus isolated offline Python syntax and four focused gate assertions; no installation, GPU training, model downloads, service activation or live model requests.
**Stack:** Python 3.11+, Starlette/Uvicorn, HTTPX, SQLite, MLX or PyTorch/Transformers/PEFT, Textual, vanilla browser UI.
**What it is:** A local OpenAI-compatible proxy that records coding-agent interactions and uses idle compute to personalize a local model through prompt lessons and LoRA training. It is not a coding agent or a tool-executing reinforcement-learning environment.

---

## Verdict

⚠️ **Interesting — thoughtful local-learning machinery, not yet a dependable automatic upgrade path.** Songe has unusually concrete durability, privacy-boundary and rollback engineering for an alpha. Its promotion gate is weaker than the “independent held-out conversations” framing suggests: the judged path resamples individual moments, including correlated ones, and the judge is the same base model family. Study or evaluate with non-sensitive data before letting it adapt an important daily model unattended.

## What It Is

An existing agent sends requests through Songe on loopback port 7613 to an existing local model server. The proxy records requests, tool results and responses. A Quick Dream extracts standing preferences and appends selected lessons to new sessions' system prompts; a Deep Dream generates synthetic practice, trains an adapter and checks a candidate before switching serving versions. Session-pinned prompt lessons avoid changing a conversation's cached prefix midstream. [S1] [S2] [S3]

The default dreams mode trains on generated practice rather than raw conversations. That does **not** mean conversations are never stored or processed: they supply lesson extraction, evaluation and synthetic-data context. A separate configurable hindsight mode trains on real steps. The roadmap's autonomous sandbox reinforcement learning and frontier-agent collaboration are future directions, not current capabilities. Practice files are parsed and validated, not executed. [S1] [S3] [S4]

## Stack

| Layer | Technology and role |
|---|---|
| Ingress/UI | Starlette/Uvicorn, HTTPX streaming proxy, local HTML/JS dashboard; Rich/Textual CLI |
| Durable state | SQLite experience, lessons, practice, cycle journals and version pointers; atomic JSON/config files |
| Learning | MLX on Apple Silicon; optional PyTorch, Transformers, PEFT and accelerator extras |
| Serving | LM Studio, vLLM, Ollama, llama.cpp, mlx-lm adapters; supported does not mean equally verified |
| Integration | opencode/pi provider edits and backups; launchd, systemd user service or Windows task integration |

## Key Features

### Separate prompt memory from weight training

Quick Dreams are inspectable/removable preferences, not fine-tuning. Deep Dreams use a frozen base conditioned on a lesson as teacher and an adapted student conditioned on the scene, with full-vocabulary forward KL the default objective. This is on-policy distillation, not demonstrated autonomous RL. Practice checks include frame validity, parseability, copy heuristics and a lesson-relevance choice. These reduce obvious bad examples but do not prove semantic correctness or secret removal. [S3] [S4] [S5]

### A real promotion gate — with an important statistical caveat

The gate checks matching samples, finite metrics, drift, tool validity, empty answers and severe looping; it can try reduced adapter strength. In the unjudged KL path it bootstraps conversation clusters and rejects insufficient independent conversations. In the judged path, however, each judged row ID becomes a separate bootstrap unit and that independent-conversation minimum is skipped. Total row count still must reach min_heldout. [S6]

A focused offline reproduction supplied five winning rows from one conversation: the judged gate accepted; the otherwise comparable unjudged gate rejected. This establishes helper behavior, not a reproduced end-to-end training promotion. The production selector limits judged moments to three per conversation/lesson and 24 overall, so the five-row fixture is not that selector's exact output; the correlation concern still applies across selected moments. The judged module's introductory description of unit-level resampling disagrees with gate.py's implementation. [S6] [S7]

The original base judges before/after answers with order masking and teacher-preference tie breaking. Useful self-evaluation is not independent task success measurement, nor proof against catastrophic forgetting. No general coding benchmark improvement was independently verified. [S7]

### Durability is more than a progress bar

Atomic writes fsync the file, replace a sibling and fsync the parent directory on POSIX. Training checkpoints include adapter/optimizer state; resumability checks and journals support interruption. Serving loads and health-checks the candidate before a transactional current/previous pointer change, restores the incumbent on failure, and tracks owned artifacts. Retention defaults to three older restorable versions; older full exports may need rebuilding from adapters, so undo is not always instant. These are strong implementation signals, not crash/power-loss tests performed here. [S8] [S9]

## Architecture

Agent → loopback proxy → local model server; captured exchanges → SQLite → lesson reading → synthetic practice → idle/resource-guarded worker → adapter → held-out evaluation → serving swap.

The code separates server adapters, accelerator backends, platform services, artifact ownership, reading/practice stores and learning phases. It includes schema migration and a targeted recovery for historical undersized scoring. Backups and configuration diffs are first-class; JSONC is not silently rewritten as plain JSON. The large worker and state store still create substantial state-machine complexity, and observed prose/code drift argues for reading executable paths over trusting design summaries. [S2] [S8] [S9] [S10]

## Security, Permissions and Privacy

- **Local-user trust boundary, not authenticated multi-tenancy.** API guards check loopback client/host, exact same-origin when Origin is present, and JSON content type for mutations. Upstream configuration accepts local HTTP endpoints only; inspected proxy/swap HTTPX clients disable environment proxies. The guard has no per-user bearer authentication, so another process able to reach loopback can interact with it. Do not expose it through a remote reverse proxy. These are static observations, not penetration-test results. [S2] [S3] [S11]
- **Transport secrets versus content secrets.** The store does not receive transport headers/bearer tokens, but serializes request and response bodies. A secret in a prompt, tool result or generated lesson can therefore persist; no general content-secret redaction appears in that record path. Private directories/files and Windows ACL code restrict access, but SQLite content is not application-encrypted. OS compromise, backups and local processes remain relevant. [S8] [S12]
- **Forgetting is not model unlearning.** forget deletes conversation/derived text tables, clears prompt lessons, requests rebuilding, checkpoints/truncates WAL and vacuums. Learned versions remain by design. It cannot promise erasure from previously learned weights, filesystem snapshots or backups. [S1] [S12]
- **Learning is a trust escalation.** Extracted lessons become future system-prompt content; third-party material encountered by an agent can influence the extraction pipeline. Suitability rules and removable lessons help, but no independently demonstrated prompt-injection resistance exists in this review. Use curated non-sensitive sessions, inspect learned preferences and keep a known-good base. [S3]
- **Local processing is not zero network or zero machine changes.** Installation/backend setup fetches packages; artifact tooling downloads pinned, SHA-256-checked llama.cpp sources/binaries from GitHub, and accelerator setup references PyTorch wheel hosting. Inspected Torch model-loading paths use local_files_only and trust_remote_code=False. Runtime learning data is designed to stay local, but dependency acquisition is an external network boundary. [S13]
- **No recorded tool execution, but real host authority.** Songe does not execute captured tool calls; it does run its own workers/server/toolchain processes, edit supported agent configurations, create a login service and manage learned artifacts. Those installation permissions must not be confused with a read-only application. [S4] [S10] [S13]

## Maturity, Tests and Evidence Limits

Public GitHub metadata retrieved anonymously on 2026-11-21 reported creation on November 20, last push November 21 at 08:00:28 UTC, 58 stars, 10 forks and four open issue/PR items. The releases endpoint returned an empty list; 0.1.0a13 is the checked-in package version, not a verified GitHub release. The reviewed commit timestamp is 2026-11-21 08:00:23 UTC. Popularity and a large test tree are not runtime proof. [S14]

CI declares Ruff, pytest and build jobs on Linux/Windows Python 3.11/3.12 and Apple Silicon macOS Python 3.12. Representative tests cover gate regressions, swap, networking, configuration, storage and platform behavior. Fixtures isolate home directories and reject requests to several known real-model ports; that fixture is not a complete network sandbox. CI configuration was inspected; successful runs at this SHA were not independently established. README reports end-to-end testing for LM Studio/macOS and vLLM/Linux, Apple Silicon and NVIDIA; AMD and the other supported servers should not be assumed equally proven. [S1] [S15]

**Actually run:** in a no-network Bubblewrap namespace with cleared environment, no host home or GPU devices and read-only source, Python 3.14 parsed all 181 Python files. Four reviewer-authored gate assertions passed: independent improvement accepted, no change rejected, same-conversation unjudged improvement rejected, same-conversation judged wins accepted. This is syntax/helper verification, not the upstream pytest suite, minimum-Python compatibility or learning efficacy.

**Not run:** installation, upstream suite, dependency vulnerability scan, dashboard/browser exercise, model conversion/download, GPU calibration/training, real agent traffic, crash recovery or uninstall. Public issue #12 reports Linux init/uninstall failure without a systemd user manager; #13 reports documentation drift. These are community reports, not reproduced findings here. [S16]

## Comparison

| Option | Best fit | Tradeoff versus Songe |
|---|---|---|
| Agent instructions / explicit project memory | Reviewed preferences and project conventions | Easier to inspect and roll back; no weight-level adaptation, no automatic lesson mining required |
| MLX-LM LoRA tooling | Explicit Apple Silicon fine-tuning experiments | More direct dataset/training control; no integrated idle proxy, lesson extraction or automatic promotion workflow |
| Hugging Face TRL + PEFT | Controlled training/evaluation research | More assembly and compute planning; stronger opportunity to separate training data, teacher and independent evaluation |
| Songe | Experimental continuous local personalization | Integrated capture-to-adapter loop; wider persistence/privacy surface and an immature automatic acceptance criterion |

Alternatives are architectural comparisons, not fresh comparative benchmarks. See [MLX-LM](https://github.com/ml-explore/mlx-lm), [TRL](https://github.com/huggingface/trl), and [PEFT](https://github.com/huggingface/peft).

## Self-Hosting Notes and Costs

This is a per-user desktop/background service, not a hosted SaaS deployment. There is no required Songe account or metered cloud API in the inspected design. Costs are local GPU/unified memory, electricity, model and derived-artifact disk space, conversion/checkpoint overhead and operational attention. “Idle compute” is not free compute; README's minutes for Quick Dreams and hour-or-more for Deep Dreams are author estimates, not measured here. CPU-only machines can serve/record but do not normally train. Model weights and their licenses are separate prerequisites. [S1] [S5] [S13]

Before an evaluation, choose a compatible model/server and non-sensitive dataset, keep auto-learning off until data handling and rollback are understood, and use external task evaluations rather than the model's own judge alone. Verify service-manager support on the target system and retain base weights plus backups. No installation or adoption was performed for this review.

## Evidence

All source-file links below are pinned to the reviewed SHA; mutable public metadata and issue reports were retrieved 2026-11-21.

[S1]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/README.md
[S2]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/proxy.py
[S3]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/quick.py
[S4]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/practice/checks.py
[S5]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/config.py
[S6]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/sleep/gate.py
[S7]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/sleep/judged.py
[S8]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/storage.py
[S9]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/sleep/swap.py
[S10]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/agents/__init__.py
[S11]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/api.py
[S12]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/log.py
[S13]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/artifacts/tools.py
[S14]: https://api.github.com/repos/sous-labs/songe
[S15]: https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/.github/workflows/ci.yml
[S16]: https://github.com/sous-labs/songe/issues/12

Additional implementation evidence: [training checkpoints](https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/backends/training.py), [recovery](https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/sleep/recovery.py), [worker/gate integration](https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/sleep/worker.py), [Torch model loading](https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/backends/torch.py), [backend installation](https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/src/songe/backends/install.py), [test fixtures](https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/tests/conftest.py), [gate tests](https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/tests/test_gate.py), [roadmap](https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/ROADMAP.md), [license](https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/LICENSE), [package manifest](https://github.com/sous-labs/songe/blob/e806a187c018455c217fbed57632ff1b8bfdd3d9/pyproject.toml), [empty release listing](https://api.github.com/repos/sous-labs/songe/releases), [documentation issue](https://github.com/sous-labs/songe/issues/13).

---

**Attribution:** Sous Labs, [sous-labs/songe](https://github.com/sous-labs/songe), Apache-2.0. Independent review; no source code extracted.
