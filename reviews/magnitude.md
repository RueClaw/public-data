# Magnitude (magnitudedev/magnitude)

**Repo:** https://github.com/magnitudedev/magnitude
**License:** Apache-2.0 at repository root; Rust workspace metadata says UNLICENSED (clarification advisable before redistribution).
**Reviewed:** 2026-11-25 (UTC)
**Revision:** `ab3c35c474d8cfe55733903d3223c7b31c0a2e1e`; release `@magnitudedev/cli@0.3.2` resolves to this commit. Scope: root manifests/docs, inference engine/service/evaluation, ACN, integrations, agent policy, storage, release and CI.
**Verification:** Static source and anonymous public metadata review only; no dependencies installed, source executed, models downloaded, accounts used or benchmarks/tests run.
**Stack:** TypeScript/Bun, Effect, React/Electron, Rust, Seismic compiler/runtime, CPU/Metal/CUDA/Vulkan, SQLite.
**What it is:** A local model inference and management platform, now centered on running large sparse models across GPU, RAM and SSD and connecting existing agents—not primarily a browser automation library or merely a llama.cpp wrapper.

---

## Verdict

⚠️ **Interesting: pilot the inference server, not an assumed safe autonomous agent.** The implemented tiered expert streaming and custom numerical compiler are substantial engineering, and the existing-agent integration is practical. But vendor speed claims are not independently reproduced, the retained coding agent lacks enforced per-action approval, and network/cloud modes invalidate an unconditional “nothing leaves your machine” reading. Start with a restricted local inference-only pilot and benchmark your exact model and hardware.

## Update Notes

Checked 2026-11-25; replaces the 2026-08-18 review in place. That review recorded release 0.0.6 but no exact source SHA, so an exact historical code diff is unavailable from its provenance. The current README emphasizes inference infrastructure, and the Rust workspace now uses Seismic rather than the previous review's llama.cpp-backed description. Release is now 0.3.2; network browser administration, existing-agent connections, current security boundaries and measurable performance qualifications require a materially different assessment. Rating changes from ✅ Deploy candidate to ⚠️ Interesting. This is a documented review refresh, not proof that every feature was introduced since August. [1][2][3]

## What It Is

Magnitude discovers hardware, assesses supported GGUF models, manages downloads and residency, serves model APIs, and offers desktop/web/CLI controls. Its headline use case is running sparse mixture-of-experts models larger than GPU memory by placing experts in different memory tiers. The README also advertises concurrent agents, prefix caching and speculative decoding. These are inference capabilities, not evidence that any particular coding model is reliable. [1][2]

Existing tools such as Codex, Claude Code, Pi, OpenCode, Hermes and OpenClaw can use the local service. The repository still contains a full coding-agent runtime, roles and shell/file tools; those must be assessed separately from an inference endpoint that returns tool calls for another application to execute. The API documentation explicitly assigns conversation history and tool execution to the caller. [4][5][6]

## Stack

| Layer | Technology and responsibility |
|---|---|
| Product clients | Bun/TypeScript CLI, React web client, Electron desktop |
| Application service | Effect-based ACN daemon, RPC, model/provider management, chat and inference proxy |
| Inference service | Rust inventory, hardware assessment, residency and worker supervision |
| Engine | Rust model families, batching, scheduling, token generation and logical state |
| Numerical execution | Seismic language/compiler/runtime and CPU, Metal, CUDA, Vulkan backends |
| Persistence | JSON configuration/credential records, model/cache files, SQLite chat events |
| Distribution | Bun/Cargo lockfiles, Changesets and multi-platform GitHub Actions |

Source: root manifests, inference workspace and architecture documentation. Architecture documents describe intended contracts; representative source confirms real implementations, not exhaustive qualification of every backend. [2][3][7]

## Key Features

### Tiered expert streaming, not magic extra memory

The executor has real streamed-expert machinery: an interest ledger orders and cancels reads, demand can accelerate a prefetch, completed reads land into tiers, and failed demand reads fail the affected rows. CPU/CUDA/Metal/Vulkan kernel trees and streaming tests exist. This supports the mechanism behind the README claim, not its universal throughput. Active working data still has to fit; SSD bandwidth, memory, context length and model sparsity matter. “Zero flash wear” describes read-only weight streaming, not every download, cache or log write the application performs. [1][8]

