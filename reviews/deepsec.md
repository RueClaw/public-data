# Deepsec — product and getting-started review

**Source:** https://deepsec.sh/docs/getting-started
**Repo / author:** [vercel-labs/deepsec](https://github.com/vercel-labs/deepsec), Vercel and contributors
**License:** Apache-2.0; preserve license and applicable NOTICE/attribution on redistribution. Hosted services and model subscriptions have separate terms.
**Reviewed / retrieved:** 2026-11-21 (UTC)
**Source date:** Guide has no visible publication/update date. Source commit dated 2026-11-19.
**Revision:** `9444b896ca60eb399f9cebaea0bef61655781d42`; package manifest 2.3.16.
**Guide provenance:** Public URL returned HTTP 200 without authentication. SHA-256 of repository `docs/getting-started.md` at that revision: `e3565ab109767e84ddf707b8705c0adfe9d08951628ca9d12955a4a62c64fcca` (not a hash of rendered website HTML).
**Verification:** Static public docs and source inspection only. No installation, source execution, scan, account creation, paid model call, or adversarial isolation test.
**Stack:** TypeScript, Node.js 22+, pnpm, Claude/Codex/Pi agent SDKs, optional Vercel AI Gateway and Sandbox.

## Verdict

⚠️ **Interesting; pilot under explicit security and spending controls, not by blindly following the one-command quickstart.** Deepsec has a credible staged, resumable source-review architecture and useful credential brokering for cloud workers. But setup starts AI work automatically, local investigation is not uniformly read-only, and the guide contradicts the inspected implementation about direct-key onboarding. The published CI example also references an authorization gate it does not contain. These are material operational caveats, not proof of an exploited vulnerability.

## Update Notes

This refresh reuses the existing Deepsec review and index row rather than creating a second review for its getting-started URL. Previous review: 2026-05-19, no exact revision recorded, rated Deploy candidate. Current scope adds the public onboarding guide, 2.3.16 source, credential/egress boundaries, CI example, provider policies and recovery. Rating changes to Interesting because those boundaries require verification before adoption. Historical claims of 2,100 unit tests and 23 bundle tests passing are not current verification and are not carried forward as evidence for this revision.

## Summary

Deepsec reviews source repositories, not primarily running web applications or network targets. A local matcher scan selects security-relevant files; coding agents investigate batches with repository context, produce structured findings, and optionally revalidate them. Direct PR mode also investigates listed files with no matcher hits. Reporting/export and enrichment are separate stages. The product is suited to security engineers who can inspect findings, authorize model data transfer, and control agent execution. [1–3]

The quickstart's single command is an automation entry point, not just an installer. It scaffolds a separate workspace, installs dependencies, selects model access, analyzes source, inventories surfaces, generates coverage matchers, scans and starts AI processing. The guide says this may take minutes to many hours. Model selection and payment-route questions are not per-tool approval gates. Scaffold-only and plan modes are useful review points, but invoking either still runs the downloaded Deepsec package itself. [1]

Source inspection supports the broad architecture: setup checkpoints, typed per-file records, configurable agent adapters and explicit cloud upload/brokering code exist. It does not establish detection accuracy, absence of prompt injection, runtime enforcement of SDK restrictions, or a secure npm artifact. This review recommends an isolated, low-budget trial on approved code only—not a production deployment recommendation.

## Architecture and capabilities

| Layer | Evidence and implication |
|---|---|
| Setup | Coordinator stores checkpoints/digests and resumes phases; inventory and declarative matcher coverage gate precede the main processing stage. Setup itself can use paid AI. [2,4] |
| Local scan | Regex/glob matching; no model charge for the scan stage. Coverage is heuristic, not proof that all exploitable paths were examined. [2] |
| Investigation | Claude, Codex and Pi backends consume source context and project INFO.md; findings/history are merged into per-file records. [2,5] |
| Revalidation | Another model-assisted assessment; vendor claims reduced false positives, not an independent exploit confirmation. [2,3] |
| PR mode | Changed/listed files are always investigated, including those without matcher hits. Exit status reflects net-new findings, not all unresolved findings. [6] |
| Cloud workers | App, target and data bundles uploaded to Vercel Sandbox; partitioned workers return records for merging. Provider credentials are injected through the egress policy. [7] |
| Extensibility | Configuration and plugins are executable code loaded with Jiti/import, not inert policy files. Trust them as part of the execution supply chain. [8] |

The durable per-file state is the strongest design choice: expensive investigation is separable from scanning, reporting and retry. However, additive history retains sensitive source-derived findings; gitignored is neither encrypted nor automatically expired.

## Installation and supply-chain requirements

The root manifest requires Node 22+ and pins its development package manager to pnpm 8.15.9. The CLI manifest is 2.3.16 and includes agent SDKs/CLIs, Vercel OIDC/Sandbox libraries, Jiti and archive tooling. Cloud upload uses system git/tar. The docs also offer an alternate package-manager invocation for repositories whose devEngines reject npx. [1,9]

The advertised unversioned npx command resolves a moving registry package. This review inspected Git source, not an npm tarball/signature or registry provenance. For an approved trial, pin and verify the intended package/version and lockfile, review lifecycle dependencies, and inspect executable config/plugins before allowing secrets. Scaffold-only avoids dependency installation and scanning by Deepsec, but is not a substitute for trusting the launcher package. Do not run the quickstart inside arbitrary third-party checkouts on a credential-rich workstation.

### Onboarding contradiction: direct key does not imply platform-free setup

Getting started says direct OpenAI/Anthropic keys need no Vercel account. The credential guide says the project link is always required. At the reviewed source revision, `ensureConnectedWorkspace` returns early only for `mode === "local"`; direct/custom routes proceed to `ensureVercelLink`. Thus the direct-key claim is not supported by this inspected setup path, while the credential guide's “always” claim is itself too broad for local subscriptions. This is a static finding; npm-distributed runtime behavior was not tested. Local model authentication also does not mean local inference: it uses existing machine-wide agent subscriptions. [1,10]

## Privileges, authority and human approvals

**Source access is not permission to test a system.** Obtain repository-owner approval, authorization to transmit source to the chosen providers, and an explicit scope for any agent tools. No live-target scanning or exploitation was performed for this review. A code-analysis finding is not permission to validate it against production or third parties.

The Codex setup adapter requests read-only/no-network tools. Investigation instead sets local `workspace-write`, cloud `danger-full-access`, `approvalPolicy: "never"` and `networkAccessEnabled: false`. That is not a uniform read-only posture. The cloud VM is intended to be the boundary; SDK settings are not independently proven enforcement. [5]

Claude requests `permissionMode: "dontAsk"`, and its local sandbox helper enables automatic Bash approval with `failIfUnavailable: false`. The source comments explicitly describe graceful degradation when the OS sandbox dependency is missing. Its child environment allowlist reduces unrelated inherited credentials but still forwards the model credential needed for authentication. Neither an allowlisted environment nor a read-oriented tool list proves source cannot influence shell behavior. Pi was not independently audited to the same depth; do not assume identical isolation across backends. [5]

Human review should happen before installing/config loading, granting provider access, exporting source, enabling workers, spending money, and acting on findings. The unattended flow provides no reason to expect an approval prompt for each agent action.

### CI example: useful separation, incomplete authorization story

The docs split analysis and comment publication: analysis has contents-read, while a separate comment job holds PR-write and reads an artifact. Fork PRs are skipped. These are useful boundaries. But the text says an `author_association` gate prevents secret exposure; **the displayed YAML has only a same-repository gate, not an author-association gate**. Same-repository provenance is not review approval. [6]

The example exposes the Gateway secret to the Deepsec step, which loads PR-controlled config; its earlier install step is not shown with that secret environment, contrary to the prose's broad description. Do not “copy as-is” for untrusted changes. Use a trusted, separately approved analysis configuration and isolated execution, explicit maintainer approval, least-privilege credentials and full action SHA pins. Never combine PR-controlled execution and repository-write permissions. Treat model-generated comment artifacts as untrusted output as well.

## Credentials, source egress and retention

- **Local model route:** repository snippets and context go to the configured model provider, directly or through Gateway. “No network” for agent shell tools is not “no model traffic.” Local subscription mode delegates authentication to existing CLI login and has no model-access preflight guarantee. [1,3,10]
- **Credential storage:** config records the environment-variable name rather than a BYOK value. Credentials can still be present in the calling environment or plaintext ignored `.env.local`; project metadata is stored separately. Use narrowly scoped/revocable credentials and protect local artifacts. [10]
- **Cloud brokering:** worker network policy selects the model host, injects headers at egress, and accepts extra allowed hosts. This usefully withholds real model tokens from worker environment values; it does not prevent authorized model calls from sending source or consuming budget. Host-side credentials remain sensitive. [7]
- **Cloud source transfer is broader than snippets:** orchestrator prepares app, target and data tarballs. Git mode includes tracked plus untracked-not-ignored files, removes symlinks and explicit nested workspace/data paths. Non-git target exclusions do not list `.env`, unlike app exclusions. Inspect the exact upload manifest; do not assume ignore rules or the broker sanitize every source secret. This is an observed packaging rule, not a demonstrated leak. [7]
- **Retention is multiple policies:** local records/reports, CI artifacts, cloud snapshots and providers are separate stores. The FAQ's “data stays on your machine unless exported” is incomplete for Sandbox mode. No unified deletion deadline or proof of snapshot cleanup was established. Vercel pricing explicitly charges for snapshot storage and advises a retention period. Stopping workers is not proof that snapshots are deleted. [3,7,11]
- **Gateway is not the whole privacy boundary:** Vercel's ZDR page says Gateway itself discards prompt/response content but records request metadata. It also says provider routing does not default to ZDR; eligible accounts must enable team-wide or per-request ZDR, with model/tool exceptions. BYOK agreements and prompt-training controls are separate. Deepsec's FAQ shorthand must not be interpreted as universal provider zero retention. [12]

## Costs and recovery

The FAQ estimates Claude Opus processing at $25–60 for 100 files, $130–300 for 500, and $500–1,200 for 2,000, with 2–3× complexity variation. These are vendor estimates, not measured here or a quote for current defaults. Revalidation may cost similarly to processing; setup/model verification and other AI stages are not made free by the scan stage being free. The README warns very large scans can cost thousands or tens of thousands. [3,9]

Cost/duration limits, low file limits and reduced concurrency are useful safeguards, but a safe-point stop is not a provider billing hard cap. In-flight requests, retries and other phases/services require separate limits. Gateway token/add-on fees, direct-provider bills and Sandbox CPU, provisioned memory, transfer and snapshot charges are independent; even I/O-waiting workers consume provisioned-memory time. Put provider-side budgets in place and verify what each limit covers. [1,11,13]

Re-running init/setup resumes completed checkpoints; interrupted processing preserves completed file records, and coverage failures carry repair/resume instructions. Revalidation and forced reinvestigation can intentionally incur new work. Back up protected state before migrations or destructive cleanup; protect caches as vulnerability data. After interruption, inspect status and outstanding workers/snapshots, collect results and confirm resources stopped. Rotate exposed credentials and verify provider billing before retrying. No crash/recovery, hard-cap, or cloud-cleanup behavior was executed here. [1–3,7]

## Evidence and maturity

The inspected repository has Node 22/24 CI configuration with SHA-pinned actions, build/lint/Knip/unit/bundle checks, focused credential/network-policy tests and a release workflow. These are positive engineering signals, not a claim that current checks passed. Public metadata on retrieval showed 8,481 stars, 526 forks, 81 open issues/PRs combined, a 2026-11-20 push and no archive flag. The latest GitHub Release endpoint returned 404; this does not mean the npm package is unreleased. [9,14]

The vendor publishes DeepSecBench results and the model picker consumes that public JSON. The FAQ claims roughly 10–29% false positives on HIGH+ after revalidation; architecture docs claim 50%+ reduction on most repositories. Those are vendor claims without an independently reproduced methodology in this review. A leaderboard does not establish performance on a particular codebase or recall for unknown vulnerabilities. No finding was reproduced and no benchmark/test suite was run. [2,3,15]

## License and service terms

Apache-2.0 plus NOTICE permits code reuse under its conditions; it does not grant free model inference, hosted compute or authority to scan third-party assets. Vercel's Terms distinguish exclusively open-source software from hosted Services; service/API terms and acceptable-use rules also apply. The fetched Terms are dated October 19, 2026 and include plan-dependent content/model-training provisions and personal/noncommercial Hobby restrictions. Apply the specific service policy and your actual agreement rather than inferring a blanket training entitlement or blanket prohibition from one page. Confirm provider/subscription terms, data-processing requirements and retention controls before confidential use. [16]

## Alternatives and operational fit

| Option | Better fit | Tradeoff |
|---|---|---|
| Semgrep with reviewed local rules | Repeatable policy and known source-pattern checks without requiring LLM inference | Rule coverage and engine/feature licensing still matter; not an autonomous cross-file investigator. [17] |
| CodeQL | Query-based semantic analysis and established code-scanning workflows | Language/build support and licensing must fit; setup differs from a one-command agent review. [18] |
| Human security review plus existing SAST | High-impact findings, architectural authorization flaws, accountable validation | Slower and labor-intensive; use agents as supporting evidence, not final sign-off. |
| Deepsec isolated pilot | Additional hypotheses from agent investigation, resumable batches and second-pass review | Source egress, execution privileges, variable cost and model uncertainty require explicit controls. |

**Recommended sequence:** retain deterministic baseline checks; review a pinned Deepsec scaffold/config in a disposable, secret-minimized environment; approve source transfer and spending; trial a small trusted scope; manually reproduce and triage findings in an authorized test environment. Expand only after measuring useful findings per dollar and proving isolation/recovery for the chosen backend.

## Verification scope and limitations

Inspected README, LICENSE/NOTICE, manifests, CI, docs, setup coordinator/auth connection, config loader, Claude/Codex adapters, cloud network policy, upload/orchestration and public service documentation. Source paths below are pinned. Website/docs may change independently of Git or the npm artifact. No exhaustive dependency, Pi-backend, plugin, archive-path, provider-contract or prompt-injection audit was performed. Public docs accessibility and artifact link/markup checks are not product safety tests.

## Sources

1. [Getting started](https://deepsec.sh/docs/getting-started); [pinned guide](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/docs/getting-started.md).
2. [Architecture](https://deepsec.sh/docs/architecture).
3. [Pinned FAQ](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/docs/faq.md).
4. [Setup coordinator](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/packages/deepsec/src/setup/coordinator.ts).
5. [Codex adapter](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/packages/processor/src/agents/codex-sdk.ts); [Claude adapter](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/packages/processor/src/agents/claude-agent-sdk.ts).
6. [Reviewing changes and CI example](https://deepsec.sh/docs/reviewing-changes).
7. [Sandbox setup/network policy](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/packages/deepsec/src/sandbox/setup.ts); [upload](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/packages/deepsec/src/sandbox/upload.ts); [orchestrator](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/packages/deepsec/src/sandbox/orchestrator.ts).
8. [Configuration loading](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/packages/deepsec/src/load-config.ts).
9. [Repository at reviewed revision](https://github.com/vercel-labs/deepsec/tree/9444b896ca60eb399f9cebaea0bef61655781d42); [CLI manifest](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/packages/deepsec/package.json).
10. [Credential guide](https://deepsec.sh/docs/vercel-setup); [connection implementation](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/packages/deepsec/src/auth/ensure-connected-workspace.ts).
11. [Sandbox pricing and snapshot retention guidance](https://vercel.com/docs/sandbox/pricing).
12. [AI Gateway ZDR and provider distinctions](https://vercel.com/docs/ai-gateway/security-and-compliance/zdr).
13. [AI Gateway pricing](https://vercel.com/docs/ai-gateway/pricing).
14. [Public repository metadata](https://api.github.com/repos/vercel-labs/deepsec); [CI definition](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/.github/workflows/ci.yml).
15. [Vendor DeepSecBench results](https://vercel.com/ai-gateway/leaderboards/deepsecbench/results.json).
16. [License](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/LICENSE); [NOTICE](https://github.com/vercel-labs/deepsec/blob/9444b896ca60eb399f9cebaea0bef61655781d42/NOTICE); [Vercel Terms](https://vercel.com/legal/terms), [Service Terms](https://vercel.com/legal/service-terms), [Acceptable Use](https://vercel.com/legal/acceptable-use-policy).
17. [Semgrep local-rule scanning](https://semgrep.dev/docs/running-rules).
18. [About CodeQL](https://codeql.github.com/docs/codeql-overview/about-codeql/).

**Attribution:** Deepsec documentation and source by Vercel and contributors, Apache-2.0; linked service policies belong to their respective publishers. Analysis is independent; vendor statements are not independently validated guarantees.
