# Context Ontology Accelerator (aws/context-ontology-accelerator)

**Repo:** https://github.com/aws/context-ontology-accelerator
**Owner:** AWS / Amazon.com, Inc. or its affiliates
**License:** Apache-2.0; preserve license, NOTICE and modification notices on redistribution. Dependencies have separate terms, including owlready2 LGPL-3.0.
**Reviewed:** 2026-11-27 (UTC)
**Revision:** 5dd33d7eb21d9af3de8fe4f03558eca992a4104a — main and v0.3.11 resolve to this commit. Scope: manifests, induction/validation/acceptance, document ingestion, Serve authorization/query/session code, token authorization, CDK stacks, deployment/teardown and public CI.
**Verification:** Static review only. Anonymous metadata, HTTPS clone and release ref checked; no source execution, installations, cloud provisioning, paid calls, application tests or live service probes.
**Stack:** Python 3.12, FastAPI, TypeScript, React/Cloudscape, Smithy, CDK, RDFLib/OWL/SHACL, Ontop, GraphRAG Toolkit/LlamaIndex, Bedrock, Neptune, OpenSearch Serverless.
**Metadata snapshot:** 1,334 stars, 167 forks; GitHub open-issues counter 57 (includes PRs). Last push 2026-11-19; latest listed release v0.3.11 published 2026-11-19. Popularity is not correctness evidence. [Metadata](https://api.github.com/repos/aws/context-ontology-accelerator) · [Release](https://github.com/aws/context-ontology-accelerator/releases/tag/v0.3.11).

---

## Verdict

⚠️ **Interesting — substantial AWS semantic infrastructure, not a turnkey correctness engine.** Scan → Model → Serve joins metrics, ontology-mediated structured queries and document GraphRAG behind real authorization machinery. Acceptance explicitly disables optional tier-1 validation, several semantic checks are incomplete or optional, and deployment has significant standing cost and destructive teardown behavior. Pilot with synthetic data and domain-specific correctness tests before trusting answers as business authority.

## What It Is

COA provides context across relational sources and documents. Scanning discovers schemas and enriches metadata; modeling generates/reviews ontologies and mappings; serving combines metrics, structured retrieval and graph/vector context through REST, streaming playground and MCP. It is not merely a vector database wrapper or a general autonomous action executor. [README](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/README.md)

Its useful separation is between semantic model (OWL/RDF classes, properties and relational mappings), lexical graph extracted from documents, and policy controlling source/SQL access. These are not interchangeable proofs: logical consistency does not prove a fact true, an SQL answer correct or an action safe.

## Stack

| Layer | Tech |
|-------|------|
| Contracts/UI | Smithy-generated clients/interfaces; React + Cloudscape |
| Services | Python/FastAPI; Lambda, ECS/Fargate, AgentCore |
| Semantics | RDFLib, owlready2/HermiT, pySHACL; Ontop/R2RML |
| Documents | GraphRAG Toolkit + LlamaIndex; Bedrock extraction/embeddings |
| State | Neptune Database/Analytics adapters; OpenSearch; S3; DynamoDB; AgentCore Memory |
| Policy | Cognito/external OIDC, namespace/platform RBAC, Cedar, SQL AST firewall |
| Build | CDK, Nx, uv/pnpm locks; Java/Gradle/Maven |

Sources: [layout](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/README.md), [workspace](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/pyproject.toml), [storage](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/infra/lib/stacks/foundation/storage-stack.ts).

## Key Features

### Schema grounding and virtual queries

Default table-to-ontology embeds schema terms, matches grounding vocabularies, emits classes/properties and records similarity confidence. That is not calibrated truth probability. RIGOR retrieves ontology context, generates Turtle with an LLM and has another LLM judge/refine it: assistance, not an independent oracle. [Default strategy](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/inducer/strategies/table_to_ontology.py) · [RIGOR](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/inducer/strategies/rigor_ontology.py)

Accepted ontologies/R2RML feed Ontop queries over source data. Acceptance is asynchronous with retriable ingest/embedding/storage steps; VKG notification is non-fatal, so acceptance does not prove serving synchronization. The ontology README warns that only OpenSearch+Neptune writes the mapped-class marker needed for Tier-2 structured queries; Analytics-only falls back to Tier 3. [Acceptance](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/proposals.py) · [Backend caveat](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/README.md)

### Extracted context is not ground truth

The document build task reads preprocessed S3 text/metadata, wraps LlamaIndex Documents and invokes GraphRAG Toolkit to populate Neptune and OpenSearch. It supports corpus-derived entity classes, preferred topics, propositions, chunk tuning and Bedrock batch inference. Defaults enable versioning and retain older versions. Extra extraction passes/retries add inference work, not evidence of fidelity. [Implementation](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/sources/src/coa_sources/documents/kg_build/graph_build.py)

Unstructured ontology induction remains v0: entailment is a pass-through even when requested, normalizer state is not persisted across runs, datatype properties can be sparse, and the pipeline does not invoke the three-tier validator. These limits appear in warnings. [Pipeline](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/inducer/unstructured/services/pipeline.py) · [Limits](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/README.md)

### Validation is narrower than certification

- **No mandatory semantic gate:** proposal acceptance passes validate=False; ingest also defaults false. Separate validation endpoints exist, but a UI workflow is not an enforced publication policy. [Accept call](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/proposals.py#L1424) · [Ingest](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/catalog/ingest.py)
- **HermiT sees a transformed graph:** imports are stripped and unsupported/malformed XSD types substituted on a throwaway copy. Reasoner errors block the report, but success does not certify the original graph plus imported axioms. [Tier 1](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/validation/validators/tier1.py)
- **SHACL needs supplied shapes:** no shapes means no findings. OntoQA-style metrics score structure, not truth. [Tier 1](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/validation/validators/tier1.py) · [Tier 2](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/validation/validators/tier2.py)
- **Competency questions are a stub:** CQ_NOT_EVALUATED is informational. OoPS! is opt-in; service failures are informational and important/critical pitfalls are warnings. Overall passed means no errors among requested checks, not that all intended checks ran. [Tier 3](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/validation/validators/tier3.py) · [Aggregation](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/validation/routers/validate.py)

## Architecture

Sources → discovery/preprocessing → enriched catalog + lexical graph → proposals → catalog/embeddings + S3 mappings → Ontop/VKG → Serve/MCP.

Serve combines curated metrics, structured queries and graph/lexical retrieval under deadlines. The SQL firewall validates ASTs: SELECT-only shapes, dangerous/table-function restrictions, table allowlists and column denylists; parsing uncertainty is denied. **Row-level filtering is explicitly not implemented here.** Use database-native row security and least-privileged source credentials where row visibility matters. [Firewall](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/context-manager/src/coa_serve/tier2/sql_firewall.py) · [Orchestrator](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/context-manager/src/coa_serve/orchestrator.py)

REST, streaming and MCP differ operationally. The guide documents roughly 28 seconds of application budget below API Gateway’s 29-second REST ceiling, while translation/full requests can have longer budgets. Increasing downstream timeouts cannot remove this ceiling. Source latency/accuracy observations were not reproduced. [Deployment constraints](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/external-docs/content/deploying.md)

## Security and Data Boundaries

### Identity, IAM and secrets

Namespace and platform-wide roles are distinct. Shared token authorization restricts algorithms to RS256 and supports issuer/audience checks; external OIDC audience needs explicit configuration review. Serve intentionally decodes JWTs without checking signatures because AgentCore verifies upstream. This is a deployment trust boundary, **not itself a demonstrated bypass**: do not expose that handler directly without equivalent verification. [Token authorizer](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/libs/common/src/coa_common/auth/token_authorizer.py) · [Serve identity](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/context-manager/src/coa_serve/auth.py)

Secrets Manager references are checked at registration and scan time for in-account namespace-tag membership, failing closed on uncertainty. Shared-role IAM can check tag presence but not per-request membership: stronger isolation is application-enforced. Cross-account sources need separate trust/permissions. Prove these boundaries with negative tests before multi-tenant use. [Secret binding](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/sources/src/coa_sources/database/secret_binding.py) · [Cross-account guide](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/external-docs/content/cross-account-sources.md)

Initial deployment asks for administrator-equivalent permissions. Runtime grants are often scoped, but wildcard-resource permissions remain where services require them. Notably the ontology task receives aws-marketplace:Subscribe, enabling account-wide first-use model subscription. Review entitlement/spend governance, not just inference permissions. [Ontology role](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/infra/lib/stacks/services/ontology-stack.ts#L445)

### Network and provider egress

Neptune uses private subnets, IAM authentication and encryption; OpenSearch restricts its network policy to a VPC endpoint. This is **not air-gapped**: the new VPC has NAT, the authorizer permits all outbound traffic for external IdP JWKS, and connector/database connectivity has separate rules. Imported VPCs require operator-supplied connectivity. [Storage](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/infra/lib/stacks/foundation/storage-stack.ts) · [Network](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/infra/lib/stacks/foundation/network-stack.ts)

Schemas/descriptions, documents, prompts and retrieved context enter configured Bedrock processing paths. Default geographic inference profiles can route across regions. Account/model availability needs independent checking; embedding model/dimension changes require migration. Provider retention/residency guarantees were not independently verified.

OoPS! has no default public endpoint: unset means no request. Enabled means ontology labels/comments/literals are serialized and POSTed to the configured service. Approve egress or use a controlled instance. Guardrails add filtering, not prompt-injection proof; the guide warns of default Classic-tier language limitations. [OoPS!](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/ontology-engine/src/coa_ontology/validation/validators/tier3.py) · [Configuration](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/external-docs/content/deploying.md)

### Retention and observability

AgentCore Memory stores conversation content with **30-day expiration**; DynamoDB session metadata has separate TTL. Staging/artifacts, older versions, graph/vector indexes, backups and logs have different lifecycles. One TTL or source deletion is not immediate erasure of all copies: inventory retention and test with synthetic canaries. [Serve stack](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/infra/lib/stacks/services/serve-stack.ts#L403) · [Document versions](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/packages/sources/src/coa_sources/documents/kg_build/graph_build.py)

Connector-integrity detection requires an account CloudTrail trail the deployment does not create. The guide says alarm actions are unwired: an alarm object without delivery is not operational alerting. [Prerequisites](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/external-docs/content/deploying.md)

## Self-Hosting Notes

This is an AWS deployment, not a free local app. The documented path builds multi-architecture images and provisions 17 platform stacks plus a managed Databricks connector. It needs substantial toolchains, quotas, model access and region compatibility. The project recommends tagged releases and says only us-east-1 has been deployment-validated. No deployment was attempted. [Guide](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/external-docs/content/deploying.md)

**Cost:** Neptune defaults to one db.r8g.large; OpenSearch collection-group settings default to minimum 2 and maximum 96 OCU. The guide estimates about $200/month for Neptune and $700/month for the default OpenSearch floor in us-east-1. These are source estimates, not independently verified current prices or total cost. NAT/endpoints, per-namespace Fargate, AgentCore, model calls, Athena scans, logs/storage add more. OpenSearch scale-to-zero affects latency and does not make the whole platform zero-idle-cost. Set budgets, quotas and tested alerts. [Capacity](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/infra/lib/stacks/foundation/storage-stack.ts) · [Cost discussion](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/external-docs/content/deploying.md)

**Deletion/recovery:** Neptune has seven-day backups but DESTROY removal policy; deletion protection applies only to the exact prod environment. Dev teardown deletes data, force-deletes DataZone and cleans dynamic ECS/Cloud Map/connector resources. AgentCore ENIs can delay final cleanup up to eight hours; the script distinguishes deferred cleanup from failure. Plain CDK destroy is insufficient. An account-wide API Gateway logging role/setting can remain and affect other APIs. Backups are not a tested restore plan: export/snapshot and rehearse recovery before destruction, inspecting retained logs/buckets and external sources separately. [Storage lifecycle](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/infra/lib/stacks/foundation/storage-stack.ts) · [Script](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/scripts/destroy.sh) · [Teardown](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/external-docs/content/deploying.md#tearing-down)

## Maturity, Dependencies and Verification

Static enumeration found 465 Python test files under package test trees and 53 TypeScript test.ts-suffix files under infra: file counts, not passing tests or coverage. Public PR CI declares lint, units and CDK synth with read-only permissions and pull_request rather than privileged target execution. It acknowledges Nx affected-graph gaps and uses a fuller merge-group suite; internal live-account integration is not ported. Inspected Actions use version tags rather than immutable SHAs. **No CI success, vulnerability scan, integration coverage or benchmark was independently reproduced.** [Workflow](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/.github/workflows/pr.yml) · [Configuration](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/pyproject.toml)

This is a read-only mirror, not accepting external PRs; public issues are a feedback path. Lockfiles/security constraints signal maintenance, not a clean bill of health. NOTICE lists owlready2 LGPL-3.0 and aiohttp 3.14.3, while the current Python constraint requires aiohttp at least 3.14.4: check inventories against built images rather than assuming synchronization. Apache-2.0 at the root does not erase dependency obligations. [Contributing](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/CONTRIBUTING.md) · [License](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/LICENSE) · [NOTICE](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/NOTICE) · [Constraints](https://github.com/aws/context-ontology-accelerator/blob/5dd33d7eb21d9af3de8fe4f03558eca992a4104a/pyproject.toml)

**Review checks:** anonymous repository/release identity, canonical deduplication, source-path citations, Markdown/HTML/index consistency, template CSS/JS preservation, markup/internal references, safe links, unresolved tokens, redaction and task-only diff. Application tests were deliberately not run because installations, source execution and cloud/live calls were out of scope. These are static findings, not exploit confirmations or performance claims.

## Comparison

| Option | Best fit | Tradeoff relative to COA |
|--------|----------|-------------------------|
| [Ontop](https://github.com/ontop/ontop) | Virtual RDF/SPARQL over relational databases | Narrower existing engine; supply identity, ingestion and agent orchestration |
| [AWS GraphRAG Toolkit](https://github.com/awslabs/graphrag-toolkit) | Document graph/vector retrieval | COA’s lexical building block without its full ontology/control plane |
| [RDFLib](https://github.com/RDFLib/rdflib) + [pySHACL](https://github.com/RDFLib/pySHACL) | Local RDF processing and explicit constraints | Smaller footprint, not an integrated multi-user platform |

These are scope comparisons, not head-to-head tests or fresh audits. Prefer Ontop for structured-only needs or GraphRAG Toolkit for documents alone; adopt COA when the combined workflow justifies its AWS footprint.

## Adoption Gates

1. Require an explicitly scoped successful validation report before publication; separately test extraction and answers on held-out domain questions.
2. Prove namespace, secret-tag, table/column and source-row authorization with negative tests; preserve upstream authentication boundaries.
3. Approve data destinations, model regions, retention and optional OoPS! egress. Start with synthetic data.
4. Price idle/loaded operation, wire alarms and rehearse teardown plus restore. Verify serving synchronization, not merely acceptance.

---

**Attribution:** AWS, [aws/context-ontology-accelerator](https://github.com/aws/context-ontology-accelerator), Apache-2.0. Independent static analysis; no source code redistributed.