### Hardware-specific tuning and reproducible evaluation scaffolding

The tuning contract ranks numerically eligible configurations over representative prefill/decode work, including 4k and 64k histories, and explicitly says unmeasured costs remain unknown. The evaluation tree contains reference, fixture, model-quality, memory and serving benchmark tooling, including Ollama comparison adapters. These are useful reproducibility assets, but scaffolding and test files are not successful result records. [9][10]

### Existing-agent connections are configuration mutations

The Codex connector writes configuration and a model catalogue; its documentation explains that even hosted-model requests then pass through the Magnitude gateway. Connection transactions register rollback actions before mutation and report incomplete restoration. Remote browser Connections instead provides a setup prompt: it does not directly reconfigure the browser user's computer. Connecting is operationally meaningful, not simply displaying a URL. [5][11]

### Compatible APIs and model lifecycle

Documented APIs include OpenAI Chat Completions, Responses and Anthropic Messages/token counting, with SSE streaming. Compatibility remains model-dependent. Model downloads track partial files and hashes; interrupted work can resume, while explicit user cancellation can discard partial data. Configuration can relocate model storage independently of application removal. [4][12][13]

## Architecture


guarded clients → ACN application service → Rust inference service → engine → Seismic → device backends

ACN also routes optional hosted requests, manages persistent chat and coordinates provider/model selection. This is a broader trust boundary than a numerical engine library. A separate retained agent runtime can invoke shell and filesystem tools. Do not conflate a web administration UI with autonomous browsing: no claim of a currently supported general-purpose browser-use agent is established by this review. [2][4][6][14]

## Performance and Evaluation Evidence

The README says “over 2x faster than Ollama.” The anonymously accessible vendor benchmark page, retrieved 2026-11-25, lists 64k context and speculative decoding enabled, default engine settings and machine/disk descriptions. For example, it reports Qwen 3.8 Flash Next at 41 tokens/s on RTX 3090 plus 64 GB RAM/PCIe 4 SSD and 87 tokens/s on RTX 5090 plus 64 GB RAM/PCIe 5 SSD; these are vendor-reported numbers, not our measurements. [1][15]

The retrieved page does not establish a pinned engine revision, full raw trials/variance, an equal-quality controlled baseline or a universal 2x gain. Its extracted content did not expose the linked Ollama comparison detail. No independent benchmark or coding-task success measurement was verified. Reproduce exact model/quantization, prompt length, prefill and decode latency, concurrency, warm/cold caches, drafter settings, memory and disk behavior before accepting the speed claim. Evaluation code improves auditability but cannot substitute for measured outcomes. [9][10][15]

## Security, Authority, Privacy and Cost

- **Inference is not execution permission.** API tool calls are executed by the client; Codex or another connected agent retains its own approval/sandbox responsibilities. Magnitude is not an approval firewall for those tools. [4][5]
- **Retained agent approval gap:** the active interceptor evaluates role policy; leader rules reject selected shell/git/path operations then end in `allowAll()`. Safeguards can be disabled. The leader prompt explicitly states tools have no built-in approval system and the model is responsible for asking. These are application-level command/path checks and prompt guidance, not an OS sandbox or guaranteed confirmation before edits. Shell execution supports detached processes. Treat source files, skills and web content as prompt-injection surfaces whenever this agent is enabled. [6][16]
- **Local-first, not multi-tenant:** network defaults bind to loopback. Enabling network access without a specific valid bind uses all interfaces; an invalid bind falls back to all interfaces with a warning. Remote inference requires a key by default, but `requireApiKey: false` disables that requirement. Host-header checks, CORS handling, same-origin remote control, constant-time key comparison and login throttling exist. Browser sessions use HttpOnly/SameSite cookies and a 30-day idle lifetime. These are good controls, not proof of a completed penetration test. [14][17][18]
- **Transport matters:** documented network access is plain HTTP. Use a trusted private network, SSH tunnel or correctly configured TLS proxy; do not expose it publicly as-is. SSH-forwarded traffic is treated as local and can open the application without a Magnitude key, so tunnel access is administration authority. One shared API key is not per-user least-privilege authorization. [18]
- **Egress is mode-dependent:** local inference can avoid remote prompt processing after acquisition, but Hugging Face downloads, updates, configured hosted providers and hosted Codex/Claude routing require networking. Custom endpoints and an Exa search provider exist. Optional OTLP exports spans/logs when configured; ACN tracing is off without its enabling environment configuration. Rust telemetry includes credential redaction, which does not prove all sensitive content is removed. Inspect selected routes and diagnostics before using confidential inputs. [5][13][19]
- **Credentials are local files, not a proven encrypted vault:** provider auth and Hugging Face records use owner-only JSON writes and corruption checks. Protect those files, network configuration and backups; 0600 is not encryption at rest. No supplied or discovered real secrets were used in this review. [20]
- **Cost:** local inference avoids provider token billing, not hardware, electricity, SSD capacity or download costs. Hosted models may incur provider charges. Context caps and request token controls are not a dollar budget; no universal hard spend ceiling was established in the inspected routing paths. [4][13][19]

