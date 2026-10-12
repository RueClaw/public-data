# langchain-typesafe (langchain-ai/langchain)

**Repo:** https://github.com/langchain-ai/langchain/tree/master/libs/partners/typesafe
**License:** MIT adapter; hosted service separate; see license details below for reuse obligations.
**Reviewed:** 2026-10-12 (UTC)
**Revision:** `e4b143729ffb3c6307376909d3aa9921b360c1f5`
**Scope:** ONLY libs/partners/typesafe plus relevant shared CI/package context
**Verification:** Static source review only. No source code, installs, tests, builds, generated pages or benchmarks executed. Any upstream CI result is separately attributed.
**Stack:** Python · LangChain Runnable · httpx2
**What it is:** Scoped TypeSafe classifier integration with experimental model routing and probabilistic tool screening.

---

## Verdict

⚠️ **Interesting.** Interesting for controlled classification and routing, not as a standalone security gate. Keep deterministic permissions and human approval independent, and review provider/tracing exposure before sending sensitive state.

## Update Notes

Checked 2026-10-12 UTC. Previous review dated 2026-10-11 had no exact revision. Rating remains Interesting; material corrections clarify custom endpoint support versus self-hosted backend availability, opt-in tool coverage, fixed threshold/context window, response consistency and traceback risks. The earlier 91-test local claim is historical and was not reproduced for this SHA. This is not a review of the full LangChain repository.

## What It Is

Scoped TypeSafe classifier integration with experimental model routing and probabilistic tool screening. Noul, Choice and Score questions flow through a sync/async Runnable with structured responses, tracing and LangChain errors.

## Stack

| Layer | Technology |
|---|---|
| Implementation | Python · LangChain Runnable · httpx2 |
| Reviewed boundary | ONLY libs/partners/typesafe plus relevant shared CI/package context |

## Key Features

### Typed composition

Noul, Choice and Score questions flow through a sync/async Runnable with structured responses, tracing and LangChain errors.

### Screening is not authorization

AutoMode bypasses unlisted tools and classifies selected calls with a fixed 0.5 threshold over the last 30 messages. False negatives can execute.

### Provider and error boundaries

Arguments and conversation leave the process. Response consistency checks and exception-chain redaction need application-level attention.

## Architecture, Evidence and Security

## Identity and architecture
This is a small Python LangChain integration for TypeSafe's hosted probabilistic classifier, NOT a local model, general type checker, or standalone security engine. Version 0.0.1a3, Python >=3.10,<4, Hatchling, runtime httpx2 >=2,<3 and langchain-core >=1.6.2,<2; optional experimental extra adds langchain >=1.3.15,<2. Source uses transitive Pydantic/LangSmith dependencies and workspace editable sources for development. [manifest](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/pyproject.toml#L1-L63).

TypeSafeClassifier is a RunnableSerializable: typed Noul (binary probability), Choice (categorical distribution), Score (ordinal expectation) questions plus recursively normalized JSON/LangChain message state -> synchronous/asynchronous httpx2 POST /v1/systemone -> Pydantic response objects, LangChain-standard exception subclasses, tracing and token metadata. Default provider https://api.typesafe.ai, floating model jev-latest, timeout 30s. SecretStr API key is excluded from representation/serialization. Both HTTP clients are created, and callers must close clients for deterministic cleanup. [classifier](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/classifier.py#L36-L69); [transport](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/classifier.py#L355-L450); [state conversion](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/_state.py#L15-L52).

