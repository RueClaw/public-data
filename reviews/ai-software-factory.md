# AI Software Factory (piomin/ai-software-factory)

**Repo:** https://github.com/piomin/ai-software-factory
**Author:** piomin (Piotr Minkowski)
**License:** No license specified; public visibility does not grant general reuse or redistribution rights. No source code extracted.
**Reviewed:** 2026-11-20 (UTC)
**Revision:** `2340226d69bbb5de768e3c93d7587f032c150a16`, default branch master; README, all agent/model/Tekton manifests, Dockerfiles and repository inventory.
**Verification:** Static review only. No agents, builds, containers, models, cluster operations or live endpoint probes run. Public GitHub metadata checked.
**Stack:** Kubernetes/OpenShift, Tekton Pipelines/Triggers, Bash, OpenCode, vLLM/Qwen, GitHub App, ORAS, Java/Maven.

## Verdict

📚 **Study — a clear Kubernetes-native coding-agent recipe, not a hardened autonomous software factory.** The strongest ideas are explicit event-to-pipeline wiring, short-lived GitHub tokens, per-event run names and a bounded build/fix loop. The important gaps are a writable trust boundary into credentialed publication, broad shell authority, non-blocking verification and infrastructure/security assumptions left to the operator. Missing licensing and a two-day public history further argue against adopting it unchanged.

## What It Is

This is a small collection of deployment manifests and embedded shell scripts, not a SaaS application, new model, general multi-agent framework or complete production delivery platform. GitHub issues and comments start Tekton runs; OpenCode plans and changes a repository using an in-cluster model; deterministic shell steps commit, push, open PRs and post replies. Its most natural audience is an OpenShift platform team experimenting with Java/Spring repositories and already operating GPUs.

Three pipelines handle new issues, issue comments prefixed with `@ai`, and PR reviews/inline comments. Questions may get answers without code changes. Planning, implementation and repair are successive invocations of the same configured coding agent, not independently trusted reviewer roles. Imported skills/subagents come from an external OCI artifact; their content is not in this repository and was not acquired. A reviewer agent, plan approval, automatic downstream-CI repair and preview environments are explicitly future ideas. [E1–E6]

## Stack

| Layer | Implementation and implications |
|---|---|
| Ingress | OpenShift edge-TLS Route → Tekton EventListener → GitHub HMAC and CEL interceptors |
| Orchestration | Four triggers, three Pipelines; shared fetch-skills, verify-build, report-failure Tasks |
| Agent | OpenCode image from Quay, config in a ConfigMap, unrestricted-by-default Bash with a few command denials |
| Inference | OpenAI-compatible vLLM service; default named Qwen3.8 Flash model; second Qwen3 Coder deployment is optional |
| SCM | GitHub App installation tokens, Git/gh; Contents, Issues and Pull Requests write permissions requested |
| State | Kubernetes PipelineRun/TaskRun objects; per-run 1 GiB skills and 10 GiB work PVCs; separate 300 GiB model cache |
| Build | Maven verify auto-detected by pom.xml; custom shell verify command optional |
| Product UI/auth | No product frontend, user database or tenant identity system; GitHub and Kubernetes supply operational identity |

## Key Features and Architecture

The flow is event logging → skills fetch → prepare/plan/agent → verify → publish, with a finally failure-report task. Prepare clones the branch, gathers context and hands a temporary token to planning. Planning writes and posts a checklist; implementation proceeds immediately, even when planning errors. Agent output is summarized outside the repository. Verify can ask the model to repair a failing build before publication. Publication excludes target directories but otherwise stages all repository changes. [E2–E6]

This is inspectable infrastructure-as-code: the scripts make automatic side effects easy to locate. Passing webhook text through environment variables and quoted expansion is better than directly splicing arbitrary text into executable script source. That does not neutralize instructions presented to the model or code executed by build tooling.

### Human approval is downstream and externally configured