## Persistence, Recovery and Export

Configuration preserves unknown keys and implements corruption recovery. Download state distinguishes resumable interruptions from explicit cancellation, while connection setup has compensating rollback. Chat storage uses a versioned SQLite database with WAL handling and typed corruption/incompatibility errors; the agent has separate session persistence. These are real recovery mechanisms, not a verified crash-recovery guarantee. [11][12][13][21]

The API caller remains responsible for its conversation history. No supported, complete cross-product conversation/configuration export-and-restore workflow was verified in the inspected docs and chat UI/service paths. Back up configuration, protected credential records, connection records and chat data with the service stopped or SQLite-aware backup tooling; treat derived caches separately from original data. Test restoration and disconnect behavior before adoption. [4][13][21]

## Licensing, Supply Chain and Maturity

The root LICENSE is Apache-2.0 (notice retention, patent terms and change notices matter), but the Rust workspace declares `license = "UNLICENSED"` and engine/Seismic crates inherit it. That is inconsistent metadata, not a basis to silently declare the whole engine unlicensed or uniformly cleared: ask maintainers to reconcile it before redistribution. Numerical adaptations carry their own preserved third-party notices. Downloaded model licenses are separate from application licensing. [22]

Bun and Cargo lockfiles, generated-protocol checking, targeted typechecks, integration tests and release candidate builds are positive signals. Release trust code checks Apple publisher identity; update manifests include digests/signing machinery. However, CI uses version-tagged third-party actions rather than all immutable SHAs, and installation/build includes native tools and trusted dependency scripts. Neither binary signatures nor all transitive licenses were independently audited. Do not execute the README's pipe-to-shell installer merely to inspect this project. [3][23]

At retrieval, anonymous GitHub metadata reported 8,297 stars, 595 forks, 51 open issues/PRs combined and last push 2026-11-25T01:23:03Z. Latest release was 0.3.2 at that timestamp. The exact reviewed commit's check-runs API exposed a successful “version” check and skipped Mintlify Deployment—not a complete all-platform green test suite. Popularity, release availability and source test counts do not prove correctness. [24]

## Comparison

