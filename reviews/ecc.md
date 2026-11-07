# ECC (affaan-m/ECC)

**Repo:** https://github.com/affaan-m/ECC
**Owner:** Affaan Mustafa and contributors
**License:** MIT; preserve copyright and permission notices in copies or substantial portions. External tools, services and model weights retain their own terms.
**Reviewed:** 2026-11-07 (UTC)
**Revision:** d2ef2680594f9a17526a6e1a2e18b3d242c5d17b — repository-wide architectural survey with focused inspection of installers, hooks, memory, provider and operator surfaces; not an exhaustive audit of every skill.
**Source updated:** 2026-11-06T21:21:50Z (reviewed commit). Package version 2.2.3; latest public release observed: v2.2.3, 2026-10-01.
**Verification:** Static source review; no source code, tests, installer, agent, model or external integration executed. Public GitHub metadata and CI status checked separately.
**Stack:** Markdown agent/skill definitions; Node.js/CommonJS CLI and hooks; TypeScript harness adapters; Bash/Python learning tools; SQLite/sql.js state; separate Rust ECC2 alpha.
**What it is:** A cross-harness coding-agent workflow and operations bundle: skills, specialist agents, rules, executable lifecycle hooks, selective installation, session memory and operator tooling. It is not elliptic-curve cryptography, a standalone model, or a universally isolated agent runtime.

## Verdict

⚠️ **Interesting — selectively pilot the workflow layer, not the entire catalog as a trusted operating system.** ECC has substantial implementation behind its prompts: managed installation, explicit hook-capability consent, bounded memory reads and writes, cross-platform tests and real guard code. Its strongest fit is an experienced Claude Code operator who wants reusable engineering routines and can audit enabled effects. Cross-harness parity is limited, several components remain alpha, and hooks, summaries and MCP registrations expand execution, persistence and network authority.

## Identity and prior coverage

The supplied URL resolves to the public canonical repository **affaan-m/ECC**. The predecessor API identity **affaan-m/everything-claude-code** redirects to the same repository. Both identities were checked against the public review index and fetched main branch: no existing full review was found; the older identity already appears in a research listing and an ECC-pattern extraction. This review adds one canonical entry without replacing those historical artifacts.

## What It Is

ECC packages a proposed engineering cycle: plan, test, implement, review, verify, remember and improve. Most specialist behavior lives in Markdown instructions consumed by an existing coding harness. For example, the planner declares Read/Grep/Glob tools and an Opus model; search-first guides investigation of existing packages and tools before implementation. Those declarations only constrain execution to the extent that the receiving harness implements them.

The executable layer is significant. The npm CLI dispatches setup, selective install, catalog/profile, memory, repair/uninstall, session inspection and control-pane operations. Claude Code is the primary supported integration; Codex has native plugin/config paths, while other adapters expose narrower capabilities. The README advertises 71 agents, 314 skills and 98 legacy command shims; these are upstream catalog counts, not independently certified behavior or quality scores. [Overview and support matrix](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/README.md).

## Stack

| Layer | Implementation and implication |
|---|---|
| Behavioral content | agents/, skills/, rules/, commands/ and legacy shims; prompts and workflow guidance, not executable isolation |
| Installation | Node CLI, manifests and recorded operations; Bash/PowerShell entry points and native plugin setup |
| Hook runtime | JSON lifecycle registration plus JavaScript dispatch, profile controls, format/check/gate/session helpers |
| Memory | Local Markdown vault; session/observation files; SQLite state is a separate operational store |
| Optional providers | Python 3.11+ llm-abstraction with Anthropic/OpenAI SDKs and Ollama/compatible adapters |
| Operator surfaces | Node HTTP control pane/dashboard; separate Rust ECC2 SQLite/TUI/daemon alpha |
| Dependencies | Node >=18 declared; pinned direct @iarna/toml, ajv, js-yaml, sql.js and zod, npm/Yarn lockfiles; Python dependencies use lower bounds |