There is **no plan-approval gate**. New issue and issue-comment change paths automatically push and create PRs, then request auto-merge unless the verification-failed marker exists. Whether a person must approve is determined by the target repository's branch protection, not the pipeline. The README correctly warns that without protection auto-merge may merge immediately. PR feedback pushes directly onto the existing PR branch; no new approval ceremony surrounds the push. Review triggers need no `@ai` prefix and do not require a change-request review state. [E1–E4,E7]

HMAC verification authenticates delivery and OWNER/MEMBER association filters who can initiate runs. The new-issue filter only checks opened and association; unlike comment/review filters it has no explicit Bot exclusion. Fork PRs are rejected in prepare, after a run has already started. These are useful admission checks, not authorization of every piece of text read later.

### Verification is informative, not a release gate

The shared task auto-runs Maven only when pom.xml is present; unknown builds and explicit skip return success without a verification note. Failed builds get up to three model repairs. Persistent failure writes a marker and note rather than failing the task. Issue pipelines then create drafts and do not enable auto-merge—a useful safeguard, but code is still pushed. The PR-comment publisher does **not** consume the failed marker to block pushing, convert the PR to draft or disable pre-existing auto-merge. Required external CI remains essential. [E3–E5]

Tests and build configuration are editable by the same agent being assessed; a prompt not to weaken tests is not an independent oracle. Verification also executes repository-controlled build plugins/scripts. No separate immutable test set or reproducible benchmark is supplied.

## Security and Trust Boundaries

### Shared writable state crosses into a credentialed publisher — high priority

Not placing the App private key directly in the implementation step is a meaningful improvement. It is not a complete privilege boundary: the agent and build share the repository, Git metadata, HOME and workspace with a later publisher that receives the App private key and freshly minted installation token. Broad Bash and external-directory access allow changes outside tracked sources. Git hooks/configuration or shared executable/configuration state can affect later Git operations; the publisher does not reconstruct an independently validated clean tree or disable those execution paths. Planning reset/clean does not reset Git metadata or shared HOME. This is a static trust-boundary finding, not a demonstrated credential theft. [E2–E5,E8]

The planner itself gets the installation token, with the installation's authority rather than a comment-only server-side token. The token-minting request has no per-repository or reduced-permission body. Allowing only selected gh command patterns does not reduce the token's API permissions. General shell/network commands remain allowed. Deleting the handoff file after loading it is good hygiene but does not make planning a secret-free sandbox.

### Prompt injection and egress are not constrained by the model location

Issue/PR conversation collection includes other authors' comments without the initiating OWNER/MEMBER filter. Repository instructions, external skills and build-error output also enter prompts. An untrusted comment can therefore be read during an authorized run. Default Bash allow, external-directory allow and shell-capable tools make webfetch denial an inadequate egress or credential boundary. No NetworkPolicy is supplied. “Nothing leaves the cluster except GitHub” is a topology aspiration, not an enforced property: model/image/skill downloads, Maven dependencies and arbitrary shell networking are additional paths. Generated summaries and failing-build log tails are deliberately posted back to GitHub and could disclose sensitive output. [E1–E6,E8]

### Authentication, Kubernetes authority and tenancy

The model service is ClusterIP over HTTP. Neither vLLM deployment supplies an API-key enforcement flag or network isolation policy; a placeholder client key is not server-side authentication. Do not expose it outside a restricted network or assume arbitrary cluster tenants are excluded. The public listener has HMAC checks and edge TLS, but this repository supplies no external rate limiter, abuse budget, repository allowlist or tenant-separated credentials/workspaces beyond per-run volumes. [E7–E10]

The README says agent pods have no kubeconfig or RBAC, yet token automount is not disabled. Comment templates explicitly select the existing pipeline service account; new-issue runs rely on defaults. Effective permissions depend on the installed Tekton/OpenShift environment and were not measured. No cloud IAM credential wiring is included; ROSA is deployment context, not a guarantee of cloud isolation. kubectl and Skaffold binaries are present, but no automatic application deployment stage or deployment-specific RBAC is implemented. The operator must verify actual pod identity, mounted tokens, namespace permissions and metadata/network reachability rather than rely on that README assurance.