Optional middleware: ModelRouter classifies the latest HumanMessage once before each agent run and retains ChoiceAnswer in state to select a preconfigured model; AutoMode classifies selected tool calls using their raw arguments, description and last 30 messages and blocks risk >=0.5 with an error ToolMessage. Classification exceptions propagate before tool execution. No approval UI, sandbox, or deterministic authorization engine is provided. [routing](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/experimental/middleware/model_router.py#L136-L209); [tool gating](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/experimental/middleware/auto_mode.py#L169-L265).

## Five findings
1. **Security boundary: useful supplementary screening, not authorization.** Unlisted tool names bypass classification outright; the list is opt-in and not checked against the agent's full inventory. Decisions are probabilistic at a hard-coded 0.5, with only the last 30 messages (older prohibitions/authorization may disappear). Prompt instructions say tool data is untrusted, but that is not demonstrated injection resistance. Errors fail closed, a positive property, but false-negative classifications execute tools. Keep independent permissions, human approval for irreversible actions, and execution isolation. Threshold is mentioned in docstrings but not exposed by the constructor. [implementation](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/experimental/middleware/auto_mode.py#L38-L47); [window](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/experimental/middleware/auto_mode.py#L169-L182); [bypass and threshold](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/experimental/middleware/auto_mode.py#L223-L234); [tests confirming bypass/fail-closed](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/tests/unit_tests/experimental/middleware/test_auto_mode.py#L245-L334).

2. **Privacy: risk assessment itself exports sensitive context.** Complete selected-tool arguments and recent conversation are transmitted to TypeSafe before a call can be blocked. Core Runnable tracing intentionally receives state AND questions; middleware omit_payload applies to its own trace inputs, not evidence that nested classifier inputs are scrubbed. Trace configuration and provider retention require explicit review. TYPESAFE_BASE_URL/custom base_url is accepted with no HTTPS/host allowlist while requests always attach the bearer key: only trusted configuration may set it. These are architectural exposure risks, not evidence of an observed leak. [context](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/experimental/middleware/auto_mode.py#L139-L182); [full Runnable input](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/README.md#L47-L50); [URL configuration](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/classifier.py#L188-L201); [authorization header](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/classifier.py#L425-L450).

3. **Error sanitization is partial: exception chains retain raw validation inputs.** APIError str/repr intentionally omit bodies and strip URL credentials/query, which is good. However malformed-success parsing raises its sanitized wrapper 'from error', preserving the Pydantic ValidationError as a cause; ordinary chained tracebacks can include invalid response input values. APIError also retains raw body/headers in attributes and Exception.args. Tests verify str/repr and field paths, not complete formatted exception chains. Avoid logging full exception chains/objects for sensitive classifications, or redact them. This is a static code-path finding, not dynamically reproduced. [safe formatting/raw storage](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/client.py#L38-L105); [chaining](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/client.py#L329-L344); [tests](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/tests/unit_tests/test_errors.py#L84-L109); [validation test](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/tests/unit_tests/test_errors.py#L151-L166).

4. **Schema validation does not establish response/request consistency.** Noul and confidence fields have 0..1 constraints, but Choice/Score probability entries are plain floats without normalization/range checks; choice is arbitrary string and score unbounded. Response parser receives no original questions, so cannot verify expected IDs/types or whether selected labels were offered. Router indexes self.models[answer.choice] directly; unknown label/missing answer produces KeyError rather than a controlled fallback. No HumanMessage produces next() exhaustion. Validate expected keys/labels/distributions at application boundaries and define explicit abort/fallback policy. [schemas](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/types.py#L215-L301); [parser](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/client.py#L313-L347); [router](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/langchain_typesafe/experimental/middleware/model_router.py#L154-L209).

5. **Promising engineering scaffolding, immature operational evidence.** Sync/async unit tests cover mock HTTP requests, callbacks/traces, nested message conversion, status mappings, allowed/blocked calls, bypass and classifier-failure termination. Makefile disables sockets and tracing credentials in unit tests; shared CI runs unit tests/current-min dependencies and compilation-only integration checks. Live tests exist, but typesafe is only a manual integration-workflow choice and is absent from DEFAULT_LIBS, so the daily schedule does not automatically prove its live provider behavior. Version is an alpha despite Beta classifier; middleware explicitly unstable, default model floats, classifier has no retry loop, and long-lived client ownership is manual. Pin model/package, add live/adversarial evaluation and backoff outside this adapter. [Makefile](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/Makefile#L5-L16); [CI unit setup](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/.github/workflows/_test.yml#L46-L72); [compile-only](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/.github/workflows/_compile_integration_test.yml#L47-L53); [manual choice/default list](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/.github/workflows/integration_tests.yml#L21-L74); [live test](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/tests/integration_tests/experimental/middleware/test_auto_mode.py#L35-L91); [stability warning](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/README.md#L62-L67).

## License
Actual package LICENSE is MIT, copyright 2026 LangChain, Inc.; permits commercial use/modification/distribution, requires preserving copyright and permission notice in copies/substantial portions, disclaims warranty. [license](https://github.com/langchain-ai/langchain/blob/e4b143729ffb3c6307376909d3aa9921b360c1f5/libs/partners/typesafe/LICENSE#L1-L21). That licenses the adapter, not TypeSafe hosted service/model weights, service pricing, retention guarantees, or third-party dependencies. No claim of offline availability or free hosted inference.

## Public metadata (repository-wide, not package adoption)
GitHub API: 147,649 stars, 24,763 forks, 646 open_issues_count (includes PRs); pushed 2026-10-12T00:41:04Z; not archived. Latest repository release returned: langchain-core==1.6.9, 2026-10-08T20:11:32Z. Recent-release listing includes langchain-typesafe==0.0.1a3, 2026-09-20T18:54:54Z (earlier a1/a2 Sept 17). These repository totals are not evidence of package-specific maturity. No package-specific issue tally or CI run status verified.
Metadata endpoints: https://api.github.com/repos/langchain-ai/langchain ; https://api.github.com/repos/langchain-ai/langchain/releases/latest ; https://api.github.com/repos/langchain-ai/langchain/releases?per_page=100
Package release: https://github.com/langchain-ai/langchain/releases/tag/langchain-typesafe%3D%3D0.0.1a3


## Comparison

Use existing structured-output models for ordinary classification, direct TypeSafe APIs without LangChain overhead, and deterministic allowlists/human-in-the-loop controls for authorization. These are fit comparisons, not separately benchmarked or audited alternatives.

## Self-Hosting Notes

Adapter is local but default classification is hosted. A custom base URL is supported; that is not proof of a self-hosted TypeSafe backend. Trust endpoint configuration, pin model/package, control tracing, close clients and add retry/validation policy.

## Verification and Limitations

Public unauthenticated source acquisition and static inspection at the exact revision above. No runtime, exploit, performance, model-quality, dependency-vulnerability or distribution-provenance verification was performed. Review is sampled, not exhaustive; absence of an observed problem is not a security guarantee. Public metadata is a 2026-10-12 snapshot and not evidence of quality. Repository-wide popularity and releases must not be mistaken for package adoption or live-provider reliability.

---

**Attribution:** [langchain-ai/langchain](https://github.com/langchain-ai/langchain/tree/master/libs/partners/typesafe), MIT adapter; hosted service separate. Source claims and upstream status are distinguished from this review’s static findings.
