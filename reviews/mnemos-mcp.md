# Mnemos (Riley-Coyote/mnemos-mcp)

**Repo:** https://github.com/Riley-Coyote/mnemos-mcp
**Author:** Riley Ralmuto / Riley-Coyote
**License:** Apache-2.0; retain NOTICE and legacy MIT notices; bundled fonts have OFL notices.
**Reviewed:** 2026-11-08 (UTC)
**Revision:** d3749e2bae6780106bebe9876393abecc460f5e3, main snapshot. Manifest 0.6.4; HEAD includes unreleased recall changes.
**Verification:** Static source review only; no installation, tests, model downloads, provider calls or deployment performed.
**Stack:** Python 3.10+, FastMCP, SQLite/FTS5, optional sentence-transformers/PyTorch or Gemini embeddings.
**What it is:** Agent-authored continuity memory: selected observations, standing preferences, handoffs, journals and a startup briefing. Not a document/code indexer or evidence of persistent subjective identity.

## Verdict

⚠️ **Interesting — pilot for one trusted local agent, not a multi-tenant memory service.** The value is the lifecycle: get the agent to save lessons, preserve their provenance, and return them next session. Transactions, correction lineage, scoped retrieval and verified backups show concrete engineering. However, forgetting retains the words, optional autonomous hours transmit context and spend model quota, and advanced/admin paths do not preserve all simple-interface isolation guarantees. Prefer a small explicitly configured trial over importing sensitive history or enabling every integration.

## What It Is

The agent chooses what to capture and writes its own content and lesson. Mnemos stores it, asks for reflection as memories age, and returns a waking packet plus query-driven recall. Standing preferences do not fade; handoffs belong to sessions; journals are not automatically converted into beliefs. This differs from automatically mining every transcript. Hooks and harness adapters provide the practical advantage over a folder of notes. Authorship resolution can inspect harness/session information; “not a transcript indexer” does not mean no integration ever reads a session file.

Neuroscience vocabulary describes software heuristics: strength, stability, accessibility, decay and graph propagation. These are inspectable mechanisms, not validated biological fidelity. The identity framing is product philosophy, not scientific evidence of consciousness. [Overview](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/README.md), [authorship](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/authorship.py).

## Stack

| Layer | Implementation |
|---|---|
| Interfaces | Twelve simple stdio MCP tools; CLI; host-specific hooks/providers |
| Persistence | SQLite WAL, FTS5, memories/notes/versions/beliefs/reflection/session tables |
| Retrieval | BM25, optional passage embeddings, reciprocal-rank fusion, bounded graph resonance |
| Maintenance | Deterministic decay/bookkeeping; agent reflection; optional model judgments |
| Operator UI | Bundled browser companion with tokenized loopback URL |
| Optional services | Claude CLI/Anthropic, OpenAI, OpenRouter; Gemini embeddings; Jev cue judge |

## Key Features and Architecture

### Capture: atomic memory, not automatic summarization