## Persistence, Retry and Recovery

Fixed PipelineRun names based on issue/comment/review IDs suppress duplicate creation while the object exists. This is useful delivery deduplication, **not exactly-once publication**. Removing a run and redelivering, as documented, loses that guard. Push, PR creation, auto-merge setup and comment posting are separate side effects with no transactional journal or lookup-before-create recovery. A late failure may leave a pushed branch or existing PR; the generic failure report can still say no PR was created. Two distinct comments on one PR can race on its head branch; there is no per-PR lock, fetch/rebase/retry or conflict-resolution queue in the publisher. [E2–E4,E6,E9]

Agent/planner errors and timeouts are deliberately logged and continued where possible. Whole task time is three hours, with 15 minutes reserved for finally; the agent's own three-hour allowance can consume all remaining verification/publication time. The repair loop checks its 45-minute deadline between attempts, so it is not a strict elapsed-time cap: a 15-minute repair and following 20-minute build can overrun it. Failure notification is best effort and suppresses token/comment errors. No durable retry scheduler, exponential backoff, result database, retention/pruning or backup policy is supplied. PVC and log lifecycle is an operator responsibility. Optional pod quota limits concurrency but not total spend; queued time consumes timeout. [E5,E6,E9]

## Costs, Installation and Update Risk

Default Qwen3.8 Flash declares two GPUs, 180 GiB requested/200 GiB limited RAM, 4 requested/16 limited CPUs, a 300 GiB cache PVC and a 128k context. It starts scaled to zero. The second Coder manifest also requests two GPUs but actually requests 20 GiB/limits 50 GiB RAM and has no cache PVC, unlike the README's general prerequisite wording. These are declared requests, not measured adequate hardware or proof the model identifiers/images are available. No model assets were downloaded. [E10]

Local inference avoids default per-token API billing, not GPU/cluster/storage/network cost. OpenShift/GPU operations, downloads, long agent runs and repeated verification dominate the economics; no dollar estimate, throughput measurement or token budget is supplied. The optional Claude Code Dockerfile and placeholder Anthropic secret are not used by the default pipelines; enabling a variant would introduce provider billing and data-egress considerations.

Agent and some base images use mutable tags; npm agent installation is unpinned; the JDK download uses a latest URL; binary downloads lack explicit checksum/signature verification. The version-tagged skills artifact is neither digest-pinned nor signature-verified and tar archives are unpacked without a repository-level member allowlist. Its executable instructions deserve supply-chain treatment, not just documentation trust. Dockerfiles finish as non-root UID 1001, but that alone does not isolate subsequent tasks or establish runtime security policy. No lockfile/SBOM or tested update matrix makes this reproducible. Rebuild from reviewed dependencies, pin digests, verify provenance and audit external skills before trial. [E6,E8,E11]

## Maturity, License and Claims Versus Evidence

