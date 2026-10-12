# AgentRun (Parcha-ai/agentrun)

**Repo:** https://github.com/Parcha-ai/agentrun
**License:** Apache-2.0; see license details below for reuse obligations.
**Reviewed:** 2026-10-12 (UTC)
**Revision:** `331e3109581528a6a433e8490be0448e77a59f87`
**Scope:** core packages/dsl in depth; root docs, manifests, spec and CI context; optional adapters not exhaustively audited
**Verification:** Static source review only. No source code, installs, tests, builds, generated pages or benchmarks executed. Any upstream CI result is separately attributed.
**Stack:** TypeScript · Node 22.19+ · TypeBox
**What it is:** Typed workflow DSL with host-owned model, decision, effect and code-execution adapters.

---

## Verdict

⚠️ **Interesting.** Interesting for controlled workflow infrastructure and its explicit uncertain-effect semantics. A valid workflow is not safe code: isolation, spending ceilings and durable effect reconciliation remain host responsibilities.

## What It Is

Typed workflow DSL with host-owned model, decision, effect and code-execution adapters. runNode, runJudge, runEffect and optional runCode separate orchestration mechanics from providers and policy.

## Stack

| Layer | Technology |
|---|---|
| Implementation | TypeScript · Node 22.19+ · TypeBox |
| Reviewed boundary | core packages/dsl in depth; root docs, manifests, spec and CI context; optional adapters not exhaustively audited |

## Key Features

### Explicit host seams

runNode, runJudge, runEffect and optional runCode separate orchestration mechanics from providers and policy.

### Validation can execute code

Default code validation and transforms use in-process JavaScript. Global shadowing is not a sandbox; untrusted definitions need nonexecuting inspection and isolated execution.

### Unknown is not failed

Uncertain side effects retain settlement information rather than encouraging blind retries. Hosts must persist receipts and reconcile actual outcomes.

## Architecture, Evidence and Security

Public GitHub REST metadata: 141 stars, 11 forks; created 2026-09-23T00:27:34Z; pushed 2026-10-12T04:47:53Z; not archived; main default. open_issues_count=26 includes pull requests; open issues endpoint filtered to actual issues yielded **2**, #10 and #29. /releases returned []; /releases/latest returned 404: no GitHub releases observed, which does not establish absence of npm releases. Metadata source: https://api.github.com/repos/Parcha-ai/agentrun ; https://api.github.com/repos/Parcha-ai/agentrun/issues?state=open&per_page=100 ; https://api.github.com/repos/Parcha-ai/agentrun/releases .