Evidence: [`package.json`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/package.json), [`pyproject.toml`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/pyproject.toml), [`scripts/ecc.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/ecc.js), [`ecc2/README.md`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/ecc2/README.md).

## Key Features

### 1. A large workflow catalog with useful engineering discipline

The research-before-coding, planning, TDD, review and verification material is reusable. The value is reducing repeated process design, not guaranteeing that an LLM followed the process. Domain-specific and security-related skill labels are not certifications. Instruction-only adapters cannot enforce Claude-style hooks. Start with a narrow workflow rather than advertise hundreds of unrelated skills to every session. Evidence: [`skills/search-first/SKILL.md`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/skills/search-first/SKILL.md), [`agents/planner.md`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/agents/planner.md) and the README support matrix.

### 2. Managed installation is materially better than blind copying

The implementation separates install planning, application, state recording, diagnosis, repair and uninstall. Install-state validation rejects unknown fields and records operations; lifecycle logic uses content hashes and containment checks, and includes preservation of drifted/symlinked copies in relevant uninstall/migration paths. Hook consent explicitly discloses automatic source writes, command/process changes, transcript-derived LLM egress, MCP activity, permission gates and persistent records. This is unusually useful disclosure, but not a universal rollback guarantee for external side effects.

The legacy shell entry point automatically runs npm install with --ignore-scripts when node_modules is missing. That prevents dependency lifecycle scripts at that step, not registry access or subsequent runtime code execution. Auto-update pulls current repository changes and reinstalls recorded selections: an update changes trusted executable bytes and deserves review. Evidence: [`scripts/lib/install-state.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/lib/install-state.js), [`scripts/lib/install-lifecycle.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/lib/install-lifecycle.js), [`scripts/lib/install/hook-consent.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/lib/install/hook-consent.js), [`install.sh`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/install.sh), [`scripts/auto-update.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/auto-update.js).

### 3. Hooks contain real checks, but are not a sandbox

GateGuard inspects tool/transcript evidence and distinguishes first-touch edits, destructive shell operations and routine commands. Config protection tries to prevent agents from weakening lint/format checks instead of fixing code. The dispatcher bounds input and fails closed on truncation for selected GateGuard/MCP checks; other paths intentionally return no opinion or skip unavailable helpers. Profiles default to standard and hooks can be disabled through configuration/environment.

This is defense in depth under a trusted operator, not an independent authorization kernel. A process with the user's filesystem/environment authority can influence configuration; the underlying harness still owns permissions, sandboxing and tool availability. Do not interpret a hook timeout, successful install or a security-scanner score as proof of containment. Evidence: [`hooks/hooks.json`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/hooks/hooks.json), [`scripts/hooks/run-with-flags.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/hooks/run-with-flags.js), [`scripts/lib/hook-flags.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/lib/hook-flags.js), [`scripts/hooks/gateguard-fact-force.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/hooks/gateguard-fact-force.js), [`scripts/hooks/config-protection.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/hooks/config-protection.js).

## Architecture and Trust Boundaries

### Host harness versus ECC

The CLI dispatches local subprocesses; manifests select files and adapters; the host harness discovers instructions and invokes hooks. Hooks may read transcripts, run formatters/checks, inspect MCP services and write session state. There is no single ECC permission boundary covering every adapter and optional service.

The sampled Codex worker preserves the operator's configured sandbox and accepts only never/on-request approval policies. It canonicalizes the task-file path into its current worktree before invocation. Noninteractive never means no approval prompts, not no tool execution. The separately named yolo profile still specifies workspace-write rather than danger-full-access; naming alone would have produced the wrong security conclusion. User-install defaults use on-request and workspace-write, with live web search. Evidence: [`scripts/orchestrate-codex-worker.sh`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/orchestrate-codex-worker.sh), [`.codex/user-config.example.toml`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/.codex/user-config.example.toml), [`.codex/yolo.config.toml`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/.codex/yolo.config.toml).

### Important finding: session summaries can use existing provider authentication

The session-end path may trigger an LLM summary when remaining context is low or at a configured message interval (default 50). The helper extracts recent conversation text and starts claude --model haiku -p by default, reusing existing Claude authentication and inheriting the process environment. It has a recursion guard, deadline budget and mechanical fallback, but the inspected invocation does **not** explicitly disable tools, MCP or inherited CLI configuration. Conversation text is concatenated into the summarization prompt rather than submitted to a separately sealed no-tool evaluator.

Therefore “local memory” does not imply offline processing or no additional model usage. The installed hook consent does disclose this egress. For sensitive workloads, deliberately disable LLM summarization or verify the helper's effective provider, tools and configuration in an isolated pilot. This is a trust-boundary concern from static inspection, not a demonstrated exploit. Evidence: [`scripts/hooks/session-end.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/hooks/session-end.js), [`scripts/lib/llm-summary.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/lib/llm-summary.js).

### Providers, credentials and network access

The core content does not require an ECC-hosted account, but the selected coding harness generally uses its own provider account. The optional Python layer resolves Claude/OpenAI/Ollama/Atlas/Astraflow providers and saved provider/model configuration; its tool executor invokes registered Python callables directly. It sanitizes model-facing exception text, while raw exceptions remain in trusted logs. Application authors must impose their own tool schema validation, approval and isolation boundaries.

MCP examples include local package execution, unpinned npx packages, @latest entries, hosted endpoints and credential placeholders. Copying an entire example is a supply-chain and authorization decision, not harmless documentation setup. The opt-in Itô bridge is an external authenticated compute workflow, not free bundled inference; hosted ECC Pro/GitHub App is separate from this MIT tree. No provider, compute reservation, paid service or MCP connection was tested. Evidence: [`src/llm/providers/resolver.py`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/src/llm/providers/resolver.py), [`src/llm/tools/executor.py`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/src/llm/tools/executor.py), [`mcp-configs/mcp-servers.json`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/mcp-configs/mcp-servers.json), [`.codex/user-config.example.toml`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/.codex/user-config.example.toml).

### Local dashboards are a trusted-machine boundary

The web dashboard explicitly describes loopback-only, unauthenticated operation. The control pane defaults to 127.0.0.1 and enables actions unless disabled. Shared Host/Origin checks help against DNS rebinding and browser-origin misuse, but accept absent Origin and compare hostnames rather than authenticating users; they are not tenant isolation or a general same-origin/token authorization scheme. Keep these operator surfaces off public proxies and shared untrusted hosts. Evidence: [`scripts/dashboard-web.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/dashboard-web.js), [`scripts/lib/control-pane/server.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/lib/control-pane/server.js), [`scripts/lib/loopback-guard.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/lib/loopback-guard.js).