The public API reported creation on 2026-11-18, last push 2026-11-20T12:36:26Z, 56 stars, 12 forks and zero open issues at retrieval on 2026-11-20. The releases endpoint returned an empty list. The issues endpoint showed one merged reliability PR (#1); its additions are present at the reviewed SHA. These are activity signals, not reliability evidence. The 46 tracked files contain no LICENSE, automated test suite or .github CI workflow. No general reuse permission was identified; dependency and model terms must also be assessed separately. [E12]

Documentation and screenshots describe a showcase installation, but this review did not independently reproduce its runs or measure success rate. The README still says nothing verifies code after the agent, while the current implementation includes verify-build. It overgeneralizes bot filtering, model resources and no-cluster-credential isolation. Its future-work section is more candid: plan gates, evaluations, observability and hardening remain unfinished. Treat successful showcase PRs as examples rather than evidence of safe unattended operation.

## Comparison

| Option | Best fit | Tradeoff relative to this repository |
|---|---|---|
| OpenCode with a supervised local checkout | A developer wants explicit per-task control | Much less platform overhead; lacks this webhook/Tekton automation unless added |
| GitHub Actions plus an explicitly approved coding-agent job | GitHub-centric teams already operating CI | Reuses CI controls and protected environments; still needs isolation and narrowly scoped credentials |
| OpenHands | Teams evaluating a broader coding-agent runtime | Compare its concrete sandbox, integrations and deployment mode rather than assuming safety from product breadth |
| This Tekton recipe | OpenShift/GPU teams studying event-driven automation | Most transparent fit to existing Kubernetes operations; most of the safety and operational product work remains yours |

These are architectural alternatives, not live benchmark results or endorsement of any alternative's default security. No paid service is necessary to study the design.

## Self-Hosting Decision

Before even a limited trial: obtain licensing clarity; choose an isolated disposable repository; require human reviews and immutable external CI; disable automatic merge initially; restrict App installation scope; isolate the publisher from agent-writable HOME/Git metadata; disable service-account token mounts on unprivileged pods; configure minimal RBAC and egress; authenticate/isolate inference; pin images and verify skill artifacts; redact logs; define retention and partial-publication recovery. Validate non-Maven, failing-build, duplicate-event and concurrent-PR paths offline or in an explicitly authorized disposable environment.

For a team not already running OpenShift and GPU inference, a supervised coding CLI is a more proportionate starting point. For an existing platform team, study the orchestration and fresh-token placement—but do not confuse a separate Tekton step with a secure trust boundary.

## Evidence and Verification Limits

All implementation references below are pinned to the reviewed SHA. Inspection covered the public tracked tree and source, not image contents, imported skills, dependency internals, target repository protection, actual cluster RBAC or model quality. No runtime exploit, build pass, deployment success, cost or throughput is claimed. No private account or project data was used.

- **E1:** [README](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/README.md).
- **E2:** [New-issue pipeline](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/pipeline-issue-agent.yaml).
- **E3:** [Issue-comment pipeline](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/pipeline-issue-comment-agent.yaml).
- **E4:** [PR-comment pipeline](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/pipeline-pr-comment-agent.yaml).
- **E5:** [Build and repair task](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/task-verify-build.yaml).
- **E6:** [Fetch skills](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/task-fetch-skills.yaml), [failure reporting](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/task-report-failure.yaml).
- **E7:** [Event admission](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/eventlistener-new-issue.yaml), [HTTPS route](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/route-new-issue.yaml).
- **E8:** [Agent permissions and token helper](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/agents/configmap-agent-config.yaml).
- **E9:** [Issue template](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/triggertemplate-new-issue.yaml), [comment template](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/triggertemplate-issue-comment.yaml), [PR template](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/triggertemplate-pr-comment.yaml), [quota](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/tekton/resourcequota-agents.yaml).
- **E10:** [Default inference deployment](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/ai/deployment-qwen38-flash.yaml), [Coder deployment](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/ai/deployment-qwen3-coder.yaml), [model service](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/ai/service-qwen38-flash.yaml), [cache](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/ai/pvc-qwen38-flash-cache.yaml).
- **E11:** [OpenCode image recipe](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/agents/Dockerfile.opencode), [optional Claude recipe](https://github.com/piomin/ai-software-factory/blob/2340226d69bbb5de768e3c93d7587f032c150a16/agents/Dockerfile).
- **E12:** [Public metadata](https://api.github.com/repos/piomin/ai-software-factory), [releases](https://api.github.com/repos/piomin/ai-software-factory/releases), [reliability PR](https://github.com/piomin/ai-software-factory/pull/1); metadata is time-varying.

**Attribution:** piomin/ai-software-factory, public source by piomin; no license specified. This is independent analysis, not a redistribution of the implementation.