## Architecture
ESM Node >=22.19.0 package @parcha/agentrun-dsl, manifest version 0.1.0-beta.12, with only typebox 1.3.7 as its declared direct runtime dependency. JSON workflow v2 is validated and interpreted; typed authoring emits the document; schema checking guards inputs, intermediate submissions, and final outputs. Compositions include chain, map, parallel, bounded loops and child workflows. Agent/model work goes to runNode, actions to runEffect, typed decisions to runJudge, optionally code to runCode; host owns credentials, permissions, budgets and persistence. Separate Jev/Pi packages are integrations, not core requirements. [packages/dsl/package.json:1-59](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/package.json#L1-L59); [packages/dsl/src/workflow.ts:269-339](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/src/workflow.ts#L269-L339); [packages/dsl/src/workflow.ts:2558-2589](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/src/workflow.ts#L2558-L2589).



## Findings
1. **High-impact trust boundary: validation and code execution are not sandboxed.** compileTransform uses new Function and invokes the resulting expression in-process; shadowing globals is explicitly only lint/accident prevention. Dynamic import/eval and alternate global access are not prohibited. A malicious or runaway workflow could access host privileges or block the event loop; JSON validity is not safe execution. runWorkflow normally validates with code execution enabled. Mitigation: admit only trusted definitions; use inspectWorkflow for discovery, executeCode:false for untrusted validation, and a genuinely isolated host runCode executor with CPU/memory/network/filesystem limits. This is a documented boundary, not a newly demonstrated exploit. [packages/dsl/src/code-exec.ts:3-14](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/src/code-exec.ts#L3-L14); [packages/dsl/src/code-exec.ts:93-126](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/src/code-exec.ts#L93-L126); [packages/dsl/src/workflow.ts:2558-2569](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/src/workflow.ts#L2558-L2569). Positive: runCode switches off local validation probes and preserves core patch checks; regression tests explicitly cover both execution and dry-run seams. [packages/dsl/test/run-code-seam.test.mjs:16-31](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/test/run-code-seam.test.mjs#L16-L31); [packages/dsl/test/run-code-seam.test.mjs:74-107](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/test/run-code-seam.test.mjs#L74-L107).

2. **Resource/cost ceilings are host obligations, not enforced by the DSL.** Tests deliberately accept map.maxConcurrency=100000, very long calls and many retries; budgetUsd is only recorded/forwarded and comment explicitly says no runner stops on money. An agent-authored but valid workflow can cause request fan-out, long resource occupancy, or spending beyond expectations. Set hard host-level concurrency, request size, elapsed-time and spend admission limits before dispatch, rather than relying on document numbers. [packages/dsl/test/no-ceilings.test.mjs:1-5](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/test/no-ceilings.test.mjs#L1-L5); [packages/dsl/test/no-ceilings.test.mjs:28-55](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/test/no-ceilings.test.mjs#L28-L55); [packages/dsl/src/workflow.ts:286-288](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/src/workflow.ts#L286-L288); [packages/dsl/README.md:54-77](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/README.md#L54-L77).

3. **Good uncertain-effect semantics, but no automatic exactly-once guarantee.** runEffect receives idempotency keys and AbortSignal; cutoff creates EffectOutcomeUnknownError retaining a settlement promise if the adapter is still pending, and uncertainty is not classified as a routine retryable failure. This avoids a common duplicate-side-effect trap. Nevertheless the host must honor cancellation, persist receipts, reconcile effects and avoid retrying unknown outcomes. checkpointFailureMode defaults to legacy best_effort when omitted; choose required for persistence-critical runs. Flat graphs can memoize identical calls across iterations; polling requires call.poll or distinct operation identifiers. [packages/dsl/src/workflow.ts:1499-1581](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/src/workflow.ts#L1499-L1581); [packages/dsl/src/workflow.ts:331-338](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/src/workflow.ts#L331-L338); [docs/host-integration.md:22-36](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/docs/host-integration.md#L22-L36). Idempotency key forwarding alone does not make a remote API idempotent.

4. **Contracts and tests are unusually explicit, but prove shapes/mechanics, not decision truth.** Source validates final output and separates escalation from thrown failures. Representative tests cover nonexecuting validation, custom code boundaries, and pathological accepted resource settings. Nonexecuting validation can accept an expression that does not yield a function, by design; runtime is still authoritative. Synthetic demos are not quality evaluations of real provider models; confidence thresholds are not calibration guarantees. [packages/dsl/src/workflow.ts:2575-2589](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/src/workflow.ts#L2575-L2589); [packages/dsl/test/nonexecuting-validation.test.mjs:80-97](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/test/nonexecuting-validation.test.mjs#L80-L97); [packages/dsl/README.md:75-77](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/README.md#L75-L77); [README.md:135-150](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/README.md#L135-L150).

5. **Young beta with documentation/version drift; integration verification required.** Both root README and DSL README still say beta.4 while package manifest says beta.12. Security policy disclaims production support guarantees. CI config checks three Node versions, builds/types/tests/generated artifacts/package verification, with npm ci --ignore-scripts; a substantial positive, not proof of production reliability. The exact SHA public Actions query returned two successful Package checks runs and one in_progress at observation. Successful run: https://github.com/Parcha-ai/agentrun/actions/runs/38204231565 ; other success https://github.com/Parcha-ai/agentrun/actions/runs/38204231454 ; active https://github.com/Parcha-ai/agentrun/actions/runs/38204871554 . [README.md:148-154](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/README.md#L148-L154); [packages/dsl/README.md:3-5](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/README.md#L3-L5); [packages/dsl/package.json:1-6](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/packages/dsl/package.json#L1-L6); [SECURITY.md:11](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/SECURITY.md#L11); [.github/workflows/ci.yml:11-39](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/.github/workflows/ci.yml#L11-L39).

## License
Actual root LICENSE is Apache License 2.0, not merely a manifest claim; packages/dsl/LICENSE byte-matches root. NOTICE attributes Copyright 2026 Parcha Labs, Inc. Permissive commercial use/modification/distribution, with contributor patent grant and patent-litigation termination. Redistributors retain license and applicable notices/NOTICE and mark modified files; not an obligation to open-source the whole integrating application. Dependencies have their own terms; TypeSafe hosted API access is separate from this source license. [LICENSE:67-122](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/LICENSE#L67-L122); [NOTICE:1-2](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/NOTICE#L1-L2); [README.md:90](https://github.com/Parcha-ai/agentrun/blob/331e3109581528a6a433e8490be0448e77a59f87/README.md#L90).


## Comparison

Ordinary typed functions suit simple fixed flows; LangGraph fits existing LangChain orchestration; Temporal merits evaluation for durable long-running scheduling. These are fit comparisons, not separately benchmarked or audited alternatives.

## Self-Hosting Notes

Node 22.19+ library, not a turnkey hosted service. Enforce concurrency/time/spend limits before dispatch, use isolated runCode, require critical checkpoint persistence and test recovery against real effect providers.

## Verification and Limitations

Public unauthenticated source acquisition and static inspection at the exact revision above. No runtime, exploit, performance, model-quality, dependency-vulnerability or distribution-provenance verification was performed. Review is sampled, not exhaustive; absence of an observed problem is not a security guarantee. Public metadata is a 2026-10-12 snapshot and not evidence of quality.

---

**Attribution:** [Parcha-ai/agentrun](https://github.com/Parcha-ai/agentrun), Apache-2.0. Source claims and upstream status are distinguished from this review’s static findings.
