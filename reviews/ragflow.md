# RAGFlow (infiniflow/ragflow)

**Repo:** https://github.com/infiniflow/ragflow
**License:** Apache-2.0 for repository code; dependency, container and model terms require separate checks.
**Reviewed:** 2026-11-26 (UTC)
**Revision:** `625a53ad4c4ecb66abe32b4c0745564eaddeec94` (main snapshot). Latest public release observed: [v1.0.0](https://github.com/infiniflow/ragflow/releases/tag/v1.0.0), published 2026-11-06; this review is not a test of that release image.
**Verification:** Static source/config/test inspection only. No source execution, installations, model downloads, uploads, accounts, paid calls or live deployment probes.
**Stack:** Go/Gin/GORM, React/TypeScript/Vite, native DeepDoc/ONNX, SQL metadata, pluggable document engines, object storage, Kvrocks/NATS; Python SDK/testing utilities.
**What it is:** A document-ingestion, retrieval and agent platform with a browser UI, increasingly organized around compiled context and evidence for agent harnesses.

---

## Verdict

⚠️ **Interesting — substantial retrieval engineering, but production trust needs deliberate boundaries.** RAGFlow is worth a controlled evaluation for document-heavy teams that need parsing, configurable retrieval and agent workflows together. This revision has meaningful authorization and failure-handling code, but citation similarity is not factual verification, local code execution is explicitly unsandboxed, and the deployment examples are not a secure production perimeter.

## What It Is

InfiniFlow combines document parsing and chunking, optional embedding/reranking, knowledge compilation, chat and tool-using agents. Its strongest advantage over assembling a vector database plus a chat UI is the integrated ingestion and evidence workflow, especially for heterogeneous documents. The README advertises deep document understanding, reduced hallucinations and scalable automation; these are product claims, not measured outcomes of this review.

The current tree is Go-centered, not the older Python-server architecture many existing RAGFlow descriptions assume. API, ingestor, syncer, chatter and admin services coexist with native document processing and a sizeable browser application. Newer documentation describes an “agent native database,” emphasizing governed compiled evidence and lexical agentic retrieval rather than treating dense retrieval as universally necessary. That direction is useful, but neither naming nor a public release proves correctness across all connectors, engines or model combinations. [E1–E3]

Anonymous GitHub metadata on the review date showed 94,770 stars, 11,417 forks, 1,311 open issues/PRs combined and a last push on 2026-11-26. These indicate activity and adoption, not a security or quality score. Canonical-source searches found no prior standalone review to refresh.

## Stack

| Layer | Tech / operational implication |
|-------|-------------------------------|
| Backend | Go 1.27.4 declared; Gin, GORM, Eino and numerous provider/cloud SDKs |
| Frontend | React/TypeScript, Vite, Ant Design; Jest, type-check and lint scripts |
| Ingestion | Parser dispatch, chunker, tokenizer, model-assisted extraction; native DeepDoc/ONNX resources |
| Metadata | MySQL default; other SQL configurations supported |
| Retrieval | Pluggable engines including Elasticsearch and Infinity; sparse/dense and reranking paths |
| Persistence | Object storage plus engine/SQL volumes; Kvrocks and NATS services |
| Agents | Workflow/runtime/tool layers; local, SSH, self-managed and hosted execution providers |

## Key Features

### 1. Ingestion is a real pipeline, not just upload-and-embed

Parser dispatch carries configured parser families and output metadata across component boundaries. `EmbedChunkText` strips table-structure tags, applies model-window trimming, checks vector counts and merges title/content embeddings. Importantly, its documented parity is limited to text embedding: edited chunk text does not recreate custom question/summary fields from an ingestion configuration. Operators should test re-edit/reparse consistency rather than assuming all derived indexes update identically. The idempotency key includes task, pipeline/component versions and an input fingerprint, a useful design signal but not by itself proof of exactly-once ingestion. [E4]

### 2. Retrieval has explicit bounded contracts

The shared retrieval service handles hybrid search, reranking, thresholds, pagination and readable-document filtering. It caps rerank candidates at 1,024, KNN top-k at 2,048 and KNN candidates at 10,000; a configured reranker supports only the first page. Score tests exercise token-field effects and backend-specific scoring behavior. These are substantive correctness mechanisms, not evidence that every engine produces interchangeable relevance scores. The `DocumentPermissionsChecked` flag and identity-dependent filtering make correct upstream authorization essential. [E5]

### 3. Citations improve traceability, not entailment

The chat pipeline repairs malformed citation markers, extracts bounded source indices, and avoids double-tagging existing model citations. When citations are missing and embeddings are available, `InsertCitations` compares answer-sentence vectors with chunk vectors, descends a similarity threshold from 0.63 toward 0.3 and attaches up to four chunks. An embedding error returns the answer without inserted citations. A semantically similar passage can contradict a sentence or omit its decisive detail; this fallback does not establish that the sentence is true. Citation coverage and source support need independent evaluation, especially for numbers, negations and multi-part claims. [E6]

## Architecture

The bounded path inspected is: parser dispatch → embedding/chunk representation → shared retrieval and permission policy → chat citation decoration. Agent tools and selectable execution providers extend this with retrieval, remote HTTP/SQL/MCP and code execution. SQL metadata, document indexes and object storage are separate state domains; the UI is not the authorization boundary. [E2, E4–E9]

### Tenant authorization: promising policy, incomplete endpoint assurance

`AuthMiddleware` resolves access/API tokens and installs user/tenant identity in request context. The community policy rejects missing identities, loads persisted ownership and membership facts, derives scope from the actual resource rather than a caller-selected active tenant, and checks dependencies for both the user and the entry owner. Tests cover these cases. Community `CheckFeature` explicitly has no role-based feature restrictions: resource authorization should not be confused with enterprise-style feature RBAC. [E7]

Public, beta-authenticated and ordinary authenticated route groups exist separately, including webhooks, sharing and preview surfaces. This review did not trace every endpoint, background task, share token, connector or enterprise build. No cross-tenant exploit was demonstrated; equally, the inspected policy cannot certify complete tenant isolation. Require a two-tenant negative test matrix covering search, downloads, previews, agent dependencies, shares and deletion before shared deployment. CORS and reverse-proxy behavior were not comprehensively audited.

### Agent execution: the word sandbox is not a guarantee

The local provider uses `os/exec` on the host with the Go process privileges and explicitly states that it is not sandboxed. Time, memory and output limits do not turn that into a security boundary. The optional self-managed manager configuration is privileged and mounts the Docker socket; it binds the host listener to loopback and defaults unauthenticated access off, but the actual separately built image and host isolation still require verification. Do not expose local execution to untrusted users or assume a prompt can reliably keep tools safe. [E8]

HTTP tool helpers contain useful SSRF defenses: HTTP(S) scheme restriction, rejection of non-public addresses, all-answer DNS checks and a pinned-IP transport design. `ALLOW_ANY_HOST` relaxes the private-host restriction. These safeguards are not a universal guarantee for all providers, MCP servers, redirects or connectors; network egress policy remains necessary. Prompt injection from retrieved documents can influence an agent even when URL validation works correctly. [E9]

### Secrets, provider egress and privacy

The model instance entity has an `api_key` string column, and the inspected creation path writes the supplied key into that entity without an application-encryption step. Separately, connector credential encryption uses AES-GCM only when `RAGFLOW_CONNECTOR_KEY` is configured; an unset key leaves credentials unchanged. Protect database backups and keep the connector encryption key recoverable separately. This is a distinction between credential classes, not a claim that every secret uses the same storage mechanism. [E10]

Provider discovery accepts an API key in a query parameter, creating a URL/access-log handling concern. The retrieval service logs question text at INFO, so operational logs are part of the data-retention boundary. Embeddings can send document text, rerankers send query/candidate text, and chat/vision/hosted code providers receive their configured payloads. Self-hosting the UI does not imply offline processing or zero provider retention. Establish destination allowlists, provider terms, log redaction/retention and least-privilege credentials; audit telemetry and connector-specific flows separately. [E5, E10]

## Self-Hosting Notes

The README recommends starting at 4 CPU cores, 16 GB RAM and 50 GB disk, with additional capacity for models and concurrent parsing. Treat this as a starting recommendation, not a tested sizing result. Compose publishes web/API/admin and several backing-service ports without loopback binding, includes example database/object-store passwords and disables Elasticsearch HTTP/transport TLS in the illustrated stack. The explicit warning to change passwords is welcome but not enforcement. Pin release images/digests, close unnecessary host ports, restrict admin ingress, terminate TLS and verify registration/authentication policy before importing sensitive data. [E1, E8]

### Persistence, backup, deletion and recovery

Named volumes cover SQL, object storage, indexes and queue/cache services. Back up these stores consistently with configuration, model identity and encryption material; a metadata-only dump cannot reconstruct original documents or guarantee equivalent embeddings. Do not confuse a volume surviving container recreation with a tested disaster-recovery plan. [E8]

`RemoveDocumentKeepFile` settles ingestion work, removes engine data and updates metadata/version records, while intentionally keeping the file/blob. `RemoveBlob` survives caller cancellation and retries up to three times within a 30-second cleanup context. These are useful cleanup mechanisms, but the inspected operations span stores rather than one global transaction. A deletion request, file unlink, index purge and backup expiry are different events. Define and test reconciliation for failed cleanup, worker interruption and partial restore; verify erasure of previews, compiled artifacts, logs and retained backups according to policy. No crash recovery, backup restoration, migration rollback or deletion-completeness experiment was run. [E11]

## Maturity, Tests and Benchmark Evidence

There are meaningful unit/integration test sources for citation formats, retrieval scoring, tenant policy, SSRF and cleanup failure cases. The `sep-tests` workflow describes self-hosted CI and SDK testing against Elasticsearch/Infinity; PR runs depend on labels/conditions. Its actual trigger is `pull_request`, despite an adjacent stale comment about `pull_request_target`. Workflow configuration is not a passing-run receipt; current CI status and coverage were not established. [E12]

The checked benchmark metrics measure first-token/total latency, percentiles, request throughput, successful throughput and failure rate. That helps operational evaluation but does not establish semantic retrieval quality or citation entailment. The agent-native-database document reports 85% BrowseComp-Plus, 91% FRAMES and a 38% average query-token reduction in the authors’ runs. These remain upstream claims: this review did not verify full run traces, exact benchmark/model settings, statistical uncertainty or independent replication. In particular, “largely solved the accuracy problem” is not justified for arbitrary enterprise documents by these reported scores. [E3, E13]

A useful acceptance suite would include difficult scanned tables, stale/replaced documents, multilingual queries, denied tenant access, malicious document instructions, citation contradictions and provider outages. Measure recall and answer support alongside cost, latency and cleanup/restore behavior on the actual deployment configuration.

## Licensing and Supply Chain

The root Apache-2.0 license permits commercial reuse with its notice, attribution and modification obligations and patent terms; it does not grant blanket rights to bundled models or third-party services. The tree has Go/Python/frontend dependency manifests and lock data, native bindings, optional database engines and container dependencies. The base image imports DeepDoc/model/tokenizer assets from a dependency image tagged `latest`, and optional runtime images also use mutable tags. A source SHA therefore does not uniquely identify all deployed bytes. [E2, E14]

No transitive SBOM/license audit, vulnerability scan, native-library audit or model-card review was performed. Confirm every selected model’s redistribution/commercial-use terms and every container component’s license before redistribution. Enterprise hooks visible in community source are not evidence that enterprise functionality or commercial terms are included.

## Comparison

These are architectural alternatives, not head-to-head benchmark results.

| Aspect | RAGFlow | Alternatives / tradeoff |
|--------|---------|------------------------|
| Integrated document platform | Parsing, retrieval, UI and agent workflows together | [Dify](https://github.com/langgenius/dify): application/workflow-centric; compare current license and ingestion behavior independently |
| Programmable retrieval | Extensive built-in system, more operational surface | [Haystack](https://github.com/deepset-ai/haystack) or [LlamaIndex](https://github.com/run-llama/llama_index): more application control, more assembly/integration ownership |
| Search substrate | Multiple storage backends plus ingestion and chat | [Qdrant](https://github.com/qdrant/qdrant) or PostgreSQL/pgvector: narrower storage layer, not replacements for parsing/citations/auth UI |

**Recommendation:** Evaluate RAGFlow when heterogeneous-document ingestion and an integrated team workflow justify its service footprint. Prefer a library-based pipeline for a small, tightly governed application where explicit data flows and a minimal execution surface matter more than a full product UI. Keep agents disabled or isolated until execution permissions, egress and adversarial-document tests are satisfactory.

## Scope and Evidence

All source citations below are pinned to the reviewed SHA. Inspection was selective, not an exhaustive security assessment: representative implementations and tests were read; frontend behavior, every parser/provider/backend, enterprise code and production binaries were not audited. Source tests were not run. Artifact-only validation checks formatting, source-link paths and trusted-template integrity; it cannot establish RAGFlow runtime correctness.

- **E1:** [`README.md`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/README.md)
- **E2:** [`go.mod`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/go.mod); [`pyproject.toml`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/pyproject.toml); [`web/package.json`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/web/package.json)
- **E3:** [`docs/basics/agent_native_database.md`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/docs/basics/agent_native_database.md)
- **E4:** [`internal/ingestion/component/parser_dispatch.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/ingestion/component/parser_dispatch.go); [`internal/ingestion/component/embed_chunk.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/ingestion/component/embed_chunk.go); [`internal/ingestion/component/idempotency.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/ingestion/component/idempotency.go)
- **E5:** [`internal/service/nlp/retrieval.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/service/nlp/retrieval.go); [`internal/service/nlp/retrieval_score_test.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/service/nlp/retrieval_score_test.go)
- **E6:** [`internal/service/citation.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/service/citation.go); [`internal/service/chat_pipeline.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/service/chat_pipeline.go); [`internal/rag/prompts/citation_prompt.md`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/rag/prompts/citation_prompt.md)
- **E7:** [`internal/handler/auth.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/handler/auth.go); [`internal/router/router.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/router/router.go); [`internal/permission/policy.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/permission/policy.go); [`internal/permission/policy_test.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/permission/policy_test.go)
- **E8:** [`internal/agent/sandbox/local.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/agent/sandbox/local.go); [`docker/docker-compose.yml`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/docker/docker-compose.yml); [`docker/docker-compose-base.yml`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/docker/docker-compose-base.yml); [`docker/.env`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/docker/.env)
- **E9:** [`internal/agent/tool/ssrf.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/agent/tool/ssrf.go); [`internal/agent/tool/http_helper.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/agent/tool/http_helper.go)
- **E10:** [`internal/entity/tenant_model_instance.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/entity/tenant_model_instance.go); [`internal/service/model_service.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/service/model_service.go); [`internal/common/connector_credentials.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/common/connector_credentials.go); [`internal/handler/providers.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/handler/providers.go); [`docs/guides/models/llm_api_key_setup.md`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/docs/guides/models/llm_api_key_setup.md)
- **E11:** [`internal/service/document/document_crud.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/service/document/document_crud.go); [`internal/storage/remove.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/storage/remove.go); [`internal/service/document/document_test.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/service/document/document_test.go)
- **E12:** [`.github/workflows/sep-tests.yml`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/.github/workflows/sep-tests.yml); [`internal/service/citation_test.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/service/citation_test.go); [`internal/agent/tool/ssrf_test.go`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/internal/agent/tool/ssrf_test.go)
- **E13:** [`test/benchmark/metrics.py`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/test/benchmark/metrics.py)
- **E14:** [`LICENSE`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/LICENSE); [`Dockerfile_base`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/Dockerfile_base); [`deps/download_deps.py`](https://github.com/infiniflow/ragflow/blob/625a53ad4c4ecb66abe32b4c0745564eaddeec94/deps/download_deps.py)
- **Metadata:** [anonymous repository API](https://api.github.com/repos/infiniflow/ragflow), [latest release API](https://api.github.com/repos/infiniflow/ragflow/releases/latest), retrieved 2026-11-26 UTC.

---

**Attribution:** InfiniFlow / infiniflow/ragflow, Apache-2.0. This review is independent analysis; no source code or model weights are redistributed.