Simple capture strips outer whitespace, appends supplied context, classifies kind/domain/tags with local rules and prepares an engram. Memory and continuity note land together through save_capture_pair; a standing mark shares that transaction. Embedding/bookkeeping follows the durable save and reports a secondary failure without claiming the original capture failed. That avoids an obvious retry-duplicates trap, although ordinary capture is not universally idempotent. Optional provider classification/connection discovery happens before the pair transaction. [Capture](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/simple_runtime.py#L5346-L5541), [store](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/store/sqlite_store.py#L4323-L4364).

### Recall: hybrid, scoped and state-changing

Current retrieval uses 30 lexical and 30 semantic seeds, word/meaning weights 0.3/0.5, reciprocal rank constant 60 and a semantic floor of 0.35. Content and its authored lesson take their better lexical rank rather than duplicate votes. Resonance walks at most two hops and five strongest links per expansion; notes do not propagate activation. Scope/visibility filtering is part of candidate selection. [Retriever](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/retrieval/reactive.py).

At this SHA recall defaults to 16 rows, three allocated to handoffs, and allows 50 on request. Handoffs have a separate search so old drafts do not dominate memory results. Recall reinforces returned memories once per session, wakes dormant matches and can restore faded archived items when requested; deliberately forgotten/replaced items are excluded by the supported simple path. Only the first 15 returned memories are co-linked. This is not a pure read API: retrieval changes future behavior. [Recall](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/simple_runtime.py#L5544-L5730), [unreleased changes](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/CHANGELOG.md).

### Continuity and upkeep are distinct

Startup context records delivery/session state without running decay. Capture can request background upkeep; scheduled and capture-triggered upkeep share a transactionally claimed, token-owned lease. Reflection asks the agent what a fading experience taught or whether a fact still holds; the agent supplies the meaning/verdict. Handoffs, journals and standing preferences have different lifecycles from ordinary memories. [Claims](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/simple_runtime.py#L405-L452), [consolidation](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/consolidation/daemon.py), [decay](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/consolidation/decay.py).

## Permissions, Security and Privacy

### MCP authority

Simple tools are context, handoff, journal, note, page, capture, recall, correct, reflect, introduce, maintain and health. Bounds include 65,536 capture characters, 4,096 query characters and 50 recall rows. Type/length validation reduces malformed-input/resource hazards, not semantic authorization. Most operations are honestly annotated as mutating, but openWorldHint=false is not an offline guarantee when providers are enabled. There is no per-call human approval gate for writes: the host's tool policy owns that decision. [Surface](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/simple_mcp.py), [limits](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/simple_tools.py).

Stdio delegates access control to whoever can launch/use the process. Simple scope is agent/person/project, configured rather than inferred from the current directory; project defaults to global. This avoids accidental fragmentation but requires explicit partitions for separation. Same-account processes can access the files. Authorship “signatures” are model/session labels, including caller-supplied model IDs, not cryptographic writer authentication. [Scope](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/simple_scope.py).

**Advanced mode is an admin boundary, not an equally restricted view.** It adds setup, ingestion, inspection, functional-memory, belief and legacy shared-pool tools. In particular, mnemos_inspect(engram_id) and legacy mnemos_forget(engram_id) directly load an ID without the simple runtime's person/project check. Advanced access plus an ID can inspect/archive another partition within that database. This is a static finding, not an executed exploit; it does not imply network exposure or bypass of the simple tool. Keep advanced mode away from mutually untrusted clients. [Inspect](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/mcp_server.py#L1252-L1295), [legacy forget](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/mcp_server.py#L1449-L1467).

### Persistent prompt injection

The implementation distinguishes agent/person/tool-authored words, labels unsigned/other-model notes and avoids promoting legacy tool-written content into identity. That is valuable provenance, but cannot determine whether an agent copied malicious instructions into its own capture. Such content can return at startup, especially when standing. There is no demonstrated semantic injection sanitizer or cryptographic writer attestation. Treat recalled text as evidence rather than authority; restrict writers and inspect corrections. [Trust model](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/docs/privacy-security.md#stored-words-and-trust).

### Local storage is not local inference

- Baseline memory/FTS and maintenance need no dedicated account/key. Cached local embedding loads are forced offline; model download is a separate operation. The README estimates about 90 MB for the model and several hundred MB for libraries including PyTorch.
- Explicit provider selection sends selected memories for link/surprise judgments. A key alone does not opt in. Providers include Claude CLI, Anthropic, OpenRouter and OpenAI. Environment/config and searched .env files determine selection/credentials; default search includes the launch directory and Mnemos's own directory. A chosen OpenRouter path can also inspect an existing OpenClaw config for a key. Inspect ambient credential discovery; do not launch from an untrusted config context. [Provider code](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/llm.py).
- Explicit Gemini selection sends embedded memory/query text to Google. Its REST implementation places the key in the request URL; caught errors redact it, but URL-handling intermediaries/logging still deserve care. [Embeddings](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/store/embedding_index.py).
- Optional Jev sends up to 1,000 message characters and six 200-character candidate lines to TypeSafe. The private key file is not shown back; scores choose cue lines, not memory rewrites. [Jev](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/jev.py).
- Anything a host agent reads enters its model context regardless of Mnemos's provider setting. Explicit shared captures enter a separate collective database, readable through recall by other agents and potentially their providers. Withdrawal authorization is tool-level, not OS isolation. [Shared memory](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/shared_memory.py).

### Quiet hours add autonomous work and cost

The documented setup choice is yes-by-default after disclosure; noninteractive setup does not directly schedule the hours. Claude hours use the person's plan and transmit prompt material, wake context and whatever is read/recalled to Anthropic. Own-hour defaults are 60 minutes/400,000 tokens; work-hour defaults 30 minutes/200,000 tokens. These ceilings are not dollar budgets or price quotes.

Controls include restricted Claude invocation, explicit MCP config, isolated settings, secret-read denies, sandbox enabled with no unsandboxed fallback, and previously written studio settings moved aside. But the own hour includes Bash/WebSearch/WebFetch: it is not an offline database timer. Actual isolation depends on Claude's installed runtime and OS sandbox. Hermes/OpenClaw handed-off hours use ordinary host tools, a weaker boundary acknowledged in the docs. Leave hours off until authority, quota and egress are accepted. [Construction](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/life.py#L690-L742), [privacy](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/docs/privacy-security.md#quiet-hours).

### Companion exposure

The companion binds specifically to 127.0.0.1, uses a random URL token, validates Host, requires a matching Origin and JSON for writes, bounds request size, and sends no-store/no-referrer/nosniff headers plus a page CSP. Assets are bundled. The page can inspect neighboring local minds and change memory/settings: its URL is a local bearer capability, not a multi-user login. Do not share/reverse-proxy it as a remote authenticated service. [Server](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/companion/server.py).

## Retention, Export, Backup and Durability

**Forgetting is not erasure.** Corrections archive the old pair and retain lineage/version history; forget archives rather than deletes. Normal recall suppresses deliberately forgotten content, but raw SQLite, backups and admin access retain it. No comprehensive hard-delete/retention-expiry workflow is provided by the documented interface. Uninstallation intentionally leaves memory. This is not a compliance deletion mechanism. [Correction](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/simple_runtime.py#L6512-L6620), [privacy](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/docs/privacy-security.md#correction-and-forgetting).

Storage is ordinary SQLite, not encrypted storage. POSIX helpers apply 0700 to newly created directories and 0600 to files; existing directories are not automatically tightened without force, and chmod is skipped on Windows. Use disk encryption, account ACLs and encrypted backups. “One file” is simplified: WAL/SHM sidecars, shared stores, backup files, config and hour records also exist. [File security](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/file_security.py).

Backup uses SQLite's online backup API, integrity-checks the copy and publishes through a temporary file. Restore saves the old destination, restores through SQLite rather than swapping a live WAL-backed file, then compares fresh-connection row counts/digests for seven principal memory tables. Stronger than copying the main DB, but not proof of every table's semantic correctness or all power-loss conditions. DB backups do not preserve every integration setting/hour artifact; this is not an off-machine backup policy. [Backup/restore](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/backup.py).

WAL, five-second busy timeout, immediate transactions, rollback on BaseException, migration backups and code-version gates address real failures. WAL synchronous=NORMAL favors performance; it does not promise the latest acknowledged transaction survives sudden power loss. An expiring upkeep lease is not permanent exclusion if a job outlives it. Recent Hermes fixes serialize shared-connection calls and correct conversation handoffs, but MCP sidecar mode still cannot distinguish every topic sharing one server. Do not treat one runtime as a proven arbitrary-concurrency service. [Transactions](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/store/sqlite_store.py#L1662-L1755), [Hermes fixes](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/CHANGELOG.md).

Workspace export is a projection, not a round-trip backup: it truncates selected content and writes MEMORY.md plus daily/topic/belief files. It directly overwrites rather than merging existing notes; selection is agent-level rather than the simple API's full person/project scope. Export into an empty dedicated destination; inspect for mixed-scope content and stale exports after forgetting. [Exporter](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/interface/openclaw_export.py).

## Evidence, Costs and Maturity

The README reports 35%→65% on 30 tasks, 14%→41% on 64 sealed questions and 22%→42% with ordinary tools. These are author-run, one-person workloads, not independently reproduced results. The useful control is that the same memories as searchable plain files scored 43% versus Mnemos's 42%: evidence supports capture/wake discipline more clearly than superior retrieval. Reported 22%/8% cost reductions are workload-specific API-price accounting, not guaranteed subscription/embedding/autonomous-hour savings. [Claims](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/README.md#how-well-it-remembers).

The public synthetic retrieval benchmark uses 224 engrams, disjoint topic vocabularies and one seed. Its recall@k denominator is capped at k, equaling precision when topics have enough relevant items; it is not full-corpus recall. Published depth-three default results also describe an older propagation design: current code uses two hops and a fan limit. Do not transfer those numbers without rerunning. Recent unreleased handoff rules were chosen after inspecting a small question set; the changelog reports no live-agent validation for that selection yet. [Benchmark](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/benchmarks/README.md), [constants](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/mnemos/retrieval/reactive.py), [changelog](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/CHANGELOG.md).

Public GitHub metadata checked 2026-11-08: repository created 2026-10-27; 133 stars, 18 forks and 10 open items including PRs; last push reported 2026-11-08. Latest release observed: v0.6.4, published 2026-11-07. Manifest explicitly says Alpha. Activity is not reliability. A sampled CodeQL run for this SHA succeeded; that does not prove the complete test matrix passed. Open PR #12 reports a fresh/no-store doctor path naming local embeddings without clearly saying dependencies are absent. [Metadata](https://api.github.com/repos/Riley-Coyote/mnemos-mcp), [release](https://github.com/Riley-Coyote/mnemos-mcp/releases/tag/v0.6.4), [CodeQL](https://github.com/Riley-Coyote/mnemos-mcp/actions/runs/42432700350), [PR](https://github.com/Riley-Coyote/mnemos-mcp/pull/12).

Tests include failed-save rollback, scope leakage, correction/forget, restoration, provider opt-in, parallel handoffs and maintenance claims. CI declares Python 3.10–3.13 tests, an 80% coverage gate for selected supported modules, an embedding job, dependency audit, Bandit, wheel-content/unlocked-install checks and Linux/macOS/Windows black-box jobs. Actions are SHA-pinned. Core MCP is bounded to >=1.30.0,<2, explicitly avoiding an incompatible major; optional ranges remain broad and a uv lockfile is present. Large modules (runtime about 8,600 lines, store about 5,800) and rapid churn increase regression risk. Tests/workflows were inspected, not executed; no independent dependency audit was run. [Manifest](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/pyproject.toml), [CI](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/.github/workflows/release-hardening.yml), [rollback tests](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/tests/test_a_failed_save_leaves_nothing.py), [scope tests](https://github.com/Riley-Coyote/mnemos-mcp/blob/d3749e2bae6780106bebe9876393abecc460f5e3/tests/test_scope_security.py).

## Comparison

| Option | Prefer when | Tradeoff versus Mnemos |
|---|---|---|
| Plain Markdown + host hooks | Small inspectable/versionable memory with few dependencies | You own capture discipline, conflict resolution and wake delivery; source's own factual control performed similarly |
| [Pi observational memory](pi-observational-memory.md) | Pi-specific compaction/source-backed observation is the need | Background observation/reflection rather than only agent-chosen words |
| [agentmemory](agentmemory.md) | Hook capture, retention and coding-agent history search matter | Broader ingestion/service surface; different security and deletion semantics |
| [Leviathan](leviathan.md) | Ranked retrieval over existing structured records | Search/indexing rather than journals, identity or autonomous reflection |

Architectural alternatives, not a fresh head-to-head benchmark or endorsement of their current versions.

## Self-Hosting Notes

Begin with simple stdio, one trusted identity, explicit scope and an isolated store. Verify actual semantic availability, not just provider selection. Leave dedicated providers, shared memory and quiet hours disabled until accepted. Do not expose the companion remotely. Back up before upgrades and test restore using synthetic data, including corrections/forgotten rows and mixed scopes. Use empty export destinations. Expand concurrency only after demonstrating distinct handoffs and complete saves on intended host versions.

Before sensitive use require synthetic checks for out-of-scope IDs, malicious stored instructions, retried writes, interrupted transactions, backup/restore, provider egress and the exact sandbox. This review is static evidence, not a penetration test, runtime compatibility certification or longitudinal retrieval evaluation. No private memory or transcripts were used.

---

**Attribution:** Riley-Coyote/mnemos-mcp, Riley Ralmuto; Apache-2.0 with NOTICE/legacy MIT notices and bundled font terms. No source code or private memory extracted.