| Option | Best reason to choose it | Tradeoff versus Magnitude |
|---|---|---|
| [Ollama](https://github.com/ollama/ollama) | Familiar local serving and model management | Compare exact workload; Magnitude's vendor speed claim is not universal evidence |
| [llama.cpp](https://github.com/ggml-org/llama.cpp) | Direct GGUF engine/server with explicit low-level controls | More manual integration; useful controlled baseline, not Magnitude's current engine |
| [vLLM](https://github.com/vllm-project/vllm) | Server-oriented GPU throughput and concurrent serving | Different deployment/memory assumptions; benchmark against your serving objective |
| [MLX LM](https://github.com/ml-explore/mlx-lm) | Apple-specific local language-model experimentation | Narrower hardware scope; not a substitute for the entire cross-platform management layer |

These are positioning comparisons, not newly tested head-to-head results. If a current local server already meets latency/memory needs, there is no demonstrated reason here to replace it solely on headline multipliers.

## Self-Hosting Notes

Prefer a disposable inference-only environment with no valuable repository, browser profile or provider credentials initially. Keep loopback defaults, pin the chosen release/model and verify distribution integrity; allow downloads deliberately. Decide separately whether to grant network administration, hosted-provider routing, connector config changes or built-in agent execution. The documented development toolchain includes Bun 1.4.2 and Rust 1.91.1, but native backend qualification is platform-specific. No installation recommendation here implies the installer was executed. [3][18][23]

Acceptance gates: reproduce throughput/quality on your hardware; verify local-only egress; test authentication from another machine if enabled; inspect connection diffs and disconnect recovery; test chat/model interruption recovery; resolve Rust license metadata; and enforce tool approvals externally if enabling autonomous work.

## Verification and Limits

Canonical URL was normalized from the submitted .git URL. The existing README row and research repository index already pointed to this source, so the existing review slug is reused. Anonymous GitHub API and HTTPS Git acquisition verified public access. Exact release tag was resolved with Git, and all code citations below pin the reviewed SHA. Only review artifacts were generated; no source code, installers, dependencies, model weights, browser sessions or devices were run or accessed. Source tests and benchmarks were not run. No exhaustive security, license, model-quality or runtime compatibility audit is claimed.

## Sources

[1] [README](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/README.md).
[2] [Inference overview](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/README.md), [architecture](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/docs/overview.md), [workspace](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/Cargo.toml).
[3] [Root manifest](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/package.json), [desktop manifest](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/desktop/package.json).
[4] [API endpoint contract](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/docs/api/endpoints.mdx).
[5] [Codex integration](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/docs/integrations/codex.mdx), [connector implementation](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/harness-connections/src/connectors/codex.ts).
[6] [Policy interceptor](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/agent/src/execution/permission-gate.ts), [shell tool](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/agent/src/tools/shell.ts).
[7] [Repository package tree](https://github.com/magnitudedev/magnitude/tree/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages).
[8] [Expert prefetch implementation](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/engine/executor/src/experts/watcher/prefetch.rs), [streamed execution](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/engine/executor/src/operators/routed/streamed.rs).
[9] [Native tuning contract](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/docs/tuning.md).
[10] [Evaluation tree](https://github.com/magnitudedev/magnitude/tree/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/evaluation), [benchmark adapter tests](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/evaluation/bench/tests/test_bench_ollama.py).
[11] [Connection transactions](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/harness-connections/src/transaction.ts).
[12] [Download lifecycle](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/service/models/src/download.rs).
[13] [Configuration and storage documentation](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/docs/reference/configuration-file.mdx).
[14] [ACN server and route guards](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/acn/src/server.ts).
[15] [Vendor benchmarks](https://magnitude.dev/benchmarks), retrieved 2026-11-25; mutable external page, not pinned source evidence.
[16] [Active role policy](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/roles/src/policy.ts), [leader role](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/roles/src/roles/leader.ts), [approval prompt](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/roles/src/prompts/leader.txt).
[17] [Network configuration and key checks](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/storage/src/config/network-access.ts), [remote browser access](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/acn/src/remote-access.ts).
[18] [Network access documentation](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/docs/api/network-access.mdx).
[19] [Inference gateway](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/acn/src/inference-gateway.ts), [ACN tracing](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/acn/src/tracing.ts), [Rust telemetry](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/service/server/src/telemetry.rs), [provider sources](https://github.com/magnitudedev/magnitude/tree/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/providers/src).
[20] [Credential storage](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/storage/src/auth/storage.ts).
[21] [SQLite chat storage](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/storage/src/chat/store-live.ts), [config recovery](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/storage/src/config/storage.ts), [agent persistence](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/agent/src/persistence/chat-persistence-service.ts).
[22] [Root license](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/LICENSE), [Rust metadata](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/Cargo.toml), [inherited engine license](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/engine/Cargo.toml), [third-party numerical notice](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/inference/seismic-std/THIRD_PARTY.md).
[23] [Release checks](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/.github/workflows/release-checks.yml), [integration workflow](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/.github/workflows/integrations.yml), [Apple trust check](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/release/src/trust.ts), [update manifest](https://github.com/magnitudedev/magnitude/blob/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/packages/release/src/hosted-update/manifest.ts).
[24] [Public repository metadata](https://api.github.com/repos/magnitudedev/magnitude), [release](https://github.com/magnitudedev/magnitude/releases/tag/%40magnitudedev%2Fcli%400.3.2), [commit checks](https://api.github.com/repos/magnitudedev/magnitude/commits/ab3c35c474d8cfe55733903d3223c7b31c0a2e1e/check-runs).

---

**Attribution:** magnitudedev/magnitude contributors; root Apache-2.0 license, with Rust metadata discrepancy and third-party/model terms as noted. Review text is independent analysis.