## Memory, Retention and Recovery

**Memory Vault:** project/team scopes live under the project's .ecc/memory, user scope under the user's .ecc/memory. Default recall is project+team. New entries are create-only and unreviewed; types/statuses and sizes are constrained. Reads are bounded (including file-count and aggregate-byte limits), use non-symlink/regular-file checks, and enforce trusted-root containment. Creation requests owner-only directories/files, project memory is ignored by Git, and known secret patterns are rejected. The MCP wrapper makes user scope opt-in and uses a server-owned harness identity. These are meaningful controls. Evidence: [`scripts/lib/memory-vault.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/lib/memory-vault.js), [`scripts/lib/memory-vault-format.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/lib/memory-vault-format.js), [`scripts/memory-mcp.mjs`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/memory-mcp.mjs).

**Not a secret store or automatic knowledge approval:** regexes recognize selected token/private-key formats, not all confidential prose, PII or novel credentials. Markdown storage is plaintext, and “unreviewed” is provenance, not a guarantee against prompt injection when recalled. No general TTL/encrypted-at-rest policy was established for the sampled vault. Backups, manual review, retention and deletion across every store remain operator responsibilities.

**Continuous learning is separate:** hook observation stores scrubbed tool input/output in JSONL; a background observer can transform observations into project/global instincts and later skills. Its checked-in observer setting is disabled by default. The observer uses a model subprocess with Read/Write allowed tools; it is not neural-weight training. Archives preserve rotated/processed observations, so rotation must not be confused with secure erasure. The skill's “100% reliable” hook-capture language is too strong: the implementation explicitly skips observation when a shell/helper is unavailable or fails. Evidence: [`skills/continuous-learning-v2/config.json`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/skills/continuous-learning-v2/config.json), [`skills/continuous-learning-v2/hooks/observe.sh`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/skills/continuous-learning-v2/hooks/observe.sh), [`skills/continuous-learning-v2/agents/observer-loop.sh`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/skills/continuous-learning-v2/agents/observer-loop.sh), [`scripts/hooks/observe-runner.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/hooks/observe-runner.js).

**Recovery is layered:** mechanical session-summary fallback, saved handoffs, recorded install state and diagnosis/repair tools help continuity. They do not undo already-issued external API actions, restore every manually changed config, or prove a model-generated summary is accurate. The Rust alpha uses SQLite as its cross-process state source; its own documentation says the overall product and release packaging are unfinished.

## Workflow Claims and Evidence

| Claim/surface | What the inspected evidence supports |
|---|---|
| Improved agent performance | Plausible reusable process and context controls; no independent end-to-end productivity or cost improvement measured here |
| Continuous learning | Observation-to-textual-instinct/skill workflow, not model training; capture can fail or be disabled |
| Security | Real hook checks, path restrictions, secret heuristics and consent; not universal sandboxing or a proof of prompt-injection immunity |
| Cross-harness support | Multiple adapters and installation tests; explicit uneven capability matrix, not equivalent hooks everywhere |
| Evaluation/promotion | Capsule/receipt tooling exists; the JavaScript gate command explicitly refuses execution without supported isolation |
| ECC2 optimization | Rust alpha has a bounded recorded-measurements comparison/promotion registry; scores and evidence references remain operator assertions, not authenticated benchmark truth or automatic runtime deployment |

Evidence: [`scripts/eval-harness.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/scripts/eval-harness.js), [`ecc2/README.md`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/ecc2/README.md), [`README.md`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/README.md).

## Tests, CI, Dependencies and Maturity

The main CI definition has Linux Node 18/20/22 lanes, Windows/macOS Node 22 lanes, package-manager compatibility lanes, exact packed-artifact installation lifecycle checks, component/schema validators, Python lint/type/unit tests, coverage gates, signature/advisory checks and supply-chain IOC scanning. Actions are SHA-pinned in the sampled workflow and checkout credential persistence is disabled. Tests include memory boundary, read-completeness, MCP, summary and observer regressions. These are stronger maintenance signals than a prompt-only repository.

The public **CI run for this exact SHA reported success**: [run 42296108996](https://github.com/affaan-m/ECC/actions/runs/42296108996). That is upstream status, not a locally reproduced result or a claim that every optional integration works. The security job blocks high runtime npm advisories, not all development dependency advisories. No independent dependency audit, registry-to-source reproducibility check, complete license inventory or release-binary verification was performed.

Observed GitHub metadata: 299,049 stars, 44,184 forks and 241 open issues/PRs combined; these are transient popularity/activity counts, not evidence of safety. The latest reviewed source is newer than the 2.2.3 release. README caveats include optional Bash/Python requirements, macOS shell limitations and native-Windows observer/memory issues; code includes related fixes, but this review did not resolve those reports experimentally. Node 18 compatibility is a stated minimum, not a recommendation to deploy an obsolete runtime. Prefer a maintained supported Node release and test the exact host/harness combination. Evidence: [`.github/workflows/ci.yml`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/.github/workflows/ci.yml), [`tests/lib/memory-vault.test.js`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/tests/lib/memory-vault.test.js), [`package.json`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/package.json), [`README.md`](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/README.md).

## Comparison

| Option | Best fit | Tradeoff versus ECC |
|---|---|---|
| [Superpowers](https://github.com/obra/superpowers) ([review](superpowers.md)) | A focused coding methodology and review loop | Less need to adopt a broad operator/memory/integration suite |
| [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin) ([review](compound-engineering-plugin.md)) | Workflow and accumulated engineering lessons across harnesses | Compare planning/review conventions first; avoid stacking duplicate policies/hooks |
| Native harness instructions plus selected skills | One project, small trusted behavior surface | More manual curation, but fewer persistent processes and incidental integrations |
| ECC | An operator who wants a wide catalog plus install, hook and memory tooling | More capabilities and more version-specific trust boundaries to own |

These are fit comparisons, not fresh comparative benchmarks. A separate sandbox/credential broker is complementary infrastructure, not replaced by any of these instruction packs.

## Self-Hosting / Adoption Notes

There is no single production server to deploy. Keep the source/release version explicit, inspect the chosen adapter's effective permissions, preview the managed install plan, and preserve existing settings. Begin with a small no-hooks/selective profile; enable hooks only after reviewing their disclosed effects. Do not bulk-import MCP examples or assume opt-in observer behavior applies to every summary hook.

A useful pilot should measure task success, review defects, tokens/cost and wall time against the same harness without ECC. Exercise uninstall with modified user files, interrupted session recovery, oversized hook inputs, secret-bearing synthetic transcripts, memory-scope separation and provider-denied/offline operation. Keep dashboards local, pin external executables, and set a retention policy for vaults, summaries, observations, archives and databases. None of these deployment steps was performed during this review.

## Verification Limits

This is a source-based architectural review, not penetration testing or a complete audit of the 314-skill catalog. No reviewed source was installed or executed, no host credentials or private data were used, and no model calls were made. Source/API access and upstream CI status were verified; behavior, performance, platform parity and recovery remain to be independently reproduced. No code was extracted from the repository.

---

**Attribution:** [Affaan Mustafa and contributors / affaan-m/ECC](https://github.com/affaan-m/ECC), [MIT license](https://github.com/affaan-m/ECC/blob/d2ef2680594f9a17526a6e1a2e18b3d242c5d17b/LICENSE). Earlier identity: affaan-m/everything-claude-code.
